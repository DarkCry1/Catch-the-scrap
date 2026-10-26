--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.CatchTheScrapShared
local Config = require(Shared.Config)
local Inventory = require(Shared.Inventory)
local CrateRules=require(Shared.CrateRules)
local PickupBuilder=require(script.Parent.Parent.Assets.PickupBuilder)
local ItemService = {}
ItemService.__index = ItemService

function ItemService.new(world, inventory)
    return setmetatable({ world = world, inventory = inventory, records = {}, serial = 0, random = Random.new() }, ItemService)
end

function ItemService:spawn(slot)
    assert(slot.current == nil, "Spawn slot already occupied")
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
    local record = { id = id, model = model, root = root, prompt = prompt, billboard = billboard, definition = definition, slot = slot, clearance = slot.clearance, weld = nil }
    if slot.crateStage then record.rewardRarity=CrateRules.roll(slot.crateStage,self.random:NextNumber()) end
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

function ItemService:attach(record, characterRoot)
    for _,part in record.model.GroundHalo:GetChildren() do part.Transparency=1 end
    record.prompt.Enabled = false
    record.billboard.Enabled = false
    local head=characterRoot.Parent:FindFirstChild("Head")
    local top=if head then characterRoot.CFrame:PointToObjectSpace(head.Position).Y+head.Size.Y/2 else 2
    local halfHeight=if record.definition.kind=="RobotCrate" then 2.1 else math.max(1,record.clearance or 1.8)-.3
    record.model:PivotTo(characterRoot.CFrame * CFrame.new(0,top+halfHeight+.2,-.65))
    record.root.Anchored = false
    local weld = Instance.new("WeldConstraint")
    weld.Name = "CarryWeld"
    weld.Part0 = characterRoot
    weld.Part1 = record.root
    weld.Parent = record.root
    record.weld = weld
end

function ItemService:place(record, position)
    if record.weld then record.weld:Destroy(); record.weld = nil end
    record.root.Anchored = true
    record.model:PivotTo(CFrame.new(position))
    record.model:SetAttribute("CarrierUserId", nil)
    for _,part in record.model.GroundHalo:GetChildren() do part.Transparency=.3 end
    record.prompt.Enabled = true
    record.billboard.Enabled = true
end

function ItemService:resetToSpawn(record)
    self:place(record, record.slot.position)
end

function ItemService:consume(record)
    self.records[record.id] = nil
    record.slot.current = nil
    record.model:Destroy()
    -- One replacement per successful deposit; dropped items are never duplicated.
    task.delay(if record.definition.kind=="RobotCrate" then Config.Crates.RespawnSeconds else Config.RespawnSeconds, function()
        if self.world.root.Parent and record.slot.current == nil then self:spawn(record.slot) end
    end)
end

return ItemService
