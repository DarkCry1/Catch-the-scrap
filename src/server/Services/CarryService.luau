--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.CatchTheScrapShared
local Config = require(Shared.Config)
local Inventory = require(Shared.Inventory)
local Movement = require(Shared.Movement)
local CarryService = {}
CarryService.__index = CarryService

local function actor(player)
    local character = player.Character
    if not character then return nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return nil, nil end
    return humanoid, root
end

function CarryService.new(world, items, inventory, feedback)
    return setmetatable({ world = world, items = items, inventory = inventory, feedback = feedback, players = {} }, CarryService)
end

function CarryService:notify(player, message)
    self.feedback:FireClient(player, message)
end

function CarryService:allowAction(player)
    local entry = self.players[player]
    if not entry then return false end
    local now = os.clock()
    if now - entry.lastAction < Config.ActionCooldown then return false end
    entry.lastAction = now
    return true
end

function CarryService:context(player, position)
    local entry = self.players[player]
    local humanoid, root = actor(player)
    return {
        alive = humanoid ~= nil,
        hasBase = entry ~= nil and entry.base ~= nil,
        distance = if root then (root.Position - position).Magnitude else math.huge,
    }
end

function CarryService:writeState(player)
    local entry = self.players[player]
    if not entry then return end
    local id = self.inventory.carrying[player.UserId]
    local record = if id then self.items.records[id] else nil
    local definition = if record then record.definition else nil
    local weight = if definition then definition.weight else 0
    local speed = Movement.effectiveSpeed(Config.BaseSpeed, Config.Strength, weight, Config.MinimumSpeed)
    player:SetAttribute("CarriedName", if definition then definition.name else "")
    player:SetAttribute("CarriedRarity", if definition then definition.rarity else "")
    player:SetAttribute("CarriedWeight", weight)
    player:SetAttribute("CarrySpeed", speed)
    player:SetAttribute("DeliveredCount", self.inventory.delivered[player.UserId] or 0)
    entry.counter.Value = self.inventory.delivered[player.UserId] or 0
    local humanoid = actor(player)
    if humanoid then humanoid.WalkSpeed = speed end
end

function CarryService:resetCarried(player, message)
    local id = Inventory.drop(self.inventory, player.UserId)
    if id then
        self.items:resetToSpawn(self.items.records[id])
        self:writeState(player)
        if message then self:notify(player, message) end
    end
end

function CarryService:addPlayer(player)
    if self.players[player] then return end
    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"
    local counter = Instance.new("IntValue")
    counter.Name = "Inlämnat"
    counter.Parent = stats
    stats.Parent = player
    local base = self.world:assignBase(player)
    local entry = { base = base, counter = counter, lastAction = -math.huge }
    self.players[player] = entry
    player:SetAttribute("BaseIndex", if base then base.index else 0)
    self:writeState(player)

    local function characterAdded(character)
        if entry.character == character then return end
        entry.character = character
        local humanoid = character:WaitForChild("Humanoid", 10)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if not humanoid or not root or humanoid.Health <= 0 or player.Character ~= character or self.players[player] ~= entry then return end
        if entry.deathConnection then entry.deathConnection:Disconnect() end
        self:resetCarried(player)
        if base then character:PivotTo(base.spawn.CFrame * CFrame.new(0, 4, 0)) end
        self:writeState(player)
        entry.deathConnection = humanoid.Died:Connect(function()
            self:resetCarried(player, "Du tappade ditt fynd. Det ligger på sin ursprungliga plats igen.")
        end)
    end
    entry.characterConnection = player.CharacterAdded:Connect(characterAdded)
    entry.removingConnection = player.CharacterRemoving:Connect(function()
        self:resetCarried(player)
    end)
    if player.Character then task.spawn(characterAdded, player.Character) end
end

function CarryService:removePlayer(player)
    local entry = self.players[player]
    if not entry then return end
    self:resetCarried(player)
    Inventory.removePlayer(self.inventory, player.UserId)
    entry.characterConnection:Disconnect()
    entry.removingConnection:Disconnect()
    if entry.deathConnection then entry.deathConnection:Disconnect() end
    if entry.base then self.world:releaseBase(entry.base) end
    self.players[player] = nil
end

function CarryService:pickup(player, record)
    if not self:allowAction(player) then return end
    local ok, reason = Inventory.pickup(self.inventory, player.UserId, record.id, self:context(player, record.root.Position))
    if not ok then self:notify(player, reason); return end
    -- All validation and ownership changes above are synchronous.
    local _, root = actor(player)
    self.items:attach(record, root)
    record.model:SetAttribute("CarrierUserId", player.UserId)
    self:writeState(player)
    self:notify(player, "Du bär " .. record.definition.name .. ". Ta det till BAS " .. self.players[player].base.index .. "!")
end

function CarryService:drop(player)
    if not self:allowAction(player) then return end
    local humanoid, root = actor(player)
    if not humanoid or not root then return end
    local id = self.inventory.carrying[player.UserId]
    if not id then return end
    local ignore = { self.world.items }
    for _, other in Players:GetPlayers() do
        if other.Character then table.insert(ignore, other.Character) end
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore
    local origin = root.Position + root.CFrame.LookVector * 5 + Vector3.new(0, 5, 0)
    local ground = workspace:Raycast(origin, Vector3.new(0, -60, 0), params)
    local record = self.items.records[id]
    Inventory.drop(self.inventory, player.UserId)
    if ground and ground.Normal.Y >= 0.7 then
        self.items:place(record, ground.Position + Vector3.new(0, 1.6, 0))
        self:notify(player, "Föremålet ligger på marken. Du kan springa fritt igen.")
    else
        self.items:resetToSpawn(record)
        self:notify(player, "Ingen säker mark här. Föremålet återställdes till sin ursprungliga plats.")
    end
    self:writeState(player)
end

function CarryService:deposit(player, base)
    if not self:allowAction(player) then return end
    local id, reason = Inventory.deposit(self.inventory, player.UserId, base.owner, self:context(player, base.deposit.Position))
    if not id then self:notify(player, reason); return end
    local record = self.items.records[id]
    local name = record.definition.name
    self.items:consume(record)
    self:writeState(player)
    self.world:updateBase(base, player, self.inventory.delivered[player.UserId])
    self:notify(player, name .. " inlämnat! Hämta ett nytt fynd på banan.")
end

return CarryService
