--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.CatchTheScrapShared.Config)
local BaseBuilder = require(script.Parent.Parent.Assets.BaseBuilder)
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

    part(root, "Landscape", Vector3.new(450, 2, 800), Vector3.new(0, -2.1, 60), Color3.fromRGB(71, 93, 72), Enum.Material.Grass)
    part(root, "HomeGround", Vector3.new(200, 2, 320), Vector3.new(0, -1, -140), Color3.fromRGB(53, 65, 72), Enum.Material.Concrete)
    part(root, "WorkshopStreet", Vector3.new(43, 0.08, 302), Vector3.new(0, 0.05, -131), Color3.fromRGB(37, 47, 56), Enum.Material.Asphalt)
    for z = -260, -15, 25 do
        for _, side in { -1, 1 } do
            local arrow = part(root, "TrackArrow", Vector3.new(0.6, 0.06, 4), Vector3.new(side * 1.3, 0.13, z), Color3.fromRGB(255, 193, 76), Enum.Material.Neon)
            arrow.CFrame *= CFrame.Angles(0, math.rad(side * 45), 0)
        end
    end
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
        local left = index % 2 == 1
        local row = math.floor((index - 1) / 2)
        local position = Vector3.new(if left then -62 else 62, 0, -35 - row * 66)
        local origin = CFrame.new(position) * CFrame.Angles(0, if left then math.pi / 2 else -math.pi / 2, 0)
        local base = BaseBuilder.create(root, index, origin)
        table.insert(self.bases, base)
        base.prompt.Triggered:Connect(function(player)
            if self.onDeposit then self.onDeposit(player, base) end
        end)
        local pole = part(root, "StreetLamp", Vector3.new(0.7, 13, 0.7), Vector3.new(if left then -29 else 29, 6.5, position.Z + 24), Color3.fromRGB(80, 101, 110), Enum.Material.Metal)
        local lamp = part(root, "Lamp", Vector3.new(3, 0.4, 3), pole.Position + Vector3.new(0, 6.5, 0), Color3.fromRGB(255, 220, 155), Enum.Material.Neon)
        local light = Instance.new("PointLight")
        light.Color = lamp.Color
        light.Brightness = 0.6
        light.Range = 18
        light.Shadows = false
        light.Parent = lamp
    end
    return self
end

function WorldService:assignBase(player)
    for _, base in self.bases do
        if base.owner == nil then
            base.owner = player.UserId
            base.prompt.Enabled = true
            base.prompt.ObjectText = player.DisplayName .. " · verkstad " .. base.index
            base.folder:SetAttribute("OwnerUserId", player.UserId)
            player.RespawnLocation = base.spawn
            return base
        end
    end
    return nil
end

function WorldService:updateEconomy(base, player, account)
    BaseBuilder.update(base, player.DisplayName, account)
end

function WorldService:releaseBase(base)
    base.owner = nil
    base.folder:SetAttribute("OwnerUserId", nil)
    base.prompt.Enabled = false
    base.prompt.ObjectText = "Ledig verkstad"
    BaseBuilder.update(base, "", nil)
end

return WorldService
