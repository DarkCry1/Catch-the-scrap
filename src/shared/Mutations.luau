--!strict
-- Robot mutations (Gold, Diamond, Rainbow, Lava, Galaxy). Rolled on the
-- server, independently of the species: a build when it completes, a box when
-- it spawns (kept secret). Every species can be collected in every version.
local Config = require("./Config")
export type Mutation = { Id: string, Label: string, Chance: number, Multiplier: number, Color: {number},
    Body: {number}, Material: string, Reflectance: number, Transparency: number, Accent: {number}, Accent2: {number},
    AccentEvery: number, Pattern: string, Sparkles: number }
export type Paint = { Color: {number}, Material: string, Reflectance: number, Transparency: number, Neon: boolean, Spectrum: boolean }
local Mutations = {}
local byId: {[string]: Mutation} = {}
for _, m in Config.Mutations do byId[m.Id] = m end
Mutations.List = Config.Mutations :: {Mutation}
-- Versions shown per species in the Robotdex: Normal first, then each mutation.
Mutations.Versions = 1 + #Mutations.List

-- Palettes repainted by a mutation (glow/trim keep the rarity color).
Mutations.Painted = { steel = true, dark = false, copper = true, rust = true, olive = true, navy = true, bone = true, crimson = true,
    teal = true, graphite = true, sand = true, white = true, gold = true, ice = true, void = true, violet = true, wall = true, floor = true } :: {[string]: boolean}

function Mutations.get(id: string?): Mutation?
    if id == nil then return nil end
    return byId[id]
end
function Mutations.valid(id: any): boolean
    return id == nil or (type(id) == "string" and byId[id] ~= nil)
end
-- The rarest mutation is checked first, so chances do not overlap.
function Mutations.roll(unit: number): string?
    assert(unit >= 0 and unit < 1, "Valid random sample required")
    local edge = 0
    local ordered: {Mutation} = table.clone(Mutations.List)
    table.sort(ordered, function(a: Mutation, b: Mutation) return a.Chance < b.Chance end)
    for _, m in ordered do
        edge += m.Chance
        if unit < edge - 1e-12 then return m.Id end
    end
    return nil
end
function Mutations.multiplier(id: string?): number
    local m = Mutations.get(id)
    return if m then m.Multiplier else 1
end
function Mutations.key(mutation: string, species: string): string
    return mutation .. ":" .. species
end
function Mutations.prefix(id: string?): string
    local m = Mutations.get(id)
    return if m then m.Label:upper() .. " " else ""
end

local function hue(h: number): {number}
    -- HSV(h, .55, 1) to 0-255 RGB without engine types.
    local s, v = 0.55, 1
    local i = math.floor(h * 6) % 6
    local f = h * 6 - math.floor(h * 6)
    local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    local rgb = ({ { v, t, p }, { q, v, p }, { p, v, t }, { p, q, v }, { t, p, v }, { v, p, q } })[i + 1]
    return { math.floor(rgb[1] * 255 + 0.5), math.floor(rgb[2] * 255 + 0.5), math.floor(rgb[3] * 255 + 0.5) }
end
-- How a painted part looks in a mutation. index = the part's position in the
-- build (1-based), so accents and the rainbow spread are stable everywhere
-- (world robots and Robotdex previews look the same).
function Mutations.paint(id: string?, index: number): Paint?
    local m = Mutations.get(id)
    if not m then return nil end
    if m.AccentEvery > 0 and index % m.AccentEvery == 0 then
        local alt = (index // m.AccentEvery) % 2 == 0
        return { Color = if alt then m.Accent2 else m.Accent, Material = "Neon", Reflectance = 0, Transparency = 0, Neon = true, Spectrum = false }
    end
    if m.Pattern == "Spectrum" then
        return { Color = hue((index * 0.037) % 1), Material = m.Material, Reflectance = m.Reflectance, Transparency = m.Transparency, Neon = false, Spectrum = true }
    end
    return { Color = m.Body, Material = m.Material, Reflectance = m.Reflectance, Transparency = m.Transparency, Neon = false, Spectrum = false }
end

-- Collection helpers over a player's mutation dex ("Mutation:Species" -> count).
function Mutations.owned(mdex: {[string]: number}, mutation: string, species: string): number
    return mdex[Mutations.key(mutation, species)] or 0
end
-- Normal (unmutated) copies: every copy is counted in dex, mutated copies
-- are also counted in mdex.
function Mutations.normalOwned(dex: {[string]: number}, mdex: {[string]: number}, species: string): number
    local n = dex[species] or 0
    for _, m in Mutations.List do n -= Mutations.owned(mdex, m.Id, species) end
    return math.max(0, n)
end
-- Versions of one species owned, out of Mutations.Versions.
function Mutations.versionsOwned(dex: {[string]: number}, mdex: {[string]: number}, species: string): number
    local n = if Mutations.normalOwned(dex, mdex, species) > 0 then 1 else 0
    for _, m in Mutations.List do
        if Mutations.owned(mdex, m.Id, species) > 0 then n += 1 end
    end
    return n
end
return Mutations
