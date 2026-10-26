--!nonstrict
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Blueprint=require(Shared.PickupBlueprint)
local PickupBuilder={}
function PickupBuilder.build(model,root,definition)
    for _,detail in Blueprint.build(definition.rarity,definition.color) do
        local part=Instance.new("Part")
        part.Name=detail.name;part.Size=Vector3.new(unpack(detail.size))
        part.CFrame=root.CFrame*CFrame.new(unpack(detail.position))*CFrame.Angles(0,math.rad(detail.yaw),math.rad(detail.roll))
        part.Shape=Enum.PartType[detail.shape];part.Material=Enum.Material[detail.material]
        part.Color=Color3.fromRGB(unpack(detail.color));part.Reflectance=if detail.material=="Metal" then .08 else 0
        part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true
        part.TopSurface=Enum.SurfaceType.Smooth;part.BottomSurface=Enum.SurfaceType.Smooth;part.Parent=model
        local weld=Instance.new("WeldConstraint");weld.Part0=root;weld.Part1=part;weld.Parent=part
    end
end
return PickupBuilder
