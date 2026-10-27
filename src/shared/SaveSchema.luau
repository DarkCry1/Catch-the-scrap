--!strict
-- Serialize an Economy account for DataStore and rebuild it defensively.
-- Anything malformed, unknown or out of range is dropped or clamped, so a
-- corrupted or tampered record can never crash the server or grant items.
local Config = require("./Config")
local Catalog = require("./RobotCatalog")
local Economy = require("./Economy")
local Rewards = require("./DexRewards")
local Mutations = require("./Mutations")
local RebirthRules = require("./RebirthRules")
local Schema = {}
Schema.Version = 1
Schema.MaxCash = 1e15

local function integer(value: any, low: number, high: number, fallback: number): number
    if type(value) ~= "number" or value ~= value or value % 1 ~= 0 then return fallback end
    return math.clamp(value, low, high)
end

function Schema.serialize(account: Economy.Account): {[string]: any}
    local projects = {}
    for _, p in account.projects do
        -- An opening in progress is saved as its finished robot (the species is
        -- already decided on the server); the reveal timer cannot survive a leave.
        local complete = p.complete or p.opening == true
        table.insert(projects, { r = p.rarity, p = if complete then Config.Robot.Recipes[p.rarity].Parts else p.parts, c = complete, v = p.variant, b = p.recovered == true, m = if complete then p.mutation else nil })
    end
    local dex = {}
    for id, n in account.dex do if n > 0 then dex[id] = n end end
    local list = function(set: {[string]: boolean}): {string}
        local out = {}
        for k, v in set do if v then table.insert(out, k) end end
        table.sort(out)
        return out
    end
    return {
        version = Schema.Version,
        cash = math.floor(account.cash), upgrades = { Speed = account.upgrades.Speed, Strength = account.upgrades.Strength },
        projects = projects, dex = dex, claimed = list(account.claimed),
        perks = { income = account.perks.income, speed = account.perks.speed },
        titles = list(account.titles), title = account.title, skins = list(account.skins), skin = account.skin,
        stats = { built = account.stats.built, unboxed = account.stats.unboxed },
        rebirths = account.rebirths, mdex = (function() local m = {}; for k, n in account.mdex do if n > 0 then m[k] = n end end; return m end)(),
        quests = account.quests, tutorial = account.tutorial,
    }
end

function Schema.deserialize(data: any): Economy.Account
    local account = Economy.new()
    if type(data) ~= "table" then return account end
    account.cash = integer(data.cash, 0, Schema.MaxCash, 0)
    if type(data.upgrades) == "table" then
        for kind, offer in Config.Upgrades do account.upgrades[kind] = integer(data.upgrades[kind], 0, offer.MaxLevel, 0) end
    end
    account.rebirths = integer(data.rebirths, 0, Config.Rebirth.Max, 0)
    account.tutorial = integer(data.tutorial, 0, 10, 0)
    if type(data.projects) == "table" then
        local active: {[string]: boolean} = {}
        for _, p in data.projects do
            if #account.projects >= RebirthRules.slots(account.rebirths) then break end
            if type(p) ~= "table" or type(p.r) ~= "string" then continue end
            local recipe = Config.Robot.Recipes[p.r]
            if not recipe then continue end
            if p.c == true then
                if type(p.v) ~= "string" or not Catalog.find(p.v) or Catalog.get(p.v).Rarity ~= p.r then continue end
                account.nextId += 1
                local mutation = if type(p.m) == "string" and Mutations.get(p.m) then p.m else nil
                table.insert(account.projects, { id = account.nextId, rarity = p.r, parts = recipe.Parts, complete = true, variant = p.v, recovered = p.b == true or nil, mutation = mutation })
            else
                local parts = integer(p.p, 0, recipe.Parts - 1, 0)
                if parts == 0 or active[p.r] then continue end -- one unfinished project per rarity
                active[p.r] = true
                account.nextId += 1
                table.insert(account.projects, { id = account.nextId, rarity = p.r, parts = parts, complete = false })
            end
        end
    end
    if type(data.dex) == "table" then
        for id, n in data.dex do
            if type(id) == "string" and Catalog.find(id) then
                local times = integer(n, 0, 1e9, 0)
                if times > 0 then account.dex[id] = times end
            end
        end
    end
    if type(data.mdex) == "table" then
        for key, n in data.mdex do
            if type(key) ~= "string" then continue end
            local mutation, id = string.match(key, "^(%a+):(%w+)$")
            if mutation and id and Mutations.get(mutation) and Catalog.find(id) then
                local times = integer(n, 0, 1e9, 0)
                if times > 0 then account.mdex[key] = times end
            end
        end
    end
    -- Every robot standing on a platform is, by definition, discovered.
    for _, p in account.projects do
        if p.complete and p.variant and not account.dex[p.variant] then account.dex[p.variant] = 1 end
        if p.complete and p.variant and p.mutation then
            local key = Mutations.key(p.mutation, p.variant)
            if not account.mdex[key] then account.mdex[key] = 1 end
        end
    end
    local q = data.quests
    if type(q) == "table" and type(q.progress) == "table" and type(q.claimed) == "table" then
        local state = { day = integer(q.day, 0, 1e7, 0), progress = {}, claimed = {}, bonus = q.bonus == true }
        for i = 1, Config.Quests.PerDay do
            state.progress[i] = integer(q.progress[i], 0, 1e6, 0)
            state.claimed[i] = q.claimed[i] == true
        end
        account.quests = state
    end
    local function set(source: any, valid: (string) -> boolean, target: {[string]: boolean})
        if type(source) ~= "table" then return end
        for _, k in source do if type(k) == "string" and valid(k) then target[k] = true end end
    end
    local titles: {[string]: boolean} = {}
    local skins: {[string]: boolean} = {}
    for _, m in Rewards.List do
        for _, r in m.Rewards do
            if r.Type == "Title" then titles[r.Name :: string] = true elseif r.Type == "Skin" then skins[r.Name :: string] = true end
        end
    end
    set(data.claimed, function(k) return Rewards.get(k) ~= nil end, account.claimed)
    -- Permanent perks are recomputed from claimed milestones, never trusted.
    for id in account.claimed do
        for _, r in (Rewards.get(id) :: Rewards.Milestone).Rewards do
            if r.Type == "Income" then account.perks.income += r.Amount :: number
            elseif r.Type == "Speed" then account.perks.speed += r.Amount :: number
            elseif r.Type == "Title" then account.titles[r.Name :: string] = true
            elseif r.Type == "Skin" then account.skins[r.Name :: string] = true end
        end
    end
    if type(data.title) == "string" and account.titles[data.title] then account.title = data.title end
    if type(data.skin) == "string" and account.skins[data.skin] then account.skin = data.skin end
    if type(data.stats) == "table" then
        account.stats.built = integer(data.stats.built, 0, 1e9, 0)
        account.stats.unboxed = integer(data.stats.unboxed, 0, 1e9, 0)
    end
    return account
end

return Schema
