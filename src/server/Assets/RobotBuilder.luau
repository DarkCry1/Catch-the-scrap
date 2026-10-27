--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Config = require(ReplicatedStorage.CatchTheScrapShared.Config)
local Blueprint = require(ReplicatedStorage.CatchTheScrapShared.RobotBlueprint)
local Variants=require(ReplicatedStorage.CatchTheScrapShared.RobotVariants)
local Catalog=require(ReplicatedStorage.CatchTheScrapShared.RobotCatalog)
local Decor=require(script.Parent.RarityDecor)
local RobotBuilder = {}

function RobotBuilder.build(parent, origin, stage, complete, rarity, scale,variant,route)
    scale = scale or 1
    local recipe = Config.Robot.Recipes[rarity]
    local model = Instance.new("Model")
    model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    model.Name = if variant then Catalog.name(rarity,variant) else if complete then recipe.Name else rarity.."RobotUnderConstruction"
    model:SetAttribute("Rarity",rarity)
    model:SetAttribute("Variant",variant)
    model:SetAttribute("Income",Catalog.income(recipe.Income,variant,route))
    model:SetAttribute("BuildStage", stage)
    model:SetAttribute("Complete", complete)
    for _, definition in (if variant then Variants.build(variant) else Blueprint) do
        local assembled = definition.step <= stage
        local object = Instance.new("Part")
        object.Name = definition.name
        object.Shape = Enum.PartType[definition.shape]
        object.Size = Vector3.new(unpack(definition.size)) * scale
        object.CFrame = origin * CFrame.new(Vector3.new(unpack(definition.position)) * scale) * CFrame.Angles(math.rad(definition.pitch or 0),math.rad(definition.yaw or 0),math.rad(definition.roll or 0))
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
        object.Reflectance = if assembled and definition.palette=="steel" then .06 else 0
        object.Transparency = if assembled then 0 else 0.9
        object.CastShadow = assembled
        object.Parent = model
        if complete and rarity=="Celestial" and (definition.palette=="amber" or definition.palette=="energy") then Decor.spectrum(object,(definition.position[1]+definition.position[2])*.13) end
        if complete and definition.name == "Reactor" then CollectionService:AddTag(object, "WorkingRobotReactor") end
    end
    model.Parent = parent
    return model
end

return RobotBuilder
