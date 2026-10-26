--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.CatchTheScrapShared.Config)
local BaseBuilder = require(script.Parent.Parent.Assets.BaseBuilder)
local FloatingText = require(script.Parent.Parent.Assets.FloatingText)
local NavigationRenderer = require(script.Parent.Parent.Assets.NavigationRenderer)
local ScrapyardBuilder = require(script.Parent.Parent.Assets.ScrapyardBuilder)
local MechanicBuilder = require(script.Parent.Parent.Assets.MechanicBuilder)
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

function WorldService.new()
    assert(not workspace:FindFirstChild("CatchTheScrapWorld"), "World already exists")
    local self = setmetatable({ bases = {}, spawns = {} }, WorldService)
    local root = Instance.new("Folder")
    root.Name = "CatchTheScrapWorld"
    root.Parent = workspace
    self.root = root
    local clouds=Instance.new("Clouds")
    clouds.Name="SalvageClouds";clouds.Cover=.45;clouds.Density=.32;clouds.Color=Color3.fromRGB(198,192,177);clouds.Parent=workspace.Terrain
    local items = Instance.new("Folder")
    items.Name = "Items"
    items.Parent = root
    self.items = items

    part(root, "WorkshopStreet", Vector3.new(43, 0.08, 302), Vector3.new(0, 0.05, -131), Color3.fromRGB(37, 47, 56), Enum.Material.Asphalt)
    for z = -260, -15, 25 do
        NavigationRenderer.draw(root,0,z,1,Color3.fromRGB(235,178,65))
    end
    FloatingText.create(root,"YardEntrance",CFrame.new(0,16,0),"CATCH THE SCRAP\nSCRAPYARD AHEAD",Color3.fromRGB(255,198,80),48,7,120)
    ScrapyardBuilder.build(self)
    self.mechanic = MechanicBuilder.create(root)

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
            base.ownerPlayer = player
            base.folder:AddPersistentPlayer(player)
            base.prompt.Enabled = true
            base.prompt.ObjectText = player.DisplayName .. " · Workshop " .. base.index
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
    if base.ownerPlayer then base.folder:RemovePersistentPlayer(base.ownerPlayer) end
    base.ownerPlayer = nil
    base.owner = nil
    base.folder:SetAttribute("OwnerUserId", nil)
    base.prompt.Enabled = false
    base.prompt.ObjectText = "Unclaimed workshop"
    BaseBuilder.update(base, "", nil)
end

return WorldService
