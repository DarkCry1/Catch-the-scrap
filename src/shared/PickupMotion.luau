--!strict
local Motion={}
function Motion.sample(time:number,phase:number): (number,number,number,number)
    local wave=time*2.4+phase
    return .35+(math.sin(wave)+1)*.24, time*.55+phase, math.sin(wave*.7)*.055, .72+math.sin(wave)*.18
end
return Motion
