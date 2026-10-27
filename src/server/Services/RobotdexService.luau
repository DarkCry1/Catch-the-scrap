--!nonstrict
-- Robotdex: discovery snapshots, milestone rewards, titles and workshop skins.
-- Clients send intent only (claim id, cosmetic id, retire id); every rule is
-- checked here against the server-owned account.
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Catalog=require(Shared.RobotCatalog)
local Economy=require(Shared.Economy)
local Rewards=require(Shared.DexRewards)
local Mutations=require(Shared.Mutations)
local Service={}
Service.__index=Service
Service.MaxCash=1e15

function Service.new(finance,carry,remote)
    return setmetatable({finance=finance,carry=carry,remote=remote,last={},random=Random.new()},Service)
end

local function list(set)
    local out={};for k,v in set do if v then table.insert(out,k) end end;table.sort(out);return out
end

function Service:send(player,message)
    local entry=self.finance.players[player];if not entry then return end
    local account=entry.account
    local projects={}
    for slot,p in account.projects do
        -- A sealed or opening box never reveals its species before the reveal.
        table.insert(projects,{id=p.id,slot=slot,complete=p.complete,rarity=p.rarity,parts=p.parts,
            variant=if p.complete then p.variant else nil,mutation=if p.complete then p.mutation else nil,
            name=if p.opening then p.rarity.." robot / opening..." elseif p.complete then Mutations.prefix(p.mutation)..Catalog.label(p.variant) else string.format("%s build %d / %d",p.rarity,p.parts,Config.Robot.Recipes[p.rarity].Parts),
            income=math.floor(Economy.projectIncome(p,Config.Robot)*Economy.multiplier(account))})
    end
    local dex={};for id,n in account.dex do dex[id]=n end
    local mdex={};for key,n in account.mdex do mdex[key]=n end
    self.remote:FireClient(player,"Robotdex",{dex=dex,claimed=list(account.claimed),projects=projects,
        perks={income=account.perks.income,speed=account.perks.speed},titles=list(account.titles),title=account.title or "",
        skins=list(account.skins),skin=account.skin or "Default",stats={built=account.stats.built,unboxed=account.stats.unboxed},
        found=Economy.discovered(account),total=Catalog.Total,message=message,mdex=mdex,
        rebirths=account.rebirths,slots=Economy.slots(account,Config.Robot),multiplier=Economy.multiplier(account)})
    player:SetAttribute("DexClaimable",Rewards.claimable(account))
end

function Service:allow(player)
    local now=os.clock()
    if now-(self.last[player] or -math.huge)<.35 then return false end
    self.last[player]=now;return true
end
function Service:request(player) if self:allow(player) then self:send(player) end end

-- Overhead title. Re-applied on every new character.
function Service:applyTitle(player)
    local entry=self.finance.players[player]
    local character=player.Character
    local head=character and character:FindFirstChild("Head")
    if not head then return end
    local tag=head:FindFirstChild("RobotdexTitle")
    local title=entry and entry.account.title
    if not title or title=="" then if tag then tag:Destroy() end;return end
    if not tag then
        tag=Instance.new("BillboardGui");tag.Name="RobotdexTitle";tag.Size=UDim2.fromOffset(220,30);tag.StudsOffset=Vector3.new(0,2.6,0)
        tag.MaxDistance=80;tag.LightInfluence=0;tag.Parent=head
        local label=Instance.new("TextLabel");label.Name="Title";label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
        label.Font=Enum.Font.GothamBlack;label.TextScaled=true;label.TextColor3=Color3.fromRGB(255,206,96);label.TextStrokeTransparency=.35;label.AutoLocalize=false;label.Parent=tag
    end
    tag.Title.Text=title:upper()
end

function Service:applySkin(player)
    local entry=self.finance.players[player]
    if entry and entry.base and self.finance.world.applySkin then self.finance.world:applySkin(entry.base,entry.account.skin or "Default") end
end

function Service:claim(player,id)
    if type(id)~="string" or not self:allow(player) then return end
    local entry=self.finance.players[player];if not entry then return end
    local account=entry.account
    local milestone=Rewards.get(id)
    if not milestone then return end
    if account.claimed[id] then self:send(player,"Reward already claimed.");return end
    if not Rewards.ready(account,milestone) then self:send(player,"Discover more robots to unlock this reward.");return end
    local boxes={}
    for _,r in milestone.Rewards do if r.Type=="Box" then table.insert(boxes,r.Rarity) end end
    if #boxes>0 then
        if not entry.base then self:send(player,"A workshop is required to receive a robot box.");return end
        if Economy.slots(account,Config.Robot)-#account.projects<#boxes then self:send(player,"Free a platform first: this reward delivers a robot box to your workshop.");return end
    end
    -- Validation complete: apply every reward exactly once, synchronously.
    self.finance:settle(player,entry,os.clock())
    account.claimed[id]=true
    local notes={}
    for _,r in milestone.Rewards do
        if r.Type=="Cash" then account.cash=math.min(Service.MaxCash,account.cash+r.Amount)
        elseif r.Type=="Income" then account.perks.income+=r.Amount
        elseif r.Type=="Speed" then account.perks.speed+=r.Amount
        elseif r.Type=="Title" then account.titles[r.Name]=true;if not account.title then account.title=r.Name end
        elseif r.Type=="Skin" then account.skins[r.Name]=true end
        table.insert(notes,Rewards.describe(r))
    end
    self.finance:publish(player,entry)
    if entry.base then self.finance.world:updateEconomy(entry.base,player,entry.account) end
    for _,rarity in boxes do
        self.finance:recoverRobot(player,rarity,Catalog.roll(self.random:NextNumber(),rarity,"Box"),Mutations.roll(self.random:NextNumber()))
    end
    self.carry:writeState(player)
    self:applyTitle(player)
    if self.onClaim then self.onClaim(player,id) end
    self:send(player,"Claimed "..milestone.Title..": "..table.concat(notes,", ").."!")
end

function Service:equip(player,kind,id)
    if (kind~="Title" and kind~="Skin") or type(id)~="string" or not self:allow(player) then return end
    local entry=self.finance.players[player];if not entry then return end
    local account=entry.account
    if kind=="Title" then
        if id~="" and not account.titles[id] then return end
        account.title=if id=="" then nil else id
        self:applyTitle(player)
        self:send(player,if id=="" then "Title hidden." else "Title equipped: "..id)
    else
        if not account.skins[id] or not Rewards.Skins[id] then return end
        account.skin=id
        self:applySkin(player)
        self:send(player,"Workshop skin applied: "..Rewards.Skins[id].Label)
    end
end

function Service:retire(player,id)
    if type(id)~="number" or id%1~=0 or not self:allow(player) then return end
    local entry=self.finance.players[player];if not entry or not entry.base then return end
    local context=self.carry:context(player,entry.base.deposit.Position)
    if entry.base.owner~=player.UserId or not context.alive or not context.hasBase or not (context.distance>=0 and context.distance<=Config.InteractionDistance) then self:send(player,"Return to your workshop to retire a robot.");return end
    self.finance:settle(player,entry,os.clock())
    local ok=Economy.retire(entry.account,id)
    if ok then self.finance:publish(player,entry);self.finance.world:updateEconomy(entry.base,player,entry.account) end
    self:send(player,if ok then "Robot retired. Robotdex entry kept; platform freed. No cash refund." else "Only completed robots can be retired.")
end

function Service:removePlayer(player) self.last[player]=nil end
return Service
