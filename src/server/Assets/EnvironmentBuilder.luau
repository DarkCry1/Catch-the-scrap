--!nonstrict
local CollectionService=game:GetService("CollectionService")
local EnvironmentBuilder={}
function EnvironmentBuilder.create(parent,effects)
    for _,effect in effects do
        local anchor=Instance.new("Part")
        anchor.Name="AmbientAnchor";anchor.Size=Vector3.new(.2,.2,.2);anchor.Position=Vector3.new(unpack(effect.position))
        anchor.Anchored=true;anchor.Transparency=1;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false;anchor.CastShadow=false;anchor.Parent=parent
        local color=Color3.fromRGB(unpack(effect.color))
        local object
        if effect.kind=="lamp" then
            object=Instance.new("PointLight");object.Color=color;object.Brightness=1.3;object.Range=24;object.Shadows=false
        else
            local attachment=Instance.new("Attachment");attachment.Parent=anchor
            object=Instance.new("ParticleEmitter")
            object.Texture=if effect.kind=="sparks" then "rbxasset://textures/particles/sparkles_main.dds" else "rbxasset://textures/particles/smoke_main.dds"
            object.Color=ColorSequence.new(color)
            object.Rate=if effect.kind=="sparks" then 2 else .7
            object.Lifetime=NumberRange.new(1.2,3.5)
            object.Speed=NumberRange.new(1.2,2.8)
            object.SpreadAngle=Vector2.new(15,15)
            object.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(1,if effect.kind=="sparks" then .1 else 4)})
            object.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.9),NumberSequenceKeypoint.new(.3,.7),NumberSequenceKeypoint.new(1,1)})
            object.LightInfluence=.8;object.LightEmission=if effect.kind=="sparks" then .5 else 0
            object.Parent=attachment
        end
        object.Enabled=false
        if not object.Parent then object.Parent=anchor end
        CollectionService:AddTag(object,"YardAmbientEffect")
    end
end
return EnvironmentBuilder
