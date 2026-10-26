--!strict
-- This state lives only on the server. The client receives display attributes.
export type Account = { scrap: number, robots: number, cash: number, fraction: number }
export type Recipe = { ScrapPerRobot: number, Slots: number, IncomePerRobot: number }
local Economy = {}

local function positiveInteger(value: number): boolean
    return value > 0 and value < math.huge and value % 1 == 0
end

function Economy.new(): Account
    return { scrap = 0, robots = 0, cash = 0, fraction = 0 }
end

function Economy.canAddScrap(account: Account, amount: number, recipe: Recipe): boolean
    assert(positiveInteger(recipe.ScrapPerRobot) and positiveInteger(recipe.Slots), "Invalid robot recipe")
    if not positiveInteger(amount) then return false end
    local space = (recipe.Slots - account.robots) * recipe.ScrapPerRobot - account.scrap
    return amount <= space
end

function Economy.addScrap(account: Account, amount: number, recipe: Recipe): (boolean, number)
    if not Economy.canAddScrap(account, amount, recipe) then return false, 0 end
    local total = account.scrap + amount
    local built = math.floor(total / recipe.ScrapPerRobot)
    account.scrap = total % recipe.ScrapPerRobot
    account.robots += built
    return true, built
end

function Economy.incomePerSecond(account: Account, recipe: Recipe): number
    assert(recipe.IncomePerRobot >= 0 and recipe.IncomePerRobot < math.huge, "Invalid income rate")
    return account.robots * recipe.IncomePerRobot
end

function Economy.advance(account: Account, seconds: number, recipe: Recipe): number
    assert(seconds >= 0 and seconds < math.huge, "Elapsed time must be finite and nonnegative")
    local earnings = account.fraction + Economy.incomePerSecond(account, recipe) * seconds
    local whole = math.floor(earnings + 1e-9)
    -- Small tolerance avoids losing an integer to floating-point frame sums.
    account.fraction = math.max(0, earnings - whole)
    account.cash += whole
    return whole
end

return Economy
