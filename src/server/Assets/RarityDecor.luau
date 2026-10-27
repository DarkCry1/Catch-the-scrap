--!nonstrict
local Tags=game:GetService("CollectionService")
local Shared=game:GetService("ReplicatedStorage").CatchTheScrapShared
local Style=require(Shared.RarityStyle)
local Frame=require(Shared.RarityFrame)
local Decor={}
function Decor.spectrum(object,phase)
    object:SetAttribute("HuePhase",phase or 0);Tags:AddTag(object,"RaritySpectrum")
end
function Decor.frame(parent,origin,rarity,pivot)
    local tint=Color3.fromRGB(unpack(Style.get(rarity).Color))
    for _,edge in Frame.build() do
        local part=Instance.new("Part");part.Name="RarityFrame";part.Size=Vector3.new(unpack(edge.size));part.CFrame=origin*CFrame.new(unpack(edge.position))
        part.Color=tint;part.Material=Enum.Material.Neon;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.CastShadow=false;part.Massless=true;part.Anchored=not pivot;part.Parent=parent
        if pivot then local weld=Instance.new("WeldConstraint");weld.Part0=pivot;weld.Part1=part;weld.Parent=part end
        if rarity=="Celestial" then Decor.spectrum(part,edge.phase) end
    end
end
function Decor.aura(model,anchor,rarity,isBox)
    local profile=Style.get(rarity)
    if profile.Rank<4 then return end
    local tint=Color3.fromRGB(unpack(profile.Color))
    local point=Instance.new("PointLight");point.Name="RarityGlow";point.Color=tint
    point.Range=if isBox then 14+profile.Rank else 6;point.Brightness=if isBox then 1.2+profile.Rank*.15 else .45;point.Shadows=false;point.Enabled=false;point.Parent=anchor
    point:SetAttribute("Rarity",rarity);point:SetAttribute("BoxPriority",isBox);Tags:AddTag(point,"RarityAmbient")
    local particles=Instance.new("ParticleEmitter");particles.Name="RarityMotes";particles.Texture="rbxasset://textures/particles/sparkles_main.dds"
    particles.Rate=profile.Particles;particles.Lifetime=NumberRange.new(.7,1.4);particles.Speed=NumberRange.new(.5,1.8);particles.SpreadAngle=Vector2.new(180,180)
    particles.Acceleration=Vector3.new(0,.9,0);particles.Drag=1;particles.LightEmission=.85;particles.Enabled=false;particles.Color=ColorSequence.new(tint)
    particles.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.13),NumberSequenceKeypoint.new(1,0)});particles.Parent=anchor
    particles:SetAttribute("Rarity",rarity);particles:SetAttribute("BoxPriority",isBox);Tags:AddTag(particles,"RarityAmbient")
    if rarity=="Celestial" then Decor.spectrum(point,0);Decor.spectrum(particles,.2) end
end
return Decor
