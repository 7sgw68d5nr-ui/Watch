--!strict
-- Per-round finite state machine: RoundStart -> PreRound(30s) -> InfectedSelection
-- -> InProgress(180s) -> RoundEnd. Owns round win-condition checks and broadcasts
-- every transition via Signal + the RoundStateChanged RemoteEvent so client HUD
-- and other server systems (TeamManager, SafeRoomSystem, ScoringSystem, ...)
-- can react without RoundManager knowing about them directly.
--
-- RoundManager only knows about ONE round at a time. GameSessionManager decides
-- whether there's a next round to start or the match is over.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Signal)
local Net = require(ReplicatedStorage.Modules.Net)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local TeamConfig = require(ReplicatedStorage.Shared.Config.TeamConfig)
local TeamManager = require(script.Parent.TeamManager)

export type RoundState = "RoundStart" | "PreRound" | "InfectedSelection" | "InProgress" | "RoundEnd"
export type RoundWinner = "Humans" | "Infected" | nil

local RoundManager = {}

RoundManager.CurrentState = "RoundStart" :: RoundState
RoundManager.CurrentRound = 0
RoundManager.RoundStateChanged = Signal.new() -- (state: RoundState, roundNumber: number)
RoundManager.RoundEnded = Signal.new() -- (winner: RoundWinner, roundNumber: number)

local activeRoundToken = 0 -- bumped every time a round is (re)started to cancel stale timers/loops

local function debugLog(...)
	if GameConfig.DEBUG_LOGGING then
		print("[RoundManager]", ...)
	end
end

local function setState(state: RoundState)
	RoundManager.CurrentState = state
	debugLog("state ->", state, "round", RoundManager.CurrentRound)
	RoundManager.RoundStateChanged:Fire(state, RoundManager.CurrentRound)
	Net.FireAllClients("RoundStateChanged", state, RoundManager.CurrentRound)
end

-- Win condition: timer elapsed OR Infected team empty (Humans win) OR
-- Humans team empty (Infected win). Returns the winner, or nil if the round
-- should keep running.
local function checkWinCondition(): RoundWinner
	local infectedCount = #TeamManager.GetPlayersOnTeam(TeamConfig.INFECTED)
	local humanCount = #TeamManager.GetPlayersOnTeam(TeamConfig.HUMANS)

	if infectedCount == 0 then
		return "Humans"
	end
	if humanCount == 0 then
		return "Infected"
	end
	return nil
end

-- Called by DamageTracker/InfectionSystem in later phases whenever a kill or
-- infection could change the win state, so RoundManager doesn't have to poll
-- every heartbeat. Safe to call liberally; it's a cheap check.
function RoundManager.CheckWinConditionNow()
	if RoundManager.CurrentState ~= "InProgress" then
		return
	end

	local winner = checkWinCondition()
	if winner ~= nil then
		RoundManager._endRound(winner)
	end
end

function RoundManager._endRound(winner: RoundWinner)
	activeRoundToken += 1
	setState("RoundEnd")
	debugLog("round", RoundManager.CurrentRound, "winner:", winner)
	RoundManager.RoundEnded:Fire(winner, RoundManager.CurrentRound)
end

-- Runs one full round. `eligiblePlayers` is provided fresh by GameSessionManager
-- each round so mid-match joiners/leavers are handled at the boundary, not
-- inside an in-progress round.
function RoundManager.RunRound(roundNumber: number, eligiblePlayers: { Player })
	activeRoundToken += 1
	local myToken = activeRoundToken

	RoundManager.CurrentRound = roundNumber
	setState("RoundStart")

	setState("PreRound")
	task.wait(GameConfig.PRE_ROUND_DURATION)
	if myToken ~= activeRoundToken then
		return
	end

	setState("InfectedSelection")
	TeamManager.SelectInfected(eligiblePlayers)
	-- Give any per-round setup (safe room site pick, spawns, etc.) a beat to
	-- react to InfectedSelection before combat opens up.
	task.wait(1)
	if myToken ~= activeRoundToken then
		return
	end

	setState("InProgress")

	local elapsed = 0
	local pollInterval = 1
	while elapsed < GameConfig.ROUND_DURATION do
		task.wait(pollInterval)
		if myToken ~= activeRoundToken then
			return
		end
		elapsed += pollInterval

		local winner = checkWinCondition()
		if winner ~= nil then
			RoundManager._endRound(winner)
			return
		end
	end

	-- Timer ran out with both teams still alive -> Humans win by survival.
	RoundManager._endRound("Humans")
end

return RoundManager
