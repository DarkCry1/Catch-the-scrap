--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.CatchTheScrapShared.Config)
local WorldService = {}
WorldService.__index = WorldService

local function part(parent, name, size, position, color, material)
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.Position = position
    object.Color = color
    object.Material = material or Enum.Material.SmoothPlastic
    object.Anchored = true
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = parent
    return object
end

local function sign(parent, name, position, text, color, width)
    local board = part(parent, name, Vector3.new(width or 24, 7, 0.5), position, Color3.fromRGB(20, 29, 44))
    board.CanCollide = false
    board.CanQuery = false
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(320, 85)
    gui.AlwaysOnTop = false
    gui.MaxDistance = 160
    gui.Parent = board
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = color
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui
    return label
end

function WorldService.new()
    assert(not workspace:FindFirstChild("CatchTheScrapWorld"), "World already exists")
    local self = setmetatable({ bases = {}, spawns = {} }, WorldService)
    local root = Instance.new("Folder")
    root.Name = "CatchTheScrapWorld"
    root.Parent = workspace
    self.root = root
    local items = Instance.new("Folder")
    items.Name = "Items"
    items.Parent = root
    self.items = items

    part(root, "HomeGround", Vector3.new(290, 2, 170), Vector3.new(0, -1, -65), Color3.fromRGB(32, 42, 56))
    sign(root, "Title", Vector3.new(0, 13, 5), "CATCH THE SCRAP\nHämta skrot • ta hem ditt fynd", Color3.fromRGB(255, 198, 80), 38)
    for zone, definition in Config.Items do
        local startZ = Config.TrackStart + (zone - 1) * Config.ZoneLength
        local center = startZ + Config.ZoneLength / 2
        local tint = Color3.fromRGB(unpack(definition.color))
        part(root, "Zone" .. zone, Vector3.new(Config.TrackWidth, 2, Config.ZoneLength), Vector3.new(0, -1, center), tint:Lerp(Color3.fromRGB(25, 33, 47), 0.78))
        sign(root, "ZoneSign" .. zone, Vector3.new(0, 11, startZ + 5), string.format("ZON %d · %s\n%s · vikt %d", zone, definition.rarity, definition.name, definition.weight), tint, 30)
        for _, x in { -Config.TrackWidth / 2 - 1, Config.TrackWidth / 2 + 1 } do
            part(root, "Rail", Vector3.new(2, 3, Config.ZoneLength), Vector3.new(x, 1.5, center), tint)
        end
        for index, offset in { 25, 55, 85, 110 } do
            local position = Vector3.new(if index % 2 == 0 then 10 else -10, 2, startZ + offset)
            part(root, "PickupPad", Vector3.new(7, 0.2, 7), Vector3.new(position.X, 0.1, position.Z), tint, Enum.Material.Neon)
            table.insert(self.spawns, { position = position, definition = definition })
        end
        for offset = 15, Config.ZoneLength - 1, 20 do
            part(root, "CenterMarker", Vector3.new(0.4, 0.06, 6), Vector3.new(0, 0.05, startZ + offset), Color3.fromRGB(185, 195, 210))
        end
    end
    part(root, "EndBarrier", Vector3.new(Config.TrackWidth, 5, 2), Vector3.new(0, 2.5, Config.TrackStart + 3 * Config.ZoneLength), Color3.fromRGB(85, 155, 255))

    for index = 1, Config.BaseCount do
        local column = (index - 1) % 4
        local row = math.floor((index - 1) / 4)
        local origin = Vector3.new((column - 1.5) * 68, 0, -40 - row * 65)
        local folder = Instance.new("Folder")
        folder.Name = "Base" .. index
        folder.Parent = root
        part(folder, "Floor", Vector3.new(56, 0.3, 49), origin + Vector3.new(0, 0.15, 0), Color3.fromRGB(52, 66, 83))
        local deposit = part(folder, "Deposit", Vector3.new(12, 1, 9), origin + Vector3.new(0, 0.8, 13), Color3.fromRGB(255, 187, 65), Enum.Material.Neon)
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Lämna in"
        prompt.ObjectText = "Ledig bas"
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.HoldDuration = 0.25
        prompt.MaxActivationDistance = Config.InteractionDistance
        prompt.RequiresLineOfSight = false
        prompt.Enabled = false
        prompt.Parent = deposit
        local spawn = Instance.new("SpawnLocation")
        spawn.Name = "Spawn"
        spawn.Size = Vector3.new(7, 0.5, 7)
        local spawnPosition = origin + Vector3.new(0, 0.6, -9)
        spawn.CFrame = CFrame.lookAt(spawnPosition, spawnPosition + Vector3.new(0, 0, 1))
        spawn.Anchored = true
        spawn.Neutral = true
        spawn.Duration = 0
        spawn.Color = Color3.fromRGB(100, 195, 220)
        spawn.Material = Enum.Material.SmoothPlastic
        spawn.Parent = folder
        local label = sign(folder, "OwnerSign", origin + Vector3.new(0, 8, -20), "LEDIG BAS " .. index, Color3.fromRGB(225, 235, 250), 32)
        local base = { index = index, owner = nil, spawn = spawn, deposit = deposit, prompt = prompt, label = label }
        table.insert(self.bases, base)
        prompt.Triggered:Connect(function(player)
            if self.onDeposit then self.onDeposit(player, base) end
        end)
    end
    return self
end

function WorldService:assignBase(player)
    for _, base in self.bases do
        if base.owner == nil then
            base.owner = player.UserId
            base.prompt.Enabled = true
            base.prompt.ObjectText = player.DisplayName .. " · bas " .. base.index
            base.label.Text = player.DisplayName .. "\nBAS " .. base.index .. " · 0 inlämnade"
            player.RespawnLocation = base.spawn
            return base
        end
    end
    return nil
end

function WorldService:updateBase(base, player, delivered)
    base.label.Text = string.format("%s\nBAS %d · %d inlämnade", player.DisplayName, base.index, delivered)
end

function WorldService:releaseBase(base)
    base.owner = nil
    base.prompt.Enabled = false
    base.prompt.ObjectText = "Ledig bas"
    base.label.Text = "LEDIG BAS " .. base.index
end

return WorldService
