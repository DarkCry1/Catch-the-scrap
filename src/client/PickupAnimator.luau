--!nonstrict
local CollectionService=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Motion=require(Shared.PickupMotion)
local PickupAnimator={}
function PickupAnimator.start(player)
    local records,nearby,pending={},{},{}
    local function reset(entry)
        if entry.joint.Parent then entry.joint.C0=CFrame.identity end
        for _,part in entry.halo do if part.Parent then part.LocalTransparencyModifier=1 end end
    end
    local function attach(model)
        if records[model] or pending[model] then return end
        local token={};pending[model]=token
        task.spawn(function()
            -- Initial replication/stream-in may deliver the tag before the rig children.
            local root=model:WaitForChild("CarryRoot",10)
            local joint=root and root:WaitForChild("IdleJoint",10)
            local halo=model:WaitForChild("GroundHalo",10)
            if pending[model]~=token then return end
            pending[model]=nil
            if not joint or not halo or not model.Parent then return end
            local entry={model=model,root=root,joint=joint,halo=halo:GetChildren(),phase=model:GetAttribute("IdlePhase") or 0}
            records[model]=entry
            entry.connection=model:GetAttributeChangedSignal("CarrierUserId"):Connect(function()
                if model:GetAttribute("CarrierUserId") then nearby[entry]=nil;reset(entry) end
            end)
            reset(entry)
        end)
    end
    local function detach(model)
        pending[model]=nil
        local entry=records[model]
        if not entry then return end
        records[model]=nil;nearby[entry]=nil;entry.connection:Disconnect();reset(entry)
    end
    CollectionService:GetInstanceAddedSignal("AnimatedScrap"):Connect(attach)
    CollectionService:GetInstanceRemovedSignal("AnimatedScrap"):Connect(detach)
    for _,model in CollectionService:GetTagged("AnimatedScrap") do attach(model) end
    local elapsed=Config.Visuals.PickupInterval
    RunService.RenderStepped:Connect(function(dt)
        elapsed+=dt
        if elapsed>=Config.Visuals.PickupInterval then
            elapsed=0
            local character=player.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            for model,entry in records do
                local visible=root and model.Parent and not model:GetAttribute("CarrierUserId") and (root.Position-entry.root.Position).Magnitude<=Config.Visuals.PickupDistance
                if visible then nearby[entry]=true elseif nearby[entry] then nearby[entry]=nil;reset(entry) end
            end
        end
        local now=os.clock()
        for entry in nearby do
            local bob,yaw,tilt,pulse=Motion.sample(now,entry.phase)
            entry.joint.C0=CFrame.new(0,bob,0)*CFrame.Angles(tilt,yaw,0)
            for _,part in entry.halo do part.LocalTransparencyModifier=1-pulse end
        end
    end)
end
return PickupAnimator
