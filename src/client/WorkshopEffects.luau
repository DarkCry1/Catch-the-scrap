--!nonstrict
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Motion=require(Shared.WorkshopMotion)
local PickupBlueprint=require(Shared.PickupBlueprint)
local Parts=require(script.Parent.EffectParts)
local Effects={}
function Effects.start(player,remote)
    local crushers,active,lastSerial={},{},{}
    local folder=Instance.new("Folder");folder.Name="LocalWorkshopEffects";folder.Parent=workspace
    local function near(position)
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        return root and (root.Position-position).Magnitude<=Config.Presentation.Distance
    end
    local pending={}
    local function attach(model)
        local token={};pending[model]=token
        task.spawn(function()
            local first=model:WaitForChild("Rotor1",10)
            local second=model:WaitForChild("Rotor2",10)
            local outlet=model:WaitForChild("SparkOutlet",10)
            local press=model:WaitForChild("PressPlate",10)
            if pending[model]~=token then return end
            local origin=model:GetAttribute("Origin")
            if not origin or not first or not second or not outlet or not press or not model.Parent then return end
            local entry={model=model,origin=origin,rotors={},angle=0}
            for _,child in {first,second} do
                local pivot=child:GetAttribute("Origin")
                child.WorldPivot=pivot
                table.insert(entry.rotors,{model=child,origin=pivot,direction=child:GetAttribute("Direction")})
            end
            entry.sparks=outlet:WaitForChild("CuttingSparks",5);entry.light=outlet:WaitForChild("CuttingGlow",5)
            entry.press=press;entry.edge=model:WaitForChild("PressEdge",5)
            if model.Parent and pending[model]==token then pending[model]=nil;crushers[model]=entry end
        end)
    end
    local function detach(model)
        pending[model]=nil
        local entry=crushers[model]
        if entry and entry.light then entry.light.Enabled=false end
        crushers[model]=nil
    end
    CollectionService:GetInstanceAddedSignal("ScrapCrusher"):Connect(attach)
    CollectionService:GetInstanceRemovedSignal("ScrapCrusher"):Connect(detach)
    for _,model in CollectionService:GetTagged("ScrapCrusher") do attach(model) end
    remote.OnClientEvent:Connect(function(channel,payload)
        if channel~="Crusher" or type(payload)~="table" then return end
        if typeof(payload.origin)~="CFrame" or typeof(payload.start)~="CFrame" or type(payload.serial)~="number" or type(payload.time)~="number" then return end
        if not Config.Robot.Recipes[payload.rarity] or not near(payload.origin.Position) then return end
        if payload.serial<=(lastSerial[payload.baseIndex] or 0) then return end
        lastSerial[payload.baseIndex]=payload.serial
        local age=workspace:GetServerTimeNow()-payload.time
        if age<-.5 or age>Config.Presentation.CrushSeconds then return end
        local previous=active[payload.baseIndex]
        if previous then previous.model:Destroy();for _,bit in previous.bits do bit.part:Destroy() end end
        local tint=Config.Robot.Recipes[payload.rarity].Color
        local model=Parts.model("GrindingScrap",PickupBlueprint.build(payload.rarity,tint),payload.start,folder)
        active[payload.baseIndex]={model=model,start=payload.start,origin=payload.origin,time=payload.time,bits={},seed=payload.serial,tint=Color3.fromRGB(unpack(tint))}
    end)
    RunService.RenderStepped:Connect(function(dt)
        local now=workspace:GetServerTimeNow()
        for model,entry in crushers do
            local visible=model.Parent and near(entry.origin.Position)
            local untilTime=model.Parent and model.Parent:GetAttribute("CrusherActiveUntil") or 0
            local running=visible and now<(untilTime or 0)
            if entry.light then entry.light.Enabled=running;entry.light.Brightness=1.2+math.sin(now*42)*.5 end
            if visible then
                entry.angle+=(if running then 17 else .7)*dt
                for _,rotor in entry.rotors do rotor.model:PivotTo(rotor.origin*CFrame.Angles(entry.angle*rotor.direction,0,0)) end
                local press=if running then (math.sin(now*20)*.5+.5)*1.1 else 0
                if entry.press then entry.press.CFrame=entry.origin*CFrame.new(0,6.1-press,-12) end
                if entry.edge then entry.edge.CFrame=entry.origin*CFrame.new(0,5.9-press,-9.1) end
                entry.sparkClock=(entry.sparkClock or 0)+dt
                if running and entry.sparks and entry.sparkClock>.12 then entry.sparkClock=0;entry.sparks:Emit(9) end
            end
        end
        for index,entry in active do
            local t=now-entry.time
            if t>Config.Presentation.CrushSeconds or not near(entry.origin.Position) then
                entry.model:Destroy();for _,bit in entry.bits do bit.part:Destroy() end;active[index]=nil;continue
            end
            local pull,scale,fade=Motion.crush(t)
            local target=entry.origin*CFrame.new(0,3.5,-12)
            local frame=entry.start:Lerp(target,pull)
            if t>.55 then frame*=CFrame.Angles(math.sin(t*58)*.12,t*5,math.cos(t*61)*.1) end
            entry.model:PivotTo(frame);entry.model:ScaleTo(math.max(.06,scale))
            for _,part in entry.model:GetChildren() do part.Transparency=fade end
            if t>.65 and #entry.bits==0 then
                local random=Random.new(entry.seed)
                for _=1,math.min(8,Config.Presentation.MaxDebris) do
                    local velocity=Vector3.new(random:NextNumber(-6,6),random:NextNumber(5,10),random:NextNumber(2,7))
                    local part=Parts.new(folder,"MetalOffcut",Vector3.new(.18,.12,.3),target,entry.tint)
                    table.insert(entry.bits,{part=part,velocity=entry.origin:VectorToWorldSpace(velocity),start=target.Position,time=t})
                end
            end
            for _,bit in entry.bits do
                local age=t-bit.time
                bit.part.CFrame=CFrame.new(bit.start+bit.velocity*age+Vector3.new(0,-15,0)*age^2)*CFrame.Angles(age*9,age*5,0)
                bit.part.Transparency=math.clamp(age/.9,0,1)
            end
        end
    end)
end
return Effects
