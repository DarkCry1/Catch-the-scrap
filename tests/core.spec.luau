--!strict
local Inventory = require("../src/shared/Inventory")
local Movement = require("../src/shared/Movement")
local Config = require("../src/shared/Config")

local assertions = 0
local suites = 0
local function check(condition: boolean, message: string)
    assertions += 1
    assert(condition, message)
end
local function test(name: string, run: () -> ())
    run()
    suites += 1
    print("PASS " .. name)
end
local near = { alive = true, hasBase = true, distance = 5 }

local function invariant(state: Inventory.State)
    for playerId, itemId in state.carrying do
        local item = state.items[itemId]
        check(item ~= nil and item.owner == playerId, "carried item must have exactly its carrier as owner")
    end
    for itemId, item in state.items do
        if item.owner ~= nil then
            check(state.carrying[item.owner] == itemId, "owned item must have a matching carrier")
        end
    end
end

test("speed: no load, heavier load, strength and floor", function()
    local light = Movement.effectiveSpeed(24, 30, 10, 7)
    local medium = Movement.effectiveSpeed(24, 30, 60, 7)
    local heavy = Movement.effectiveSpeed(24, 30, 150, 7)
    check(Movement.effectiveSpeed(24, 30, 0, 7) == 24, "unladen speed")
    check(24 > light and light > medium and medium > heavy, "weight must slow movement")
    check(heavy == 7, "minimum speed prevents an unusable crawl")
    check(Movement.effectiveSpeed(24, 60, 60, 7) > medium, "strength mitigates the penalty")
    for _, item in Config.Items do
        local speed = Movement.effectiveSpeed(Config.BaseSpeed, Config.Strength, item.weight, Config.MinimumSpeed)
        check(speed >= Config.MinimumSpeed and speed <= Config.BaseSpeed, "configured item speed within bounds")
    end
end)

test("invalid movement inputs cannot produce a NaN speed", function()
    for _, args in {
        { 24, 0, 10, 7 }, { 24, -1, 10, 7 }, { 24, 30, -1, 7 },
        { 24, 30, math.huge, 7 }, { 0 / 0, 30, 10, 7 },
        { 24, 30, 0 / 0, 7 }, { 24, 30, 10, 25 },
    } do
        local ok = pcall(function() Movement.effectiveSpeed(args[1], args[2], args[3], args[4]) end)
        check(not ok, "invalid speed configuration must fail explicitly")
    end
end)

test("one carried item per player and one owner per item", function()
    local state = Inventory.new(12)
    Inventory.registerItem(state, "A")
    Inventory.registerItem(state, "B")
    check(Inventory.pickup(state, 1, "A", near), "first pickup succeeds")
    check(not Inventory.pickup(state, 1, "B", near), "cannot carry two")
    check(not Inventory.pickup(state, 2, "A", near), "contested pickup has one winner")
    check(Inventory.drop(state, 2) == nil, "another player cannot drop the owner's loot")
    check(Inventory.pickup(state, 2, "B", near), "another free item remains usable")
    invariant(state)
end)

test("pickups reject dead, baseless, distant and malformed contexts", function()
    local state = Inventory.new(12)
    Inventory.registerItem(state, "A")
    for _, context in {
        { alive = false, hasBase = true, distance = 1 },
        { alive = true, hasBase = false, distance = 1 },
        { alive = true, hasBase = true, distance = 12.01 },
        { alive = true, hasBase = true, distance = -1 },
        { alive = true, hasBase = true, distance = math.huge },
        { alive = true, hasBase = true, distance = 0 / 0 },
    } do
        check(not Inventory.pickup(state, 1, "A", context), "invalid pickup must fail")
        check(state.carrying[1] == nil and state.items.A.owner == nil, "failed pickup must not mutate ownership")
    end
    check(not Inventory.pickup(state, 1, "missing", near), "unknown items are rejected")
    check(Inventory.pickup(state, 1, "A", { alive = true, hasBase = true, distance = 12 }), "exact distance boundary allowed")
end)

test("drop frees the item without rewards, allowing another pickup", function()
    local state = Inventory.new(12)
    Inventory.registerItem(state, "A")
    Inventory.pickup(state, 1, "A", near)
    check(Inventory.drop(state, 1) == "A", "drop returns the carried id")
    check(Inventory.drop(state, 1) == nil, "repeated drop is harmless")
    check(state.delivered[1] == nil, "drop must not award a deposit")
    check(Inventory.pickup(state, 2, "A", near), "dropped loot becomes available")
    invariant(state)
end)

test("deposits require own base and proximity and award only once", function()
    local state = Inventory.new(12)
    Inventory.registerItem(state, "A")
    Inventory.pickup(state, 1, "A", near)
    check(Inventory.deposit(state, 1, 2, near) == nil, "another base rejected")
    for _, context in {
        { alive = false, hasBase = true, distance = 1 },
        { alive = true, hasBase = false, distance = 1 },
        { alive = true, hasBase = true, distance = 100 },
        { alive = true, hasBase = true, distance = 0 / 0 },
    } do
        check(Inventory.deposit(state, 1, 1, context) == nil, "invalid deposit rejected")
        check(state.carrying[1] == "A" and state.items.A.owner == 1, "failed deposit keeps the loot")
    end
    check(Inventory.deposit(state, 1, 1, near) == "A", "own-base deposit succeeds")
    check(state.delivered[1] == 1 and state.carrying[1] == nil and state.items.A == nil, "deposit consumes loot and awards exactly one")
    check(Inventory.deposit(state, 1, 1, near) == nil, "duplicate deposit rejected")
    check(state.delivered[1] == 1, "no duplicate reward")
    check(not Inventory.pickup(state, 2, "A", near), "consumed id cannot be replayed")
end)

test("death cleanup preserves banked count; disconnect frees held item", function()
    local state = Inventory.new(12)
    Inventory.registerItem(state, "A")
    Inventory.registerItem(state, "B")
    Inventory.pickup(state, 1, "A", near)
    Inventory.deposit(state, 1, 1, near)
    Inventory.pickup(state, 1, "B", near)
    check(Inventory.drop(state, 1) == "B", "death cleanup releases carried item")
    check(state.delivered[1] == 1, "death does not lose banked session progress")
    Inventory.pickup(state, 1, "B", near)
    check(Inventory.removePlayer(state, 1) == "B", "disconnect returns item for world reset")
    check(state.carrying[1] == nil and state.delivered[1] == nil, "no persistence after leaving")
    check(Inventory.pickup(state, 2, "B", near), "disconnect does not strand an item")
    check(Inventory.removePlayer(state, 1) == nil, "duplicate cleanup is safe")
    invariant(state)
end)

test("state invariants survive 500 mixed multiplayer actions", function()
    local state = Inventory.new(12)
    for index = 1, 6 do Inventory.registerItem(state, tostring(index)) end
    math.randomseed(261026)
    local deposits = 0
    for _ = 1, 500 do
        local playerId = math.random(1, 4)
        local action = math.random(1, 3)
        if action == 1 then
            Inventory.pickup(state, playerId, tostring(math.random(1, 6)), near)
        elseif action == 2 then
            Inventory.drop(state, playerId)
        else
            local deposited = Inventory.deposit(state, playerId, playerId, near)
            if deposited then
                deposits += 1
                Inventory.registerItem(state, deposited)
            end
        end
        invariant(state)
    end
    local awarded = 0
    for _, count in state.delivered do awarded += count end
    check(deposits > 0 and awarded == deposits, "session counters match successful deposits only")
end)

print(string.format("%d test groups passed; %d assertions; no skipped tests", suites, assertions))
