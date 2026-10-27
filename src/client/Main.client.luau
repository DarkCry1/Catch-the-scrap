--!nonstrict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ContextActionService=game:GetService("ContextActionService")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local StarterGui=game:GetService("StarterGui")
local player=Players.LocalPlayer
local Shared=ReplicatedStorage:WaitForChild("CatchTheScrapShared")
local Config=require(Shared:WaitForChild("Config"))
local Model=require(Shared:WaitForChild("HudModel"))
local remotes=ReplicatedStorage:WaitForChild("CatchTheScrapRemotes")
local actionRemote=remotes:WaitForChild("Action")
local feedbackRemote=remotes:WaitForChild("Feedback")
-- Each presentation module starts independently so a cosmetic failure cannot stop the HUD.
for _,name in {"GuardianAnimator","RarityWorldEffects","CarryPose","Feel","RobotAnimator","EnvironmentEffects","CameraGuard","PickupAnimator","RareBoxAnnouncements","WorkshopEffects","UnboxingEffects","RebirthCinematic","ButtonFx"} do
    task.spawn(function()
        local ok,err=pcall(function() require(script.Parent:WaitForChild(name)).start(player,actionRemote) end)
        if not ok then warn("[Catch the Scrap] "..name..": "..tostring(err)) end
    end)
end
task.spawn(function()
    for _=1,5 do
        if pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end) then break end
        task.wait(.5)
    end
end)
local gui=Instance.new("ScreenGui");gui.Name="CatchTheScrapHUD";gui.ResetOnSpawn=false;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=player:WaitForChild("PlayerGui")
local function round(o,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o end
local function card(parent,name,class)
    local f=Instance.new(class or "Frame");f.Name=name;f.BackgroundColor3=Color3.fromRGB(18,29,40);f.BackgroundTransparency=.06;f.Parent=parent;round(f,12)
    local edge=Instance.new("UIStroke");edge.Color=Color3.fromRGB(67,90,107);edge.Transparency=.35;edge.Parent=f;return f
end
local function text(parent,name,size,tint)
    local l=Instance.new("TextLabel");l.Name=name;l.BackgroundTransparency=1;l.TextColor3=tint or Color3.fromRGB(227,237,243);l.Font=Enum.Font.Gotham
    l.TextSize=size;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextWrapped=true;l.AutoLocalize=false;l.Parent=parent;return l
end
local function button(parent,name,title,tint)
    local b=Instance.new("TextButton");b.Name=name;b.Text=title;b.TextColor3=tint or Color3.fromRGB(224,237,245);b.BackgroundColor3=Color3.fromRGB(36,53,68)
    b.Font=Enum.Font.GothamBold;b.TextSize=12;b.AutoLocalize=false;b.Parent=parent;round(b,8);return b
end
local wallet=card(gui,"Wallet");wallet.Position=UDim2.fromOffset(14,12);wallet.Size=UDim2.fromOffset(244,82)
local money=text(wallet,"Cash",28,Color3.fromRGB(112,240,182));money.Font=Enum.Font.GothamBold;money.Position=UDim2.fromOffset(14,8);money.Size=UDim2.new(1,-94,0,34)
local income=text(wallet,"Income",13,Color3.fromRGB(160,187,201));income.Position=UDim2.fromOffset(15,48);income.Size=UDim2.new(1,-96,0,20)
local base=button(wallet,"Base","BASE 01");base.Position=UDim2.new(1,-80,0,12);base.Size=UDim2.fromOffset(68,26)
local detailsButton=button(wallet,"Details","DETAILS");detailsButton.Position=UDim2.new(1,-80,0,46);detailsButton.Size=UDim2.fromOffset(68,23)
local context=card(gui,"CurrentGoal");context.AnchorPoint=Vector2.new(.5,1);context.Position=UDim2.new(.5,0,1,-20);context.Size=UDim2.fromOffset(400,70)
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(400,70);limit.Parent=context
local title=text(context,"Goal",15);title.Font=Enum.Font.GothamBold;title.Position=UDim2.fromOffset(14,9);title.Size=UDim2.new(1,-112,0,23)
local hint=text(context,"Hint",12,Color3.fromRGB(165,191,206));hint.Position=UDim2.fromOffset(14,34);hint.Size=UDim2.new(1,-112,0,19)
local progress=Instance.new("Frame");progress.Position=UDim2.new(0,14,1,-7);progress.Size=UDim2.new(1,-28,0,2);progress.BackgroundColor3=Color3.fromRGB(51,74,87);progress.BorderSizePixel=0;progress.Parent=context
local fill=Instance.new("Frame");fill.Size=UDim2.fromScale(0,1);fill.BackgroundColor3=Color3.fromRGB(255,193,76);fill.BorderSizePixel=0;fill.Parent=progress
local drop=button(context,"Drop",if UserInputService.KeyboardEnabled then "DROP [Q]" else "DROP",Color3.fromRGB(255,201,90));drop.AnchorPoint=Vector2.new(1,.5);drop.Position=UDim2.new(1,-12,.5,-2);drop.Size=UDim2.fromOffset(84,36)
local details=card(gui,"DetailsPanel","ScrollingFrame");details.CanvasSize=UDim2.fromOffset(0,424);details.ScrollBarThickness=3;details.BorderSizePixel=0;details.ClipsDescendants=true;details.Position=UDim2.fromOffset(100,102);details.Size=UDim2.fromOffset(290,330);details.Visible=false
local detailsTitle=text(details,"Heading",15);detailsTitle.Text="YOUR WORKSHOP";detailsTitle.Font=Enum.Font.GothamBold;detailsTitle.Position=UDim2.fromOffset(14,10);detailsTitle.Size=UDim2.new(1,-60,0,24)
local close=button(details,"Close","X");close.Position=UDim2.new(1,-42,0,9);close.Size=UDim2.fromOffset(28,26)
local stats=text(details,"Stats",12,Color3.fromRGB(174,202,216));stats.Position=UDim2.fromOffset(14,40);stats.Size=UDim2.new(1,-28,0,50)
local rows={}
for i,stage in Config.Stages do
    local l=text(details,stage.Rarity,12,Color3.fromRGB(unpack(stage.Color)));l.Position=UDim2.fromOffset(14,94+(i-1)*22);l.Size=UDim2.new(1,-28,0,20);rows[stage.Rarity]=l
end
local carryLabel=text(details,"CarryStyle",11);carryLabel.Text="CARRY METHOD";carryLabel.Position=UDim2.fromOffset(14,294);carryLabel.Size=UDim2.new(1,-28,0,18)
local methods={}
for i,style in {"Auto","Harness"} do
    local b=button(details,"Carry"..style,if style=="Auto" then "TWO HANDS" else "HARNESS");b.Position=UDim2.fromOffset(14+(i-1)*134,317);b.Size=UDim2.fromOffset(126,28);methods[style]=b
    b.Activated:Connect(function() actionRemote:FireServer("SetCarryStyle",style) end)
end
local note=text(details,"SessionNote",10,Color3.fromRGB(143,166,181));note.Text="Progress saves automatically.";note.Position=UDim2.fromOffset(14,353);note.Size=UDim2.new(1,-28,0,18)
local toast=card(gui,"Feedback");toast.AnchorPoint=Vector2.new(.5,1);toast.Position=UDim2.new(.5,0,1,-99);toast.Size=UDim2.fromOffset(420,48);toast.Visible=false
local message=text(toast,"Message",13);message.Position=UDim2.fromOffset(12,4);message.Size=UDim2.new(1,-24,1,-8);message.TextXAlignment=Enum.TextXAlignment.Center;message.TextScaled=true
local messageSize=Instance.new("UITextSizeConstraint");messageSize.MinTextSize=11;messageSize.MaxTextSize=13;messageSize.Parent=message
local zone=1
local function render()
    local carried=player:GetAttribute("CarriedName") or ""
    local index=player:GetAttribute("BaseIndex") or 0
    income.Text="+"..Model.money(player:GetAttribute("IncomePerSecond") or 0).." / SEC"
    base.Text=string.format("BASE %02d",index)
    local counts={}
    for _,stage in Config.Stages do
        local count=player:GetAttribute(stage.Rarity.."Parts") or 0;counts[stage.Rarity]=count
        local recipe=Config.Robot.Recipes[stage.Rarity]
        rows[stage.Rarity].Text=string.format("%s   %d / %d    $%d/sec",stage.Rarity,count,recipe.Parts,recipe.Income)
    end
    local heading,sub,ratio=Model.context(remotes:GetAttribute("Ready")==true,index,carried,player:GetAttribute("CarriedKind") or "",player:GetAttribute("CarriedRarity") or "",player:GetAttribute("UsedPlatforms") or 0,counts,zone,player:GetAttribute("PlatformCount"))
    -- New-player guide replaces the goal card until the first robot is shown off.
    local guideTitle,guideHint,guideRatio=Model.tutorial(player:GetAttribute("TutorialStep") or Model.TutorialSteps,carried~="",counts.Common or 0)
    if guideTitle and index>0 then heading,sub,ratio=guideTitle,guideHint,guideRatio end
    title.Text=heading;hint.Text=sub;fill.Size=UDim2.fromScale(ratio,1);drop.Visible=carried~=""
    local space=if drop.Visible then -112 else -28;title.Size=UDim2.new(1,space,0,23);hint.Size=UDim2.new(1,space,0,19)
    stats.Text=string.format("Robots %d/%d  ·  Speed %.1f  ·  Rebirth %d\nStrength %d  ·  Carrying %d weight\nIncome multiplier x%.2f",player:GetAttribute("RobotCount") or 0,player:GetAttribute("PlatformCount") or Config.Robot.Slots,player:GetAttribute("CarrySpeed") or Config.BaseSpeed,player:GetAttribute("Rebirths") or 0,player:GetAttribute("CarryStrength") or Config.Strength,player:GetAttribute("CarriedWeight") or 0,player:GetAttribute("IncomeMultiplier") or 1)
    carryLabel.Text="CARRY METHOD"..(if carried~="" then " / "..string.upper(player:GetAttribute("CarryMode") or "") else "")
    for style,b in methods do b.BackgroundColor3=if (player:GetAttribute("CarryStyle") or "Auto")==style then Color3.fromRGB(48,114,113) else Color3.fromRGB(36,53,68) end
end
local function requestDrop()
    if gui.Enabled and not UserInputService:GetFocusedTextBox() and (player:GetAttribute("CarriedName") or "")~="" then actionRemote:FireServer("Drop") end
end
drop.Activated:Connect(requestDrop)
ContextActionService:BindAction("CatchTheScrapDrop",function(_,state)
    if state==Enum.UserInputState.Begin then requestDrop() end;return Enum.ContextActionResult.Pass
end,false,Enum.KeyCode.Q,Enum.KeyCode.ButtonB)
local function toggle() details.Visible=not details.Visible end
detailsButton.Activated:Connect(toggle);base.Activated:Connect(toggle);close.Activated:Connect(function() details.Visible=false end)
local version=0
feedbackRemote.OnClientEvent:Connect(function(value)
    if type(value)~="string" then return end
    version+=1;local current=version;message.Text=value;toast.Visible=true
    task.delay(4,function() if version==current then toast.Visible=false end end)
end)
local function layout()
    local camera=workspace.CurrentCamera;local width=if camera then camera.ViewportSize.X else 800
    wallet.Size=UDim2.fromOffset(math.min(244,width-(if player:GetAttribute("CanAdmin") then 130 else 28)),82)
    context.Size=UDim2.fromOffset(math.min(400,width-28),70);toast.Size=UDim2.fromOffset(math.min(420,width-28),48)
    details.Size=UDim2.fromOffset(math.min(290,width-114),math.min(330,math.max(100,(if camera then camera.ViewportSize.Y else 800)-206)))
end
local viewport
local function watchCamera()
    if viewport then viewport:Disconnect() end
    if workspace.CurrentCamera then viewport=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout) end;layout()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera);watchCamera()
for _,attribute in {"BaseIndex","Cash","IncomePerSecond","RobotCount","UsedPlatforms","CarriedName","CarriedKind","CarriedRarity","CarriedWeight","CarrySpeed","CarryStrength","CarryStyle","CarryMode","CommonParts","UncommonParts","RareParts","EpicParts","LegendaryParts","MythicParts","CelestialParts","TutorialStep","PlatformCount","Rebirths","IncomeMultiplier"} do player:GetAttributeChangedSignal(attribute):Connect(render) end
player:GetAttributeChangedSignal("CanAdmin"):Connect(layout)
player:GetAttributeChangedSignal("SaveStatus"):Connect(function()
    note.Text=if player:GetAttribute("SaveStatus")=="offline" then "Saving is off this session." else "Progress saves automatically."
end)
remotes:GetAttributeChangedSignal("Ready"):Connect(render)
-- Cash counts up smoothly toward the server value (big jumps animate faster).
local shownCash=player:GetAttribute("Cash") or 0
RunService.RenderStepped:Connect(function(dt)
    local target=player:GetAttribute("Cash") or 0
    if math.abs(target-shownCash)<1 then shownCash=target else shownCash+=(target-shownCash)*(1-math.exp(-8*dt)) end
    local text=Model.money(math.floor(shownCash+.5))
    if money.Text~=text then money.Text=text end
end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt;if elapsed<.4 then return end;elapsed=0
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then local current=math.clamp(math.floor((root.Position.Z-Config.TrackStart)/Config.ZoneLength)+1,1,#Config.Stages);if current~=zone then zone=current;render() end end
end)
render()
require(script.Parent:WaitForChild("MechanicShop")).start(player,actionRemote,gui)
require(script.Parent:WaitForChild("AdminMenu")).start(player,actionRemote,gui)

local openIndex=require(script.Parent:WaitForChild("Robotdex")).start(player,actionRemote,gui)
for _,name in {"QuestsPanel","RebirthPanel"} do
    local ok,err=pcall(function() require(script.Parent:WaitForChild(name)).start(player,actionRemote,gui) end)
    if not ok then warn("[Catch the Scrap] "..name..": "..tostring(err)) end
end
local indexButton=button(details,"Robotdex","ROBOTDEX [I]")
indexButton.Position=UDim2.fromOffset(14,255);indexButton.Size=UDim2.new(1,-28,0,28)
indexButton.Activated:Connect(function() details.Visible=false;openIndex() end)
-- Sound on/off (local only).
local Audio=require(script.Parent:WaitForChild("Audio"))
local soundButton=button(details,"Sound","SOUND: ON")
soundButton.Position=UDim2.fromOffset(14,378);soundButton.Size=UDim2.new(1,-28,0,28)
soundButton.Activated:Connect(function()
    Audio.setMuted(not Audio.muted)
    soundButton.Text=if Audio.muted then "SOUND: OFF" else "SOUND: ON"
end)
