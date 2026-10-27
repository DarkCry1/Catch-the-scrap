--!strict
local Motion=require("../src/shared/WorkshopMotion")
local function multiply(a:{number},b:{number}): {number}
    local c={}
    for row=0,2 do for column=0,2 do
        local sum=0
        for k=0,2 do sum+=a[row*3+k+1]*b[k*3+column+1] end
        table.insert(c,sum)
    end end
    return c
end
local function transpose(a:{number}): {number} return {a[1],a[4],a[7],a[2],a[5],a[8],a[3],a[6],a[9]} end
local function angles(x:number,y:number,z:number): {number}
    local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
    return multiply(multiply({1,0,0,0,cx,-sx,0,sx,cx},{cy,0,sy,0,1,0,-sy,0,cy}),{cz,-sz,0,sz,cz,0,0,0,1})
end
local checks=0
for _,nativeYaw in {0,-math.pi/2,math.pi/2} do
    local axes=angles(0,nativeYaw,0)
    for _,side in {-1,1} do
        for frame=0,120 do
            local x,y,z=Motion.arm(frame/10,side)
            local worldRaise=angles(x,y,z)
            local jointRaise=multiply(multiply(transpose(axes),worldRaise),axes)
            -- Motor6D C0 * local pose * C1^-1, with neutral Animator Transform.
            local arm=multiply(multiply(axes,jointRaise),transpose(axes))
            local handY,handZ=-3*arm[5],-3*arm[8]
            assert(handY>2.2 and handZ<-.8,"R6/R15 native shoulder axes must lift hands up and in front of the torso")
            checks+=1
        end
    end
end
print(string.format("R6/R15 overhead shoulder matrix checks passed; %d poses",checks))
