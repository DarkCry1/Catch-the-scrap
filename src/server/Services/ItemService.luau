--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.CatchTheScrapShared
local Config = require(Shared.Config)
local Inventory = require(Shared.Inventory)
local Catalog=require(Shared.RobotCatalog)
local Mutations=require(Shared.Mutations)
local PickupBuilder=require(script.Parent.Parent.Assets.PickupBuilder)
local CarryRig=require(script.Parent.Parent.Assets.CarryRig)
local SpawnRules=require(Shared.SpawnRules)
local ItemService = {}
ItemService.__index = ItemService

function ItemService.new(world, inventory)
    return setmetatable({ world = world, inventory = inventory, records = {}, serial = 0, random = Random.new() }, ItemService)
end

function ItemService:spawn(slot)
    assert(slot.current == nil, "Spawn slot already occupied")
    if slot.zone and self.world.spawnObstacles then
        local occupied={}
        for id,record in self.records do
            local state=self.inventory.items[id]
            if state and state.owner==nil then local p=record.root.Position;table.insert(occupied,{x=p.X,z=p.Z}) end
        end
        local chosen=SpawnRules.choose(Config.TrackWidth,Config.TrackStart+(slot.zone-1)*Config.ZoneLength,Config.ZoneLength,self.world.spawnObstacles,occupied,slot.lastPosition,function() return self.random:NextNumber() end)
        if not chosen then
            task.delay(1,function() if self.world.root.Parent and not slot.current then self:spawn(slot) end end)
            return nil
        end
        slot.lastPosition=chosen;slot.position=Vector3.new(chosen.x,slot.clearance,chosen.z)
    end
    self.serial += 1
    local id = "scrap-" .. self.serial
    local definition = slot.definition
    local model = Instance.new("Model")
    model.Name = definition.name
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model:SetAttribute("ItemId", id)
    model:SetAttribute("Weight", definition.weight)
    model:SetAttribute("Rarity", definition.rarity)
    model:SetAttribute("Kind", definition.kind or "Scrap")
    local root = Instance.new("Part")
    root.Name = "CarryRoot"
    root.Transparency = 1
    root.Size = Vector3.new(2.5, 2.5, 2.5)
    root.CFrame = CFrame.new(slot.position)
    root.Color = Color3.fromRGB(unpack(definition.color))
    root.Material = Enum.Material.Metal
    root.Anchored = true
    root.CanCollide = false
    root.CanTouch = false
    root.CanQuery = false
    root.Massless = true
    root.Parent = model
    model.PrimaryPart = root
    PickupBuilder.build(model,root,definition)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = if definition.kind=="RobotCrate" then "Recover box" else "Pick up"
    prompt.AutoLocalize = false
    prompt.ObjectText = string.format("%s · %s · weight %d", definition.name, definition.rarity, definition.weight)
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0.15
    prompt.MaxActivationDistance = Config.InteractionDistance
    prompt.RequiresLineOfSight = false
    prompt.Parent = root
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ItemLabel"
    billboard.Size = UDim2.fromOffset(180, 54)
    billboard.StudsOffset = Vector3.new(0, 4.2, 0)
    billboard.MaxDistance = 65
    billboard.Parent = root
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(18, 26, 40)
    label.BackgroundTransparency = 1
    label.TextStrokeTransparency = 0.3
    label.AutoLocalize = false
    label.TextColor3 = Color3.fromRGB(unpack(definition.color))
    label.Text = string.format("%s\n%s · weight %d", definition.name, definition.rarity, definition.weight)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = billboard
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
    if definition.rarity=="Celestial" then label:SetAttribute("HuePhase",0);game:GetService("CollectionService"):AddTag(label,"RaritySpectrum") end
    local record = { id = id, model = model, root = root, prompt = prompt, billboard = billboard, definition = definition, slot = slot, clearance = slot.clearance, weld = nil }
    if slot.crateStage then
        record.rewardRarity=definition.rarity
        record.rewardVariant=Catalog.roll(self.random:NextNumber(),definition.rarity,"Box",self.lastVariant)
        self.lastVariant=record.rewardVariant
        record.rewardMutation=Mutations.roll(self.random:NextNumber())
    end
    self.records[id] = record
    slot.current = record
    Inventory.registerItem(self.inventory, id)
    model.Parent = self.world.items
    prompt.Triggered:Connect(function(player)
        -- A destroyed or delayed prompt cannot act on a replacement item.
        if self.records[id] == record and self.onPickup then self.onPickup(player, record) end
    end)
    return record
end

function ItemService:start()
    for _, slot in self.world.spawns do self:spawn(slot) end
end

function ItemService:attach(record, characterRoot,style)
    for _,part in record.model.GroundHalo:GetChildren() do part.Transparency=1 end
    local beacon=record.root:FindFirstChild("EventBeacon");if beacon then beacon.Enabled=false end
    record.prompt.Enabled = false
    record.billboard.Enabled = false
    return CarryRig.attach(record,characterRoot,style or "Auto")
end

function ItemService:place(record, position)
    CarryRig.clear(record)
    record.root.Anchored = true
    record.model:PivotTo(CFrame.new(position))
    record.model:SetAttribute("CarrierUserId", nil)
    for _,part in record.model.GroundHalo:GetChildren() do part.Transparency=.3 end
    local beacon=record.root:FindFirstChild("EventBeacon");if beacon then beacon.Enabled=true end
    record.prompt.Enabled = true
    record.billboard.Enabled = true
end

function ItemService:resetToSpawn(record)
    self:place(record, record.slot.position)
end

function ItemService:despawn(record)
    local item=self.inventory.items[record.id]
    if not item or item.owner~=nil then return false end
    self.inventory.items[record.id]=nil;self.records[record.id]=nil;record.slot.current=nil;record.model:Destroy()
    return true
end

function ItemService:consume(record)
    CarryRig.clear(record)
    self.records[record.id] = nil
    record.slot.current = nil
    record.model:Destroy()
    if record.definition.kind=="RobotCrate" then return end
    -- Scrap replacements only; rare boxes are scheduled by RareBoxService.
    task.delay(Config.RespawnSeconds, function()
        if self.world.root.Parent and record.slot.current == nil then self:spawn(record.slot) end
    end)
end

return ItemService
