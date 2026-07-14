--!strict
-- Game place bootstrap. Requires systems in dependency order and starts the
-- match loop. Later phases will add more requires here (StaminaSystem,
-- WeaponSystem, InfectionSystem, ...) but the load order convention is:
-- config/utility modules (already required by the systems that need them) ->
-- TeamManager -> RoundManager -> GameSessionManager -> start.

local ServerScriptService = game:GetService("ServerScriptService")

local Systems = ServerScriptService.Systems

local TeamManager = require(Systems.TeamManager)
local GameSessionManager = require(Systems.GameSessionManager)

TeamManager.Init()
GameSessionManager.Init()

-- Phase 1 debug-only auto-start: begins a match as soon as the minimum
-- population is present. Real Hub-driven session start (via
-- SessionRegistration/MatchCoordinator) replaces this in Phase 6.
local Players = game:GetService("Players")
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.Config.GameConfig)

local matchStarted = false

local function tryAutoStart()
	if matchStarted then
		return
	end
	if #Players:GetPlayers() >= GameConfig.MIN_PLAYERS_TO_START then
		matchStarted = true
		GameSessionManager.StartMatch()
	end
end

Players.PlayerAdded:Connect(tryAutoStart)
tryAutoStart()

print("[Init] Quarantine Regen Game place bootstrapped (Phase 1: round FSM, no combat)")
