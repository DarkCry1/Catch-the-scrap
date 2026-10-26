--!strict
local Blueprint={}
export type Part={name:string,size:{number},position:{number},color:{number},material:string,shape:string,yaw:number,roll:number}
function Blueprint.build(): {Part}
    local parts:{Part}={}
    local cardboard,tape,dark={166,117,68},{209,170,109},{64,47,33}
    local function add(name:string,size:{number},p:{number},color:{number},material:string?)
        table.insert(parts,{name=name,size=size,position=p,color=color,material=material or "SmoothPlastic",shape="Block",yaw=0,roll=0})
    end
    add("BoxBottom",{4.2,.16,4.2},{0,-2,0},cardboard)
    for _,side in {-1,1} do
        add("BoxSide",{.14,4,4.2},{side*2.03,0,0},cardboard)
        add("BoxFace",{4,4,.14},{0,0,side*2.03},cardboard)
        add(if side==-1 then "FlapLeft" else "FlapRight",{2.08,.14,4.2},{side*1.04,2.08,0},cardboard)
        add("PackingTape",{.5,4,.05},{side*.2,0,side*2.12},tape)
        add("TopTape",{.42,.05,4.15},{side*.2,2.18,0},tape)
        add("EdgeSeam",{.06,3.9,.05},{side*1.87,0,2.12},dark)
        for seam=-1,1 do add("Corrugation",{.05,3.8,.05},{side*2.12,0,seam*1.2},tape) end
        add("WearMark",{.7,.08,.05},{side*1.3,-1.5,2.12},tape)
    end
    add("ShippingLabel",{1.85,1.5,.05},{.55,.4,2.14},{230,221,193})
    for line=0,5 do add("Barcode",{.07+(line%2)*.06,.48,.05},{line*.2,.25,2.18},dark) end
    -- Stamped little robot face: a hint, while the actual tier stays secret.
    add("RobotStamp",{1,.75,.05},{-1.05,.5,2.14},dark)
    for _,side in {-1,1} do add("StampEye",{.18,.18,.05},{-1.05+side*.25,.57,2.18},tape) end
    add("StampAntenna",{.1,.3,.05},{-1.05,1.02,2.14},dark)
    return parts
end
function Blueprint.clearance(): number return 2.3 end
return Blueprint
