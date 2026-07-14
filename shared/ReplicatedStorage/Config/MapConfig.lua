--!strict
-- Map registry. Actual geometry lives directly in the Game place's Workspace
-- (not synced via Rojo) and is discovered via CollectionService tags matching
-- each map's TagPrefix, e.g. "Map_Alpha_SafeRoomKey", "Map_Alpha_HumanSpawn".

export type MapDefinition = {
	Id: string,
	DisplayName: string,
	TagPrefix: string,
}

export type MapConfig = {
	Maps: { MapDefinition },
}

local MapConfig: MapConfig = {
	Maps = {
		{ Id = "Map_Alpha", DisplayName = "Alpha", TagPrefix = "Map_Alpha" },
		{ Id = "Map_Beta", DisplayName = "Beta", TagPrefix = "Map_Beta" },
		{ Id = "Map_Gamma", DisplayName = "Gamma", TagPrefix = "Map_Gamma" },
	},
}

return MapConfig
