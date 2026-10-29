--!nonstrict
-- Mutation auras v2 (local, cosmetic). Every finished mutated robot (tag
-- "MutatedRobot", attribute Mutation) is wrapped in a layered aura, in the
-- spirit of the mutation auras of popular Roblox collection games. Rarer
-- mutations get more layers (tier 1 Gold ... tier 5 Galaxy):
--   * a heartbeat-pulsing glow over the whole robot (Highlight),
--   * rising aura flames around the body and a soft halo cloud,
--   * mutation particles (gold glints, diamond shards, rainbow sparkles,
--     lava flames/embers/smoke, galaxy stars and nebula mist),
--   * a rotating rune sigil on the floor with two pulse waves,
--   * a light column and energy spirals twisting up the robot,
--   * orbiting orbs/crystals with trails,
--   * a floating crown (gold spikes, diamond, halo, fire ring, planet),
--   * a floating mutation title with an animated gradient,
--   * signature extras: gold shine bursts, diamond prism rays, lava floor
--     cracks and eruptions, galaxy shooting stars,
--   * an ignition burst when a mutated robot first appears.
-- Built only near the camera; nearest robots get the Highlight (Roblox draws
-- at most 31) and full detail, farther ones a lighter version.
local CollectionService=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Config=require(game:GetService("ReplicatedStorage").CatchTheScrapShared.Config)
local Auras={enabled=true,active={}}
Auras.NearDistance=70

local SPARKLE="rbxasset://textures/particles/sparkles_main.dds"
local FIRE="rbxasset://textures/particles/fire_main.dds"
local EMBER="rbxasset://textures/particles/fire_sparks_main.dds"
local SMOKE="rbxasset://textures/particles/smoke_main.dds"
local GLOW="rbxasset://textures/particles/forcefield_glow_main.dds"

-- Per-mutation look. Colors are {r,g,b}. Particle "from": "body" (robot
-- volume) or "feet" (floor layer). rainbow=true cycles every color.
Auras.Styles={
    Gold={tier=1,color={255,198,64},accent={255,240,170},deep={200,120,20},fill=.68,pulse=.16,pillar=.7,wave=1.8,
        sigil={segments=10,inner=5},spirals=2,crown="Spikes",title={{255,250,210},{255,198,64},{200,120,20}},
        particles={
            {texture=GLOW,from="body",rate=4,colors={{255,206,80},{255,170,40}},size={2.8,3.8},transparency={.72,1},life={1.2,1.8},speed={0,.3},rot={-40,40}},
            {texture=SPARKLE,from="body",rate=18,colors={{255,236,140},{255,255,230}},size={.4,0},life={.7,1.3},speed={.3,1.2},accel={0,.8,0},rot={-90,90}},
            {texture=SPARKLE,from="feet",rate=8,colors={{255,214,90},{255,250,200}},size={.25,0},life={1.4,2.2},speed={1.5,2.6},accel={0,.4,0}},
        },
        flames={rate=22,colors={{255,226,120},{255,150,30}},size={1.5,.3},life={.8,1.2},speed={3,4.5}},
        orbit={count=3,radius=.75,speed=1.1,size=.32,shape="Ball",trail=true,height={.35,.75}},
        light={brightness=1.8,range=15,flicker=0},extra="Shine"},
    Diamond={tier=2,color={140,226,255},accent={255,255,255},deep={60,140,220},fill=.66,pulse=.18,pillar=.68,wave=2.2,
        sigil={segments=12,inner=6},spirals=2,crown="Crystal",title={{255,255,255},{150,230,255},{80,160,240}},
        particles={
            {texture=GLOW,from="body",rate=5,colors={{170,236,255},{120,200,255}},size={3,4},transparency={.7,1},life={1.2,1.9},speed={0,.25},rot={-30,30}},
            {texture=SPARKLE,from="body",rate=24,colors={{255,255,255},{150,230,255}},size={.5,0},life={.5,1},speed={.2,.8},rot={-200,200}},
            {texture=SMOKE,from="feet",rate=4,colors={{200,240,255},{160,220,255}},size={1.4,2.8},transparency={.8,1},life={2,3},speed={.3,.6}},
        },
        flames={rate=24,colors={{235,250,255},{120,200,255}},size={1.4,.25},life={.8,1.3},speed={3,4.5}},
        orbit={count=4,radius=.8,speed=.7,size=.42,shape="Crystal",trail=false,height={.25,.85}},
        light={brightness=2,range=16,flicker=0},extra="Prism"},
    Rainbow={tier=3,color={255,110,220},accent={255,255,255},deep={120,80,255},fill=.64,pulse=.16,pillar=.66,wave=1.5,rainbow=true,
        sigil={segments=14,inner=7},spirals=3,crown="Halo",title="rainbow",
        particles={
            {texture=GLOW,from="body",rate=6,colors="rainbow",size={2.8,4},transparency={.66,1},life={1.2,1.8},speed={0,.3},rot={-60,60}},
            {texture=SPARKLE,from="body",rate=26,colors="rainbow",size={.45,0},life={.7,1.3},speed={.4,1.4},accel={0,.6,0},rot={-120,120}},
            {texture=SPARKLE,from="feet",rate=10,colors="rainbow",size={.3,0},life={1.4,2.2},speed={1.5,2.5},accel={0,.4,0}},
        },
        flames={rate=28,colors="rainbow",size={1.5,.3},life={.8,1.3},speed={3,5}},
        orbit={count=5,radius=.82,speed=1.6,size=.3,shape="Ball",trail=true,height={.2,.9}},
        light={brightness=2,range=16,flicker=0},extra="Spectrum"},
    Lava={tier=4,color={255,104,36},accent={255,200,70},deep={150,20,10},fill=.62,pulse=.22,pillar=.7,wave=1.3,
        sigil={segments=12,inner=6},spirals=3,crown="Fire",title={{255,240,150},{255,120,30},{170,20,10}},
        particles={
            {texture=GLOW,from="body",rate=5,colors={{255,120,40},{200,40,10}},size={2.8,3.8},transparency={.66,1},life={1,1.6},speed={0,.4},rot={-40,40}},
            {texture=FIRE,from="feet",rate=22,colors={{255,190,60},{255,70,20}},size={1.5,.2},transparency={.2,1},life={.6,1.1},speed={2,4},accel={0,3,0}},
            {texture=EMBER,from="body",rate=18,colors={{255,220,90},{255,90,20}},size={.2,0},life={1,1.8},speed={1.5,3},accel={0,2.5,0},spread=25},
            {texture=SMOKE,from="feet",rate=4,colors={{60,40,36},{30,24,22}},size={1.2,3.4},transparency={.7,1},life={2.2,3.2},speed={1.2,2},accel={0,.8,0}},
        },
        flames={rate=30,colors={{255,220,100},{255,60,10}},size={1.7,.3},life={.7,1.1},speed={3.5,5.5}},
        orbit=nil,
        light={brightness=2.4,range=17,flicker=.45},extra="Cracks"},
    Galaxy={tier=5,color={168,112,255},accent={110,220,255},deep={60,20,140},fill=.6,pulse=.18,pillar=.62,wave=2,
        sigil={segments=16,inner=8},spirals=4,crown="Planet",title={{110,220,255},{168,112,255},{255,110,220}},
        particles={
            {texture=GLOW,from="body",rate=7,colors={{150,90,255},{255,110,220}},size={3.2,4.4},transparency={.64,1},life={1.6,2.4},speed={0,.25},rot={-30,30}},
            {texture=SMOKE,from="body",rate=5,colors={{120,60,220},{255,90,200}},size={1.6,3.2},transparency={.7,1},life={2.4,3.4},speed={.1,.4},rot={-25,25}},
            {texture=SPARKLE,from="body",rate=28,colors={{255,255,255},{110,220,255}},size={.32,0},life={.6,1.5},speed={.1,.6},rot={-90,90}},
            {texture=SPARKLE,from="feet",rate=10,colors={{255,110,220},{168,112,255}},size={.28,0},life={1.6,2.6},speed={1,2},accel={0,.5,0}},
        },
        flames={rate=30,colors={{110,220,255},{168,112,255}},size={1.7,.3},life={.9,1.4},speed={3,4.8}},
        orbit={count=6,radius=.95,speed=.9,size=.28,shape="Ball",trail=true,height={.15,1},tilt=.35},
        light={brightness=2.2,range=17,flicker=0},extra="Stars"},
}

local function rgb(t) return Color3.fromRGB(t[1],t[2],t[3]) end
local function hueColor(h) return Color3.fromHSV(h%1,.65,1) end
local function sequence(colors)
    if colors=="rainbow" then
        local keys={}
        for i=0,6 do table.insert(keys,ColorSequenceKeypoint.new(i/6,hueColor(i/6))) end
        return ColorSequence.new(keys)
    end
    if #colors>=3 then
        return ColorSequence.new({ColorSequenceKeypoint.new(0,rgb(colors[1])),ColorSequenceKeypoint.new(.5,rgb(colors[2])),ColorSequenceKeypoint.new(1,rgb(colors[3]))})
    end
    return ColorSequence.new(rgb(colors[1]),rgb(colors[2]))
end
local function part(folder,name,size,cframe,color,shape,material)
    local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cframe;p.Color=color;p.Material=material or Enum.Material.Neon
    p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
    if shape then p.Shape=shape end
    p.Parent=folder;return p
end
local function emitter(parent,spec,scale)
    local e=Instance.new("ParticleEmitter");e.Texture=spec.texture or GLOW;e.Rate=spec.rate*scale;e.Color=sequence(spec.colors)
    e.Size=NumberSequence.new(spec.size[1],spec.size[2])
    e.Transparency=if spec.transparency then NumberSequence.new(spec.transparency[1],spec.transparency[2]) else NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(.7,.3),NumberSequenceKeypoint.new(1,1)})
    e.Lifetime=NumberRange.new(spec.life[1],spec.life[2]);e.Speed=NumberRange.new(spec.speed[1],spec.speed[2])
    e.SpreadAngle=Vector2.new(spec.spread or 180,spec.spread or 180);e.LightEmission=1;e.LightInfluence=0
    if spec.rot then e.RotSpeed=NumberRange.new(spec.rot[1],spec.rot[2]);e.Rotation=NumberRange.new(0,360) end
    if spec.accel then e.Acceleration=Vector3.new(spec.accel[1],spec.accel[2],spec.accel[3]) end
    e.Parent=parent
    return e
end

-- Build one robot's aura. Returns an entry with everything to animate/destroy.
function Auras.build(folder,model,mutation,ignite)
    local style=Auras.Styles[mutation];if not style then return nil end
    local bboxCFrame,size=model:GetBoundingBox()
    local pivot=model:GetPivot()
    local width=math.max(size.X,size.Z)
    local floor=pivot.Position.Y
    local center=Vector3.new(bboxCFrame.Position.X,bboxCFrame.Position.Y,bboxCFrame.Position.Z)
    local base=CFrame.new(center.X,floor,center.Z)
    local top=floor+size.Y
    local scale=1+(style.tier-1)*.18
    local holder=Instance.new("Folder");holder.Name="Aura_"..model.Name;holder.Parent=folder
    local color,accent,deep=rgb(style.color),rgb(style.accent),rgb(style.deep)
    local entry={model=model,style=style,holder=holder,base=base,width=width,height=size.Y,top=top,scale=scale,phase=math.random()*10,
        orbs={},emitters={},sigil={},spirals={},crown={},cracks={},rays={},lod=1,frame=0,nextBurst=0}

    -- Glow over the robot.
    local glow=Instance.new("Highlight");glow.Name="AuraGlow";glow.Adornee=model;glow.FillColor=color;glow.OutlineColor=accent
    glow.FillTransparency=style.fill;glow.OutlineTransparency=.1;glow.DepthMode=Enum.HighlightDepthMode.Occluded;glow.Enabled=false;glow.Parent=holder
    entry.highlight=glow

    -- Emitter volumes: the robot body, a floor layer and a ring of flames.
    local body=part(holder,"AuraBody",Vector3.new(size.X*.8,size.Y*.85,size.Z*.8),CFrame.new(center),color);body.Transparency=1
    local feet=part(holder,"AuraFeet",Vector3.new(width*1.1,.2,width*1.1),base*CFrame.new(0,.15,0),color);feet.Transparency=1
    local ringZone=part(holder,"AuraFlameRing",Vector3.new(width*1.35,.2,width*1.35),base*CFrame.new(0,.1,0),color);ringZone.Transparency=1
    for _,spec in style.particles do
        local e=emitter(if spec.from=="feet" then feet else body,spec,scale)
        if spec.from=="feet" then e.EmissionDirection=Enum.NormalId.Top end
        table.insert(entry.emitters,{emitter=e,rate=e.Rate})
    end
    -- Rising aura flames: tall stretched glow wisps from a ring around the robot.
    local flames=emitter(ringZone,{texture=GLOW,rate=style.flames.rate,colors=style.flames.colors,size=style.flames.size,
        transparency={.12,1},life=style.flames.life,speed=style.flames.speed,accel={0,2.5,0},spread=8},scale*1.35)
    flames.Name="AuraFlames";flames.EmissionDirection=Enum.NormalId.Top;flames.Drag=1.2
    -- v1.9: bigger, brighter flames (they read weak in Studio lighting).
    local fs=style.flames.size[1]*1.3
    flames.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,fs*.6),NumberSequenceKeypoint.new(.3,fs),NumberSequenceKeypoint.new(1,style.flames.size[2])})
    pcall(function()
        flames.Squash=NumberSequence.new(1.6,2.4)
        flames.Shape=Enum.ParticleEmitterShape.Disc;flames.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface;flames.ShapePartial=.75
    end)
    table.insert(entry.emitters,{emitter=flames,rate=flames.Rate})
    entry.flames=flames
    -- Burst emitter (ignition, shine, eruptions).
    local burst=emitter(body,{texture=SPARKLE,rate=0,colors={style.accent,style.color},size={.7,0},life={.6,1.2},speed={8,16},rot={-200,200}},1)
    burst.Name="AuraBurst";burst.Rate=0;burst.Drag=3;entry.burst=burst

    -- Floor: faint glow disc, rotating rune sigil, two pulse waves.
    local ring=part(holder,"AuraRing",Vector3.new(.06,width*1.4,width*1.4),base*CFrame.new(0,.06,0)*CFrame.Angles(0,0,math.pi/2),color,Enum.PartType.Cylinder)
    ring.Transparency=.72;entry.ring=ring
    local radius=width*.72
    for i=1,style.sigil.segments do
        local seg=part(holder,"AuraRune",Vector3.new(.5*scale,.08,radius*2*math.pi/style.sigil.segments*.62),base,accent)
        table.insert(entry.sigil,{part=seg,angle=(i-1)/style.sigil.segments*math.pi*2,radius=radius,dir=1,y=.09})
    end
    for i=1,style.sigil.inner do
        local mark=part(holder,"AuraMark",Vector3.new(.55,.08,.55)*scale,base,color)
        table.insert(entry.sigil,{part=mark,angle=(i-1)/style.sigil.inner*math.pi*2,radius=radius*.62,dir=-1,y=.1,diamond=true})
    end
    entry.waves={}
    for i=1,2 do
        local wave=part(holder,"AuraWave",Vector3.new(.05,width,width),ring.CFrame,accent,Enum.PartType.Cylinder);wave.Transparency=1
        table.insert(entry.waves,{part=wave,offset=(i-1)*.5})
    end
    entry.wave=entry.waves[1].part

    -- Light column and energy spirals.
    local a0=Instance.new("Attachment");a0.Parent=feet
    local a1=Instance.new("Attachment");a1.Position=Vector3.new(0,size.Y+6,0);a1.Parent=feet
    local column=Instance.new("Beam");column.Name="AuraColumn";column.Attachment0=a0;column.Attachment1=a1;column.FaceCamera=true
    column.Width0=width*1.25;column.Width1=width*.45;column.LightEmission=1;column.LightInfluence=0;column.Segments=1
    column.Color=ColorSequence.new(color,accent)
    local pillar=style.pillar-.14
    column.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,pillar),NumberSequenceKeypoint.new(.6,(1+pillar)/2),NumberSequenceKeypoint.new(1,1)})
    column.Parent=feet;entry.column=column
    local spinner=part(holder,"AuraSpinner",Vector3.one*.2,base,color);spinner.Transparency=1;entry.spinner=spinner
    for i=1,style.spirals do
        local angle=(i-1)/style.spirals*math.pi*2
        local s0=Instance.new("Attachment");s0.Position=Vector3.new(math.cos(angle)*radius*.9,.2,math.sin(angle)*radius*.9);s0.Parent=spinner
        local s1=Instance.new("Attachment");s1.Position=Vector3.new(math.cos(angle+math.pi)*radius*.35,size.Y*1.15,math.sin(angle+math.pi)*radius*.35);s1.Parent=spinner
        local spiral=Instance.new("Beam");spiral.Name="AuraSpiral";spiral.Attachment0=s0;spiral.Attachment1=s1;spiral.FaceCamera=true;spiral.Segments=24
        spiral.CurveSize0=radius*1.6;spiral.CurveSize1=-radius*1.2;spiral.Width0=.35*scale;spiral.Width1=.08;spiral.LightEmission=1;spiral.LightInfluence=0
        spiral.Color=ColorSequence.new(accent,color)
        spiral.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.25),NumberSequenceKeypoint.new(.8,.4),NumberSequenceKeypoint.new(1,1)})
        spiral.Parent=spinner
        table.insert(entry.spirals,spiral)
    end

    -- Orbiting orbs/crystals with trails.
    local orbit=style.orbit
    if orbit then
        for i=1,orbit.count do
            local shape=if orbit.shape=="Ball" then Enum.PartType.Ball else nil
            local orb=part(holder,"AuraOrb",if orbit.shape=="Crystal" then Vector3.new(orbit.size*.7,orbit.size*1.6,orbit.size*.7) else Vector3.one*orbit.size*scale,base,if i%2==0 then accent else color,shape)
            if orbit.shape=="Crystal" then orb.Material=Enum.Material.Glass;orb.Transparency=.15;orb.Reflectance=.4 end
            local trail
            if orbit.trail then
                local t0=Instance.new("Attachment");t0.Position=Vector3.new(0,orbit.size*.45,0);t0.Parent=orb
                local t1=Instance.new("Attachment");t1.Position=Vector3.new(0,-orbit.size*.45,0);t1.Parent=orb
                trail=Instance.new("Trail");trail.Attachment0=t0;trail.Attachment1=t1;trail.Lifetime=.55;trail.LightEmission=1;trail.FaceCamera=true
                trail.Color=if style.rainbow then sequence("rainbow") else ColorSequence.new(orb.Color,deep);trail.Transparency=NumberSequence.new(.2,1);trail.Parent=orb
            end
            local h=orbit.height[1]+(orbit.height[2]-orbit.height[1])*((i-1)/math.max(1,orbit.count-1))
            table.insert(entry.orbs,{part=orb,trail=trail,angle=(i-1)/orbit.count*math.pi*2,height=h*size.Y,dir=if i%2==0 then -1 else 1})
        end
    end

    -- Crown floating over the head.
    local crownY=size.Y+1.6
    entry.crownY=crownY
    if style.crown=="Spikes" then
        for i=1,5 do
            local spike=part(holder,"AuraCrown",Vector3.new(.3,.9,.3),base,accent);table.insert(entry.crown,{part=spike,angle=(i-1)/5*math.pi*2,radius=.65,y=0})
        end
        local band=part(holder,"AuraCrown",Vector3.new(.18,1.6,1.6),base,color,Enum.PartType.Cylinder);table.insert(entry.crown,{part=band,ring=true,y=-.4})
    elseif style.crown=="Crystal" then
        local gem=part(holder,"AuraCrown",Vector3.new(.8,1.5,.8),base,Color3.fromRGB(210,245,255),nil,Enum.Material.Glass);gem.Transparency=.1;gem.Reflectance=.5
        table.insert(entry.crown,{part=gem,gem=true,y=0})
        local core=part(holder,"AuraCrown",Vector3.new(.35,.35,.35),base,Color3.new(1,1,1),Enum.PartType.Ball);table.insert(entry.crown,{part=core,y=0})
    elseif style.crown=="Halo" or style.crown=="Fire" then
        for i=1,10 do
            local bead=part(holder,"AuraCrown",Vector3.one*.28,base,if i%2==0 then accent else color,Enum.PartType.Ball)
            table.insert(entry.crown,{part=bead,angle=(i-1)/10*math.pi*2,radius=1.05,y=0})
        end
        if style.crown=="Fire" then
            local fireZone=part(holder,"AuraCrownFire",Vector3.new(1.8,.2,1.8),base*CFrame.new(0,crownY,0),color);fireZone.Transparency=1
            local f=emitter(fireZone,{texture=FIRE,rate=26,colors={{255,220,90},{255,60,10}},size={.8,.1},transparency={.2,1},life={.4,.7},speed={1.5,3},accel={0,2,0},spread=10},1)
            f.EmissionDirection=Enum.NormalId.Top;table.insert(entry.emitters,{emitter=f,rate=f.Rate})
        end
    elseif style.crown=="Planet" then
        local planet=part(holder,"AuraCrown",Vector3.one*.9,base,Color3.fromRGB(120,70,220),Enum.PartType.Ball,Enum.Material.SmoothPlastic)
        planet.Reflectance=.3;table.insert(entry.crown,{part=planet,y=.2,planet=true})
        local planetRing=part(holder,"AuraCrown",Vector3.new(.05,1.9,1.9),base,accent,Enum.PartType.Cylinder);planetRing.Transparency=.25
        table.insert(entry.crown,{part=planetRing,y=.2,planetRing=true})
        local moon=part(holder,"AuraCrown",Vector3.one*.3,base,Color3.fromRGB(255,110,220),Enum.PartType.Ball);table.insert(entry.crown,{part=moon,angle=0,radius=1.4,y=.2,moon=true})
    end

    -- Floating title.
    local title=Instance.new("BillboardGui");title.Name="AuraTitle";title.Size=UDim2.fromOffset(220,54);title.StudsOffsetWorldSpace=Vector3.new(0,size.Y*.5+3.6,0)
    title.MaxDistance=95;title.LightInfluence=0;title.Adornee=body;title.Parent=holder
    local label=Instance.new("TextLabel");label.Name="Label";label.Size=UDim2.new(1,0,.66,0);label.BackgroundTransparency=1;label.Font=Enum.Font.GothamBlack;label.TextScaled=true
    label.Text="★ "..string.upper(mutation).." ★";label.TextColor3=Color3.new(1,1,1);label.AutoLocalize=false;label.Parent=title
    local labelStroke=Instance.new("UIStroke");labelStroke.Color=deep;labelStroke.Thickness=2.5;labelStroke.Parent=label
    local gradient=Instance.new("UIGradient");gradient.Color=sequence(style.title);gradient.Parent=label
    local sub=Instance.new("TextLabel");sub.Name="Multiplier";sub.Position=UDim2.fromScale(0,.64);sub.Size=UDim2.new(1,0,.36,0);sub.BackgroundTransparency=1;sub.Font=Enum.Font.GothamBold;sub.TextScaled=true
    local m=Config.Mutations;local mult=1;for _,info in m do if info.Id==mutation then mult=info.Multiplier end end
    sub.Text=string.format("x%g INCOME",mult);sub.TextColor3=accent;sub.TextStrokeTransparency=.3;sub.AutoLocalize=false;sub.Parent=title
    entry.title=title;entry.gradient=gradient;entry.labelStroke=labelStroke

    -- Signature extras.
    if style.extra=="Prism" then
        for i=1,3 do
            local r0=Instance.new("Attachment");r0.Parent=spinner
            local r1=Instance.new("Attachment");r1.Parent=spinner
            local ray=Instance.new("Beam");ray.Name="AuraPrism";ray.Attachment0=r0;ray.Attachment1=r1;ray.FaceCamera=true;ray.Width0=.12;ray.Width1=.5
            ray.LightEmission=1;ray.LightInfluence=0;ray.Color=ColorSequence.new(Color3.new(1,1,1),color)
            ray.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,.35),NumberSequenceKeypoint.new(1,1)});ray.Parent=spinner
            table.insert(entry.rays,{a=r0,b=r1,angle=(i-1)/3*math.pi,beam=ray})
        end
    elseif style.extra=="Cracks" then
        for i=1,8 do
            local a=(i-1)/8*math.pi*2+.2
            local length=width*(.55+.25*((i*7)%3)/2)
            local crack=part(holder,"AuraCrack",Vector3.new(.16,.05,length),base*CFrame.Angles(0,a,0)*CFrame.new(0,.07,-length/2-width*.15),Color3.fromRGB(255,120,30))
            table.insert(entry.cracks,crack)
        end
    elseif style.extra=="Stars" then
        local starZone=part(holder,"AuraStarfield",Vector3.new(width*2.2,size.Y*1.6,width*2.2),CFrame.new(center),color);starZone.Transparency=1
        local stars=emitter(starZone,{texture=SPARKLE,rate=14,colors={{255,255,255},{200,230,255}},size={.18,0},transparency={0,1},life={1.2,2.4},speed={0,.05},rot={-40,40}},1)
        table.insert(entry.emitters,{emitter=stars,rate=stars.Rate})
        local comet=part(holder,"AuraComet",Vector3.one*.35,base,Color3.new(1,1,1),Enum.PartType.Ball)
        local c0=Instance.new("Attachment");c0.Position=Vector3.new(0,.15,0);c0.Parent=comet
        local c1=Instance.new("Attachment");c1.Position=Vector3.new(0,-.15,0);c1.Parent=comet
        local tail=Instance.new("Trail");tail.Attachment0=c0;tail.Attachment1=c1;tail.Lifetime=.5;tail.LightEmission=1;tail.FaceCamera=true;tail.WidthScale=NumberSequence.new(1,0)
        tail.Color=ColorSequence.new(Color3.new(1,1,1),accent);tail.Transparency=NumberSequence.new(0,1);tail.Parent=comet
        comet.Transparency=1;entry.comet=comet;entry.cometTrail=tail
    end

    local light=Instance.new("PointLight");light.Name="AuraLight";light.Color=color;light.Brightness=style.light.brightness;light.Range=style.light.range*scale;light.Shadows=false;light.Parent=body
    entry.light=light

    -- Ignition: a flash sphere and a spark burst when the robot first appears.
    if ignite then
        local flash=part(holder,"AuraIgnite",Vector3.one*width*.6,CFrame.new(center),accent,Enum.PartType.Ball);flash.Transparency=.1
        TweenService:Create(flash,TweenInfo.new(.7,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=Vector3.one*width*3.2,Transparency=1}):Play()
        task.delay(.75,function() if flash.Parent then flash:Destroy() end end)
        pcall(function() burst:Emit(60) end)
    end
    return entry
end

function Auras.destroy(entry)
    if entry.holder then entry.holder:Destroy() end
end

-- Near robots get full detail; far ones fewer particles, no trails.
function Auras.setLod(entry,lod)
    if entry.lod==lod then return end
    entry.lod=lod
    local factor=if lod==1 then 1 else .45
    for _,item in entry.emitters do item.emitter.Rate=item.rate*factor end
    for _,o in entry.orbs do if o.trail then o.trail.Enabled=lod==1 end end
    for _,spiral in entry.spirals do spiral.Enabled=lod==1 or entry.style.tier>=3 end
    entry.title.Enabled=lod==1
end

-- Per-frame animation for one aura.
function Auras.step(entry,now)
    local style=entry.style
    entry.frame+=1
    local t=now+entry.phase
    -- Heartbeat: a strong beat and a softer echo every 1.2 s.
    local beatPhase=(t%1.2)/1.2
    local beat=math.max(math.exp(-((beatPhase-.08)^2)/.004),.6*math.exp(-((beatPhase-.28)^2)/.004))
    local hue=if style.rainbow then hueColor(t*.25) else nil
    if entry.highlight.Enabled then
        entry.highlight.FillTransparency=style.fill+style.pulse*(1-beat)
        entry.highlight.OutlineTransparency=.05+.3*(1-beat)
        if hue then entry.highlight.FillColor=hue;entry.highlight.OutlineColor=hueColor(t*.25+.5) end
    end
    entry.light.Brightness=style.light.brightness*(.75+.45*beat)
    if style.light.flicker>0 then
        entry.light.Brightness*=(1-style.light.flicker*.5+style.light.flicker*math.noise(t*6,entry.phase))
    end
    entry.ring.Transparency=.72-.18*beat
    if hue then entry.ring.Color=hue;entry.column.Color=ColorSequence.new(hue,hueColor(t*.25+.33)) end
    for _,w in entry.waves do
        local k=((t/style.wave)+w.offset)%1
        local d=entry.width*(1+k*1.6)
        w.part.Size=Vector3.new(.05,d,d);w.part.Transparency=.3+.7*k
        w.part.CFrame=entry.base*CFrame.new(0,.08+k*.04,0)*CFrame.Angles(0,0,math.pi/2)
        if hue then w.part.Color=hueColor(t*.25+w.offset) end
    end
    -- Far auras animate the heavier pieces at a third of the frame rate.
    if entry.lod>1 and entry.frame%3~=0 then return end
    for i,seg in entry.sigil do
        local a=seg.angle+t*.5*seg.dir
        local cf=entry.base*CFrame.Angles(0,a,0)*CFrame.new(0,seg.y,-seg.radius)
        seg.part.CFrame=if seg.diamond then cf*CFrame.Angles(0,math.pi/4,0) else cf*CFrame.Angles(0,math.pi/2,0)
        if hue then seg.part.Color=hueColor(t*.25+i/#entry.sigil) end
    end
    entry.spinner.CFrame=entry.base*CFrame.Angles(0,t*1.4,0)
    local orbit=style.orbit
    if orbit then
        local radius=entry.width*orbit.radius
        local tilt=CFrame.Angles(orbit.tilt or 0,0,(orbit.tilt or 0)*.6)
        for i,o in entry.orbs do
            local a=o.angle+t*orbit.speed*o.dir
            local bob=math.sin(t*1.7+i)*.35
            o.part.CFrame=entry.base*CFrame.new(0,o.height,0)*tilt*CFrame.new(math.cos(a)*radius,bob,math.sin(a)*radius)*CFrame.Angles(0,t*2,if orbit.shape=="Crystal" then .5 else 0)
            if hue then o.part.Color=hueColor(t*.25+i/#entry.orbs) end
        end
    end
    local crownBase=entry.base*CFrame.new(0,entry.crownY+math.sin(t*1.6)*.25,0)
    for i,c in entry.crown do
        if c.ring then c.part.CFrame=crownBase*CFrame.new(0,c.y,0)*CFrame.Angles(0,t,math.pi/2)
        elseif c.planetRing then c.part.CFrame=crownBase*CFrame.new(0,c.y,0)*CFrame.Angles(.5,t*.6,math.pi/2+.35)
        elseif c.moon then local a=t*1.8;c.part.CFrame=crownBase*CFrame.new(math.cos(a)*c.radius,c.y+math.sin(a)*.4,math.sin(a)*c.radius)
        elseif c.radius then
            local a=c.angle+t*1.1
            c.part.CFrame=crownBase*CFrame.new(math.cos(a)*c.radius,c.y,math.sin(a)*c.radius)
            if hue then c.part.Color=hueColor(t*.25+i/#entry.crown) end
        else c.part.CFrame=crownBase*CFrame.new(0,c.y,0)*CFrame.Angles(0,t*1.3,if c.gem then .2 else 0) end
    end
    -- Title shimmer.
    entry.gradient.Offset=Vector2.new(math.sin(t*1.3)*.35,0);entry.gradient.Rotation=(t*40)%360
    if hue then entry.gradient.Color=ColorSequence.new(hueColor(t*.25),hueColor(t*.25+.4));entry.labelStroke.Color=hueColor(t*.25+.6) end
    -- Signature extras.
    if style.extra=="Prism" then
        for _,r in entry.rays do
            local a=r.angle+t*.35
            local reach=entry.width*1.6
            local mid=entry.height*.55
            r.a.Position=Vector3.new(math.cos(a)*reach,mid+math.sin(t+a)*1.2,math.sin(a)*reach)
            r.b.Position=Vector3.new(-math.cos(a)*reach,mid-math.sin(t+a)*1.2,-math.sin(a)*reach)
        end
    elseif style.extra=="Cracks" then
        for i,crack in entry.cracks do crack.Transparency=.15+.55*(math.noise(t*3,i*.7)+.5) end
    elseif style.extra=="Stars" and entry.comet then
        local k=(t%3.2)/3.2
        if k<.35 then
            local p=k/.35
            local from=Vector3.new(-entry.width*2.2,entry.height*1.6,-entry.width)
            local to=Vector3.new(entry.width*2.2,entry.height*.4,entry.width)
            entry.comet.Transparency=0;entry.cometTrail.Enabled=true
            entry.comet.CFrame=entry.base*CFrame.new(from:Lerp(to,p))
        else entry.comet.Transparency=1;entry.cometTrail.Enabled=false end
    end
    -- Periodic bursts: gold shine and lava eruptions.
    if (style.extra=="Shine" or style.extra=="Cracks") and now>=entry.nextBurst then
        entry.nextBurst=now+(if style.extra=="Shine" then 2.6 else 3.4)
        pcall(function() entry.burst:Emit(if style.extra=="Shine" then 14 else 26) end)
    end
end

function Auras.start(player)
    local settings=Config.Auras
    local folder=Instance.new("Folder");folder.Name="LocalMutationAuras";folder.Parent=workspace
    local tracked={}
    local started=os.clock()
    local function revealed(model)
        local at=model:GetAttribute("RevealAt")
        return at==nil or workspace:GetServerTimeNow()>=at
    end
    local function drop(model)
        local entry=Auras.active[model]
        if entry then Auras.destroy(entry);Auras.active[model]=nil end
    end
    local function track(model,fresh)
        if model:IsA("Model") then tracked[model]={fresh=fresh==true} end
    end
    local function untrack(model) tracked[model]=nil;drop(model) end
    CollectionService:GetInstanceAddedSignal("MutatedRobot"):Connect(function(model) track(model,os.clock()-started>2) end)
    CollectionService:GetInstanceRemovedSignal("MutatedRobot"):Connect(untrack)
    for _,model in CollectionService:GetTagged("MutatedRobot") do track(model,false) end

    -- Every half second: build auras in range, drop far ones, pick detail
    -- levels and give the nearest robots the Highlight.
    local function refresh()
        local camera=workspace.CurrentCamera
        local eye=camera and camera.CFrame.Position
        local ranked={}
        for model,info in tracked do
            if not model.Parent then untrack(model);continue end
            local mutation=model:GetAttribute("Mutation")
            local entry=Auras.active[model]
            if entry and entry.style~=Auras.Styles[mutation] then drop(model);entry=nil;info.fresh=true end
            local distance=if eye then (model:GetPivot().Position-eye).Magnitude else 0
            local wanted=Auras.enabled and settings.Enabled and Auras.Styles[mutation]~=nil and distance<=settings.Distance and revealed(model)
            if wanted and not entry then
                entry=Auras.build(folder,model,mutation,info.fresh);Auras.active[model]=entry;info.fresh=false
            elseif not wanted and entry and (not Auras.enabled or distance>settings.Distance+20 or not Auras.Styles[mutation]) then drop(model);entry=nil end
            if entry then
                Auras.setLod(entry,if distance<=Auras.NearDistance then 1 else 2)
                table.insert(ranked,{entry=entry,distance=distance})
            end
        end
        table.sort(ranked,function(a,b) return a.distance<b.distance end)
        for i,item in ranked do item.entry.highlight.Enabled=i<=settings.MaxHighlights end
    end
    Auras.refresh=refresh
    local elapsed=1
    RunService.RenderStepped:Connect(function(dt)
        elapsed+=dt
        if elapsed>=.5 then elapsed=0;refresh() end
        local now=os.clock()
        for _,entry in Auras.active do Auras.step(entry,now) end
    end)
end

function Auras.setEnabled(value)
    Auras.enabled=value==true
    if not Auras.enabled then
        for model,entry in Auras.active do Auras.destroy(entry);Auras.active[model]=nil end
    end
    if Auras.refresh then Auras.refresh() end
end
return Auras
