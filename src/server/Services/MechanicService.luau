--!nonstrict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Shared=ReplicatedStorage.CatchTheScrapShared
local Config=require(Shared.Config)
local UpgradeRules=require(Shared.UpgradeRules)
local MechanicService={}
MechanicService.__index=MechanicService

function MechanicService.new(world,economy,carry,remote)
    local self=setmetatable({stand=world.mechanic,economy=economy,carry=carry,remote=remote,active={},lastBuy={}},MechanicService)
    self.stand.prompt.Triggered:Connect(function(player) self:open(player) end)
    return self
end

function MechanicService:context(player)
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local entry=self.economy.players[player]
    return {alive=humanoid~=nil and humanoid.Health>0,hasBase=entry~=nil and entry.base~=nil,
        distance=if root and root:IsA("BasePart") then (root.Position-self.stand.interaction.Position).Magnitude else math.huge}
end

function MechanicService:send(player,message,close,opening)
    if close then self.remote:FireClient(player,"MechanicShop",{open=false,message=message});return end
    local account=self.economy.players[player].account
    self.remote:FireClient(player,"MechanicShop",{open=true,mode=if opening then "open" else "update",message=message,cash=account.cash,
        offers={UpgradeRules.offer(account,"Speed",Config),UpgradeRules.offer(account,"Strength",Config)}})
end

function MechanicService:open(player)
    if not UpgradeRules.canInteract(self:context(player),Config.UpgradeDistance) then return end
    self.active[player]=true
    local entry=self.economy.players[player]
    self.economy:settle(player,entry,os.clock())
    self:send(player,"Session upgrades. Spend your robot income on better gear.",false,true)
end

function MechanicService:buy(player,kind,expectedLevel)
    if not self.active[player] then return end
    if not UpgradeRules.canInteract(self:context(player),Config.UpgradeDistance) then
        self.active[player]=nil;self:send(player,"Visit Milo to buy upgrades.",true);return
    end
    local now=os.clock()
    if now-(self.lastBuy[player] or -math.huge)<Config.UpgradeCooldown then
        self:send(player,"Give Milo a moment, then try again.");return
    end
    self.lastBuy[player]=now
    if typeof(kind)~="string" or typeof(expectedLevel)~="number" then
        self:send(player,"Please select a current upgrade offer.");return
    end
    local entry=self.economy.players[player]
    self.economy:settle(player,entry,now)
    local ok,message=UpgradeRules.purchase(entry.account,kind,expectedLevel,Config)
    self.economy:publish(player,entry)
    if ok then self.carry:writeState(player) end
    if ok and self.onEvent then self.onEvent(player,"Upgrade",1) end
    self:send(player,message)
end

function MechanicService:removePlayer(player)
    self.active[player]=nil;self.lastBuy[player]=nil
end

return MechanicService
