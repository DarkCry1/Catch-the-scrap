--!strict
local Frame={}
export type Edge={position:{number},size:{number},phase:number}
function Frame.build(): {Edge}
 local edges:{Edge}={}
 for side=0,3 do for step=0,4 do
    local t=-2.2+(step+.5)*4.4/5
    local p=if side==0 then {t,2.2,2.2} elseif side==1 then {2.2,-t,2.2} elseif side==2 then {-t,-2.2,2.2} else {-2.2,t,2.2}
    table.insert(edges,{position=p,size=if side%2==0 then {.86,.09,.09} else {.09,.86,.09},phase=(side*5+step)/20})
 end end
 return edges
end
return Frame
