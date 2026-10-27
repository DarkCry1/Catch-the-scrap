--!strict
-- Daily quests: three per player per UTC day, chosen deterministically from
-- (day, UserId) so every server agrees. Easy / medium / hard slots scale the
-- target and the cash reward; finishing all three unlocks a bonus box.
local Config = require("./Config")
export type Template = { Id: string, Text: string, Event: string, Targets: {number} }
export type Quest = { id: string, text: string, event: string, target: number, reward: number }
export type State = { day: number, progress: {number}, claimed: {boolean}, bonus: boolean }
local Rules = {}

local templates: {Template} = {
    { Id = "Deliver", Text = "Deliver %d scrap parts to your workshop", Event = "Deposit", Targets = { 12, 25, 45 } },
    { Id = "DeliverHigh", Text = "Deliver %d Rare-or-better parts", Event = "DepositHigh", Targets = { 4, 10, 18 } },
    { Id = "Build", Text = "Finish %d robots", Event = "Build", Targets = { 2, 4, 7 } },
    { Id = "Unbox", Text = "Open %d robot boxes", Event = "Unbox", Targets = { 1, 1, 2 } },
    { Id = "Discover", Text = "Discover %d new Robotdex entries", Event = "Discover", Targets = { 1, 2, 3 } },
    { Id = "Upgrade", Text = "Buy %d upgrades from Milo", Event = "Upgrade", Targets = { 1, 2, 3 } },
    { Id = "Escape", Text = "Escape %d scrap guardian chases with loot", Event = "Escape", Targets = { 1, 2, 4 } },
}
Rules.Templates = templates

function Rules.day(unixTime: number): number
    return math.floor(unixTime / 86400)
end
function Rules.secondsLeft(unixTime: number): number
    return 86400 - unixTime % 86400
end

local function generator(seed: number): () -> number
    local state = seed % 2147483647
    if state <= 0 then state += 2147483646 end
    return function()
        state = (state * 48271) % 2147483647
        return (state - 1) / 2147483646
    end
end

function Rules.quests(day: number, userId: number, rebirths: number): {Quest}
    local random = generator(day * 7919 + math.abs(userId) % 1000003 + 17)
    local pool = table.clone(templates)
    local out: {Quest} = {}
    for slot = 1, Config.Quests.PerDay do
        local index = math.floor(random() * #pool) + 1
        local t = table.remove(pool, index) :: Template
        local target = t.Targets[math.min(slot, #t.Targets)]
        table.insert(out, { id = t.Id, text = string.format(t.Text, target), event = t.Event, target = target,
            reward = Config.Quests.CashReward[slot] * (1 + rebirths) })
    end
    return out
end

function Rules.fresh(day: number): State
    local progress, claimed = {}, {}
    for i = 1, Config.Quests.PerDay do progress[i] = 0; claimed[i] = false end
    return { day = day, progress = progress, claimed = claimed, bonus = false }
end

-- Bring a saved state to `day` (new day = new quests).
function Rules.current(state: State?, day: number): State
    if state == nil or state.day ~= day then return Rules.fresh(day) end
    return state
end

-- Record an event; returns true when any quest progressed.
function Rules.advance(state: State, quests: {Quest}, event: string, amount: number): boolean
    local changed = false
    for i, q in quests do
        if q.event == event and not state.claimed[i] and state.progress[i] < q.target then
            state.progress[i] = math.min(q.target, state.progress[i] + amount)
            changed = true
        end
    end
    return changed
end

function Rules.claimable(state: State, quests: {Quest}): number
    local n = 0
    for i, q in quests do if not state.claimed[i] and state.progress[i] >= q.target then n += 1 end end
    if Rules.bonusReady(state) then n += 1 end
    return n
end
function Rules.bonusReady(state: State): boolean
    if state.bonus then return false end
    for i = 1, Config.Quests.PerDay do if not state.claimed[i] then return false end end
    return true
end
return Rules
