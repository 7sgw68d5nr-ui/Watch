--!strict
-- The claw: an active attack (not passive contact), 5-stud range, 45° cone in
-- front of the infected, 1s cooldown, 0.25s windup before the hit check,
-- blocked while sprinting. Every attempt (hit or miss) resets the attacker's
-- own regen timer. A confirmed hit converts the victim to Infected after a
-- 0.5s delay.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Signal)
local Net = require(ReplicatedStorage.Modules.Net)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local TeamConfig = require(ReplicatedStorage.Shared.Config.TeamConfig)
local MutagenConfig = require(ReplicatedStorage.Shared.Config.MutagenConfig)

local TeamManager = require(script.Parent.TeamManager)
local StaminaSystem = require(script.Parent.StaminaSystem)
local WeightSystem = require(script.Parent.WeightSystem)
local RegenSystem = require(script.Parent.RegenSystem)
local RoundManager = require(script.Parent.RoundManager)

local InfectionSystem = {}

local CLAW_RANGE_STUDS = 5
local CLAW_CONE_HALF_ANGLE_DEGREES = 22.5 -- "cône de 45°" = 45° total width, 22.5° either side of look vector
local CLAW_COOLDOWN_SECONDS = 1
local CLAW_WINDUP_SECONDS = 0.25

InfectionSystem.PlayerInfected = Signal.new() -- (victim: Player, attacker: Player) — ScoringSystem (Étape 3) consumes this for infection-order bonuses

local lastClawTime: { [Player]: number } = {}

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
	if distance > CLAW_RANGE_STUDS or distance <= 0 then
		return false
	end

	local lookVector = attackerRoot.CFrame.LookVector
	local angleRadians = math.acos(math.clamp(lookVector:Dot(toTarget.Unit), -1, 1))
	local angleDegrees = math.deg(angleRadians)

	return angleDegrees <= CLAW_CONE_HALF_ANGLE_DEGREES
end

-- Applies the Infected stat profile (currently always "Base" until Étape 4
-- adds real mutagen selection) to a newly-converted player.
local function applyInfectedProfile(player: Player)
	local profile = MutagenConfig.Profiles[MutagenConfig.DEFAULT_PROFILE_ID]

	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.MaxHealth = profile.MaxHP
		humanoid.Health = profile.MaxHP
	end

	WeightSystem.SetBaseSpeed(player, profile.WalkSpeed, profile.WalkSpeed) -- infected sprint speed folded into base per current spec numbers
	StaminaSystem.SetProfile(player, profile.MaxStamina, 15, profile.StaminaRegenPerSec, false)
	RegenSystem.StartTracking(player, profile.RegenPercent)
end

local function convertToInfected(victim: Player, attacker: Player)
	TeamManager.SetPlayerTeam(victim, TeamConfig.INFECTED)
	applyInfectedProfile(victim)

	InfectionSystem.PlayerInfected:Fire(victim, attacker)
	RoundManager.CheckWinConditionNow()
end

local function findClawTarget(attacker: Player): Player?
	local attackerRoot = getHumanoidRootPart(attacker)
	if not attackerRoot then
		return nil
	end

	for _, human in ipairs(TeamManager.GetPlayersOnTeam(TeamConfig.HUMANS)) do
		local targetRoot = getHumanoidRootPart(human)
		local humanoid = human.Character and human.Character:FindFirstChildOfClass("Humanoid")
		if targetRoot and humanoid and humanoid.Health > 0 and isWithinCone(attackerRoot, targetRoot) then
			return human
		end
	end

	return nil
end

local function onClawAttempt(player: Player)
	if RoundManager.CurrentState ~= "InProgress" then
		return
	end
	if player.Team == nil or player.Team.Name ~= TeamConfig.INFECTED then
		return
	end
	if StaminaSystem.IsSprinting(player) then
		return
	end

	local now = os.clock()
	local last = lastClawTime[player] or 0
	if now - last < CLAW_COOLDOWN_SECONDS then
		return
	end
	lastClawTime[player] = now

	task.delay(CLAW_WINDUP_SECONDS, function()
		-- Every attempt, hit or miss, resets the attacker's own regen timer.
		RegenSystem.ResetTimer(player)

		-- Re-validate the attacker is still alive/infected after the windup.
		if player.Team == nil or player.Team.Name ~= TeamConfig.INFECTED then
			return
		end

		local target = findClawTarget(player)
		if not target then
			return
		end

		task.delay(GameConfig.HUMAN_TO_INFECTED_DELAY, function()
			-- Re-check both players are still in a valid state after the delay.
			if target.Team == nil or target.Team.Name ~= TeamConfig.HUMANS then
				return
			end
			if player.Team == nil or player.Team.Name ~= TeamConfig.INFECTED then
				return
			end
			convertToInfected(target, player)
		end)
	end)
end

function InfectionSystem.Init()
	Net.OnServerEvent("ClawAttempt", function(player: Player)
		onClawAttempt(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastClawTime[player] = nil
	end)
end

return InfectionSystem
