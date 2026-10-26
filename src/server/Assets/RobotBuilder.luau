--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Config = require(ReplicatedStorage.CatchTheScrapShared.Config)
local Blueprint = require(ReplicatedStorage.CatchTheScrapShared.RobotBlueprint)
local RobotBuilder = {}

function RobotBuilder.build(parent, origin, stage, complete, rarity, scale)
    scale = scale or 1
    local recipe = Config.Robot.Recipes[rarity]
    local model = Instance.new("Model")
    model.Name = if complete then recipe.Name else rarity.."RobotUnderConstruction"
    model:SetAttribute("Rarity",rarity)
    model:SetAttribute("BuildStage", stage)
    model:SetAttribute("Complete", complete)
    for _, definition in Blueprint do
        local assembled = definition.step <= stage
        local object = Instance.new("Part")
        object.Name = definition.name
        object.Shape = Enum.PartType[definition.shape]
        object.Size = Vector3.new(unpack(definition.size)) * scale
        object.CFrame = origin * CFrame.new(Vector3.new(unpack(definition.position)) * scale)
        object.Anchored = true
        object.CanCollide = false
        object.CanTouch = false
        object.CanQuery = false
        object.TopSurface = Enum.SurfaceType.Smooth
        object.BottomSurface = Enum.SurfaceType.Smooth
        object.Color = if assembled then Color3.fromRGB(unpack(Config.Palette[definition.palette])) else Color3.fromRGB(80, 205, 215)
        if assembled and (definition.palette == "amber" or definition.palette == "energy") then
            object.Color = Color3.fromRGB(unpack(recipe.Color))
        end
        object.Material = if not assembled or definition.palette == "energy" then Enum.Material.Neon else Enum.Material.Metal
        object.Transparency = if assembled then 0 else 0.9
        object.CastShadow = assembled
        object.Parent = model
        if complete and definition.name == "Reactor" then CollectionService:AddTag(object, "WorkingRobotReactor") end
    end
    model.Parent = parent
    return model
end

return RobotBuilder
