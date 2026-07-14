--!strict
-- Match-level constants. RoundManager/GameSessionManager read from here rather
-- than hardcoding timings so the whole match flow is tunable in one place.

export type GameConfig = {
	MIN_PLAYERS_TO_START: number,
	MAX_PLAYERS: number,
	ROUNDS_PER_MATCH: number,
	JOIN_LOCK_ROUND: number, -- players can no longer join once this round has started
	PRE_ROUND_DURATION: number,
	ROUND_DURATION: number,
	INFECTED_COUNT_THRESHOLD: number, -- 9+ players = 2 infected, else 1
	INFECTED_COUNT_HIGH: number,
	INFECTED_COUNT_LOW: number,
	HUMAN_TO_INFECTED_DELAY: number, -- delay after a confirmed claw hit
	DEBUG_LOGGING: boolean,
}

local GameConfig: GameConfig = {
	MIN_PLAYERS_TO_START = 4,
	MAX_PLAYERS = 16,
	ROUNDS_PER_MATCH = 5,
	JOIN_LOCK_ROUND = 3,
	PRE_ROUND_DURATION = 30,
	ROUND_DURATION = 180,
	INFECTED_COUNT_THRESHOLD = 9,
	INFECTED_COUNT_HIGH = 2,
	INFECTED_COUNT_LOW = 1,
	HUMAN_TO_INFECTED_DELAY = 0.5,
	DEBUG_LOGGING = true,
}

return GameConfig
