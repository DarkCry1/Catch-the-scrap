--!strict
-- Prototype values: adjust after Studio playtests, not final game balance.
return table.freeze({
    BaseSpeed = 24,
    Strength = 30,
    MinimumSpeed = 7,
    InteractionDistance = 12,
    ActionCooldown = 0.2,
    RespawnSeconds = 8,
    TrackWidth = 44,
    ZoneLength = 120,
    TrackStart = 20,
    BaseCount = 8,
    Robot = { ScrapPerRobot = 10, Slots = 4, IncomePerRobot = 5 },
    Palette = {
        dark = { 27, 38, 51 }, floor = { 62, 75, 84 }, wall = { 72, 91, 104 },
        steel = { 118, 140, 151 }, amber = { 255, 181, 61 }, energy = { 90, 240, 217 },
        copper = { 181, 108, 67 }, black = { 12, 20, 29 },
    },
    BaseAccents = { { 78, 222, 205 }, { 110, 169, 255 }, { 241, 157, 82 }, { 185, 150, 255 } },
    Items = {
        { id = "gear", name = "Kugghjul", rarity = "Common", weight = 10, color = { 165, 180, 195 }, shape = "Cylinder" },
        { id = "motor", name = "Skrotmotor", rarity = "Uncommon", weight = 60, color = { 70, 215, 150 }, shape = "Block" },
        { id = "core", name = "Robotkärna", rarity = "Rare", weight = 150, color = { 85, 155, 255 }, shape = "Ball" },
    },
})
