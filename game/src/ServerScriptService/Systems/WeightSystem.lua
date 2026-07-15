--!strict
-- Single writer of Humanoid.WalkSpeed. Every system that affects movement
-- speed (CrouchSystem, WeaponSystem's per-weapon weight, and later
-- MutagenSystem/VestSystem) registers a named multiplicative modifier here
-- instead of touching Humanoid.WalkSpeed directly, so nothing stomps anything
-- else. Base walk/sprint speed is set per-player by whatever assigns their
-- team/class (TeamManager for Humans today; MutagenSystem will do the same
-- for Infected in Étape 4 — until then Infected default to the "Base"
-- mutagen's WalkSpeed, applied inline by InfectionSystem on conversion).

local Players = game:GetService("Players")

local WeightSystem = {}

type PlayerState = {
	baseWalkSpeed: number,
	baseSprintSpeed: number,
	isSprinting: boolean,
	modifiers: { [string]: number },
}

local states: { [Player]: PlayerState } = {}

local function getState(player: Player): PlayerState
	local state = states[player]
	if not state then
		state = {
			baseWalkSpeed = 16,
			baseSprintSpeed = 16,
			isSprinting = false,
			modifiers = {},
		}
		states[player] = state
	end
	return state
end

local function getHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

function WeightSystem.SetBaseSpeed(player: Player, walkSpeed: number, sprintSpeed: number)
	local state = getState(player)
	state.baseWalkSpeed = walkSpeed
	state.baseSprintSpeed = sprintSpeed
	WeightSystem.Recompute(player)
end

function WeightSystem.SetSprinting(player: Player, isSprinting: boolean)
	local state = getState(player)
	if state.isSprinting == isSprinting then
		return
	end
	state.isSprinting = isSprinting
	WeightSystem.Recompute(player)
end

-- multiplier of 1 = no effect. e.g. CrouchSystem sets "Crouch" to 0.35;
-- WeaponSystem sets "WeaponWeight" to (1 + weapon.WeightPercent).
function WeightSystem.SetModifier(player: Player, key: string, multiplier: number)
	local state = getState(player)
	state.modifiers[key] = multiplier
	WeightSystem.Recompute(player)
end

function WeightSystem.ClearModifier(player: Player, key: string)
	local state = getState(player)
	if state.modifiers[key] == nil then
		return
	end
	state.modifiers[key] = nil
	WeightSystem.Recompute(player)
end

function WeightSystem.GetEffectiveSpeed(player: Player): number
	local state = getState(player)
	local base = state.isSprinting and state.baseSprintSpeed or state.baseWalkSpeed

	local totalMultiplier = 1
	for _, multiplier in pairs(state.modifiers) do
		totalMultiplier *= multiplier
	end

	return base * totalMultiplier
end

function WeightSystem.Recompute(player: Player)
	local humanoid = getHumanoid(player)
	if not humanoid then
		return
	end
	humanoid.WalkSpeed = WeightSystem.GetEffectiveSpeed(player)
end

function WeightSystem.ReleasePlayer(player: Player)
	states[player] = nil
end

function WeightSystem.Init()
	Players.PlayerRemoving:Connect(WeightSystem.ReleasePlayer)
end

return WeightSystem
