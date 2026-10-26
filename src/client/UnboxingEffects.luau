--!nonstrict
local CollectionService=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Motion=require(Shared.WorkshopMotion)
local Parts=require(script.Parent.EffectParts)
local Effects={}
function Effects.start(player)
    local entries,pending={},{}
    local folder=Instance.new("Folder");folder.Name="LocalUnboxingEffects";folder.Parent=workspace
    local gold=Color3.fromRGB(255,209,112)
    local function near(position)
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        return root and (root.Position-position).Magnitude<Config.Presentation.Distance
    end
    local function detach(model)
        pending[model]=nil
        local entry=entries[model]
        if not entry then return end
        if entry.glow then entry.glow:Destroy() end
        if entry.highlight then entry.highlight:Destroy() end
        if model.Parent then
            if entry.kind=="Robot" then model:ScaleTo(1);model:PivotTo(entry.origin)
            else for _,item in entry.parts do if item.part.Parent then item.part.CFrame=entry.origin*item.localFrame;item.part.LocalTransparencyModifier=0 end end end
        end
        entries[model]=nil
    end
    local function box(model)
        local token={};pending[model]=token
        task.spawn(function()
            if not model:WaitForChild("BoxBottom",10) or pending[model]~=token then return end
            pending[model]=nil
            local origin=model:GetAttribute("Origin");local start=model:GetAttribute("StartedAt")
            if not origin or not start then return end
            local entry={kind="Box",model=model,origin=origin,start=start,parts={}}
            for _,part in model:GetChildren() do
                if part:IsA("BasePart") then table.insert(entry.parts,{part=part,localFrame=origin:ToObjectSpace(part.CFrame)}) end
            end
            entries[model]=entry
        end)
    end
    local function robot(model)
        local token={};pending[model]=token
        task.spawn(function()
            if not model:WaitForChild("Reactor",10) or pending[model]~=token then return end
            pending[model]=nil
            local started=model:GetAttribute("RevealAt")
            if not started or workspace:GetServerTimeNow()-started>1.2 then return end
            local origin=model:GetAttribute("RevealOrigin") or model:GetPivot()
            model.WorldPivot=origin
            entries[model]={kind="Robot",model=model,origin=origin,start=started}
        end)
    end
    for tag,attach in {OpeningRobotBox=box,RecoveredRobotReveal=robot} do
        CollectionService:GetInstanceAddedSignal(tag):Connect(attach)
        CollectionService:GetInstanceRemovedSignal(tag):Connect(detach)
        for _,model in CollectionService:GetTagged(tag) do attach(model) end
    end
    RunService.RenderStepped:Connect(function()
        local now=workspace:GetServerTimeNow()
        for model,entry in entries do
            if not model.Parent then detach(model);continue end
            local visible=near(entry.origin.Position)
            local t=math.max(0,now-entry.start)
            if entry.kind=="Robot" then
                if not visible or t>1.15 then detach(model);continue end
                local recipe=Config.Robot.Recipes[model:GetAttribute("Rarity")]
                if not entry.burst and recipe then
                    entry.burst=true
                    local tint=Color3.fromRGB(unpack(recipe.Color))
                    Parts.burst(folder,entry.origin*CFrame.new(0,3.5,0),tint,32)
                    local highlight=Instance.new("Highlight");highlight.Adornee=model;highlight.FillColor=tint;highlight.OutlineColor=tint
                    highlight.FillTransparency=.75;highlight.OutlineTransparency=.1;highlight.DepthMode=Enum.HighlightDepthMode.Occluded
                    highlight.Parent=folder;entry.highlight=highlight
                end
                local p=math.clamp(t/.8,0,1)
                local scale=1+2.7*(p-1)^3+1.7*(p-1)^2
                model:ScaleTo(math.max(.12,scale));model:PivotTo(entry.origin*CFrame.new(0,math.sin(p*math.pi)*1.3,0)*CFrame.Angles(0,(1-p)*math.rad(25),0))
                if entry.highlight then entry.highlight.FillTransparency=.75+p*.25;entry.highlight.OutlineTransparency=.1+p*.9 end
            elseif visible then
                local shake,angle,glow=Motion.unbox(t)
                local frame=entry.origin*CFrame.Angles(shake,shake*.5,-shake)
                for _,item in entry.parts do
                    local part=item.part
                    if part.Name=="FlapLeft" or part.Name=="FlapRight" then
                        local side=if part.Name=="FlapLeft" then -1 else 1
                        part.CFrame=frame*CFrame.new(side*2.08,2.08,0)*CFrame.Angles(0,0,-side*angle)*CFrame.new(-side*1.04,0,0)
                    else
                        part.CFrame=frame*item.localFrame
                        if part.Name=="TopTape" then part.LocalTransparencyModifier=if t>.85 then 1 else 0 end
                    end
                end
                if glow>0 then
                    if not entry.glow then
                        entry.glow=Parts.new(folder,"MysteryLight",Vector3.new(5,2.7,2.7),entry.origin*CFrame.new(0,1.7,0)*CFrame.Angles(0,0,math.pi/2),gold,Enum.Material.Neon,Enum.PartType.Cylinder)
                        local light=Instance.new("PointLight");light.Color=gold;light.Range=12;light.Brightness=1.2;light.Shadows=false;light.Parent=entry.glow
                    end
                    entry.glow.Transparency=1-glow*.22
                    if not entry.burst and angle>1.4 then entry.burst=true;Parts.burst(folder,entry.origin*CFrame.new(0,2,0),gold,18) end
                end
            elseif entry.glow then entry.glow:Destroy();entry.glow=nil end
        end
    end)
end
return Effects
