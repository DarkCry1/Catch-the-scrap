--!strict
-- Gold and Rainbow robot mutations. Rolled on the server, independently of the
-- species: a build when it completes, a box when it spawns (kept secret).
local Config = require("./Config")
export type Mutation = { Id: string, Label: string, Chance: number, Multiplier: number, Color: {number} }
local Mutations = {}
local byId: {[string]: Mutation} = {}
for _, m in Config.Mutations do byId[m.Id] = m end
Mutations.List = Config.Mutations :: {Mutation}

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
return Mutations
