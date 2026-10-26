--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("CatchTheScrapShared"):WaitForChild("Config"))
require(script.Parent:WaitForChild("RobotAnimator")).start()
local remotes = ReplicatedStorage:WaitForChild("CatchTheScrapRemotes")
local actionRemote = remotes:WaitForChild("Action")
local feedbackRemote = remotes:WaitForChild("Feedback")
local gui = Instance.new("ScreenGui")
gui.Name = "CatchTheScrapHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function round(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
end

local panel = Instance.new("Frame")
panel.Position = UDim2.fromOffset(16, 12)
panel.Size = UDim2.new(1, -32, 0, 265)
panel.BackgroundColor3 = Color3.fromRGB(18, 26, 40)
panel.BackgroundTransparency = 0.08
panel.Parent = gui
round(panel, 12)
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(400, 265)
constraint.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(67, 87, 112)
stroke.Parent = panel

local function text(parent, name, y, height, size, color)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = UDim2.fromOffset(14, y)
    label.Size = UDim2.new(1, -28, 0, height)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.fromRGB(230, 238, 248)
    label.Font = Enum.Font.Gotham
    label.TextSize = size
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = parent
    return label
end

local title = text(panel, "Title", 10, 24, 20, Color3.fromRGB(255, 198, 80))
title.Font = Enum.Font.GothamBold
title.Text = "CATCH THE SCRAP"
local home = text(panel, "Home", 38, 22, 14)
local money = text(panel, "Money", 65, 27, 23, Color3.fromRGB(110, 240, 180))
money.Font = Enum.Font.GothamBold
local production = text(panel, "Production", 98, 22, 14, Color3.fromRGB(255, 198, 80))
local progressBackground = Instance.new("Frame")
progressBackground.Position = UDim2.fromOffset(14, 126)
progressBackground.Size = UDim2.new(1, -28, 0, 6)
progressBackground.BackgroundColor3 = Color3.fromRGB(49, 65, 82)
progressBackground.BorderSizePixel = 0
progressBackground.Parent = panel
round(progressBackground, 3)
local progress = Instance.new("Frame")
progress.Size = UDim2.fromScale(0, 1)
progress.BackgroundColor3 = Color3.fromRGB(255, 198, 80)
progress.BorderSizePixel = 0
progress.Parent = progressBackground
round(progress, 3)
local carrying = text(panel, "Carrying", 142, 28, 14)
local stats = text(panel, "Stats", 172, 22, 13, Color3.fromRGB(125, 215, 235))
local message = text(panel, "Message", 202, 51, 13, Color3.fromRGB(190, 205, 225))

local drop = Instance.new("TextButton")
drop.Name = "Drop"
drop.AnchorPoint = Vector2.new(0.5, 1)
drop.Position = UDim2.new(0.5, 0, 1, -24)
drop.Size = UDim2.fromOffset(200, 52)
drop.BackgroundColor3 = Color3.fromRGB(255, 193, 70)
drop.TextColor3 = Color3.fromRGB(20, 28, 40)
drop.Font = Enum.Font.GothamBold
drop.TextSize = 18
drop.Text = if UserInputService.KeyboardEnabled then "Släpp [Q]" else "Släpp föremål"
drop.Visible = false
drop.Parent = gui
round(drop, 12)

local note = text(gui, "SessionNote", 0, 20, 11, Color3.fromRGB(210, 220, 235))
note.AnchorPoint = Vector2.new(0.5, 1)
note.Position = UDim2.new(0.5, 0, 1, -4)
note.Size = UDim2.new(1, -32, 0, 18)
note.TextXAlignment = Enum.TextXAlignment.Center
note.Text = "Prototyp · Scrap, robotar och pengar sparas bara under spelsessionen."

local function layout()
    local camera = workspace.CurrentCamera
    local compact = camera ~= nil and camera.ViewportSize.Y < 500
    panel.AnchorPoint = Vector2.new(if compact then 1 else 0, 0)
    panel.Position = if compact then UDim2.new(1, -16, 0, 8) else UDim2.fromOffset(16, 12)
    panel.Size = UDim2.new(1, -32, 0, if compact then 200 else 265)
    constraint.MaxSize = Vector2.new(if compact then 360 else 400, if compact then 200 else 265)
    local positions = if compact then {
        { title, 6, 21, 16 }, { home, 30, 18, 11 }, { money, 51, 23, 19 },
        { production, 77, 20, 11 }, { carrying, 114, 22, 12 },
        { stats, 140, 18, 11 }, { message, 160, 31, 11 },
    } else {
        { title, 10, 24, 20 }, { home, 38, 22, 14 }, { money, 65, 27, 23 },
        { production, 98, 22, 14 }, { carrying, 142, 28, 14 },
        { stats, 172, 22, 13 }, { message, 202, 51, 13 },
    }
    for _, row in positions do
        row[1].Position = UDim2.fromOffset(14, row[2])
        row[1].Size = UDim2.new(1, -28, 0, row[3])
        row[1].TextSize = row[4]
    end
    progressBackground.Position = UDim2.fromOffset(14, if compact then 103 else 126)
    drop.Size = UDim2.fromOffset(if compact then 180 else 200, if compact then 44 else 52)
end
local viewportConnection
local function watchCamera()
    if viewportConnection then viewportConnection:Disconnect() end
    if workspace.CurrentCamera then
        viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
    end
    layout()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()

local feedbackVersion = 0
local function defaultMessage()
    if not remotes:GetAttribute("Ready") then return "Väntar på spelservern…" end
    if (player:GetAttribute("BaseIndex") or 0) == 0 then return "Alla 8 baser är upptagna. Testa en ny server." end
    if (player:GetAttribute("RobotCount") or 0) >= Config.Robot.Slots then return "Alla robotplatser är fyllda. Dina robotar fortsätter att tjäna pengar!" end
    if (player:GetAttribute("CarriedName") or "") ~= "" then
        return "Gå in i din verkstad och lämna fyndet vid maskinen med orange kant."
    end
    return "Varje fynd ger 1 scrap. Lämna " .. Config.Robot.ScrapPerRobot .. " scrap för att bygga en robot!"
end

local function render()
    local base = player:GetAttribute("BaseIndex") or 0
    local count = player:GetAttribute("DeliveredCount") or 0
    home.Text = string.format("VERKSTAD %s  •  INLÄMNAT: %d", if base > 0 then tostring(base) else "—", count)
    local robots = player:GetAttribute("RobotCount") or 0
    local scrap = player:GetAttribute("ScrapProgress") or 0
    local full = robots >= Config.Robot.Slots
    money.Text = string.format("$%d   +$%d / SEK", player:GetAttribute("Cash") or 0, player:GetAttribute("IncomePerSecond") or 0)
    production.Text = if full then string.format("ROBOTAR %d/%d  •  FULLT UTBYGGD", robots, Config.Robot.Slots) else string.format("ROBOTAR %d/%d  •  NÄSTA: %d/%d SCRAP", robots, Config.Robot.Slots, scrap, Config.Robot.ScrapPerRobot)
    progress.Size = UDim2.fromScale(if full then 1 else scrap / Config.Robot.ScrapPerRobot, 1)
    local name = player:GetAttribute("CarriedName") or ""
    local weight = player:GetAttribute("CarriedWeight") or 0
    local speed = player:GetAttribute("CarrySpeed") or 24
    carrying.Text = if name == "" then "Du har händerna fria." else string.format("%s · %s", name, player:GetAttribute("CarriedRarity") or "")
    stats.Text = string.format("Vikt: %d  •  Fart: %.1f", weight, speed)
    drop.Visible = name ~= ""
    if feedbackVersion == 0 then message.Text = defaultMessage() end
end

local function requestDrop()
    if (player:GetAttribute("CarriedName") or "") ~= "" then actionRemote:FireServer("Drop") end
end
drop.Activated:Connect(requestDrop)
ContextActionService:BindAction("CatchTheScrapDrop", function(_, state)
    if state == Enum.UserInputState.Begin then requestDrop() end
    return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
feedbackRemote.OnClientEvent:Connect(function(value)
    if typeof(value) ~= "string" then return end
    feedbackVersion += 1
    local version = feedbackVersion
    message.Text = value
    task.delay(5, function()
        if feedbackVersion == version then feedbackVersion = 0; message.Text = defaultMessage() end
    end)
end)
for _, attribute in { "BaseIndex", "DeliveredCount", "CarriedName", "CarriedRarity", "CarriedWeight", "CarrySpeed", "Cash", "IncomePerSecond", "RobotCount", "ScrapProgress" } do
    player:GetAttributeChangedSignal(attribute):Connect(render)
end
remotes:GetAttributeChangedSignal("Ready"):Connect(render)
render()
