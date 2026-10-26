--!strict
local Economy = require("../src/shared/Economy")
local Inventory = require("../src/shared/Inventory")
local Config = require("../src/shared/Config")
local Base = require("../src/shared/BaseBlueprint")
local Robot = require("../src/shared/RobotBlueprint")
local recipe = Config.Robot
local assertions, suites = 0, 0
local function check(condition: boolean, message: string)
    assertions += 1
    assert(condition, message)
end
local function test(name: string, run: () -> ())
    run(); suites += 1; print("PASS " .. name)
end

test("ten accepted scraps produce exactly one income-generating robot", function()
    local account = Economy.new()
    check(Economy.advance(account, 100, recipe) == 0, "empty bases do not earn")
    for scrap = 1, 9 do
        local ok, built = Economy.addScrap(account, 1, recipe)
        check(ok and built == 0 and account.scrap == scrap and account.robots == 0, "partial assembly retains scrap")
        check(Economy.incomePerSecond(account, recipe) == 0, "unfinished robots do not earn")
    end
    local ok, built = Economy.addScrap(account, 1, recipe)
    check(ok and built == 1 and account.scrap == 0 and account.robots == 1, "tenth scrap consumes the recipe once")
    check(Economy.incomePerSecond(account, recipe) == 5, "first robot earns the configured $5/sec")
    check(Economy.advance(account, 12, recipe) == 60 and account.cash == 60, "twelve seconds yields sixty dollars")
end)

test("multiple robots and leftover scrap preserve exact accounting", function()
    local account = Economy.new()
    local ok, built = Economy.addScrap(account, 25, recipe)
    check(ok and built == 2 and account.scrap == 5, "two recipes plus five scrap")
    check(Economy.incomePerSecond(account, recipe) == 10, "income stacks across robots")
    Economy.addScrap(account, 15, recipe)
    check(account.robots == 4 and account.scrap == 0, "four slots filled exactly")
    check(Economy.advance(account, 3, recipe) == 60, "four robots generate $20/sec")
end)

test("full workshop rejects deposits without consuming carried loot", function()
    local account = Economy.new()
    Economy.addScrap(account, 40, recipe)
    local inventory = Inventory.new(12)
    Inventory.registerItem(inventory, "held")
    Inventory.pickup(inventory, 1, "held", { alive = true, hasBase = true, distance = 2 })
    check(not Economy.canAddScrap(account, 1, recipe), "full capacity gate rejects the deposit")
    local ok, built = Economy.addScrap(account, 1, recipe)
    check(not ok and built == 0 and account.robots == 4 and account.scrap == 0, "rejection does not mutate economy")
    check(inventory.carrying[1] == "held" and inventory.items.held.owner == 1, "carry remains owned until a deposit can be accepted")
    check(inventory.delivered[1] == nil, "no false delivery count")
end)

test("frame-sized ticks and long ticks produce the same cash", function()
    local frames = Economy.new()
    local lump = Economy.new()
    Economy.addScrap(frames, 10, recipe)
    Economy.addScrap(lump, 10, recipe)
    for _ = 1, 600 do Economy.advance(frames, 1 / 60, recipe) end
    Economy.advance(lump, 10, recipe)
    check(frames.cash == lump.cash and frames.cash == 50, "frame frequency must not change earnings")
    check(frames.fraction >= 0 and frames.fraction < 1, "fractional balance stays normalized")
    local fractional = Economy.new()
    Economy.addScrap(fractional, 10, recipe)
    check(Economy.advance(fractional, 0.1, recipe) == 0, "sub-dollar earnings retained")
    check(Economy.advance(fractional, 0.1, recipe) == 1, "two half-dollars accrue to one")
end)

test("new robots do not earn retroactively and accounts are isolated", function()
    local alice = Economy.new()
    local bob = Economy.new()
    Economy.advance(alice, 50, recipe)
    Economy.addScrap(alice, 10, recipe)
    check(alice.cash == 0, "no earnings for time before assembly")
    Economy.advance(alice, 1, recipe)
    Economy.addScrap(alice, 10, recipe)
    Economy.advance(alice, 1, recipe)
    check(alice.cash == 15, "rate changes apply to subsequent elapsed time")
    check(bob.cash == 0 and bob.robots == 0 and bob.scrap == 0, "other players receive no shared progress")
    local rejoined = Economy.new()
    check(rejoined.cash == 0 and rejoined.robots == 0, "a new session starts empty")
end)

test("invalid deposits and times cannot generate money or robots", function()
    local account = Economy.new()
    for _, amount in { -1, 0, 0.5, math.huge, 0 / 0, 41 } do
        check(not Economy.addScrap(account, amount, recipe), "invalid amount rejected")
        check(account.scrap == 0 and account.robots == 0, "rejection is atomic")
    end
    for _, seconds in { -1, math.huge, 0 / 0 } do
        check(not pcall(function() Economy.advance(account, seconds, recipe) end), "invalid elapsed time must fail")
    end
end)

test("blueprints have ten visible robot stages and a walkable entrance", function()
    local steps: {[number]: boolean} = {}
    local names: {[string]: boolean} = {}
    for _, part in Robot do
        check(not names[part.name], "robot part names are unique")
        names[part.name] = true
        steps[part.step] = true
        check(part.step >= 1 and part.step <= 10, "part has a valid assembly stage")
        for _, size in part.size do check(size > 0, "robot geometry must have positive dimensions") end
        check(part.position[2] - part.size[2] / 2 >= 0, "robot does not extend below its pad")
        check(part.position[2] + part.size[2] / 2 < 11, "robot clears the workshop canopy")
    end
    for step = 1, 10 do check(steps[step] == true, "every delivered scrap reveals geometry") end
    check(#Robot <= 45, "keep the robot part budget suitable for a small multiplayer prototype")
    for _, part in Base do
        for _, size in part.size do check(size > 0, "base geometry has positive dimensions") end
        -- A character-sized box at the gate center must fit under the lintel.
        local overlapsEntrance = math.abs(part.position[1]) < part.size[1] / 2 + 2
            and math.abs(part.position[3] - 23) < part.size[3] / 2 + 2
            and part.position[2] + part.size[2] / 2 > 1
            and part.position[2] - part.size[2] / 2 < 7
        check(not (part.collidable and overlapsEntrance), "entrance must remain walkable: " .. part.name)
    end
end)

print(string.format("%d economy/geometry groups passed; %d assertions; no skipped tests", suites, assertions))
