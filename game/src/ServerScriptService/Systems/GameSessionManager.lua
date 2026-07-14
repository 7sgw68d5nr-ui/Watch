--!strict
-- Match-level orchestration: runs GameConfig.ROUNDS_PER_MATCH rounds back to
-- back on one map via RoundManager, decides who's eligible to play each round
-- (join-lock at GameConfig.JOIN_LOCK_ROUND), and watches for the "down to 1
-- player" immediate-end condition. Everything else about population handling
-- (sub-4-players-continues-normally) falls out naturally from just re-reading
-- Players:GetPlayers() at each round boundary.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Signal)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local TeamConfig = require(ReplicatedStorage.Shared.Config.TeamConfig)
local RoundManager = require(script.Parent.RoundManager)
local TeamManager = require(script.Parent.TeamManager)

local GameSessionManager = {}

GameSessionManager.MatchEnded = Signal.new() -- () -- Phase 6 hooks Hub-return here

local joinLocked = false
local matchInProgress = false
local watchdogConnection: RBXScriptConnection? = nil

local function debugLog(...)
	if GameConfig.DEBUG_LOGGING then
		print("[GameSessionManager]", ...)
	end
end

-- Players who should be treated as "in the match" for the next round: anyone
-- currently connected, unless the match has passed the join-lock round and
-- they weren't already part of it. New joiners after the lock still connect
-- to the server (spectate) but RoundManager never assigns them Human/Infected.
local matchRoster: { [Player]: boolean } = {}

local function getEligiblePlayers(): { Player }
	local eligible = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if matchRoster[player] then
			table.insert(eligible, player)
		end
	end
	return eligible
end

local function onPlayerAdded(player: Player)
	if not joinLocked then
		matchRoster[player] = true
		TeamManager.SetPlayerTeam(player, TeamConfig.HUMANS)
		debugLog(player.Name, "joined the match")
	else
		TeamManager.SetPlayerTeam(player, TeamConfig.SPECTATORS)
		debugLog(player.Name, "joined after lock -> spectating until next match")
	end
end

local function onPlayerRemoving(player: Player)
	matchRoster[player] = nil

	if not matchInProgress then
		return
	end

	local remaining = getEligiblePlayers()
	-- getEligiblePlayers() is read before matchRoster fully reflects the
	-- leaving player's removal from Players:GetPlayers() during this event,
	-- so subtract them explicitly.
	local remainingCount = 0
	for _, p in ipairs(remaining) do
		if p ~= player then
			remainingCount += 1
		end
	end

	if remainingCount <= 1 then
		debugLog("population dropped to", remainingCount, "-> ending match immediately")
		GameSessionManager.EndMatch()
	end
end

function GameSessionManager.StartMatch()
	if matchInProgress then
		warn("[GameSessionManager] StartMatch called while a match is already running")
		return
	end

	matchInProgress = true
	joinLocked = false
	table.clear(matchRoster)

	for _, player in ipairs(Players:GetPlayers()) do
		matchRoster[player] = true
	end

	debugLog("match starting with", #getEligiblePlayers(), "players")

	task.spawn(function()
		for roundNumber = 1, GameConfig.ROUNDS_PER_MATCH do
			if not matchInProgress then
				return
			end

			if roundNumber >= GameConfig.JOIN_LOCK_ROUND then
				joinLocked = true
			end

			local eligible = getEligiblePlayers()
			if #eligible <= 1 then
				debugLog("population too low to continue (", #eligible, ") -> ending match")
				break
			end

			RoundManager.RunRound(roundNumber, eligible)

			-- RunRound resolves synchronously within this coroutine (it awaits
			-- its own internal timers), so by the time control returns here the
			-- round has fully ended and it's safe to move to the next one.
		end

		GameSessionManager.EndMatch()
	end)
end

function GameSessionManager.EndMatch()
	if not matchInProgress then
		return
	end

	matchInProgress = false
	debugLog("match ended")
	GameSessionManager.MatchEnded:Fire()

	-- Phase 5 hooks ProgressionSystem here (award points to matchRoster).
	-- Phase 6 hooks HubTeleport-equivalent here (send matchRoster back to Hub).
	-- Until then, leave everyone on the Game server in RoundEnd state.
end

function GameSessionManager.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

return GameSessionManager
