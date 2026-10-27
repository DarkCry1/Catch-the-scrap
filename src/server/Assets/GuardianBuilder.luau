--!nonstrict
local Tags=game:GetService("CollectionService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Rules=require(Shared.GuardianRules)
local Blueprint=require(Shared.GuardianBlueprint)
local Decor=require(script.Parent.RarityDecor)
local Builder={}
function Builder.build(parent,stage,position)
    local profile=Config.Guardians.Profiles[stage];local rarity=Config.Stages[stage].Rarity;local scale=profile.Scale
    local tint=Color3.fromRGB(unpack(Config.Stages[stage].Color))
    local model=Instance.new("Model");model.Name=rarity.."Guardian";model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    model:SetAttribute("Stage",stage);model:SetAttribute("Rarity",rarity);model:SetAttribute("DisplayName",profile.Name)
    model:SetAttribute("Scale",scale);model:SetAttribute("ChaseSpeed",profile.ChaseSpeed);model:SetAttribute("Height",Rules.height(stage));model:SetAttribute("State","Patrol")
    local function part(name,size,frame)
        local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=frame;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;p.Anchored=false;p.CastShadow=false;p.Parent=model;return p
    end
    local frame=CFrame.new(position)
    local root=part("GuardianRoot",Vector3.one,frame);root.Transparency=1;root.Anchored=true;model.PrimaryPart=root
    local pivots,joints,eyes={},{},{}
    for _,name in {"Torso","Head","LeftArm","RightArm","LeftLeg","RightLeg"} do
        local p=Vector3.new(unpack(Blueprint.Pivots[name]))*scale
        local pivot=part(name.."Pivot",Vector3.one*.15,frame*CFrame.new(p));pivot.Transparency=1
        local motor=Instance.new("Motor6D");motor.Name=name.."Motor";motor.Part0=if name=="Torso" or name=="LeftLeg" or name=="RightLeg" then root else pivots.Torso
        local parentP=if motor.Part0==root then Vector3.zero else Vector3.new(unpack(Blueprint.Pivots.Torso))*scale
        motor.Part1=pivot;motor.C0=CFrame.new(p-parentP);motor.C1=CFrame.identity;motor.Parent=pivot
        pivots[name]=pivot;joints[name]=motor
    end
    for i,d in Blueprint.build(stage) do
        local p=part(d.name,Vector3.new(unpack(d.size))*scale,frame*CFrame.new(Vector3.new(unpack(d.position))*scale)*CFrame.Angles(math.rad(d.pitch or 0),math.rad(d.yaw or 0),math.rad(d.roll or 0)))
        p.Shape=Enum.PartType[d.shape];p.Material=if d.palette=="energy" then Enum.Material.Neon else Enum.Material.Metal
        p.Color=if d.palette=="amber" or d.palette=="energy" then tint else Color3.fromRGB(unpack(Config.Palette[d.palette]))
        p.CastShadow=true
        local weld=Instance.new("WeldConstraint");weld.Part0=pivots[d.group];weld.Part1=p;weld.Parent=p
        if d.name=="LeftEye" or d.name=="RightEye" or d.name=="SecurityVisor" then table.insert(eyes,p)
        elseif rarity=="Celestial" and (d.palette=="energy" or d.palette=="amber") then Decor.spectrum(p,i*.055) end
    end
    local lamp=Instance.new("PointLight");lamp.Name="AlarmLight";lamp.Range=12;lamp.Brightness=1.5;lamp.Enabled=false;lamp.Shadows=false;lamp.Parent=pivots.Head
    local board=Instance.new("BillboardGui");board.Name="GuardianLabel";board.Size=UDim2.fromOffset(260,66);board.StudsOffset=Vector3.new(0,Rules.height(stage)+1.4,0);board.MaxDistance=105;board.AlwaysOnTop=false;board.Parent=root
    local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Font=Enum.Font.GothamBold;label.TextSize=15;label.TextStrokeTransparency=.25;label.TextColor3=tint;label.TextWrapped=true;label.AutoLocalize=false;label.Parent=board
    model.Parent=parent;Tags:AddTag(model,"StageGuardian")
    return {model=model,root=root,joints=joints,eyes=eyes,lamp=lamp,label=label,tint=tint}
end
return Builder
