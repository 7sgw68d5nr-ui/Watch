--!strict
-- Game place bootstrap. Requires systems in dependency order and starts the
-- match loop.
--
-- Load order: low-level movement/damage plumbing first (WeightSystem,
-- StaminaSystem, CrouchSystem, DamageTracker), then things that depend on
-- them (RegenSystem, InfectionSystem, WeaponSystem, KnifeSystem,
-- FallDamageSystem), then the round/match orchestration that ties it all
-- together (TeamManager, RoundManager, GameSessionManager).

local ServerScriptService = game:GetService("ServerScriptService")

local Systems = ServerScriptService.Systems

local WeightSystem = require(Systems.WeightSystem)
local StaminaSystem = require(Systems.StaminaSystem)
local CrouchSystem = require(Systems.CrouchSystem)
local DamageTracker = require(Systems.DamageTracker)
local RegenSystem = require(Systems.RegenSystem)
local InfectionSystem = require(Systems.InfectionSystem)
local WeaponSystem = require(Systems.WeaponSystem)
local KnifeSystem = require(Systems.KnifeSystem)
local FallDamageSystem = require(Systems.FallDamageSystem)
local TeamManager = require(Systems.TeamManager)
local GameSessionManager = require(Systems.GameSessionManager)

WeightSystem.Init()
StaminaSystem.Init()
CrouchSystem.Init()
DamageTracker.Init()
RegenSystem.Init()
InfectionSystem.Init()
WeaponSystem.Init()
KnifeSystem.Init()
FallDamageSystem.Init()
TeamManager.Init()
GameSessionManager.Init()

-- CrouchSystem needs its remote wired explicitly (it has no other trigger).
do
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Net = require(ReplicatedStorage.Modules.Net)
	Net.OnServerEvent("RequestCrouch", function(player: Player, isCrouching: boolean)
		CrouchSystem.SetCrouching(player, isCrouching)
	end)
	Net.OnServerEvent("RequestSprint", function(player: Player, wantsSprint: boolean)
		StaminaSystem.RequestSprint(player, wantsSprint)
	end)
end

-- Phase 1 debug-only auto-start: begins a match as soon as the minimum
-- population is present. Real Hub-driven session start (via
-- SessionRegistration/MatchCoordinator) replaces this in Étape 5.
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

print("[Init] Quarantine Regen Game place bootstrapped (Étape 1 complète + début Étape 2 : armes/combat humain)")
