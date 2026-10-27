--!nonstrict
-- Rebirth celebration (local only, ~4 s, tap/click to skip):
--  1. your robots glow gold, lift off and dissolve (the server removes them
--     shortly after),
--  2. a shockwave ring and a light pillar burst from the workshop,
--  3. a field-of-view punch and camera shake,
--  4. a big golden "REBIRTH n" title over rotating light rays with the new
--     multiplier and platform count,
--  5. a rising sweep, a boom and a chord (Audio "Rebirth").
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local Audio=require(script.Parent.Audio)
local Parts=require(script.Parent.EffectParts)
local Cinematic={}
Cinematic.Seconds=4.2
local GOLD=Color3.fromRGB(255,206,96)

function Cinematic.start(player,remote)
    local folder=Instance.new("Folder");folder.Name="LocalRebirthEffects";folder.Parent=workspace
    local gui=Instance.new("ScreenGui");gui.Name="RebirthCinematic";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=50;gui.Enabled=false;gui.Parent=player:WaitForChild("PlayerGui")
    local shade=Instance.new("Frame");shade.Size=UDim2.fromScale(1,1);shade.BackgroundColor3=Color3.fromRGB(10,6,2);shade.BorderSizePixel=0;shade.Parent=gui
    local flash=Instance.new("Frame");flash.Size=UDim2.fromScale(1,1);flash.BackgroundColor3=Color3.new(1,1,1);flash.BorderSizePixel=0;flash.ZIndex=5;flash.Parent=gui
    local rays=Instance.new("Frame");rays.AnchorPoint=Vector2.new(.5,.5);rays.Position=UDim2.fromScale(.5,.45);rays.Size=UDim2.fromOffset(0,0);rays.BackgroundTransparency=1;rays.Parent=gui
    local rayParts={}
    for i=1,18 do
        local ray=Instance.new("Frame");ray.AnchorPoint=Vector2.new(.5,1);ray.Position=UDim2.fromScale(.5,.5);ray.Size=UDim2.fromOffset(if i%2==0 then 26 else 12,1400)
        ray.BackgroundColor3=GOLD;ray.BorderSizePixel=0;ray.Rotation=i*20;ray.Parent=rays
        local fade=Instance.new("UIGradient");fade.Rotation=90;fade.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.75,.55),NumberSequenceKeypoint.new(1,.2)});fade.Parent=ray
        table.insert(rayParts,ray)
    end
    local title=Instance.new("TextLabel");title.AnchorPoint=Vector2.new(.5,.5);title.Position=UDim2.fromScale(.5,.42);title.Size=UDim2.fromOffset(900,130)
    title.BackgroundTransparency=1;title.Font=Enum.Font.GothamBlack;title.TextScaled=true;title.TextColor3=Color3.new(1,1,1);title.AutoLocalize=false;title.ZIndex=3;title.Parent=gui
    local titleGradient=Instance.new("UIGradient");titleGradient.Rotation=90;titleGradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,244,200)),ColorSequenceKeypoint.new(.5,GOLD),ColorSequenceKeypoint.new(1,Color3.fromRGB(200,120,30))});titleGradient.Parent=title
    local titleStroke=Instance.new("UIStroke");titleStroke.Color=Color3.fromRGB(80,40,10);titleStroke.Thickness=4;titleStroke.Parent=title
    local titleScale=Instance.new("UIScale");titleScale.Parent=title
    local subtitle=Instance.new("TextLabel");subtitle.AnchorPoint=Vector2.new(.5,0);subtitle.Position=UDim2.fromScale(.5,.53);subtitle.Size=UDim2.fromOffset(820,40)
    subtitle.BackgroundTransparency=1;subtitle.Font=Enum.Font.GothamBold;subtitle.TextScaled=true;subtitle.TextColor3=Color3.fromRGB(255,240,210);subtitle.AutoLocalize=false;subtitle.ZIndex=3;subtitle.Parent=gui
    local kept=Instance.new("TextLabel");kept.AnchorPoint=Vector2.new(.5,0);kept.Position=UDim2.fromScale(.5,.6);kept.Size=UDim2.fromOffset(700,26)
    kept.BackgroundTransparency=1;kept.Font=Enum.Font.Gotham;kept.TextScaled=true;kept.TextColor3=Color3.fromRGB(200,230,200);kept.AutoLocalize=false;kept.ZIndex=3;kept.Parent=gui
    kept.Text="✓ Robotdex, rewards, titles and skins kept"
    for _,label in {subtitle,kept} do local limit=Instance.new("UITextSizeConstraint");limit.MaxTextSize=if label==subtitle then 30 else 20;limit.Parent=label end
    local hint=Instance.new("TextLabel");hint.AnchorPoint=Vector2.new(.5,1);hint.Position=UDim2.new(.5,0,1,-24);hint.Size=UDim2.fromOffset(300,20);hint.BackgroundTransparency=1
    hint.Font=Enum.Font.Gotham;hint.TextSize=14;hint.TextColor3=Color3.fromRGB(200,180,140);hint.Text="Click to continue";hint.AutoLocalize=false;hint.ZIndex=3;hint.Parent=gui

    local playing,serial,spin=false,0,0
    local savedFov
    local function finish(version)
        if version~=serial or not playing then return end
        playing=false
        for _,o in {shade,flash} do TweenService:Create(o,TweenInfo.new(.5),{BackgroundTransparency=1}):Play() end
        for _,o in {title,subtitle,kept,hint} do TweenService:Create(o,TweenInfo.new(.4),{TextTransparency=1}):Play() end
        TweenService:Create(titleStroke,TweenInfo.new(.4),{Transparency=1}):Play()
        for _,r in rayParts do TweenService:Create(r,TweenInfo.new(.4),{BackgroundTransparency=1}):Play() end
        local camera=workspace.CurrentCamera
        local fov=savedFov;savedFov=nil
        if camera and fov then TweenService:Create(camera,TweenInfo.new(.6,Enum.EasingStyle.Sine),{FieldOfView=fov}):Play() end
        task.delay(.55,function() if version==serial then gui.Enabled=false end end)
    end

    -- World effects at the player's workshop.
    local function worldBurst(packet)
        local world=workspace:FindFirstChild("CatchTheScrapWorld")
        local base=world and world:FindFirstChild("Workshop"..tostring(packet.baseIndex))
        local origin=packet.origin
        if typeof(origin)~="CFrame" then return end
        -- Robots: gold glow, lift and dissolve.
        local robots=base and base:FindFirstChild("Robots")
        if robots then
            for _,model in robots:GetChildren() do
                for _,p in model:GetDescendants() do
                    if p:IsA("BasePart") then
                        local delay=math.random()*.35
                        task.delay(delay,function()
                            if not p.Parent then return end
                            p.Material=Enum.Material.Neon;p.Color=GOLD
                            TweenService:Create(p,TweenInfo.new(1.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{
                                CFrame=p.CFrame*CFrame.new(0,0,0)+Vector3.new(0,7+math.random()*5,0),Transparency=1,Size=p.Size*.4}):Play()
                        end)
                    end
                end
            end
        end
        local center=origin*CFrame.new(0,.6,0)
        local ring=Parts.new(folder,"RebirthShockwave",Vector3.new(.3,4,4),center*CFrame.Angles(0,0,math.pi/2),GOLD,Enum.Material.Neon,Enum.PartType.Cylinder)
        ring.Transparency=.1
        TweenService:Create(ring,TweenInfo.new(1.4,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=Vector3.new(.3,95,95),Transparency=1}):Play()
        local pillar=Parts.new(folder,"RebirthPillar",Vector3.new(80,10,10),center*CFrame.new(0,40,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(255,236,170),Enum.Material.Neon,Enum.PartType.Cylinder)
        pillar.Transparency=.2
        TweenService:Create(pillar,TweenInfo.new(1.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(160,.5,.5),Transparency=1}):Play()
        for i=0,3 do task.delay(i*.18,function() Parts.burst(folder,center*CFrame.new(0,3+i*3,0),GOLD,60) end) end
        game:GetService("Debris"):AddItem(ring,2);game:GetService("Debris"):AddItem(pillar,2.2)
    end

    local function play(packet)
        serial+=1;local version=serial;playing=true
        Audio.play("Rebirth")
        worldBurst(packet)
        local camera=workspace.CurrentCamera
        if camera then
            if not savedFov then savedFov=camera.FieldOfView end
            TweenService:Create(camera,TweenInfo.new(.35,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{FieldOfView=savedFov-14}):Play()
        end
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        gui.Enabled=true
        shade.BackgroundTransparency=1;flash.BackgroundTransparency=1
        TweenService:Create(shade,TweenInfo.new(.6),{BackgroundTransparency=.35}):Play()
        task.delay(.7,function()
            if version~=serial then return end
            flash.BackgroundTransparency=0
            TweenService:Create(flash,TweenInfo.new(.7,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
            -- Camera shake on the boom.
            if humanoid then
                local start=os.clock()
                local connection;connection=RunService.RenderStepped:Connect(function()
                    local t=os.clock()-start
                    if t>.6 or not humanoid.Parent then humanoid.CameraOffset=Vector3.zero;connection:Disconnect();return end
                    local s=(1-t/.6)*.8
                    humanoid.CameraOffset=Vector3.new(math.noise(t*35,3)*s,math.noise(t*35,7)*s,0)
                end)
            end
        end)
        title.Text="REBIRTH "..tostring(packet.rebirths or "");title.TextTransparency=1;titleStroke.Transparency=1;titleScale.Scale=2.6
        subtitle.Text=string.format("INCOME x%.1f   ·   %d PLATFORMS",packet.multiplier or 1,packet.slots or 6);subtitle.TextTransparency=1
        kept.TextTransparency=1;hint.TextTransparency=1
        for _,r in rayParts do r.BackgroundTransparency=1 end
        task.delay(.72,function()
            if version~=serial then return end
            TweenService:Create(title,TweenInfo.new(.25),{TextTransparency=0}):Play()
            TweenService:Create(titleStroke,TweenInfo.new(.25),{Transparency=0}):Play()
            TweenService:Create(titleScale,TweenInfo.new(.65,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
            for _,r in rayParts do TweenService:Create(r,TweenInfo.new(.8),{BackgroundTransparency=0}):Play() end
        end)
        task.delay(1.25,function() if version==serial then TweenService:Create(subtitle,TweenInfo.new(.4),{TextTransparency=0}):Play() end end)
        task.delay(1.6,function() if version==serial then TweenService:Create(kept,TweenInfo.new(.4),{TextTransparency=0}):Play() end end)
        task.delay(2.2,function() if version==serial then TweenService:Create(hint,TweenInfo.new(.4),{TextTransparency=.2}):Play() end end)
        task.delay(Cinematic.Seconds,finish,version)
    end

    RunService.RenderStepped:Connect(function(dt)
        if not gui.Enabled then return end
        spin+=dt*14;rays.Rotation=spin
        titleGradient.Offset=Vector2.new(0,math.sin(os.clock()*2)*.15)
    end)
    UserInputService.InputBegan:Connect(function(input)
        if playing and os.clock()>0 and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.Space) then
            if title.TextTransparency<.5 then finish(serial) end
        end
    end)
    remote.OnClientEvent:Connect(function(channel,packet)
        if channel=="Fx" and type(packet)=="table" and packet.kind=="Rebirth" then play(packet) end
    end)
end
return Cinematic
