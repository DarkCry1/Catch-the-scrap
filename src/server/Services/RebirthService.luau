--!nonstrict
-- Rebirth requests: the client sends only the rebirth count it saw (so a stale
-- double press cannot rebirth twice). Cost, eligibility and effects are
-- decided here with RebirthRules.
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Rules=require(Shared.RebirthRules)
local Economy=require(Shared.Economy)
local Service={}
Service.__index=Service
Service.ClearDelay=1.6
Service.delay=function(seconds,fn) task.delay(seconds,fn) end

function Service.new(finance,carry,remote)
    return setmetatable({finance=finance,carry=carry,remote=remote,last={}},Service)
end

function Service:snapshot(player,message)
    local entry=self.finance.players[player];if not entry then return end
    local account=entry.account
    -- `blocker` is any reason other than cash, so the client can light the
    -- button as soon as the published Cash reaches the cost.
    local ok,reason=Rules.check(account)
    local blocker=if ok or account.cash<Rules.cost(account.rebirths) and account.rebirths<Config.Rebirth.Max then "" else reason
    for _,p in account.projects do if p.opening then blocker="Wait for your robot box to finish opening." end end
    self.remote:FireClient(player,"Rebirth",{rebirths=account.rebirths,cost=Rules.cost(account.rebirths),cash=account.cash,
        ready=ok,reason=blocker,max=Config.Rebirth.Max,currentMultiplier=Rules.multiplier(account.rebirths),nextMultiplier=Rules.multiplier(account.rebirths+1),
        slots=Economy.slots(account,Config.Robot),nextSlots=Rules.slots(account.rebirths+1),message=message})
end

function Service:request(player,expected)
    if type(expected)~="number" or expected%1~=0 then return end
    local now=os.clock()
    if now-(self.last[player] or -math.huge)<1 then return end
    self.last[player]=now
    local entry=self.finance.players[player];if not entry then return end
    local account=entry.account
    if expected~=account.rebirths then self:snapshot(player,"Your rebirth status changed. Check it and try again.");return end
    self.finance:settle(player,entry,now)
    local ok,reason=Rules.check(account)
    if not ok then self:snapshot(player,reason);return end
    -- Anything carried stays with the player; robots and upgrades are reset.
    Rules.apply(account)
    self.finance:publish(player,entry)
    -- The client plays the rebirth cinematic first (robots lift off and
    -- dissolve); the workshop is cleared a moment later for that effect.
    local base=entry.base
    if base then
        self.remote:FireClient(player,"Fx",{kind="Rebirth",rebirths=account.rebirths,multiplier=Rules.multiplier(account.rebirths),
            slots=Economy.slots(account,Config.Robot),baseIndex=base.index,origin=base.origin})
        Service.delay(Service.ClearDelay,function()
            if self.finance.players[player]==entry and base.owner==player.UserId then self.finance.world:updateEconomy(base,player,entry.account) end
        end)
    end
    self.carry:writeState(player)
    if self.onRebirth then self.onRebirth(player,account.rebirths) end
    self:snapshot(player,string.format("REBIRTH %d! Income x%.1f and %d platforms. Your Robotdex is safe.",account.rebirths,Rules.multiplier(account.rebirths),Economy.slots(account,Config.Robot)))
end

function Service:removePlayer(player) self.last[player]=nil end
return Service
