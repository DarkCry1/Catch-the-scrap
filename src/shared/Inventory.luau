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
    if not context.alive then return false, "Du måste vara vid liv." end
    if not context.hasBase then return false, "Alla baser är upptagna. Testa en ny server." end
    -- Ordered comparisons also reject NaN and negative or infinite distances.
    if not (context.distance >= 0 and context.distance <= state.maxDistance) then
        return false, "Gå närmare föremålet eller din inlämningsplats."
    end
    return true, ""
end

function Inventory.pickup(state: State, playerId: number, itemId: string, context: Context): (boolean, string)
    local allowed, reason = canInteract(state, context)
    if not allowed then return false, reason end
    if state.carrying[playerId] then return false, "Du bär redan ett föremål. Släpp eller lämna in det först." end
    local item = state.items[itemId]
    if not item or item.owner ~= nil then return false, "Någon annan hann ta föremålet." end
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
    if playerId ~= baseOwnerId then return nil, "Det här är någon annans bas. Följ skylten till din egen." end
    local itemId = state.carrying[playerId]
    if not itemId then return nil, "Hämta ett föremål på banan först." end
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
