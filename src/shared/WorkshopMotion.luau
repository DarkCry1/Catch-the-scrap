--!strict
local Motion={}
function Motion.crush(t:number): (number,number,number)
    local pull=math.clamp(t/.65,0,1)
    local crush=math.clamp((t-.55)/.7,0,1)
    return 1-(1-pull)^3,1-crush*.94,math.clamp((t-1.25)/.25,0,1)
end
function Motion.unbox(t:number): (number,number,number)
    local open=math.clamp((t-.85)/.85,0,1)
    local shake=math.sin(t*35)*.055*(1-math.clamp(t/.95,0,1))
    local glow=math.clamp((t-1.1)/.6,0,1)
    return shake,(1-(1-open)^3)*math.rad(130),glow
end
return Motion
