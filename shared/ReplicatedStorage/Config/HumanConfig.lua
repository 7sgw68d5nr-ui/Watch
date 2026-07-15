--!strict
-- Base Human stats. Infected base stats live in MutagenConfig (the "Base"
-- mutagen entry) since every infected is always running some mutagen profile
-- - there's no separate "infected base" stat block outside that table.

export type HumanConfig = {
	MAX_HP: number,
	WALK_SPEED: number,
	SPRINT_SPEED: number,
	MAX_STAMINA: number,
	SPRINT_DRAIN_PER_SEC: number,
	SPRINT_MAX_DURATION: number,
	STAMINA_REGEN_PER_SEC: number,
	JUMP_STAMINA_COST: number,
	MIN_STAMINA_TO_JUMP: number,
	CROUCH_SPEED_MULTIPLIER: number,
	CROUCH_CAMERA_DROP: number, -- studs
}

local HumanConfig: HumanConfig = {
	MAX_HP = 100,
	WALK_SPEED = 16,
	SPRINT_SPEED = 22.4, -- x1.4
	MAX_STAMINA = 100,
	SPRINT_DRAIN_PER_SEC = 20, -- empties in 5s
	SPRINT_MAX_DURATION = 5,
	STAMINA_REGEN_PER_SEC = 15,
	JUMP_STAMINA_COST = 10,
	MIN_STAMINA_TO_JUMP = 10,
	CROUCH_SPEED_MULTIPLIER = 0.35,
	CROUCH_CAMERA_DROP = 2,
}

return HumanConfig
