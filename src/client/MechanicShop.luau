--!nonstrict
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local Config=require(game:GetService("ReplicatedStorage"):WaitForChild("CatchTheScrapShared"):WaitForChild("Config"))
local MechanicShop={}

function MechanicShop.start(player,remote,hud)
    local gui=Instance.new("ScreenGui")
    gui.Name="MechanicShop";gui.ResetOnSpawn=false;gui.Enabled=false;gui.DisplayOrder=10
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=player:WaitForChild("PlayerGui")
    local dim=Instance.new("Frame")
    dim.Size=UDim2.fromScale(1,1);dim.BackgroundColor3=Color3.fromRGB(5,10,17);dim.BackgroundTransparency=.28
    dim.Parent=gui
    local backdrop=Instance.new("TextButton")
    backdrop.Size=UDim2.fromScale(1,1);backdrop.BackgroundTransparency=1;backdrop.Text=""
    backdrop.AutoButtonColor=false;backdrop.Parent=dim
    local panel=Instance.new("Frame")
    panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.new(1,-32,1,-24)
    panel.BackgroundColor3=Color3.fromRGB(19,29,40);panel.ZIndex=2;panel.Parent=dim
    local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(560,410);limit.Parent=panel
    local function round(object,radius)
        local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,radius);corner.Parent=object
    end
    round(panel,14)
    local outline=Instance.new("UIStroke");outline.Color=Color3.fromRGB(101,125,140);outline.Parent=panel
    local function label(parent,text,color,size)
        local obj=Instance.new("TextLabel")
        obj.BackgroundTransparency=1;obj.Text=text;obj.TextColor3=color;obj.Font=Enum.Font.Gotham
        obj.TextSize=size;obj.TextWrapped=true;obj.TextXAlignment=Enum.TextXAlignment.Left;obj.AutoLocalize=false;obj.Parent=parent
        return obj
    end
    local title=label(panel,"MILO'S WORKSHOP",Color3.fromRGB(255,198,80),22)
    title.Font=Enum.Font.GothamBold;title.Position=UDim2.fromOffset(18,12);title.Size=UDim2.new(1,-76,0,26)
    local subtitle=label(panel,"Better gear. Faster scrap runs.",Color3.fromRGB(190,207,220),13)
    subtitle.Position=UDim2.fromOffset(18,42);subtitle.Size=UDim2.new(1,-36,0,20)
    local wallet=label(panel,"YOUR CASH  $0",Color3.fromRGB(105,235,180),22)
    wallet.Font=Enum.Font.GothamBold;wallet.Position=UDim2.fromOffset(18,66);wallet.Size=UDim2.new(1,-36,0,26)
    local closeButton=Instance.new("TextButton")
    closeButton.AnchorPoint=Vector2.new(1,0);closeButton.Position=UDim2.new(1,-12,0,12);closeButton.Size=UDim2.fromOffset(36,32)
    closeButton.BackgroundColor3=Color3.fromRGB(48,64,78);closeButton.Text="X";closeButton.TextColor3=Color3.new(1,1,1)
    closeButton.Font=Enum.Font.GothamBold;closeButton.TextSize=16;closeButton.Modal=true;closeButton.AutoLocalize=false;closeButton.Parent=panel;round(closeButton,8)
    local body=Instance.new("Frame")
    body.Position=UDim2.fromOffset(16,102);body.Size=UDim2.new(1,-32,1,-144);body.BackgroundTransparency=1;body.Parent=panel
    local status=label(panel,"Spend your robot income on better gear.",Color3.fromRGB(204,216,225),11)
    status.Position=UDim2.new(0,18,1,-33);status.Size=UDim2.new(1,-36,0,25)
    local cards={}
    local offers={}
    local cash=0
    local pending=false
    local hudWasEnabled=true
    local function close()
        if gui.Enabled then hud.Enabled=hudWasEnabled end
        gui.Enabled=false;pending=false
    end
    closeButton.Activated:Connect(close)
    backdrop.Activated:Connect(close)
    -- The panel consumes clicks so clicking its empty space does not dismiss it.
    panel.Active=true
    local function render()
        wallet.Text=string.format("YOUR CASH  $%d",cash)
        for kind,card in cards do
            local offer=offers[kind]
            if not offer then continue end
            card.name.Text=string.format("%s  LV %d/%d",offer.label:upper(),offer.level,offer.maxLevel)
            card.value.Text=if offer.maxed then tostring(offer.currentValue).."  MAX" else string.format("%d  ->  %d",offer.currentValue,offer.nextValue)
            card.description.Text=offer.description
            local enabled=not pending and not offer.maxed and cash>=offer.cost
            card.button.Active=enabled;card.button.AutoButtonColor=enabled
            card.button.BackgroundColor3=if enabled then card.color else Color3.fromRGB(51,65,77)
            card.button.TextColor3=if enabled then Color3.fromRGB(12,23,30) else Color3.fromRGB(158,176,188)
            card.button.Text=if offer.maxed then "MAXED" elseif pending then "..." else "Buy  $"..offer.cost
        end
    end
    for index,kind in {"Speed","Strength"} do
        local color=if kind=="Speed" then Color3.fromRGB(105,222,231) else Color3.fromRGB(255,193,80)
        local frame=Instance.new("Frame")
        frame.Position=UDim2.new(0,0,(index-1)*.5,(index-1)*5);frame.Size=UDim2.new(1,0,.5,-5)
        frame.BackgroundColor3=Color3.fromRGB(30,44,58);frame.Parent=body;round(frame,10)
        local name=label(frame,kind,color,12);name.Font=Enum.Font.GothamBold
        local value=label(frame,"",Color3.fromRGB(235,241,246),19);value.Font=Enum.Font.GothamBold
        local description=label(frame,"",Color3.fromRGB(176,197,211),11)
        local button=Instance.new("TextButton")
        button.AnchorPoint=Vector2.new(1,.5);button.Position=UDim2.new(1,-12,.5,0);button.Size=UDim2.fromOffset(112,44)
        button.Font=Enum.Font.GothamBold;button.TextSize=14;button.AutoLocalize=false;button.Parent=frame;round(button,9)
        local function layoutCard()
            local center=frame.AbsoluteSize.Y/2
            name.Position=UDim2.fromOffset(12,center-28);name.Size=UDim2.new(1,-148,0,16)
            value.Position=UDim2.fromOffset(12,center-10);value.Size=UDim2.new(1,-148,0,22)
            description.Position=UDim2.fromOffset(12,center+14);description.Size=UDim2.new(1,-148,0,22)
        end
        frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutCard);layoutCard()
        cards[kind]={name=name,value=value,description=description,button=button,color=color}
        button.Activated:Connect(function()
            local offer=offers[kind]
            if pending or not offer or offer.maxed or cash<offer.cost then return end
            pending=true;status.Text="Milo is fitting your upgrade...";render()
            remote:FireServer("BuyUpgrade",kind,offer.level)
        end)
    end
    remote.OnClientEvent:Connect(function(channel,data)
        if channel~="MechanicShop" or typeof(data)~="table" then return end
        if not data.open then close();return end
        if data.mode~="open" and not gui.Enabled then return end
        if typeof(data.offers)~="table" then return end
        if not gui.Enabled then hudWasEnabled=hud.Enabled end
        offers={}
        for _,offer in data.offers do offers[offer.kind]=offer end
        cash=data.cash;pending=false;status.Text=data.message or "Upgrades last for this server session."
        gui.Enabled=true;hud.Enabled=false;render()
    end)
    player:GetAttributeChangedSignal("Cash"):Connect(function()
        cash=player:GetAttribute("Cash") or cash
        if gui.Enabled then render() end
    end)
    player.CharacterRemoving:Connect(close)
    UserInputService.InputBegan:Connect(function(input,processed)
        if not processed and input.KeyCode==Enum.KeyCode.Escape and gui.Enabled then close() end
    end)
    local elapsed=0
    RunService.Heartbeat:Connect(function(dt)
        if not gui.Enabled then return end
        elapsed+=dt;if elapsed<.2 then return end;elapsed=0
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local world=workspace:FindFirstChild("CatchTheScrapWorld")
        local stand=world and world:FindFirstChild("MechanicStand")
        local target=stand and stand:FindFirstChild("Interaction")
        if not root or not target or (root.Position-target.Position).Magnitude>Config.UpgradeDistance then close() end
    end)
end

return MechanicShop
