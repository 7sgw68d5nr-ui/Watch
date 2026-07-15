--!strict
-- Infected regeneration: heals RegenPercent of max HP every 3 seconds spent
-- stationary (0.5-stud movement tolerance). Resets on movement past the
-- tolerance, on taking damage (hooked via DamageTracker.DamageApplied), and
-- on every claw attempt (hit or miss — hooked from InfectionSystem).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MutagenConfig = require(ReplicatedStorage.Shared.Config.MutagenConfig)
local DamageTracker = require(script.Parent.DamageTracker)

local RegenSystem = {}

local REGEN_TICK_SECONDS = 3
local MOVEMENT_TOLERANCE_STUDS = 0.5

type TrackedState = {
	lastPosition: Vector3,
	stationarySeconds: number,
	regenPercent: number, -- from the infected's active mutagen profile
}

local tracked: { [Player]: TrackedState } = {}

local function getHumanoidRootPart(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function getHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

-- `regenPercent` defaults to the Base mutagen profile; MutagenSystem (Étape 4)
-- will pass the player's actually-selected profile once selection exists.
function RegenSystem.StartTracking(player: Player, regenPercent: number?)
	local root = getHumanoidRootPart(player)
	tracked[player] = {
		lastPosition = root and root.Position or Vector3.zero,
		stationarySeconds = 0,
		regenPercent = regenPercent or MutagenConfig.Profiles.Base.RegenPercent,
	}
end

function RegenSystem.StopTracking(player: Player)
	tracked[player] = nil
end

-- Resets the stationary timer without moving the reference position — used
-- when the infected takes damage or attempts a claw while still standing
-- still (the *timer* resets even though they haven't physically moved).
function RegenSystem.ResetTimer(player: Player)
	local state = tracked[player]
	if not state then
		return
	end
	state.stationarySeconds = 0

	local root = getHumanoidRootPart(player)
	if root then
		state.lastPosition = root.Position
	end
end

local function tick(deltaTime: number)
	for player, state in pairs(tracked) do
		local root = getHumanoidRootPart(player)
		local humanoid = getHumanoid(player)
		if not root or not humanoid or humanoid.Health <= 0 then
			continue
		end

		local delta = (root.Position - state.lastPosition).Magnitude
		if delta > MOVEMENT_TOLERANCE_STUDS then
			state.lastPosition = root.Position
			state.stationarySeconds = 0
			continue
		end

		state.stationarySeconds += deltaTime

		if state.stationarySeconds >= REGEN_TICK_SECONDS then
			state.stationarySeconds -= REGEN_TICK_SECONDS

			local healAmount = humanoid.MaxHealth * state.regenPercent
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmount)
		end
	end
end

function RegenSystem.Init()
	Players.PlayerRemoving:Connect(RegenSystem.StopTracking)
	RunService.Heartbeat:Connect(tick)

	-- Taking damage resets the regen timer (spec: "Reset sur mouvement/dégâts
	-- reçus/tentative de griffe"). DamageTracker doesn't know which victims
	-- are Infected, so this just no-ops harmlessly for Humans (not tracked).
	DamageTracker.DamageApplied:Connect(function(_attacker, victim: Player)
		RegenSystem.ResetTimer(victim)
	end)
end

return RegenSystem
