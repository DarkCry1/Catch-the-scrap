--!nonstrict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.CatchTheScrapShared
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)
local UpgradeRules = require(Shared.UpgradeRules)
local EconomyService = {}
EconomyService.__index = EconomyService

local function attribute(player, name, value)
    if player:GetAttribute(name) ~= value then player:SetAttribute(name, value) end
end

function EconomyService.new(world)
    local self = setmetatable({ world = world, players = {} }, EconomyService)
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
    attribute(player, "BaseSpeed", UpgradeRules.value("Speed", account.upgrades.Speed, Config))
    attribute(player, "CarryStrength", UpgradeRules.value("Strength", account.upgrades.Strength, Config))
    entry.cashCounter.Value = account.cash
end

function EconomyService:settle(player, entry, now)
    local elapsed = math.max(0, now - entry.lastTime)
    entry.lastTime = now
    local earned = Economy.advance(entry.account, elapsed, Config.Robot)
    if earned > 0 and now - entry.lastPublish >= 0.2 then self:publish(player, entry) end
end

function EconomyService:addPlayer(player, base)
    local cashCounter = Instance.new("IntValue")
    cashCounter.Name = "Cash"
    cashCounter.Parent = player.leaderstats
    local entry = { base = base, account = Economy.new(), lastTime = os.clock(), lastPublish = -math.huge, cashCounter = cashCounter }
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
    local ok, built, index = Economy.addPart(entry.account, rarity, Config.Robot)
    assert(ok, "Scrap capacity must be checked before consuming carried loot")
    self:publish(player, entry)
    self.world:updateEconomy(entry.base, player, entry.account)
    return built, entry.account.projects[index].parts
end

function EconomyService:removePlayer(player)
    self.players[player] = nil
end

function EconomyService:movementStats(player)
    local entry = self.players[player]
    if not entry then return Config.BaseSpeed, Config.Strength end
    return UpgradeRules.value("Speed",entry.account.upgrades.Speed,Config), UpgradeRules.value("Strength",entry.account.upgrades.Strength,Config)
end

return EconomyService
