--!strict
-- Rebirth: spend cash to restart the workshop for permanent progress.
-- Resets: cash, partial income, Speed/Strength levels and every platform.
-- Keeps: Robotdex, claimed milestones, perks, titles, skins, quests, stats.
-- Gains: +IncomeBonus income multiplier and one extra platform per rebirth
-- (until Robot.MaxSlots).
local Config = require("./Config")
local Rules = {}

function Rules.cost(rebirths: number): number
    return Config.Rebirth.BaseCost * Config.Rebirth.Growth ^ rebirths
end
function Rules.multiplier(rebirths: number): number
    return 1 + Config.Rebirth.IncomeBonus * rebirths
end
function Rules.slots(rebirths: number): number
    return math.min(Config.Robot.MaxSlots, Config.Robot.Slots + rebirths)
end

type Account = { cash: number, fraction: number, rebirths: number, upgrades: {[string]: number}, projects: {any} }

-- Returns ok, reason. Openings in progress block a rebirth so a sealed box is
-- never silently destroyed.
function Rules.check(account: Account): (boolean, string)
    if account.rebirths >= Config.Rebirth.Max then return false, "Maximum rebirth reached." end
    for _, p in account.projects do
        if p.opening then return false, "Wait for your robot box to finish opening." end
    end
    local cost = Rules.cost(account.rebirths)
    if account.cash < cost then return false, string.format("You need $%d to rebirth.", cost) end
    return true, ""
end

function Rules.apply(account: Account): boolean
    if not Rules.check(account) then return false end
    account.rebirths += 1
    account.cash = 0
    account.fraction = 0
    for kind in account.upgrades do account.upgrades[kind] = 0 end
    table.clear(account.projects)
    return true
end
return Rules
