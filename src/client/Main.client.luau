--!nonstrict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ContextActionService=game:GetService("ContextActionService")
local UserInputService=game:GetService("UserInputService")
local player=Players.LocalPlayer
local Config=require(ReplicatedStorage:WaitForChild("CatchTheScrapShared"):WaitForChild("Config"))
require(script.Parent:WaitForChild("RobotAnimator")).start()
local remotes=ReplicatedStorage:WaitForChild("CatchTheScrapRemotes")
local actionRemote=remotes:WaitForChild("Action")
local feedbackRemote=remotes:WaitForChild("Feedback")
local gui=Instance.new("ScreenGui")
gui.Name="CatchTheScrapHUD"
gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild("PlayerGui")
local function round(object,radius)
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,radius)
    corner.Parent=object
end
local panel=Instance.new("Frame")
panel.BackgroundColor3=Color3.fromRGB(18,26,35)
panel.BackgroundTransparency=.06
panel.Parent=gui
round(panel,12)
local constraint=Instance.new("UISizeConstraint")
constraint.Parent=panel
local stroke=Instance.new("UIStroke")
stroke.Color=Color3.fromRGB(74,94,108)
stroke.Parent=panel
local function text(parent,name,size,color)
    local label=Instance.new("TextLabel")
    label.Name=name
    label.BackgroundTransparency=1
    label.TextColor3=color or Color3.fromRGB(231,238,242)
    label.Font=Enum.Font.Gotham
    label.TextSize=size
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.TextWrapped=true
    label.AutoLocalize=false
    label.Parent=parent
    return label
end
local title=text(panel,"Title",20,Color3.fromRGB(255,198,80))
title.Font=Enum.Font.GothamBold
title.Text="CATCH THE SCRAP"
local home=text(panel,"Home",13)
local money=text(panel,"Money",23,Color3.fromRGB(110,240,180))
money.Font=Enum.Font.GothamBold
local recipes={}
for _,rarity in {"Common","Uncommon","Rare"} do
    local color=Color3.fromRGB(unpack(Config.Robot.Recipes[rarity].Color))
    local label=text(panel,rarity.."Recipe",13,color)
    local background=Instance.new("Frame")
    background.BackgroundColor3=Color3.fromRGB(43,57,69)
    background.BorderSizePixel=0
    background.Parent=panel
    local fill=Instance.new("Frame")
    fill.Size=UDim2.fromScale(0,1)
    fill.BackgroundColor3=color
    fill.BorderSizePixel=0
    fill.Parent=background
    round(background,2);round(fill,2)
    recipes[rarity]={label=label,background=background,fill=fill}
end
local carrying=text(panel,"Carrying",14)
local stats=text(panel,"Stats",12,Color3.fromRGB(150,208,214))
local message=text(panel,"Message",13,Color3.fromRGB(190,205,218))
local drop=Instance.new("TextButton")
drop.Name="Drop"
drop.AnchorPoint=Vector2.new(.5,1)
drop.Position=UDim2.new(.5,0,1,-26)
drop.BackgroundColor3=Color3.fromRGB(255,193,70)
drop.TextColor3=Color3.fromRGB(20,28,40)
drop.Font=Enum.Font.GothamBold
drop.TextSize=18
drop.Text=if UserInputService.KeyboardEnabled then "Drop [Q]" else "Drop part"
drop.AutoLocalize=false
drop.Visible=false
drop.Parent=gui
round(drop,12)
local note=text(gui,"SessionNote",11,Color3.fromRGB(210,220,230))
note.AnchorPoint=Vector2.new(.5,1)
note.Position=UDim2.new(.5,0,1,-4)
note.Size=UDim2.new(1,-32,0,18)
note.TextXAlignment=Enum.TextXAlignment.Center
note.Text="Prototype: parts, robots and cash last for this server session only."
local function place(label,y,height,size)
    label.Position=UDim2.fromOffset(14,y)
    label.Size=UDim2.new(1,-28,0,height)
    label.TextSize=size
end
local function layout()
    local compact=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y<500
    local height=if compact then 218 else 306
    panel.AnchorPoint=Vector2.new(if compact then 1 else 0,0)
    panel.Position=if compact then UDim2.new(1,-16,0,8) else UDim2.fromOffset(16,12)
    panel.Size=UDim2.new(1,-32,0,height)
    constraint.MaxSize=Vector2.new(if compact then 360 else 400,height)
    place(title,if compact then 6 else 10,24,if compact then 16 else 20)
    place(home,if compact then 29 else 39,18,if compact then 11 else 13)
    place(money,if compact then 49 else 65,27,if compact then 19 else 23)
    for index,rarity in {"Common","Uncommon","Rare"} do
        local row=recipes[rarity]
        local y=(if compact then 78 else 103)+(index-1)*(if compact then 18 else 25)
        place(row.label,y,16,if compact then 11 else 13)
        row.background.Position=UDim2.fromOffset(14,y+16)
        row.background.Size=UDim2.new(1,-28,0,3)
    end
    place(carrying,if compact then 136 else 184,24,if compact then 12 else 14)
    place(stats,if compact then 159 else 215,18,11)
    place(message,if compact then 180 else 242,if compact then 31 else 52,if compact then 11 else 13)
    drop.Size=UDim2.fromOffset(if compact then 180 else 200,if compact then 44 else 52)
end
local viewportConnection
local function watchCamera()
    if viewportConnection then viewportConnection:Disconnect() end
    if workspace.CurrentCamera then viewportConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout) end
    layout()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
local feedbackVersion=0
local function defaultMessage()
    if not remotes:GetAttribute("Ready") then return "Waiting for the scrapyard..." end
    if (player:GetAttribute("BaseIndex") or 0)==0 then return "All workshops are occupied. Try another server." end
    if (player:GetAttribute("CarriedName") or "")~="" then return "Return to your workshop. Hold E at the orange deposit machine." end
    if (player:GetAttribute("UsedPlatforms") or 0)>=Config.Robot.Slots then return "Platforms reserved. Finish existing robots with matching parts." end
    return "Follow yellow arrows into the yard. Collect matching parts to build robots."
end
local function render()
    local index=player:GetAttribute("BaseIndex") or 0
    home.Text=string.format("WORKSHOP %02d  |  ROBOTS %d/%d",index,player:GetAttribute("RobotCount") or 0,Config.Robot.Slots)
    money.Text=string.format("$%d   +$%d / SEC",player:GetAttribute("Cash") or 0,player:GetAttribute("IncomePerSecond") or 0)
    for rarity,row in recipes do
        local recipe=Config.Robot.Recipes[rarity]
        local count=player:GetAttribute(rarity.."Parts") or 0
        row.label.Text=string.format("%s  %d/%d PARTS  |  $%d/sec",rarity:upper(),count,recipe.Parts,recipe.Income)
        row.fill.Size=UDim2.fromScale(count/recipe.Parts,1)
    end
    local name=player:GetAttribute("CarriedName") or ""
    carrying.Text=if name=="" then "Hands free. Ready to collect." else name.." | "..(player:GetAttribute("CarriedRarity") or "")
    stats.Text=string.format("Weight: %d  |  Speed: %.1f  |  Delivered: %d",player:GetAttribute("CarriedWeight") or 0,player:GetAttribute("CarrySpeed") or Config.BaseSpeed,player:GetAttribute("DeliveredCount") or 0)
    drop.Visible=name~=""
    if feedbackVersion==0 then message.Text=defaultMessage() end
end
local function requestDrop()
    if (player:GetAttribute("CarriedName") or "")~="" then actionRemote:FireServer("Drop") end
end
drop.Activated:Connect(requestDrop)
ContextActionService:BindAction("CatchTheScrapDrop",function(_,state)
    if state==Enum.UserInputState.Begin then requestDrop() end
    return Enum.ContextActionResult.Pass
end,false,Enum.KeyCode.Q,Enum.KeyCode.ButtonB)
feedbackRemote.OnClientEvent:Connect(function(value)
    if typeof(value)~="string" then return end
    feedbackVersion+=1
    local version=feedbackVersion
    message.Text=value
    task.delay(5,function()
        if feedbackVersion==version then feedbackVersion=0;message.Text=defaultMessage() end
    end)
end)
for _,attribute in {"BaseIndex","DeliveredCount","CarriedName","CarriedRarity","CarriedWeight","CarrySpeed","Cash","IncomePerSecond","RobotCount","UsedPlatforms","CommonParts","UncommonParts","RareParts"} do
    player:GetAttributeChangedSignal(attribute):Connect(render)
end
remotes:GetAttributeChangedSignal("Ready"):Connect(render)
render()
