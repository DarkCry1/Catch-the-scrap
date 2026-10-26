--!nonstrict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Shared=ReplicatedStorage.CatchTheScrapShared
local Config=require(Shared.Config)
local Blueprint=require(Shared.MechanicBlueprint)
local RobotBuilder=require(script.Parent.RobotBuilder)
local FloatingText=require(script.Parent.FloatingText)
local MechanicBuilder={}

function MechanicBuilder.create(parent)
    local stand=Instance.new("Model")
    stand.Name="MechanicStand"
    stand.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    stand.Parent=parent
    local origin=CFrame.new(55,0,7)*CFrame.Angles(0,-math.pi/2,0)
    local function part(name,size,position,palette,material)
        local p=Instance.new("Part")
        p.Name=name;p.Size=Vector3.new(unpack(size));p.CFrame=origin*CFrame.new(unpack(position))
        p.Anchored=true;p.Color=Color3.fromRGB(unpack(Config.Palette[palette]));p.Material=Enum.Material[material]
        p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=stand
        return p
    end
    for _,p in Blueprint do
        local object=part(p.name,p.size,p.position,p.palette,p.material)
        if p.collidable==false then object.CanCollide=false end
    end
    local milo=RobotBuilder.build(stand,origin*CFrame.new(0,.6,-1),5,true,"Common",.72)
    milo.Name="MiloTheMechanic"
    milo:SetAttribute("NPC",true)
    FloatingText.create(stand,"MechanicLabel",origin*CFrame.new(0,12,1),"MILO THE MECHANIC\nSPEED & STRENGTH",Color3.fromRGB(255,198,80),27,4,105)
    local interaction=part("Interaction",{8,3,1},{0,2.5,7},"amber","SmoothPlastic")
    interaction.Transparency=1;interaction.CanCollide=false;interaction.CanTouch=false;interaction.CanQuery=false;interaction.CastShadow=false
    local prompt=Instance.new("ProximityPrompt")
    prompt.ActionText="Browse upgrades";prompt.ObjectText="Milo the Mechanic";prompt.AutoLocalize=false
    prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.HoldDuration=.15;prompt.MaxActivationDistance=Config.UpgradeDistance
    prompt.RequiresLineOfSight=true;prompt.Parent=interaction
    return {model=stand,interaction=interaction,prompt=prompt}
end

return MechanicBuilder
