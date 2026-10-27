--!nonstrict
-- Shared look for the side-dock panels (Daily quests, Rebirth): the same
-- leather-and-paper field manual style as the Robotdex.
local Kit={}
Kit.PAPER=Color3.fromRGB(238,230,208)
Kit.PAPER_DARK=Color3.fromRGB(222,211,184)
Kit.INK=Color3.fromRGB(44,36,28)
Kit.MUTED=Color3.fromRGB(122,106,86)
Kit.COVER=Color3.fromRGB(64,38,26)
Kit.BRASS=Color3.fromRGB(214,168,82)
Kit.GREEN=Color3.fromRGB(46,132,82)
Kit.RED=Color3.fromRGB(150,60,40)

function Kit.corner(o,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 8);c.Parent=o;return c end
function Kit.stroke(o,color,t) local s=Instance.new("UIStroke");s.Color=color;s.Thickness=t or 1;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=o;return s end
function Kit.frame(parent,color,pos,size,name)
    local f=Instance.new("Frame");f.Name=name or "Frame";f.BackgroundColor3=color or Kit.PAPER;f.BorderSizePixel=0
    f.Position=pos or UDim2.new();f.Size=size or UDim2.fromScale(1,1);f.Parent=parent;return f
end
function Kit.text(parent,value,size,color,pos,dims,font,align)
    local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Text=value;l.TextSize=size;l.TextColor3=color or Kit.INK;l.Font=font or Enum.Font.Gotham
    l.Position=pos or UDim2.new();l.Size=dims or UDim2.new(1,0,0,size+4);l.TextWrapped=true;l.AutoLocalize=false
    l.TextXAlignment=align or Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Top;l.Parent=parent;return l
end
function Kit.button(parent,value,pos,dims,color,ink,callback)
    local b=Instance.new("TextButton");b.Text=value;b.Font=Enum.Font.GothamBold;b.TextSize=13;b.TextColor3=ink or Kit.PAPER;b.BackgroundColor3=color or Kit.COVER
    b.Position=pos;b.Size=dims;b.AutoLocalize=false;b.AutoButtonColor=true;b.Parent=parent;Kit.corner(b,7)
    if callback then b.Activated:Connect(callback) end
    return b
end
function Kit.money(n)
    n=math.floor(n or 0)
    if n>=1e12 then return string.format("$%.1fT",n/1e12) elseif n>=1e9 then return string.format("$%.1fB",n/1e9) elseif n>=1e6 then return string.format("$%.1fM",n/1e6) elseif n>=1e4 then return string.format("$%.1fK",n/1e3) end
    return "$"..n
end

-- A small leather tab on the left screen edge (below the Robotdex launcher).
function Kit.launcher(playerGui,name,title,offsetY)
    local gui=Instance.new("ScreenGui");gui.Name=name.."Launcher";gui.ResetOnSpawn=false;gui.DisplayOrder=5;gui.Parent=playerGui
    local b=Instance.new("TextButton");b.Name=name;b.Text="";b.AutoLocalize=false;b.AnchorPoint=Vector2.new(0,.5)
    b.Position=UDim2.new(0,10,.5,offsetY);b.Size=UDim2.fromOffset(78,54);b.BackgroundColor3=Kit.COVER;b.Parent=gui;Kit.corner(b,10);Kit.stroke(b,Kit.BRASS,2)
    Kit.text(b,title,12,Kit.BRASS,UDim2.fromOffset(4,8),UDim2.new(1,-8,0,16),Enum.Font.GothamBlack,Enum.TextXAlignment.Center)
    local sub=Kit.text(b,"",12,Kit.PAPER,UDim2.fromOffset(4,28),UDim2.new(1,-8,0,16),Enum.Font.GothamBold,Enum.TextXAlignment.Center)
    local badge=Instance.new("TextLabel");badge.Name="Claimable";badge.AnchorPoint=Vector2.new(.5,.5);badge.Position=UDim2.new(1,-2,0,4);badge.Size=UDim2.fromOffset(22,22)
    badge.BackgroundColor3=Color3.fromRGB(226,58,52);badge.TextColor3=Color3.new(1,1,1);badge.Font=Enum.Font.GothamBlack;badge.TextSize=12;badge.AutoLocalize=false;badge.Visible=false;badge.Parent=b;Kit.corner(badge,11)
    return gui,b,sub,badge
end

-- A centered paper panel with a leather frame and close button.
function Kit.panel(playerGui,name,title,maxSize)
    local gui=Instance.new("ScreenGui");gui.Name=name;gui.ResetOnSpawn=false;gui.DisplayOrder=21;gui.Enabled=false;gui.IgnoreGuiInset=true;gui.Parent=playerGui
    local dim=Kit.frame(gui,Color3.fromRGB(6,9,13));dim.BackgroundTransparency=.35
    local cover=Kit.frame(dim,Kit.COVER,UDim2.fromScale(.5,.5),UDim2.new(1,-20,1,-20),"Cover");cover.AnchorPoint=Vector2.new(.5,.5);Kit.corner(cover,14);Kit.stroke(cover,Color3.fromRGB(30,16,10),3)
    local limit=Instance.new("UISizeConstraint");limit.MaxSize=maxSize;limit.Parent=cover
    Kit.text(cover,title,20,Kit.BRASS,UDim2.fromOffset(20,10),UDim2.new(1,-80,0,24),Enum.Font.GothamBlack)
    local close=Kit.button(cover,"X",UDim2.new(1,-48,0,8),UDim2.fromOffset(36,30),Color3.fromRGB(110,40,30),Kit.PAPER)
    local page=Kit.frame(cover,Kit.PAPER,UDim2.fromOffset(12,46),UDim2.new(1,-24,1,-82),"Page");Kit.corner(page,8)
    local status=Kit.text(cover,"",12,Color3.fromRGB(240,214,160),UDim2.new(0,18,1,-28),UDim2.new(1,-36,0,16))
    return gui,page,close,status
end
return Kit
