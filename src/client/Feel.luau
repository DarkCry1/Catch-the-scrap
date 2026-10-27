--!nonstrict
-- Game feel: sounds, deposit popups, build celebrations, drone alarms and the
-- new-player guide beam. Purely cosmetic and local; driven by server "Fx"
-- packets and player attributes. Sounds come from the Audio module.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Style=require(Shared.RarityStyle)
local Mutations=require(Shared.Mutations)
local Parts=require(script.Parent.EffectParts)
local Audio=require(script.Parent.Audio)
local Stack=require(script.Parent.TopStack)
local Feel={}


function Feel.start(player,remote)
    local folder=Instance.new("Folder");folder.Name="LocalFeelEffects";folder.Parent=workspace
    Audio.start()
    Audio.watchCash(player)
    local function play(name) Audio.play(name) end

    -- Floating text above a world position.
    local function popup(position,text,color,size)
        local anchor=Parts.new(folder,"PopupAnchor",Vector3.one*.1,CFrame.new(position),color);anchor.Transparency=1
        local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(260,50);gui.AlwaysOnTop=true;gui.LightInfluence=0;gui.MaxDistance=120;gui.Parent=anchor
        local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text=text;label.TextColor3=color
        label.Font=Enum.Font.GothamBlack;label.TextScaled=true;label.TextStrokeTransparency=.3;label.AutoLocalize=false;label.Parent=gui
        local limit=Instance.new("UITextSizeConstraint");limit.MaxTextSize=size or 28;limit.Parent=label
        TweenService:Create(anchor,TweenInfo.new(1.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=CFrame.new(position+Vector3.new(0,4,0))}):Play()
        TweenService:Create(label,TweenInfo.new(1.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{TextTransparency=1,TextStrokeTransparency=1}):Play()
        game:GetService("Debris"):AddItem(anchor,1.5)
    end

    -- Full-screen tint used for alarms and celebrations.
    local overlayGui=Instance.new("ScreenGui");overlayGui.Name="FeelOverlay";overlayGui.ResetOnSpawn=false;overlayGui.IgnoreGuiInset=true;overlayGui.DisplayOrder=2;overlayGui.Parent=player:WaitForChild("PlayerGui")
    local flash=Instance.new("Frame");flash.Size=UDim2.fromScale(1,1);flash.BackgroundColor3=Color3.fromRGB(255,40,30);flash.BackgroundTransparency=1;flash.BorderSizePixel=0;flash.Parent=overlayGui
    local banner=Instance.new("TextLabel");banner.AnchorPoint=Vector2.new(.5,0);banner.Position=UDim2.new(.5,0,0,-80);banner.Size=UDim2.fromOffset(420,44)
    banner.BackgroundColor3=Color3.fromRGB(120,20,16);banner.BackgroundTransparency=.1;banner.TextColor3=Color3.new(1,1,1);banner.Font=Enum.Font.GothamBlack;banner.TextSize=20
    banner.Text="SECURITY DRONE! RUN!";banner.AutoLocalize=false;banner.Visible=false;banner.Parent=overlayGui
    local bannerCorner=Instance.new("UICorner");bannerCorner.CornerRadius=UDim.new(0,10);bannerCorner.Parent=banner
    banner.Visible=true
    local bannerSlot=Stack.add(banner,44)
    local function pulse(color,strength,seconds)
        flash.BackgroundColor3=color;flash.BackgroundTransparency=1-strength
        TweenService:Create(flash,TweenInfo.new(seconds or .5),{BackgroundTransparency=1}):Play()
    end
    local shakeUntil,shakeStrength=0,0
    local function shake(seconds,strength) shakeUntil=os.clock()+seconds;shakeStrength=strength end

    remote.OnClientEvent:Connect(function(channel,packet)
        if channel~="Fx" or type(packet)~="table" then return end
        local kind=packet.kind
        if kind=="Deposit" and typeof(packet.position)=="Vector3" and Config.Robot.Recipes[packet.rarity] then
            Audio.progress(packet.count or 0,packet.total or 0)
            local color=Color3.fromRGB(unpack(Style.get(packet.rarity).Color))
            popup(packet.position+Vector3.new(0,3,0),string.format("+1 %s  %d/%d",packet.rarity:upper(),packet.count or 0,packet.total or 0),color)
        elseif kind=="Built" or kind=="Unboxed" then
            local mutation=Mutations.get(packet.mutation)
            play(if mutation then mutation.Id elseif packet.new then "BuiltNew" else "Built")
            if typeof(packet.position)=="Vector3" then
                local color=if mutation then Color3.fromRGB(unpack(mutation.Color)) else Color3.fromRGB(255,214,110)
                Parts.burst(folder,CFrame.new(packet.position+Vector3.new(0,4,0)),color,if mutation then 90 else 40)
                if mutation then
                    task.delay(.25,function() Parts.burst(folder,CFrame.new(packet.position+Vector3.new(0,7,0)),Color3.fromRGB(255,255,255),60) end)
                    popup(packet.position+Vector3.new(0,9,0),mutation.Label:upper().."!",color,36)
                end
            end
            if mutation then pulse(Color3.fromRGB(unpack(mutation.Color)),.35,.8) end
        elseif kind=="Claim" then
            play("Claim");pulse(Color3.fromRGB(110,240,160),.18,.5)
        elseif kind=="DroneAlert" then
            play("Alarm");pulse(Color3.fromRGB(255,40,30),.35,.6);shake(.35,.25)
        elseif kind=="DroneCatch" then
            play("Catch");pulse(Color3.fromRGB(255,30,20),.55,1);shake(.6,.6)
        elseif kind=="DroneLost" then
            play("Escape")
        elseif kind=="Guide" and packet.done then
            play("Guide");pulse(Color3.fromRGB(255,214,110),.25,.8)
        end
    end)
    player:GetAttributeChangedSignal("CarriedName"):Connect(function()
        if (player:GetAttribute("CarriedName") or "")~="" then play("Pickup") end
    end)
    local chasing=false
    local function chase()
        chasing=player:GetAttribute("DroneChase")==true
        if chasing then Stack.show(bannerSlot) else Stack.hide(bannerSlot) end
    end
    player:GetAttributeChangedSignal("DroneChase"):Connect(chase)

    -- New-player guide beam: points to the nearest Common scrap or to the
    -- player's own deposit machine, depending on the guide step.
    local beamTarget=Parts.new(folder,"GuideTarget",Vector3.one*.2,CFrame.new(),Color3.new());beamTarget.Transparency=1
    local targetAttachment=Instance.new("Attachment");targetAttachment.Parent=beamTarget
    local marker=Instance.new("BillboardGui");marker.Size=UDim2.fromOffset(60,60);marker.AlwaysOnTop=true;marker.StudsOffset=Vector3.new(0,3,0);marker.Enabled=false;marker.Parent=beamTarget
    local arrow=Instance.new("TextLabel");arrow.Size=UDim2.fromScale(1,1);arrow.BackgroundTransparency=1;arrow.Text="▼";arrow.TextColor3=Color3.fromRGB(90,240,217)
    arrow.Font=Enum.Font.GothamBlack;arrow.TextScaled=true;arrow.TextStrokeTransparency=.2;arrow.AutoLocalize=false;arrow.Parent=marker
    local beam=Instance.new("Beam");beam.Attachment1=targetAttachment;beam.Width0=.35;beam.Width1=.35;beam.FaceCamera=true;beam.LightEmission=1
    beam.Color=ColorSequence.new(Color3.fromRGB(90,240,217));beam.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(1,.6)});beam.Segments=12;beam.Enabled=false;beam.Parent=beamTarget
    local rootAttachment
    local function guideTarget()
        local step=player:GetAttribute("TutorialStep") or 4
        if step>=4 or step==3 then return nil end
        local carrying=(player:GetAttribute("CarriedName") or "")~=""
        local world=workspace:FindFirstChild("CatchTheScrapWorld")
        if not world then return nil end
        if step==1 or (step==2 and carrying) or (step==0 and carrying) then
            local base=world:FindFirstChild("Workshop"..(player:GetAttribute("BaseIndex") or 0))
            local deposit=base and base:FindFirstChild("Deposit")
            return deposit and deposit.Position
        end
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local items=world:FindFirstChild("Items")
        if not root or not items then return nil end
        local best,bestDistance=nil,math.huge
        for _,model in items:GetChildren() do
            if model:GetAttribute("Rarity")=="Common" and model:GetAttribute("Kind")=="Scrap" and not model:GetAttribute("CarrierUserId") then
                local carry=model:FindFirstChild("CarryRoot")
                if carry then
                    local distance=(carry.Position-root.Position).Magnitude
                    if distance<bestDistance then best,bestDistance=carry.Position,distance end
                end
            end
        end
        return best
    end
    local elapsed=1
    RunService.RenderStepped:Connect(function(dt)
        -- Camera shake through the humanoid's camera offset (local only).
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local now=os.clock()
            if now<shakeUntil then
                local s=shakeStrength*(shakeUntil-now)
                humanoid.CameraOffset=Vector3.new(math.noise(now*40,1)*s,math.noise(now*40,2)*s,0)
            elseif humanoid.CameraOffset.Magnitude>0 and shakeStrength>0 then humanoid.CameraOffset=Vector3.zero;shakeStrength=0 end
        end
        if chasing then banner.BackgroundTransparency=.1+(math.sin(os.clock()*10)+1)*.15 end
        elapsed+=dt;if elapsed<.4 then return end;elapsed=0
        local target=guideTarget()
        local root=character and character:FindFirstChild("HumanoidRootPart")
        if target and root then
            if not rootAttachment or rootAttachment.Parent~=root then
                rootAttachment=Instance.new("Attachment");rootAttachment.Name="GuideBeamStart";rootAttachment.Parent=root
                beam.Attachment0=rootAttachment
            end
            beamTarget.CFrame=CFrame.new(target+Vector3.new(0,1,0))
            beam.Enabled=true;marker.Enabled=true
        else
            beam.Enabled=false;marker.Enabled=false
        end
    end)
end
return Feel
