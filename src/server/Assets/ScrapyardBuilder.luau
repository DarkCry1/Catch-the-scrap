--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.CatchTheScrapShared
local Config = require(Shared.Config)
local Blueprint = require(Shared.ScrapyardBlueprint)
local FloatingText = require(script.Parent.FloatingText)
local NavigationRenderer = require(script.Parent.NavigationRenderer)
local ScrapyardBuilder = {}
function ScrapyardBuilder.build(world)
    local yard = Instance.new("Model")
    yard.Name = "Scrapyard"
    yard.Parent = world.root
    local layout = Blueprint.build(Config.TrackWidth, Config.ZoneLength, Config.TrackStart)
    for _, definition in layout.parts do
        local part = Instance.new("Part")
        part.Name = definition.name
        part.Size = Vector3.new(unpack(definition.size))
        part.CFrame = CFrame.new(unpack(definition.position)) * CFrame.Angles(math.rad(definition.pitch),math.rad(definition.yaw),math.rad(definition.roll))
        part.Shape = Enum.PartType[definition.shape]
        part.Material = Enum.Material[definition.material]
        part.Color = Color3.fromRGB(unpack(definition.color))
        part.Transparency = definition.transparency
        part.Anchored = true
        part.CanCollide = definition.collidable
        part.CanTouch = false
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Parent = yard
    end
    for _, sign in layout.signs do
        FloatingText.create(yard,"YardLabel",CFrame.new(unpack(sign.position)),sign.text,Color3.fromRGB(unpack(sign.color)),48,4,100)
    end
    for z = Config.TrackStart+45, Config.TrackStart+Config.ZoneLength*3-15, 60 do
        NavigationRenderer.draw(yard,7,z,1,Color3.fromRGB(235,178,65))
        NavigationRenderer.draw(yard,-7,z,-1,Color3.fromRGB(100,192,190))
    end
    local definitions = {}
    for _, item in Config.Items do definitions[item.rarity]=item end
    for _, spawn in layout.spawns do
        table.insert(world.spawns,{position=Vector3.new(unpack(spawn.position)),definition=definitions[spawn.rarity]})
    end
end
return ScrapyardBuilder
