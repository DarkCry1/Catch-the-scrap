--!nonstrict
local RunService=game:GetService("RunService")
local Rules=require(game:GetService("ReplicatedStorage").CatchTheScrapShared.AdminRules)
local Access=require(script.Parent.Parent.AdminConfig)
local Service={}
Service.__index=Service
function Service.new(economy,carry,events,remote)
    return setmetatable({economy=economy,carry=carry,events=events,remote=remote,last={}},Service)
end
function Service:allowed(player)
    return Rules.allowed(player.UserId,RunService:IsStudio(),Access.AllowStudio,game.CreatorType==Enum.CreatorType.User and game.CreatorId==player.UserId,Access.UserIds)
end
function Service:addPlayer(player) player:SetAttribute("CanAdmin",self:allowed(player)) end
function Service:removePlayer(player) self.last[player]=nil end
function Service:reply(player,ok,message)
    self.remote:FireClient(player,"AdminResult",{ok=ok,message=message})
end
function Service:run(player,command,value)
    -- Authority is checked from server configuration on EVERY request.
    if not self:allowed(player) then return end
    if not Rules.validate(command,value) then self:reply(player,false,"Invalid command or value.");return end
    local now=os.clock()
    if now-(self.last[player] or -math.huge)<.3 then return end
    self.last[player]=now
    local entry=self.economy.players[player]
    local actor=self.carry.players[player]
    if not entry or not actor then return end
    if command=="Event" then
        local ok,message=self.events:forceSpawn(value.rarity,value.stage)
        self:reply(player,ok,message);return
    elseif command=="SetCash" or command=="AddCash" then
        self.economy:settle(player,entry,now)
        local cash=if command=="SetCash" then value else entry.account.cash+value
        if cash>1000000000 then self:reply(player,false,"Cash limit is $1,000,000,000.");return end
        entry.account.cash=cash;entry.account.fraction=0
        self.economy:publish(player,entry)
        if entry.base then self.economy.world:updateEconomy(entry.base,player,entry.account) end
    elseif command=="SetSpeed" then actor.adminSpeed=value;self.carry:writeState(player)
    elseif command=="SetStrength" then entry.adminStrength=value;self.economy:publish(player,entry);self.carry:writeState(player)
    elseif command=="ResetStats" then actor.adminSpeed=nil;entry.adminStrength=nil;self.economy:publish(player,entry);self.carry:writeState(player)
    elseif command=="Home" then
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if not entry.base or not humanoid or humanoid.Health<=0 then self:reply(player,false,"A living character and workshop are required.");return end
        character:PivotTo(entry.base.spawn.CFrame*CFrame.new(0,4,0))
    end
    self:reply(player,true,"Applied: "..command)
end
return Service
