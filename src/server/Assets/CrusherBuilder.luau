--!nonstrict
local CollectionService=game:GetService("CollectionService")
local Blueprint=require(game:GetService("ReplicatedStorage").CatchTheScrapShared.CrusherBlueprint)
local Builder={}
local function part(parent,d,origin)
    local object=Instance.new("Part");object.Name=d.name;object.Size=Vector3.new(unpack(d.size))
    object.CFrame=origin*CFrame.new(unpack(d.position))*CFrame.Angles(math.rad(d.pitch),0,0)
    object.Shape=Enum.PartType[d.shape];object.Material=Enum.Material[d.material];object.Color=Color3.fromRGB(unpack(d.color))
    object.Anchored=true;object.CanCollide=false;object.CanTouch=false;object.CanQuery=false;object.Parent=parent
    return object
end
function Builder.create(parent,origin)
    local model=Instance.new("Model");model.Name="ScrapCrusher";model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    model:SetAttribute("Origin",origin)
    local layout=Blueprint.build()
    for _,d in layout.housing do part(model,d,origin) end
    for index,rotor in layout.rotors do
        local group=Instance.new("Model");group.Name="Rotor"..index
        local pivot=origin*CFrame.new(unpack(rotor.position))
        for _,d in rotor.parts do part(group,d,pivot) end
        group.WorldPivot=pivot;group.Parent=model
        group:SetAttribute("Origin",pivot);group:SetAttribute("Direction",rotor.direction)
    end
    local anchor=Instance.new("Part");anchor.Name="SparkOutlet";anchor.Size=Vector3.one*.1;anchor.Transparency=1
    anchor.CFrame=origin*CFrame.new(0,4.8,-12);anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.Parent=model
    local sparks=Instance.new("ParticleEmitter");sparks.Name="CuttingSparks";sparks.Texture="rbxasset://textures/particles/sparkles_main.dds"
    sparks.Rate=0;sparks.Lifetime=NumberRange.new(.18,.45);sparks.Speed=NumberRange.new(9,19);sparks.SpreadAngle=Vector2.new(65,65)
    sparks.Acceleration=Vector3.new(0,-25,0);sparks.Drag=2;sparks.LightEmission=1
    sparks.Color=ColorSequence.new(Color3.fromRGB(255,226,126),Color3.fromRGB(255,113,30))
    sparks.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.16),NumberSequenceKeypoint.new(1,0)})
    sparks.Parent=anchor
    local light=Instance.new("PointLight");light.Name="CuttingGlow";light.Color=Color3.fromRGB(255,163,65);light.Range=11;light.Brightness=1.5;light.Shadows=false;light.Enabled=false;light.Parent=anchor
    model.Parent=parent;CollectionService:AddTag(model,"ScrapCrusher")
    return model
end
return Builder
