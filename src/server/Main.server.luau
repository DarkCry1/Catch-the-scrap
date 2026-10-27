--!nonstrict
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
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
local RobotdexService=require(script.Parent.Services.RobotdexService)
local SaveService=require(script.Parent.Services.SaveService)
local AdminService=require(script.Parent.Services.AdminService)
local MechanicService = require(script.Parent.Services.MechanicService)
local RebirthService=require(script.Parent.Services.RebirthService)
local ProgressService=require(script.Parent.Services.ProgressService)
local SecurityService=require(script.Parent.Services.SecurityService)
local Mutations=require(Shared.Mutations)

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
economy.onRecovered=function(player,rarity,variant,new,mutation)
    local recipe=Config.Robot.Recipes[rarity]
    local income=Catalog.income(recipe.Income,variant)*Mutations.multiplier(mutation)
    Remotes.Action:FireClient(player,"RobotUnboxed",{rarity=rarity,name=Mutations.prefix(mutation)..Catalog.get(variant).Name,income=income,new=new})
    Remotes.Feedback:FireClient(player,string.format("UNBOXED: %s%s%s +$%d per second.",Mutations.prefix(mutation),Catalog.label(variant),if new then " (NEW in Robotdex!)" else "!",income))
end
items.onPickup = function(player, record) carry:pickup(player, record) end
world.onDeposit = function(player, base) carry:deposit(player, base) end
items:start()
local rareBoxes=RareBoxService.new(world,items,inventory,Remotes.Action)
local admin=AdminService.new(economy,carry,rareBoxes,Remotes.Action)
local index=RobotdexService.new(economy,carry,Remotes.Action)
admin.dex=index
economy.onIndexChange=function(player) index:send(player) end
local progress=ProgressService.new(economy,Remotes.Action)
local rebirth=RebirthService.new(economy,carry,Remotes.Action)
local security=SecurityService.new(world,carry,Remotes.Action)
economy.onDiscovery=function(player,id,new,source,mutation,slot)
    local entry=economy.players[player]
    local key=if mutation then Mutations.key(mutation,id) else nil
    local newMutation=key~=nil and entry~=nil and entry.account.mdex[key]==1
    if new or newMutation then Remotes.Action:FireClient(player,"DexDiscovery",{id=id,source=source,mutation=mutation,newSpecies=new}) end
    local pad=entry and entry.base and slot and entry.base.pads[slot]
    Remotes.Action:FireClient(player,"Fx",{kind=if source=="Box" then "Unboxed" else "Built",id=id,mutation=mutation,new=new,position=pad and pad.origin.Position})
    progress:event(player,if source=="Box" then "Unbox" else "Build",1)
    if new then progress:event(player,"Discover",1) end
end
carry.onEvent=function(player,kind,amount,rarity,count)
    progress:event(player,kind,amount,rarity)
    if kind=="Deposit" then
        local entry=economy.players[player]
        local recipe=Config.Robot.Recipes[rarity]
        if entry and entry.base and recipe then
            Remotes.Action:FireClient(player,"Fx",{kind="Deposit",rarity=rarity,count=count,total=recipe.Parts,position=entry.base.deposit.Position})
        end
    end
end
mechanic.onEvent=function(player,kind,amount) progress:event(player,kind,amount) end
security.onEscape=function(player) progress:event(player,"Escape",1) end
security:start()

-- DataStore access throws in Studio unless "Enable Studio Access to API
-- Services" is on; SaveService then runs session-only.
local store=nil
do
    local ok,result=pcall(function() return DataStoreService:GetDataStore(Config.Save.Store) end)
    if ok then store=result else warn("[Catch the Scrap] DataStore unavailable: "..tostring(result)) end
    -- In Studio, probe once so a disabled "Studio Access to API Services"
    -- falls back to session-only play immediately instead of retrying per player.
    if store and RunService:IsStudio() then
        local probe,err=pcall(function() return store:GetAsync("studio_probe") end)
        if not probe then warn("[Catch the Scrap] Studio DataStore access is off ("..tostring(err).."). Progress is session-only.");store=nil end
    end
end
local saves=SaveService.new({store=store,jobId=if game.JobId~="" then game.JobId else "studio-"..tostring(os.clock())})
local function accounts()
    local out={}
    for player,entry in economy.players do out[player]=entry.account end
    return out
end
saves:startAutosave(accounts)
-- A rebirth is a big, irreversible change: refresh views and save at once.
rebirth.onRebirth=function(player)
    index:send(player);progress:send(player)
    local entry=economy.players[player]
    if entry then task.spawn(function() saves:save(player,entry.account,false) end) end
end
game:BindToClose(function() saves:shutdown(accounts) end)

local function join(player)
    local account,status=saves:load(player)
    if status=="left" or not player.Parent then saves.profiles[player]=nil;return end
    carry:addPlayer(player,account)
    admin:addPlayer(player)
    progress:addPlayer(player)
    rebirth:snapshot(player)
    index:applySkin(player)
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Head",10)
        index:applyTitle(player)
    end)
    if player.Character then task.spawn(function() player.Character:WaitForChild("Head",10);index:applyTitle(player) end) end
    rareBoxes:announceTo(player)
    index:send(player)
    player:SetAttribute("SaveStatus",status)
    if status=="offline" then
        Remotes.Feedback:FireClient(player,if RunService:IsStudio() then "Saving is off: enable Studio Access to API Services to test DataStore saves." else "Saving is temporarily unavailable. Progress this visit may not be kept.")
    elseif status=="loaded" then
        Remotes.Feedback:FireClient(player,"Welcome back! Your workshop and Robotdex were loaded.")
    end
end

-- Client requests contain intent only; prices, cash, effects, positions and
-- ownership are resolved and validated on the server.
Remotes.Action.OnServerEvent:Connect(function(player, action, ...)
    local count = select("#", ...)
    if action == "Drop" and count == 0 then
        carry:drop(player)
    elseif action=="SetCarryStyle" and count==1 then carry:setStyle(player,...)
    elseif action=="RequestIndex" and count==0 then index:request(player);progress:event(player,"OpenDex",1)
    elseif action=="RequestQuests" and count==0 then progress:send(player)
    elseif action=="ClaimQuest" and count==1 then progress:claim(player,...)
    elseif action=="RequestRebirth" and count==0 then rebirth:snapshot(player)
    elseif action=="Rebirth" and count==1 then rebirth:request(player,...)
    elseif action=="RetireRobot" and count==1 then index:retire(player,...)
    elseif action=="ClaimReward" and count==1 then index:claim(player,...)
    elseif action=="EquipCosmetic" and count==2 then index:equip(player,...)
    elseif action=="Admin" and count==2 then admin:run(player,...)
    elseif action == "BuyUpgrade" and count == 2 then
        mechanic:buy(player, ...)
    end
end)
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(function(player)
    local entry=economy.players[player]
    if entry then economy:settle(player,entry,os.clock()) end
    local account=entry and entry.account
    index:removePlayer(player)
    progress:removePlayer(player)
    rebirth:removePlayer(player)
    admin:removePlayer(player)
    mechanic:removePlayer(player)
    carry:removePlayer(player)
    if account then saves:release(player,account) else saves.profiles[player]=nil end
end)
for _, player in Players:GetPlayers() do task.spawn(join,player) end
Remotes:SetAttribute("Ready", true)
print("[Catch the Scrap] Scrapyard ready. Robotdex v1.2: "..#Catalog.List.." species. Saving: "..(if store then "DataStore" else "session-only"))
