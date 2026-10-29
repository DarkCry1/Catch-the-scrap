--!strict
local Rules={}
function Rules.assetId(value:any): string?
    if type(value)~="string" then return nil end
    local id=string.match(value,"^rbxassetid://([1-9]%d*)$") or string.match(value,"^([1-9]%d*)$")
    return if id then "rbxassetid://"..id else nil
end
function Rules.volume(settings:{Volume:number,DuckChase:number,DuckCinematic:number},chased:boolean,cinematic:boolean,muted:boolean): number
    if muted then return 0 end
    local factor=1
    if chased then factor=math.min(factor,settings.DuckChase) end
    if cinematic then factor=math.min(factor,settings.DuckCinematic) end
    return math.clamp(settings.Volume*factor,0,1)
end
return Rules
