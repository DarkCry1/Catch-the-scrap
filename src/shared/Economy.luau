--!strict
-- Each unfinished rarity project reserves one platform. Part types never mix.
export type Recipe = { Parts: number, Income: number, Name: string, Color: {number} }
export type Settings = { Slots: number, Recipes: {[string]: Recipe} }
export type Project = { id:number, rarity: string, parts: number, complete: boolean, opening: boolean?, startedAt: number?, recovered: boolean?, variant: string? }
export type Account = { projects: {Project}, cash: number, fraction: number, upgrades: {[string]: number}, unlocked:{[string]:boolean}, selected:{[string]:string}, nextId:number }
local Catalog=require("./RobotCatalog")
local Style=require("./RarityStyle")
local Economy = {}

function Economy.new(): Account
    return { projects = {}, cash = 0, fraction = 0, upgrades = { Speed = 0, Strength = 0 },unlocked={},selected={},nextId=0 }
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
    return project ~= nil or #account.projects < settings.Slots
end

function Economy.addPart(account: Account, rarity: string, settings: Settings): (boolean, boolean, number)
    if not Economy.canAddPart(account, rarity, settings) then return false, false, 0 end
    local project, index = Economy.activeProject(account, rarity)
    if not project then
        account.nextId+=1
        project = { id=account.nextId,rarity = rarity, parts = 0, complete = false,variant=account.selected[rarity] or "Bastion" } :: Project
        table.insert(account.projects, project)
        index = #account.projects
    end
    assert(project ~= nil and index ~= nil, "Accepted parts must have a reserved platform")
    project.parts += 1
    project.complete = project.parts == settings.Recipes[rarity].Parts
    if project.complete then account.unlocked[Style.key(rarity,project.variant or "Bastion")]=true end
    return true, project.complete, index
end

function Economy.canRecoverRobot(account: Account, settings: Settings): boolean
    return #account.projects < settings.Slots
end

function Economy.reserveRobot(account: Account, rarity: string, settings: Settings, startedAt: number,variant: string?): number?
    if not settings.Recipes[rarity] or not Economy.canRecoverRobot(account,settings) then return nil end
    local choice=variant or "Volt"
    if not Catalog.find(choice) or not Catalog.canAcquire(rarity,choice,"Box") then return nil end
    account.nextId+=1
    table.insert(account.projects,{id=account.nextId,rarity=rarity,parts=0,complete=false,opening=true,startedAt=startedAt,recovered=true,variant=choice})
    return #account.projects
end

function Economy.finishRecovery(account: Account,index: number,settings: Settings): boolean
    local project=account.projects[index]
    if not project or not project.opening then return false end
    project.opening=nil;project.complete=true;project.parts=settings.Recipes[project.rarity].Parts
    account.unlocked[Style.key(project.rarity,project.variant or "Volt")]=true
    return true
end

function Economy.select(account:Account,rarity:string,variant:string,settings:Settings): boolean
    if not settings.Recipes[rarity] or not Catalog.find(variant) or not Catalog.canAcquire(rarity,variant,"Build") then return false end
    account.selected[rarity]=variant
    return true
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

function Economy.incomePerSecond(account: Account, settings: Settings): number
    local rate = 0
    for _, project in account.projects do
        if project.complete then rate += Catalog.income(settings.Recipes[project.rarity].Income,project.variant,if project.recovered then "Box" else "Build") end
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
