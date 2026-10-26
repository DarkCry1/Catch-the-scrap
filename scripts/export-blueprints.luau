--!nonstrict
-- Used by the optional Blender preview; the game loads these same blueprints.
local function json(value)
    if type(value) == "table" then
        local entries = {}
        if #value > 0 then
            for _, item in value do table.insert(entries, json(item)) end
            return "[" .. table.concat(entries, ",") .. "]"
        end
        for key, item in value do table.insert(entries, string.format("%q", key) .. ":" .. json(item)) end
        return "{" .. table.concat(entries, ",") .. "}"
    elseif type(value) == "string" then return string.format("%q", value)
    else return tostring(value) end
end
local Config = require("../src/shared/Config")
local PickupBlueprint=require("../src/shared/PickupBlueprint")
local pickupVisuals={}
for _,item in Config.Items do
    pickupVisuals[item.rarity]={parts=PickupBlueprint.build(item.rarity,item.color),clearance=PickupBlueprint.clearance(item.rarity,item.color)}
end
print(json({
    pickupVisuals=pickupVisuals,
    mechanic = require("../src/shared/MechanicBlueprint"),
    base = require("../src/shared/BaseBlueprint"),
    robot = require("../src/shared/RobotBlueprint"),
    palette = Config.Palette,
    accent = Config.BaseAccents[1],
    yard = require("../src/shared/ScrapyardBlueprint").build(Config.TrackWidth,Config.ZoneLength,Config.TrackStart),
    items = Config.Items,
    navigation = require("../src/shared/Navigation").chevron(0,0,1),
}))
