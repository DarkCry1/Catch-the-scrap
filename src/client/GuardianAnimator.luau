--!nonstrict
-- Six local motor poses per nearby guardian. Gameplay stays on the server.
local Tags=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local Animator={}
function Animator.start(player)
    local entries,pending={},{}
    local function remove(model)
        pending[model]=nil
        local e=entries[model];if not e then return end
        for _,connection in e.connections do connection:Disconnect() end
        for _,motor in e.joints do if motor.Parent then motor.Transform=CFrame.identity end end
        entries[model]=nil
    end
    local function add(model)
        local token={};pending[model]=token
        task.spawn(function()
            local root=model:WaitForChild("GuardianRoot",10);if not root or pending[model]~=token then return end
            local joints={}
            for _,name in {"Torso","Head","LeftArm","RightArm","LeftLeg","RightLeg"} do
                local pivot=model:WaitForChild(name.."Pivot",10)
                local motor=pivot and pivot:WaitForChild(name.."Motor",5)
                if not motor or pending[model]~=token then return end
                joints[name]=motor
            end
            pending[model]=nil
            local e={root=root,joints=joints,model=model,phase=0,blend=0,connections={},visible=false,motion=model:GetAttribute("Motion") or root.CFrame,scale=model:GetAttribute("Scale") or 1}
            table.insert(e.connections,model:GetAttributeChangedSignal("Motion"):Connect(function() e.motion=model:GetAttribute("Motion") or e.motion end))
            entries[model]=e
        end)
    end
    Tags:GetInstanceAddedSignal("StageGuardian"):Connect(add);Tags:GetInstanceRemovedSignal("StageGuardian"):Connect(remove)
    for _,model in Tags:GetTagged("StageGuardian") do add(model) end
    RunService.PreSimulation:Connect(function(dt)
        local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
        for model,e in entries do
            if not model.Parent then remove(model);continue end
            local visible=root and (root.Position-e.motion.Position).Magnitude<175
            if not visible then
                if e.visible then for _,motor in e.joints do motor.Transform=CFrame.identity end end
                e.visible=false;continue
            end
            e.visible=true
            local speed=model:GetAttribute("MoveSpeed") or 0
            local walking=speed>.2
            e.blend+=( (if walking then 1 else 0)-e.blend)*math.min(1,dt*12)
            e.phase+=dt*(2.2+speed/e.scale*.48)
            local s=math.sin(e.phase)*e.blend;local state=model:GetAttribute("State")
            local swing=if state=="Chase" then .58 else .36
            e.root.CFrame=e.root.CFrame:Lerp(e.motion,1-math.exp(-dt*22))
            e.joints.LeftLeg.Transform=CFrame.Angles(s*swing,0,0)
            e.joints.RightLeg.Transform=CFrame.Angles(-s*swing,0,0)
            local brace=if state=="Alert" or state=="Chase" then -.35 else 0
            e.joints.LeftArm.Transform=CFrame.Angles(-s*swing*.7+brace,0,0)
            e.joints.RightArm.Transform=CFrame.Angles(s*swing*.7+brace,0,0)
            e.joints.Torso.Transform=CFrame.new(0,(math.abs(math.cos(e.phase))*.12*e.blend+math.sin(os.clock()*1.5)*.025)*e.scale,0)*CFrame.Angles(0,0,s*.035)
            e.joints.Head.Transform=CFrame.Angles(0,math.sin(os.clock()*.9)*.1*(1-e.blend),0)
        end
    end)
end
return Animator
