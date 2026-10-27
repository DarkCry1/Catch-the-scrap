--!nonstrict
-- Native IK/Tool carrying; no client Motor6D pose overrides.
local Rig={}
function Rig.clear(record)
    record.carrying=false
    if record.weld then record.weld:Destroy();record.weld=nil end
    if record.rig then
        for _,object in record.rig do object:Destroy() end
        record.rig=nil
    end
end
function Rig.attach(record,root,style)
    Rig.clear(record)
    local character=root.Parent
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    assert(humanoid,"A living character is required for carrying")
    record.rig={};record.carrying=true
    local function keep(object) table.insert(record.rig,object);return object end
    local function weld(a,b)
        local joint=Instance.new("WeldConstraint");joint.Name="CargoWeld";joint.Part0=a;joint.Part1=b;joint.Parent=b
        record.weld=joint
    end
    local function mount(offset)
        record.root.Anchored=true;record.model:PivotTo(root.CFrame*offset);record.root.Anchored=false;weld(root,record.root)
    end
    local r15=character:FindFirstChild("RightUpperArm") and character:FindFirstChild("LeftUpperArm") and character:FindFirstChild("RightHand") and character:FindFirstChild("LeftHand")
    if style=="Auto" and r15 then
        local ok=pcall(function()
            mount(CFrame.new(0,.9,-2.5))
            if not humanoid:FindFirstChildOfClass("Animator") then local animator=Instance.new("Animator");animator.Parent=humanoid end
            for _,side in {"Left","Right"} do
                local target=keep(Instance.new("Attachment"));target.Name=side.."CargoGrip"
                local box=record.definition.kind=="RobotCrate"
                target.Position=Vector3.new((if side=="Left" then -1 else 1)*(if box then 1.6 else 1),-.3,if box then 1.65 else .35)
                target.Parent=record.root
                local ik=keep(Instance.new("IKControl"));ik.Name="Cargo"..side
                ik.Type=Enum.IKControlType.Position;ik.ChainRoot=character:FindFirstChild(side.."UpperArm");ik.EndEffector=character:FindFirstChild(side.."Hand")
                ik.Target=target;ik.Weight=1;ik.Priority=10;ik.SmoothTime=.12;ik.Enabled=true;ik.Parent=humanoid
            end
        end)
        if ok then return "Two-hand IK" end
        Rig.clear(record);record.rig={};record.carrying=true
    end
    if style~="Harness" and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")) then
        local ok=pcall(function()
            local tool=keep(Instance.new("Tool"));tool.Name="Carried Salvage";tool.RequiresHandle=true;tool.CanBeDropped=false;tool.ManualActivationOnly=true
            tool.Grip=CFrame.new(0,-.25,if record.definition.kind=="RobotCrate" then 2.1 else .45)
            local handle=Instance.new("Part");handle.Name="Handle";handle.Size=Vector3.one*.2;handle.Transparency=1
            handle.Anchored=false;handle.Massless=true;handle.CanCollide=false;handle.CanTouch=false;handle.CanQuery=false;handle.CFrame=root.CFrame;handle.Parent=tool
            record.root.Anchored=true;record.model:PivotTo(handle.CFrame);record.root.Anchored=false;weld(handle,record.root)
            tool.Parent=character;humanoid:EquipTool(tool)
            tool.Unequipped:Connect(function()
                task.defer(function()
                    if record.carrying and tool.Parent and tool.Parent~=character and character.Parent and humanoid.Health>0 then humanoid:EquipTool(tool) end
                end)
            end)
        end)
        if ok then return "Handheld" end
        Rig.clear(record);record.rig={};record.carrying=true
    end
    -- Body-mounted fallback supports unusual avatars without an arm animation.
    mount(CFrame.new(0,.5,2.3))
    for _,side in {-1,1} do
        local strap=keep(Instance.new("Part"));strap.Name="CargoHarnessStrap";strap.Size=Vector3.new(.18,2.7,.16)
        strap.Color=Color3.fromRGB(55,66,76);strap.Material=Enum.Material.Fabric
        strap.CFrame=root.CFrame*CFrame.new(side*.65,.45,.65);strap.Anchored=false;strap.Massless=true;strap.CanCollide=false;strap.CanQuery=false;strap.CanTouch=false;strap.Parent=character
        local joint=Instance.new("WeldConstraint");joint.Part0=root;joint.Part1=strap;joint.Parent=strap
    end
    return "Harness"
end
return Rig
