--!strict
-- Team identity used by TeamManager. Kept as plain names (not Team instances)
-- so this module has zero Roblox-service dependencies and stays easy to require
-- from both places and from tests.

export type TeamConfig = {
	HUMANS: string,
	INFECTED: string,
	SPECTATORS: string,
	COLORS: { [string]: Color3 },
}

local TeamConfig: TeamConfig = {
	HUMANS = "Humans",
	INFECTED = "Infected",
	SPECTATORS = "Spectators",
	COLORS = {
		Humans = Color3.fromRGB(70, 130, 220),
		Infected = Color3.fromRGB(180, 40, 40),
		Spectators = Color3.fromRGB(150, 150, 150),
	},
}

return TeamConfig
