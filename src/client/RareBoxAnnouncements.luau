--!nonstrict
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local Config=require(game:GetService("ReplicatedStorage").CatchTheScrapShared.Config)
local Visuals=require(script.Parent.RarityVisuals)
local Stack=require(script.Parent.TopStack)
local Audio=require(script.Parent.Audio)
local Announcements={}
function Announcements.start(player,remote)
    local gui=Instance.new("ScreenGui");gui.Name="RareRobotEvents";gui.ResetOnSpawn=false;gui.DisplayOrder=30;gui.Parent=player:WaitForChild("PlayerGui")
    local banner=Instance.new("CanvasGroup");banner.AnchorPoint=Vector2.new(.5,0);banner.Position=UDim2.new(.5,0,0,-140)
    banner.Size=UDim2.new(.9,0,0,118);banner.BackgroundColor3=Color3.fromRGB(14,23,37);banner.BackgroundTransparency=.08;banner.Visible=false;banner.Parent=gui
    local max=Instance.new("UISizeConstraint");max.MaxSize=Vector2.new(820,118);max.Parent=banner
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,14);corner.Parent=banner
    local stroke=Instance.new("UIStroke");stroke.Thickness=2;stroke.Parent=banner
    local scale=Instance.new("UIScale");scale.Parent=banner
    local slot=Stack.add(banner,118)
    local function text(parent,size,pos,height)
        local label=Instance.new("TextLabel");label.BackgroundTransparency=1;label.Font=Enum.Font.GothamBold;label.TextSize=size;label.AutoLocalize=false
        label.TextWrapped=true;label.Position=UDim2.new(0,14,0,pos);label.Size=UDim2.new(1,-28,0,height);label.TextColor3=Color3.new(1,1,1);label.Parent=parent;return label
    end
    local tag=text(banner,12,9,16);tag.Text="SERVER EVENT / ROBOT RECOVERY"
    local title=text(banner,28,30,48)
    title.TextScaled=true
    local fontSize=Instance.new("UITextSizeConstraint");fontSize.MinTextSize=16;fontSize.MaxTextSize=28;fontSize.Parent=title
    local sub=text(banner,14,81,25)
    local ticker=text(gui,13,0,20);ticker.AnchorPoint=Vector2.new(.5,0);ticker.Position=UDim2.new(.5,0,0,8);ticker.Size=UDim2.new(.65,0,0,20)
    ticker.TextStrokeTransparency=.35
    local serial=0;local seen={}
    local function receive(channel,packet)
        if (channel~="RareBoxSpawned" and channel~="RobotUnboxed" and channel~="RobotBuilt") or type(packet)~="table" then return end
        if channel=="RareBoxSpawned" and seen[packet.id] then return end
        local recipe=Config.Robot.Recipes[packet.rarity]
        if not recipe then return end
        if channel=="RareBoxSpawned" then seen[packet.id]=true end;serial+=1;local version=serial
        Visuals.apply(banner,packet.rarity)
        banner:SetAttribute("ActiveRarity",packet.rarity)
        local tint=Color3.fromRGB(unpack(recipe.Color));title.Text=(if packet.rarity=="Epic" then "An " else "A ")..packet.rarity.." Robot Box has spawned!"
        title.TextColor3=tint;stroke.Color=tint;sub.Text=string.format("STAGE %02d / %s — Find the beacon and bring it home!",packet.stage or 0,(packet.district or ""):upper())
        if channel=="RobotUnboxed" or channel=="RobotBuilt" then tag.Text=if channel=="RobotBuilt" then "ROBOT ASSEMBLED!" else "ROBOT RECOVERED!";title.Text=packet.name;sub.Text=packet.rarity:upper().." / +$"..packet.income.." PER SECOND" else tag.Text="SERVER EVENT / ROBOT RECOVERY" end
        banner.Visible=true;banner.GroupTransparency=0;scale.Scale=.9
        Stack.show(slot)
        TweenService:Create(scale,TweenInfo.new(.4,Enum.EasingStyle.Back),{Scale=1}):Play()
        if channel=="RareBoxSpawned" then Audio.play("Open") end
        task.delay(7,function()
            if version~=serial then return end
            TweenService:Create(banner,TweenInfo.new(.45),{GroupTransparency=1}):Play()
            task.delay(.45,function() if version==serial then Stack.hide(slot) end end)
            task.delay(.9,function() if version==serial then banner.Visible=false end end)
        end)
    end
    remote.OnClientEvent:Connect(receive)
    for index=1,Config.Crates.LiveLimit do
        local prefix="RareBox"..index
        local function current()
            local id=remote:GetAttribute(prefix.."Id")
            if type(id)~="string" or id=="" then return end
            receive("RareBoxSpawned",{id=id,rarity=remote:GetAttribute(prefix.."Rarity"),stage=remote:GetAttribute(prefix.."Stage"),district=remote:GetAttribute(prefix.."District"),time=remote:GetAttribute(prefix.."Time")})
        end
        remote:GetAttributeChangedSignal(prefix.."Id"):Connect(function() task.defer(current) end)
        current()
    end
    RunService.RenderStepped:Connect(function()
        if banner.Visible and banner:GetAttribute("ActiveRarity")=="Celestial" then title.TextColor3=Visuals.color("Celestial",os.clock()) end
    end)
    local elapsed=0
    RunService.Heartbeat:Connect(function(dt)
        elapsed+=dt;if elapsed<1 then return end;elapsed=0
        local nextAt=remote:GetAttribute("NextRareBoxAt")
        if not nextAt then ticker.Text="";return end
        local seconds=math.max(0,math.ceil(nextAt-workspace:GetServerTimeNow()))
        ticker.Text=if seconds==0 then "RARE ROBOT EVENT / WATCH FOR THE NEXT BEACON" else string.format("NEXT ROBOT BOX EVENT  %02d:%02d",math.floor(seconds/60),seconds%60)
    end)
end
return Announcements
