--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Config = require(ReplicatedStorage.CatchTheScrapShared.Config)
local Blueprint = require(ReplicatedStorage.CatchTheScrapShared.RobotBlueprint)
local Variants=require(ReplicatedStorage.CatchTheScrapShared.RobotVariants)
local Catalog=require(ReplicatedStorage.CatchTheScrapShared.RobotCatalog)
local Mutations=require(ReplicatedStorage.CatchTheScrapShared.Mutations)
local Decor=require(script.Parent.RarityDecor)
local RobotBuilder = {}
-- Surface finish per palette; everything else is painted metal.
local finishes = { rust = Enum.Material.CorrodedMetal, bone = Enum.Material.SmoothPlastic, white = Enum.Material.SmoothPlastic, sand = Enum.Material.SmoothPlastic, black = Enum.Material.SmoothPlastic, void = Enum.Material.Glass }

-- Palettes repainted by a mutation (glow/trim keep the rarity color).
local painted = Mutations.Painted

function RobotBuilder.build(parent, origin, stage, complete, rarity, scale,variant,route,mutation)
    scale = scale or 1
    local recipe = Config.Robot.Recipes[rarity]
    local model = Instance.new("Model")
    model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    model.Name = if variant then Catalog.name(variant) else if complete then recipe.Name else rarity.."RobotUnderConstruction"
    model:SetAttribute("Rarity",rarity)
    model:SetAttribute("Variant",variant)
    model:SetAttribute("Income",Catalog.income(recipe.Income,variant)*Mutations.multiplier(mutation))
    model:SetAttribute("Mutation",mutation)
    local mutationInfo = if complete then Mutations.get(mutation) else nil
    -- Clients build the glowing aura (MutationAuras) for tagged robots.
    if mutationInfo then CollectionService:AddTag(model, "MutatedRobot") end
    local partIndex = 0
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
        object.Material = if not assembled or definition.palette == "energy" then Enum.Material.Neon else (finishes[definition.palette] or Enum.Material.Metal)
        object.Reflectance = if assembled and definition.palette=="steel" then .06 else 0
        object.Transparency = if assembled then 0 else 0.9
        object.CastShadow = assembled
        object.Parent = model
        partIndex += 1
        if mutationInfo and painted[definition.palette] then
            -- Shared look (Mutations.paint) so the Robotdex preview matches.
            local paint = Mutations.paint(mutationInfo.Id, partIndex)
            object.Color = Color3.fromRGB(unpack(paint.Color))
            object.Material = Enum.Material[paint.Material] or Enum.Material.Metal
            object.Reflectance = paint.Reflectance
            object.Transparency = paint.Transparency
            if paint.Spectrum then Decor.spectrum(object, partIndex * .037) end
        end
        if complete and rarity=="Celestial" and (definition.palette=="amber" or definition.palette=="energy") then Decor.spectrum(object,(definition.position[1]+definition.position[2])*.13) end
        if complete and definition.name == "Reactor" then
            CollectionService:AddTag(object, "WorkingRobotReactor")
            if mutationInfo then
                local sparkle = Instance.new("ParticleEmitter"); sparkle.Name = "MutationSparkle"
                sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"; sparkle.Rate = mutationInfo.Sparkles
                sparkle.Lifetime = NumberRange.new(.8, 1.6); sparkle.Speed = NumberRange.new(.6, 2); sparkle.SpreadAngle = Vector2.new(180, 180)
                sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, .28), NumberSequenceKeypoint.new(1, 0) })
                sparkle.LightEmission = 1; sparkle.Parent = object
                sparkle.Color = if mutationInfo.AccentEvery > 0 then ColorSequence.new(Color3.fromRGB(unpack(mutationInfo.Accent)), Color3.fromRGB(unpack(mutationInfo.Accent2))) else ColorSequence.new(Color3.fromRGB(unpack(mutationInfo.Color)))
                if mutationInfo.Pattern == "Spectrum" then Decor.spectrum(sparkle, .5) end
            end
        end
    end
    model.Parent = parent
    return model
end

return RobotBuilder
