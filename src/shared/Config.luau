--!strict
-- Prototype values: adjust after Studio playtests, not final game balance.
local recipes: {[string]: { Parts: number, Income: number, Name: string, Color: {number} }} = {
            Common = { Parts = 5, Income = 5, Name = "Common Scrap Bot", Color = { 255, 181, 61 } },
            Uncommon = { Parts = 7, Income = 10, Name = "Uncommon Scrap Bot", Color = { 80, 215, 145 } },
            Rare = { Parts = 10, Income = 20, Name = "Rare Scrap Bot", Color = { 90, 160, 255 } },
        }

local upgrades: {[string]: { Label: string, Description: string, BaseCost: number, CostMultiplier: number, PerLevel: number, MaxLevel: number }} = {
    Speed = { Label = "Speed", Description = "Run faster, even while carrying.", BaseCost = 75, CostMultiplier = 1.6, PerLevel = 2, MaxLevel = 10 },
    Strength = { Label = "Strength", Description = "Carry heavy parts faster.", BaseCost = 100, CostMultiplier = 1.65, PerLevel = 10, MaxLevel = 10 },
}

return table.freeze({
    Upgrades = upgrades,
    UpgradeDistance = 12,
    UpgradeCooldown = 0.35,
    BaseSpeed = 24,
    Strength = 30,
    MinimumSpeed = 7,
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
        copper = { 181, 108, 67 }, black = { 12, 20, 29 },
    },
    BaseAccents = { { 78, 222, 205 }, { 110, 169, 255 }, { 241, 157, 82 }, { 185, 150, 255 } },
    Items = {
        { id = "gear", name = "Common Gear", rarity = "Common", weight = 10, color = { 165, 180, 195 }, shape = "Cylinder" },
        { id = "motor", name = "Uncommon Motor", rarity = "Uncommon", weight = 35, color = { 70, 215, 150 }, shape = "Block" },
        { id = "core", name = "Rare Core", rarity = "Rare", weight = 65, color = { 85, 155, 255 }, shape = "Ball" },
    },
})
