--!strict
local Catalog=require("../../src/shared/RobotCatalog")
local Variants=require("../../src/shared/RobotVariants")
local Rules=require("../../src/shared/CrateRules")
local Economy=require("../../src/shared/Economy")
local Config=require("../../src/shared/Config")
local checks=0
local function check(ok:boolean,message:string) checks+=1;assert(ok,message) end
local fingerprints:{[string]:boolean}={}
local last=nil
for _,variant in Catalog.List do
    local geometry=Variants.build(variant.Id)
    check(#geometry>=35 and #geometry<90,"bounded complete robot detail")
    local names:{[string]:boolean}={}
    local signature={}
    for _,part in geometry do
        check(not names[part.name],"unique variant part names");names[part.name]=true
        check((Config.Palette :: any)[part.palette]~=nil,"valid native-material palette")
        local roll=math.rad(part.roll or 0)
        local halfY=math.abs(part.size[1]/2*math.sin(roll))+math.abs(part.size[2]/2*math.cos(roll))
        check(part.position[2]-halfY>=-.001,"robot clears platform")
        check(part.position[2]+halfY<9.5,"variant and reveal fit workshop canopy")
        local halfX=math.abs(part.size[1]/2*math.cos(roll))+math.abs(part.size[2]/2*math.sin(roll))
        check(math.abs(part.position[1])+halfX<6,"robot fits its 12-stud platform")
        table.insert(signature,part.name..":"..part.shape..":"..table.concat(part.size,","))
    end
    check(names.Reactor==true,"all variants retain a reveal-ready reactor")
    local stamp=table.concat(signature,";")
    check(not fingerprints[stamp],"variants have different geometry, not just different colors")
    fingerprints[stamp]=true
    local income=Catalog.income(Config.Robot.Recipes.Rare.Income,variant.Id)
    check(income>=80 and income<=200,"valuable Rare event payout")
    local account=Economy.new()
    local fromBox=Catalog.canAcquire("Rare",variant.Id,"Box")
    local index=Economy.reserveRobot(account,"Rare",Config.Robot,0,variant.Id)
    check((index~=nil)==fromBox and Economy.incomePerSecond(account,Config.Robot)==0,"variant earns nothing before reveal")
    if fromBox then Economy.finishRecovery(account,index or 0,Config.Robot) end
    check(Economy.incomePerSecond(account,Config.Robot)==(if fromBox then income else 0),"server variant payout equals displayed payout")
    last=variant.Id
end
for sample=0,999 do
    local id=Catalog.roll(sample/1000,last)
    check(id~=last,"consecutive event boxes cannot repeat the exact same variant")
    last=id
    local rarity=Rules.roll(sample/1000)
    check(rarity~="Common" and rarity~="Uncommon" and Config.Robot.Recipes[rarity]~=nil,"announced tier always at least Rare")
end
check(Catalog.income(20,nil)==20,"crafted robot income stays at its original recipe rate")
check(Config.Crates.FirstDelay==60 and Config.Crates.SpawnMin>=240 and Config.Crates.SpawnMax<=420,"rare event intervals are deliberate")
print(string.format("Distinct robot geometry/event payouts passed %d assertions",checks))
