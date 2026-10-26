--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
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
panel.Size = UDim2.new(1, -32, 0, 198)
panel.BackgroundColor3 = Color3.fromRGB(18, 26, 40)
panel.BackgroundTransparency = 0.08
panel.Parent = gui
round(panel, 12)
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(400, 198)
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
local carrying = text(panel, "Carrying", 66, 36, 15)
local stats = text(panel, "Stats", 106, 22, 14, Color3.fromRGB(125, 215, 235))
local message = text(panel, "Message", 134, 52, 14, Color3.fromRGB(190, 205, 225))

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
note.Text = "Prototyp · Inlämnade fynd sparas bara under den här spelsessionen."

local feedbackVersion = 0
local function defaultMessage()
    if not remotes:GetAttribute("Ready") then return "Väntar på spelservern…" end
    if (player:GetAttribute("BaseIndex") or 0) == 0 then return "Alla 8 baser är upptagna. Testa en ny server." end
    if (player:GetAttribute("CarriedName") or "") ~= "" then
        return "Tillbaka till din orange inlämningsplatta! Tryck E eller på skärmen."
    end
    return "Spring ut på banan. Gå nära ett fynd och håll E eller tryck på skärmen."
end

local function render()
    local base = player:GetAttribute("BaseIndex") or 0
    local count = player:GetAttribute("DeliveredCount") or 0
    home.Text = string.format("DIN BAS: %s  •  INLÄMNAT: %d", if base > 0 then tostring(base) else "—", count)
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
for _, attribute in { "BaseIndex", "DeliveredCount", "CarriedName", "CarriedRarity", "CarriedWeight", "CarrySpeed" } do
    player:GetAttributeChangedSignal(attribute):Connect(render)
end
remotes:GetAttributeChangedSignal("Ready"):Connect(render)
render()
