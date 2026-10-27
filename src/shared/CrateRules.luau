--!strict
local Config=require("./Config")
local Rules={}
function Rules.roll(unit:number): string
    assert(unit>=0 and unit<1,"Random sample must be in [0,1)")
    return if unit<.7 then "Rare" elseif unit<.92 then "Epic" elseif unit<.98 then "Legendary" elseif unit<.998 then "Mythic" else "Celestial"
end
function Rules.definition(rarity:string)
    local recipe=Config.Robot.Recipes[rarity]
    assert(recipe and rarity~="Common" and rarity~="Uncommon","Event crates are at least Rare")
    return {id="robot-box",name=rarity.." Robot Box",rarity=rarity,kind="RobotCrate",weight=65,color=recipe.Color,shape="Block"}
end
return Rules
