--!nonstrict
-- Robotdex: a field-manual style book opened from the left edge of the screen
-- (or with I). Left page: one rarity's species as cards (undiscovered robots
-- are black silhouettes). Right page: the selected robot. Bookmarks switch
-- rarity, Rewards (milestones, titles, skins) and Platforms (retire robots).
-- All data comes from the server ("Robotdex" packets); buttons send intent.
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Prompts=game:GetService("ProximityPromptService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Config=require(Shared.Config)
local Catalog=require(Shared.RobotCatalog)
local Variants=require(Shared.RobotVariants)
local Rewards=require(Shared.DexRewards)
local Style=require(Shared.RarityStyle)
local Visuals=require(script.Parent.RarityVisuals)
local Mutations=require(Shared.Mutations)
local Stack=require(script.Parent.TopStack)
local Audio=require(script.Parent.Audio)
local Dex={}

local PAPER=Color3.fromRGB(238,230,208)
local PAPER_DARK=Color3.fromRGB(222,211,184)
local INK=Color3.fromRGB(44,36,28)
local MUTED=Color3.fromRGB(122,106,86)
local COVER=Color3.fromRGB(64,38,26)
local BRASS=Color3.fromRGB(214,168,82)
local FONT=Enum.Font.GothamBold

local function rgb(t) return Color3.fromRGB(unpack(t)) end
local function rarityColor(rarity) return rgb(Style.get(rarity).Color) end
local function money(n)
    n=math.floor(n or 0)
    if n>=1e9 then return string.format("$%.1fB",n/1e9) elseif n>=1e6 then return string.format("$%.1fM",n/1e6) elseif n>=1e4 then return string.format("$%.1fK",n/1e3) end
    return "$"..n
end

local function corner(o,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 8);c.Parent=o;return c end
local function stroke(o,color,t) local s=Instance.new("UIStroke");s.Color=color;s.Thickness=t or 1;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=o;return s end
local function frame(parent,color,pos,size,name)
    local f=Instance.new("Frame");f.Name=name or "Frame";f.BackgroundColor3=color or PAPER;f.BorderSizePixel=0;f.Position=pos or UDim2.new();f.Size=size or UDim2.fromScale(1,1);f.Parent=parent;return f
end
local function text(parent,value,size,color,pos,dims,font,align)
    local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Text=value;l.TextSize=size;l.TextColor3=color or INK;l.Font=font or Enum.Font.Gotham
    l.Position=pos or UDim2.new();l.Size=dims or UDim2.new(1,0,0,size+4);l.TextWrapped=true;l.AutoLocalize=false
    l.TextXAlignment=align or Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Top;l.Parent=parent;return l
end
local function button(parent,value,pos,dims,color,ink,callback)
    local b=Instance.new("TextButton");b.Text=value;b.Font=FONT;b.TextSize=13;b.TextColor3=ink or PAPER;b.BackgroundColor3=color or COVER
    b.Position=pos;b.Size=dims;b.AutoLocalize=false;b.AutoButtonColor=true;b.Parent=parent;corner(b,7)
    if callback then b.Activated:Connect(callback) end
    return b
end

-- 3D picture of a species. silhouette=true renders a black shape (undiscovered).
-- mutation paints it like that version in the world (Mutations.paint).
local spinning={}
local function robotView(parent,id,silhouette,detail,spin,mutation)
    local species=Catalog.get(id)
    local vp=Instance.new("ViewportFrame");vp.BackgroundTransparency=1;vp.Size=UDim2.fromScale(1,1);vp.Ambient=Color3.fromRGB(165,160,150)
    vp.LightColor=Color3.fromRGB(255,244,226);vp.LightDirection=Vector3.new(-1,-1.4,-1.2);vp.Parent=parent
    if silhouette then vp.ImageColor3=Color3.new(0,0,0);vp.ImageTransparency=.12 end
    local model=Instance.new("Model");model.Name=id
    local top,wide=0,0
    local tint=rarityColor(species.Rarity)
    local index=0
    for _,d in Variants.build(id) do
        index+=1
        local big=math.max(d.size[1],d.size[2],d.size[3])
        if not detail and big<.36 then continue end
        local p=Instance.new("Part");p.Anchored=true;p.CanCollide=false;p.Size=Vector3.new(unpack(d.size))
        p.Shape=Enum.PartType[d.shape] or Enum.PartType.Block
        p.CFrame=CFrame.new(unpack(d.position))*CFrame.Angles(math.rad(d.pitch or 0),math.rad(d.yaw or 0),math.rad(d.roll or 0))
        local glow=d.palette=="energy"
        p.Color=if d.palette=="amber" or glow then tint else rgb(Config.Palette[d.palette] or {150,150,150})
        p.Material=if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
        local paint=if mutation and not silhouette and Mutations.Painted[d.palette] then Mutations.paint(mutation,index) else nil
        if paint then
            p.Color=rgb(paint.Color);p.Reflectance=paint.Reflectance
            p.Material=if paint.Neon then Enum.Material.Neon else (Enum.Material[paint.Material] or Enum.Material.SmoothPlastic)
        end
        p.Parent=model
        top=math.max(top,d.position[2]+big/2);wide=math.max(wide,math.abs(d.position[1])+big/2,math.abs(d.position[3])+big/2)
    end
    model.WorldPivot=CFrame.new()
    model.Parent=vp
    local camera=Instance.new("Camera");camera.FieldOfView=32;camera.Parent=vp;vp.CurrentCamera=camera
    local reach=math.max(top*1.05,wide*1.7,4)
    local focus=Vector3.new(0,top*.47,0)
    camera.CFrame=CFrame.lookAt(focus+Vector3.new(reach*.55,reach*.35,reach*1.55),focus)
    if spin then spinning[vp]={model=model,start=os.clock()} end
    return vp
end
-- Glowing aura behind a mutated robot preview (rays + pulsing halo).
local halos={}
local function aura(parent,mutation)
    local m=Mutations.get(mutation);if not m then return end
    local color=rgb(m.Color)
    local holder=Instance.new("Frame");holder.Name="Aura";holder.BackgroundTransparency=1;holder.Size=UDim2.fromScale(1,1);holder.ClipsDescendants=true;holder.ZIndex=1;holder.Parent=parent;corner(holder,8)
    local rays=Instance.new("Frame");rays.Name="AuraRays";rays.BackgroundTransparency=1;rays.AnchorPoint=Vector2.new(.5,.5);rays.Position=UDim2.fromScale(.5,.55);rays.Size=UDim2.fromOffset(0,0);rays.ZIndex=1;rays.Parent=holder
    local rayList={}
    for i=1,12 do
        local ray=Instance.new("Frame");ray.AnchorPoint=Vector2.new(.5,1);ray.Position=UDim2.fromScale(.5,.5);ray.Size=UDim2.fromOffset(if i%2==0 then 18 else 8,420)
        ray.BackgroundColor3=color;ray.BorderSizePixel=0;ray.Rotation=i*30;ray.ZIndex=1;ray.Parent=rays
        local fade=Instance.new("UIGradient");fade.Rotation=90;fade.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.8,.6),NumberSequenceKeypoint.new(1,.45)});fade.Parent=ray
        table.insert(rayList,ray)
    end
    local halo=Instance.new("Frame");halo.Name="AuraHalo";halo.AnchorPoint=Vector2.new(.5,.5);halo.Position=UDim2.fromScale(.5,.55);halo.Size=UDim2.fromScale(.7,.7)
    halo.BackgroundColor3=color;halo.BackgroundTransparency=.45;halo.BorderSizePixel=0;halo.ZIndex=1;halo.Parent=holder
    local ratio=Instance.new("UIAspectRatioConstraint");ratio.AspectRatio=1;ratio.Parent=halo
    local round=Instance.new("UICorner");round.CornerRadius=UDim.new(.5,0);round.Parent=halo
    local ring=Instance.new("UIStroke");ring.Color=rgb(m.Accent2);ring.Thickness=3;ring.Transparency=.25;ring.Parent=halo
    local shine=Instance.new("UIGradient");shine.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(.5,.75),NumberSequenceKeypoint.new(1,.1)});shine.Parent=halo
    local pulse=Instance.new("UIScale");pulse.Parent=halo
    -- Rising sparkles (twinkling diamonds) and a soft floor glow.
    local floorGlow=Instance.new("Frame");floorGlow.Name="AuraFloor";floorGlow.AnchorPoint=Vector2.new(.5,.5);floorGlow.Position=UDim2.fromScale(.5,.9);floorGlow.Size=UDim2.fromScale(.75,.16)
    floorGlow.BackgroundColor3=color;floorGlow.BackgroundTransparency=.35;floorGlow.BorderSizePixel=0;floorGlow.ZIndex=1;floorGlow.Parent=holder
    local floorRound=Instance.new("UICorner");floorRound.CornerRadius=UDim.new(.5,0);floorRound.Parent=floorGlow
    local floorFade=Instance.new("UIGradient");floorFade.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,1)});floorFade.Parent=floorGlow
    local sparks={}
    for i=1,14 do
        local spark=Instance.new("Frame");spark.Name="AuraSpark";spark.AnchorPoint=Vector2.new(.5,.5);spark.Size=UDim2.fromOffset(if i%3==0 then 9 else 6,if i%3==0 then 9 else 6)
        spark.BackgroundColor3=if i%2==0 then rgb(m.Accent2) else Color3.new(1,1,1);spark.BorderSizePixel=0;spark.Rotation=45;spark.ZIndex=3;spark.Parent=holder
        table.insert(sparks,{frame=spark,x=((i*37)%100)/100,offset=((i*53)%100)/100,speed=.18+((i*29)%10)/50})
    end
    halos[holder]={rays=rays,rayList=rayList,halo=halo,ring=ring,shine=shine,pulse=pulse,sparks=sparks,floor=floorGlow,rainbow=m.Pattern=="Spectrum",start=os.clock()}
    return holder
end
RunService.RenderStepped:Connect(function()
    local now=os.clock()
    for vp,entry in spinning do
        if not vp.Parent then spinning[vp]=nil
        else entry.model:PivotTo(CFrame.Angles(0,math.sin((now-entry.start)*.6)*.65,0)) end
    end
    for holder,h in halos do
        if not holder.Parent then halos[holder]=nil;continue end
        local t=now-h.start
        h.rays.Rotation=t*18;h.shine.Rotation=t*90
        h.pulse.Scale=1+math.sin(t*2.6)*.06
        h.halo.BackgroundTransparency=.45+math.sin(t*2.6)*.12
        h.floor.BackgroundTransparency=.3+math.sin(t*2.6)*.15
        for i,sp in h.sparks do
            local k=(sp.offset+t*sp.speed)%1
            sp.frame.Position=UDim2.fromScale(.12+sp.x*.76+math.sin(t*2+i)*.02,.92-k*.85)
            sp.frame.BackgroundTransparency=math.clamp(.1+k*.9+math.sin(t*9+i)*.15,0,1)
            sp.frame.Rotation=45+t*90*(if i%2==0 then 1 else -1)
            if h.rainbow then sp.frame.BackgroundColor3=Color3.fromHSV((t*.2+i/14)%1,.5,1) end
        end
        if h.rainbow then
            local c=Color3.fromHSV((t*.2)%1,.6,1)
            h.halo.BackgroundColor3=c;h.ring.Color=Color3.fromHSV((t*.2+.5)%1,.6,1)
            for i,r in h.rayList do r.BackgroundColor3=Color3.fromHSV((t*.2+i/12)%1,.6,1) end
        end
    end
end)

function Dex.start(player,remote,hud)
    local playerGui=player:WaitForChild("PlayerGui")
    local data={dex={},mdex={},rebirths=0,multiplier=1,claimed={},projects={},perks={income=0,speed=0},titles={},title="",skins={"Default"},skin="Default",stats={built=0,unboxed=0},found=0,total=Catalog.Total}
    local tab,selected,compactDetail="Common",nil,false
    local version=nil -- selected version of the selected robot (nil = Normal)
    local claimedSet,titleSet,skinSet={}, {}, {}

    -- Launcher on the left edge of the HUD.
    local launcherGui=Instance.new("ScreenGui");launcherGui.Name="RobotdexLauncher";launcherGui.ResetOnSpawn=false;launcherGui.DisplayOrder=5;launcherGui.Parent=playerGui
    local launcher=Instance.new("TextButton");launcher.Name="Robotdex";launcher.Text="";launcher.AutoLocalize=false;launcher.AnchorPoint=Vector2.new(0,.5)
    launcher.Position=UDim2.new(0,10,.5,-64);launcher.Size=UDim2.fromOffset(78,112);launcher.BackgroundColor3=COVER;launcher.Parent=launcherGui;corner(launcher,10);stroke(launcher,BRASS,2)
    local spine=frame(launcher,Color3.fromRGB(44,25,17),UDim2.fromOffset(0,0),UDim2.new(0,10,1,0));corner(spine,10)
    text(launcher,"ROBOT\nDEX",15,BRASS,UDim2.fromOffset(12,10),UDim2.new(1,-16,0,38),Enum.Font.GothamBlack,Enum.TextXAlignment.Center)
    local launcherCount=text(launcher,"0/"..Catalog.Total,13,PAPER,UDim2.fromOffset(12,54),UDim2.new(1,-16,0,18),FONT,Enum.TextXAlignment.Center)
    local launcherBar=frame(launcher,Color3.fromRGB(34,20,14),UDim2.fromOffset(16,76),UDim2.new(1,-26,0,6));corner(launcherBar,3)
    local launcherFill=frame(launcherBar,BRASS,UDim2.new(),UDim2.fromScale(0,1));corner(launcherFill,3)
    text(launcher,if UserInputService.KeyboardEnabled then "[ I ]" else "OPEN",11,Color3.fromRGB(196,170,130),UDim2.fromOffset(12,88),UDim2.new(1,-16,0,14),FONT,Enum.TextXAlignment.Center)
    local badge=Instance.new("TextLabel");badge.Name="Claimable";badge.AnchorPoint=Vector2.new(.5,.5);badge.Position=UDim2.new(1,-2,0,4);badge.Size=UDim2.fromOffset(24,24)
    badge.BackgroundColor3=Color3.fromRGB(226,58,52);badge.TextColor3=Color3.new(1,1,1);badge.Font=Enum.Font.GothamBlack;badge.TextSize=13;badge.AutoLocalize=false;badge.Visible=false;badge.Parent=launcher;corner(badge,12)

    -- The book.
    local gui=Instance.new("ScreenGui");gui.Name="Robotdex";gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.ResetOnSpawn=false;gui.DisplayOrder=20;gui.Enabled=false;gui.IgnoreGuiInset=true;gui.Parent=playerGui
    local dim=frame(gui,Color3.fromRGB(6,9,13));dim.BackgroundTransparency=.25
    local book=frame(dim,COVER,UDim2.fromScale(.5,.5),UDim2.new(1,-20,1,-20),"Book");book.AnchorPoint=Vector2.new(.5,.5);corner(book,16);stroke(book,Color3.fromRGB(30,16,10),3)
    local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(1060,660);limit.Parent=book
    for _,c in {{0,0},{1,0},{0,1},{1,1}} do
        local rivet=frame(book,BRASS,UDim2.new(c[1],if c[1]==0 then 7 else -19,c[2],if c[2]==0 then 7 else -19),UDim2.fromOffset(12,12));corner(rivet,6)
    end
    local title=text(book,"ROBOTDEX",20,BRASS,UDim2.fromOffset(26,10),UDim2.new(.4,0,0,24),Enum.Font.GothamBlack)
    local closeButton=button(book,"X",UDim2.new(1,-50,0,8),UDim2.fromOffset(36,30),Color3.fromRGB(110,40,30),PAPER)
    local tabs=Instance.new("ScrollingFrame");tabs.Name="Bookmarks";tabs.BackgroundTransparency=1;tabs.BorderSizePixel=0;tabs.ScrollBarThickness=0
    tabs.Position=UDim2.fromOffset(18,42);tabs.Size=UDim2.new(1,-36,0,34);tabs.ScrollingDirection=Enum.ScrollingDirection.X;tabs.AutomaticCanvasSize=Enum.AutomaticSize.X;tabs.CanvasSize=UDim2.new();tabs.Parent=book
    local tabLayout=Instance.new("UIListLayout");tabLayout.FillDirection=Enum.FillDirection.Horizontal;tabLayout.Padding=UDim.new(0,4);tabLayout.Parent=tabs
    local pages=frame(book,PAPER_DARK,UDim2.fromOffset(16,78),UDim2.new(1,-32,1,-122),"Pages");corner(pages,8)
    local left=frame(pages,PAPER,UDim2.fromOffset(6,6),UDim2.new(.5,-12,1,-12),"LeftPage");corner(left,6)
    local right=frame(pages,PAPER,UDim2.new(.5,6,0,6),UDim2.new(.5,-12,1,-12),"RightPage");corner(right,6)
    local spineLine=frame(pages,Color3.fromRGB(170,150,118),UDim2.new(.5,-1,0,10),UDim2.new(0,2,1,-20))
    local footer=text(book,"",13,PAPER,UDim2.new(0,24,1,-38),UDim2.new(.55,0,0,18),FONT)
    local footerBar=frame(book,Color3.fromRGB(36,21,14),UDim2.new(.56,0,1,-34),UDim2.new(.44,-30,0,10));corner(footerBar,5)
    local footerFill=frame(footerBar,BRASS,UDim2.new(),UDim2.fromScale(0,1));corner(footerFill,5)
    local status=text(book,"",12,Color3.fromRGB(240,214,160),UDim2.new(0,24,1,-20),UDim2.new(1,-48,0,16))

    local function isCompact() return book.AbsoluteSize.X<760 end
    local hudEnabled,promptEnabled=true,true
    local render

    local function clear(page) for _,c in page:GetChildren() do if not c:IsA("UICorner") then c:Destroy() end end end
    local function scroll(page,top)
        local s=Instance.new("ScrollingFrame");s.BackgroundTransparency=1;s.BorderSizePixel=0;s.ScrollBarThickness=5;s.ScrollBarImageColor3=MUTED
        s.Position=UDim2.fromOffset(12,top);s.Size=UDim2.new(1,-18,1,-top-10);s.AutomaticCanvasSize=Enum.AutomaticSize.Y;s.CanvasSize=UDim2.new();s.Parent=page
        return s
    end
    local function owned(id) return (data.dex[id] or 0)>0 end
    local function mutationCount(mutation,id) return (data.mdex or {})[Mutations.key(mutation,id)] or 0 end
    local function versionCount(mutation,id) return if mutation then mutationCount(mutation,id) else Mutations.normalOwned(data.dex,data.mdex or {},id) end
    local function versions(id) return Mutations.versionsOwned(data.dex,data.mdex or {},id) end
    -- Unclaimed entry rewards for owned versions.
    local function entryReady(id,mutation) return versionCount(mutation,id)>0 and not claimedSet[Rewards.entryId(id,mutation)] end
    local function anyEntryReady(id)
        if entryReady(id,nil) then return true end
        for _,m in Mutations.List do if entryReady(id,m.Id) then return true end end
        return false
    end
    local function dot(parent)
        local d=Instance.new("TextLabel");d.Name="ClaimDot";d.AnchorPoint=Vector2.new(.5,.5);d.Position=UDim2.new(1,-11,0,28);d.Size=UDim2.fromOffset(18,18)
        d.BackgroundColor3=Color3.fromRGB(226,58,52);d.Text="!";d.TextColor3=Color3.new(1,1,1);d.Font=Enum.Font.GothamBlack;d.TextSize=12;d.AutoLocalize=false;d.ZIndex=5;d.Parent=parent;corner(d,9)
        return d
    end
    local function countFound(rarity)
        local n,total=0,0
        for _,s in Catalog.forRarity(rarity) do total+=1;if owned(s.Id) then n+=1 end end
        return n,total
    end

    -- LEFT PAGE: species cards of one rarity.
    local function indexPage(page,rarity)
        local stage;for _,s in Config.Stages do if s.Rarity==rarity then stage=s end end
        local n,total=countFound(rarity)
        local head=text(page,rarity:upper(),20,rarityColor(rarity),UDim2.fromOffset(14,10),UDim2.new(1,-28,0,24),Enum.Font.GothamBlack)
        if rarity=="Celestial" then head.TextColor3=Color3.fromRGB(70,150,190) end
        text(page,string.format("%s  ·  %d / %d discovered  ·  %d parts per build",stage.Name,n,total,Config.Robot.Recipes[rarity].Parts),12,MUTED,UDim2.fromOffset(14,36),UDim2.new(1,-28,0,16))
        local grid=scroll(page,58)
        local layout=Instance.new("UIGridLayout");layout.CellPadding=UDim2.fromOffset(8,8);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=grid
        local width=page.AbsoluteSize.X-36
        local columns=if width>420 then 4 elseif width>300 then 3 else 2
        local cell=math.floor((width-(columns-1)*8)/columns)
        layout.CellSize=UDim2.fromOffset(cell,math.floor(cell*1.22))
        for _,s in Catalog.forRarity(rarity) do
            local have=owned(s.Id)
            local fullSet=have and versions(s.Id)>=Mutations.Versions
            local card=Instance.new("TextButton");card.Text="";card.AutoButtonColor=true;card.LayoutOrder=s.Number;card.BackgroundColor3=if fullSet then Color3.fromRGB(255,236,176) elseif have then Color3.fromRGB(250,245,230) else Color3.fromRGB(214,203,178);card.Parent=grid;corner(card,8)
            local edge=stroke(card,if s.Id==selected then rarityColor(rarity) else Color3.fromRGB(180,164,134),if s.Id==selected then 3 else 1)
            if have and rarity=="Celestial" and s.Id==selected then Visuals.apply(card,rarity) end
            local picture=frame(card,Color3.new(),UDim2.fromOffset(4,18),UDim2.new(1,-8,1,-52));picture.BackgroundTransparency=1
            robotView(picture,s.Id,not have,false,false)
            text(card,string.format("#%03d",s.Number),11,MUTED,UDim2.fromOffset(7,4),UDim2.new(.5,0,0,13),FONT)
            text(card,s.Source=="Box" and "BOX" or "BUILD",10,if s.Source=="Box" then Color3.fromRGB(150,80,30) else MUTED,UDim2.new(.5,0,0,4),UDim2.new(.5,-7,0,13),FONT,Enum.TextXAlignment.Right)
            text(card,if have then s.Name else "???",12,INK,UDim2.new(0,6,1,-32),UDim2.new(1,-12,0,15),FONT,Enum.TextXAlignment.Center)
            text(card,if fullSet then "FULL SET ★" elseif have then string.format("%d/%d versions",versions(s.Id),Mutations.Versions) else "undiscovered",10,if fullSet then Color3.fromRGB(150,100,10) else MUTED,UDim2.new(0,6,1,-16),UDim2.new(1,-12,0,13),FONT,Enum.TextXAlignment.Center)
            -- One star per mutated version owned, in that mutation's color.
            local slot=0
            for _,m in Mutations.List do
                if mutationCount(m.Id,s.Id)>0 then
                    text(card,"★",14,rgb(m.Color),UDim2.new(0,4+slot*12,0,16),UDim2.fromOffset(13,15),Enum.Font.GothamBlack,Enum.TextXAlignment.Center)
                    slot+=1
                end
            end
            if have and anyEntryReady(s.Id) then dot(card) end
            card.Activated:Connect(function()
                if selected~=s.Id then version=nil end
                selected=s.Id;compactDetail=true;render()
            end)
        end
    end

    -- RIGHT PAGE: one species, with every version (Normal + mutations) as
    -- clickable chips. The 3D preview shows the chosen version.
    local function detailPage(page,id)
        local s=Catalog.get(id)
        local have=owned(id)
        local m=Mutations.get(version)
        local haveVersion=versionCount(version,id)>0
        local top=10
        -- Short pages (phones) scroll instead of squeezing the preview.
        local H=math.max(page.AbsoluteSize.Y,470)
        local host=page
        if page.AbsoluteSize.Y<470 then
            host=Instance.new("ScrollingFrame");host.Name="DetailScroll";host.BackgroundTransparency=1;host.BorderSizePixel=0;host.ScrollBarThickness=5;host.ScrollBarImageColor3=MUTED
            host.Size=UDim2.fromScale(1,1);host.CanvasSize=UDim2.fromOffset(0,H);host.Parent=page
        end
        local viewH=math.floor(H*.44)
        if isCompact() then button(host,"< BACK",UDim2.fromOffset(12,8),UDim2.fromOffset(80,28),COVER,PAPER,function() compactDetail=false;render() end);top=42 end
        local view=frame(host,if m and haveVersion then Color3.fromRGB(34,30,44) else Color3.fromRGB(226,216,192),UDim2.fromOffset(14,top),UDim2.new(1,-28,0,viewH-top),"Preview");corner(view,8)
        if m then stroke(view,rgb(m.Color),2) end
        if m and haveVersion then aura(view,version) end
        local preview=robotView(view,id,not haveVersion,true,haveVersion,version);preview.ZIndex=2
        text(view,string.format("#%03d",s.Number),16,if m and haveVersion then PAPER else MUTED,UDim2.fromOffset(10,8),UDim2.fromOffset(90,20),Enum.Font.GothamBlack)
        local pill=text(view,s.Rarity:upper(),12,Color3.new(1,1,1),UDim2.new(1,-110,0,8),UDim2.fromOffset(100,20),FONT,Enum.TextXAlignment.Center)
        pill.BackgroundTransparency=0;pill.BackgroundColor3=rarityColor(s.Rarity);pill.TextYAlignment=Enum.TextYAlignment.Center;corner(pill,10)
        if s.Rarity=="Celestial" then Visuals.apply(pill,"Celestial") end
        if m then
            local tag=text(view,m.Label:upper().." VERSION",12,Color3.new(1,1,1),UDim2.new(1,-150,1,-28),UDim2.fromOffset(140,20),Enum.Font.GothamBlack,Enum.TextXAlignment.Center)
            tag.BackgroundTransparency=0;tag.BackgroundColor3=rgb(m.Color);tag.TextYAlignment=Enum.TextYAlignment.Center;tag.TextStrokeTransparency=.5;corner(tag,10)
        end

        -- Version chips.
        local found=versions(id)
        local strip=frame(host,PAPER,UDim2.fromOffset(14,viewH+6),UDim2.new(1,-28,0,96),"Versions");strip.BackgroundTransparency=1
        text(strip,string.format("VERSIONS  %d / %d",found,Mutations.Versions),13,INK,UDim2.fromOffset(0,0),UDim2.new(.6,0,0,16),Enum.Font.GothamBlack)
        if found>=Mutations.Versions then text(strip,"FULL SET ★",12,Color3.fromRGB(170,110,10),UDim2.new(.6,0,0,1),UDim2.new(.4,0,0,16),Enum.Font.GothamBlack,Enum.TextXAlignment.Right) end
        local row=frame(strip,PAPER,UDim2.fromOffset(0,20),UDim2.new(1,0,0,76),"Chips");row.BackgroundTransparency=1
        local chipLayout=Instance.new("UIListLayout");chipLayout.FillDirection=Enum.FillDirection.Horizontal;chipLayout.Padding=UDim.new(0,5);chipLayout.SortOrder=Enum.SortOrder.LayoutOrder;chipLayout.Parent=row
        local options={false}
        for _,mm in Mutations.List do table.insert(options,mm.Id) end
        for order,option in options do
            local mutation=if option then option else nil
            local info=Mutations.get(mutation)
            local count=versionCount(mutation,id)
            local got=count>0
            local tint=if info then rgb(info.Color) else rarityColor(s.Rarity)
            local chip=Instance.new("TextButton");chip.Name="Version"..(mutation or "Normal");chip.Text="";chip.AutoButtonColor=true;chip.LayoutOrder=order
            chip.Size=UDim2.new(1/#options,-5,1,0);chip.BackgroundColor3=if got then Color3.fromRGB(250,245,230) else Color3.fromRGB(205,194,170);chip.Parent=row;corner(chip,7)
            stroke(chip,if mutation==version then tint else Color3.fromRGB(180,164,134),if mutation==version then 3 else 1)
            local picture=frame(chip,Color3.new(),UDim2.fromOffset(2,2),UDim2.new(1,-4,1,-32));picture.BackgroundTransparency=1
            if have then robotView(picture,id,not got,false,false,mutation) end
            local name=text(chip,if info then info.Label:upper() else "NORMAL",10,if got then tint else MUTED,UDim2.new(0,2,1,-30),UDim2.new(1,-4,0,13),Enum.Font.GothamBlack,Enum.TextXAlignment.Center)
            if got and not info and s.Rarity=="Common" then name.TextColor3=INK end
            text(chip,if got then "×"..count elseif info then string.format("%g%%",info.Chance*100) else "—",10,MUTED,UDim2.new(0,2,1,-15),UDim2.new(1,-4,0,13),FONT,Enum.TextXAlignment.Center)
            if got and entryReady(id,mutation) then dot(chip) end
            chip.Activated:Connect(function() version=mutation;render() end)
        end

        local y=0
        local info=scroll(host,0);info.Position=UDim2.fromOffset(14,viewH+108);info.Size=UDim2.new(1,-24,0,H-viewH-116)
        local function line(value,size,color,font,height)
            local l=text(info,value,size,color,UDim2.fromOffset(0,y),UDim2.new(1,-8,0,height or size+6),font);y+=(height or size+6)+4;return l
        end
        line(if have then Mutations.prefix(version)..s.Name else "??? UNDISCOVERED",20,if m and have then rgb(m.Color) else INK,Enum.Font.GothamBlack,24)
        local recipe=Config.Robot.Recipes[s.Rarity]
        local route=if s.Source=="Box" then "Found in "..s.Rarity.." Robot Boxes (events and rewards)" else "Built from "..recipe.Parts.." "..s.Rarity.." scrap parts"
        line(route,13,MUTED,FONT,18)
        local income=Catalog.income(recipe.Income,id)*Mutations.multiplier(version)
        if m then
            line(string.format("%s chance: %g%% per robot   ·   Income: $%d/sec (x%g)",m.Label,m.Chance*100,income,m.Multiplier),13,INK,Enum.Font.Gotham,18)
        else
            line(string.format("%s chance: %.1f%%   ·   Income: $%d/sec (×%s)",s.Source=="Box" and "Box" or "Build",Catalog.chance(id)*100,income,tostring(s.Multiplier)),13,INK,Enum.Font.Gotham,18)
        end
        if have then
            local count=versionCount(version,id)
            if count>0 then
                line(string.format("%s collected ×%d.",if m then m.Label.." version" else "Normal version",count),13,Color3.fromRGB(46,120,70),FONT,18)
                local entryId=Rewards.entryId(id,version)
                if claimedSet[entryId] then
                    line("Entry reward claimed ✓",12,MUTED,FONT,16)
                else
                    local claim=button(info,string.format("CLAIM ENTRY REWARD  $%s",tostring(Rewards.entryCash(id,version))),UDim2.fromOffset(0,y),UDim2.new(1,-8,0,30),Color3.fromRGB(58,140,80),PAPER,function()
                        remote:FireServer("ClaimReward",entryId)
                    end)
                    claim.Name="ClaimEntry";y+=36
                end
            else
                line(string.format("%s version not collected yet.",if m then m.Label else "Normal"),13,Color3.fromRGB(170,90,40),FONT,18)
            end
            line('"'..s.Blurb..'"',14,INK,Enum.Font.GothamMedium,38)
            line("Every finished build or box can roll a version. Collect all "..Mutations.Versions.." for a FULL SET (Robotdex rewards).",12,MUTED,Enum.Font.Gotham,32)
        else
            line(if s.Source=="Box" then "Watch for "..s.Rarity.." box events, or earn reward boxes from Robotdex milestones." else "Keep finishing "..s.Rarity.." builds: every completed build rolls one of this page's build robots.",13,MUTED,Enum.Font.Gotham,36)
        end
    end

    local function summaryPage(page)
        text(page,"FIELD NOTES",20,INK,UDim2.fromOffset(14,10),UDim2.new(1,-28,0,24),Enum.Font.GothamBlack)
        local body=scroll(page,42)
        local y=0
        local function line(value,size,color,font,height)
            text(body,value,size,color or INK,UDim2.fromOffset(0,y),UDim2.new(1,-8,0,height or size+6),font);y+=(height or size+6)+4
        end
        line("Every finished scrap build rolls a random robot of that rarity. Rarer robots earn more. Boxes hold robots that can never be built.",13,MUTED,Enum.Font.Gotham,52)
        for _,stage in Config.Stages do
            local n,total=countFound(stage.Rarity)
            text(body,string.format("%s  %d / %d",stage.Rarity:upper(),n,total),12,INK,UDim2.fromOffset(0,y),UDim2.new(.5,0,0,16),FONT)
            local bar=frame(body,Color3.fromRGB(205,192,164),UDim2.new(.5,0,0,y+3),UDim2.new(.5,-12,0,9));corner(bar,4)
            local fill=frame(bar,rarityColor(stage.Rarity),UDim2.new(),UDim2.fromScale(n/total,1));corner(fill,4)
            y+=22
        end
        y+=6
        text(body,"VERSIONS",13,INK,UDim2.fromOffset(0,y),UDim2.new(1,0,0,16),Enum.Font.GothamBlack);y+=20
        for _,m in Mutations.List do
            local n=0
            for _,sp in Catalog.List do if mutationCount(m.Id,sp.Id)>0 then n+=1 end end
            text(body,string.format("%s ★  %d / %d",m.Label:upper(),n,Catalog.Total),12,rgb(m.Color),UDim2.fromOffset(0,y),UDim2.new(.5,0,0,16),Enum.Font.GothamBlack)
            local bar=frame(body,Color3.fromRGB(205,192,164),UDim2.new(.5,0,0,y+3),UDim2.new(.5,-12,0,9));corner(bar,4)
            local fill=frame(bar,rgb(m.Color),UDim2.new(),UDim2.fromScale(n/Catalog.Total,1));corner(fill,4)
            y+=22
        end
        local sets=0
        for _,sp in Catalog.List do if versions(sp.Id)>=Mutations.Versions then sets+=1 end end
        line(string.format("FULL SETS (all %d versions): %d / %d",Mutations.Versions,sets,Catalog.Total),13,Color3.fromRGB(150,110,20),FONT,18)
        line(string.format("Built %d  ·  Unboxed %d  ·  Robotdex bonus +%d%%  ·  Speed bonus +%d",data.stats.built,data.stats.unboxed,data.perks.income,data.perks.speed),13,INK,FONT,34)
        line(string.format("Rebirth %d  ·  total income x%.2f  ·  %d platforms",data.rebirths or 0,data.multiplier or 1,data.slots or Config.Robot.Slots),13,INK,FONT,18)
        if player:GetAttribute("SaveStatus")=="offline" then line("Saving is off in this session.",12,Color3.fromRGB(170,60,40),FONT,18) else line("Your Robotdex is saved automatically.",12,Color3.fromRGB(46,120,70),FONT,18) end
    end

    local function rewardsPage(page)
        text(page,"REWARDS",20,INK,UDim2.fromOffset(14,10),UDim2.new(1,-28,0,24),Enum.Font.GothamBlack)
        text(page,"Milestones, plus a small cash reward for every new robot and version.",12,MUTED,UDim2.fromOffset(14,36),UDim2.new(1,-28,0,16))
        local ready=Rewards.readyEntries({dex=data.dex,claimed=claimedSet,mdex=data.mdex or {}})
        if #ready>0 then
            local total=0
            for _,m in ready do total+=m.Rewards[1].Amount end
            local all=button(page,string.format("CLAIM %d ENTRIES  $%s",#ready,money(total):sub(2)),UDim2.new(1,-214,0,8),UDim2.fromOffset(200,28),Color3.fromRGB(58,140,80),PAPER,function()
                remote:FireServer("ClaimEntries")
            end)
            all.Name="ClaimEntries"
        end
        local list=scroll(page,58)
        local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,6);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=list
        for order,m in Rewards.List do
            local have=Rewards.progress(data,m)
            local done=claimedSet[m.Id]
            local ready=not done and have>=m.Need
            local row=frame(list,if ready then Color3.fromRGB(255,240,196) else Color3.fromRGB(246,240,224),nil,UDim2.new(1,-8,0,70));row.LayoutOrder=(if ready then 0 elseif done then 200 else 100)+order;corner(row,8)
            stroke(row,if ready then BRASS elseif m.Rarity then rarityColor(m.Rarity) else Color3.fromRGB(196,180,150),if ready then 2 else 1)
            text(row,m.Title:upper(),13,INK,UDim2.fromOffset(10,6),UDim2.new(1,-130,0,16),FONT)
            local parts={};for _,r in m.Rewards do table.insert(parts,Rewards.describe(r)) end
            text(row,table.concat(parts,"  ·  "),11,MUTED,UDim2.fromOffset(10,24),UDim2.new(1,-130,0,28))
            local bar=frame(row,Color3.fromRGB(214,202,176),UDim2.new(0,10,1,-14),UDim2.new(1,-130,0,6));corner(bar,3)
            local fill=frame(bar,if m.Rarity then rarityColor(m.Rarity) else BRASS,UDim2.new(),UDim2.fromScale(math.min(1,have/m.Need),1));corner(fill,3)
            local action=if done then "CLAIMED" elseif ready then "CLAIM" else string.format("%d / %d",math.min(have,m.Need),m.Need)
            local b=button(row,action,UDim2.new(1,-112,.5,-17),UDim2.fromOffset(100,34),if ready then Color3.fromRGB(46,132,82) elseif done then Color3.fromRGB(150,140,120) else Color3.fromRGB(196,184,158),if ready or done then Color3.new(1,1,1) else INK)
            b.Active=ready;b.AutoButtonColor=ready
            if ready then b.Activated:Connect(function() status.Text="Claiming...";remote:FireServer("ClaimReward",m.Id) end) end
        end
    end

    local function cosmeticsPage(page)
        text(page,"TITLES & WORKSHOP SKINS",18,INK,UDim2.fromOffset(14,10),UDim2.new(1,-28,0,24),Enum.Font.GothamBlack)
        local list=scroll(page,42)
        local y=0
        local function header(value) text(list,value,13,MUTED,UDim2.fromOffset(0,y),UDim2.new(1,-8,0,16),FONT);y+=22 end
        local function option(label,active,unlocked,callback)
            local b=button(list,(active and "✓ " or "")..label,UDim2.fromOffset(0,y),UDim2.new(1,-8,0,32),if active then Color3.fromRGB(46,132,82) elseif unlocked then COVER else Color3.fromRGB(200,188,162),if unlocked then Color3.new(1,1,1) else MUTED,unlocked and callback or nil)
            b.TextXAlignment=Enum.TextXAlignment.Left;local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,10);pad.Parent=b;b.Active=unlocked;y+=38
        end
        header("OVERHEAD TITLE")
        option("No title",data.title=="",true,function() remote:FireServer("EquipCosmetic","Title","") end)
        local titles={}
        for _,m in Rewards.List do for _,r in m.Rewards do if r.Type=="Title" then table.insert(titles,r.Name) end end end
        for _,name in titles do option(if titleSet[name] then name else name.."  (locked)",data.title==name,titleSet[name]==true,function() remote:FireServer("EquipCosmetic","Title",name) end) end
        y+=6;header("WORKSHOP SKIN")
        for _,id in Rewards.SkinOrder do
            local skin=Rewards.Skins[id]
            option(if skinSet[id] then skin.Label else skin.Label.."  (locked)",data.skin==id,skinSet[id]==true,function() remote:FireServer("EquipCosmetic","Skin",id) end)
        end
        y+=6;text(list,string.format("Permanent bonuses: +%d%% income, +%d base speed.",data.perks.income,data.perks.speed),12,INK,UDim2.fromOffset(0,y),UDim2.new(1,-8,0,30),FONT)
    end

    local function platformsPage(page)
        text(page,"YOUR PLATFORMS",20,INK,UDim2.fromOffset(14,10),UDim2.new(1,-28,0,24),Enum.Font.GothamBlack)
        text(page,"Retire a finished robot at your deposit machine to free its platform. Robotdex entries are kept. No refund.",12,MUTED,UDim2.fromOffset(14,36),UDim2.new(1,-28,0,32))
        local list=scroll(page,74)
        local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,6);layout.Parent=list
        for slot=1,data.slots or Config.Robot.Slots do
            local project;for _,p in data.projects do if p.slot==slot then project=p end end
            local row=frame(list,Color3.fromRGB(246,240,224),nil,UDim2.new(1,-8,0,64));row.LayoutOrder=slot;corner(row,8)
            stroke(row,if project then rarityColor(project.rarity) else Color3.fromRGB(196,180,150),1)
            text(row,"PLATFORM "..slot,11,MUTED,UDim2.fromOffset(10,6),UDim2.new(1,-150,0,14),FONT)
            text(row,if project then project.name else "Available",14,INK,UDim2.fromOffset(10,22),UDim2.new(1,-150,0,18),FONT)
            if project and project.complete then
                text(row,money(project.income).." / sec",12,Color3.fromRGB(46,120,70),UDim2.fromOffset(10,42),UDim2.new(1,-150,0,14),FONT)
                local armed=false;local retire
                retire=button(row,"RETIRE",UDim2.new(1,-132,.5,-17),UDim2.fromOffset(120,34),Color3.fromRGB(150,60,40),Color3.new(1,1,1),function()
                    if armed then armed=false;remote:FireServer("RetireRobot",project.id) else armed=true;retire.Text="CONFIRM RETIRE";task.delay(5,function() if retire.Parent then armed=false;retire.Text="RETIRE" end end) end
                end)
            end
        end
    end

    local tabButtons={}
    local tabList={}
    for _,stage in Config.Stages do table.insert(tabList,{id=stage.Rarity,label=stage.Rarity:upper(),color=rarityColor(stage.Rarity)}) end
    table.insert(tabList,{id="Rewards",label="REWARDS",color=BRASS});table.insert(tabList,{id="Platforms",label="PLATFORMS",color=Color3.fromRGB(130,150,160)})
    for order,t in tabList do
        local b=button(tabs,t.label,UDim2.new(),UDim2.fromOffset(if t.id=="Rewards" or t.id=="Platforms" then 104 else 98,32),t.color,Color3.fromRGB(20,16,12),function()
            tab=t.id;compactDetail=false
            if Catalog.find(selected or "")==nil or (Config.Robot.Recipes[t.id] and Catalog.get(selected).Rarity~=t.id) then selected=nil end
            render()
        end)
        b.LayoutOrder=order;b.TextSize=12;tabButtons[t.id]=b
        if t.id=="Celestial" then Visuals.apply(b,"Celestial") end
    end

    render=function()
        if not gui.Enabled then return end
        claimedSet,titleSet,skinSet={}, {}, {}
        for _,id in data.claimed do claimedSet[id]=true end
        for _,id in data.titles do titleSet[id]=true end
        for _,id in data.skins do skinSet[id]=true end
        local compact=isCompact()
        clear(left);clear(right)
        for id,b in tabButtons do b.Size=UDim2.fromOffset(b.Size.X.Offset,if id==tab then 34 else 28);b.BackgroundTransparency=if id==tab then 0 else .25 end
        right.Visible=not compact;spineLine.Visible=not compact
        left.Size=if compact then UDim2.new(1,-12,1,-12) else UDim2.new(.5,-12,1,-12)
        local claimable=Rewards.claimable({dex=data.dex,claimed=claimedSet,mdex=data.mdex})
        tabButtons.Rewards.Text=if claimable>0 then "REWARDS ("..claimable..")" else "REWARDS"
        footer.Text=string.format("COLLECTION %d / %d  ·  %d%%",data.found,data.total,math.floor(data.found/math.max(1,data.total)*100))
        footerFill.Size=UDim2.fromScale(data.found/math.max(1,data.total),1)
        if Config.Robot.Recipes[tab] then
            if not selected then
                version=nil
                for _,s in Catalog.forRarity(tab) do if owned(s.Id) then selected=s.Id;break end end
                selected=selected or Catalog.forRarity(tab)[1].Id
            end
            if compact and compactDetail then detailPage(left,selected) else indexPage(left,tab) end
            if not compact then detailPage(right,selected) end
        elseif tab=="Rewards" then
            if compact and compactDetail then cosmeticsPage(left) else rewardsPage(left) end
            if compact then
                local b=button(left,"TITLES & SKINS >",UDim2.new(1,-150,0,8),UDim2.fromOffset(138,28),COVER,PAPER,function() compactDetail=not compactDetail;render() end)
                if compactDetail then b.Text="< REWARDS" end
            else cosmeticsPage(right) end
        else
            platformsPage(left)
            if not compact then summaryPage(right) end
        end
    end

    local function updateLauncher()
        launcherCount.Text=data.found.."/"..data.total
        launcherFill.Size=UDim2.fromScale(data.found/math.max(1,data.total),1)
        local claimable=player:GetAttribute("DexClaimable") or 0
        badge.Visible=claimable>0;badge.Text=tostring(claimable)
    end
    local function close()
        if not gui.Enabled then return end
        Audio.play("Close")
        gui.Enabled=false;launcherGui.Enabled=true;hud.Enabled=hudEnabled;Prompts.Enabled=promptEnabled
    end
    local function open()
        if workspace.CurrentCamera and workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable then return end
        if gui.Enabled then close();return end
        if not hud.Enabled then return end
        hudEnabled=hud.Enabled;promptEnabled=Prompts.Enabled;hud.Enabled=false;Prompts.Enabled=false;launcherGui.Enabled=false
        gui.Enabled=true;status.Text="";render();remote:FireServer("RequestIndex");Audio.play("Open")
    end
    closeButton.Activated:Connect(close)
    launcher.Activated:Connect(open)

    -- New discovery banner (shown even when the book is closed).
    local toastGui=Instance.new("ScreenGui");toastGui.Name="RobotdexDiscovery";toastGui.ResetOnSpawn=false;toastGui.DisplayOrder=30;toastGui.Parent=playerGui
    local toast=frame(toastGui,COVER,UDim2.new(.5,0,0,-120),UDim2.fromOffset(380,96),"Toast");toast.AnchorPoint=Vector2.new(.5,0);corner(toast,12);stroke(toast,BRASS,2)
    local toastSlot=Stack.add(toast,96)
    local toastPicture=frame(toast,PAPER,UDim2.fromOffset(8,8),UDim2.fromOffset(80,80));corner(toastPicture,8)
    local toastHeading=text(toast,"NEW ROBOTDEX ENTRY!",13,BRASS,UDim2.fromOffset(98,12),UDim2.new(1,-106,0,16),Enum.Font.GothamBlack)
    local toastName=text(toast,"",18,PAPER,UDim2.fromOffset(98,32),UDim2.new(1,-106,0,22),Enum.Font.GothamBlack)
    local toastInfo=text(toast,"",12,Color3.fromRGB(220,200,170),UDim2.fromOffset(98,58),UDim2.new(1,-106,0,30))
    local toastVersion=0
    local function discovered(id,mutation,newSpecies)
        local s=Catalog.find(id);if not s then return end
        local m=Mutations.get(mutation)
        toastVersion+=1;local current=toastVersion
        for _,c in toastPicture:GetChildren() do if c:IsA("ViewportFrame") then c:Destroy() end end
        robotView(toastPicture,id,false,false,true,mutation)
        toastHeading.Text=if m and not newSpecies then "NEW "..m.Label:upper().." ROBOT!" elseif m then "NEW ROBOT — AND "..m.Label:upper().."!" else "NEW ROBOTDEX ENTRY!"
        toastName.Text=Mutations.prefix(mutation)..Catalog.label(id);toastName.TextColor3=if m then rgb(m.Color) else rarityColor(s.Rarity)
        toastInfo.Text=string.format("%s %s  ·  press I to open the Robotdex",s.Rarity,s.Source=="Box" and "box robot" or "build")
        Stack.show(toastSlot)
        Audio.play("Discover")
        task.delay(5,function()
            if toastVersion==current then Stack.hide(toastSlot) end
        end)
    end

    remote.OnClientEvent:Connect(function(channel,packet)
        if type(packet)~="table" then return end
        if channel=="Robotdex" then
            data=packet;data.dex=packet.dex or {};data.mdex=packet.mdex or {}
            if packet.message then
                status.Text=packet.message
                if string.sub(packet.message,1,7)=="Claimed" then Audio.play("Claim") end
            end
            updateLauncher();render()
        elseif channel=="DexDiscovery" and type(packet.id)=="string" then
            discovered(packet.id,packet.mutation,packet.newSpecies~=false)
        end
    end)
    player:GetAttributeChangedSignal("DexClaimable"):Connect(updateLauncher)
    UserInputService.InputBegan:Connect(function(input,processed)
        -- While the book is open, I always closes it (a clicked panel can mark keys as processed).
        if input.KeyCode==Enum.KeyCode.I and (not processed or gui.Enabled) and not UserInputService:GetFocusedTextBox() then open() end
    end)
    player.CharacterRemoving:Connect(close)
    book:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if gui.Enabled then render() end end)
    hud:GetPropertyChangedSignal("Enabled"):Connect(function() if not gui.Enabled then launcherGui.Enabled=hud.Enabled end end)
    remote:FireServer("RequestIndex")
    return open
end
return Dex
