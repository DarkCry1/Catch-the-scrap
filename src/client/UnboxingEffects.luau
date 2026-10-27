--!nonstrict
local CollectionService=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Catalog=require(Shared.RobotCatalog)
local Variants=require(Shared.RobotVariants)
local Parts=require(script.Parent.EffectParts)
local Style=require(Shared.RarityStyle)
local Visuals=require(script.Parent.RarityVisuals)
local Camera=require(script.Parent.OpeningCamera)
local Effects={}
function Effects.start(player)
    local entries,pending={},{}
    local folder=Instance.new("Folder");folder.Name="LocalUnboxingEffects";folder.Parent=workspace
    local function near(position)
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        return root and (root.Position-position).Magnitude<Config.Presentation.Distance
    end
    local function clearFx(entry)
        if entry.fx then entry.fx:Destroy();entry.fx=nil;entry.rings=nil;entry.caption=nil;entry.ghost=nil;entry.ghostId=nil;entry.shards=nil;entry.orb=nil;entry.light=nil end
        if entry.highlight then entry.highlight:Destroy();entry.highlight=nil end
    end
    local function detach(model)
        pending[model]=nil
        local entry=entries[model];if not entry then return end
        clearFx(entry)
        if model.Parent then
            if entry.kind=="Robot" then model:ScaleTo(1);model:PivotTo(entry.origin)
            else for _,item in entry.parts do if item.part.Parent then item.part.CFrame=entry.origin*item.localFrame;item.part.LocalTransparencyModifier=0 end end end
        end
        entries[model]=nil
    end
    local function attach(model,kind)
        local token={};pending[model]=token
        task.spawn(function()
            if not model:WaitForChild(if kind=="Robot" then "Reactor" else "BoxBottom",10) or pending[model]~=token then return end
            pending[model]=nil
            local start=model:GetAttribute(if kind=="Robot" then "RevealAt" else "StartedAt")
            if not start or (kind=="Robot" and workspace:GetServerTimeNow()-start>1.5) then return end
            local origin=model:GetAttribute(if kind=="Robot" then "RevealOrigin" else "Origin") or model:GetPivot()
            model.WorldPivot=origin
            local rarity=model:GetAttribute("Rarity") or "Rare"
            local entry={kind=kind,model=model,origin=origin,start=start,parts={},rarity=rarity,profile=Style.get(rarity),choices={},owner=model:GetAttribute("OwnerUserId")}
            for _,part in model:GetChildren() do if part:IsA("BasePart") then table.insert(entry.parts,{part=part,localFrame=origin:ToObjectSpace(part.CFrame)}) end end
            local recipe=Config.Robot.Recipes[model:GetAttribute("Rarity")]
            entry.tint=Color3.fromRGB(unpack(if recipe then recipe.Color else {255,210,110}))
            for _,v in Catalog.List do if Catalog.canAcquire(rarity,v.Id,"Box") then table.insert(entry.choices,v) end end
            entries[model]=entry
            if kind=="Box" then Camera.play(player,origin,rarity,start,model:GetAttribute("OwnerUserId"),model) end
        end)
    end
    for tag,kind in {OpeningRobotBox="Box",RecoveredRobotReveal="Robot"} do
        local thisKind=kind
        CollectionService:GetInstanceAddedSignal(tag):Connect(function(model) attach(model,thisKind) end)
        CollectionService:GetInstanceRemovedSignal(tag):Connect(detach)
        for _,model in CollectionService:GetTagged(tag) do attach(model,thisKind) end
    end
    local function makeFx(entry)
        local fx=Instance.new("Folder");fx.Name="UnboxingStage";fx.Parent=folder;entry.fx=fx;entry.rings={}
        for ring=1,entry.profile.Rings do
            for segment=0,15 do
                local part=Parts.new(fx,"EnergyArc",Vector3.new(.7,.09,.13),entry.origin,entry.tint,Enum.Material.Neon)
                table.insert(entry.rings,{part=part,ring=ring,angle=segment*math.pi/8})
            end
        end
        entry.shards={}
        for shard=1,entry.profile.Shards do
            local part=Parts.new(fx,"OrbitingCrystal",Vector3.new(.18,.85,.18),entry.origin,entry.tint,Enum.Material.Neon)
            table.insert(entry.shards,{part=part,phase=shard/math.max(1,entry.profile.Shards)})
        end
        if entry.profile.Rank>=4 then
            entry.orb=Parts.new(fx,"ReactorSphere",Vector3.one,entry.origin,entry.tint,Enum.Material.Neon,Enum.PartType.Ball)
            entry.orb.Transparency=.88
        end
        local anchor=Parts.new(fx,"ScanCaption",Vector3.one*.1,entry.origin*CFrame.new(0,5.5,0),entry.tint);anchor.Transparency=1
        local board=Instance.new("BillboardGui");board.Size=UDim2.fromOffset(300,64);board.MaxDistance=95;board.Parent=anchor
        local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.TextColor3=entry.tint
        label.Font=Enum.Font.GothamBlack;label.TextSize=21;label.TextStrokeTransparency=.25;label.TextWrapped=true;label.AutoLocalize=false;label.Parent=board;entry.caption=label
        local light=Instance.new("PointLight");light.Color=entry.tint;light.Range=13;light.Shadows=false;light.Brightness=1.5;light.Parent=anchor;entry.light=light
    end
    local function ghost(entry,id)
        if entry.ghostId==id then return end
        if entry.ghost then entry.ghost:Destroy() end
        local details={}
        for _,d in Variants.build(id) do
            table.insert(details,{name=d.name,size=d.size,position=d.position,shape=d.shape,yaw=d.yaw,roll=d.roll,color={entry.tint.R*255,entry.tint.G*255,entry.tint.B*255},material="Neon"})
        end
        entry.ghost=Parts.model("ScanningHologram",details,entry.origin,entry.fx);entry.ghost:ScaleTo(.25)
        for _,part in entry.ghost:GetChildren() do part.Transparency=.6 end
        entry.ghostId=id
    end
    RunService.RenderStepped:Connect(function()
        local now=workspace:GetServerTimeNow()
        for model,entry in entries do
            if not model.Parent then detach(model);continue end
            local visible=near(entry.origin.Position);local age=math.max(0,now-entry.start)
            local t=if entry.kind=="Box" then age/entry.profile.Duration*5.6 else age
            entry.tint=Visuals.color(entry.rarity,now)
            if entry.kind=="Robot" then
                if not visible or t>1.5 then detach(model);continue end
                if not entry.burst then
                    entry.burst=true;Parts.burst(folder,entry.origin*CFrame.new(0,3.5,0),entry.tint,45)
                    local h=Instance.new("Highlight");h.Adornee=model;h.FillColor=entry.tint;h.OutlineColor=entry.tint;h.FillTransparency=.5;h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Parent=folder;entry.highlight=h
                end
                local p=math.clamp(t/1.05,0,1);local scale=1+2.7*(p-1)^3+1.7*(p-1)^2
                model:ScaleTo(math.max(.08,scale))
                model:PivotTo(entry.origin*CFrame.new(0,math.sin(p*math.pi)*.9,0)*CFrame.Angles(0,(1-p)*math.pi*.8,0))
                if entry.highlight then entry.highlight.FillTransparency=.5+p*.5;entry.highlight.OutlineTransparency=p end
            elseif visible then
                if not entry.fx then
                    local count=0;for _,other in entries do if other.fx then count+=1 end end
                    if count>=Config.Visuals.CinematicBudget and entry.owner==player.UserId then
                        for _,other in entries do if other.fx and other.owner~=player.UserId then clearFx(other);count-=1;break end end
                    end
                    if count>=Config.Visuals.CinematicBudget then continue end
                    makeFx(entry)
                end
                local charge=math.clamp(t/1.4,0,1)
                local shake=math.sin(t*(22+t*7))*.065*charge*(1-math.clamp((t-1.4)/.7,0,1))
                local opening=math.clamp((t-1.45)/.85,0,1);local angle=(1-(1-opening)^3)*math.rad(135)
                local launch=math.clamp((t-4.15)/1.1,0,1)
                local frame=entry.origin*CFrame.new(0,math.sin(t*8)*.05*charge,0)*CFrame.Angles(shake,shake*.4,-shake)
                for _,item in entry.parts do
                    local part=item.part;local name=part.Name
                    if name=="FlapLeft" or name=="FlapRight" then
                        local side=if name=="FlapLeft" then -1 else 1
                        part.CFrame=frame*CFrame.new(side*2.08,2.08,0)*CFrame.Angles(0,0,-side*angle)*CFrame.new(-side*(1.04+launch*3),launch*2,0)
                    else
                        local p=item.localFrame.Position
                        local outward=if math.abs(p.X)>math.abs(p.Z) then Vector3.new(if p.X<0 then -1 else 1,0,0) else Vector3.new(0,0,if p.Z<0 then -1 else 1)
                        part.CFrame=frame*item.localFrame*CFrame.new(outward*launch*3+Vector3.new(0,math.sin(launch*math.pi)*1.8,0))*CFrame.Angles(launch*.5,launch*.4,0)
                    end
                    part.LocalTransparencyModifier=if name=="TopTape" and t>1.25 then 1 else launch
                end
                for _,arc in entry.rings do
                    local radius=(if arc.ring==1 then 2.8 else 1.8)+charge*.5+launch*4
                    local a=arc.angle+t*(if arc.ring==1 then 1.7 else -2.3)
                    local y=if arc.ring==1 then -1.95 else 1+(arc.ring-2)*.5+math.sin(t*3+arc.ring)*.25
                    local tilt=if arc.ring<=2 then CFrame.identity else CFrame.Angles(math.rad(25*(arc.ring-2)),0,math.rad(20*math.sin(t*.5)))
                    arc.part.CFrame=entry.origin*CFrame.new(0,y,0)*tilt*CFrame.new(math.cos(a)*radius,0,math.sin(a)*radius)*CFrame.Angles(0,-a+math.pi/2,0)
                    arc.part.Color=Visuals.color(entry.rarity,now,arc.angle/(2*math.pi))
                    arc.part.Size=Vector3.new(radius*.34,.09,.13);arc.part.Transparency=.7-charge*.45+launch*.3
                end
                for _,shard in entry.shards do
                    local a=shard.phase*math.pi*2+t*1.6
                    local radius=2.8+charge+launch*3
                    shard.part.CFrame=entry.origin*CFrame.new(math.cos(a)*radius,1+math.sin(a*2)*1.6+launch*2,math.sin(a)*radius)*CFrame.Angles(t*2,a,.6)
                    shard.part.Color=Visuals.color(entry.rarity,now,shard.phase)
                    shard.part.Transparency=.15+launch*.5
                end
                if entry.orb then
                    entry.orb.Size=Vector3.one*(1+charge*2.5+launch*3)
                    entry.orb.CFrame=entry.origin*CFrame.new(0,1.5,0);entry.orb.Color=entry.tint
                end
                entry.caption.TextColor3=entry.tint;entry.light.Color=entry.tint
                entry.light.Brightness=1+charge*2+math.sin(t*25)*.3
                entry.caption.Text=if t<1.45 then "REACTOR CHARGING..." elseif t<4.15 then "IDENTIFYING ROBOT..." else "SIGNAL CONFIRMED!"
                if t>=2 and t<4.15 then
                    local index=math.floor((t-2)*4)%math.max(1,#entry.choices)+1
                    ghost(entry,entry.choices[index].Id)
                    entry.ghost:PivotTo(entry.origin*CFrame.new(0,1.9+math.sin(t*5)*.2,0)*CFrame.Angles(0,t*2,0))
                elseif entry.ghost then entry.ghost:Destroy();entry.ghost=nil;entry.ghostId=nil end
                if t>4.15 and not entry.burst then entry.burst=true;Parts.burst(folder,entry.origin*CFrame.new(0,2.5,0),entry.tint,40) end
            else clearFx(entry) end
        end
    end)
end
return Effects
