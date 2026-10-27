--!strict
-- Regression coverage for the uploaded v1.4 systems retained by the guardian release.
local Config=require("../src/shared/Config")
local Catalog=require("../src/shared/RobotCatalog")
local Economy=require("../src/shared/Economy")
local Mutations=require("../src/shared/Mutations")
local Rebirth=require("../src/shared/RebirthRules")
local Quests=require("../src/shared/QuestRules")
local Schema=require("../src/shared/SaveSchema")
local Variants=require("../src/shared/RobotVariants")
local Rewards=require("../src/shared/DexRewards")
local n=0
local function check(ok:boolean,message:string) n+=1;assert(ok,message) end
check(#Catalog.List==61,"uploaded 61-species Robotdex retained")
check(Config.Robot.Slots==6 and Config.Robot.MaxSlots==8,"six initial and eight maximum platforms retained")
local all=Economy.new()
for _,stage in Config.Stages do
    for _,route in {"Build","Box"} do
        local pool=Catalog.pool(stage.Rarity,route)
        local total=0;for _,species in pool do total+=species.Weight end
        local edge=0
        for _,species in pool do
            local sample=(edge+species.Weight/2)/total;edge+=species.Weight
            local id=Catalog.roll(sample,stage.Rarity,route)
            check(id==species.Id,"weighted source pool reaches every species")
            check(Catalog.canAcquire(stage.Rarity,id,route),"result matches exact rarity and source")
            local account=Economy.new()
            if route=="Build" then
                for part=1,Config.Robot.Recipes[stage.Rarity].Parts do
                    local accepted,complete=Economy.addPart(account,stage.Rarity,Config.Robot,sample,.9)
                    check(accepted and complete==(part==Config.Robot.Recipes[stage.Rarity].Parts),"matching parts build only at recipe threshold")
                end
            else
                local slot=Economy.reserveRobot(account,stage.Rarity,Config.Robot,0,id,"Gold")
                check(slot~=nil and Economy.incomePerSecond(account,Config.Robot)==0,"box reserves without early income")
                check(Economy.finishRecovery(account,slot :: number,Config.Robot),"reserved box completes")
                check(not Economy.finishRecovery(account,slot :: number,Config.Robot),"reveal cannot award twice")
            end
            check(account.projects[1].variant==id and account.dex[id]==1,"actual result registered exactly once")
            local before=Economy.incomePerSecond(account,Config.Robot)
            local loaded=Schema.deserialize(Schema.serialize(account))
            check(loaded.dex[id]==1 and Economy.incomePerSecond(loaded,Config.Robot)==before,"saved robot and income round-trip")
            local geometry=Variants.build(id)
            check(#geometry>10 and #geometry<250,"all imported robot models remain buildable")
            for _,p in geometry do check((Config.Palette :: any)[p.palette]~=nil,"every species has valid colors") end
            Economy.record(all,id,nil)
        end
    end
end
check(Economy.discovered(all)==61,"all sixty-one species remain legitimately reachable")
check(Mutations.roll(0)=="Rainbow" and Mutations.roll(.02)=="Gold" and Mutations.roll(.9)==nil,"mutation odds retained")
check(Mutations.multiplier("Gold")==2 and Mutations.multiplier("Rainbow")==4,"mutation payouts retained")
for rebirths=0,4 do
    local account=Schema.deserialize(Schema.serialize(all));account.rebirths=rebirths;account.cash=Rebirth.cost(rebirths)
    account.upgrades.Speed=3;account.upgrades.Strength=2
    check(Rebirth.apply(account),"eligible rebirth succeeds")
    check(account.cash==0 and #account.projects==0 and account.upgrades.Speed==0,"rebirth resets workshop and spending")
    check(Economy.discovered(account)==61,"rebirth preserves Robotdex")
    check(Economy.slots(account,Config.Robot)==math.min(8,7+rebirths),"rebirth unlocks platforms through eight")
end
local a=Economy.new();a.cash=1000;a.rebirths=2;a.tutorial=4;a.quests=Quests.fresh(20000)
local quests=Quests.quests(20000,11824623188,2)
check(#quests==3,"three daily quests retained")
for i,q in quests do
    check(q.id==Quests.quests(20000,11824623188,2)[i].id,"daily quests stable across servers")
    check(Quests.advance(a.quests :: Quests.State,quests,q.event,q.target),"quest progresses from matching event")
end
local loaded=Schema.deserialize(Schema.serialize(a))
check(loaded.cash==1000 and loaded.rebirths==2 and loaded.tutorial==4,"save retains progression")
check(loaded.quests~=nil and (loaded.quests :: Quests.State).day==20000,"quest day retained")
check(#Rewards.List>10,"collection reward milestones retained")
local bad=Schema.deserialize({cash=0/0,rebirths=math.huge,projects={{r="Fake",c=true}},dex={Fake=100000},perks={income=1000000}})
check(bad.cash==0 and bad.rebirths==0 and #bad.projects==0 and Economy.discovered(bad)==0 and bad.perks.income==0,"malformed data cannot grant progress")
print("Imported Robotdex, economy, mutations, rebirth, quests and save schema passed "..n.." assertions")
