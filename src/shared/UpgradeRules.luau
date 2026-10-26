--!strict
export type Definition = { Label: string, Description: string, BaseCost: number, CostMultiplier: number, PerLevel: number, MaxLevel: number }
export type Settings = { read BaseSpeed: number, read Strength: number, read Upgrades: {[string]: Definition} }
export type Wallet = { cash: number, upgrades: {[string]: number} }
export type Offer = { kind: string, label: string, description: string, level: number, maxLevel: number,
    currentValue: number, nextValue: number, cost: number, maxed: boolean }
export type Context = { alive: boolean, hasBase: boolean, distance: number }
local UpgradeRules = {}

function UpgradeRules.canInteract(context: Context, maxDistance: number): boolean
    return context.alive and context.hasBase and context.distance>=0 and context.distance<=maxDistance
end

function UpgradeRules.value(kind: string, level: number, settings: Settings): number
    local base = if kind=="Speed" then settings.BaseSpeed else settings.Strength
    return base + level * settings.Upgrades[kind].PerLevel
end

function UpgradeRules.offer(wallet: Wallet, kind: string, settings: Settings): Offer
    local definition = settings.Upgrades[kind]
    assert(definition ~= nil, "Unknown upgrade")
    local level = wallet.upgrades[kind] or 0
    local maxed = level >= definition.MaxLevel
    return { kind=kind, label=definition.Label, description=definition.Description, level=level, maxLevel=definition.MaxLevel,
        currentValue=UpgradeRules.value(kind,level,settings),
        nextValue=UpgradeRules.value(kind,if maxed then level else level+1,settings),
        cost=if maxed then 0 else math.ceil(definition.BaseCost*definition.CostMultiplier^level), maxed=maxed }
end

function UpgradeRules.purchase(wallet: Wallet, kind: string, expectedLevel: number, settings: Settings): (boolean,string)
    if not settings.Upgrades[kind] then return false,"Milo does not sell that upgrade." end
    if not (expectedLevel>=0 and expectedLevel<math.huge and expectedLevel%1==0) then
        return false,"Please review the current upgrade offer."
    end
    local offer=UpgradeRules.offer(wallet,kind,settings)
    -- A repeated or delayed click cannot buy the next, more expensive level.
    if offer.level~=expectedLevel then return false,"This offer changed. Review the updated price." end
    if offer.maxed then return false,"This upgrade is already maxed out." end
    if wallet.cash<offer.cost then return false,"You need $"..(offer.cost-wallet.cash).." more for this upgrade." end
    -- This transaction is synchronous: no yielding between the debit and level change.
    wallet.cash-=offer.cost
    wallet.upgrades[kind]=offer.level+1
    return true,offer.label.." upgraded to level "..(offer.level+1).."!"
end

return UpgradeRules
