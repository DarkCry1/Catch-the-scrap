--!nonstrict
local CollectionService=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local Config=require(game:GetService("ReplicatedStorage").CatchTheScrapShared.Config)
local EnvironmentEffects={}
function EnvironmentEffects.start(player)
    local active={}
    local function attach(object)
        if object:IsA("Light") or object:IsA("ParticleEmitter") then object.Enabled=false;active[object]=true end
    end
    local function detach(object)
        active[object]=nil
        if object.Parent then object.Enabled=false end
    end
    CollectionService:GetInstanceAddedSignal("YardAmbientEffect"):Connect(attach)
    CollectionService:GetInstanceRemovedSignal("YardAmbientEffect"):Connect(detach)
    for _,object in CollectionService:GetTagged("YardAmbientEffect") do attach(object) end
    local elapsed=0
    RunService.Heartbeat:Connect(function(dt)
        elapsed+=dt;if elapsed<Config.Visuals.EffectInterval then return end;elapsed=0
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        for object in active do
            local parent=object.Parent
            local position=if parent and parent:IsA("Attachment") then parent.WorldPosition elseif parent and parent:IsA("BasePart") then parent.Position else nil
            local visible=root~=nil and position~=nil and (root.Position-position).Magnitude<=Config.Visuals.EffectDistance
            if object.Enabled~=visible then object.Enabled=visible end
        end
    end)
end
return EnvironmentEffects
