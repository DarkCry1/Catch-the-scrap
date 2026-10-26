--!strict
-- Each unfinished rarity project reserves one platform. Part types never mix.
export type Recipe = { Parts: number, Income: number, Name: string, Color: {number} }
export type Settings = { Slots: number, Recipes: {[string]: Recipe} }
export type Project = { rarity: string, parts: number, complete: boolean }
export type Account = { projects: {Project}, cash: number, fraction: number, upgrades: {[string]: number} }
local Economy = {}

function Economy.new(): Account
    return { projects = {}, cash = 0, fraction = 0, upgrades = { Speed = 0, Strength = 0 } }
end

function Economy.activeProject(account: Account, rarity: string): (Project?, number?)
    for index, project in account.projects do
        if project.rarity == rarity and not project.complete then return project, index end
    end
    return nil, nil
end

function Economy.canAddPart(account: Account, rarity: string, settings: Settings): boolean
    if not settings.Recipes[rarity] then return false end
    local project = Economy.activeProject(account, rarity)
    return project ~= nil or #account.projects < settings.Slots
end

function Economy.addPart(account: Account, rarity: string, settings: Settings): (boolean, boolean, number)
    if not Economy.canAddPart(account, rarity, settings) then return false, false, 0 end
    local project, index = Economy.activeProject(account, rarity)
    if not project then
        project = { rarity = rarity, parts = 0, complete = false }
        table.insert(account.projects, project)
        index = #account.projects
    end
    assert(project ~= nil and index ~= nil, "Accepted parts must have a reserved platform")
    project.parts += 1
    project.complete = project.parts == settings.Recipes[rarity].Parts
    return true, project.complete, index
end

function Economy.robotCount(account: Account): number
    local count = 0
    for _, project in account.projects do if project.complete then count += 1 end end
    return count
end

function Economy.progress(account: Account, rarity: string): number
    local project = Economy.activeProject(account, rarity)
    return if project then project.parts else 0
end

function Economy.incomePerSecond(account: Account, settings: Settings): number
    local rate = 0
    for _, project in account.projects do
        if project.complete then rate += settings.Recipes[project.rarity].Income end
    end
    return rate
end

function Economy.advance(account: Account, seconds: number, settings: Settings): number
    assert(seconds >= 0 and seconds < math.huge, "Elapsed time must be finite and nonnegative")
    local earnings = account.fraction + Economy.incomePerSecond(account, settings) * seconds
    local whole = math.floor(earnings + 1e-9)
    account.fraction = math.max(0, earnings - whole)
    account.cash += whole
    return whole
end

return Economy
