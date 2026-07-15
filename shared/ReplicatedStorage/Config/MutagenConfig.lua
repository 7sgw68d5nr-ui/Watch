--!strict
-- Mutagen stat profiles. "Base" is the only one applied automatically right
-- now (every Infected uses it) — Rapide/Tank data is fully specified here per
-- the design doc, but the pre-match *selection* logic (MutagenSystem choosing
-- between them, gated by gamepass ownership) is Étape 4 work, not wired yet.

export type MutagenProfile = {
	Id: string,
	DisplayName: string,
	MaxHP: number,
	WalkSpeed: number,
	HitboxScale: number,
	RegenPercent: number, -- fraction of MaxHP regenerated per RegenSystem tick
	MaxStamina: number,
	StaminaRegenPerSec: number,
}

export type MutagenConfig = {
	DEFAULT_PROFILE_ID: string,
	Profiles: { [string]: MutagenProfile },
}

local MutagenConfig: MutagenConfig = {
	DEFAULT_PROFILE_ID = "Base",
	Profiles = {
		Base = {
			Id = "Base",
			DisplayName = "Base",
			MaxHP = 250,
			WalkSpeed = 19.2, -- x1.20 vs human
			HitboxScale = 1.0,
			RegenPercent = 0.10,
			MaxStamina = 120,
			StaminaRegenPerSec = 20,
		},
		Rapide = {
			Id = "Rapide",
			DisplayName = "Rapide",
			MaxHP = 200,
			WalkSpeed = 22, -- +15% vs Base
			HitboxScale = 1.0,
			RegenPercent = 0.15,
			MaxStamina = 120,
			StaminaRegenPerSec = 25,
		},
		Tank = {
			Id = "Tank",
			DisplayName = "Tank",
			MaxHP = 400,
			WalkSpeed = 19.2, -- unchanged vs Base
			HitboxScale = 1.15,
			RegenPercent = 0.10,
			MaxStamina = 100,
			StaminaRegenPerSec = 18,
		},
	},
}

return MutagenConfig
