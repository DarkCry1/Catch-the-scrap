--!nonstrict
local UserInputService=game:GetService("UserInputService")
local Menu={}
function Menu.start(player,remote,hud)
    local gui=Instance.new("ScreenGui");gui.Name="AdminTools";gui.ResetOnSpawn=false;gui.DisplayOrder=40;gui.Parent=player:WaitForChild("PlayerGui")
    local function round(object) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=object end
    local function label(parent,text,pos,size,fontSize)
        local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Text=text;l.TextColor3=Color3.fromRGB(225,236,243)
        l.Position=pos;l.Size=size;l.TextSize=fontSize or 14;l.Font=Enum.Font.GothamBold;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextWrapped=true;l.AutoLocalize=false;l.Parent=parent;return l
    end
    local open=Instance.new("TextButton");open.AnchorPoint=Vector2.new(1,0);open.Position=UDim2.new(1,-16,0,10);open.Size=UDim2.fromOffset(90,34)
    open.Text=if UserInputService.KeyboardEnabled then "ADMIN [F4]" else "ADMIN";open.TextSize=12;open.Font=Enum.Font.GothamBold;open.TextColor3=Color3.fromRGB(255,201,96);open.BackgroundColor3=Color3.fromRGB(23,34,46);open.AutoLocalize=false;open.Parent=gui;round(open)
    local panel=Instance.new("Frame");panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.new(1,-24,1,-32)
    panel.BackgroundColor3=Color3.fromRGB(16,25,36);panel.Visible=false;panel.Active=true;panel.Parent=gui;round(panel)
    local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(600,510);limit.Parent=panel
    label(panel,"ADMIN CONTROL",UDim2.fromOffset(20,14),UDim2.new(1,-90,0,26),21)
    local body=Instance.new("ScrollingFrame");body.Position=UDim2.fromOffset(16,54);body.Size=UDim2.new(1,-32,1,-106);body.CanvasSize=UDim2.fromOffset(0,380);body.BackgroundTransparency=1;body.BorderSizePixel=0;body.ScrollBarThickness=4;body.Parent=panel
    local status=label(panel,"Personal changes affect only you. Events are server-wide.",UDim2.new(0,20,1,-42),UDim2.new(1,-40,0,32),12)
    local function button(parent,text,pos,size,callback)
        local b=Instance.new("TextButton");b.Text=text;b.Position=pos;b.Size=size;b.Font=Enum.Font.GothamBold;b.TextSize=12;b.TextColor3=Color3.fromRGB(18,28,37);b.BackgroundColor3=Color3.fromRGB(105,219,204);b.AutoLocalize=false;b.Parent=parent;round(b);b.Activated:Connect(callback);return b
    end
    local function send(command,value)
        if not player:GetAttribute("CanAdmin") then return end
        status.Text="Applying...";remote:FireServer("Admin",command,value)
    end
    local function toggle()
        if not player:GetAttribute("CanAdmin") then return end
        panel.Visible=not panel.Visible
    end
    button(panel,"X",UDim2.new(1,-52,0,12),UDim2.fromOffset(34,32),toggle)
    open.Activated:Connect(toggle)
    UserInputService.InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.F4 then toggle() end end)
    local function field(title,y,initial)
        label(body,title,UDim2.fromOffset(2,y),UDim2.new(.24,0,0,36),13)
        local t=Instance.new("TextBox");t.Position=UDim2.new(.25,0,0,y);t.Size=UDim2.new(.28,0,0,36);t.Text=initial;t.ClearTextOnFocus=false
        t.BackgroundColor3=Color3.fromRGB(32,47,61);t.TextColor3=Color3.new(1,1,1);t.Font=Enum.Font.Gotham;t.TextSize=15;t.AutoLocalize=false;t.Parent=body;round(t);return t
    end
    local cash=field("CASH",0,"10000")
    button(body,"SET",UDim2.new(.55,0,0,0),UDim2.new(.2,0,0,36),function() send("SetCash",tonumber(cash.Text)) end)
    button(body,"ADD",UDim2.new(.77,0,0,0),UDim2.new(.21,0,0,36),function() send("AddCash",tonumber(cash.Text)) end)
    local speed=field("SPEED",48,"60")
    button(body,"SET SPEED",UDim2.new(.55,0,0,48),UDim2.new(.43,0,0,36),function() send("SetSpeed",tonumber(speed.Text)) end)
    local strength=field("STRENGTH",96,"150")
    button(body,"SET STRENGTH",UDim2.new(.55,0,0,96),UDim2.new(.43,0,0,36),function() send("SetStrength",tonumber(strength.Text)) end)
    button(body,"RESET STATS",UDim2.fromOffset(2,144),UDim2.new(.5,-8,0,36),function() send("ResetStats",0) end)
    button(body,"RETURN TO BASE",UDim2.new(.5,6,0,144),UDim2.new(.5,-14,0,36),function() send("Home",0) end)
    label(body,"SPAWN ROBOT BOX EVENT",UDim2.fromOffset(2,198),UDim2.new(1,-8,0,22),14)
    local tier="Rare";local stage=field("STAGE 1–7",228,"1")
    local tiers={"Rare","Epic","Legendary","Mythic","Celestial"};local selected=1
    local tierButton
    tierButton=button(body,tier,UDim2.new(.55,0,0,228),UDim2.new(.43,0,0,36),function() selected=selected%#tiers+1;tier=tiers[selected];tierButton.Text=tier end)
    button(body,"TRIGGER EVENT",UDim2.fromOffset(2,280),UDim2.new(1,-10,0,44),function() send("Event",{rarity=tier,stage=tonumber(stage.Text)}) end)
    label(body,"Two live boxes maximum. Stats reset when you leave the server.",UDim2.fromOffset(2,336),UDim2.new(1,-10,0,36),11)
    local function access()
        open.Visible=player:GetAttribute("CanAdmin")==true
        if not open.Visible then panel.Visible=false end
    end
    player:GetAttributeChangedSignal("CanAdmin"):Connect(access);access()
    remote.OnClientEvent:Connect(function(channel,data)
        if channel=="AdminResult" and type(data)=="table" then status.Text=data.message;status.TextColor3=if data.ok then Color3.fromRGB(112,232,180) else Color3.fromRGB(255,150,122) end
    end)
end
return Menu
