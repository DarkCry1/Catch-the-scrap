--!strict
-- Robotdex milestones. Modelled on popular Roblox collection games:
-- discovery-count milestones (like index thresholds in Steal a Brainrot, which
-- grant permanent cash multipliers and base skins) and per-page completion.
-- Rewards are claimed manually in the Robotdex and validated on the server.
local Catalog = require("./RobotCatalog")
export type Reward = { Type: string, Amount: number?, Rarity: string?, Name: string? }
export type Milestone = { Id: string, Kind: string, Need: number, Rarity: string?, Mutation: string?, Title: string, Rewards: {Reward} }
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
    { Id = "Dex15", Kind = "Total", Need = 15, Title = "Fifteen Discovered", Rewards = { income(10) } },
    { Id = "Dex20", Kind = "Total", Need = 20, Title = "Twenty Discovered", Rewards = { cash(25000), skin("Brass") } },
    { Id = "Dex25", Kind = "Total", Need = 25, Title = "Twenty-Five Discovered", Rewards = { box("Epic"), title("Robot Wrangler") } },
    { Id = "Dex30", Kind = "Total", Need = 30, Title = "Half the Yard", Rewards = { income(15) } },
    { Id = "Dex35", Kind = "Total", Need = 35, Title = "Thirty-Five Discovered", Rewards = { speed(2), cash(150000) } },
    { Id = "Dex40", Kind = "Total", Need = 40, Title = "Forty Discovered", Rewards = { box("Legendary"), skin("Neon") } },
    { Id = "Dex45", Kind = "Total", Need = 45, Title = "Three Quarters", Rewards = { income(25), title("Master Mechanic") } },
    { Id = "Dex50", Kind = "Total", Need = 50, Title = "Fifty Discovered", Rewards = { box("Mythic") } },
    { Id = "Dex55", Kind = "Total", Need = 55, Title = "Ninety Percent", Rewards = { income(25), skin("Void") } },
    { Id = "DexAll", Kind = "Total", Need = total, Title = "Complete Robotdex", Rewards = { income(50), box("Celestial"), title("Celestial Archivist"), skin("Starforge") } },
    { Id = "PageCommon", Kind = "Rarity", Rarity = "Common", Need = 0, Title = "Common Page", Rewards = { cash(5000), title("Junk Hoarder") } },
    { Id = "PageUncommon", Kind = "Rarity", Rarity = "Uncommon", Need = 0, Title = "Uncommon Page", Rewards = { cash(30000), speed(1) } },
    { Id = "PageRare", Kind = "Rarity", Rarity = "Rare", Need = 0, Title = "Rare Page", Rewards = { income(5), box("Rare") } },
    { Id = "PageEpic", Kind = "Rarity", Rarity = "Epic", Need = 0, Title = "Epic Page", Rewards = { income(5), box("Epic") } },
    { Id = "PageLegendary", Kind = "Rarity", Rarity = "Legendary", Need = 0, Title = "Legendary Page", Rewards = { income(10), title("Golden Hand") } },
    { Id = "PageMythic", Kind = "Rarity", Rarity = "Mythic", Need = 0, Title = "Mythic Page", Rewards = { income(10), box("Legendary") } },
    { Id = "PageCelestial", Kind = "Rarity", Rarity = "Celestial", Need = 0, Title = "Celestial Page", Rewards = { income(15), title("Starforged") } },
    -- v1.3 mutation collections (distinct species owned as Gold / Rainbow).
    { Id = "Gold3", Kind = "Mutation", Mutation = "Gold", Need = 3, Title = "Three Gold Robots", Rewards = { cash(50000), title("Gold Digger") } },
    { Id = "Gold10", Kind = "Mutation", Mutation = "Gold", Need = 10, Title = "Ten Gold Robots", Rewards = { income(10), skin("Gilded") } },
    { Id = "Gold25", Kind = "Mutation", Mutation = "Gold", Need = 25, Title = "Gold Collection", Rewards = { income(20), box("Legendary") } },
    { Id = "Rainbow1", Kind = "Mutation", Mutation = "Rainbow", Need = 1, Title = "First Rainbow", Rewards = { cash(100000), title("Prism Hunter") } },
    { Id = "Rainbow5", Kind = "Mutation", Mutation = "Rainbow", Need = 5, Title = "Five Rainbows", Rewards = { income(15), skin("Prism") } },
    { Id = "Rainbow12", Kind = "Mutation", Mutation = "Rainbow", Need = 12, Title = "Rainbow Collection", Rewards = { income(25), box("Mythic"), title("Spectrum Legend") } },
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
}
Rewards.Skins = skins
Rewards.SkinOrder = { "Default", "Brass", "Gilded", "Neon", "Void", "Prism", "Starforge" }

function Rewards.get(id: string): Milestone?
    for _, m in list do if m.Id == id then return m end end
    return nil
end

type DexState = { dex: {[string]: number}, claimed: {[string]: boolean}, mdex: {[string]: number} }
function Rewards.progress(state: DexState, m: Milestone): number
    local count = 0
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
function Rewards.claimable(state: DexState): number
    local n = 0
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
