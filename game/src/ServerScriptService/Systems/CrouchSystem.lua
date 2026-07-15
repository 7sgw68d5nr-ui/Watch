--!strict
-- Server-authoritative crouch state. 35% speed via a WeightSystem modifier,
-- blocks sprint while active, and replicates the boolean to the owning
-- client (via a Player attribute) so InputController/camera code can drive
-- the smooth lerp camera-drop client-side without the server caring about
-- camera specifics.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HumanConfig = require(ReplicatedStorage.Shared.Config.HumanConfig)
local WeightSystem = require(script.Parent.WeightSystem)
local StaminaSystem = require(script.Parent.StaminaSystem)

local CrouchSystem = {}

local CROUCH_MODIFIER_KEY = "Crouch"

function CrouchSystem.SetCrouching(player: Player, isCrouching: boolean)
	if isCrouching then
		-- Crouch blocks sprint (spec: "bloque le sprint").
		StaminaSystem.RequestSprint(player, false)
		WeightSystem.SetModifier(player, CROUCH_MODIFIER_KEY, HumanConfig.CROUCH_SPEED_MULTIPLIER)
	else
		WeightSystem.ClearModifier(player, CROUCH_MODIFIER_KEY)
	end

	player:SetAttribute("Crouching", isCrouching)
end

function CrouchSystem.IsCrouching(player: Player): boolean
	return player:GetAttribute("Crouching") == true
end

function CrouchSystem.Init()
	Players.PlayerRemoving:Connect(function(player)
		player:SetAttribute("Crouching", nil)
	end)
end

return CrouchSystem
