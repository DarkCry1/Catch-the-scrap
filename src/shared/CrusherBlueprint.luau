--!strict
export type Part={name:string,size:{number},position:{number},color:{number},material:string,shape:string,pitch:number,yaw:number,roll:number}
export type Rotor={position:{number},parts:{Part},direction:number}
local Blueprint={}
function Blueprint.build(): {housing:{Part},rotors:{Rotor}}
    local layout:{housing:{Part},rotors:{Rotor}}={housing={},rotors={}}
    local steel,dark,amber={125,143,151},{29,39,47},{255,181,61}
    local function add(list:{Part},name:string,size:{number},p:{number},c:{number},material:string?,shape:string?,pitch:number?)
        table.insert(list,{name=name,size=size,position=p,color=c,material=material or "Metal",shape=shape or "Block",pitch=pitch or 0,yaw=0,roll=0})
    end
    add(layout.housing,"CrusherFloor",{10,1,8},{0,1,-12},dark)
    for _,side in {-1,1} do
        add(layout.housing,"CrusherSide",{.6,3.3,8},{side*4.9,2.8,-12},dark)
        add(layout.housing,"HopperSideRim",{.45,.4,8.4},{side*5,4.65,-12},amber)
        add(layout.housing,"HopperEndRim",{10.4,.4,.5},{0,4.65,-12+side*4},amber)
        add(layout.housing,"BearingBlock",{.4,2.3,5.5},{side*5.25,3.1,-12},steel)
        add(layout.housing,"PressColumn",{.7,6.7,.7},{side*5.9,3.85,-13.5},steel)
        add(layout.housing,"PressPiston",{.35,3,.35},{side*3.4,7.2,-12},steel)
        for z=-14,-10,2 do add(layout.housing,"HousingBolt",{.14,.3,.3},{side*5.5,3,z},amber,"Metal","Cylinder") end
    end
    add(layout.housing,"FrontGrille",{9.2,2.3,.4},{0,2.6,-8.2},steel)
    for x=-3.6,3.6,1.2 do add(layout.housing,"GrilleSlot",{.55,.9,.08},{x,2.6,-7.96},dark) end
    add(layout.housing,"BackHousing",{9.4,2.7,.4},{0,2.7,-15.8},dark)
    add(layout.housing,"PressCrossbar",{13,1,1.2},{0,7.3,-13.5},dark)
    add(layout.housing,"PressPlate",{8.7,.4,5.7},{0,6.1,-12},steel)
    add(layout.housing,"PressEdge",{8.8,.25,.16},{0,5.9,-9.1},amber)
    for _,side in {-1,1} do
        local rotor:Rotor={position={0,3.75,-12+side*1.35},parts={},direction=side}
        add(rotor.parts,"DriveShaft",{9,.5,.5},{0,0,0},dark,"Metal","Cylinder")
        for saw=0,5 do
            local x=-3.6+saw*1.44
            add(rotor.parts,"CuttingDisc",{.24,2.25,2.25},{x,0,0},steel,"Metal","Cylinder")
            for tooth=0,4 do
                local a=(tooth/5+saw*.07)*math.pi*2
                add(rotor.parts,"CuttingTooth",{.38,.45,.6},{x,math.cos(a)*1.2,math.sin(a)*1.2},if saw%2==0 then steel else amber,"Metal","Block",math.deg(a))
            end
        end
        table.insert(layout.rotors,rotor)
    end
    return layout
end
return Blueprint
