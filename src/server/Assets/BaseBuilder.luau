--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.CatchTheScrapShared
local Config = require(Shared.Config)
local Blueprint = require(Shared.BaseBlueprint)
local RobotBuilder = require(script.Parent.RobotBuilder)
local Economy = require(Shared.Economy)
local FloatingText = require(script.Parent.FloatingText)
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
    label.AutoLocalize = false
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
    local ownerLabel = surfaceLabel(pieces.GateHeader, "WORKSHOP " .. index .. "  /  UNCLAIMED", accent)
    pieces.ProgressBoard.Transparency = 1
    pieces.ProgressBoard.CastShadow = false
    local progressLabel = FloatingText.create(folder,"BuildProgress",origin*CFrame.new(0,7,-16),"DEPOSIT MATCHING PARTS\nCOMMON 0/5  |  RARE 0/10",color("amber",accent),16,4,65)
    local deposit = part(folder, "Deposit", Vector3.new(8, 3, 1), origin * CFrame.new(0, 2.8, -7.5), accent, Enum.Material.SmoothPlastic, false)
    deposit.Transparency = 1
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Deposit part"
    prompt.AutoLocalize = false
    prompt.ObjectText = "Unclaimed workshop"
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
        local label = FloatingText.create(folder,"SlotLabel"..slot,origin*CFrame.new(x,2.5,z+6.5),"SLOT "..slot,accent,10,1.5,45)
        table.insert(pads, { origin = origin * CFrame.new(x, 1.05, z), label = label, model = nil, key = "" })
    end
    return { index = index, owner = nil, origin = origin, folder = folder, spawn = spawn, deposit = deposit, prompt = prompt,
        label = ownerLabel, progressLabel = progressLabel, pads = pads, robots = robots, visualKey = "", accent = accent }
end

function BaseBuilder.update(base, displayName, account)
    if not account then
        base.label.Text = "WORKSHOP " .. base.index .. "  /  UNCLAIMED"
        base.progressLabel.Text = "DEPOSIT MATCHING PARTS\nCOMMON 0/5  |  RARE 0/10"
        base.robots:ClearAllChildren()
        for slot, pad in base.pads do pad.model=nil; pad.key=""; pad.label.Text="SLOT "..slot end
        return
    end
    base.label.Text = string.format("%s  /  WORKSHOP %02d\n%d ROBOTS  |  $%d / SEC",displayName,base.index,Economy.robotCount(account),Economy.incomePerSecond(account,Config.Robot))
    base.progressLabel.Text = string.format("MATCHING PARTS ONLY\nC %d/5  |  U %d/7  |  R %d/10",Economy.progress(account,"Common"),Economy.progress(account,"Uncommon"),Economy.progress(account,"Rare"))
    for slot, pad in base.pads do
        local project = account.projects[slot]
        local key = if project then project.rarity..":"..project.parts else "empty"
        if key == pad.key then continue end
        pad.key=key
        if pad.model then pad.model:Destroy(); pad.model=nil end
        if project then
            local recipe=Config.Robot.Recipes[project.rarity]
            local stage=if project.complete then 5 else math.floor(project.parts/recipe.Parts*5)
            pad.model=RobotBuilder.build(base.robots,pad.origin,stage,project.complete,project.rarity)
            pad.label.Text=if project.complete then project.rarity:upper().." / $"..recipe.Income.." PER SEC" else string.format("%s / %d OF %d",project.rarity:upper(),project.parts,recipe.Parts)
            pad.label.TextColor3=Color3.fromRGB(unpack(recipe.Color))
        else
            pad.label.Text="SLOT "..slot.." / AVAILABLE"
        end
    end
end

return BaseBuilder
