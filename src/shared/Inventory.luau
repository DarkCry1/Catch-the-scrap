--!strict
-- Pure server-side state machine. No yields between checking and taking ownership.
export type Context = { alive: boolean, hasBase: boolean, distance: number }
export type Item = { owner: number? }
export type State = {
    items: { [string]: Item },
    carrying: { [number]: string },
    delivered: { [number]: number },
    maxDistance: number,
}

local Inventory = {}

function Inventory.new(maxDistance: number): State
    assert(maxDistance > 0 and maxDistance < math.huge, "maxDistance must be finite and positive")
    return { items = {}, carrying = {}, delivered = {}, maxDistance = maxDistance }
end

function Inventory.registerItem(state: State, itemId: string)
    assert(state.items[itemId] == nil, "Duplicate item id")
    state.items[itemId] = { owner = nil }
end

local function canInteract(state: State, context: Context): (boolean, string)
    if not context.alive then return false, "You must be alive to interact." end
    if not context.hasBase then return false, "All workshops are occupied. Try another server." end
    -- Ordered comparisons also reject NaN and negative or infinite distances.
    if not (context.distance >= 0 and context.distance <= state.maxDistance) then
        return false, "Move closer to the item or your deposit machine."
    end
    return true, ""
end

function Inventory.pickup(state: State, playerId: number, itemId: string, context: Context): (boolean, string)
    local allowed, reason = canInteract(state, context)
    if not allowed then return false, reason end
    if state.carrying[playerId] then return false, "You are already carrying a part. Drop or deposit it first." end
    local item = state.items[itemId]
    if not item or item.owner ~= nil then return false, "That part is no longer available." end
    item.owner = playerId
    state.carrying[playerId] = itemId
    return true, ""
end

function Inventory.drop(state: State, playerId: number): string?
    local itemId = state.carrying[playerId]
    if not itemId then return nil end
    local item = state.items[itemId]
    assert(item and item.owner == playerId, "Inventory ownership invariant broken")
    item.owner = nil
    state.carrying[playerId] = nil
    return itemId
end

function Inventory.deposit(state: State, playerId: number, baseOwnerId: number, context: Context): (string?, string)
    local allowed, reason = canInteract(state, context)
    if not allowed then return nil, reason end
    if playerId ~= baseOwnerId then return nil, "This is another player's workshop. Return to your own." end
    local itemId = state.carrying[playerId]
    if not itemId then return nil, "Collect a part from the scrapyard first." end
    local item = state.items[itemId]
    assert(item and item.owner == playerId, "Inventory ownership invariant broken")
    state.items[itemId] = nil
    state.carrying[playerId] = nil
    state.delivered[playerId] = (state.delivered[playerId] or 0) + 1
    return itemId, ""
end

function Inventory.removePlayer(state: State, playerId: number): string?
    local itemId = Inventory.drop(state, playerId)
    state.delivered[playerId] = nil
    return itemId
end

return Inventory
