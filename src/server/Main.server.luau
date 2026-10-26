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
local MechanicService = require(script.Parent.Services.MechanicService)

local inventory = Inventory.new(Config.InteractionDistance)
local world = WorldService.new()
local items = ItemService.new(world, inventory)
local economy = EconomyService.new(world)
local carry = CarryService.new(world, items, inventory, Remotes.Feedback, economy)
local mechanic = MechanicService.new(world, economy, carry, Remotes.Action)
items.onPickup = function(player, record) carry:pickup(player, record) end
world.onDeposit = function(player, base) carry:deposit(player, base) end
items:start()

-- Client requests contain intent only; prices, cash, effects, positions and
-- ownership are resolved and validated on the server.
Remotes.Action.OnServerEvent:Connect(function(player, action, ...)
    local count = select("#", ...)
    if action == "Drop" and count == 0 then
        carry:drop(player)
    elseif action == "BuyUpgrade" and count == 2 then
        mechanic:buy(player, ...)
    end
end)
Players.PlayerAdded:Connect(function(player) carry:addPlayer(player) end)
Players.PlayerRemoving:Connect(function(player)
    mechanic:removePlayer(player)
    carry:removePlayer(player)
end)
for _, player in Players:GetPlayers() do carry:addPlayer(player) end
Remotes:SetAttribute("Ready", true)
print("[Catch the Scrap] Scrapyard ready. Milo's mechanic stand is open for Speed and Strength upgrades. Session-only progress.")
