--!nonstrict
-- Daily quests panel (left dock, under the Robotdex). Three quests per day and
-- a bonus robot box for finishing all three. Buttons send intent only.
local Prompts=game:GetService("ProximityPromptService")
local Kit=require(script.Parent.UiKit)
local Audio=require(script.Parent.Audio)
local Panel={}

local function clock(seconds)
    seconds=math.max(0,math.floor(seconds))
    return string.format("%dh %02dm",math.floor(seconds/3600),math.floor(seconds%3600/60))
end

function Panel.start(player,remote,hud)
    local playerGui=player:WaitForChild("PlayerGui")
    local launcherGui,launcher,sub,badge=Kit.launcher(playerGui,"Quests","DAILY",58)
    local gui,page,close,status=Kit.panel(playerGui,"DailyQuests","DAILY QUESTS",Vector2.new(480,470))
    local data=nil
    local receivedAt=os.clock()
    local render
    local function row(y,height)
        local f=Kit.frame(page,Color3.fromRGB(246,240,224),UDim2.fromOffset(12,y),UDim2.new(1,-24,0,height));Kit.corner(f,8);Kit.stroke(f,Color3.fromRGB(196,180,150),1);return f
    end
    render=function()
        for _,c in page:GetChildren() do if not c:IsA("UICorner") then c:Destroy() end end
        if not data then Kit.text(page,"Loading quests...",14,Kit.MUTED,UDim2.fromOffset(14,14),UDim2.new(1,-28,0,20));return end
        local left=data.resetIn-(os.clock()-receivedAt)
        Kit.text(page,"New quests in "..clock(left),12,Kit.MUTED,UDim2.fromOffset(14,10),UDim2.new(1,-28,0,16),Enum.Font.GothamBold)
        local y=34
        for i,q in data.quests do
            local done=q.progress>=q.target
            local f=row(y,78)
            Kit.text(f,q.text,14,Kit.INK,UDim2.fromOffset(10,8),UDim2.new(1,-130,0,34),Enum.Font.GothamBold)
            Kit.text(f,"Reward "..Kit.money(q.reward),12,Kit.GREEN,UDim2.fromOffset(10,44),UDim2.new(1,-130,0,14),Enum.Font.GothamBold)
            local bar=Kit.frame(f,Color3.fromRGB(214,202,176),UDim2.new(0,10,1,-14),UDim2.new(1,-130,0,6));Kit.corner(bar,3)
            local fill=Kit.frame(bar,Kit.BRASS,UDim2.new(),UDim2.fromScale(math.min(1,q.progress/q.target),1));Kit.corner(fill,3)
            local label=if q.claimed then "CLAIMED" elseif done then "CLAIM" else string.format("%d / %d",q.progress,q.target)
            local b=Kit.button(f,label,UDim2.new(1,-112,.5,-17),UDim2.fromOffset(100,34),if done and not q.claimed then Kit.GREEN elseif q.claimed then Color3.fromRGB(150,140,120) else Color3.fromRGB(196,184,158),if done or q.claimed then Color3.new(1,1,1) else Kit.INK)
            b.Active=done and not q.claimed;b.AutoButtonColor=b.Active
            if b.Active then local index=i;b.Activated:Connect(function() status.Text="Claiming...";remote:FireServer("ClaimQuest",index) end) end
            y+=86
        end
        local f=row(y,70)
        Kit.text(f,"DAILY BONUS",13,Kit.INK,UDim2.fromOffset(10,8),UDim2.new(1,-130,0,16),Enum.Font.GothamBlack)
        Kit.text(f,"Finish all three quests for a free "..data.bonusBox.." Robot Box (needs a free platform).",11,Kit.MUTED,UDim2.fromOffset(10,26),UDim2.new(1,-130,0,34))
        local label=if data.bonusClaimed then "CLAIMED" elseif data.bonusReady then "OPEN BOX" else "LOCKED"
        local b=Kit.button(f,label,UDim2.new(1,-112,.5,-17),UDim2.fromOffset(100,34),if data.bonusReady then Kit.GREEN else Color3.fromRGB(196,184,158),if data.bonusReady then Color3.new(1,1,1) else Kit.INK)
        b.Active=data.bonusReady==true;b.AutoButtonColor=b.Active
        if b.Active then b.Activated:Connect(function() status.Text="Opening...";remote:FireServer("ClaimQuest",0) end) end
    end
    local hudEnabled,promptEnabled=true,true
    local function hide()
        if not gui.Enabled then return end
        Audio.play("Close");gui.Enabled=false;hud.Enabled=hudEnabled;Prompts.Enabled=promptEnabled
    end
    local function open()
        if gui.Enabled then hide();return end
        if not hud.Enabled then return end
        hudEnabled,promptEnabled=hud.Enabled,Prompts.Enabled;hud.Enabled=false;Prompts.Enabled=false
        Audio.play("Open");gui.Enabled=true;status.Text="";render();remote:FireServer("RequestQuests")
    end
    launcher.Activated:Connect(open);close.Activated:Connect(hide)
    local function updateLauncher()
        local n=player:GetAttribute("QuestClaimable") or 0
        badge.Visible=n>0;badge.Text=tostring(n)
        if data then
            local done=0;for _,q in data.quests do if q.claimed then done+=1 end end
            sub.Text=done.." / "..#data.quests
        end
    end
    remote.OnClientEvent:Connect(function(channel,packet)
        if channel~="Quests" or type(packet)~="table" or type(packet.quests)~="table" then return end
        data=packet;receivedAt=os.clock()
        if packet.message then status.Text=packet.message end
        updateLauncher()
        if gui.Enabled then render() end
    end)
    player:GetAttributeChangedSignal("QuestClaimable"):Connect(updateLauncher)
    hud:GetPropertyChangedSignal("Enabled"):Connect(function() launcherGui.Enabled=hud.Enabled or gui.Enabled end)
    player.CharacterRemoving:Connect(hide)
    remote:FireServer("RequestQuests")
    return open
end
return Panel
