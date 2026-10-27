--!strict
local Config=require("./Config")
local Rules={}
function Rules.roll(unit:number): string
    assert(unit>=0 and unit<1,"Random sample must be in [0,1)")
    -- v1.2: 68 / 22 / 7 / 2.5 / 0.5 percent (Robotdex box pages must be completable).
    return if unit<.68 then "Rare" elseif unit<.90 then "Epic" elseif unit<.97 then "Legendary" elseif unit<.995 then "Mythic" else "Celestial"
end
function Rules.definition(rarity:string)
    local recipe=Config.Robot.Recipes[rarity]
    assert(recipe and rarity~="Common" and rarity~="Uncommon","Event crates are at least Rare")
    return {id="robot-box",name=rarity.." Robot Box",rarity=rarity,kind="RobotCrate",weight=65,color=recipe.Color,shape="Block"}
end
return Rules
