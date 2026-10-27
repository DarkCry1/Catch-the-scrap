--!nonstrict
-- One walking warden per rarity district. Server-authoritative confiscation;
-- only the carried item is reset. Existing Drone* UI/quest channels are retained.
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Rules=require(Shared.GuardianRules)
local Navigation=require(Shared.GuardianNavigation)
local Builder=require(script.Parent.Parent.Assets.GuardianBuilder)
local Security={}
Security.__index=Security
local function point(position) return {x=position.X,z=position.Z} end
local function alive(player)
    if not player or not player.Parent then return nil end
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if root and humanoid and humanoid.Health>0 then return root end
    return nil
end
function Security.new(world,carry,remote,clock)
    local self=setmetatable({world=world,carry=carry,remote=remote,now=clock or os.clock,guardians={},elapsed=0},Security)
    local folder=Instance.new("Folder");folder.Name="StageGuardians";folder.Parent=world.root;self.folder=folder
    for stage,profile in Config.Guardians.Profiles do
        local navigation=Navigation.new(stage,world.guardianGeometry or {})
        local home=Rules.patrol(stage,1)
        local cell=navigation:nearest(home)
        assert(cell,"Guardian district needs a walkable patrol lane")
        home={x=navigation.cells[cell].x,z=navigation.cells[cell].z}
        local rig=Builder.build(folder,stage,Vector3.new(home.x,.12,home.z))
        local guardian={rig=rig,stage=stage,profile=profile,navigation=navigation,home=home,position=home,state="Patrol",patrolIndex=1,route={},routeIndex=1,nextPlan=0,facing=Vector3.new(0,0,1)}
        table.insert(self.guardians,guardian)
        self:setState(guardian,"Patrol")
    end
    self.removal=world.root.Destroying:Connect(function() self:destroy() end)
    return self
end
function Security:record(player,stage)
    local id=self.carry.inventory.carrying[player.UserId]
    local ownership=id and self.carry.inventory.items[id]
    local record=id and self.carry.items.records[id]
    if ownership and ownership.owner==player.UserId and record and Rules.protects(stage,record.slot) then return record end
    return nil
end
function Security:eligible(player,guardian)
    local root=alive(player)
    if root and self:record(player,guardian.stage) and Rules.inside(guardian.stage,point(root.Position)) and root.Position.Y>=-2 and root.Position.Y<=Rules.height(guardian.stage)+7 then return root end
    return nil
end
function Security:setState(guardian,state,target)
    guardian.state=state;guardian.target=target;guardian.route={};guardian.routeIndex=1;guardian.lastGoal=nil;guardian.nextPlan=0
    local rig=guardian.rig
    rig.model:SetAttribute("State",state);rig.model:SetAttribute("TargetUserId",if target then target.UserId else nil)
    local alarm=state=="Alert" or state=="Chase"
    local tint=if alarm then Color3.fromRGB(255,70,46) elseif state=="Cooldown" then Color3.fromRGB(82,186,255) else rig.tint
    for _,eye in rig.eyes do eye.Color=tint end
    rig.lamp.Enabled=alarm;rig.lamp.Color=tint
    rig.label.TextColor3=tint
    rig.label.Text=string.format("%s / %s\n%s",Config.Stages[guardian.stage].Rarity:upper(),guardian.profile.Name:upper(),if state=="Alert" then "INTRUDER DETECTED!" elseif state=="Chase" then "RETURN MY SCRAP!" elseif state=="Cooldown" then "COOLING DOWN" else "PATROL / CHASE SPEED "..guardian.profile.ChaseSpeed)
end
function Security:cooldown(guardian,escaped)
    local player=guardian.target
    if escaped and self.onEscape then self.onEscape(player) end
    if player and player.Parent then self.remote:FireClient(player,"Fx",{kind="DroneLost"}) end
    self:setState(guardian,"Cooldown")
    guardian.coolUntil=self.now()+Config.Guardians.CooldownSeconds
end
function Security:move(guardian,goal,speed,dt)
    local now=self.now()
    if now>=guardian.nextPlan and (not guardian.lastGoal or Navigation.distance(goal,guardian.lastGoal)>4 or (not guardian.route[guardian.routeIndex] and Navigation.distance(guardian.position,goal)>2)) then
        guardian.route=guardian.navigation:route(guardian.position,goal);guardian.routeIndex=1;guardian.lastGoal={x=goal.x,z=goal.z};guardian.nextPlan=now+Config.Guardians.RepathSeconds
    end
    local before=guardian.position;local remaining=speed*dt
    while remaining>1e-5 do
        local nextPoint=guardian.route[guardian.routeIndex];if not nextPoint then break end
        local distance=Navigation.distance(guardian.position,nextPoint)
        if distance<.001 then guardian.routeIndex+=1;continue end
        local step=math.min(distance,remaining)
        guardian.position={x=guardian.position.x+(nextPoint.x-guardian.position.x)*step/distance,z=guardian.position.z+(nextPoint.z-guardian.position.z)*step/distance}
        remaining-=step
        if distance<=step+.001 then guardian.routeIndex+=1 end
    end
    local delta=Vector3.new(guardian.position.x-before.x,0,guardian.position.z-before.z)
    if delta.Magnitude>.001 then guardian.facing=delta.Unit end
    self:pose(guardian,if dt>0 then delta.Magnitude/dt else 0)
end
function Security:pose(guardian,speed)
    local p=Vector3.new(guardian.position.x,.12,guardian.position.z)
    -- Our own blueprint faces +Z; CFrame.lookAt normally points local -Z.
    local frame=CFrame.lookAt(p,p-guardian.facing)
    guardian.rig.root.CFrame=frame
    guardian.rig.model:SetAttribute("Motion",frame)
    guardian.rig.model:SetAttribute("MoveSpeed",math.floor(speed*10+.5)/10)
end
function Security:step(dt)
    if self.destroyed then return end
    dt=math.clamp(dt,0,.15) -- a stalled server must not teleport a guard into loot.
    local now=self.now();local chased={}
    for _,guardian in self.guardians do
        local profile=guardian.profile
        if guardian.state=="Patrol" then
            local best,bestDistance=nil,profile.DetectRange
            for player in self.carry.players do
                local root=self:eligible(player,guardian)
                if root then
                    local p=point(root.Position);local d=Navigation.distance(guardian.position,p)
                    if d<=bestDistance and guardian.navigation:clear(guardian.position,p,.25) then best,bestDistance=player,d end
                end
            end
            if best then
                self:setState(guardian,"Alert",best);guardian.attackAt=now+profile.WarningSeconds
                chased[best]=true;self:pose(guardian,0)
                self.remote:FireClient(best,"Fx",{kind="DroneAlert",name=profile.Name,stage=guardian.stage,seconds=profile.ChaseSeconds+profile.WarningSeconds})
            else
                local goal=Rules.patrol(guardian.stage,guardian.patrolIndex)
                if Navigation.distance(guardian.position,goal)<4 then guardian.patrolIndex+=1;goal=Rules.patrol(guardian.stage,guardian.patrolIndex) end
                self:move(guardian,goal,profile.PatrolSpeed,dt)
            end
        elseif guardian.state=="Alert" then
            if not self:eligible(guardian.target,guardian) then self:cooldown(guardian,false)
            elseif now>=guardian.attackAt then
                local target=guardian.target
                self:setState(guardian,"Chase",target);guardian.chaseUntil=now+profile.ChaseSeconds;chased[target]=true
            else chased[guardian.target]=true;self:pose(guardian,0) end
        elseif guardian.state=="Chase" then
            local player=guardian.target;local root=self:eligible(player,guardian)
            if not root or now>=guardian.chaseUntil then
                -- Dropping, dying or disconnecting never awards an escape quest.
                local escaped=alive(player) and self:record(player,guardian.stage)~=nil
                self:cooldown(guardian,escaped)
            else
                local goal=Rules.clamp(guardian.stage,point(root.Position),Rules.radius(guardian.stage)+1)
                self:move(guardian,goal,profile.ChaseSpeed,dt)
                local close=Navigation.distance(guardian.position,point(root.Position))<=Rules.catchRange(guardian.stage)
                if close and guardian.navigation:clear(guardian.position,point(root.Position),.1) then
                    self.carry:resetCarried(player,profile.Name.." caught you! Your loot returned to the yard.")
                    self.remote:FireClient(player,"Fx",{kind="DroneCatch"})
                    if self.onCatch then self.onCatch(player) end
                    self:setState(guardian,"Cooldown");guardian.coolUntil=now+Config.Guardians.CooldownSeconds
                else chased[player]=true end
            end
        else
            self:move(guardian,guardian.home,profile.PatrolSpeed*.65,dt)
            if now>=guardian.coolUntil then self:setState(guardian,"Patrol") end
        end
    end
    for player in self.carry.players do
        local value=chased[player]==true
        if player:GetAttribute("DroneChase")~=value then player:SetAttribute("DroneChase",value) end
    end
end
function Security:start()
    if self.connection then return end
    self.connection=RunService.Heartbeat:Connect(function(dt)
        self.elapsed+=dt
        if self.elapsed<Config.Guardians.Step then return end
        local step=self.elapsed;self.elapsed=0;self:step(step)
    end)
end
function Security:destroy()
    if self.destroyed then return end;self.destroyed=true
    if self.connection then self.connection:Disconnect() end
    if self.removal then self.removal:Disconnect() end
    for player in self.carry.players do player:SetAttribute("DroneChase",false) end
    self.folder:Destroy()
end
return Security
