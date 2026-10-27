--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.CatchTheScrapShared
local Config = require(Shared.Config)
local Blueprint = require(Shared.BaseBlueprint)
local WorkshopLayout = require(Shared.WorkshopLayout)
local RobotBuilder = require(script.Parent.RobotBuilder)
local Economy = require(Shared.Economy)
local FloatingText = require(script.Parent.FloatingText)
local CrusherBuilder=require(script.Parent.CrusherBuilder)
local CrateBuilder=require(script.Parent.CrateBuilder)
local Catalog=require(Shared.RobotCatalog)
local Style=require(Shared.RarityStyle)
local Rewards=require(Shared.DexRewards)
local Mutations=require(Shared.Mutations)
local Decor=require(script.Parent.RarityDecor)
local Tags=game:GetService("CollectionService")
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
    folder.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
    folder.Parent = parent
    local accent = Color3.fromRGB(unpack(Config.BaseAccents[(index - 1) % #Config.BaseAccents + 1]))
    local pieces = {}
    local accentParts = {}
    for _, definition in Blueprint do
        pieces[definition.name] = part(folder, definition.name, Vector3.new(unpack(definition.size)),
            origin * CFrame.new(unpack(definition.position)) * CFrame.Angles(0, math.rad(definition.yaw), 0),
            color(definition.palette, accent), Enum.Material[definition.material], definition.collidable)
        if definition.palette == "accent" then table.insert(accentParts, pieces[definition.name]) end
    end
    CrusherBuilder.create(folder,origin)
    -- A short hazard-marked approach gives the hopper a clear visual target.
    for n = -3, 3 do
        part(folder, "HazardStripe", Vector3.new(0.65, 0.03, 3), origin * CFrame.new(n * 1.25, 0.51, -5.5) * CFrame.Angles(0, math.rad(25), 0), color("amber", accent), Enum.Material.SmoothPlastic, false)
    end
    local ownerLabel = surfaceLabel(pieces.GateHeader, "WORKSHOP " .. index .. "  /  UNCLAIMED", accent)
    pieces.ProgressBoard.Transparency = 1
    pieces.ProgressBoard.CastShadow = false
    local progressLabel = FloatingText.create(folder,"BuildProgress",origin*CFrame.new(0,7,-16),"DEPOSIT MATCHING PARTS\n7 RARITIES / "..Config.Robot.Slots.." ROBOT PLATFORMS",color("amber",accent),16,4,65)
    local deposit = part(folder, "Deposit", Vector3.new(8, 3, 1), origin * CFrame.new(0, 2.8, -7.5), accent, Enum.Material.SmoothPlastic, false)
    deposit.Transparency = 1
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Deliver scrap or box"
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
    local padSize = Config.Workshops.PadDiameter
    for slot = 1, Config.Robot.MaxSlots do
        local layout = WorkshopLayout.Pads[slot]
        local x, z = layout.x, layout.z
        local center = origin * CFrame.new(x, 0.75, z)
        local platform = part(folder, "RobotPad" .. slot, Vector3.new(0.5, padSize, padSize), center * CFrame.Angles(0, 0, math.pi / 2), color("dark", accent), Enum.Material.Metal, true)
        platform.Shape = Enum.PartType.Cylinder
        local ring = part(folder, "PadLight" .. slot, Vector3.new(0.08, padSize + 0.1, padSize + 0.1), center * CFrame.new(0, 0.24, 0) * CFrame.Angles(0, 0, math.pi / 2), accent, Enum.Material.Neon, false)
        ring.Shape = Enum.PartType.Cylinder
        table.insert(accentParts, ring)
        local cap = part(folder, "PadCap" .. slot, Vector3.new(0.08, padSize - 1.3, padSize - 1.3), center * CFrame.new(0, 0.30, 0) * CFrame.Angles(0, 0, math.pi / 2), color("floor", accent), Enum.Material.DiamondPlate, false)
        cap.Shape = Enum.PartType.Cylinder
        local label = FloatingText.create(folder,"SlotLabel"..slot,origin*CFrame.new(x,2.5,z+padSize/2+1),"SLOT "..slot,accent,10,1.5,45)
        table.insert(pads, { origin = origin * CFrame.new(x, 1.05, z), label = label, model = nil, key = "", ring = ring, cap = cap })
    end
    return { index = index, owner = nil, origin = origin, folder = folder, spawn = spawn, deposit = deposit, prompt = prompt,
        label = ownerLabel, progressLabel = progressLabel, pads = pads, robots = robots, visualKey = "", accent = accent, accentParts = accentParts, skin = "Default" }
end

-- Robotdex workshop skins recolor the neon trim and platform rings.
function BaseBuilder.applySkin(base, skinId)
    local skin = Rewards.Skins[skinId] or Rewards.Skins.Default
    base.skin = if Rewards.Skins[skinId] then skinId else "Default"
    local tint = if skin.Color then Color3.fromRGB(unpack(skin.Color)) else base.accent
    for index, object in base.accentParts do
        if skin.Rainbow then Decor.spectrum(object, index / #base.accentParts) else Tags:RemoveTag(object, "RaritySpectrum") end
        object.Color = tint
    end
    base.label.TextColor3 = tint
end

function BaseBuilder.update(base, displayName, account)
    if not account then
        base.label.Text = "WORKSHOP " .. base.index .. "  /  UNCLAIMED"
        base.progressLabel.Text = "DEPOSIT MATCHING PARTS\n7 RARITIES / "..Config.Robot.Slots.." ROBOT PLATFORMS"
        base.robots:ClearAllChildren()
        for slot, pad in base.pads do
            pad.model=nil; pad.key=""; pad.label.Text="SLOT "..slot
            local locked = slot > Config.Robot.Slots
            pad.ring.Transparency = if locked then .75 else 0; pad.cap.Transparency = if locked then .4 else 0
        end
        return
    end
    local rebirthText = if account.rebirths > 0 then string.format("  |  REBIRTH %d", account.rebirths) else ""
    base.label.Text = string.format("%s  /  WORKSHOP %02d\n%d ROBOTS  |  $%d / SEC%s",displayName,base.index,Economy.robotCount(account),math.floor(Economy.incomePerSecond(account,Config.Robot)),rebirthText)
    local unlocked = Economy.slots(account, Config.Robot)
    local active={}
    for _,project in account.projects do
        if not project.complete and not project.opening then table.insert(active,string.format("%s %d/%d",project.rarity:upper(),project.parts,Config.Robot.Recipes[project.rarity].Parts)) end
    end
    base.progressLabel.Text = if #active>0 then "ASSEMBLY / "..table.concat(active," | ") else "DEPOSIT MATCHING PARTS\n7 RARITIES / "..Config.Robot.Slots.." ROBOT PLATFORMS"
    for slot, pad in base.pads do
        local project = account.projects[slot]
        local locked = slot > unlocked
        pad.ring.Transparency = if locked then .75 else 0; pad.cap.Transparency = if locked then .4 else 0
        local key = if project then tostring(project.id)..":"..tostring(project.variant)..":"..tostring(project.mutation)..":"..project.rarity..":"..project.parts..(if project.opening then ":opening" else ":ready") elseif locked then "locked" else "empty"
        if key == pad.key then continue end
        pad.key=key
        if pad.model then pad.model:Destroy(); pad.model=nil end
        if project then
            local recipe=Config.Robot.Recipes[project.rarity]
            if project.opening then
                pad.model=CrateBuilder.display(base.robots,pad.origin*CFrame.new(0,2.35,0),project.startedAt,project.rarity)
                pad.label.Text=project.rarity:upper().." ROBOT / UNBOXING...";pad.label.TextColor3=Color3.fromRGB(235,194,121)
                continue
            end
            local stage=if project.complete then 5 else math.floor(project.parts/recipe.Parts*5)
            pad.model=RobotBuilder.build(base.robots,pad.origin,stage,project.complete,project.rarity,nil,project.variant,if project.recovered then "Box" else "Build",if project.complete then project.mutation else nil)
            if project.recovered then
                pad.model.WorldPivot=pad.origin
                pad.model:SetAttribute("OwnerUserId",base.owner)
                pad.model:SetAttribute("RevealAt",project.startedAt+Style.get(project.rarity).Duration)
                pad.model:SetAttribute("RevealOrigin",pad.origin)
                game:GetService("CollectionService"):AddTag(pad.model,"RecoveredRobotReveal")
            end
            pad.label.Text=if project.complete then Mutations.prefix(project.mutation)..(if project.variant then Catalog.label(project.variant):upper() else project.rarity:upper()).."\n$"..math.floor(Economy.projectIncome(project,Config.Robot)).." PER SEC" else string.format("%s / %d OF %d\nMYSTERY BUILD",project.rarity:upper(),project.parts,recipe.Parts)
            local mutation = Mutations.get(project.mutation)
            pad.label.TextColor3=Color3.fromRGB(unpack(if mutation and project.complete then mutation.Color else recipe.Color))
        elseif locked then
            pad.label.Text="SLOT "..slot.." / LOCKED\nREBIRTH TO UNLOCK"
            pad.label.TextColor3=Color3.fromRGB(150,160,170)
        else
            pad.label.Text="SLOT "..slot.." / AVAILABLE"
            pad.label.TextColor3=base.accent
        end
    end
end

return BaseBuilder
