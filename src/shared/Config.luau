--!strict
local RarityStyle=require("./RarityStyle")
-- Prototype values: adjust after Studio playtests, not final game balance.
local recipes: {[string]: { Parts: number, Income: number, Name: string, Color: {number} }} = {
            Common = { Parts = 5, Income = 5, Name = "Common Scrap Bot", Color = RarityStyle.get("Common").Color },
            Uncommon = { Parts = 7, Income = 10, Name = "Uncommon Scrap Bot", Color = RarityStyle.get("Uncommon").Color },
            Rare = { Parts = 10, Income = 20, Name = "Rare Scrap Bot", Color = RarityStyle.get("Rare").Color },
            Epic = { Parts = 12, Income = 45, Name = "Epic Turbine Bot", Color = RarityStyle.get("Epic").Color },
            Legendary = { Parts = 15, Income = 100, Name = "Legendary Fusion Bot", Color = RarityStyle.get("Legendary").Color },
            Mythic = { Parts = 18, Income = 225, Name = "Mythic Singularity Bot", Color = RarityStyle.get("Mythic").Color },
            Celestial = { Parts = 20, Income = 500, Name = "Celestial Starforge Bot", Color = RarityStyle.get("Celestial").Color },
        }

local upgrades: {[string]: { Label: string, Description: string, BaseCost: number, CostMultiplier: number, PerLevel: number, MaxLevel: number }} = {
    Speed = { Label = "Speed", Description = "Run faster, even while carrying.", BaseCost = 75, CostMultiplier = 1.6, PerLevel = 2, MaxLevel = 10 },
    Strength = { Label = "Strength", Description = "Carry heavy parts faster.", BaseCost = 100, CostMultiplier = 1.65, PerLevel = 10, MaxLevel = 10 },
}

return table.freeze({
    Stages = {
        { Rarity = "Common", Name = "Sorting Yard", Color = recipes.Common.Color },
        { Rarity = "Uncommon", Name = "Machine Graveyard", Color = recipes.Uncommon.Color },
        { Rarity = "Rare", Name = "Reactor Wrecks", Color = recipes.Rare.Color },
        { Rarity = "Epic", Name = "Turbine Foundry", Color = recipes.Epic.Color },
        { Rarity = "Legendary", Name = "Golden Furnace", Color = recipes.Legendary.Color },
        { Rarity = "Mythic", Name = "Void Salvage", Color = recipes.Mythic.Color },
        { Rarity = "Celestial", Name = "Starforge Ruins", Color = recipes.Celestial.Color },
    },
    Crates = { OpenSeconds = 5.6, FirstDelay = 60, SpawnMin = 240, SpawnMax = 420, GroundLifetime = 180, LiveLimit = 2, PerStage = 2 },
    Presentation = { Distance = 140, CrushSeconds = 1.6, MaxDebris = 18 },
    WallHeight = 64,
    Camera = { MaxZoom = 32, EdgeInset = 2, NearPlanePadding = 1.5 },
    Upgrades = upgrades,
    UpgradeDistance = 12,
    UpgradeCooldown = 0.35,
    BaseSpeed = 24,
    Strength = 30,
    MinimumSpeed = 7,
    PickupClearance = 2.2,
    Visuals = { EffectDistance = 160, EffectInterval = 0.4, YardPartBudget = 3800, PickupDistance = 110, PickupInterval = 0.2, PickupPartBudget = 84, CratePartBudget = 112, CinematicBudget = 3 },
    InteractionDistance = 12,
    ActionCooldown = 0.2,
    RespawnSeconds = 8,
    TrackWidth = 160,
    ZoneLength = 480,
    TrackStart = 20,
    BaseCount = 8,
    -- DataStore progress (v1.2). LockSeconds must exceed AutosaveSeconds.
    Save = { Store = "CatchTheScrap_Progress_v1", LockSeconds = 90, RetrySeconds = 4, ErrorRetries = 3, AutosaveSeconds = 45 },
    -- Inner faces of the plaza walls (the home street and workshops).
    Plaza = { HalfWidth = 102, BackZ = -318 },
    -- Workshop footprint in its own frame: Width runs along the street, Depth
    -- from the street-facing gate to the back wall. Rows alternate sides.
    Workshops = { Width = 68, Depth = 66, CenterX = 67, FirstZ = -44, Spacing = 76, PadDiameter = 14 },
    -- v1.3: each rebirth resets cash, robots and upgrades (the Robotdex stays),
    -- adds IncomeBonus to the income multiplier and unlocks one extra platform
    -- (up to Robot.MaxSlots). Cost = BaseCost * Growth ^ rebirths.
    Rebirth = { BaseCost = 250000, Growth = 4, IncomeBonus = 0.5, Max = 12 },
    -- Mutations are rolled independently of the species (builds and boxes).
    Mutations = {
        { Id = "Gold", Label = "Gold", Chance = 0.05, Multiplier = 2, Color = { 255, 198, 64 } },
        { Id = "Rainbow", Label = "Rainbow", Chance = 0.01, Multiplier = 4, Color = { 126, 234, 255 } },
    },
    -- Daily quests: three per player per UTC day.
    Quests = { PerDay = 3, CashReward = { 1500, 4000, 10000 }, BonusBox = "Rare" },
    -- Sound design (client). Every cue is built from Roblox's built-in sounds;
    -- put an uploaded or Creator Store sound here ("rbxassetid://123") to
    -- replace any cue, e.g. Overrides = { Click = "rbxassetid://123" }.
    Audio = { Master = 0.8, IncomeTickSeconds = 2.5, Overrides = {} :: {[string]: string} },
    -- One original walking guardian per district. Provisional playtest values,
    -- not measured values from any other Roblox experience.
    Guardians = {
        Step = 0.05, RepathSeconds = 0.7, CooldownSeconds = 8, Grid = 8,
        Profiles = {
            { Name = "Rustyard Watcher", Scale = 0.95, PatrolSpeed = 6, ChaseSpeed = 15, DetectRange = 48, WarningSeconds = 1.4, ChaseSeconds = 7 },
            { Name = "Scrap Bruiser", Scale = 1.10, PatrolSpeed = 7, ChaseSpeed = 17, DetectRange = 54, WarningSeconds = 1.3, ChaseSeconds = 7.5 },
            { Name = "Core Warden", Scale = 1.25, PatrolSpeed = 8, ChaseSpeed = 19, DetectRange = 60, WarningSeconds = 1.2, ChaseSeconds = 8 },
            { Name = "Turbine Enforcer", Scale = 1.40, PatrolSpeed = 9, ChaseSpeed = 22, DetectRange = 68, WarningSeconds = 1.1, ChaseSeconds = 8.5 },
            { Name = "Gilded Colossus", Scale = 1.60, PatrolSpeed = 10, ChaseSpeed = 25, DetectRange = 76, WarningSeconds = 1.0, ChaseSeconds = 9 },
            { Name = "Void Reaper", Scale = 1.80, PatrolSpeed = 11, ChaseSpeed = 28, DetectRange = 84, WarningSeconds = 0.9, ChaseSeconds = 9.5 },
            { Name = "Astral Sentinel", Scale = 2.00, PatrolSpeed = 12, ChaseSpeed = 31, DetectRange = 92, WarningSeconds = 0.8, ChaseSeconds = 10 },
        },
    },
    Robot = {
        Slots = 6,
        MaxSlots = 8,
        Recipes = recipes,
    },
    Palette = {
        dark = { 27, 38, 51 }, floor = { 62, 75, 84 }, wall = { 72, 91, 104 },
        steel = { 118, 140, 151 }, amber = { 255, 181, 61 }, energy = { 90, 240, 217 },
        copper = { 173, 105, 61 }, black = { 12, 20, 29 }, rust = { 138, 77, 49 }, rubber = { 29, 33, 34 },
        -- Robot body colors (v1.2 Robotdex species)
        olive = { 98, 110, 64 }, navy = { 42, 62, 102 }, bone = { 214, 206, 184 }, crimson = { 156, 42, 50 },
        teal = { 40, 128, 128 }, graphite = { 58, 61, 68 }, sand = { 186, 158, 108 }, white = { 222, 228, 234 },
        gold = { 214, 168, 58 }, ice = { 150, 206, 228 }, void = { 40, 22, 58 }, violet = { 112, 66, 168 },
    },
    BaseAccents = { { 78, 222, 205 }, { 110, 169, 255 }, { 241, 157, 82 }, { 185, 150, 255 } },
    Items = {
        { id = "gear", name = "Common Gear", rarity = "Common", weight = 10, color = recipes.Common.Color, shape = "Cylinder" },
        { id = "motor", name = "Uncommon Motor", rarity = "Uncommon", weight = 35, color = recipes.Uncommon.Color, shape = "Block" },
        { id = "core", name = "Rare Core", rarity = "Rare", weight = 65, color = recipes.Rare.Color, shape = "Ball" },
        { id = "turbine", name = "Epic Turbine", rarity = "Epic", weight = 85, color = recipes.Epic.Color, shape = "Cylinder" },
        { id = "fusion", name = "Legendary Fusion Cell", rarity = "Legendary", weight = 110, color = recipes.Legendary.Color, shape = "Cylinder" },
        { id = "singularity", name = "Mythic Singularity", rarity = "Mythic", weight = 140, color = recipes.Mythic.Color, shape = "Ball" },
        { id = "starforge", name = "Celestial Star Engine", rarity = "Celestial", weight = 180, color = recipes.Celestial.Color, shape = "Ball" },
    },
})
