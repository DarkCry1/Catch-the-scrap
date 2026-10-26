--!nonstrict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.CatchTheScrapShared
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)
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
    local account = entry.account
    attribute(player, "ScrapProgress", account.scrap)
    attribute(player, "RobotCount", account.robots)
    attribute(player, "Cash", account.cash)
    attribute(player, "IncomePerSecond", Economy.incomePerSecond(account, Config.Robot))
    entry.cashCounter.Value = account.cash
end

function EconomyService:settle(player, entry, now)
    local elapsed = math.max(0, now - entry.lastTime)
    entry.lastTime = now
    if Economy.advance(entry.account, elapsed, Config.Robot) > 0 then self:publish(player, entry) end
end

function EconomyService:addPlayer(player, base)
    local cashCounter = Instance.new("IntValue")
    cashCounter.Name = "Pengar"
    cashCounter.Parent = player.leaderstats
    local entry = { base = base, account = Economy.new(), lastTime = os.clock(), cashCounter = cashCounter }
    self.players[player] = entry
    self:publish(player, entry)
    if base then self.world:updateEconomy(base, player, entry.account) end
end

function EconomyService:canDeposit(player)
    local entry = self.players[player]
    return entry ~= nil and entry.base ~= nil and Economy.canAddScrap(entry.account, 1, Config.Robot)
end

function EconomyService:addScrap(player)
    local entry = self.players[player]
    -- Settle elapsed time at the OLD robot count before starting new production.
    self:settle(player, entry, os.clock())
    local ok, built = Economy.addScrap(entry.account, 1, Config.Robot)
    assert(ok, "Scrap capacity must be checked before consuming carried loot")
    self:publish(player, entry)
    self.world:updateEconomy(entry.base, player, entry.account)
    return built, entry.account.scrap
end

function EconomyService:removePlayer(player)
    self.players[player] = nil
end

return EconomyService
