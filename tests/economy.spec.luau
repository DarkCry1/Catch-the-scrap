--!strict
local Economy=require("../src/shared/Economy")
local Config=require("../src/shared/Config")
local Base=require("../src/shared/BaseBlueprint")
local Robot=require("../src/shared/RobotBlueprint")
local settings=Config.Robot
local assertions,suites=0,0
local function check(condition: boolean,message: string)
    assertions+=1;assert(condition,message)
end
local function test(name: string,run: ()->())
    run();suites+=1;print("PASS "..name)
end
local function add(account: Economy.Account,rarity: string,count: number)
    for _=1,count do check(Economy.addPart(account,rarity,settings),"part accepted") end
end

test("five Common parts build one Common robot",function()
    local account=Economy.new()
    add(account,"Common",4)
    check(Economy.robotCount(account)==0 and Economy.progress(account,"Common")==4,"four is not five")
    check(Economy.advance(account,100,settings)==0,"unfinished robots never earn")
    local ok,built,index=Economy.addPart(account,"Common",settings)
    check(ok and built and index==1,"fifth part completes the original platform")
    check(account.projects[1].rarity=="Common" and account.projects[1].parts==5,"robot retains Common provenance")
    check(Economy.incomePerSecond(account,settings)==5,"Common rate is $5/sec")
    check(Economy.advance(account,12,settings)==60,"twelve seconds earns sixty dollars")
end)

test("ten Rare parts build Rare and Common parts never substitute",function()
    local account=Economy.new()
    add(account,"Common",4);add(account,"Rare",9)
    check(Economy.robotCount(account)==0,"neither recipe is complete")
    check(Economy.progress(account,"Common")==4 and Economy.progress(account,"Rare")==9,"separate rarity progress")
    add(account,"Common",1)
    check(Economy.robotCount(account)==1 and Economy.progress(account,"Rare")==9,"Common completion does not consume Rare")
    check(Economy.incomePerSecond(account,settings)==5,"unfinished Rare adds no income")
    add(account,"Rare",1)
    check(Economy.robotCount(account)==2 and account.projects[2].rarity=="Rare","tenth Rare finishes Rare")
    check(Economy.incomePerSecond(account,settings)==25,"Common plus Rare gives $25/sec")
end)

test("Uncommon recipe and subsequent same-tier projects",function()
    local account=Economy.new()
    add(account,"Uncommon",7)
    check(Economy.robotCount(account)==1 and Economy.incomePerSecond(account,settings)==10,"seven Uncommon parts complete Uncommon")
    add(account,"Uncommon",2)
    check(#account.projects==2 and account.projects[2].parts==2,"next build owns a new platform")
    check(Economy.incomePerSecond(account,settings)==10,"partial second build adds no income")
end)

test("reserved slots prevent stranded partial builds and preserve capacity",function()
    local account=Economy.new()
    add(account,"Common",15);add(account,"Rare",1)
    check(#account.projects==4 and Economy.robotCount(account)==3,"one unfinished Rare occupies the fourth slot")
    check(not Economy.canAddPart(account,"Common",settings),"cannot take the reserved Rare slot")
    local ok,built,index=Economy.addPart(account,"Common",settings)
    check(not ok and not built and index==0,"rejected deposit does not create a project")
    check(Economy.progress(account,"Rare")==1 and #account.projects==4,"rejection preserves partial progress")
    check(Economy.canAddPart(account,"Rare",settings),"can still finish the reserved slot")
    add(account,"Rare",9)
    check(Economy.robotCount(account)==4 and Economy.incomePerSecond(account,settings)==35,"four-slot mixed workshop complete")
    for _,rarity in {"Common","Uncommon","Rare","Unknown","common"} do
        check(not Economy.addPart(account,rarity,settings),"full or unknown recipe must reject")
    end
end)

test("fractional timing is independent of frame size",function()
    local frames,lump=Economy.new(),Economy.new()
    add(frames,"Common",5);add(lump,"Common",5)
    for _=1,600 do Economy.advance(frames,1/60,settings) end
    Economy.advance(lump,10,settings)
    check(frames.cash==50 and lump.cash==50,"frame scheduling cannot change earnings")
    local fraction=Economy.new();add(fraction,"Common",5)
    check(Economy.advance(fraction,.1,settings)==0,"half dollar retained")
    check(Economy.advance(fraction,.1,settings)==1,"two halves make a dollar")
    for _,seconds in {-1,math.huge,0/0} do
        check(not pcall(function() Economy.advance(fraction,seconds,settings) end),"invalid time rejected")
    end
end)

test("no retroactive income, unknown recipes, or shared accounts",function()
    local alice,bob=Economy.new(),Economy.new()
    check(not Economy.addPart(alice,"Unknown",settings),"unknown rarity rejected")
    check(#alice.projects==0,"unknown rarity has no effects")
    Economy.advance(alice,100,settings);add(alice,"Common",5)
    check(alice.cash==0,"old time earns no money")
    Economy.advance(alice,1,settings);add(alice,"Rare",10);Economy.advance(alice,1,settings)
    check(alice.cash==30,"new rate applies only after robot completion")
    check(bob.cash==0 and #bob.projects==0,"accounts are independent")
    local rejoined=Economy.new()
    check(rejoined.cash==0 and #rejoined.projects==0,"new session is empty")
end)

test("five assembly groups and unobstructed workshop doorway",function()
    local steps: {[number]: boolean}={}
    local names: {[string]: boolean}={}
    for _,part in Robot do
        check(not names[part.name],"unique robot part name");names[part.name]=true
        check(part.step>=1 and part.step<=5,"five assembly groups only");steps[part.step]=true
        for _,size in part.size do check(size>0,"positive robot dimensions") end
        check(part.position[2]-part.size[2]/2>=0,"robot clears the pad")
        check(part.position[2]+part.size[2]/2<11,"robot clears the canopy")
    end
    for step=1,5 do check(steps[step]==true,"each Common part reveals one group") end
    for _,part in Base do
        local overlaps=math.abs(part.position[1])<part.size[1]/2+2
            and math.abs(part.position[3]-23)<part.size[3]/2+2
            and part.position[2]+part.size[2]/2>1 and part.position[2]-part.size[2]/2<7
        check(not (part.collidable and overlaps),"clear entrance: "..part.name)
    end
end)
print(string.format("%d rarity/economy groups passed; %d assertions; no skipped tests",suites,assertions))
