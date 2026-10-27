--!strict
export type Variant={Id:string,Name:string,Multiplier:number,Weight:number}
local Catalog={}
local list:{Variant}={
    {Id="Bastion",Name="Iron Bastion",Multiplier=1,Weight=30},
    {Id="Volt",Name="Volt Runner",Multiplier=1.15,Weight=24},
    {Id="Driller",Name="Drillmaster",Multiplier=1.35,Weight=20},
    {Id="Magnet",Name="Magnetron",Multiplier=1.5,Weight=14},
    {Id="Orbital",Name="Orbital Warden",Multiplier=1.8,Weight=9},
    {Id="Sunforge",Name="Sunforge Sentinel",Multiplier=2.25,Weight=3},
}
Catalog.List=list
function Catalog.get(id:string): Variant
    for _,v in list do if v.Id==id then return v end end
    error("Unknown robot variant: "..id)
end
function Catalog.income(base:number,id:string?): number
    return if id then math.floor(base*4*Catalog.get(id).Multiplier+.5) else base
end
function Catalog.roll(unit:number,exclude:string?): string
    assert(unit>=0 and unit<1,"Valid variant random sample required")
    local total=0
    for _,v in list do if v.Id~=exclude then total+=v.Weight end end
    local sample=unit*total
    for _,v in list do
        if v.Id==exclude then continue end
        sample-=v.Weight
        if sample<0 then return v.Id end
    end
    return list[1].Id
end
return Catalog
