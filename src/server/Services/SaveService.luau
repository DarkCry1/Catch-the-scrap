--!nonstrict
-- Persistent progress (cash, upgrades, platforms, Robotdex, rewards, cosmetics).
--
-- One DataStore key per player: { data = SaveSchema payload, lock = {job,time} }.
-- A session lock stops two servers from writing the same player at once:
-- loading waits while another live server holds a fresh lock; autosave keeps
-- our lock fresh; leaving or shutdown releases it. Every write goes through
-- UpdateAsync and refuses to overwrite a lock owned by another server.
-- When DataStores are unavailable (Studio without API access, outages), the
-- player keeps playing with session-only progress and is told so.
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Schema=require(Shared.SaveSchema)
local Economy=require(Shared.Economy)
local Save={}
Save.__index=Save

-- deps: {store=DataStore|nil, jobId=string, now=function, wait=function}
function Save.new(deps)
    local self=setmetatable({store=deps.store,jobId=deps.jobId or "studio",now=deps.now or os.time,wait=deps.wait or task.wait,profiles={},pending=0,closing=false},Save)
    return self
end

function Save.key(userId) return "player_"..tostring(userId) end

local function fresh(lock,now,jobId)
    return type(lock)=="table" and lock.job~=jobId and type(lock.time)=="number" and now-lock.time<Config.Save.LockSeconds
end

-- Returns account, status: "loaded" | "new" | "offline".
function Save:load(player)
    local key=Save.key(player.UserId)
    if not self.store then
        self.profiles[player]={key=key,offline=true}
        return Economy.new(),"offline"
    end
    local attempts=math.ceil(Config.Save.LockSeconds/Config.Save.RetrySeconds)+2
    for attempt=1,attempts do
        local blocked,snapshot=false,nil
        local ok,err=pcall(function()
            self.store:UpdateAsync(key,function(old)
                local now=self.now()
                if type(old)=="table" and fresh(old.lock,now,self.jobId) then blocked=true;return nil end
                local record=if type(old)=="table" then old else {}
                record.lock={job=self.jobId,time=now}
                snapshot=record.data
                return record
            end)
        end)
        if ok and not blocked then
            local account=Schema.deserialize(snapshot)
            self.profiles[player]={key=key,offline=false}
            return account,if snapshot then "loaded" else "new"
        end
        if not ok then
            warn("[Catch the Scrap] Save load failed ("..tostring(err).."), attempt "..attempt)
            if attempt>=Config.Save.ErrorRetries then break end
        end
        if not player.Parent then return nil,"left" end
        self.wait(Config.Save.RetrySeconds)
    end
    -- DataStore unreachable: keep the game playable, but never write over a
    -- record we could not lock.
    self.profiles[player]={key=key,offline=true}
    return Economy.new(),"offline"
end

-- Write the account. release=true clears our lock (player left / shutdown).
function Save:save(player,account,release)
    local profile=self.profiles[player]
    if not profile or profile.offline or not self.store or not account then return false end
    while profile.saving do self.wait(.1) end
    profile.saving=true
    local payload=Schema.serialize(account)
    local written=false
    local ok,err=pcall(function()
        self.store:UpdateAsync(profile.key,function(old)
            local now=self.now()
            if type(old)=="table" and type(old.lock)=="table" and old.lock.job~=self.jobId and fresh(old.lock,now,self.jobId) then
                return nil -- another server owns this player now; never overwrite it
            end
            written=true
            return {data=payload,lock=if release then nil else {job=self.jobId,time=now},savedAt=now}
        end)
    end)
    profile.saving=false
    if not ok then warn("[Catch the Scrap] Save failed: "..tostring(err)) end
    return ok and written
end

function Save:release(player,account)
    self.pending+=1
    local ok=self:save(player,account,true)
    self.profiles[player]=nil
    self.pending-=1
    return ok
end

function Save:isOffline(player)
    local profile=self.profiles[player]
    return profile==nil or profile.offline==true
end

-- accounts: function returning {[player]=account} for autosave/shutdown.
function Save:startAutosave(accounts)
    task.spawn(function()
        while not self.closing do
            self.wait(Config.Save.AutosaveSeconds)
            for player,account in accounts() do
                if self.profiles[player] then task.spawn(function() self:save(player,account,false) end) end
            end
        end
    end)
end

function Save:shutdown(accounts)
    self.closing=true
    for player,account in accounts() do
        if self.profiles[player] then task.spawn(function() self:release(player,account) end) end
    end
    local waited=0
    while self.pending>0 and waited<25 do self.wait(.25);waited+=.25 end
end

return Save
