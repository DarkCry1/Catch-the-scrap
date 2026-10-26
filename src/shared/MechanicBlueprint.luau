--!strict
-- Original compact roadside service stand. Front is local +Z, toward the street.
export type Part = {name:string,size:{number},position:{number},palette:string,material:string,collidable:boolean?}
local parts: {Part}={
    {name="ServiceDeck",size={24,.5,17},position={0,.25,0},palette="dark",material="Concrete"},
    {name="DeckInset",size={22,.1,15},position={0,.55,0},palette="floor",material="DiamondPlate"},
    {name="Counter",size={17,2.7,3},position={0,1.9,4},palette="steel",material="Metal"},
    {name="CounterTop",size={18,.35,4},position={0,3.4,4},palette="dark",material="Metal"},
    {name="CounterTrim",size={18,.25,.25},position={0,3.5,6.1},palette="amber",material="Neon"},
    {name="LeftPost",size={1,9.5,1},position={-10.5,5.25,-6},palette="steel",material="Metal"},
    {name="RightPost",size={1,9.5,1},position={10.5,5.25,-6},palette="steel",material="Metal"},
    {name="ServiceCanopy",size={25,.6,13},position={0,10.2,-1},palette="dark",material="Metal"},
    {name="CanopyEdge",size={25,.35,.35},position={0,10.3,5.7},palette="amber",material="Neon"},
    {name="ToolCabinet",size={5,4.4,2.5},position={-7,2.8,-5},palette="copper",material="Metal"},
    {name="CabinetTop",size={5.4,.2,3},position={-7,5.1,-5},palette="dark",material="Metal"},
    {name="BatteryRack",size={4,3.4,3},position={7.5,2.3,-5},palette="steel",material="Metal"},
    {name="BatteryLight",size={3,.4,.2},position={7.5,3,-3.4},palette="energy",material="Neon"},
    {name="ToolTray",size={4,.2,1.5},position={5,3.7,4},palette="copper",material="Metal"},
    {name="WrenchHandle",size={.35,2.7,.35},position={-2.2,3.9,-.4},palette="steel",material="Metal",collidable=false},
    {name="WrenchJawLeft",size={.35,.8,.5},position={-2.65,5.25,-.4},palette="steel",material="Metal",collidable=false},
    {name="WrenchJawRight",size={.35,.8,.5},position={-1.75,5.25,-.4},palette="steel",material="Metal",collidable=false},
    {name="WrenchBridge",size={1.25,.3,.5},position={-2.2,4.95,-.4},palette="steel",material="Metal",collidable=false},
    {name="WorkGoggles",size={1.65,.35,.2},position={0,5.62,-.12},palette="energy",material="Neon",collidable=false},
}
for drawer=0,2 do
    table.insert(parts,{name="ToolDrawer"..drawer,size={4.4,.7,.14},position={-7,1.5+drawer*1.1,-3.65},palette="dark",material="Metal",collidable=false})
    table.insert(parts,{name="DrawerHandle"..drawer,size={1.4,.15,.2},position={-7,1.5+drawer*1.1,-3.5},palette="steel",material="Metal",collidable=false})
end
for rib=-9,9,3 do
    table.insert(parts,{name="CounterReinforcement"..rib,size={.15,2.4,.2},position={rib,1.9,5.6},palette="dark",material="Metal",collidable=false})
end
return parts
