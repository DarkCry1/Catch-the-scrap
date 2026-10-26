--!nonstrict
local CollectionService=game:GetService("CollectionService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Blueprint=require(Shared.PickupBlueprint)
local CrateBlueprint=require(Shared.CrateBlueprint)
local PickupBuilder={}
function PickupBuilder.build(model,root,definition)
    local pivot=Instance.new("Part")
    pivot.Name="VisualPivot";pivot.Size=Vector3.new(.1,.1,.1);pivot.Transparency=1
    pivot.CFrame=root.CFrame;pivot.Massless=true;pivot.CanCollide=false;pivot.CanTouch=false;pivot.CanQuery=false;pivot.Parent=model
    local joint=Instance.new("Motor6D")
    joint.Name="IdleJoint";joint.Part0=root;joint.Part1=pivot;joint.Parent=root
    local isBox=definition.kind=="RobotCrate"
    local details=if isBox then CrateBlueprint.build() else Blueprint.build(definition.rarity,definition.color)
    for _,detail in details do
        local part=Instance.new("Part")
        part.Name=detail.name;part.Size=Vector3.new(unpack(detail.size))
        part.CFrame=root.CFrame*CFrame.new(unpack(detail.position))*CFrame.Angles(0,math.rad(detail.yaw),math.rad(detail.roll))
        part.Shape=Enum.PartType[detail.shape];part.Material=Enum.Material[detail.material]
        part.Color=Color3.fromRGB(unpack(detail.color));part.Reflectance=if detail.material=="Metal" then .12 else 0
        part.CastShadow=detail.material~="Neon" and math.min(unpack(detail.size))>.3
        part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true
        part.TopSurface=Enum.SurfaceType.Smooth;part.BottomSurface=Enum.SurfaceType.Smooth;part.Parent=model
        local weld=Instance.new("WeldConstraint");weld.Part0=pivot;weld.Part1=part;weld.Parent=part
    end
    local halo=Instance.new("Folder");halo.Name="GroundHalo";halo.Parent=model
    local height=-(if isBox then CrateBlueprint.clearance() else Blueprint.clearance(definition.rarity,definition.color))+.08
    for i=0,11 do
        local a=i*math.pi/6
        local marker=Instance.new("Part")
        marker.Name="HaloSegment";marker.Size=Vector3.new(.75,.06,.1);marker.Material=Enum.Material.Neon
        marker.Color=Color3.fromRGB(unpack(definition.color));marker.Transparency=.3
        marker.CFrame=root.CFrame*CFrame.new(math.cos(a)*1.85,height,math.sin(a)*1.85)*CFrame.Angles(0,-a+math.pi/2,0)
        marker.Massless=true;marker.CanCollide=false;marker.CanTouch=false;marker.CanQuery=false;marker.CastShadow=false;marker.Parent=halo
        local weld=Instance.new("WeldConstraint");weld.Part0=root;weld.Part1=marker;weld.Parent=marker
    end
    model:SetAttribute("IdlePhase",(root.Position.X*7+root.Position.Z*13)%628/100)
    CollectionService:AddTag(model,"AnimatedScrap")
end
return PickupBuilder
