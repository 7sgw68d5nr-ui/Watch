--!strict
-- Single chokepoint for all damage in the game. WeaponSystem, KnifeSystem,
-- InfectionSystem (claw), ExplosiveSystem, and FallDamageSystem all call
-- DamageTracker:ApplyDamage(...) instead of touching Humanoid.Health
-- directly. This is also where the rolling-window damage log lives, which
-- Étape 3's ScoringSystem will read to compute assists (>=20% of cumulative
-- damage within 12s of the attacker's last hit).
--
-- Callers are responsible for their own damage math (headshot multipliers,
-- shotgun falloff, etc.) — this module just applies a final number and logs it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Signal)

export type DamageType = "Weapon" | "Knife" | "Claw" | "Explosive" | "Fall"

export type DamageEvent = {
	attacker: Player?, -- nil for environmental damage (fall damage has no attacker)
	amount: number,
	timestamp: number,
	damageType: DamageType,
}

local DamageTracker = {}

local ASSIST_WINDOW_SECONDS = 12
local ASSIST_THRESHOLD_FRACTION = 0.20

-- victim -> ordered list of DamageEvent (oldest first)
local damageLogs: { [Player]: { DamageEvent } } = {}

DamageTracker.DamageApplied = Signal.new() -- (attacker, victim, amount, damageType)
DamageTracker.PlayerDied = Signal.new() -- (victim, killer: Player?, damageType)

local function getHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local function pruneOldEvents(victim: Player)
	local log = damageLogs[victim]
	if not log then
		return
	end

	local cutoff = os.clock() - ASSIST_WINDOW_SECONDS
	local pruned = {}
	for _, event in ipairs(log) do
		if event.timestamp >= cutoff then
			table.insert(pruned, event)
		end
	end
	damageLogs[victim] = pruned
end

-- Returns true if `amount` is positive and the humanoid exists/is alive;
-- false-y results mean the caller should treat this as a no-op (e.g. hitting
-- an already-dead body).
function DamageTracker:ApplyDamage(attacker: Player?, victim: Player, amount: number, damageType: DamageType): boolean
	if amount <= 0 then
		return false
	end

	local humanoid = getHumanoid(victim)
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	damageLogs[victim] = damageLogs[victim] or {}
	table.insert(damageLogs[victim], {
		attacker = attacker,
		amount = amount,
		timestamp = os.clock(),
		damageType = damageType,
	})
	pruneOldEvents(victim)

	humanoid:TakeDamage(amount)

	self.DamageApplied:Fire(attacker, victim, amount, damageType)

	if humanoid.Health <= 0 then
		self.PlayerDied:Fire(victim, attacker, damageType)
	end

	return true
end

-- Assist rule: any attacker (other than the killer) whose cumulative damage
-- within the rolling 12s window is >=20% of the victim's cumulative logged
-- damage in that same window. The killer is NOT included here — ScoringSystem
-- awards the killer's points unconditionally and calls this only for assists.
function DamageTracker:GetAssists(victim: Player, killer: Player?): { Player }
	pruneOldEvents(victim)
	local log = damageLogs[victim]
	if not log or #log == 0 then
		return {}
	end

	local totalByAttacker: { [Player]: number } = {}
	local totalDamage = 0

	for _, event in ipairs(log) do
		if event.attacker then
			totalByAttacker[event.attacker] = (totalByAttacker[event.attacker] or 0) + event.amount
			totalDamage += event.amount
		end
	end

	if totalDamage <= 0 then
		return {}
	end

	local assists = {}
	for attacker, amount in pairs(totalByAttacker) do
		if attacker ~= killer and (amount / totalDamage) >= ASSIST_THRESHOLD_FRACTION then
			table.insert(assists, attacker)
		end
	end

	return assists
end

function DamageTracker:ClearLog(victim: Player)
	damageLogs[victim] = nil
end

function DamageTracker.Init()
	local Players = game:GetService("Players")
	Players.PlayerRemoving:Connect(function(player)
		damageLogs[player] = nil
	end)
end

return DamageTracker
