--!strict
-- Server-authoritative stamina pool. Drains while sprinting, regenerates
-- otherwise, cuts sprint at 0. Also gates jumping for Humans (10 stamina
-- flat cost, blocked below the threshold via Humanoid.JumpPower = 0).
--
-- Class profile (Human vs Infected) is set by whoever assigns team/mutagen
-- (TeamManager/MutagenSystem) via SetProfile, so this module doesn't need to
-- know about Team instances itself.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HumanConfig = require(ReplicatedStorage.Shared.Config.HumanConfig)
local WeightSystem = require(script.Parent.WeightSystem)

local StaminaSystem = {}

type PlayerState = {
	maxStamina: number,
	stamina: number,
	drainPerSec: number,
	regenPerSec: number,
	isSprinting: boolean,
	isHuman: boolean, -- only Humans can jump/pay jump cost per spec
}

local states: { [Player]: PlayerState } = {}

local function getState(player: Player): PlayerState?
	return states[player]
end

local function getHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

-- Called by TeamManager (Humans) and, later, MutagenSystem (Infected) whenever
-- a player's class/profile is (re)assigned.
function StaminaSystem.SetProfile(player: Player, maxStamina: number, drainPerSec: number, regenPerSec: number, isHuman: boolean)
	states[player] = {
		maxStamina = maxStamina,
		stamina = maxStamina,
		drainPerSec = drainPerSec,
		regenPerSec = regenPerSec,
		isSprinting = false,
		isHuman = isHuman,
	}
end

function StaminaSystem.GetStamina(player: Player): number
	local state = getState(player)
	return state and state.stamina or 0
end

function StaminaSystem.IsSprinting(player: Player): boolean
	local state = getState(player)
	return state ~= nil and state.isSprinting
end

-- Called from InputController's sprint-key remote. Sprinting is refused at 0
-- stamina (spec: "0 stamina = coupe simple du sprint").
function StaminaSystem.RequestSprint(player: Player, wantsSprint: boolean)
	local state = getState(player)
	if not state then
		return
	end

	local actuallySprinting = wantsSprint and state.stamina > 0
	if state.isSprinting == actuallySprinting then
		return
	end

	state.isSprinting = actuallySprinting
	WeightSystem.SetSprinting(player, actuallySprinting)
end

-- Humans only: flat 10 stamina cost, blocked below threshold (JumpPower = 0
-- makes the block visible/felt immediately rather than just silently eating
-- the button press).
function StaminaSystem.TryJump(player: Player): boolean
	local state = getState(player)
	if not state or not state.isHuman then
		return false
	end

	if state.stamina < HumanConfig.MIN_STAMINA_TO_JUMP then
		return false
	end

	state.stamina = math.max(0, state.stamina - HumanConfig.JUMP_STAMINA_COST)
	return true
end

local function updateJumpGate(player: Player, state: PlayerState)
	if not state.isHuman then
		return
	end

	local humanoid = getHumanoid(player)
	if not humanoid then
		return
	end

	if state.stamina < HumanConfig.MIN_STAMINA_TO_JUMP then
		humanoid.JumpPower = 0
	elseif humanoid.JumpPower == 0 then
		humanoid.JumpPower = 50 -- Roblox default; restores normal jumping
	end
end

local function tick(deltaTime: number)
	for player, state in pairs(states) do
		if state.isSprinting then
			state.stamina = math.max(0, state.stamina - state.drainPerSec * deltaTime)
			if state.stamina <= 0 then
				-- Stamina hit 0 mid-sprint: force sprint off.
				state.isSprinting = false
				WeightSystem.SetSprinting(player, false)
			end
		else
			state.stamina = math.min(state.maxStamina, state.stamina + state.regenPerSec * deltaTime)
		end

		updateJumpGate(player, state)
	end
end

function StaminaSystem.ReleasePlayer(player: Player)
	states[player] = nil
end

-- Deducts the jump stamina cost the moment Roblox's own jump gating lets a
-- jump actually happen. JumpPower is already forced to 0 below the threshold
-- (see updateJumpGate), so by the time this fires the jump was legitimate;
-- this just charges for it. No client remote needed for jump at all.
local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.StateChanged:Connect(function(_old, new)
		if new == Enum.HumanoidStateType.Jumping then
			StaminaSystem.TryJump(player)
		end
	end)
end

function StaminaSystem.Init()
	Players.PlayerRemoving:Connect(StaminaSystem.ReleasePlayer)
	RunService.Heartbeat:Connect(tick)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	end)
end

return StaminaSystem
