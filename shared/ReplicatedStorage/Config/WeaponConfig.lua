--!strict
-- Per-weapon combat data. Slot numbers match the spec: 1=primary, 2=secondary,
-- 3=knife (always available), 4=explosive (see ExplosiveConfig, Phase 4).
--
-- Caliber ("Small"/"Large") drives the hit-reaction applied by WeaponSystem:
-- Small = brief slow on the infected hit, Large = knockback impulse.

export type Caliber = "Small" | "Large" | "Melee"

export type WeaponDefinition = {
	Id: string,
	Slot: number,
	DisplayName: string,
	DamagePerShot: number,
	RPM: number,
	MagazineSize: number,
	ReloadTime: number,
	Caliber: Caliber,
	WeightPercent: number, -- negative = speed penalty, e.g. -0.05 = -5%
	SwitchTime: number,
	HeadshotMultiplier: number,
	-- Shotgun-only falloff; nil for every other weapon (spec: falloff not
	-- implemented anywhere else yet).
	Falloff: {
		FullDamageRange: number,
		MinDamageRange: number,
		MinDamageMultiplier: number,
	}?,
	SmallCaliberSlow: { Multiplier: number, Duration: number }?, -- e.g. 10% slow for 0.3s
	LargeCaliberKnockback: number?, -- studs
}

export type WeaponConfig = {
	Weapons: { [string]: WeaponDefinition },
}

local WeaponConfig: WeaponConfig = {
	Weapons = {
		Pistol = {
			Id = "Pistol",
			Slot = 2,
			DisplayName = "Pistolet",
			DamagePerShot = 32,
			RPM = 240,
			MagazineSize = 12,
			ReloadTime = 1.5,
			Caliber = "Small",
			WeightPercent = -0.05,
			SwitchTime = 0.3,
			HeadshotMultiplier = 2,
			SmallCaliberSlow = { Multiplier = 0.9, Duration = 0.3 },
		},
		SMG = {
			Id = "SMG",
			Slot = 2,
			DisplayName = "SMG",
			DamagePerShot = 26,
			RPM = 600,
			MagazineSize = 30,
			ReloadTime = 2,
			Caliber = "Small",
			WeightPercent = -0.08,
			SwitchTime = 0.35,
			HeadshotMultiplier = 2,
			SmallCaliberSlow = { Multiplier = 0.9, Duration = 0.3 },
		},
		AssaultRifle = {
			Id = "AssaultRifle",
			Slot = 1,
			DisplayName = "Fusil d'assaut",
			DamagePerShot = 25,
			RPM = 420,
			MagazineSize = 30,
			ReloadTime = 2.5,
			Caliber = "Small",
			WeightPercent = -0.12,
			SwitchTime = 0.45,
			HeadshotMultiplier = 2,
			SmallCaliberSlow = { Multiplier = 0.9, Duration = 0.3 },
		},
		Shotgun = {
			Id = "Shotgun",
			Slot = 1,
			DisplayName = "Fusil à pompe",
			DamagePerShot = 12.5, -- point-blank; Falloff below degrades this with range
			RPM = 60,
			MagazineSize = 6,
			ReloadTime = 3,
			Caliber = "Large",
			WeightPercent = -0.15,
			SwitchTime = 0.5,
			HeadshotMultiplier = 2,
			Falloff = {
				FullDamageRange = 10,
				MinDamageRange = 40,
				MinDamageMultiplier = 0.2,
			},
			LargeCaliberKnockback = 2,
		},
		MachineGun = {
			Id = "MachineGun",
			Slot = 1,
			DisplayName = "Mitrailleuse",
			DamagePerShot = 22.5,
			RPM = 480,
			MagazineSize = 75,
			ReloadTime = 4,
			Caliber = "Large",
			WeightPercent = -0.30,
			SwitchTime = 0.7,
			HeadshotMultiplier = 2,
			LargeCaliberKnockback = 1,
		},
		Knife = {
			Id = "Knife",
			Slot = 3,
			DisplayName = "Couteau",
			DamagePerShot = 25, -- PLACEHOLDER, never locked per spec
			RPM = 0, -- melee, driven by KnifeSystem cooldown instead of RPM
			MagazineSize = 0,
			ReloadTime = 0,
			Caliber = "Melee",
			WeightPercent = 0,
			SwitchTime = 0.2,
			HeadshotMultiplier = 2,
		},
	},
}

return WeaponConfig
