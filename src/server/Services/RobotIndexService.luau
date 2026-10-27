--!nonstrict
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Catalog=require(Shared.RobotCatalog)
local Economy=require(Shared.Economy)
local Style=require(Shared.RarityStyle)
local Service={}
Service.__index=Service
function Service.new(finance,carry,remote)
    return setmetatable({finance=finance,carry=carry,remote=remote,last={}},Service)
end
function Service:send(player,message)
    local entry=self.finance.players[player];if not entry then return end
    local account=entry.account
    local rows,projects={},{}
    local found=0
    for _,stage in Config.Stages do for _,v in Catalog.List do
        local unlocked=account.unlocked[Style.key(stage.Rarity,v.Id)]==true
        if unlocked then found+=1 end
        table.insert(rows,{rarity=stage.Rarity,id=v.Id,name=Catalog.name(stage.Rarity,v.Id),source=Catalog.source(stage.Rarity,v.Id),unlocked=unlocked,selected=account.selected[stage.Rarity]==v.Id or (not account.selected[stage.Rarity] and v.Id=="Bastion"),buildIncome=Catalog.income(Config.Robot.Recipes[stage.Rarity].Income,v.Id,"Build"),boxIncome=Catalog.income(Config.Robot.Recipes[stage.Rarity].Income,v.Id,"Box"),parts=Config.Robot.Recipes[stage.Rarity].Parts})
    end end
    for slot,p in account.projects do
        table.insert(projects,{id=p.id,slot=slot,complete=p.complete,name=if p.opening then p.rarity.." robot / opening..." else Catalog.name(p.rarity,p.variant or "Bastion"),rarity=p.rarity,income=if p.complete then Catalog.income(Config.Robot.Recipes[p.rarity].Income,p.variant,if p.recovered then "Box" else "Build") else 0})
    end
    self.remote:FireClient(player,"RobotIndex",{rows=rows,projects=projects,found=found,total=#rows,message=message})
end
function Service:allow(player)
    local now=os.clock()
    if now-(self.last[player] or -math.huge)<.35 then return false end
    self.last[player]=now;return true
end
function Service:request(player) if self:allow(player) then self:send(player) end end
function Service:select(player,rarity,id)
    if type(rarity)~="string" or type(id)~="string" or not self:allow(player) then return end
    local entry=self.finance.players[player];if not entry then return end
    local ok=Economy.select(entry.account,rarity,id,Config.Robot)
    self:send(player,if ok then "Selected for your next "..rarity.." build. Current projects keep their chassis." else "That robot cannot be built. Find its box instead.")
end
function Service:retire(player,id)
    if type(id)~="number" or id%1~=0 or not self:allow(player) then return end
    local entry=self.finance.players[player];if not entry or not entry.base then return end
    local context=self.carry:context(player,entry.base.deposit.Position)
    if entry.base.owner~=player.UserId or not context.alive or not context.hasBase or not (context.distance>=0 and context.distance<=Config.InteractionDistance) then self:send(player,"Return to your workshop to retire a robot.");return end
    self.finance:settle(player,entry,os.clock())
    local ok=Economy.retire(entry.account,id)
    if ok then self.finance:publish(player,entry);self.finance.world:updateEconomy(entry.base,player,entry.account) end
    self:send(player,if ok then "Robot retired. Discovery kept; platform freed. No cash refund." else "Only completed robots can be retired.")
end
function Service:removePlayer(player) self.last[player]=nil end
return Service
