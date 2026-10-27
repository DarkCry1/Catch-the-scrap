--!strict
local Config=require("./Config")
local Model={}
function Model.money(value:number): string
    if value>=1000000000 then return string.format("$%.1fB",value/1000000000) end
    if value>=1000000 then return string.format("$%.1fM",value/1000000) end
    if value>=10000 then return string.format("$%.1fK",value/1000) end
    return "$"..math.floor(value)
end
function Model.context(ready:boolean,base:number,name:string,kind:string,rarity:string,used:number,progress:{[string]:number},zone:number): (string,string,number)
    if not ready then return "Opening the scrapyard...","",0 end
    if base==0 then return "No workshop available","Join a server with a free workshop.",0 end
    if name~="" then return name,string.format("Deliver to Base %02d",base),1 end
    local tier=Config.Stages[math.clamp(zone,1,#Config.Stages)].Rarity
    if used>=Config.Robot.Slots then
        for _,stage in Config.Stages do if (progress[stage.Rarity] or 0)>0 then tier=stage.Rarity;break end end
        if (progress[tier] or 0)==0 then return "Your workshop is full","Your robots are earning cash.",1 end
    end
    local recipe=Config.Robot.Recipes[tier]
    local count=progress[tier] or 0
    return string.format("%s robot  %d / %d",tier,count,recipe.Parts),"Collect matching scrap in this area.",count/recipe.Parts
end
return Model
