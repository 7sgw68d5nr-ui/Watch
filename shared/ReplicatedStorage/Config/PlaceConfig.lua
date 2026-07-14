--!strict
-- Cross-place IDs. PLACEHOLDER until the places are published — both the Hub
-- and Game place must be updated with real IDs before TeleportService calls
-- (MatchCoordinator, HubTeleportSystem-equivalent) will work.

export type PlaceConfig = {
	HUB_PLACE_ID: number,
	GAME_PLACE_ID: number,
}

local PlaceConfig: PlaceConfig = {
	HUB_PLACE_ID = 0, -- PLACEHOLDER: set once the Hub place is published
	GAME_PLACE_ID = 0, -- PLACEHOLDER: set once the Game place is published
}

return PlaceConfig
