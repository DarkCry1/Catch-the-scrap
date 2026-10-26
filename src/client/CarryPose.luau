--!nonstrict
-- Procedural R6/R15 overhead pose; no uploaded animation assets required.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Motion=require(Shared.WorkshopMotion)
local Config=require(Shared.Config)
local Pose={}
local names={LeftShoulder={"Shoulder",-1},RightShoulder={"Shoulder",1},["Left Shoulder"]={"Shoulder",-1},["Right Shoulder"]={"Shoulder",1},LeftElbow={"Elbow",-1},RightElbow={"Elbow",1},LeftWrist={"Wrist",-1},RightWrist={"Wrist",1}}
function Pose.start(localPlayer)
    local entries={}
    local function restore(entry)
        for _,item in entry.joints or {} do
            if item.joint.Parent and item.baseline then item.joint.Transform=item.baseline;item.baseline=nil end
        end
    end
    local function observe(player) entries[player]={player=player,alpha=0,joints={}} end
    for _,player in Players:GetPlayers() do observe(player) end
    Players.PlayerAdded:Connect(observe)
    Players.PlayerRemoving:Connect(function(player)
        if entries[player] then restore(entries[player]);entries[player]=nil end
    end)
    -- Return our previous override before Animator evaluates the next walk/idle frame.
    RunService.PreAnimation:Connect(function() for _,entry in entries do restore(entry) end end)
    local elapsed=.3
    RunService.PreSimulation:Connect(function(dt)
        elapsed+=dt
        if elapsed>=.25 then
            elapsed=0
            local localRoot=localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
            for player,entry in entries do
                local character=player.Character
                if entry.character~=character then restore(entry);entry.character=character;entry.joints={};entry.alpha=0 end
                local root=character and character:FindFirstChild("HumanoidRootPart")
                local humanoid=character and character:FindFirstChildOfClass("Humanoid")
                entry.carrying=root and humanoid and humanoid.Health>0 and (player:GetAttribute("CarriedName") or "")~="" and localRoot and (localRoot.Position-root.Position).Magnitude<Config.Presentation.Distance
                if entry.carrying and #entry.joints==0 then
                    for _,joint in character:GetDescendants() do
                        local spec=names[joint.Name]
                        if spec and joint:IsA("Motor6D") then table.insert(entry.joints,{joint=joint,kind=spec[1],side=spec[2]}) end
                    end
                end
            end
        end
        local now=os.clock()
        for _,entry in entries do
            entry.alpha+=( (if entry.carrying then 1 else 0)-entry.alpha)*(1-math.exp(-14*dt))
            if entry.alpha<.002 and not entry.carrying then entry.alpha=0;continue end
            for _,item in entry.joints do
                local joint=item.joint
                if not joint.Parent then continue end
                local target
                if item.kind=="Shoulder" then
                    local x,y,z=Motion.arm(now,item.side)
                    local axes=joint.C0.Rotation
                    target=axes:Inverse()*CFrame.Angles(x,y,z)*axes
                else
                    target=CFrame.Angles(math.rad(if item.kind=="Elbow" then 22 else -8),0,0)
                end
                item.baseline=joint.Transform
                joint.Transform=item.baseline:Lerp(target,entry.alpha)
            end
        end
    end)
end
return Pose
