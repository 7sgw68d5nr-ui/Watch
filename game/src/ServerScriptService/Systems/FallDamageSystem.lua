--!strict
-- Humans-only fall damage: 0-50 studs no damage, 50-130 studs linear ramp to
-- ~100 damage (a near-guaranteed kill at full HP), and the same slope
-- continues past 130 studs so longer falls only get deadlier. Infected are
-- immune (spec: no fall damage for Infected at all).
--
-- Roblox has no built-in fall-damage Humanoid property, so this tracks
-- Freefall -> Landed state transitions manually and measures the Y drop.

local Players = game:GetService("Players")
local TeamConfig = require(game:GetService("ReplicatedStorage").Shared.Config.TeamConfig)

local DamageTracker = require(script.Parent.DamageTracker)

local FallDamageSystem = {}

local NO_DAMAGE_RANGE = 50
local RAMP_END_RANGE = 130
local RAMP_END_DAMAGE = 100
local DAMAGE_PER_STUD = RAMP_END_DAMAGE / (RAMP_END_RANGE - NO_DAMAGE_RANGE)

local fallStartY: { [Player]: number } = {}

local function computeFallDamage(distance: number): number
	if distance <= NO_DAMAGE_RANGE then
		return 0
	end
	return (distance - NO_DAMAGE_RANGE) * DAMAGE_PER_STUD
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart

	humanoid.StateChanged:Connect(function(_old, new)
		if new == Enum.HumanoidStateType.Freefall then
			fallStartY[player] = root.Position.Y
		elseif new == Enum.HumanoidStateType.Landed then
			local startY = fallStartY[player]
			fallStartY[player] = nil

			if not startY then
				return
			end
			-- Infected are immune outright; skip the whole calc for them.
			if player.Team ~= nil and player.Team.Name == TeamConfig.INFECTED then
				return
			end

			local distance = startY - root.Position.Y
			local damage = computeFallDamage(distance)
			if damage > 0 then
				DamageTracker:ApplyDamage(nil, player, damage, "Fall")
			end
		end
	end)
end

function FallDamageSystem.Init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		fallStartY[player] = nil
	end)
end

return FallDamageSystem
