--!nonstrict
local UserInputService=game:GetService("UserInputService")
local Prompts=game:GetService("ProximityPromptService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Catalog=require(Shared.RobotCatalog)
local Variants=require(Shared.RobotVariants)
local Visuals=require(script.Parent.RarityVisuals)
local Index={}
function Index.start(player,remote,hud)
    local gui=Instance.new("ScreenGui");gui.Name="RobotCollection";gui.ResetOnSpawn=false;gui.DisplayOrder=20;gui.Enabled=false;gui.Parent=player.PlayerGui
    local dim=Instance.new("Frame");dim.Size=UDim2.fromScale(1,1);dim.BackgroundColor3=Color3.fromRGB(5,10,17);dim.BackgroundTransparency=.18;dim.Parent=gui
    local panel=Instance.new("Frame");panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.new(1,-24,1,-24);panel.BackgroundColor3=Color3.fromRGB(17,27,39);panel.Parent=dim
    local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(760,560);limit.Parent=panel
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,14);corner.Parent=panel
    local function label(parent,text,y,height,size)
        local l=Instance.new("TextLabel");l.Text=text;l.BackgroundTransparency=1;l.TextColor3=Color3.fromRGB(225,237,245);l.Font=Enum.Font.Gotham
        l.TextSize=size or 13;l.TextWrapped=true;l.AutoLocalize=false;l.TextXAlignment=Enum.TextXAlignment.Left;l.Position=UDim2.fromOffset(12,y);l.Size=UDim2.new(1,-24,0,height);l.Parent=parent;return l
    end
    local function button(parent,text,position,size,fn)
        local b=Instance.new("TextButton");b.Text=text;b.Position=position;b.Size=size;b.Font=Enum.Font.GothamBold;b.TextSize=12;b.TextColor3=Color3.fromRGB(226,238,245);b.BackgroundColor3=Color3.fromRGB(36,53,69);b.AutoLocalize=false;b.Parent=parent
        local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=b;b.Activated:Connect(fn);return b
    end
    local title=label(panel,"ROBOT INDEX / 0 OF 70",12,26,21);title.Font=Enum.Font.GothamBold;title.Size=UDim2.new(1,-70,0,26)
    local status=label(panel,"Discover robots by building or unboxing. Progress lasts for this visit.",0,32,11);status.Position=UDim2.new(0,12,1,-40)
    local body=Instance.new("ScrollingFrame");body.Position=UDim2.fromOffset(12,96);body.Size=UDim2.new(1,-24,1,-148);body.BackgroundTransparency=1;body.BorderSizePixel=0;body.ScrollBarThickness=4;body.Parent=panel
    local selectedTier,selectedId,workshop="Rare","Bastion",false
    local data={rows={},projects={},found=0,total=70}
    local hudEnabled,promptEnabled=true,true
    local function close()
        if not gui.Enabled then return end
        gui.Enabled=false;hud.Enabled=hudEnabled;Prompts.Enabled=promptEnabled
    end
    button(panel,"X",UDim2.new(1,-48,0,12),UDim2.fromOffset(34,30),close)
    local tierButton,tabButton
    local render
    tierButton=button(panel,"RARE",UDim2.fromOffset(12,52),UDim2.new(.5,-18,0,32),function()
        local index=1;for i,s in Config.Stages do if s.Rarity==selectedTier then index=i end end
        selectedTier=Config.Stages[index%#Config.Stages+1].Rarity;workshop=false;body.CanvasPosition=Vector2.zero;render()
    end)
    tabButton=button(panel,"YOUR PLATFORMS",UDim2.new(.5,6,0,52),UDim2.new(.5,-18,0,32),function() workshop=not workshop;body.CanvasPosition=Vector2.zero;render() end)
    local function preview(parent,row,height)
        local viewport=Instance.new("ViewportFrame");viewport.Size=UDim2.new(1,0,0,height);viewport.BackgroundColor3=Color3.fromRGB(10,19,30);viewport.BorderSizePixel=0;viewport.Ambient=Color3.fromRGB(150,166,190);viewport.LightColor=Color3.fromRGB(255,238,213);viewport.Parent=parent
        Visuals.apply(viewport,selectedTier)
        local world=Instance.new("WorldModel");world.Parent=viewport
        local camera=Instance.new("Camera");camera.CFrame=CFrame.lookAt(Vector3.new(10,7,15),Vector3.new(0,4,0));camera.FieldOfView=38;camera.Parent=viewport;viewport.CurrentCamera=camera
        for _,d in Variants.build(row.id) do
            local p=Instance.new("Part");p.Name=d.name;p.Size=Vector3.new(unpack(d.size));p.CFrame=CFrame.new(unpack(d.position))*CFrame.Angles(math.rad(d.pitch or 0),math.rad(d.yaw or 0),math.rad(d.roll or 0));p.Shape=Enum.PartType[d.shape]
            p.Color=Color3.fromRGB(unpack(if d.palette=="amber" or d.palette=="energy" then Config.Robot.Recipes[selectedTier].Color else Config.Palette[d.palette]));p.Material=if d.palette=="energy" then Enum.Material.Neon else Enum.Material.Metal
            p.Anchored=true;p.CanCollide=false;p.Parent=world
        end
    end
    render=function()
        body:ClearAllChildren();tierButton.Text=selectedTier:upper();tabButton.Text=if workshop then "BACK TO ROBOTS" else "YOUR PLATFORMS"
        title.Text=string.format("ROBOT INDEX / %d OF %d",data.found,data.total);Visuals.apply(panel,selectedTier)
        if workshop then
            body.CanvasSize=UDim2.fromOffset(0,400)
            label(body,"Retire a completed robot at your base to free its platform. Discoveries stay unlocked. No refund.",0,48,12)
            for slot=1,Config.Robot.Slots do
                local project=data.projects[slot]
                local f=Instance.new("Frame");f.Position=UDim2.fromOffset(0,58+(slot-1)*78);f.Size=UDim2.new(1,-8,0,70);f.BackgroundColor3=Color3.fromRGB(29,43,57);f.Parent=body
                local l=label(f,if project then project.name.."\n$"..project.income.." / SEC" else "PLATFORM "..slot.." / AVAILABLE",8,54,13);l.Size=UDim2.new(1,-154,0,54)
                if project and project.complete then
                    local armed=false;local retire
                    retire=button(f,"RETIRE",UDim2.new(1,-136,0,15),UDim2.fromOffset(124,36),function()
                        if armed then armed=false;remote:FireServer("RetireRobot",project.id) else armed=true;retire.Text="CONFIRM RETIRE";task.delay(5,function() if retire.Parent then armed=false;retire.Text="RETIRE" end end) end
                    end)
                end
            end
            return
        end
        local rows={};for _,row in data.rows do if row.rarity==selectedTier then table.insert(rows,row) end end
        if #rows==0 then label(body,"Loading robot collection...",0,50,14);return end
        local current=rows[1];for _,row in rows do if row.id==selectedId then current=row end end
        selectedId=current.id
        local compact=panel.AbsoluteSize.X<620
        local left=Instance.new("Frame");left.BackgroundTransparency=1;left.Position=UDim2.fromOffset(0,0);left.Size=if compact then UDim2.new(1,-8,0,354) else UDim2.new(.44,-8,0,410);left.Parent=body
        local vh=if compact then 190 else 240
        preview(left,current,vh)
        local name=label(left,current.name,vh+6,42,17);name.Font=Enum.Font.GothamBold
        local origin=if current.source=="Both" then "BUILD OR BOX" elseif current.source=="Box" then "BOX EXCLUSIVE" else "BUILD EXCLUSIVE" 
        label(left,origin..(if current.unlocked then " / DISCOVERED" else " / UNDISCOVERED"),vh+48,34,11)
        local income=if current.source=="Build" then "Build: $"..current.buildIncome.."/sec" elseif current.source=="Box" then "Box: $"..current.boxIncome.."/sec" else "Build $"..current.buildIncome.."/sec / Box $"..current.boxIncome.."/sec"
        label(left,income,vh+84,32,12)
        button(left,if current.source=="Box" then "FIND THIS ROBOT IN A BOX" elseif current.selected then "SELECTED FOR NEXT BUILD" else "USE FOR NEXT BUILD",UDim2.fromOffset(12,vh+122),UDim2.new(1,-24,0,38),function()
            if current.source~="Box" then remote:FireServer("SelectBlueprint",selectedTier,current.id) else status.Text="This chassis is box-exclusive. Watch for a "..selectedTier.." box event." end
        end)
        local list=Instance.new("Frame");list.BackgroundTransparency=1;list.Position=if compact then UDim2.fromOffset(0,380) else UDim2.new(.46,0,0,0);list.Size=if compact then UDim2.new(1,-8,0,420) else UDim2.new(.54,-8,0,420);list.Parent=body
        for i,row in rows do
            local text=(if row.unlocked then "✓ " else "○ ")..Catalog.get(row.id).Name.."  / "..row.source:upper()
            local b=button(list,text,UDim2.fromOffset(0,(i-1)*42),UDim2.new(1,0,0,36),function() selectedId=row.id;body.CanvasPosition=Vector2.zero;render() end)
            if row.id==selectedId then Visuals.apply(b,selectedTier) end
        end
        body.CanvasSize=UDim2.fromOffset(0,if compact then 810 else 420)
    end
    local function open()
        if workspace.CurrentCamera and workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable then return end
        if gui.Enabled then close();return end
        if not hud.Enabled then return end
        hudEnabled=hud.Enabled;promptEnabled=Prompts.Enabled;hud.Enabled=false;Prompts.Enabled=false;gui.Enabled=true;render();remote:FireServer("RequestIndex")
    end
    remote.OnClientEvent:Connect(function(channel,packet)
        if channel~="RobotIndex" or type(packet)~="table" then return end
        data=packet;status.Text=packet.message or "Choose a chassis for your next build. Finish robots to discover them."
        if gui.Enabled then render() end
    end)
    UserInputService.InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.I then open() end end)
    player.CharacterRemoving:Connect(close)
    panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if gui.Enabled then render() end end)
    return open
end
return Index
