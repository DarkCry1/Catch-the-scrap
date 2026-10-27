--!nonstrict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.CatchTheScrapShared
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)
local UpgradeRules = require(Shared.UpgradeRules)
local Style=require(Shared.RarityStyle)
local EconomyService = {}
EconomyService.__index = EconomyService

local function attribute(player, name, value)
    if player:GetAttribute(name) ~= value then player:SetAttribute(name, value) end
end

function EconomyService.new(world)
    local self = setmetatable({ world = world, players = {}, random = Random.new() }, EconomyService)
    self.connection = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        for player, entry in self.players do self:settle(player, entry, now) end
    end)
    return self
end

function EconomyService:publish(player, entry)
    entry.lastPublish = os.clock()
    local account = entry.account
    for _, stage in Config.Stages do
        local rarity = stage.Rarity
        attribute(player, rarity .. "Parts", Economy.progress(account, rarity))
    end
    attribute(player, "UsedPlatforms", #account.projects)
    attribute(player, "RobotCount", Economy.robotCount(account))
    attribute(player, "Cash", account.cash)
    attribute(player, "IncomePerSecond", Economy.incomePerSecond(account, Config.Robot))
    attribute(player, "SpeedLevel", account.upgrades.Speed)
    attribute(player, "StrengthLevel", account.upgrades.Strength)
    attribute(player, "BaseSpeed", UpgradeRules.value("Speed", account.upgrades.Speed, Config) + account.perks.speed)
    attribute(player, "CarryStrength", entry.adminStrength or UpgradeRules.value("Strength", account.upgrades.Strength, Config))
    attribute(player, "DexFound", Economy.discovered(account))
    attribute(player, "IncomeBonus", account.perks.income)
    attribute(player, "Rebirths", account.rebirths)
    attribute(player, "PlatformCount", Economy.slots(account, Config.Robot))
    attribute(player, "IncomeMultiplier", Economy.multiplier(account))
    if entry.rebirthCounter then entry.rebirthCounter.Value = account.rebirths end
    entry.cashCounter.Value = account.cash
end

function EconomyService:settle(player, entry, now)
    local elapsed = math.max(0, now - entry.lastTime)
    entry.lastTime = now
    local earned = Economy.advance(entry.account, elapsed, Config.Robot)
    if earned > 0 and now - entry.lastPublish >= 0.2 then self:publish(player, entry) end
end

-- `account` is the loaded save (SaveService); a fresh account otherwise.
function EconomyService:addPlayer(player, base, account)
    local cashCounter = Instance.new("IntValue")
    cashCounter.Name = "Cash"
    cashCounter.Parent = player.leaderstats
    local rebirthCounter = Instance.new("IntValue")
    rebirthCounter.Name = "Rebirths"
    rebirthCounter.Parent = player.leaderstats
    local entry = { base = base, account = account or Economy.new(), lastTime = os.clock(), lastPublish = -math.huge, cashCounter = cashCounter, rebirthCounter = rebirthCounter }
    self.players[player] = entry
    self:publish(player, entry)
    if base then self.world:updateEconomy(base, player, entry.account) end
end

function EconomyService:canDeposit(player, rarity)
    local entry = self.players[player]
    return entry ~= nil and entry.base ~= nil and Economy.canAddPart(entry.account, rarity, Config.Robot)
end

function EconomyService:addPart(player, rarity)
    local entry = self.players[player]
    -- Settle elapsed time at the OLD robot count before starting new production.
    self:settle(player, entry, os.clock())
    local ok, built, index, new = Economy.addPart(entry.account, rarity, Config.Robot, self.random:NextNumber(), self.random:NextNumber())
    assert(ok, "Scrap capacity must be checked before consuming carried loot")
    local project = entry.account.projects[index]
    self:publish(player, entry)
    self.world:updateEconomy(entry.base, player, entry.account)
    if built and self.onDiscovery then self.onDiscovery(player, project.variant, new, "Build", project.mutation, index) end
    if self.onIndexChange and (built or project.parts==1) then self.onIndexChange(player) end
    return built, project.parts, project.variant, new
end

function EconomyService:canRecoverRobot(player)
    local entry=self.players[player]
    return entry~=nil and entry.base~=nil and Economy.canRecoverRobot(entry.account,Config.Robot)
end

function EconomyService:recoverRobot(player,rarity,variant,mutation)
    local entry=self.players[player]
    self:settle(player,entry,os.clock())
    local index=Economy.reserveRobot(entry.account,rarity,Config.Robot,workspace:GetServerTimeNow(),variant,mutation)
    assert(index,"Recovered robot capacity must be checked before consuming a box")
    local project=entry.account.projects[index]
    self:publish(player,entry)
    self.world:updateEconomy(entry.base,player,entry.account)
    if self.onIndexChange then self.onIndexChange(player) end
    task.delay(Style.get(rarity).Duration,function()
        -- A delayed reveal cannot award a departed account or a new workshop owner.
        if self.players[player]~=entry or entry.base.owner~=player.UserId or not table.find(entry.account.projects,project) then return end
        self:settle(player,entry,os.clock())
        local finished,new=Economy.finishRecovery(entry.account,table.find(entry.account.projects,project),Config.Robot)
        if not finished then return end
        self:publish(player,entry)
        self.world:updateEconomy(entry.base,player,entry.account)
        if self.onIndexChange then self.onIndexChange(player) end
        if self.onRecovered then self.onRecovered(player,rarity,project.variant,new,project.mutation) end
        if self.onDiscovery then self.onDiscovery(player,project.variant,new,"Box",project.mutation,table.find(entry.account.projects,project)) end
    end)
    return index
end

function EconomyService:removePlayer(player)
    self.players[player] = nil
end

function EconomyService:movementStats(player)
    local entry = self.players[player]
    if not entry then return Config.BaseSpeed, Config.Strength end
    return UpgradeRules.value("Speed",entry.account.upgrades.Speed,Config)+entry.account.perks.speed, entry.adminStrength or UpgradeRules.value("Strength",entry.account.upgrades.Strength,Config)
end

return EconomyService
