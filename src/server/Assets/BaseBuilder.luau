--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.CatchTheScrapShared
local Config = require(Shared.Config)
local Blueprint = require(Shared.BaseBlueprint)
local RobotBuilder = require(script.Parent.RobotBuilder)
local BaseBuilder = {}

local function color(name, accent)
    return if name == "accent" then accent else Color3.fromRGB(unpack(Config.Palette[name]))
end

local function part(parent, name, size, cframe, tint, material, collidable)
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.CFrame = cframe
    object.Color = tint
    object.Material = material
    object.Anchored = true
    object.CanCollide = collidable
    object.CanTouch = false
    object.CanQuery = collidable
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = parent
    return object
end

local function surfaceLabel(board, text, tint)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Back -- The workshop's front is local +Z.
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 28
    gui.LightInfluence = 0
    gui.MaxDistance = 150
    gui.Parent = board
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(0.96, 0.86)
    label.Position = UDim2.fromScale(0.02, 0.03)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = tint
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui
    return label
end

function BaseBuilder.create(parent, index, origin)
    local folder = Instance.new("Model")
    folder.Name = "Workshop" .. index
    folder.Parent = parent
    local accent = Color3.fromRGB(unpack(Config.BaseAccents[(index - 1) % #Config.BaseAccents + 1]))
    local pieces = {}
    for _, definition in Blueprint do
        pieces[definition.name] = part(folder, definition.name, Vector3.new(unpack(definition.size)),
            origin * CFrame.new(unpack(definition.position)) * CFrame.Angles(0, math.rad(definition.yaw), 0),
            color(definition.palette, accent), Enum.Material[definition.material], definition.collidable)
    end
    -- A short hazard-marked approach gives the hopper a clear visual target.
    for n = -3, 3 do
        part(folder, "HazardStripe", Vector3.new(0.65, 0.03, 3), origin * CFrame.new(n * 1.25, 0.51, -5.5) * CFrame.Angles(0, math.rad(25), 0), color("amber", accent), Enum.Material.SmoothPlastic, false)
    end
    local ownerLabel = surfaceLabel(pieces.GateHeader, "VERKSTAD " .. index .. "  /  LEDIG", accent)
    local progressLabel = surfaceLabel(pieces.ProgressBoard, "LÄMNA SCRAP HÄR\n0 / 10", color("amber", accent))
    local bar = Instance.new("Frame")
    bar.Size = UDim2.fromScale(0, 0.06)
    bar.Position = UDim2.fromScale(0.02, 0.91)
    bar.BorderSizePixel = 0
    bar.BackgroundColor3 = accent
    bar.Parent = progressLabel.Parent
    local deposit = part(folder, "Deposit", Vector3.new(8, 3, 1), origin * CFrame.new(0, 2.8, -7.5), accent, Enum.Material.SmoothPlastic, false)
    deposit.Transparency = 1
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Lämna scrap"
    prompt.ObjectText = "Ledig verkstad"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0.25
    prompt.MaxActivationDistance = Config.InteractionDistance
    prompt.RequiresLineOfSight = true
    prompt.Enabled = false
    prompt.Parent = deposit
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "Spawn"
    spawn.Size = Vector3.new(6, 0.2, 6)
    spawn.CFrame = origin * CFrame.new(0, 0.6, 9) * CFrame.Angles(0, math.pi, 0)
    spawn.Transparency = 1
    spawn.Anchored = true
    spawn.CanCollide = false
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Parent = folder
    local robots = Instance.new("Folder")
    robots.Name = "Robots"
    robots.Parent = folder
    local pads = {}
    for slot = 1, Config.Robot.Slots do
        local x = if slot % 2 == 1 then -16 else 16
        local z = if slot <= 2 then -12 else 8
        local center = origin * CFrame.new(x, 0.75, z)
        local platform = part(folder, "RobotPad" .. slot, Vector3.new(0.5, 12, 12), center * CFrame.Angles(0, 0, math.pi / 2), color("dark", accent), Enum.Material.Metal, true)
        platform.Shape = Enum.PartType.Cylinder
        local ring = part(folder, "PadLight" .. slot, Vector3.new(0.08, 12.1, 12.1), center * CFrame.new(0, 0.24, 0) * CFrame.Angles(0, 0, math.pi / 2), accent, Enum.Material.Neon, false)
        ring.Shape = Enum.PartType.Cylinder
        local cap = part(folder, "PadCap" .. slot, Vector3.new(0.08, 10.7, 10.7), center * CFrame.new(0, 0.30, 0) * CFrame.Angles(0, 0, math.pi / 2), color("floor", accent), Enum.Material.DiamondPlate, false)
        cap.Shape = Enum.PartType.Cylinder
        local placard = part(folder, "SlotSign" .. slot, Vector3.new(10, 1.7, 0.2), origin * CFrame.new(x, 1.4, z + 6.5), color("black", accent), Enum.Material.SmoothPlastic, false)
        local label = surfaceLabel(placard, "PLATS " .. slot, accent)
        table.insert(pads, { origin = origin * CFrame.new(x, 1.05, z), label = label, model = nil })
    end
    return { index = index, owner = nil, origin = origin, folder = folder, spawn = spawn, deposit = deposit, prompt = prompt,
        label = ownerLabel, progressLabel = progressLabel, progressBar = bar, pads = pads, robots = robots, visualKey = "", accent = accent }
end

function BaseBuilder.update(base, displayName, account)
    if not account then
        base.label.Text = "VERKSTAD " .. base.index .. "  /  LEDIG"
        base.progressLabel.Text = "LÄMNA SCRAP HÄR\n0 / " .. Config.Robot.ScrapPerRobot
        base.progressBar.Size = UDim2.fromScale(0, 0.06)
        base.visualKey = ""
        base.robots:ClearAllChildren()
        for slot, pad in base.pads do pad.model = nil; pad.label.Text = "PLATS " .. slot end
        return
    end
    local rate = account.robots * Config.Robot.IncomePerRobot
    base.label.Text = string.format("%s  /  VERKSTAD %02d\n%d ROBOTAR  •  $%d / SEK", displayName, base.index, account.robots, rate)
    local full = account.robots >= Config.Robot.Slots
    base.progressLabel.Text = if full then string.format("VERKSTADEN ÄR FULL\n%d ROBOTAR IGÅNG", Config.Robot.Slots) else string.format("NÄSTA ROBOT\n%d / %d SCRAP", account.scrap, Config.Robot.ScrapPerRobot)
    base.progressBar.Size = UDim2.fromScale(if full then 0.96 else 0.96 * account.scrap / Config.Robot.ScrapPerRobot, 0.06)
    local key = account.robots .. ":" .. account.scrap
    if key == base.visualKey then return end
    base.visualKey = key
    for slot, pad in base.pads do
        local complete = slot <= account.robots
        local active = slot == account.robots + 1 and not full
        local stage = if complete then 10 else math.floor(account.scrap / Config.Robot.ScrapPerRobot * 10)
        -- Preserve existing finished models and their client effects.
        if complete and pad.model and pad.model:GetAttribute("Complete") then continue end
        if pad.model then pad.model:Destroy(); pad.model = nil end
        if complete or active then
            pad.model = RobotBuilder.build(base.robots, pad.origin, stage, complete)
            pad.label.Text = if complete then "MK-I  /  $" .. Config.Robot.IncomePerRobot .. " PER SEK" else string.format("BYGGER  /  %d AV %d", account.scrap, Config.Robot.ScrapPerRobot)
        else
            pad.label.Text = "PLATS " .. slot .. "  /  LEDIG"
        end
    end
end

return BaseBuilder
