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
local RareBoxService=require(script.Parent.Services.RareBoxService)
local Catalog=require(Shared.RobotCatalog)
local RobotIndexService=require(script.Parent.Services.RobotIndexService)
local AdminService=require(script.Parent.Services.AdminService)
local MechanicService = require(script.Parent.Services.MechanicService)

local inventory = Inventory.new(Config.InteractionDistance)
local world = WorldService.new()
local items = ItemService.new(world, inventory)
local economy = EconomyService.new(world)
local carry = CarryService.new(world, items, inventory, Remotes.Feedback, economy)
local mechanic = MechanicService.new(world, economy, carry, Remotes.Action)
local effectSerial=0
carry.onCrush=function(base,record)
    effectSerial+=1
    local now=workspace:GetServerTimeNow()
    base.folder:SetAttribute("CrusherActiveUntil",now+Config.Presentation.CrushSeconds)
    Remotes.Action:FireAllClients("Crusher",{serial=effectSerial,time=now,baseIndex=base.index,origin=base.origin,start=record.root.CFrame,rarity=record.definition.rarity})
end
economy.onRecovered=function(player,rarity,variant)
    local recipe=Config.Robot.Recipes[rarity]
    Remotes.Action:FireClient(player,"RobotUnboxed",{rarity=rarity,name=Catalog.get(variant).Name,income=Catalog.income(recipe.Income,variant)})
    Remotes.Feedback:FireClient(player,string.format("UNBOXED: %s! +$%d per second.",Catalog.get(variant).Name,Catalog.income(recipe.Income,variant)))
end
items.onPickup = function(player, record) carry:pickup(player, record) end
world.onDeposit = function(player, base) carry:deposit(player, base) end
items:start()
local rareBoxes=RareBoxService.new(world,items,inventory,Remotes.Action)
local admin=AdminService.new(economy,carry,rareBoxes,Remotes.Action)
local index=RobotIndexService.new(economy,carry,Remotes.Action)
economy.onIndexChange=function(player) index:send(player) end

-- Client requests contain intent only; prices, cash, effects, positions and
-- ownership are resolved and validated on the server.
Remotes.Action.OnServerEvent:Connect(function(player, action, ...)
    local count = select("#", ...)
    if action == "Drop" and count == 0 then
        carry:drop(player)
    elseif action=="SetCarryStyle" and count==1 then carry:setStyle(player,...)
    elseif action=="RequestIndex" and count==0 then index:request(player)
    elseif action=="SelectBlueprint" and count==2 then index:select(player,...)
    elseif action=="RetireRobot" and count==1 then index:retire(player,...)
    elseif action=="Admin" and count==2 then admin:run(player,...)
    elseif action == "BuyUpgrade" and count == 2 then
        mechanic:buy(player, ...)
    end
end)
Players.PlayerAdded:Connect(function(player) carry:addPlayer(player);admin:addPlayer(player);rareBoxes:announceTo(player) end)
Players.PlayerRemoving:Connect(function(player)
    index:removePlayer(player)
    admin:removePlayer(player)
    mechanic:removePlayer(player)
    carry:removePlayer(player)
end)
for _, player in Players:GetPlayers() do carry:addPlayer(player);admin:addPlayer(player) end
Remotes:SetAttribute("Ready", true)
print("[Catch the Scrap] Scrapyard ready. Recover sealed robot boxes, shred scrap and visit Milo for upgrades. Session-only progress.")
