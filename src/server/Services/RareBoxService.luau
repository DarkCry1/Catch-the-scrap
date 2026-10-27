--!nonstrict
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Rules=require(Shared.CrateRules)
local Service={}
Service.__index=Service
function Service.new(world,items,inventory,remote)
    local self=setmetatable({world=world,items=items,inventory=inventory,remote=remote,random=Random.new(),live={},serial=0,nextAt=workspace:GetServerTimeNow()+Config.Crates.FirstDelay,elapsed=0},Service)
    self:publish()
    self.connection=RunService.Heartbeat:Connect(function(dt)
        self.elapsed+=dt;if self.elapsed<1 then return end;self.elapsed=0
        self:tick(workspace:GetServerTimeNow())
    end)
    return self
end
function Service:publish()
    self.remote:SetAttribute("NextRareBoxAt",self.nextAt)
    self.remote:SetAttribute("LiveRareBoxes",#self.live)
    for index=1,Config.Crates.LiveLimit do
        local entry=self.live[index]
        local state=entry and self.inventory.items[entry.record.id]
        local packet=entry and state and state.owner==nil and entry.packet
        local prefix="RareBox"..index
        if packet then
            self.remote:SetAttribute(prefix.."Rarity",packet.rarity)
            self.remote:SetAttribute(prefix.."Stage",packet.stage)
            self.remote:SetAttribute(prefix.."District",packet.district)
            self.remote:SetAttribute(prefix.."Time",packet.time)
        end
        self.remote:SetAttribute(prefix.."Id",if packet then packet.id else "")
    end
end
function Service:announceTo(player)
    for _,entry in self.live do
        local state=self.inventory.items[entry.record.id]
        if state and state.owner==nil then self.remote:FireClient(player,"RareBoxSpawned",entry.packet) end
    end
end
function Service:spawnEvent(now,forcedTier,forcedStage)
    if #self.live>=Config.Crates.LiveLimit then return false,"Two boxes are already active. Deliver one first." end
    local slots={}
    for _,slot in self.world.crateSpawns do
        local free=true
        for id,record in self.items.records do
            local state=self.inventory.items[id]
            if state and state.owner==nil then
                local p=record.root.CFrame.Position
                if (p.X-slot.position.X)^2+(p.Z-slot.position.Z)^2<36 then free=false;break end
            end
        end
        if free and not slot.current and (if forcedStage then slot.crateStage==forcedStage else self.serial>0 or slot.crateStage<=3) then table.insert(slots,slot) end
    end
    if #slots==0 then return false,"No free event position in that stage." end
    local slot=slots[self.random:NextInteger(1,#slots)]
    local rarity=forcedTier or Rules.roll(self.random:NextNumber())
    slot.definition=Rules.definition(rarity)
    local record=self.items:spawn(slot)
    self.serial+=1
    local stage=Config.Stages[slot.crateStage]
    local packet={id=record.id,rarity=rarity,stage=slot.crateStage,district=stage.Name,time=now}
    table.insert(self.live,{record=record,expires=now+Config.Crates.GroundLifetime,packet=packet})
    self.remote:FireAllClients("RareBoxSpawned",packet)
    self.nextAt=now+self.random:NextInteger(Config.Crates.SpawnMin,Config.Crates.SpawnMax)
    return true,rarity.." box spawned in "..stage.Name.."."
end
function Service:forceSpawn(rarity,stage)
    local ok,message=self:spawnEvent(workspace:GetServerTimeNow(),rarity,stage)
    self:publish();return ok,message
end

function Service:tick(now)
    for i=#self.live,1,-1 do
        local entry=self.live[i]
        local state=self.inventory.items[entry.record.id]
        if not self.items.records[entry.record.id] then table.remove(self.live,i)
        elseif state and state.owner~=nil then entry.expires=now+Config.Crates.GroundLifetime
        elseif now>=entry.expires and self.items:despawn(entry.record) then table.remove(self.live,i) end
    end
    if now>=self.nextAt then self:spawnEvent(now,nil,nil) end
    self:publish()
end
return Service
