--!strict
-- Prototype values: adjust after Studio playtests, not final game balance.
local recipes: {[string]: { Parts: number, Income: number, Name: string, Color: {number} }} = {
            Common = { Parts = 5, Income = 5, Name = "Common Scrap Bot", Color = { 255, 181, 61 } },
            Uncommon = { Parts = 7, Income = 10, Name = "Uncommon Scrap Bot", Color = { 80, 215, 145 } },
            Rare = { Parts = 10, Income = 20, Name = "Rare Scrap Bot", Color = { 90, 160, 255 } },
            Epic = { Parts = 12, Income = 45, Name = "Epic Turbine Bot", Color = { 183, 110, 255 } },
            Legendary = { Parts = 15, Income = 100, Name = "Legendary Fusion Bot", Color = { 255, 199, 65 } },
            Mythic = { Parts = 18, Income = 225, Name = "Mythic Singularity Bot", Color = { 255, 90, 138 } },
            Celestial = { Parts = 20, Income = 500, Name = "Celestial Starforge Bot", Color = { 105, 245, 255 } },
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
    Crates = { OpenSeconds = 3.8, RespawnSeconds = 35, PerStage = 2 },
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
    Visuals = { EffectDistance = 160, EffectInterval = 0.4, YardPartBudget = 3800, PickupDistance = 110, PickupInterval = 0.2, PickupPartBudget = 64 },
    InteractionDistance = 12,
    ActionCooldown = 0.2,
    RespawnSeconds = 8,
    TrackWidth = 160,
    ZoneLength = 480,
    TrackStart = 20,
    BaseCount = 8,
    Robot = {
        Slots = 4,
        Recipes = recipes,
    },
    Palette = {
        dark = { 27, 38, 51 }, floor = { 62, 75, 84 }, wall = { 72, 91, 104 },
        steel = { 118, 140, 151 }, amber = { 255, 181, 61 }, energy = { 90, 240, 217 },
        copper = { 173, 105, 61 }, black = { 12, 20, 29 }, rust = { 138, 77, 49 }, rubber = { 29, 33, 34 },
    },
    BaseAccents = { { 78, 222, 205 }, { 110, 169, 255 }, { 241, 157, 82 }, { 185, 150, 255 } },
    Items = {
        { id = "gear", name = "Common Gear", rarity = "Common", weight = 10, color = { 165, 180, 195 }, shape = "Cylinder" },
        { id = "motor", name = "Uncommon Motor", rarity = "Uncommon", weight = 35, color = { 70, 215, 150 }, shape = "Block" },
        { id = "core", name = "Rare Core", rarity = "Rare", weight = 65, color = recipes.Rare.Color, shape = "Ball" },
        { id = "turbine", name = "Epic Turbine", rarity = "Epic", weight = 85, color = recipes.Epic.Color, shape = "Cylinder" },
        { id = "fusion", name = "Legendary Fusion Cell", rarity = "Legendary", weight = 110, color = recipes.Legendary.Color, shape = "Cylinder" },
        { id = "singularity", name = "Mythic Singularity", rarity = "Mythic", weight = 140, color = recipes.Mythic.Color, shape = "Ball" },
        { id = "starforge", name = "Celestial Star Engine", rarity = "Celestial", weight = 180, color = recipes.Celestial.Color, shape = "Ball" },
    },
})
