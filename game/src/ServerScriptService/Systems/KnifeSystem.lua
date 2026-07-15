--!strict
-- Human melee (slot 3, always available). Spec: "logique proche de la
-- griffe" — mirrors InfectionSystem's range/cone/cooldown/windup shape since
-- no distinct numbers were specified for the knife. Damage comes from
-- WeaponConfig.Weapons.Knife (25, PLACEHOLDER per spec, never locked).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Modules.Net)
local WeaponConfig = require(ReplicatedStorage.Shared.Config.WeaponConfig)
local TeamConfig = require(ReplicatedStorage.Shared.Config.TeamConfig)

local TeamManager = require(script.Parent.TeamManager)
local StaminaSystem = require(script.Parent.StaminaSystem)
local DamageTracker = require(script.Parent.DamageTracker)
local RoundManager = require(script.Parent.RoundManager)

local KnifeSystem = {}

local KNIFE_RANGE_STUDS = 5
local KNIFE_CONE_HALF_ANGLE_DEGREES = 22.5
local KNIFE_COOLDOWN_SECONDS = 1
local KNIFE_WINDUP_SECONDS = 0.25

local lastSwingTime: { [Player]: number } = {}

local function getHumanoidRootPart(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function isWithinCone(attackerRoot: BasePart, targetRoot: BasePart): boolean
	local toTarget = targetRoot.Position - attackerRoot.Position
	local distance = toTarget.Magnitude
	if distance > KNIFE_RANGE_STUDS or distance <= 0 then
		return false
	end

	local angleDegrees = math.deg(math.acos(math.clamp(attackerRoot.CFrame.LookVector:Dot(toTarget.Unit), -1, 1)))
	return angleDegrees <= KNIFE_CONE_HALF_ANGLE_DEGREES
end

local function findKnifeTarget(attacker: Player): Player?
	local attackerRoot = getHumanoidRootPart(attacker)
	if not attackerRoot then
		return nil
	end

	for _, infected in ipairs(TeamManager.GetPlayersOnTeam(TeamConfig.INFECTED)) do
		local targetRoot = getHumanoidRootPart(infected)
		local humanoid = infected.Character and infected.Character:FindFirstChildOfClass("Humanoid")
		if targetRoot and humanoid and humanoid.Health > 0 and isWithinCone(attackerRoot, targetRoot) then
			return infected
		end
	end

	return nil
end

local function onKnifeAttack(player: Player)
	if RoundManager.CurrentState ~= "InProgress" then
		return
	end
	if player.Team == nil or player.Team.Name ~= TeamConfig.HUMANS then
		return
	end
	if StaminaSystem.IsSprinting(player) then
		return
	end

	local now = os.clock()
	if now - (lastSwingTime[player] or 0) < KNIFE_COOLDOWN_SECONDS then
		return
	end
	lastSwingTime[player] = now

	task.delay(KNIFE_WINDUP_SECONDS, function()
		if player.Team == nil or player.Team.Name ~= TeamConfig.HUMANS then
			return
		end

		local target = findKnifeTarget(player)
		if not target then
			return
		end

		local damage = WeaponConfig.Weapons.Knife.DamagePerShot
		DamageTracker:ApplyDamage(player, target, damage, "Knife")
	end)
end

function KnifeSystem.Init()
	Net.OnServerEvent("KnifeAttack", onKnifeAttack)

	Players.PlayerRemoving:Connect(function(player)
		lastSwingTime[player] = nil
	end)
end

return KnifeSystem
