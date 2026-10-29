--!strict
local Rules={}
function Rules.allowed(userId:number,isStudio:boolean,allowStudio:boolean,isPersonalOwner:boolean,ids:{number}): boolean
    if isStudio and allowStudio then return true end
    if userId>0 and isPersonalOwner then return true end
    for _,id in ids do if id==userId then return true end end
    return false
end
local function integer(value:any,minimum:number,maximum:number): boolean
    return type(value)=="number" and value>=minimum and value<=maximum and value%1==0
end
function Rules.validate(command:any,value:any): boolean
    if command=="SetCash" or command=="AddCash" then return integer(value,0,1000000000) end
    if command=="SetSpeed" then return integer(value,7,120) end
    if command=="SetStrength" then return integer(value,1,10000) end
    if command=="ResetStats" or command=="Home" or command=="ResetProgress" then return value==0 end
    if command=="DexFill" then return integer(value,0,1000) end
    if command=="MutateRobots" then return integer(value,0,16) end
    if command=="Event" and type(value)=="table" then
        local tier=value.rarity
        return (tier=="Rare" or tier=="Epic" or tier=="Legendary" or tier=="Mythic" or tier=="Celestial") and integer(value.stage,1,7)
    end
    return false
end
return Rules
