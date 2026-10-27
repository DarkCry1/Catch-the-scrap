--!nonstrict
-- Local-only, noncolliding presentation geometry and short particle bursts.
local Parts={}
function Parts.new(parent,name,size,frame,color,material,shape)
    local object=Instance.new("Part");object.Name=name;object.Size=size;object.CFrame=frame
    object.Color=color;object.Material=material or Enum.Material.Metal;object.Shape=shape or Enum.PartType.Block
    object.Anchored=true;object.CanCollide=false;object.CanQuery=false;object.CanTouch=false;object.CastShadow=false;object.Parent=parent
    return object
end
function Parts.model(name,details,origin,parent)
    local model=Instance.new("Model");model.Name=name
    for _,d in details do
        Parts.new(model,d.name,Vector3.new(unpack(d.size)),origin*CFrame.new(unpack(d.position))*CFrame.Angles(math.rad(d.pitch or 0),math.rad(d.yaw or 0),math.rad(d.roll or 0)),Color3.fromRGB(unpack(d.color)),Enum.Material[d.material],Enum.PartType[d.shape])
    end
    model.WorldPivot=origin;model.Parent=parent
    return model
end
function Parts.burst(parent,origin,color,count)
    local anchor=Parts.new(parent,"RevealBurst",Vector3.one*.1,origin,color);anchor.Transparency=1
    local emitter=Instance.new("ParticleEmitter");emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"
    emitter.Rate=0;emitter.Lifetime=NumberRange.new(.35,.85);emitter.Speed=NumberRange.new(6,13);emitter.SpreadAngle=Vector2.new(180,180)
    emitter.Acceleration=Vector3.new(0,-10,0);emitter.Drag=2;emitter.LightEmission=1;emitter.Color=ColorSequence.new(color)
    emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.22),NumberSequenceKeypoint.new(1,0)})
    emitter.Parent=anchor;emitter:Emit(count)
    game:GetService("Debris"):AddItem(anchor,1.2)
end
return Parts
