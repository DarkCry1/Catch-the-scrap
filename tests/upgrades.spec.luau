--!strict
local Rules=require("../src/shared/UpgradeRules")
local Economy=require("../src/shared/Economy")
local Movement=require("../src/shared/Movement")
local Config=require("../src/shared/Config")
local Stand=require("../src/shared/MechanicBlueprint")
local checks,groups=0,0
local function check(ok: boolean,message: string) checks+=1;assert(ok,message) end
local function test(name: string,run: ()->()) run();groups+=1;print("PASS "..name) end

test("offers show exact stat changes and escalating prices",function()
    local wallet=Economy.new()
    local speed=Rules.offer(wallet,"Speed",Config)
    local strength=Rules.offer(wallet,"Strength",Config)
    check(speed.cost==75 and speed.currentValue==24 and speed.nextValue==26,"first Speed offer")
    check(strength.cost==100 and strength.currentValue==30 and strength.nextValue==40,"first Strength offer")
    wallet.cash=1000
    check(Rules.purchase(wallet,"Speed",0,Config),"Speed purchase succeeds")
    check(wallet.cash==925 and wallet.upgrades.Speed==1,"one exact debit and one level")
    check(Rules.offer(wallet,"Speed",Config).cost==120,"next level has its own price")
    check(Rules.offer(wallet,"Strength",Config).cost==100,"other upgrade price unchanged")
end)

test("insufficient funds and stale offers never debit money",function()
    local wallet=Economy.new();wallet.cash=74
    check(not Rules.purchase(wallet,"Speed",0,Config),"cannot spend unaffordable cash")
    check(wallet.cash==74 and wallet.upgrades.Speed==0,"failure is atomic")
    wallet.cash=200
    Rules.purchase(wallet,"Speed",0,Config)
    local balance=wallet.cash
    check(not Rules.purchase(wallet,"Speed",0,Config),"replayed click is rejected")
    check(wallet.cash==balance and wallet.upgrades.Speed==1,"replay cannot buy a second level")
    check(not Rules.purchase(wallet,"Strength",1,Config),"future level is not a valid offer")
end)

test("maximum levels and malformed requests are rejected",function()
    local wallet=Economy.new();wallet.cash=1000000
    for level=0,9 do check(Rules.purchase(wallet,"Speed",level,Config),"ten legitimate Speed purchases") end
    local balance=wallet.cash
    check(Rules.offer(wallet,"Speed",Config).maxed,"max level shown explicitly")
    check(not Rules.purchase(wallet,"Speed",10,Config),"no level eleven")
    check(wallet.cash==balance and wallet.upgrades.Speed==10,"maxed purchase does not charge")
    check(Rules.value("Speed",10,Config)==44,"Speed cap")
    for _,level in {-1,.5,math.huge,0/0} do check(not Rules.purchase(wallet,"Strength",level,Config),"invalid expected level") end
    check(not Rules.purchase(wallet,"Cash",0,Config),"unknown upgrade is never a money operation")
    check(not Rules.purchase(wallet,"speed",0,Config),"upgrade whitelist is case-sensitive")
end)

test("mechanic interaction requires a live nearby player with a base",function()
    check(Rules.canInteract({alive=true,hasBase=true,distance=12},12),"exact boundary allowed")
    for _,context in {
        {alive=false,hasBase=true,distance=1},{alive=true,hasBase=false,distance=1},
        {alive=true,hasBase=true,distance=12.01},{alive=true,hasBase=true,distance=-1},
        {alive=true,hasBase=true,distance=math.huge},{alive=true,hasBase=true,distance=0/0},
    } do check(not Rules.canInteract(context,12),"unsafe mechanic context rejected") end
end)

test("Strength improves loaded speed, Speed improves both, with isolated accounts",function()
    local alice,bob=Economy.new(),Economy.new();alice.cash=1000
    local before=Movement.effectiveSpeed(24,30,65,7)
    Rules.purchase(alice,"Strength",0,Config)
    local strength=Rules.value("Strength",alice.upgrades.Strength,Config)
    check(Movement.effectiveSpeed(24,strength,65,7)>before,"strength mitigates weight")
    check(Movement.effectiveSpeed(24,strength,0,7)==24,"Strength does not inflate unloaded speed")
    Rules.purchase(alice,"Speed",0,Config)
    check(Movement.effectiveSpeed(Rules.value("Speed",1,Config),strength,65,7)>before,"combined upgrades apply")
    check(bob.cash==0 and bob.upgrades.Speed==0 and bob.upgrades.Strength==0,"no shared levels or money")
    check(Economy.new().upgrades.Speed==0,"new server session resets upgrades")
end)

test("stand geometry stays outside the main street and clear of workshop footprints",function()
    for _,part in Stand do
        for _,size in part.size do check(size>0,"positive stand dimensions") end
        -- Stand origin is (55,0,7), yaw -90: local Z becomes world -X.
        local worldMinX=55-part.position[3]-part.size[3]/2
        local worldMinZ=7+part.position[1]-part.size[1]/2
        local worldMaxZ=7+part.position[1]+part.size[1]/2
        check(worldMinX>22,"stand does not obstruct the main road")
        check(worldMinZ>-7 and worldMaxZ<=20,"stand fits the plaza ahead of the workshops")
    end
end)
print(string.format("%d upgrade groups passed; %d assertions; no skipped tests",groups,checks))
