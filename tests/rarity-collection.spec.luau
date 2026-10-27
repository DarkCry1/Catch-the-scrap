--!strict
local Style=require("../src/shared/RarityStyle")
local Frame=require("../src/shared/RarityFrame")
local Catalog=require("../src/shared/RobotCatalog")
local Economy=require("../src/shared/Economy")
local Config=require("../src/shared/Config")
local checks=0
local function check(ok:boolean,message:string) checks+=1;assert(ok,message) end
check(#Catalog.List==10,"ten chassis for every rarity")
local account=Economy.new()
local rank,duration=0,0
for _,tier in Config.Stages do
    local style=Style.get(tier.Rarity)
    check(style.Rank>rank and style.Duration>duration,"higher tiers have progressively richer opening profiles")
    rank,duration=style.Rank,style.Duration
    check(Config.Robot.Recipes[tier.Rarity].Color==style.Color,"one authoritative rarity color")
    local buildOnly,boxOnly,both=0,0,0
    for _,v in Catalog.List do
        local source=Catalog.source(tier.Rarity,v.Id)
        if source=="Build" then buildOnly+=1 elseif source=="Box" then boxOnly+=1 else both+=1 end
        local key=Style.key(tier.Rarity,v.Id)
        check(not account.unlocked[key],"discovery starts locked")
        local index:number
        if Catalog.canAcquire(tier.Rarity,v.Id,"Build") then
            check(Economy.select(account,tier.Rarity,v.Id,Config.Robot),"legal blueprint can be selected before discovery")
            for n=1,Config.Robot.Recipes[tier.Rarity].Parts do
                local ok,complete,slot=Economy.addPart(account,tier.Rarity,Config.Robot)
                check(ok and complete==(n==Config.Robot.Recipes[tier.Rarity].Parts),"exact matching-part recipe retained")
                index=slot
                if n<Config.Robot.Recipes[tier.Rarity].Parts then check(not account.unlocked[key],"partial construction cannot grant discovery") end
            end
        else
            check(not Economy.select(account,tier.Rarity,v.Id,Config.Robot),"box-only chassis cannot be forged through blueprint selection")
            local slot=Economy.reserveRobot(account,tier.Rarity,Config.Robot,0,v.Id)
            check(slot~=nil and not account.unlocked[key],"boxed discovery waits for server completion")
            index=slot or 0;Economy.finishRecovery(account,index,Config.Robot)
        end
        check(account.unlocked[key]==true,"completion discovers this exact rarity/chassis")
        local project=account.projects[index]
        check(project.variant==v.Id,"selected or boxed variant retained in production")
        check(Economy.retire(account,project.id),"finished chassis can be retired to free a slot")
        check(account.unlocked[key]==true and #account.projects==0,"retirement keeps discovery and never strands slots")
        check(not Economy.retire(account,project.id),"stale retirement id cannot remove another robot")
        if source=="Build" then
            check(Economy.reserveRobot(account,tier.Rarity,Config.Robot,0,v.Id)==nil,"build-only chassis cannot be awarded from boxes")
        end
    end
    if style.Rank>=3 then check(buildOnly==4 and boxOnly==4 and both==2,"Rare and above have four build-only, four box-only and two shared chassis")
    else check(buildOnly==10,"low tiers remain entirely reachable through building") end
end
local found=0;for _ in account.unlocked do found+=1 end
check(found==70,"all seventy collection entries can be legitimately acquired")
local projectAccount=Economy.new()
Economy.addPart(projectAccount,"Rare",Config.Robot)
local id=projectAccount.projects[1].id
Economy.select(projectAccount,"Rare","Driller",Config.Robot)
for _=1,9 do Economy.addPart(projectAccount,"Rare",Config.Robot) end
check(projectAccount.projects[1].variant=="Bastion","selection cannot transmute an existing partial build")
check(Economy.retire(projectAccount,id),"completed old chassis can be retired")
Economy.addPart(projectAccount,"Rare",Config.Robot)
check(projectAccount.projects[1].variant=="Driller" and projectAccount.projects[1].id~=id,"next build uses the selected blueprint and a fresh id")
check(not Economy.retire(projectAccount,projectAccount.projects[1].id),"unfinished robots cannot be retired")
for n=0,999 do
    local chosen=Catalog.roll(n/1000,nil,"Rare")
    check(Catalog.canAcquire("Rare",chosen,"Box"),"every random box draw honors acquisition exclusivity")
end
local frame=Frame.build()
check(#frame==20,"celestial border is a bounded segmented perimeter")
for i,edge in frame do
    check(edge.phase==(i-1)/20,"rainbow phases advance continuously along the frame")
    local color=Style.rgb("Celestial",1,edge.phase)
    for _,channel in color do check(channel>=0 and channel<=255,"rainbow values are finite RGB colors") end
end
local a,b=Style.rgb("Celestial",0,0),Style.rgb("Celestial",2,0)
check(a[1]~=b[1] or a[2]~=b[2] or a[3]~=b[3],"rainbow travels over time")
check(Style.rgb("Epic",99,0)==Style.get("Epic").Color and Style.get("Epic").Color[3]>Style.get("Epic").Color[2],"Epic stays purple")
check(Style.get("Legendary").Color[1]>240 and Style.get("Legendary").Color[2]>150,"Legendary stays gold")
print(string.format("Rarity/source restrictions/seventy discoveries passed %d assertions",checks))
