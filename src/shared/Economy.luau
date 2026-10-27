--!strict
-- Each unfinished rarity project reserves one platform. Part types never mix.
-- v1.2: the species of a scrap build is rolled (weighted) only when the build
-- completes; boxes carry a species rolled on the server when they spawn.
-- Every completed robot is counted in the Robotdex (`dex[id]` = times obtained).
local QuestRules=require("./QuestRules")
export type Recipe = { Parts: number, Income: number, Name: string, Color: {number} }
export type Settings = { Slots: number, MaxSlots: number, Recipes: {[string]: Recipe} }
export type Project = { id:number, rarity: string, parts: number, complete: boolean, opening: boolean?, startedAt: number?, recovered: boolean?, variant: string?, mutation: string? }
export type Perks = { income: number, speed: number }
export type Stats = { built: number, unboxed: number }
export type Account = {
    projects: {Project}, cash: number, fraction: number, upgrades: {[string]: number},
    dex: {[string]: number}, claimed: {[string]: boolean}, perks: Perks,
    titles: {[string]: boolean}, title: string?, skins: {[string]: boolean}, skin: string?,
    nextId: number, stats: Stats,
    -- v1.3
    rebirths: number, mdex: {[string]: number}, quests: QuestRules.State?, tutorial: number,
}
local Catalog=require("./RobotCatalog")
local Mutations=require("./Mutations")
local RebirthRules=require("./RebirthRules")
local Economy = {}

function Economy.new(): Account
    return {
        projects = {}, cash = 0, fraction = 0, upgrades = { Speed = 0, Strength = 0 },
        dex = {}, claimed = {}, perks = { income = 0, speed = 0 },
        titles = {}, title = nil, skins = { Default = true }, skin = "Default",
        nextId = 0, stats = { built = 0, unboxed = 0 },
        rebirths = 0, mdex = {}, quests = nil, tutorial = 0,
    }
end

-- Platforms this account may use (base slots plus one per rebirth, capped).
function Economy.slots(account: Account, settings: Settings): number
    return math.min(settings.MaxSlots, settings.Slots + account.rebirths)
end

-- Number of species owned with a given mutation.
function Economy.mutated(account: Account, mutation: string): number
    local count = 0
    for key, times in account.mdex do
        if times > 0 and string.sub(key, 1, #mutation + 1) == mutation .. ":" then count += 1 end
    end
    return count
end

-- Number of distinct species discovered (optionally for one rarity).
function Economy.discovered(account: Account, rarity: string?): number
    local count = 0
    for id, times in account.dex do
        local species = Catalog.find(id)
        if species and times > 0 and (rarity == nil or species.Rarity == rarity) then count += 1 end
    end
    return count
end

-- Record a completed robot; returns new species, new mutation for that species.
function Economy.record(account: Account, id: string, mutation: string?): (boolean, boolean)
    local before = account.dex[id] or 0
    account.dex[id] = before + 1
    local newMutation = false
    if mutation then
        local key = Mutations.key(mutation, id)
        newMutation = (account.mdex[key] or 0) == 0
        account.mdex[key] = (account.mdex[key] or 0) + 1
    end
    return before == 0, newMutation
end

function Economy.activeProject(account: Account, rarity: string): (Project?, number?)
    for index, project in account.projects do
        if project.rarity == rarity and not project.complete and not project.opening then return project, index end
    end
    return nil, nil
end

function Economy.canAddPart(account: Account, rarity: string, settings: Settings): boolean
    if not settings.Recipes[rarity] then return false end
    local project = Economy.activeProject(account, rarity)
    return project ~= nil or #account.projects < Economy.slots(account, settings)
end

-- `sample` in [0,1) chooses the species, `mutationSample` the mutation, if
-- this part completes the build. Returns accepted, completed, platform index,
-- new discovery.
function Economy.addPart(account: Account, rarity: string, settings: Settings, sample: number?, mutationSample: number?): (boolean, boolean, number, boolean)
    if not Economy.canAddPart(account, rarity, settings) then return false, false, 0, false end
    local project, index = Economy.activeProject(account, rarity)
    if not project then
        account.nextId+=1
        project = { id=account.nextId,rarity = rarity, parts = 0, complete = false } :: Project
        table.insert(account.projects, project)
        index = #account.projects
    end
    assert(project ~= nil and index ~= nil, "Accepted parts must have a reserved platform")
    project.parts += 1
    project.complete = project.parts == settings.Recipes[rarity].Parts
    local new = false
    if project.complete then
        project.variant = Catalog.roll(math.clamp(sample or 0, 0, 0.999999), rarity, "Build")
        project.mutation = if mutationSample then Mutations.roll(math.clamp(mutationSample, 0, 0.999999)) else nil
        account.stats.built += 1
        new = Economy.record(account, project.variant :: string, project.mutation)
    end
    return true, project.complete, index, new
end

function Economy.canRecoverRobot(account: Account, settings: Settings): boolean
    return #account.projects < Economy.slots(account, settings)
end

function Economy.reserveRobot(account: Account, rarity: string, settings: Settings, startedAt: number,variant: string?,mutation: string?): number?
    if not settings.Recipes[rarity] or not Economy.canRecoverRobot(account,settings) then return nil end
    if rarity == "Common" or rarity == "Uncommon" then return nil end
    local choice=variant or Catalog.roll(0, rarity, "Box")
    if not Catalog.canAcquire(rarity,choice,"Box") or not Mutations.valid(mutation) then return nil end
    account.nextId+=1
    table.insert(account.projects,{id=account.nextId,rarity=rarity,parts=0,complete=false,opening=true,startedAt=startedAt,recovered=true,variant=choice,mutation=mutation})
    return #account.projects
end

-- Returns finished, new discovery.
function Economy.finishRecovery(account: Account,index: number,settings: Settings): (boolean, boolean)
    local project=account.projects[index]
    if not project or not project.opening then return false, false end
    project.opening=nil;project.complete=true;project.parts=settings.Recipes[project.rarity].Parts
    account.stats.unboxed += 1
    return true, (Economy.record(account, project.variant :: string, project.mutation))
end

function Economy.retire(account:Account,id:number): boolean
    for index,project in account.projects do
        if project.id==id and project.complete then table.remove(account.projects,index);return true end
    end
    return false
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

-- Base income of one finished robot: recipe x species x mutation.
function Economy.projectIncome(project: Project, settings: Settings): number
    if not project.complete then return 0 end
    return Catalog.income(settings.Recipes[project.rarity].Income, project.variant) * Mutations.multiplier(project.mutation)
end

-- Workshop income: robots x (1 + Robotdex bonus) x rebirth multiplier.
function Economy.multiplier(account: Account): number
    return (1 + account.perks.income / 100) * RebirthRules.multiplier(account.rebirths)
end
function Economy.incomePerSecond(account: Account, settings: Settings): number
    local rate = 0
    for _, project in account.projects do rate += Economy.projectIncome(project, settings) end
    return rate * Economy.multiplier(account)
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
