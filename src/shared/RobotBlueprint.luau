--!strict
-- Original Scrap Bot MK-I. All dimensions are in studs; front is local +Z.
-- Each part is [name, assembly group (1–5), size, position, palette, shape].
export type Part = { name: string, step: number, size: {number}, position: {number}, palette: string, shape: string, yaw: number? }
local parts: {Part} = {
    { name = "LeftBoot", step = 1, size = { 1.6, 0.8, 2.1 }, position = { -1, 0.45, 0.3 }, palette = "dark", shape = "Block" },
    { name = "RightBoot", step = 1, size = { 1.6, 0.8, 2.1 }, position = { 1, 0.45, 0.3 }, palette = "dark", shape = "Block" },
    { name = "LeftToe", step = 1, size = { 1.65, 0.25, 0.6 }, position = { -1, 0.7, 1.1 }, palette = "amber", shape = "Block" },
    { name = "RightToe", step = 1, size = { 1.65, 0.25, 0.6 }, position = { 1, 0.7, 1.1 }, palette = "amber", shape = "Block" },
    { name = "LeftShin", step = 1, size = { 0.85, 1.8, 0.95 }, position = { -1, 1.65, 0 }, palette = "steel", shape = "Block" },
    { name = "RightShin", step = 1, size = { 0.85, 1.8, 0.95 }, position = { 1, 1.65, 0 }, palette = "steel", shape = "Block" },
    { name = "LeftKnee", step = 1, size = { 1.05, 0.65, 0.4 }, position = { -1, 2.1, 0.6 }, palette = "amber", shape = "Block" },
    { name = "RightKnee", step = 1, size = { 1.05, 0.65, 0.4 }, position = { 1, 2.1, 0.6 }, palette = "amber", shape = "Block" },
    { name = "Pelvis", step = 2, size = { 2.8, 0.85, 1.5 }, position = { 0, 2.8, 0 }, palette = "dark", shape = "Block" },
    { name = "Belt", step = 2, size = { 3, 0.22, 1.7 }, position = { 0, 3.15, 0 }, palette = "amber", shape = "Block" },
    { name = "Torso", step = 2, size = { 3.4, 2.6, 1.8 }, position = { 0, 4.45, 0 }, palette = "steel", shape = "Block" },
    { name = "LeftRib", step = 2, size = { 0.35, 1.9, 2 }, position = { -1.75, 4.4, 0 }, palette = "dark", shape = "Block" },
    { name = "RightRib", step = 2, size = { 0.35, 1.9, 2 }, position = { 1.75, 4.4, 0 }, palette = "dark", shape = "Block" },
    { name = "ChestPlate", step = 5, size = { 2.5, 1.6, 0.3 }, position = { 0, 4.6, 1.02 }, palette = "amber", shape = "Block" },
    { name = "ReactorSocket", step = 5, size = { 1.25, 1.25, 0.35 }, position = { 0, 4.6, 1.22 }, palette = "dark", shape = "Block" },
    { name = "Reactor", step = 5, size = { 0.85, 0.85, 0.4 }, position = { 0, 4.6, 1.42 }, palette = "energy", shape = "Ball" },
    { name = "LeftShoulder", step = 3, size = { 1.3, 0.95, 1.9 }, position = { -2.25, 5.15, 0 }, palette = "amber", shape = "Block" },
    { name = "LeftArm", step = 3, size = { 0.8, 1.6, 0.85 }, position = { -2.3, 4.25, 0 }, palette = "steel", shape = "Block" },
    { name = "LeftForearm", step = 3, size = { 1.05, 1.35, 1.1 }, position = { -2.3, 3.15, 0.2 }, palette = "dark", shape = "Block" },
    { name = "LeftHand", step = 3, size = { 1.25, 0.65, 1.3 }, position = { -2.3, 2.35, 0.25 }, palette = "amber", shape = "Block" },
    { name = "RightShoulder", step = 3, size = { 1.3, 0.95, 1.9 }, position = { 2.25, 5.15, 0 }, palette = "amber", shape = "Block" },
    { name = "RightArm", step = 3, size = { 0.8, 1.6, 0.85 }, position = { 2.3, 4.25, 0 }, palette = "steel", shape = "Block" },
    { name = "RightForearm", step = 3, size = { 1.05, 1.35, 1.1 }, position = { 2.3, 3.15, 0.2 }, palette = "dark", shape = "Block" },
    { name = "RightHand", step = 3, size = { 1.25, 0.65, 1.3 }, position = { 2.3, 2.35, 0.25 }, palette = "amber", shape = "Block" },
    { name = "Neck", step = 4, size = { 0.8, 0.45, 0.8 }, position = { 0, 5.85, 0 }, palette = "dark", shape = "Block" },
    { name = "Head", step = 4, size = { 2.35, 1.7, 1.85 }, position = { 0, 6.8, 0 }, palette = "steel", shape = "Block" },
    { name = "Brow", step = 4, size = { 2.55, 0.3, 2.05 }, position = { 0, 7.5, 0 }, palette = "amber", shape = "Block" },
    { name = "Visor", step = 4, size = { 1.95, 0.65, 0.2 }, position = { 0, 6.95, 0.98 }, palette = "dark", shape = "Block" },
    { name = "LeftEye", step = 5, size = { 0.55, 0.3, 0.18 }, position = { -0.5, 6.97, 1.13 }, palette = "energy", shape = "Block" },
    { name = "RightEye", step = 5, size = { 0.55, 0.3, 0.18 }, position = { 0.5, 6.97, 1.13 }, palette = "energy", shape = "Block" },
    { name = "Jaw", step = 4, size = { 1.3, 0.25, 0.25 }, position = { 0, 6.35, 1.02 }, palette = "dark", shape = "Block" },
    { name = "Antenna", step = 5, size = { 0.15, 0.8, 0.15 }, position = { 0.75, 8.05, 0 }, palette = "dark", shape = "Block" },
    { name = "AntennaLight", step = 5, size = { 0.4, 0.4, 0.4 }, position = { 0.75, 8.6, 0 }, palette = "energy", shape = "Ball" },
    { name = "Backpack", step = 5, size = { 1.8, 1.8, 0.7 }, position = { 0, 4.6, -1.1 }, palette = "dark", shape = "Block" },
    { name = "Exhaust", step = 5, size = { 0.65, 1.6, 0.65 }, position = { -0.6, 5.45, -1.3 }, palette = "copper", shape = "Block" },
}

for _,side in {-1,1} do
    for _,y in {4.0,5.15} do
        table.insert(parts,{name="ChestRivet"..side..y,step=5,size={.16,.23,.23},position={side*1.0,y,1.24},palette="dark",shape="Cylinder",yaw=90})
    end
    table.insert(parts,{name="ShoulderInset"..side,step=3,size={.5,.3,.15},position={side*2.25,5.15,1.03},palette="dark",shape="Block"})
end
for _,y in {3.9,4.2} do
    table.insert(parts,{name="BackVent"..y,step=5,size={1.2,.13,.1},position={0,y,-1.5},palette="black",shape="Block"})
end
return parts
