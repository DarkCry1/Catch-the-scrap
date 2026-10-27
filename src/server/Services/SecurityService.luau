--!nonstrict
-- Security drones patrol the Epic and higher districts. A drone that spots a
-- player carrying loot chases for a limited time; if it reaches them, the loot
-- is returned to its spawn (banked progress is never lost). After a chase the
-- drone overheats and cools down, so outrunning it or breaking line of travel
-- is a real escape. Players without loot are ignored.
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Security={}
Security.__index=Security
Security.Step=1/20

local function part(model,name,size,shape,color,material,offset,root)
    local p=Instance.new("Part");p.Name=name;p.Size=size;p.Shape=shape;p.Color=color;p.Material=material
    p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;p.Anchored=false;p.CastShadow=false
    p.CFrame=root.CFrame*offset;p.Parent=model
    local weld=Instance.new("WeldConstraint");weld.Part0=root;weld.Part1=p;weld.Parent=p
    return p
end

function Security.buildDrone(parent,name,position)
    local model=Instance.new("Model");model.Name=name;model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    local root=Instance.new("Part");root.Name="DroneRoot";root.Size=Vector3.new(1,1,1);root.Transparency=1;root.Anchored=true
    root.CanCollide=false;root.CanQuery=false;root.CanTouch=false;root.CFrame=CFrame.new(position);root.Parent=model;model.PrimaryPart=root
    local dark,steel=Color3.fromRGB(46,52,60),Color3.fromRGB(128,140,150)
    part(model,"Hull",Vector3.new(2.8,2.8,2.8),Enum.PartType.Ball,dark,Enum.Material.Metal,CFrame.new(),root)
    part(model,"ArmorBand",Vector3.new(.35,3.3,3.3),Enum.PartType.Cylinder,steel,Enum.Material.Metal,CFrame.Angles(0,0,math.pi/2),root)
    local eye=part(model,"Eye",Vector3.new(1,1,1),Enum.PartType.Ball,Color3.fromRGB(255,196,60),Enum.Material.Neon,CFrame.new(0,0,-1.25),root)
    part(model,"Lens",Vector3.new(.25,1.4,1.4),Enum.PartType.Cylinder,dark,Enum.Material.Metal,CFrame.new(0,0,-1.1)*CFrame.Angles(0,math.pi/2,0),root)
    for i=0,3 do
        local a=math.pi/4+i*math.pi/2
        local offset=Vector3.new(math.cos(a)*2.1,.35,math.sin(a)*2.1)
        part(model,"RotorArm",Vector3.new(2.2,.22,.3),Enum.PartType.Block,steel,Enum.Material.Metal,CFrame.new(offset/2)*CFrame.Angles(0,-a,0),root)
        part(model,"Rotor",Vector3.new(.12,1.7,1.7),Enum.PartType.Cylinder,Color3.fromRGB(30,34,38),Enum.Material.SmoothPlastic,CFrame.new(offset+Vector3.new(0,.2,0))*CFrame.Angles(0,0,math.pi/2),root)
        part(model,"RotorLight",Vector3.new(.3,.3,.3),Enum.PartType.Ball,Color3.fromRGB(255,80,60),Enum.Material.Neon,CFrame.new(offset+Vector3.new(0,-.2,0)),root)
    end
    local search=Instance.new("SpotLight");search.Name="Searchlight";search.Face=Enum.NormalId.Bottom;search.Angle=45;search.Range=26;search.Brightness=2.5
    search.Color=Color3.fromRGB(255,226,150);search.Shadows=false;search.Parent=eye
    local siren=Instance.new("PointLight");siren.Name="Siren";siren.Range=16;siren.Brightness=3;siren.Color=Color3.fromRGB(255,50,40);siren.Enabled=false;siren.Parent=eye
    model.Parent=parent
    return model,root,eye,siren
end

function Security.new(world,carry,remote,clock)
    local self=setmetatable({world=world,carry=carry,remote=remote,now=clock or os.clock,drones={},random=Random.new(),elapsed=0},Security)
    local folder=Instance.new("Folder");folder.Name="SecurityDrones";folder.Parent=world.root
    for stage,count in Config.Drones.Stages do
        local z0=Config.TrackStart+(stage-1)*Config.ZoneLength
        for i=1,count do
            local position=Vector3.new((i-.5-count/2)*30,Config.Drones.Height,z0+Config.ZoneLength*(i/(count+1)))
            local model,root,eye,siren=Security.buildDrone(folder,string.format("SecurityDrone_S%d_%d",stage,i),position)
            table.insert(self.drones,{model=model,root=root,eye=eye,siren=siren,stage=stage,z0=z0,z1=z0+Config.ZoneLength,position=position,state="Patrol",phase=i*1.7})
        end
    end
    return self
end

function Security:start()
    RunService.Heartbeat:Connect(function(dt)
        self.elapsed+=dt
        if self.elapsed<Security.Step then return end
        local step=self.elapsed;self.elapsed=0
        self:step(step)
    end)
end

local function alive(player)
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if humanoid and humanoid.Health>0 and root then return root end
    return nil
end

function Security:carrier(player)
    return self.carry.inventory.carrying[player.UserId]~=nil
end

function Security:setState(drone,state,target)
    drone.state=state;drone.target=target
    drone.model:SetAttribute("State",state)
    drone.model:SetAttribute("TargetUserId",if target then target.UserId else nil)
    drone.siren.Enabled=state=="Chase"
    drone.eye.Color=if state=="Chase" then Color3.fromRGB(255,60,50) elseif state=="Cooldown" then Color3.fromRGB(90,160,255) else Color3.fromRGB(255,196,60)
end

function Security:move(drone,goal,speed,dt)
    local offset=goal-drone.position
    local distance=offset.Magnitude
    if distance>1e-3 then drone.position+=offset.Unit*math.min(distance,speed*dt) end
    local flat=Vector3.new(offset.X,0,offset.Z)
    local facing=if flat.Magnitude>.1 then flat.Unit else (drone.facing or Vector3.new(0,0,-1))
    drone.facing=facing
    local bob=math.sin(self.now()*3+drone.phase)*.25
    drone.root.CFrame=CFrame.lookAt(drone.position+Vector3.new(0,bob,0),drone.position+Vector3.new(0,bob,0)+facing)
    return distance
end

function Security:inZone(drone,position,margin)
    return position.Z>=drone.z0-margin and position.Z<=drone.z1+margin and math.abs(position.X)<=Config.TrackWidth/2
end

function Security:step(dt)
    local now=self.now()
    local d=Config.Drones
    local chased={}
    for _,drone in self.drones do
        if drone.state=="Patrol" then
            if not drone.waypoint or (drone.waypoint-drone.position).Magnitude<2 then
                drone.waypoint=Vector3.new(self.random:NextNumber(-1,1)*(Config.TrackWidth/2-14),d.Height,self.random:NextNumber(drone.z0+20,drone.z1-20))
            end
            self:move(drone,drone.waypoint,d.PatrolSpeed,dt)
            -- Spot the closest player carrying loot inside this district.
            local best,bestDistance=nil,d.DetectRange
            for player in self.carry.players do
                local root=alive(player)
                if root and self:carrier(player) and self:inZone(drone,root.Position,0) then
                    local flat=Vector3.new(root.Position.X-drone.position.X,0,root.Position.Z-drone.position.Z).Magnitude
                    if flat<=bestDistance then best,bestDistance=player,flat end
                end
            end
            if best then
                self:setState(drone,"Chase",best);drone.chaseUntil=now+d.ChaseSeconds
                self.remote:FireClient(best,"Fx",{kind="DroneAlert",seconds=d.ChaseSeconds})
            end
        elseif drone.state=="Chase" then
            local player=drone.target
            local root=player and player.Parent and alive(player)
            if not root or not self:carrier(player) or not self:inZone(drone,root.Position,30) or now>=drone.chaseUntil then
                -- Escaped (still carrying) or lost interest.
                if root and self:carrier(player) and self.onEscape then self.onEscape(player) end
                if player and player.Parent then self.remote:FireClient(player,"Fx",{kind="DroneLost"}) end
                self:setState(drone,"Cooldown",nil);drone.coolUntil=now+d.CooldownSeconds
            else
                chased[player]=true
                local distance=self:move(drone,root.Position+Vector3.new(0,2.5,0),d.ChaseSpeed[drone.stage],dt)
                if distance<=d.CatchRange then
                    self.carry:resetCarried(player,"A security drone confiscated your loot! It went back to the yard.")
                    self.remote:FireClient(player,"Fx",{kind="DroneCatch"})
                    if self.onCatch then self.onCatch(player) end
                    self:setState(drone,"Cooldown",nil);drone.coolUntil=now+d.CooldownSeconds
                end
            end
        else
            self:move(drone,Vector3.new(drone.position.X,d.Height,math.clamp(drone.position.Z,drone.z0+20,drone.z1-20)),d.PatrolSpeed*.6,dt)
            if now>=drone.coolUntil then drone.waypoint=nil;self:setState(drone,"Patrol",nil) end
        end
    end
    for player in self.carry.players do
        local value=chased[player]==true
        if player:GetAttribute("DroneChase")~=value then player:SetAttribute("DroneChase",value) end
    end
end
return Security
