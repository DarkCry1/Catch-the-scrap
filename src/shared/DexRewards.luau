--!strict
-- Robotdex milestones. Modelled on popular Roblox collection games:
-- discovery-count milestones (like index thresholds in Steal a Brainrot, which
-- grant permanent cash multipliers and base skins) and per-page completion.
-- Rewards are claimed manually in the Robotdex and validated on the server.
local Catalog = require("./RobotCatalog")
local Mutations = require("./Mutations")
local Config = require("./Config")
export type Reward = { Type: string, Amount: number?, Rarity: string?, Name: string? }
export type Milestone = { Id: string, Kind: string, Need: number, Rarity: string?, Mutation: string?, Species: string?, Title: string, Rewards: {Reward} }
local Rewards = {}

local total = Catalog.Total
local function cash(n: number): Reward return { Type = "Cash", Amount = n } end
local function income(p: number): Reward return { Type = "Income", Amount = p } end
local function box(r: string): Reward return { Type = "Box", Rarity = r } end
local function title(name: string): Reward return { Type = "Title", Name = name } end
local function skin(name: string): Reward return { Type = "Skin", Name = name } end
local function speed(n: number): Reward return { Type = "Speed", Amount = n } end

local list: {Milestone} = {
    { Id = "Dex5", Kind = "Total", Need = 5, Title = "First Five", Rewards = { cash(1000), title("Scrap Collector") } },
    { Id = "Dex10", Kind = "Total", Need = 10, Title = "Ten Discovered", Rewards = { box("Rare") } },
    { Id = "Dex15", Kind = "Total", Need = 15, Title = "Fifteen Discovered", Rewards = { income(3) } },
    { Id = "Dex20", Kind = "Total", Need = 20, Title = "Twenty Discovered", Rewards = { cash(25000), skin("Brass") } },
    { Id = "Dex25", Kind = "Total", Need = 25, Title = "Twenty-Five Discovered", Rewards = { box("Epic"), title("Robot Wrangler") } },
    { Id = "Dex30", Kind = "Total", Need = 30, Title = "Half the Yard", Rewards = { income(4) } },
    { Id = "Dex35", Kind = "Total", Need = 35, Title = "Thirty-Five Discovered", Rewards = { speed(1), cash(150000) } },
    { Id = "Dex40", Kind = "Total", Need = 40, Title = "Forty Discovered", Rewards = { box("Legendary"), skin("Neon") } },
    { Id = "Dex45", Kind = "Total", Need = 45, Title = "Three Quarters", Rewards = { income(5), title("Master Mechanic") } },
    { Id = "Dex50", Kind = "Total", Need = 50, Title = "Fifty Discovered", Rewards = { box("Mythic") } },
    { Id = "Dex55", Kind = "Total", Need = 55, Title = "Ninety Percent", Rewards = { income(5), skin("Void") } },
    { Id = "DexAll", Kind = "Total", Need = total, Title = "Complete Robotdex", Rewards = { income(10), box("Celestial"), title("Celestial Archivist"), skin("Starforge") } },
    { Id = "PageCommon", Kind = "Rarity", Rarity = "Common", Need = 0, Title = "Common Page", Rewards = { cash(5000), title("Junk Hoarder") } },
    { Id = "PageUncommon", Kind = "Rarity", Rarity = "Uncommon", Need = 0, Title = "Uncommon Page", Rewards = { cash(30000), speed(1) } },
    { Id = "PageRare", Kind = "Rarity", Rarity = "Rare", Need = 0, Title = "Rare Page", Rewards = { income(2), box("Rare") } },
    { Id = "PageEpic", Kind = "Rarity", Rarity = "Epic", Need = 0, Title = "Epic Page", Rewards = { income(2), box("Epic") } },
    { Id = "PageLegendary", Kind = "Rarity", Rarity = "Legendary", Need = 0, Title = "Legendary Page", Rewards = { income(3), title("Golden Hand") } },
    { Id = "PageMythic", Kind = "Rarity", Rarity = "Mythic", Need = 0, Title = "Mythic Page", Rewards = { income(3), box("Legendary") } },
    { Id = "PageCelestial", Kind = "Rarity", Rarity = "Celestial", Need = 0, Title = "Celestial Page", Rewards = { income(4), title("Starforged") } },
    -- v1.3 mutation collections (distinct species owned as Gold / Rainbow).
    { Id = "Gold3", Kind = "Mutation", Mutation = "Gold", Need = 3, Title = "Three Gold Robots", Rewards = { cash(50000), title("Gold Digger") } },
    { Id = "Gold10", Kind = "Mutation", Mutation = "Gold", Need = 10, Title = "Ten Gold Robots", Rewards = { income(3), skin("Gilded") } },
    { Id = "Gold25", Kind = "Mutation", Mutation = "Gold", Need = 25, Title = "Gold Collection", Rewards = { income(4), box("Legendary") } },
    { Id = "Rainbow1", Kind = "Mutation", Mutation = "Rainbow", Need = 1, Title = "First Rainbow", Rewards = { cash(100000), title("Prism Hunter") } },
    { Id = "Rainbow5", Kind = "Mutation", Mutation = "Rainbow", Need = 5, Title = "Five Rainbows", Rewards = { income(3), skin("Prism") } },
    { Id = "Rainbow12", Kind = "Mutation", Mutation = "Rainbow", Need = 12, Title = "Rainbow Collection", Rewards = { income(5), box("Mythic"), title("Spectrum Legend") } },
    -- v1.5 mutations.
    { Id = "Diamond2", Kind = "Mutation", Mutation = "Diamond", Need = 2, Title = "Two Diamond Robots", Rewards = { cash(75000), title("Diamond Cutter") } },
    { Id = "Diamond8", Kind = "Mutation", Mutation = "Diamond", Need = 8, Title = "Eight Diamond Robots", Rewards = { income(3), skin("Crystal") } },
    { Id = "Diamond20", Kind = "Mutation", Mutation = "Diamond", Need = 20, Title = "Diamond Collection", Rewards = { box("Mythic"), cash(2000000) } },
    { Id = "Lava1", Kind = "Mutation", Mutation = "Lava", Need = 1, Title = "First Lava Robot", Rewards = { cash(150000), title("Magma Tamer") } },
    { Id = "Lava4", Kind = "Mutation", Mutation = "Lava", Need = 4, Title = "Four Lava Robots", Rewards = { income(3), skin("Inferno") } },
    { Id = "Lava10", Kind = "Mutation", Mutation = "Lava", Need = 10, Title = "Lava Collection", Rewards = { box("Mythic"), title("Volcano Lord") } },
    { Id = "Galaxy1", Kind = "Mutation", Mutation = "Galaxy", Need = 1, Title = "First Galaxy Robot", Rewards = { cash(300000), title("Stargazer") } },
    { Id = "Galaxy3", Kind = "Mutation", Mutation = "Galaxy", Need = 3, Title = "Three Galaxy Robots", Rewards = { income(4), skin("Nebula") } },
    { Id = "Galaxy6", Kind = "Mutation", Mutation = "Galaxy", Need = 6, Title = "Galaxy Collection", Rewards = { box("Celestial"), title("Galactic Legend") } },
    -- Full sets: every version (Normal + all mutations) of one species.
    { Id = "Set1", Kind = "Complete", Need = 1, Title = "First Full Set", Rewards = { box("Epic"), title("Set Collector") } },
    { Id = "Set3", Kind = "Complete", Need = 3, Title = "Three Full Sets", Rewards = { cash(1000000) } },
    { Id = "Set5", Kind = "Complete", Need = 5, Title = "Five Full Sets", Rewards = { income(3), box("Legendary") } },
    { Id = "Set15", Kind = "Complete", Need = 15, Title = "Fifteen Full Sets", Rewards = { income(5), title("Version Master"), skin("Mosaic") } },
}
-- Page milestones need every species of that rarity.
for _, m in list do
    if m.Kind == "Rarity" then m.Need = #Catalog.forRarity(m.Rarity :: string) end
end
Rewards.List = list

-- Cosmetic workshop skins: accent color for neon trim (Starforge = rainbow).
export type Skin = { Label: string, Color: {number}?, Rainbow: boolean }
local skins: {[string]: Skin} = {
    Default = { Label = "Workshop Default", Color = nil, Rainbow = false },
    Brass = { Label = "Brass Works", Color = { 255, 186, 82 }, Rainbow = false },
    Neon = { Label = "Neon Forge", Color = { 255, 72, 196 }, Rainbow = false },
    Void = { Label = "Void Salvage", Color = { 156, 96, 255 }, Rainbow = false },
    Starforge = { Label = "Starforge", Color = { 126, 234, 255 }, Rainbow = true },
    Gilded = { Label = "Gilded Works", Color = { 255, 206, 64 }, Rainbow = false },
    Prism = { Label = "Prism Forge", Color = { 255, 120, 220 }, Rainbow = true },
    Crystal = { Label = "Crystal Works", Color = { 170, 236, 255 }, Rainbow = false },
    Inferno = { Label = "Inferno Forge", Color = { 255, 96, 24 }, Rainbow = false },
    Nebula = { Label = "Nebula Lab", Color = { 168, 112, 255 }, Rainbow = false },
    Mosaic = { Label = "Mosaic Forge", Color = { 255, 255, 255 }, Rainbow = true },
}
Rewards.Skins = skins
Rewards.SkinOrder = { "Default", "Brass", "Gilded", "Crystal", "Neon", "Inferno", "Void", "Nebula", "Prism", "Mosaic", "Starforge" }

-- Entry rewards (v1.7): every species, and every mutated version of it, pays
-- a small one-time cash reward the first time it is collected, claimed in the
-- Robotdex. Worth EntrySeconds of that robot's income, so it never outpaces
-- simply owning the robot (the grind stays the main source of cash).
Rewards.EntrySeconds = 40
function Rewards.entryId(species: string, mutation: string?): string
    return if mutation then "Entry:" .. mutation .. ":" .. species else "Entry:" .. species
end
function Rewards.entryCash(species: string, mutation: string?): number
    local s = Catalog.get(species)
    local income = Catalog.income(Config.Robot.Recipes[s.Rarity].Income, species) * Mutations.multiplier(mutation)
    return math.max(50, math.floor(income * Rewards.EntrySeconds / 10 + 0.5) * 10)
end
local entryCache: {[string]: Milestone} = {}
local function entry(id: string): Milestone?
    local cached = entryCache[id]
    if cached then return cached end
    if string.sub(id, 1, 6) ~= "Entry:" then return nil end
    local rest = string.sub(id, 7)
    local colon = string.find(rest, ":", 1, true)
    local mutation: string? = if colon then string.sub(rest, 1, colon - 1) else nil
    local species = if colon then string.sub(rest, colon + 1) else rest
    if not Catalog.find(species) or (mutation ~= nil and Mutations.get(mutation) == nil) then return nil end
    local label = Mutations.prefix(mutation) .. Catalog.get(species).Name
    local m: Milestone = { Id = id, Kind = "Entry", Need = 1, Species = species, Mutation = mutation, Title = "Robotdex entry: " .. label,
        Rewards = { cash(Rewards.entryCash(species, mutation)) } }
    entryCache[id] = m
    return m
end
function Rewards.get(id: string): Milestone?
    for _, m in list do if m.Id == id then return m end end
    return entry(id)
end

type DexState = { dex: {[string]: number}, claimed: {[string]: boolean}, mdex: {[string]: number} }
function Rewards.progress(state: DexState, m: Milestone): number
    local count = 0
    if m.Kind == "Entry" then
        local species = m.Species :: string
        local owned = if m.Mutation then Mutations.owned(state.mdex, m.Mutation :: string, species) else Mutations.normalOwned(state.dex, state.mdex, species)
        return if owned > 0 then 1 else 0
    end
    if m.Kind == "Complete" then
        for _, s in Catalog.List do
            if Mutations.versionsOwned(state.dex, state.mdex, s.Id) >= Mutations.Versions then count += 1 end
        end
        return count
    end
    if m.Kind == "Mutation" then
        local prefix = (m.Mutation :: string) .. ":"
        for key, times in state.mdex do
            if times > 0 and string.sub(key, 1, #prefix) == prefix and Catalog.find(string.sub(key, #prefix + 1)) then count += 1 end
        end
        return count
    end
    for id, times in state.dex do
        local s = Catalog.find(id)
        if s and times > 0 and (m.Kind == "Total" or s.Rarity == m.Rarity) then count += 1 end
    end
    return count
end
function Rewards.ready(state: DexState, m: Milestone): boolean
    return not state.claimed[m.Id] and Rewards.progress(state, m) >= m.Need
end
-- Entry rewards ready to claim (owned versions not yet claimed).
function Rewards.readyEntries(state: DexState): {Milestone}
    local out: {Milestone} = {}
    for _, s in Catalog.List do
        if (state.dex[s.Id] or 0) > 0 then
            local ids = { Rewards.entryId(s.Id, nil) }
            for _, mu in Mutations.List do table.insert(ids, Rewards.entryId(s.Id, mu.Id)) end
            for _, id in ids do
                local m = entry(id) :: Milestone
                if Rewards.ready(state, m) then table.insert(out, m) end
            end
        end
    end
    return out
end
function Rewards.claimable(state: DexState): number
    local n = #Rewards.readyEntries(state)
    for _, m in list do if Rewards.ready(state, m) then n += 1 end end
    return n
end
function Rewards.describe(r: Reward): string
    if r.Type == "Cash" then return string.format("$%s cash", tostring(r.Amount)) end
    if r.Type == "Income" then return string.format("+%d%% income forever", r.Amount :: number) end
    if r.Type == "Box" then return (r.Rarity :: string) .. " Robot Box" end
    if r.Type == "Title" then return "Title: " .. (r.Name :: string) end
    if r.Type == "Skin" then return "Workshop skin: " .. Rewards.Skins[r.Name :: string].Label end
    if r.Type == "Speed" then return string.format("+%d base speed forever", r.Amount :: number) end
    return r.Type
end
-- Total permanent income bonus available from all milestones (for balance tests).
function Rewards.maxIncomeBonus(): number
    local sum = 0
    for _, m in list do for _, r in m.Rewards do if r.Type == "Income" then sum += r.Amount :: number end end end
    return sum
end
return Rewards
