--!strict
-- Original open-front salvage workshop, local +Z faces the street.
-- [name, size, position, palette, material, collidable, yaw degrees]
export type Part = { name: string, size: {number}, position: {number}, palette: string, material: string, collidable: boolean, yaw: number }
local parts: {Part} = {
    { name = "Foundation", size = { 58, 0.6, 50 }, position = { 0, 0, 0 }, palette = "dark", material = "Concrete", collidable = true, yaw = 0 },
    { name = "WorkshopFloor", size = { 54, 0.18, 46 }, position = { 0, 0.39, 0 }, palette = "floor", material = "DiamondPlate", collidable = true, yaw = 0 },
    { name = "FrontThreshold", size = { 54, 0.15, 3 }, position = { 0, 0.54, 23 }, palette = "steel", material = "Metal", collidable = true, yaw = 0 },
    { name = "LeftWall", size = { 1, 4.5, 48 }, position = { -27.5, 2.55, 0 }, palette = "wall", material = "Metal", collidable = true, yaw = 0 },
    { name = "RightWall", size = { 1, 4.5, 48 }, position = { 27.5, 2.55, 0 }, palette = "wall", material = "Metal", collidable = true, yaw = 0 },
    { name = "BackWall", size = { 54, 9, 1 }, position = { 0, 4.8, -23.5 }, palette = "wall", material = "Metal", collidable = true, yaw = 0 },
    { name = "BackInset", size = { 42, 5, 0.18 }, position = { 0, 5.4, -22.85 }, palette = "dark", material = "Metal", collidable = false, yaw = 0 },
    { name = "BackStripe", size = { 51, 0.35, 0.2 }, position = { 0, 2.1, -22.8 }, palette = "amber", material = "Neon", collidable = false, yaw = 0 },
    { name = "LeftTrim", size = { 0.25, 0.25, 47 }, position = { -26.8, 4.9, 0 }, palette = "accent", material = "Neon", collidable = false, yaw = 0 },
    { name = "RightTrim", size = { 0.25, 0.25, 47 }, position = { 26.8, 4.9, 0 }, palette = "accent", material = "Neon", collidable = false, yaw = 0 },
    { name = "LeftGatePillar", size = { 2.3, 14, 2.5 }, position = { -25.5, 7.3, 23 }, palette = "steel", material = "Metal", collidable = true, yaw = 0 },
    { name = "RightGatePillar", size = { 2.3, 14, 2.5 }, position = { 25.5, 7.3, 23 }, palette = "steel", material = "Metal", collidable = true, yaw = 0 },
    { name = "LeftGateLight", size = { 0.3, 11.5, 0.3 }, position = { -24.2, 7.1, 24.4 }, palette = "accent", material = "Neon", collidable = false, yaw = 0 },
    { name = "RightGateLight", size = { 0.3, 11.5, 0.3 }, position = { 24.2, 7.1, 24.4 }, palette = "accent", material = "Neon", collidable = false, yaw = 0 },
    { name = "GateHeader", size = { 54, 4, 3 }, position = { 0, 13.2, 23 }, palette = "dark", material = "Metal", collidable = true, yaw = 0 },
    { name = "HeaderEdge", size = { 53, 0.3, 0.3 }, position = { 0, 15.35, 24.6 }, palette = "amber", material = "Neon", collidable = false, yaw = 0 },
    { name = "RearCanopy", size = { 57, 0.8, 15 }, position = { 0, 12.8, -17 }, palette = "dark", material = "Metal", collidable = true, yaw = 0 },
    { name = "CanopyLip", size = { 57, 0.5, 0.5 }, position = { 0, 12.4, -9.5 }, palette = "steel", material = "Metal", collidable = false, yaw = 0 },
    { name = "LeftRearColumn", size = { 2, 12, 2 }, position = { -26, 6.4, -22 }, palette = "steel", material = "Metal", collidable = true, yaw = 0 },
    { name = "RightRearColumn", size = { 2, 12, 2 }, position = { 26, 6.4, -22 }, palette = "steel", material = "Metal", collidable = true, yaw = 0 },
    { name = "CanopyLight", size = { 26, 0.18, 0.5 }, position = { 0, 12.25, -16 }, palette = "energy", material = "Neon", collidable = false, yaw = 0 },
    { name = "AisleLeft", size = { 0.15, 0.06, 36 }, position = { -6.8, 0.52, 1 }, palette = "amber", material = "Neon", collidable = false, yaw = 0 },
    { name = "AisleRight", size = { 0.15, 0.06, 36 }, position = { 6.8, 0.52, 1 }, palette = "amber", material = "Neon", collidable = false, yaw = 0 },
    { name = "DepositHousing", size = { 10, 3, 7 }, position = { 0, 1.95, -12 }, palette = "dark", material = "Metal", collidable = true, yaw = 0 },
    { name = "HopperRim", size = { 10.8, 0.5, 7.8 }, position = { 0, 3.7, -12 }, palette = "amber", material = "Metal", collidable = true, yaw = 0 },
    { name = "HopperInside", size = { 8.5, 0.2, 5.7 }, position = { 0, 3.97, -12 }, palette = "black", material = "SmoothPlastic", collidable = false, yaw = 0 },
    { name = "HopperScanner", size = { 7, 0.1, 0.25 }, position = { 0, 4.1, -10 }, palette = "energy", material = "Neon", collidable = false, yaw = 0 },
    { name = "LeftMachineRail", size = { 0.6, 3.5, 0.6 }, position = { -5.8, 2.15, -9 }, palette = "steel", material = "Metal", collidable = true, yaw = 0 },
    { name = "RightMachineRail", size = { 0.6, 3.5, 0.6 }, position = { 5.8, 2.15, -9 }, palette = "steel", material = "Metal", collidable = true, yaw = 0 },
    { name = "ProgressBoard", size = { 12, 4.4, 0.35 }, position = { 0, 7, -16 }, palette = "black", material = "SmoothPlastic", collidable = false, yaw = 0 },
    { name = "LeftToolCabinet", size = { 4, 5, 3 }, position = { -22, 3, -20.5 }, palette = "steel", material = "Metal", collidable = true, yaw = 0 },
    { name = "CabinetDoor", size = { 3.5, 4.2, 0.15 }, position = { -22, 3, -18.9 }, palette = "dark", material = "Metal", collidable = false, yaw = 0 },
    { name = "CabinetHandle", size = { 0.15, 1.2, 0.25 }, position = { -20.8, 3, -18.7 }, palette = "amber", material = "Metal", collidable = false, yaw = 0 },
    { name = "PowerCabinet", size = { 4, 5, 3 }, position = { 22, 3, -20.5 }, palette = "copper", material = "Metal", collidable = true, yaw = 0 },
    { name = "PowerIndicator", size = { 2.4, 0.45, 0.18 }, position = { 22, 4, -18.9 }, palette = "energy", material = "Neon", collidable = false, yaw = 0 },
    { name = "PowerIndicator2", size = { 2.4, 0.45, 0.18 }, position = { 22, 3, -18.9 }, palette = "energy", material = "Neon", collidable = false, yaw = 0 },
}

for _,side in {-1,1} do
    for bay=0,3 do
        table.insert(parts,{name="SalvagedWallPanel",size={.22,3.8,9},position={side*26.9,2.6,-17+bay*11},palette=if bay%2==0 then "rust" else "steel",material="CorrodedMetal",collidable=false,yaw=0})
    end
    for y=1.8,4.2,1.2 do
        table.insert(parts,{name="CabinetVent",size={2.7,.12,.12},position={side*22,y,-18.7},palette="black",material="Metal",collidable=false,yaw=0})
    end
    table.insert(parts,{name="ServiceConduit",size={.3,7,.3},position={side*24.8,4.5,-22.5},palette="copper",material="Metal",collidable=false,yaw=0})
end
for x=-24,24,8 do
    table.insert(parts,{name="RoofPatch",size={6,.12,12},position={x,13.26,-17},palette=if x%16==0 then "rust" else "steel",material="CorrodedMetal",collidable=false,yaw=0})
end
return parts
