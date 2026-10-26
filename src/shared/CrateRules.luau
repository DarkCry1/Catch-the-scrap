--!strict
local Config=require("./Config")
local Rules={}
-- A fixed result is drawn once on the server at spawn; carrying/dropping never rerolls it.
function Rules.roll(stage:number,unit:number): string
    assert(stage%1==0 and stage>=1 and stage<=#Config.Stages,"Valid crate district required")
    assert(unit>=0 and unit<1,"Random sample must be in [0,1)")
    local offset=if unit<.7 then 0 elseif unit<.9 then -1 elseif unit<.99 then 1 else 2
    return Config.Stages[math.clamp(stage+offset,1,#Config.Stages)].Rarity
end
function Rules.definition(stage:number)
    assert(Config.Stages[stage],"Valid crate district required")
    return {id="robot-box",name="Sealed Robot Box",rarity="Mystery",kind="RobotCrate",weight=20+stage*12,color={225,182,113},shape="Block"}
end
return Rules
