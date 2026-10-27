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
local spinning={}
local function robotView(parent,id,silhouette,detail,spin)
    local species=Catalog.get(id)
    local vp=Instance.new("ViewportFrame");vp.BackgroundTransparency=1;vp.Size=UDim2.fromScale(1,1);vp.Ambient=Color3.fromRGB(165,160,150)
    vp.LightColor=Color3.fromRGB(255,244,226);vp.LightDirection=Vector3.new(-1,-1.4,-1.2);vp.Parent=parent
    if silhouette then vp.ImageColor3=Color3.new(0,0,0);vp.ImageTransparency=.12 end
    local model=Instance.new("Model");model.Name=id
    local top,wide=0,0
    local tint=rarityColor(species.Rarity)
    for _,d in Variants.build(id) do
        local big=math.max(d.size[1],d.size[2],d.size[3])
        if not detail and big<.36 then continue end
        local p=Instance.new("Part");p.Anchored=true;p.CanCollide=false;p.Size=Vector3.new(unpack(d.size))
        p.Shape=Enum.PartType[d.shape] or Enum.PartType.Block
        p.CFrame=CFrame.new(unpack(d.position))*CFrame.Angles(math.rad(d.pitch or 0),math.rad(d.yaw or 0),math.rad(d.roll or 0))
        local glow=d.palette=="energy"
        p.Color=if d.palette=="amber" or glow then tint else rgb(Config.Palette[d.palette] or {150,150,150})
        p.Material=if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
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
RunService.RenderStepped:Connect(function()
    local now=os.clock()
    for vp,entry in spinning do
        if not vp.Parent then spinning[vp]=nil
        else entry.model:PivotTo(CFrame.Angles(0,math.sin((now-entry.start)*.6)*.65,0)) end
    end
end)

function Dex.start(player,remote,hud)
    local playerGui=player:WaitForChild("PlayerGui")
    local data={dex={},mdex={},rebirths=0,multiplier=1,claimed={},projects={},perks={income=0,speed=0},titles={},title="",skins={"Default"},skin="Default",stats={built=0,unboxed=0},found=0,total=Catalog.Total}
    local tab,selected,compactDetail="Common",nil,false
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
    local gui=Instance.new("ScreenGui");gui.Name="Robotdex";gui.ResetOnSpawn=false;gui.DisplayOrder=20;gui.Enabled=false;gui.IgnoreGuiInset=true;gui.Parent=playerGui
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
            local card=Instance.new("TextButton");card.Text="";card.AutoButtonColor=true;card.LayoutOrder=s.Number;card.BackgroundColor3=if have then Color3.fromRGB(250,245,230) else Color3.fromRGB(214,203,178);card.Parent=grid;corner(card,8)
            local edge=stroke(card,if s.Id==selected then rarityColor(rarity) else Color3.fromRGB(180,164,134),if s.Id==selected then 3 else 1)
            if have and rarity=="Celestial" and s.Id==selected then Visuals.apply(card,rarity) end
            local picture=frame(card,Color3.new(),UDim2.fromOffset(4,18),UDim2.new(1,-8,1,-52));picture.BackgroundTransparency=1
            robotView(picture,s.Id,not have,false,false)
            text(card,string.format("#%03d",s.Number),11,MUTED,UDim2.fromOffset(7,4),UDim2.new(.5,0,0,13),FONT)
            text(card,s.Source=="Box" and "BOX" or "BUILD",10,if s.Source=="Box" then Color3.fromRGB(150,80,30) else MUTED,UDim2.new(.5,0,0,4),UDim2.new(.5,-7,0,13),FONT,Enum.TextXAlignment.Right)
            text(card,if have then s.Name else "???",12,INK,UDim2.new(0,6,1,-32),UDim2.new(1,-12,0,15),FONT,Enum.TextXAlignment.Center)
            text(card,if have then "×"..data.dex[s.Id].." owned" else "undiscovered",10,MUTED,UDim2.new(0,6,1,-16),UDim2.new(1,-12,0,13),Enum.Font.Gotham,Enum.TextXAlignment.Center)
            -- Mutation stars: gold and rainbow versions owned.
            for i,m in Mutations.List do
                if mutationCount(m.Id,s.Id)>0 then
                    local star=text(card,"★",15,rgb(m.Color),UDim2.new(0,4+(i-1)*14,0,16),UDim2.fromOffset(14,16),Enum.Font.GothamBlack,Enum.TextXAlignment.Center)
                    if m.Id=="Rainbow" then star.TextColor3=Color3.fromRGB(255,110,220) end
                end
            end
            card.Activated:Connect(function() selected=s.Id;compactDetail=true;render() end)
        end
    end

    -- RIGHT PAGE: one species.
    local function detailPage(page,id)
        local s=Catalog.get(id)
        local have=owned(id)
        local top=10
        if isCompact() then button(page,"< BACK",UDim2.fromOffset(12,8),UDim2.fromOffset(80,28),COVER,PAPER,function() compactDetail=false;render() end);top=42 end
        local view=frame(page,Color3.fromRGB(226,216,192),UDim2.fromOffset(14,top),UDim2.new(1,-28,.5,-top));corner(view,8)
        robotView(view,id,not have,true,have)
        text(view,string.format("#%03d",s.Number),16,MUTED,UDim2.fromOffset(10,8),UDim2.fromOffset(90,20),Enum.Font.GothamBlack)
        local pill=text(view,s.Rarity:upper(),12,Color3.new(1,1,1),UDim2.new(1,-110,0,8),UDim2.fromOffset(100,20),FONT,Enum.TextXAlignment.Center)
        pill.BackgroundTransparency=0;pill.BackgroundColor3=rarityColor(s.Rarity);pill.TextYAlignment=Enum.TextYAlignment.Center;corner(pill,10)
        if s.Rarity=="Celestial" then Visuals.apply(pill,"Celestial") end
        local y=0
        local info=scroll(page,0);info.Position=UDim2.new(0,14,.5,6);info.Size=UDim2.new(1,-24,.5,-14)
        local function line(value,size,color,font,height)
            local l=text(info,value,size,color,UDim2.fromOffset(0,y),UDim2.new(1,-8,0,height or size+6),font);y+=(height or size+6)+4;return l
        end
        line(if have then s.Name else "??? UNDISCOVERED",20,INK,Enum.Font.GothamBlack,24)
        local recipe=Config.Robot.Recipes[s.Rarity]
        local route=if s.Source=="Box" then "Found in "..s.Rarity.." Robot Boxes (events and rewards)" else "Built from "..recipe.Parts.." "..s.Rarity.." scrap parts"
        line(route,13,MUTED,FONT,18)
        line(string.format("%s chance: %.1f%%   ·   Income: $%d/sec (×%s)",s.Source=="Box" and "Box" or "Build",Catalog.chance(id)*100,Catalog.income(recipe.Income,id),tostring(s.Multiplier)),13,INK,Enum.Font.Gotham,18)
        if have then
            line('"'..s.Blurb..'"',14,INK,Enum.Font.GothamMedium,38)
            line(string.format("Obtained %d time%s.",data.dex[id],data.dex[id]==1 and "" or "s"),13,Color3.fromRGB(46,120,70),FONT,18)
            local parts={}
            for _,m in Mutations.List do
                local n=mutationCount(m.Id,id)
                table.insert(parts,if n>0 then string.format("%s ★ ×%d (x%d income)",m.Label,n,m.Multiplier) else string.format("%s: not found yet (%.0f%% per robot)",m.Label,m.Chance*100))
            end
            line(table.concat(parts,"   ·   "),12,Color3.fromRGB(150,110,20),FONT,32)
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
        local gold,rainbow=0,0
        for key,n in data.mdex or {} do if n>0 then if string.sub(key,1,5)=="Gold:" then gold+=1 elseif string.sub(key,1,8)=="Rainbow:" then rainbow+=1 end end end
        line(string.format("GOLD ★ %d / %d    RAINBOW ★ %d / %d",gold,Catalog.Total,rainbow,Catalog.Total),13,Color3.fromRGB(150,110,20),FONT,18)
        line(string.format("Built %d  ·  Unboxed %d  ·  Robotdex bonus +%d%%  ·  Speed bonus +%d",data.stats.built,data.stats.unboxed,data.perks.income,data.perks.speed),13,INK,FONT,34)
        line(string.format("Rebirth %d  ·  total income x%.2f  ·  %d platforms",data.rebirths or 0,data.multiplier or 1,data.slots or Config.Robot.Slots),13,INK,FONT,18)
        if player:GetAttribute("SaveStatus")=="offline" then line("Saving is off in this session.",12,Color3.fromRGB(170,60,40),FONT,18) else line("Your Robotdex is saved automatically.",12,Color3.fromRGB(46,120,70),FONT,18) end
    end

    local function rewardsPage(page)
        text(page,"REWARDS",20,INK,UDim2.fromOffset(14,10),UDim2.new(1,-28,0,24),Enum.Font.GothamBlack)
        text(page,"Claim milestone rewards as your Robotdex grows.",12,MUTED,UDim2.fromOffset(14,36),UDim2.new(1,-28,0,16))
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
        robotView(toastPicture,id,false,false,true)
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
            if packet.message then status.Text=packet.message end
            updateLauncher();render()
        elseif channel=="DexDiscovery" and type(packet.id)=="string" then
            discovered(packet.id,packet.mutation,packet.newSpecies~=false)
        end
    end)
    player:GetAttributeChangedSignal("DexClaimable"):Connect(updateLauncher)
    UserInputService.InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.I then open() end end)
    player.CharacterRemoving:Connect(close)
    book:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if gui.Enabled then render() end end)
    hud:GetPropertyChangedSignal("Enabled"):Connect(function() if not gui.Enabled then launcherGui.Enabled=hud.Enabled end end)
    remote:FireServer("RequestIndex")
    return open
end
return Dex
