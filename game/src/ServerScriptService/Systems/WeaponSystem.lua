--!strict
-- Server-authoritative gunplay: the client sends fire *intent* (weapon id,
-- ray origin/direction) via the FireWeapon remote; this module validates
-- state (ammo, cooldown, reload, sprint-lock), performs the actual raycast,
-- and applies damage through DamageTracker. Never trusts a client-reported
-- hit. Ammo/reload/cooldown all live server-side; the client's HUD is a
-- mirror updated by remote events, not the source of truth.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Modules.Net)
local WeaponConfig = require(ReplicatedStorage.Shared.Config.WeaponConfig)
local TeamConfig = require(ReplicatedStorage.Shared.Config.TeamConfig)

local TeamManager = require(script.Parent.TeamManager)
local StaminaSystem = require(script.Parent.StaminaSystem)
local WeightSystem = require(script.Parent.WeightSystem)
local DamageTracker = require(script.Parent.DamageTracker)
local RoundManager = require(script.Parent.RoundManager)

local WeaponSystem = {}

type PlayerWeaponState = {
	equippedWeaponId: string?,
	ammo: { [string]: number },
	isReloading: boolean,
	lastFireTime: number,
}

local states: { [Player]: PlayerWeaponState } = {}

local function getState(player: Player): PlayerWeaponState
	local state = states[player]
	if not state then
		state = { equippedWeaponId = nil, ammo = {}, isReloading = false, lastFireTime = 0 }
		states[player] = state
	end
	return state
end

local function getAmmo(state: PlayerWeaponState, weaponId: string): number
	local def = WeaponConfig.Weapons[weaponId]
	if state.ammo[weaponId] == nil then
		state.ammo[weaponId] = def.MagazineSize
	end
	return state.ammo[weaponId]
end

local function getPlayerFromPart(part: BasePart): Player?
	local character = part:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	local player = Players:GetPlayerFromCharacter(character)
	return player
end

local function applyCaliberHitReaction(weaponDef: WeaponConfig.WeaponDefinition, target: Player)
	if weaponDef.Caliber == "Small" and weaponDef.SmallCaliberSlow then
		local slow = weaponDef.SmallCaliberSlow
		local key = "SmallCaliberSlow"
		WeightSystem.SetModifier(target, key, slow.Multiplier)
		task.delay(slow.Duration, function()
			WeightSystem.ClearModifier(target, key)
		end)
	elseif weaponDef.Caliber == "Large" and weaponDef.LargeCaliberKnockback then
		local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			-- Simple velocity-impulse knockback; not physically precise, just
			-- enough to sell "gros calibre = knockback" until playtesting tunes it.
			root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + (root.CFrame.LookVector * weaponDef.LargeCaliberKnockback * 4)
		end
	end
end

local function computeDamage(weaponDef: WeaponConfig.WeaponDefinition, distance: number, hitPart: BasePart): number
	local damage = weaponDef.DamagePerShot

	if weaponDef.Falloff then
		local falloff = weaponDef.Falloff
		if distance >= falloff.MinDamageRange then
			damage *= falloff.MinDamageMultiplier
		elseif distance > falloff.FullDamageRange then
			local t = (distance - falloff.FullDamageRange) / (falloff.MinDamageRange - falloff.FullDamageRange)
			damage *= (1 - t) + (falloff.MinDamageMultiplier * t)
		end
	end

	if hitPart.Name == "Head" then
		damage *= weaponDef.HeadshotMultiplier
	end

	return damage
end

local function canAct(player: Player): boolean
	if RoundManager.CurrentState ~= "InProgress" then
		return false
	end
	if player.Team == nil or player.Team.Name ~= TeamConfig.HUMANS then
		return false
	end
	if StaminaSystem.IsSprinting(player) then
		return false
	end
	return true
end

local function onFireWeapon(player: Player, weaponId: string, origin: Vector3, direction: Vector3)
	local def = WeaponConfig.Weapons[weaponId]
	if not def or def.Caliber == "Melee" then
		return
	end
	if not canAct(player) then
		return
	end

	local state = getState(player)
	if state.isReloading then
		return
	end

	local now = os.clock()
	local minInterval = 60 / def.RPM
	if now - state.lastFireTime < minInterval then
		return
	end

	if getAmmo(state, weaponId) <= 0 then
		return
	end

	state.lastFireTime = now
	state.ammo[weaponId] -= 1
	Net.FireClient("AmmoUpdated", player, weaponId, state.ammo[weaponId])

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }

	local result = Workspace:Raycast(origin, direction.Unit * 1000, params)
	if not result then
		return
	end

	local target = getPlayerFromPart(result.Instance)
	if not target or target.Team == nil or target.Team.Name ~= TeamConfig.INFECTED then
		return
	end

	local distance = (result.Position - origin).Magnitude
	local damage = computeDamage(def, distance, result.Instance)

	local applied = DamageTracker:ApplyDamage(player, target, damage, "Weapon")
	if applied then
		applyCaliberHitReaction(def, target)
	end
end

local function onReloadWeapon(player: Player, weaponId: string)
	local def = WeaponConfig.Weapons[weaponId]
	if not def or def.Caliber == "Melee" then
		return
	end
	if not canAct(player) then
		return
	end

	local state = getState(player)
	if state.isReloading then
		return
	end
	if getAmmo(state, weaponId) >= def.MagazineSize then
		return
	end

	state.isReloading = true
	task.delay(def.ReloadTime, function()
		state.isReloading = false
		state.ammo[weaponId] = def.MagazineSize
		Net.FireClient("AmmoUpdated", player, weaponId, def.MagazineSize)
	end)
end

function WeaponSystem.SetEquippedWeapon(player: Player, weaponId: string)
	local state = getState(player)
	state.equippedWeaponId = weaponId

	local def = WeaponConfig.Weapons[weaponId]
	if def then
		WeightSystem.SetModifier(player, "WeaponWeight", 1 + def.WeightPercent)
	end
end

function WeaponSystem.ResetAmmoForRound(player: Player)
	local state = getState(player)
	state.ammo = {}
	state.isReloading = false
end

local function onEquipWeapon(player: Player, weaponId: string)
	local def = WeaponConfig.Weapons[weaponId]
	-- Slot 3 (Knife) is handled by KnifeSystem, not equip-gated firing here;
	-- only accept firearm slots (1/2) through this path.
	if not def or def.Slot ~= 1 and def.Slot ~= 2 then
		return
	end
	WeaponSystem.SetEquippedWeapon(player, weaponId)
end

function WeaponSystem.Init()
	Net.OnServerEvent("FireWeapon", onFireWeapon)
	Net.OnServerEvent("ReloadWeapon", onReloadWeapon)
	Net.OnServerEvent("EquipWeapon", onEquipWeapon)

	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return WeaponSystem
