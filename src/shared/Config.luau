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
    Items = {
        { id = "gear", name = "Kugghjul", rarity = "Common", weight = 10, color = { 165, 180, 195 }, shape = "Cylinder" },
        { id = "motor", name = "Skrotmotor", rarity = "Uncommon", weight = 60, color = { 70, 215, 150 }, shape = "Block" },
        { id = "core", name = "Robotkärna", rarity = "Rare", weight = 150, color = { 85, 155, 255 }, shape = "Ball" },
    },
})
