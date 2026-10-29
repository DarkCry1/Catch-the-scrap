--!nonstrict
-- Rebirth panel (left dock). Shows what resets, what is kept and what is
-- gained. The button needs two presses and sends only the rebirth count the
-- player saw; the server decides everything else.
local Prompts=game:GetService("ProximityPromptService")
local Kit=require(script.Parent.UiKit)
local Audio=require(script.Parent.Audio)
local Panel={}

function Panel.start(player,remote,hud)
    local playerGui=player:WaitForChild("PlayerGui")
    local launcherGui,launcher,sub,badge=Kit.launcher(playerGui,"Rebirth","REBIRTH",120)
    local gui,page,close,status=Kit.panel(playerGui,"RebirthPanel","REBIRTH",Vector2.new(480,470))
    local data=nil
    local armed=false
    local shownReady=nil
    local render
    render=function()
        for _,c in page:GetChildren() do if not c:IsA("UICorner") then c:Destroy() end end
        if not data then Kit.text(page,"Loading...",14,Kit.MUTED,UDim2.fromOffset(14,14),UDim2.new(1,-28,0,20));return end
        local y=12
        local function line(value,size,color,font,height)
            Kit.text(page,value,size,color or Kit.INK,UDim2.fromOffset(16,y),UDim2.new(1,-32,0,height or size+6),font);y+=(height or size+6)+6
        end
        line(string.format("REBIRTH %d  →  %d",data.rebirths,math.min(data.rebirths+1,data.max)),22,Kit.INK,Enum.Font.GothamBlack,28)
        line(string.format("Income multiplier  x%.1f  →  x%.1f",data.currentMultiplier,data.nextMultiplier),15,Kit.GREEN,Enum.Font.GothamBold,20)
        line(string.format("Robot platforms  %d  →  %d",data.slots,data.nextSlots),15,Kit.GREEN,Enum.Font.GothamBold,20)
        line("RESETS: cash, every robot on your platforms, Speed and Strength upgrades.",13,Kit.RED,Enum.Font.GothamBold,34)
        line("KEEPS: your Robotdex, every mutation version, claimed rewards, income bonuses, titles, skins and daily quests.",13,Kit.MUTED,Enum.Font.Gotham,52)
        line(string.format("Cost: %s   ·   You have: %s",Kit.money(data.cost),Kit.money(player:GetAttribute("Cash") or data.cash)),15,Kit.INK,Enum.Font.GothamBold,20)
        local ready=data.reason=="" and data.rebirths<data.max and (player:GetAttribute("Cash") or 0)>=data.cost
        shownReady=ready
        local label=if data.rebirths>=data.max then "MAXIMUM REBIRTH" elseif not ready then (if data.reason~="" then "NOT YET" else "NOT ENOUGH CASH") elseif armed then "TAP AGAIN TO REBIRTH" else "REBIRTH FOR "..Kit.money(data.cost)
        local b=Kit.button(page,label,UDim2.new(0,16,1,-62),UDim2.new(1,-32,0,46),if ready then (if armed then Kit.RED else Kit.GREEN) else Color3.fromRGB(196,184,158),if ready then Color3.new(1,1,1) else Kit.INK)
        b.TextSize=16;b.Active=ready;b.AutoButtonColor=ready
        if ready then
            b.Activated:Connect(function()
                if armed then armed=false;status.Text="Rebirthing...";remote:FireServer("Rebirth",data.rebirths)
                else armed=true;render();task.delay(5,function() if armed then armed=false;render() end end) end
            end)
        elseif data.reason~="" then line(data.reason,12,Kit.MUTED,Enum.Font.Gotham,30) end
    end
    local hudEnabled,promptEnabled=true,true
    local function hide()
        if not gui.Enabled then return end
        Audio.play("Close");gui.Enabled=false;armed=false;hud.Enabled=hudEnabled;Prompts.Enabled=promptEnabled
    end
    local function open()
        if gui.Enabled then hide();return end
        if not hud.Enabled then return end
        hudEnabled,promptEnabled=hud.Enabled,Prompts.Enabled;hud.Enabled=false;Prompts.Enabled=false
        Audio.play("Open");gui.Enabled=true;status.Text="";render();remote:FireServer("RequestRebirth")
    end
    launcher.Activated:Connect(open);close.Activated:Connect(hide)
    local function updateLauncher()
        local rebirths=player:GetAttribute("Rebirths") or 0
        sub.Text="R"..rebirths
        local ready=data~=nil and data.reason=="" and data.rebirths<data.max and (player:GetAttribute("Cash") or 0)>=data.cost
        badge.Visible=ready;badge.Text="!"
    end
    remote.OnClientEvent:Connect(function(channel,packet)
        -- The rebirth cinematic takes over the screen.
        if channel=="Fx" and type(packet)=="table" and packet.kind=="Rebirth" then hide();return end
        if channel~="Rebirth" or type(packet)~="table" or type(packet.cost)~="number" then return end
        data=packet
        if packet.message then status.Text=packet.message end
        updateLauncher()
        if gui.Enabled then render() end
    end)
    player:GetAttributeChangedSignal("Cash"):Connect(function()
        updateLauncher()
        -- Re-render only when affordability flips, so buttons stay pressable.
        if gui.Enabled and not armed and data then
            local ready=data.reason=="" and data.rebirths<data.max and (player:GetAttribute("Cash") or 0)>=data.cost
            if ready~=shownReady then render() end
        end
    end)
    player:GetAttributeChangedSignal("Rebirths"):Connect(function() updateLauncher();remote:FireServer("RequestRebirth") end)
    hud:GetPropertyChangedSignal("Enabled"):Connect(function() launcherGui.Enabled=hud.Enabled or gui.Enabled end)
    player.CharacterRemoving:Connect(hide)
    return open
end
return Panel
