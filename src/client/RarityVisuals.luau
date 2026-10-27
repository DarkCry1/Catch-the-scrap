--!nonstrict
local RunService=game:GetService("RunService")
local Style=require(game:GetService("ReplicatedStorage").CatchTheScrapShared.RarityStyle)
local UI={}
local active={}
local started=false
local function rainbow()
    local stops={}
    for i=0,6 do table.insert(stops,ColorSequenceKeypoint.new(i/6,Color3.fromHSV(i/6,.85,1))) end
    return ColorSequence.new(stops)
end
function UI.apply(frame,rarity)
    local old=active[frame]
    if old then old.rarity=rarity;old.gradient.Enabled=rarity=="Celestial";old.stroke.Color=Color3.fromRGB(unpack(Style.get(rarity).Color));return end
    local stroke=frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke");stroke.Name="RarityBorder";stroke.Thickness=2;stroke.Color=Color3.fromRGB(unpack(Style.get(rarity).Color));stroke.Parent=frame
    local gradient=Instance.new("UIGradient");gradient.Color=rainbow();gradient.Enabled=rarity=="Celestial";gradient.Parent=stroke
    active[frame]={rarity=rarity,gradient=gradient,stroke=stroke}
    frame.Destroying:Connect(function() active[frame]=nil end)
    if not started then
        started=true
        RunService.RenderStepped:Connect(function()
            local now=os.clock()
            for object,entry in active do
                if entry.rarity=="Celestial" and object.Parent then
                    entry.stroke.Color=Color3.new(1,1,1)
                    entry.gradient.Rotation=(now*60)%360
                    entry.gradient.Offset=Vector2.new(math.sin(now*.7)*.18,math.cos(now*.7)*.18)
                end
            end
        end)
    end
end
function UI.color(rarity,time,phase) return Color3.fromRGB(unpack(Style.rgb(rarity,time,phase))) end
return UI
