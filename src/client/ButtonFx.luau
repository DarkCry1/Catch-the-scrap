--!nonstrict
-- Smooth hover and press feedback for every button in the player's GUI:
-- scale up and glow on hover (Quint easing), dip on press, spring back on
-- release, plus soft hover and click sounds. Applied automatically to buttons
-- created at any time; set attribute NoButtonFx=true to opt out.
local TweenService=game:GetService("TweenService")
local Audio=require(script.Parent.Audio)
local Fx={}
Fx.HoverScale=1.06
Fx.PressScale=.95
Fx.In=TweenInfo.new(.18,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
Fx.Out=TweenInfo.new(.28,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
Fx.Press=TweenInfo.new(.08,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
Fx.Release=TweenInfo.new(.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out)

local managed=setmetatable({},{__mode="k"})

function Fx.attach(button)
    if managed[button] or button:GetAttribute("NoButtonFx") then return end
    if not (button:IsA("TextButton") or button:IsA("ImageButton")) then return end
    managed[button]=true
    button.AutoButtonColor=false
    local scale=button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale");scale.Parent=button
    -- White glow layer tinted over the button (keeps the button's own colors).
    local glow=Instance.new("Frame");glow.Name="HoverGlow";glow.BackgroundColor3=Color3.new(1,1,1);glow.BackgroundTransparency=1
    glow.BorderSizePixel=0;glow.Size=UDim2.fromScale(1,1);glow.ZIndex=button.ZIndex+1;glow.Active=false;glow.Parent=button
    local corner=button:FindFirstChildOfClass("UICorner")
    if corner then local c=Instance.new("UICorner");c.CornerRadius=corner.CornerRadius;c.Parent=glow end
    local hovering,pressed=false,false
    local function live() return button.Active and button.Visible end
    local function settle(info)
        local target=if pressed and live() then Fx.PressScale elseif hovering and live() then Fx.HoverScale else 1
        TweenService:Create(scale,info,{Scale=target}):Play()
        TweenService:Create(glow,info,{BackgroundTransparency=if hovering and live() then (if pressed then .78 else .86) else 1}):Play()
    end
    button.MouseEnter:Connect(function()
        hovering=true;settle(Fx.In)
        if live() and Audio.Cues.Hover and #Audio.Cues.Hover>0 then Audio.play("Hover") end
    end)
    button.MouseLeave:Connect(function() hovering=false;pressed=false;settle(Fx.Out) end)
    button.MouseButton1Down:Connect(function() pressed=true;settle(Fx.Press) end)
    button.MouseButton1Up:Connect(function() pressed=false;settle(Fx.Release) end)
    button.Activated:Connect(function()
        local label=if button:IsA("TextButton") then string.upper(button.Text) else ""
        Audio.play(if not live() then "Deny" elseif string.sub(label,1,5)=="CLAIM" then "ClaimPress" else "Click")
        if not hovering then
            -- Touch/gamepad: a quick pop instead of a hover state.
            scale.Scale=Fx.PressScale;TweenService:Create(scale,Fx.Release,{Scale=1}):Play()
        end
    end)
end

function Fx.start(player)
    local gui=player:WaitForChild("PlayerGui")
    for _,object in gui:GetDescendants() do Fx.attach(object) end
    gui.DescendantAdded:Connect(function(object)
        if object:IsA("TextButton") or object:IsA("ImageButton") then task.defer(Fx.attach,object) end
    end)
end
return Fx
