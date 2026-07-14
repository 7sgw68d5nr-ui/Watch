--!strict
-- Phase 1 debug HUD: shows current round state/number so RoundManager's FSM
-- can be verified visually in Studio without digging through the output log.
-- Replaced by the full HUDController (health/stamina/ammo/scoreboard) in
-- later phases; kept intentionally bare-bones here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Modules.Net)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DebugHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local label = Instance.new("TextLabel")
label.Name = "RoundStateLabel"
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 10)
label.Size = UDim2.new(0, 400, 0, 40)
label.BackgroundTransparency = 0.3
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.TextColor3 = Color3.new(1, 1, 1)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = "Waiting for round state..."
label.Parent = screenGui

Net.OnClientEvent("RoundStateChanged", function(state: string, roundNumber: number)
	label.Text = string.format("Round %d — %s", roundNumber, state)
end)
