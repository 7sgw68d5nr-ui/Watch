--!strict
-- Assigns/moves players between Humans/Infected/Spectators, and performs the
-- patient-zero draw (random selection without replacement) at the start of
-- each round's InfectedSelection phase. RoundManager owns *when* these happen;
-- TeamManager owns *how*.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeamConfig = require(ReplicatedStorage.Shared.Config.TeamConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local HumanConfig = require(ReplicatedStorage.Shared.Config.HumanConfig)

local TeamManager = {}

-- Lazily required to avoid a require() cycle: StaminaSystem/WeightSystem
-- don't depend on TeamManager, but requiring them at module-load time before
-- ServerScriptService.Systems has fully populated can be order-sensitive.
local StaminaSystem = nil
local WeightSystem = nil
local RegenSystem = nil

local function getMovementSystems()
	if not StaminaSystem then
		StaminaSystem = require(script.Parent.StaminaSystem)
		WeightSystem = require(script.Parent.WeightSystem)
		RegenSystem = require(script.Parent.RegenSystem)
	end
	return StaminaSystem, WeightSystem, RegenSystem
end

local teamInstances: { [string]: Team } = {}

local function ensureTeam(name: string): Team
	local existing = teamInstances[name]
	if existing then
		return existing
	end

	local team = Instance.new("Team")
	team.Name = name
	team.TeamColor = BrickColor.new(TeamConfig.COLORS[name] or Color3.new(1, 1, 1))
	team.AutoAssignable = false
	team.Parent = game:GetService("Teams")

	teamInstances[name] = team
	return team
end

function TeamManager.Init()
	ensureTeam(TeamConfig.HUMANS)
	ensureTeam(TeamConfig.INFECTED)
	ensureTeam(TeamConfig.SPECTATORS)
end

function TeamManager.SetPlayerTeam(player: Player, teamName: string)
	local team = ensureTeam(teamName)
	player.Team = team
	player.TeamColor = team.TeamColor

	-- Humans get their base movement/stamina profile (re)applied every time
	-- they're placed on the team, which covers both initial join and the
	-- per-round reset in ResetAllToHumans. Infected profile application is
	-- handled by InfectionSystem at the moment of conversion instead, since
	-- it also needs to resize MaxHealth/Health, which TeamManager has no
	-- opinion about.
	if teamName == TeamConfig.HUMANS then
		local Stamina, Weight, Regen = getMovementSystems()
		Weight.SetBaseSpeed(player, HumanConfig.WALK_SPEED, HumanConfig.SPRINT_SPEED)
		Stamina.SetProfile(player, HumanConfig.MAX_STAMINA, HumanConfig.SPRINT_DRAIN_PER_SEC, HumanConfig.STAMINA_REGEN_PER_SEC, true)
		Regen.StopTracking(player)

		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.MaxHealth = HumanConfig.MAX_HP
			humanoid.Health = HumanConfig.MAX_HP
		end
	end
end

function TeamManager.GetPlayersOnTeam(teamName: string): { Player }
	local team = teamInstances[teamName]
	if not team then
		return {}
	end

	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team == team then
			table.insert(result, player)
		end
	end
	return result
end

-- Resets everyone currently in the match (Humans+Infected, not pure spectators
-- who left mid-round) back onto the Humans team, ready for the next round's
-- InfectedSelection draw.
function TeamManager.ResetAllToHumans(eligiblePlayers: { Player })
	for _, player in ipairs(eligiblePlayers) do
		TeamManager.SetPlayerTeam(player, TeamConfig.HUMANS)
	end
end

-- Determines how many infected this round should have, per GameConfig's
-- population thresholds.
function TeamManager.GetInfectedCountForPopulation(playerCount: number): number
	if playerCount >= GameConfig.INFECTED_COUNT_THRESHOLD then
		return GameConfig.INFECTED_COUNT_HIGH
	end
	return GameConfig.INFECTED_COUNT_LOW
end

-- Random draw without replacement: shuffles eligible players and takes the
-- first `count` as patient(s) zero. Pure function of its inputs (aside from
-- math.random) so it's easy to reason about/test.
function TeamManager.DrawPatientZero(eligiblePlayers: { Player }, count: number): { Player }
	local pool = table.clone(eligiblePlayers)
	local drawn = {}

	count = math.min(count, #pool)
	for _ = 1, count do
		local index = math.random(1, #pool)
		table.insert(drawn, table.remove(pool, index))
	end

	return drawn
end

-- Runs the InfectedSelection phase: resets everyone to Humans, then infects
-- the drawn patient(s) zero. Returns the list of newly-infected players so
-- callers (RoundManager) can fire MutagenSystem/InfectionSystem hooks.
function TeamManager.SelectInfected(eligiblePlayers: { Player }): { Player }
	TeamManager.ResetAllToHumans(eligiblePlayers)

	local infectedCount = TeamManager.GetInfectedCountForPopulation(#eligiblePlayers)
	local patientsZero = TeamManager.DrawPatientZero(eligiblePlayers, infectedCount)

	for _, player in ipairs(patientsZero) do
		TeamManager.SetPlayerTeam(player, TeamConfig.INFECTED)
	end

	return patientsZero
end

return TeamManager
