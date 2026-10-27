--!nonstrict
local Tags=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local Style=require(game:GetService("ReplicatedStorage").CatchTheScrapShared.RarityStyle)
local Effects={}
local function position(object)
    local parent=object
    for _=1,8 do
        if not parent then return nil end
        if parent:IsA("BasePart") then return parent.Position end
        if parent:IsA("Attachment") then return parent.WorldPosition end
        parent=parent.Parent
    end
    return nil
end
function Effects.start(player)
    local spectrum,ambient={},{}
    local function spectrumAdd(o) spectrum[o]=o:GetAttribute("HuePhase") or 0 end
    local function ambientAdd(o) o.Enabled=false;ambient[o]=true end
    Tags:GetInstanceAddedSignal("RaritySpectrum"):Connect(spectrumAdd)
    Tags:GetInstanceRemovedSignal("RaritySpectrum"):Connect(function(o) spectrum[o]=nil end)
    Tags:GetInstanceAddedSignal("RarityAmbient"):Connect(ambientAdd)
    Tags:GetInstanceRemovedSignal("RarityAmbient"):Connect(function(o) ambient[o]=nil;if o.Parent then o.Enabled=false end end)
    for _,o in Tags:GetTagged("RaritySpectrum") do spectrumAdd(o) end
    for _,o in Tags:GetTagged("RarityAmbient") do ambientAdd(o) end
    local elapsed,budgetTime=0,0
    RunService.Heartbeat:Connect(function(dt)
        elapsed+=dt;budgetTime+=dt;if elapsed<1/30 then return end;elapsed=0
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local now=workspace:GetServerTimeNow()
        for o,phase in spectrum do
            local p=position(o)
            if root and p and (root.Position-p).Magnitude<140 then
                local tint=Color3.fromRGB(unpack(Style.rgb("Celestial",now,phase)))
                if o:IsA("BasePart") or o:IsA("Light") then o.Color=tint
                elseif o:IsA("Beam") or o:IsA("ParticleEmitter") then o.Color=ColorSequence.new(tint)
                elseif o:IsA("TextLabel") then o.TextColor3=tint end
            end
        end
        if budgetTime<.2 then return end;budgetTime=0
        local candidates={}
        for o in ambient do
            local p=position(o);local distance=if p and root then (root.Position-p).Magnitude else math.huge
            o.Enabled=false
            if distance<110 then table.insert(candidates,{object=o,score=distance-(if o:GetAttribute("BoxPriority") then 1000 else 0)}) end
        end
        table.sort(candidates,function(a,b) return a.score<b.score end)
        local lights,emitters=0,0
        for _,c in candidates do
            local o=c.object
            if o:IsA("Light") and lights<8 then lights+=1;o.Enabled=true
            elseif o:IsA("ParticleEmitter") and emitters<12 then emitters+=1;o.Enabled=true end
        end
    end)
end
return Effects
