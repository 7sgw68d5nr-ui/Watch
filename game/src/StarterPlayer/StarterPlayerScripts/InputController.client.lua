--!strict
-- Étape 2 input bindings: fire/reload/knife/claw/sprint/crouch/equip.
-- Sends intent only (weapon id, aim ray) — the server is the source of truth
-- for everything that matters (ammo, cooldowns, hits, damage). No dedicated
-- jump binding: Roblox's default spacebar jump is gated server-side via
-- Humanoid.JumpPower (see StaminaSystem), so no remote is needed for jump.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage.Modules.Net)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local equippedWeaponId = "AssaultRifle"
local isFiring = false
local lastClientFireTime = 0

local KEY_TO_WEAPON = {
	[Enum.KeyCode.One] = "AssaultRifle",
	[Enum.KeyCode.Two] = "Pistol",
}

-- Approximate client-side throttle so we don't spam the remote faster than
-- any weapon could plausibly fire; the server enforces the real RPM cap
-- independently and is what actually matters for correctness.
local CLIENT_FIRE_THROTTLE = 1 / 20

local function getAimRay(): (Vector3, Vector3)
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector
	return origin, direction
end

local function isInfected(): boolean
	return player.Team ~= nil and player.Team.Name == "Infected"
end

local function fireLoop()
	while isFiring do
		if isInfected() then
			Net.FireServer("ClawAttempt")
			task.wait(0.1)
		else
			local now = os.clock()
			if now - lastClientFireTime >= CLIENT_FIRE_THROTTLE then
				lastClientFireTime = now
				local origin, direction = getAimRay()
				Net.FireServer("FireWeapon", equippedWeaponId, origin, direction)
			end
			task.wait()
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if not isFiring then
			isFiring = true
			task.spawn(fireLoop)
		end
	elseif input.KeyCode == Enum.KeyCode.R then
		if not isInfected() then
			Net.FireServer("ReloadWeapon", equippedWeaponId)
		end
	elseif input.KeyCode == Enum.KeyCode.V then
		if not isInfected() then
			Net.FireServer("KnifeAttack")
		end
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		Net.FireServer("RequestSprint", true)
	elseif input.KeyCode == Enum.KeyCode.C then
		Net.FireServer("RequestCrouch", true)
	elseif KEY_TO_WEAPON[input.KeyCode] then
		equippedWeaponId = KEY_TO_WEAPON[input.KeyCode]
		Net.FireServer("EquipWeapon", equippedWeaponId)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isFiring = false
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		Net.FireServer("RequestSprint", false)
	elseif input.KeyCode == Enum.KeyCode.C then
		Net.FireServer("RequestCrouch", false)
	end
end)

-- Equip the default weapon once the character (and thus server-side player
-- state) exists.
player.CharacterAdded:Connect(function()
	task.wait(1)
	Net.FireServer("EquipWeapon", equippedWeaponId)
end)

if player.Character then
	Net.FireServer("EquipWeapon", equippedWeaponId)
end
