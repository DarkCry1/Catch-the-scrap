--!nonstrict
-- Guard robots (v1.7). Hover security bots stand watch in every stage. When a
-- player steals scrap or a robot box there, every idle guard of that stage
-- within AlertRange raises the alarm and, after a short reaction, chases the
-- thief at the stage's speed (Config.Guards.Speed). Speeds grow per stage, so
-- reaching the higher rarities needs Speed and Strength upgrades.
--
-- A guard that reaches the thief zaps them: the loot goes back to the yard
-- (banked progress is never touched), the player is knocked back and slowed
-- for a moment. Guards give up when the thief leaves the stage, drops or
-- delivers the loot, dies, or after MaxChase seconds, then return to post.
-- Movement uses a Humanoid (smooth, physical, collides with the yard);
-- Service.build can be replaced in tests.
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Blueprint=require(Shared.GuardBlueprint)
local HudModel=require(Shared.HudModel)
local Guards={}
Guards.__index=Guards
Guards.Step=0.1

local function weldPart(model,root,name,size,cframe,color,material,shape)
    local p=Instance.new("Part");p.Name=name;p.Size=size;p.Color=color;p.Material=material or Enum.Material.Metal
    if shape then p.Shape=shape end
    p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;p.Anchored=false;p.CastShadow=false
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    p.CFrame=root.CFrame*cframe;p.Parent=model
    local weld=Instance.new("WeldConstraint");weld.Part0=root;weld.Part1=p;weld.Parent=p
    return p
end

-- Builds one giant guard robot standing at position (yard floor, y = 0),
-- from the shared GuardBlueprint scaled by Config.Guards.Scale[stage].
function Guards.build(parent,name,position,stage)
    local settings=Config.Guards
    local scale=settings.Scale[stage] or 2
    local tint=Color3.fromRGB(unpack(Config.Stages[stage].Color))
    local palette={dark=Color3.fromRGB(34,38,46),steel=Color3.fromRGB(120,132,146),navy=Color3.fromRGB(28,40,66),tint=tint,
        gold=Color3.fromRGB(255,196,60),cyan=Color3.fromRGB(110,220,255),visor=Color3.fromRGB(255,196,60),siren=Color3.fromRGB(80,30,30)}
    local model=Instance.new("Model");model.Name=name
    local rootSize=Vector3.new(2,2,1)*scale
    local hip=settings.HipHeight*scale
    local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=rootSize;root.Transparency=1
    -- Non-colliding root: giants glide over junk piles instead of getting stuck.
    root.CanCollide=false;root.CanQuery=false;root.CanTouch=false;root.CFrame=CFrame.new(position+Vector3.new(0,hip+rootSize.Y/2,0));root.Parent=model
    model.PrimaryPart=root
    local named={}
    for _,d in Blueprint.forStage(stage) do
        local offset=CFrame.new(d.position[1]*scale,d.position[2]*scale,d.position[3]*scale)*CFrame.Angles(math.rad(d.rotation[1]),math.rad(d.rotation[2]),math.rad(d.rotation[3]))
        local p=weldPart(model,root,d.name,Vector3.new(d.size[1],d.size[2],d.size[3])*scale,offset,palette[d.color],Enum.Material[d.material],Enum.PartType[d.shape])
        named[d.name]=named[d.name] or p
    end
    local thrust=Instance.new("ParticleEmitter");thrust.Name="Thruster";thrust.Texture="rbxasset://textures/particles/fire_main.dds";thrust.EmissionDirection=Enum.NormalId.Left
    thrust.Rate=22;thrust.Lifetime=NumberRange.new(.25,.45);thrust.Speed=NumberRange.new(5*scale,7*scale);thrust.LightEmission=1
    thrust.Size=NumberSequence.new(.9*scale,0);thrust.Color=ColorSequence.new(Color3.fromRGB(120,220,255),tint);thrust.Parent=named.Underglow
    local glow=Instance.new("PointLight");glow.Name="HoverGlow";glow.Color=tint;glow.Range=10*scale;glow.Brightness=1.2;glow.Parent=named.Underglow
    local visor=named.Visor
    local search=Instance.new("SpotLight");search.Name="Searchlight";search.Face=Enum.NormalId.Front;search.Angle=38;search.Range=22*scale;search.Brightness=2.2
    search.Color=Color3.fromRGB(255,214,140);search.Shadows=false;search.Parent=visor
    local siren=named.Siren
    local light=Instance.new("PointLight");light.Name="SirenLight";light.Color=Color3.fromRGB(255,50,40);light.Range=12*scale;light.Brightness=3;light.Enabled=false;light.Parent=siren
    -- Alarm marker.
    local mark=Instance.new("BillboardGui");mark.Name="Alarm";mark.Size=UDim2.fromOffset(160,56);mark.StudsOffset=Vector3.new(0,(Blueprint.height(settings.HipHeight)-settings.HipHeight)*scale,0)
    mark.AlwaysOnTop=true;mark.MaxDistance=180;mark.Enabled=false;mark.Parent=root
    local text=Instance.new("TextLabel");text.Name="Text";text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.Font=Enum.Font.GothamBlack;text.TextScaled=true
    text.TextColor3=Color3.fromRGB(255,70,60);text.TextStrokeTransparency=.2;text.Text="!";text.AutoLocalize=false;text.Parent=mark
    local humanoid=Instance.new("Humanoid");humanoid.RigType=Enum.HumanoidRigType.R15;humanoid.HipHeight=hip
    humanoid.WalkSpeed=Config.Guards.Speed[stage];humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;humanoid.JumpPower=50
    humanoid.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff;humanoid.BreakJointsOnDeath=false;humanoid.RequiresNeck=false;humanoid.Parent=model
    pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end)
    model:SetAttribute("Stage",stage);model:SetAttribute("Speed",Config.Guards.Speed[stage]);model:SetAttribute("State","Idle");model:SetAttribute("Scale",scale)
    game:GetService("CollectionService"):AddTag(model,"GuardRobot")
    model.Parent=parent
    pcall(function() root:SetNetworkOwner(nil) end)
    return {model=model,root=root,humanoid=humanoid,visor=visor,siren=siren,light=light,search=search,mark=mark,text=text,stripe=named.ChestStripe}
end

-- Guard posts: spread over the stage on a grid, nudged off obstacles.
function Guards.posts(stage,count,obstacles)
    local z0=Config.TrackStart+(stage-1)*Config.ZoneLength
    local half=Config.TrackWidth/2-16
    local posts={}
    local rows=math.ceil(count/2)
    for i=1,count do
        local row=math.ceil(i/2)
        local x=(if i%2==1 then -1 else 1)*half*(if rows>1 and row%2==0 then .3 else .62)
        if count%2==1 and i==count then x=0 end
        local z=z0+Config.ZoneLength*(row-.5)/rows
        for _=1,12 do
            local blocked=false
            for _,o in obstacles or {} do
                if math.abs(x-o.x)<=o.halfX+3 and math.abs(z-o.z)<=o.halfZ+3 then blocked=true;break end
            end
            if not blocked then break end
            x=math.clamp(x+7,-half,half);z+=5
        end
        table.insert(posts,Vector3.new(x,0,z))
    end
    return posts
end

function Guards.new(world,carry,remote,clock)
    local self=setmetatable({world=world,carry=carry,remote=remote,now=clock or os.clock,guards={},random=Random.new(),elapsed=0},Guards)
    local folder=Instance.new("Folder");folder.Name="GuardRobots";folder.Parent=world.root
    for stage,count in Config.Guards.Count do
        local z0=Config.TrackStart+(stage-1)*Config.ZoneLength
        for i,post in Guards.posts(stage,count,world.spawnObstacles) do
            local parts=Guards.build(folder,string.format("GuardRobot_S%d_%d",stage,i),post,stage)
            parts.stage=stage;parts.post=post;parts.z0=z0;parts.z1=z0+Config.ZoneLength;parts.state="Idle";parts.speed=Config.Guards.Speed[stage]
            parts.wanderAt=0;parts.lastPosition=post;parts.stuck=0
            -- Bigger guards reach farther with their batons.
            parts.scale=Config.Guards.Scale[stage] or 2;parts.reach=Config.Guards.CatchRange*(.5+.5*parts.scale)
            table.insert(self.guards,parts)
        end
    end
    return self
end

function Guards:start()
    RunService.Heartbeat:Connect(function(dt)
        self.elapsed+=dt
        if self.elapsed<Guards.Step then return end
        local step=self.elapsed;self.elapsed=0
        self:step(step)
    end)
end

local function alive(player)
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if humanoid and humanoid.Health>0 and root then return root,humanoid end
    return nil
end
local function flat(a,b) return Vector3.new(a.X-b.X,0,a.Z-b.Z).Magnitude end

function Guards:carrier(player)
    return self.carry.inventory.carrying[player.UserId]~=nil
end
function Guards.stageAt(z)
    local stage=math.floor((z-Config.TrackStart)/Config.ZoneLength)+1
    return if stage>=1 and stage<=#Config.Stages then stage else nil
end

function Guards:setState(guard,state,target)
    guard.state=state;guard.target=target
    guard.model:SetAttribute("State",state)
    guard.model:SetAttribute("TargetUserId",if target then target.UserId else nil)
    local hot=state=="Alert" or state=="Chase"
    guard.light.Enabled=hot
    guard.siren.Color=if hot then Color3.fromRGB(255,50,40) else Color3.fromRGB(80,30,30)
    guard.visor.Color=if hot then Color3.fromRGB(255,50,40) elseif state=="Cooldown" then Color3.fromRGB(90,160,255) else Color3.fromRGB(255,196,60)
    if guard.search then guard.search.Color=if hot then Color3.fromRGB(255,60,50) else Color3.fromRGB(255,214,140) end
    guard.mark.Enabled=hot
    guard.text.Text=if state=="Alert" then "!" else "STOP, THIEF!"
    guard.humanoid.WalkSpeed=if state=="Chase" then guard.speed else guard.speed*.45
end

-- Called when a player picks up scrap or a robot box.
function Guards:theft(player)
    local root=alive(player)
    if not root then return end
    local stage=Guards.stageAt(root.Position.Z)
    if not stage then return end
    -- New players learn the loop first: stage 1 guards only warn during the guide.
    if stage<=Config.Guards.GraceStage and (player:GetAttribute("TutorialStep") or 0)<HudModel.TutorialSteps then
        self.remote:FireClient(player,"Fx",{kind="GuardGrace",stage=stage})
        return 0
    end
    local now=self.now()
    local alerted=0
    for _,guard in self.guards do
        if guard.stage==stage and (guard.state=="Idle" or guard.state=="Return") and flat(guard.root.Position,root.Position)<=Config.Guards.AlertRange then
            self:setState(guard,"Alert",player);guard.chaseFrom=now+Config.Guards.Reaction;guard.chaseUntil=guard.chaseFrom+Config.Guards.MaxChase
            guard.humanoid:MoveTo(guard.root.Position)
            alerted+=1
        end
    end
    if alerted>0 then
        self.remote:FireClient(player,"Fx",{kind="GuardAlert",stage=stage,guards=alerted,guardSpeed=Config.Guards.Speed[stage],playerSpeed=player:GetAttribute("CarrySpeed") or 0})
    end
    return alerted
end

function Guards:attack(guard,player,root)
    local speed=player:GetAttribute("CarrySpeed") or 0
    self.carry:resetCarried(player,string.format("A Stage %d guard robot zapped you! The loot went back to the yard. Guard speed %d vs your %d: upgrade Speed and Strength at the Mechanic.",guard.stage,guard.speed,math.floor(speed)))
    local from=guard.root.Position
    self.remote:FireClient(player,"Fx",{kind="GuardAttack",from=from,to=root.Position,guardSpeed=guard.speed,playerSpeed=speed})
    if self.remote.FireAllClients then self.remote:FireAllClients("GuardZap",{from=from+Vector3.new(0,1,0),to=root.Position,stage=guard.stage}) end
    -- Short stun, then the normal carry speed comes back.
    local _,humanoid=alive(player)
    if humanoid then
        humanoid.WalkSpeed=Config.Guards.StunSpeed
        task.delay(Config.Guards.StunSeconds,function() if player.Parent then self.carry:writeState(player) end end)
    end
    if self.onCatch then self.onCatch(player) end
end

function Guards:release(guard,escaped)
    local player=guard.target
    if escaped and player and player.Parent then
        self.remote:FireClient(player,"Fx",{kind="GuardLost"})
        if self.onEscape then self.onEscape(player) end
    end
    self:setState(guard,"Return",nil)
    guard.humanoid:MoveTo(guard.post)
end

function Guards:step(dt)
    local now=self.now()
    local settings=Config.Guards
    local chased={}
    for _,guard in self.guards do
        local position=guard.root.Position
        if guard.state=="Alert" or guard.state=="Chase" then
            local player=guard.target
            local root=player and player.Parent and alive(player)
            local carrying=root and self:carrier(player)
            local inside=root and root.Position.Z>=guard.z0-settings.Leash and root.Position.Z<=guard.z1+settings.Leash
            if not root or not carrying or not inside or now>=guard.chaseUntil then
                -- Escaped when the thief still has the loot and is alive.
                self:release(guard,root~=nil and carrying)
            else
                chased[player]=true
                if guard.state=="Alert" and now>=guard.chaseFrom then self:setState(guard,"Chase",player) end
                if guard.state=="Chase" then
                    guard.humanoid:MoveTo(root.Position)
                    -- Hop over junk if the guard is stuck.
                    if (position-guard.lastPosition).Magnitude<guard.speed*dt*.2 then guard.stuck+=dt else guard.stuck=0 end
                    if guard.stuck>.6 then guard.humanoid.Jump=true;guard.stuck=0 end
                    if flat(position,root.Position)<=guard.reach and math.abs(position.Y-root.Position.Y)<8*guard.scale then
                        self:attack(guard,player,root)
                        self:setState(guard,"Cooldown",nil);guard.coolUntil=now+settings.Cooldown
                        guard.humanoid:MoveTo(position)
                    end
                end
            end
        elseif guard.state=="Cooldown" then
            if now>=guard.coolUntil then self:setState(guard,"Return",nil);guard.humanoid:MoveTo(guard.post) end
        elseif guard.state=="Return" then
            if flat(position,guard.post)<3 then self:setState(guard,"Idle",nil);guard.wanderAt=now+2
            else guard.humanoid:MoveTo(guard.post) end
        else
            -- Idle: stroll around the post now and then.
            if now>=guard.wanderAt then
                guard.wanderAt=now+self.random:NextNumber(3,6)
                local a=self.random:NextNumber(0,math.pi*2)
                local r=self.random:NextNumber(0,settings.IdleWander)
                guard.humanoid:MoveTo(guard.post+Vector3.new(math.cos(a)*r,0,math.sin(a)*r))
            end
        end
        guard.lastPosition=position
    end
    for player in self.carry.players do
        local value=chased[player]==true
        if player:GetAttribute("GuardChase")~=value then player:SetAttribute("GuardChase",value) end
    end
end
return Guards
