--!nonstrict
-- Daily quests and the new-player guide. Gameplay services report events
-- (Pickup, Deposit, Build, Unbox, Discover, Upgrade, Escape, OpenDex); this
-- service advances quest counters and the guide step on the server.
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Quests=require(Shared.QuestRules)
local Economy=require(Shared.Economy)
local Catalog=require(Shared.RobotCatalog)
local Mutations=require(Shared.Mutations)
local Style=require(Shared.RarityStyle)
local Hud=require(Shared.HudModel)
local Service={}
Service.__index=Service
Service.MaxCash=1e15

function Service.new(finance,remote,clock)
    return setmetatable({finance=finance,remote=remote,now=clock or os.time,last={},random=Random.new()},Service)
end

function Service:state(player)
    local entry=self.finance.players[player];if not entry then return nil end
    local account=entry.account
    local day=Quests.day(self.now())
    account.quests=Quests.current(account.quests,day)
    return entry,account,Quests.quests(day,player.UserId,account.rebirths)
end

function Service:addPlayer(player)
    local entry=self.finance.players[player];if not entry then return end
    -- Returning players from before the guide existed skip it.
    if entry.account.stats.built>0 and entry.account.tutorial<Hud.TutorialSteps then entry.account.tutorial=Hud.TutorialSteps end
    player:SetAttribute("TutorialStep",entry.account.tutorial)
    self:send(player)
end

function Service:send(player,message)
    local entry,account,list=self:state(player);if not entry then return end
    local quests={}
    for i,q in list do
        table.insert(quests,{text=q.text,target=q.target,progress=account.quests.progress[i],claimed=account.quests.claimed[i],reward=q.reward})
    end
    self.remote:FireClient(player,"Quests",{day=account.quests.day,quests=quests,bonusReady=Quests.bonusReady(account.quests),bonusClaimed=account.quests.bonus,
        bonusBox=Config.Quests.BonusBox,resetIn=Quests.secondsLeft(self.now()),message=message})
    player:SetAttribute("QuestClaimable",Quests.claimable(account.quests,list))
end

function Service:advanceTutorial(player,account,from)
    if account.tutorial==from then
        account.tutorial=from+1
        player:SetAttribute("TutorialStep",account.tutorial)
        if account.tutorial>=Hud.TutorialSteps then self.remote:FireClient(player,"Fx",{kind="Guide",done=true}) end
    end
end

function Service:event(player,kind,amount,rarity)
    local entry,account,list=self:state(player);if not entry then return end
    amount=amount or 1
    local changed=false
    if kind=="Pickup" then self:advanceTutorial(player,account,0)
    elseif kind=="Deposit" then
        self:advanceTutorial(player,account,1)
        changed=Quests.advance(account.quests,list,"Deposit",amount) or changed
        if rarity and Config.Robot.Recipes[rarity] and Style.get(rarity).Rank>=3 then changed=Quests.advance(account.quests,list,"DepositHigh",amount) or changed end
    elseif kind=="Build" then
        self:advanceTutorial(player,account,2)
        changed=Quests.advance(account.quests,list,"Build",amount)
    elseif kind=="OpenDex" then self:advanceTutorial(player,account,3)
    elseif kind=="Unbox" or kind=="Discover" or kind=="Upgrade" or kind=="Escape" then
        changed=Quests.advance(account.quests,list,kind,amount)
    end
    if changed then self:send(player) end
end

function Service:claim(player,index)
    if type(index)~="number" or index%1~=0 then return end
    local now=os.clock()
    if now-(self.last[player] or -math.huge)<.35 then return end
    self.last[player]=now
    local entry,account,list=self:state(player);if not entry then return end
    local state=account.quests
    if index==0 then
        if not Quests.bonusReady(state) then self:send(player,"Finish all three quests first.");return end
        if not entry.base or Economy.slots(account,Config.Robot)-#account.projects<1 then self:send(player,"Free a platform first: the daily bonus is a robot box.");return end
        state.bonus=true
        local rarity=Config.Quests.BonusBox
        self.finance:recoverRobot(player,rarity,Catalog.roll(self.random:NextNumber(),rarity,"Box"),Mutations.roll(self.random:NextNumber()))
        self:send(player,"Daily bonus claimed: a "..rarity.." Robot Box is opening at your workshop!")
        return
    end
    local quest=list[index]
    if not quest then return end
    if state.claimed[index] then self:send(player,"Already claimed.");return end
    if state.progress[index]<quest.target then self:send(player,"Finish the quest first.");return end
    self.finance:settle(player,entry,now)
    state.claimed[index]=true
    account.cash=math.min(Service.MaxCash,account.cash+quest.reward)
    self.finance:publish(player,entry)
    self.remote:FireClient(player,"Fx",{kind="Claim",amount=quest.reward})
    self:send(player,string.format("Quest complete! +$%d",quest.reward))
end

function Service:removePlayer(player) self.last[player]=nil end
return Service
