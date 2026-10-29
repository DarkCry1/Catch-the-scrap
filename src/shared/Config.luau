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
    -- Order = how they are listed (most common first). Every species can be
    -- collected in every version. Body = plate color, Accent = every Nth part
    -- becomes glowing neon (0 = none), Pattern "Spectrum" = animated rainbow.
    Mutations = {
        { Id = "Gold", Label = "Gold", Chance = 0.05, Multiplier = 2, Color = { 255, 198, 64 },
            Body = { 255, 198, 64 }, Material = "Metal", Reflectance = 0.28, Transparency = 0, Accent = { 255, 236, 150 }, Accent2 = { 255, 236, 150 }, AccentEvery = 0, Pattern = "Solid", Sparkles = 6 },
        { Id = "Diamond", Label = "Diamond", Chance = 0.025, Multiplier = 3, Color = { 140, 226, 255 },
            Body = { 190, 240, 255 }, Material = "Glass", Reflectance = 0.35, Transparency = 0.1, Accent = { 255, 255, 255 }, Accent2 = { 160, 230, 255 }, AccentEvery = 4, Pattern = "Solid", Sparkles = 9 },
        { Id = "Rainbow", Label = "Rainbow", Chance = 0.01, Multiplier = 4, Color = { 255, 110, 220 },
            Body = { 255, 110, 220 }, Material = "SmoothPlastic", Reflectance = 0.1, Transparency = 0, Accent = { 255, 255, 255 }, Accent2 = { 255, 255, 255 }, AccentEvery = 0, Pattern = "Spectrum", Sparkles = 10 },
        { Id = "Lava", Label = "Lava", Chance = 0.006, Multiplier = 5, Color = { 255, 104, 36 },
            Body = { 66, 36, 28 }, Material = "Basalt", Reflectance = 0, Transparency = 0, Accent = { 255, 104, 28 }, Accent2 = { 255, 196, 60 }, AccentEvery = 2, Pattern = "Solid", Sparkles = 12 },
        { Id = "Galaxy", Label = "Galaxy", Chance = 0.0025, Multiplier = 8, Color = { 168, 112, 255 },
            Body = { 72, 40, 150 }, Material = "SmoothPlastic", Reflectance = 0.25, Transparency = 0, Accent = { 110, 220, 255 }, Accent2 = { 255, 110, 220 }, AccentEvery = 3, Pattern = "Solid", Sparkles = 16 },
    },
    -- Daily quests: three per player per UTC day.
    Quests = { PerDay = 3, CashReward = { 1500, 4000, 10000 }, BonusBox = "Rare" },
    -- Sound design (client). Every cue is built from Roblox's built-in sounds;
    -- put an uploaded or Creator Store sound here ("rbxassetid://123") to
    -- replace any cue, e.g. Overrides = { Click = "rbxassetid://123" }.
    -- v1.7 guard robots: hover security bots in every stage. Stealing scrap or
    -- a robot box there alerts every idle guard within AlertRange; after
    -- Reaction seconds they chase at that stage's Speed. Speeds are tuned so
    -- each stage needs Speed + Strength upgrades (about level 0, 2, 4, 5, 7, 8
    -- and 10) to outrun them while carrying that stage's scrap.
    Guards = {
        Count = { 3, 3, 4, 4, 5, 5, 6 },
        Speed = { 17, 20.5, 22, 22.5, 24.5, 24.5, 25.5 },
        AlertRange = 190, Reaction = 0.8, CatchRange = 4.2, MaxChase = 22, Leash = 14,
        Cooldown = 3.5, StunSeconds = 1.3, StunSpeed = 5, IdleWander = 14, HipHeight = 2.6,
        -- v1.8: guards are giants and grow stage by stage (model scale; a
        -- player is about 5 studs tall, a stage 1 guard about 14, stage 7 about 21).
        Scale = { 2, 2.15, 2.3, 2.45, 2.6, 2.8, 3 },
        -- v1.9: stage 1 guards only warn players who have not finished the guide.
        GraceStage = 1,
    },
    -- Glowing mutation auras around robots (client-side, cosmetic).
    -- MaxHighlights: nearest robots that get the full-body glow (Roblox limit 31).
    Auras = { Enabled = true, Distance = 170, MaxHighlights = 24 },
    -- Overrides: replace a cue with an uploaded / Creator Store sound, e.g.
    -- Overrides = { Click = "rbxassetid://123", Claim = "rbxassetid://456" },
    -- OverrideVolume = { Click = 0.5 }. Cue names: Click, Open, Close, Deny,
    -- ClaimPress, Claim, Pickup, Deposit, Built, BuiltNew, Gold, Diamond,
    -- Rainbow, Lava, Galaxy, Discover, Alarm, Catch, Escape, Guide, Rebirth,
    -- GuardAlert, Zap, Stomp.
    Audio = { Master = 0.8, Overrides = {} :: {[string]: string}, OverrideVolume = {} :: {[string]: number} },
    -- Original background loop. Upload the supplied audio, then set the ID on
    -- SoundService.ScrapyardMusic (or override it here). M mutes all game audio.
    Music = { Enabled = true, SoundId = "", Volume = 0.32, DuckChase = 0.35, DuckCinematic = 0.45, FadeInSeconds = 3, FadeSeconds = 0.5 },
    -- Security drones patrol Epic and higher zones and chase players carrying loot.
    Drones = {
        Stages = { [4] = 2, [5] = 2, [6] = 3, [7] = 3 },
        ChaseSpeed = { [4] = 12.5, [5] = 13.5, [6] = 14.5, [7] = 15.5 },
        PatrolSpeed = 9, Height = 16, DetectRange = 38, CatchRange = 4.5,
        ChaseSeconds = 7, CooldownSeconds = 9, BaseSafeRadius = 0,
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
