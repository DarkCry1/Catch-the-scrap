--!strict
-- Robotdex species. Every species belongs to exactly one rarity and one source:
--   Build: rolled (weighted) when a scrap project of that rarity completes.
--   Box:   rolled (weighted) when a robot box of that rarity is opened.
-- Lower weight = rarer within its pool = higher income multiplier.
-- Ten original hand-built chassis (legacy ids) keep their RobotVariants
-- geometry; all other species are assembled by RobotForge from `design`.
local Forge = require("./RobotForge")
export type Species = {
    Id: string, Number: number, Name: string, Rarity: string, Source: string,
    Weight: number, Multiplier: number, Blurb: string, Design: Forge.Design?,
}
local Catalog = {}
local list: {Species} = {}
local byId: {[string]: Species} = {}
local function D(legs: string, body: string, arms: string, head: string, extras: {string}, main: string, dark: string, accent: string, extra: {[string]: any}?): Forge.Design
    local design: Forge.Design = { legs = legs, body = body, arms = arms, head = head, extras = extras, main = main, dark = dark, accent = accent }
    if extra then
        design.scale = extra.scale; design.bodySize = extra.bodySize; design.legHeight = extra.legHeight
    end
    return design
end
local function S(id: string, name: string, rarity: string, source: string, weight: number, multiplier: number, blurb: string, design: Forge.Design?)
    local species: Species = { Id = id, Number = #list + 1, Name = name, Rarity = rarity, Source = source, Weight = weight, Multiplier = multiplier, Blurb = blurb, Design = design }
    assert(byId[id] == nil, "Duplicate species id " .. id)
    table.insert(list, species); byId[id] = species
end

-- COMMON: Sorting Yard junk bots (all built from scrap)
S("Rustbucket", "Rustbucket", "Common", "Build", 14, 1.0, "A bucket that learned to walk. Rattles politely.", D("Biped", "Barrel", "Stub", "Bucket", { "Antenna" }, "rust", "dark", "steel", { legHeight = 1.8 }))
S("Canbot", "Canbot", "Common", "Build", 13, 1.0, "Recycled from a thousand soda cans. Still fizzes.", D("Trike", "Barrel", "Claw", "Cyclops", {}, "steel", "dark", "crimson", { bodySize = { 2.6, 2.6, 2.6 } }))
S("Sprocket", "Sprocket", "Common", "Build", 12, 1.05, "Balances on one wheel and a lot of confidence.", D("Unicycle", "Sphere", "Stub", "Dome", { "Antenna", "Exhaust" }, "copper", "dark", "steel", { bodySize = { 2.8, 2.8, 2.8 } }))
S("JunkWalker", "Junk Walker", "Common", "Build", 11, 1.05, "The yard's most common commuter.", D("Biped", "Box", "Claw", "Visor", { "Backpack" }, "steel", "dark", "rust"))
S("TinScout", "Tin Scout", "Common", "Build", 10, 1.1, "Sniffs out loose bolts from 50 studs away.", D("Quad", "Box", "Stub", "Camera", { "Antenna", "Tail" }, "olive", "dark", "steel", { bodySize = { 2.6, 1.8, 3.4 } }))
S("ScrapCrab", "Scrap Crab", "Common", "Build", 9, 1.15, "Walks sideways. Pinches forward.", D("Crab", "Disc", "Pincer", "Stalks", {}, "crimson", "dark", "sand", { bodySize = { 3.6, 1.2, 3.6 } }))
S("BoltBuggy", "Bolt Buggy", "Common", "Build", 8, 1.2, "Zero to ten studs per second, eventually.", D("Wheels", "Wedge", "Stub", "TV", { "Exhaust" }, "teal", "dark", "steel"))
S("PailPusher", "Pail Pusher", "Common", "Build", 7, 1.25, "Moves dirt from here to slightly over there.", D("Treads", "Crate", "Scoop", "Visor", {}, "sand", "dark", "rust"))
S("GearHopper", "Gear Hopper", "Common", "Build", 6, 1.3, "Bounces between scrap piles all day.", D("Pogo", "Sphere", "Stub", "Dome", { "Gears", "TwinAntenna" }, "steel", "graphite", "copper", { bodySize = { 2.8, 2.8, 2.8 } }))
S("WrenchWally", "Wrench Wally", "Common", "Build", 5, 1.4, "Fixes everything except his own squeak.", D("Biped", "Box", "Hammer", "Horned", {}, "navy", "dark", "steel"))
S("MopDroid", "Mop Droid", "Common", "Build", 4, 1.6, "Cleans the yard. The yard did not ask.", D("Hover", "Barrel", "Tentacle", "Camera", { "Backpack" }, "white", "graphite", "teal", { bodySize = { 2.6, 2.6, 2.6 } }))
S("LuckyLugnut", "Lucky Lugnut", "Common", "Build", 4, 2.0, "Found it? Buy a lottery ticket.", D("Unicycle", "Sphere", "Stub", "Cyclops", { "Halo", "Antenna" }, "gold", "dark", "white", { bodySize = { 2.8, 2.8, 2.8 } }))

-- UNCOMMON: Machine Graveyard workers
S("Bastion", "Iron Bastion", "Uncommon", "Build", 14, 1.0, "Heavy armor salvaged from a collapsed gatehouse.", nil)
S("Weldsmith", "Arc Weldsmith", "Uncommon", "Build", 13, 1.05, "Welds day and night behind a scorched visor.", nil)
S("Hauler", "Scrap Hauler", "Uncommon", "Build", 12, 1.1, "Carries more than it should. Complains less.", nil)
S("ForkliftFred", "Forklift Fred", "Uncommon", "Build", 11, 1.15, "Lifts pallets and spirits.", D("Wheels", "Box", "Fork", "TV", { "Antenna" }, "gold", "dark", "graphite"))
S("PipeFitter", "Pipe Fitter", "Uncommon", "Build", 10, 1.2, "Speaks fluent plumbing.", D("Biped", "Barrel", "Hammer", "Periscope", { "Exhaust" }, "teal", "dark", "copper"))
S("RivetGunner", "Rivet Gunner", "Uncommon", "Build", 9, 1.25, "Fastens anything at 900 rivets per minute.", D("Treads", "Box", "Cannon", "Visor", { "Backpack" }, "olive", "dark", "steel"))
S("SawSentry", "Saw Sentry", "Uncommon", "Build", 8, 1.3, "Guards the timber pile. There is no timber pile.", D("Quad", "Wedge", "Saw", "Camera", {}, "steel", "dark", "crimson", { bodySize = { 3, 2, 3.4 } }))
S("DozerDan", "Dozer Dan", "Uncommon", "Build", 7, 1.35, "Pushes first, asks questions never.", D("Treads", "Crate", "Scoop", "Bucket", { "Exhaust" }, "gold", "dark", "rust"))
S("CoilCrawler", "Coil Crawler", "Uncommon", "Build", 6, 1.45, "Slithers through cable heaps.", D("Snake", "Capsule", "Stub", "Cyclops", { "TwinAntenna" }, "teal", "graphite", "copper", { bodySize = { 2.2, 3, 2.2 } }))
S("CraneArm", "Crane Arm", "Uncommon", "Build", 5, 1.6, "Can lift a car. Prefers lifting moods.", D("Treads", "Tower", "Claw", "Camera", { "Dish" }, "gold", "dark", "steel"))
S("ChromeCourier", "Chrome Courier", "Uncommon", "Build", 4, 1.9, "Delivers parcels nobody ordered.", D("Hover", "Box", "Stub", "Dome", { "Propeller" }, "white", "graphite", "steel", { bodySize = { 3, 2.2, 2 } }))

-- RARE: Reactor Wrecks
S("Driller", "Drillmaster", "Rare", "Build", 30, 1.0, "Tunnels through reactor rubble with a spinning bit.", nil)
S("ReactorRover", "Reactor Rover", "Rare", "Build", 25, 1.1, "A rolling coolant tank with opinions.", D("Wheels", "Barrel", "Claw", "Dome", { "Antenna" }, "olive", "dark", "steel"))
S("CoolantCrab", "Coolant Crab", "Rare", "Build", 20, 1.2, "Keeps the cores cold and its claws colder.", D("Crab", "Disc", "Pincer", "Stalks", { "Backpack" }, "ice", "navy", "steel", { bodySize = { 3.8, 1.3, 3.8 } }))
S("FuseBox", "Fuse Box", "Rare", "Build", 15, 1.35, "Do not touch. Seriously.", D("Biped", "Box", "Stub", "TV", { "Exhaust", "Gears" }, "graphite", "dark", "gold", { legHeight = 1.9 }))
S("IsotopeImp", "Isotope Imp", "Rare", "Build", 8, 1.6, "Small, glowing, and very pleased about it.", D("Hover", "Sphere", "Claw", "Horned", { "Tail" }, "olive", "void", "steel", { bodySize = { 2.6, 2.6, 2.6 } }))
S("MeltdownMk2", "Meltdown Mk-II", "Rare", "Build", 4, 2.0, "Runs hot. Always. Everywhere.", D("Treads", "Furnace", "Cannon", "Visor", { "Flames" }, "crimson", "dark", "graphite"))
S("Volt", "Volt Runner", "Rare", "Box", 45, 4.0, "A sprinter built around a stolen capacitor.", nil)
S("GammaGuardian", "Gamma Guardian", "Rare", "Box", 30, 4.6, "Shields up, radiation in.", D("Biped", "Tower", "Shield", "Horned", { "Spikes" }, "olive", "dark", "steel", { bodySize = { 2.6, 3, 2.2 }, legHeight = 1.9 }))
S("FissionPhantom", "Fission Phantom", "Rare", "Box", 18, 5.4, "Flickers between here and slightly radioactive.", D("Hover", "Capsule", "Tentacle", "Cyclops", { "OrbitRing" }, "ice", "void", "steel"))
S("AtomAce", "Atom Ace", "Rare", "Box", 7, 6.5, "The fastest wheel in the wreck fields.", D("Unicycle", "Sphere", "Wing", "Dome", { "Halo", "Fins" }, "white", "navy", "gold", { bodySize = { 2.8, 2.8, 2.8 } }))

-- EPIC: Turbine Foundry
S("Magnet", "Magnetron", "Epic", "Build", 32, 1.0, "Tank-tracked collector with a giant magnet.", nil)
S("TurbineTusk", "Turbine Tusk", "Epic", "Build", 26, 1.15, "Drills with turbine-powered tusks.", D("Quad", "Barrel", "Drill", "Horned", { "Exhaust" }, "steel", "graphite", "copper", { bodySize = { 3, 2.4, 3 } }))
S("BlastFurnace", "Blast Furnace", "Epic", "Build", 20, 1.3, "Smelts scrap into slightly better scrap.", D("Treads", "Furnace", "Hammer", "Bucket", { "Flames" }, "graphite", "dark", "copper"))
S("GaleGolem", "Gale Golem", "Epic", "Build", 14, 1.5, "Its rotor never stops. Neither does it.", D("HeavyBiped", "Box", "Shield", "Visor", { "Propeller" }, "violet", "dark", "steel", { bodySize = { 3.6, 2.6, 2.2 } }))
S("RotorWraith", "Rotor Wraith", "Epic", "Build", 8, 1.9, "A whisper of blades over the foundry.", D("Hover", "Disc", "Wing", "Camera", { "Propeller", "Fins" }, "violet", "void", "white"))
S("Orbital", "Orbital Warden", "Epic", "Box", 45, 4.2, "Hovers inside a ring of orbiting plates.", nil)
S("CycloneSovereign", "Cyclone Sovereign", "Epic", "Box", 30, 4.8, "Rules the turbine halls from the eye of a storm.", D("Hover", "Sphere", "Saw", "Crown", { "Fins" }, "violet", "dark", "white", { bodySize = { 3, 3, 3 } }))
S("PistonPaladin", "Piston Paladin", "Epic", "Box", 18, 5.6, "Every punch is a perfectly timed piston stroke.", D("Biped", "Tower", "Hammer", "Horned", { "Cape" }, "steel", "dark", "violet", { bodySize = { 2.6, 3, 2.2 }, legHeight = 1.9 }))
S("VortexValkyrie", "Vortex Valkyrie", "Epic", "Box", 7, 6.8, "Rides the updraft above the foundry stacks.", D("Hover", "Wedge", "Wing", "Dome", { "Halo", "Wings" }, "white", "violet", "gold"))

-- LEGENDARY: Golden Furnace
S("GildedGolem", "Gilded Golem", "Legendary", "Build", 40, 1.0, "Plated in gold leaf from the furnace floor.", D("HeavyBiped", "Box", "Hammer", "Crown", {}, "gold", "dark", "crimson", { bodySize = { 3.6, 2.6, 2.2 } }))
S("EmberHound", "Ember Hound", "Legendary", "Build", 30, 1.2, "Fetches glowing ingots. Do not pet.", D("Quad", "Wedge", "Stub", "Horned", { "Tail", "Flames" }, "crimson", "dark", "gold", { bodySize = { 3, 2, 3.4 } }))
S("AnvilAncient", "Anvil Ancient", "Legendary", "Build", 20, 1.45, "Older than the yard. Harder than the anvil.", D("Treads", "Crate", "Hammer", "Visor", { "Exhaust", "Gears" }, "graphite", "dark", "gold"))
S("CrucibleQueen", "Crucible Queen", "Legendary", "Build", 10, 1.8, "Pours molten gold with royal precision.", D("Hover", "Barrel", "Tentacle", "Crown", { "Cape" }, "gold", "crimson", "white"))
S("Prism", "Prism Oracle", "Legendary", "Box", 45, 4.4, "Sees the future in floating crystals.", nil)
S("SolarSphinx", "Solar Sphinx", "Legendary", "Box", 30, 5.2, "Guards the furnace with a riddle and a laser.", D("Quad", "Wedge", "Wing", "Horned", { "Wings", "Halo" }, "sand", "dark", "gold", { bodySize = { 3, 2.2, 3.6 } }))
S("MoltenMonarch", "Molten Monarch", "Legendary", "Box", 18, 6.0, "Crowned in fire, armed with cannons.", D("Biped", "Furnace", "Cannon", "Crown", { "Spikes" }, "crimson", "dark", "gold"))
S("GoldwingSeraph", "Goldwing Seraph", "Legendary", "Box", 7, 7.2, "A rumor with golden wings.", D("Hover", "Capsule", "Wing", "Dome", { "Halo", "Wings" }, "gold", "white", "crimson"))

-- MYTHIC: Void Salvage
S("VoidStalker", "Void Stalker", "Mythic", "Build", 60, 1.0, "Six legs, one eye, zero sound.", D("Crab", "Disc", "Claw", "Cyclops", { "Spikes" }, "void", "black", "violet", { bodySize = { 3.8, 1.4, 3.8 } }))
S("NullLeviathan", "Null Leviathan", "Mythic", "Build", 30, 1.3, "Swims through the dark between scrap heaps.", D("Snake", "Capsule", "Tentacle", "Horned", { "Fins" }, "void", "black", "teal"))
S("EclipseEngine", "Eclipse Engine", "Mythic", "Build", 10, 1.8, "Swallows light to spin its blades.", D("Hover", "Sphere", "Saw", "Camera", { "OrbitRing" }, "black", "void", "gold", { bodySize = { 3, 3, 3 } }))
S("Sunforge", "Sunforge Sentinel", "Mythic", "Box", 50, 4.5, "Solar wings, extra arms, endless patience.", nil)
S("AbyssArchon", "Abyss Archon", "Mythic", "Box", 32, 5.6, "Commands the void salvage from a floating tower.", D("Hover", "Tower", "Tentacle", "Crown", { "Crystals", "Wings" }, "void", "black", "violet", { bodySize = { 2.4, 3, 2.2 } }))
S("RiftReaper", "Rift Reaper", "Mythic", "Box", 18, 7.0, "Collects what the rift leaves behind.", D("Biped", "Wedge", "Saw", "Skull", { "Cape", "Spikes" }, "black", "void", "crimson"))

-- CELESTIAL: Starforge Ruins
S("StarforgeTitan", "Starforge Titan", "Celestial", "Build", 75, 1.0, "Hammered together where stars cooled.", D("HeavyBiped", "Box", "Hammer", "Crown", { "Halo" }, "white", "navy", "gold", { bodySize = { 3.6, 2.6, 2.2 }, legHeight = 2.0 }))
S("NebulaNomad", "Nebula Nomad", "Celestial", "Build", 25, 1.4, "Drifts between ruins, humming in starlight.", D("Hover", "Sphere", "Wing", "Cyclops", { "OrbitRing", "Crystals" }, "navy", "void", "white", { bodySize = { 3, 3, 3 } }))
S("Chrono", "Chrono Knight", "Celestial", "Box", 45, 4.6, "A knight that keeps perfect time.", nil)
S("CometColossus", "Comet Colossus", "Celestial", "Box", 35, 5.8, "Fell from the sky. Got up angry.", D("Treads", "Tower", "Cannon", "Visor", { "Star", "Wings" }, "white", "navy", "ice"))
S("GenesisCore", "Genesis Core", "Celestial", "Box", 20, 8.0, "Where every robot in the yard began.", D("Hover", "Sphere", "Tentacle", "Cyclops", { "Halo", "Crystals", "Star" }, "white", "void", "gold", { bodySize = { 3.4, 3.4, 3.4 } }))

Catalog.List = list
Catalog.Total = #list

function Catalog.find(id: string): Species?
    return byId[id]
end
function Catalog.get(id: string): Species
    return assert(byId[id], "Unknown robot species: " .. tostring(id))
end
function Catalog.pool(rarity: string, source: string): {Species}
    local out = {}
    for _, s in list do if s.Rarity == rarity and s.Source == source then table.insert(out, s) end end
    return out
end
function Catalog.forRarity(rarity: string): {Species}
    local out = {}
    for _, s in list do if s.Rarity == rarity then table.insert(out, s) end end
    return out
end
-- Probability of this species within its own pool (shown in the Robotdex).
function Catalog.chance(id: string): number
    local species = Catalog.get(id)
    local total = 0
    for _, s in Catalog.pool(species.Rarity, species.Source) do total += s.Weight end
    return species.Weight / total
end
function Catalog.canAcquire(rarity: string, id: string, route: string): boolean
    local species = byId[id]
    return species ~= nil and species.Rarity == rarity and species.Source == route
end
-- Income per second for a completed robot of this species.
function Catalog.income(base: number, id: string?): number
    if not id then return base end
    return math.floor(base * Catalog.get(id).Multiplier + 0.5)
end
function Catalog.name(id: string): string
    return Catalog.get(id).Name
end
function Catalog.label(id: string): string
    local s = Catalog.get(id)
    return string.format("#%03d %s", s.Number, s.Name)
end
-- Weighted roll within a rarity's Build or Box pool. `exclude` avoids an
-- immediate repeat (used by world boxes), if the pool has alternatives.
function Catalog.roll(unit: number, rarity: string, source: string, exclude: string?): string
    assert(unit >= 0 and unit < 1, "Valid random sample required")
    local pool = Catalog.pool(rarity, source)
    assert(#pool > 0, "No " .. source .. " robots for " .. rarity)
    local total = 0
    for _, s in pool do if s.Id ~= exclude or #pool == 1 then total += s.Weight end end
    local sample = unit * total
    for _, s in pool do
        if s.Id == exclude and #pool > 1 then continue end
        sample -= s.Weight
        if sample < 0 then return s.Id end
    end
    return pool[#pool].Id
end
return Catalog
