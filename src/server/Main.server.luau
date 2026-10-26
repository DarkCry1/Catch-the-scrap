--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("CatchTheScrapShared")
local Remotes = ReplicatedStorage:WaitForChild("CatchTheScrapRemotes")
local Config = require(Shared.Config)
local Inventory = require(Shared.Inventory)
local WorldService = require(script.Parent.Services.WorldService)
local ItemService = require(script.Parent.Services.ItemService)
local CarryService = require(script.Parent.Services.CarryService)
local EconomyService = require(script.Parent.Services.EconomyService)

local inventory = Inventory.new(Config.InteractionDistance)
local world = WorldService.new()
local items = ItemService.new(world, inventory)
local economy = EconomyService.new(world)
local carry = CarryService.new(world, items, inventory, Remotes.Feedback, economy)
items.onPickup = function(player, record) carry:pickup(player, record) end
world.onDeposit = function(player, base) carry:deposit(player, base) end
items:start()

-- The client can request only a drop. It never chooses an item, owner, weight,
-- base, reward, or position. Proximity prompts are validated again on the server.
Remotes.Action.OnServerEvent:Connect(function(player, action, ...)
    if action ~= "Drop" or select("#", ...) ~= 0 then return end
    carry:drop(player)
end)
Players.PlayerAdded:Connect(function(player) carry:addPlayer(player) end)
Players.PlayerRemoving:Connect(function(player) carry:removePlayer(player) end)
for _, player in Players:GetPlayers() do carry:addPlayer(player) end
Remotes:SetAttribute("Ready", true)
print("[Catch the Scrap] Verkstäder startade: 10 scrap = 1 robot, $5/sek, 4 platser per bas. Ingen datasparning.")
