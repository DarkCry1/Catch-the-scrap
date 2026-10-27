--!strict
export type Variant={Id:string,Name:string,Multiplier:number,Weight:number,Source:string}
local Catalog={}
local list:{Variant}={
    {Id="Bastion",Name="Iron Bastion",Multiplier=1,Weight=30,Source="Build"},
    {Id="Volt",Name="Volt Runner",Multiplier=1.15,Weight=24,Source="Both"},
    {Id="Driller",Name="Drillmaster",Multiplier=1.35,Weight=20,Source="Build"},
    {Id="Magnet",Name="Magnetron",Multiplier=1.5,Weight=14,Source="Both"},
    {Id="Orbital",Name="Orbital Warden",Multiplier=1.8,Weight=9,Source="Box"},
    {Id="Sunforge",Name="Sunforge Sentinel",Multiplier=2.25,Weight=3,Source="Box"},
    {Id="Weldsmith",Name="Arc Weldsmith",Multiplier=1.25,Weight=18,Source="Build"},
    {Id="Hauler",Name="Scrap Hauler",Multiplier=1.4,Weight=16,Source="Build"},
    {Id="Prism",Name="Prism Oracle",Multiplier=2,Weight=6,Source="Box"},
    {Id="Chrono",Name="Chrono Knight",Multiplier=2.5,Weight=2,Source="Box"},
}
Catalog.List=list
function Catalog.find(id:string): Variant?
    for _,v in list do if v.Id==id then return v end end
    return nil
end
function Catalog.get(id:string): Variant return assert(Catalog.find(id),"Unknown robot variant: "..id) end
function Catalog.source(rarity:string,id:string): string
    local v=Catalog.get(id)
    return if rarity=="Common" or rarity=="Uncommon" then "Build" else v.Source
end
function Catalog.canAcquire(rarity:string,id:string,route:string): boolean
    local source=Catalog.source(rarity,id)
    return source=="Both" or source==route
end
function Catalog.income(base:number,id:string?,route:string?): number
    return if id then math.floor(base*(if route=="Build" then 1 else 4)*Catalog.get(id).Multiplier+.5) else base
end
function Catalog.name(rarity:string,id:string): string return rarity.." "..Catalog.get(id).Name end
function Catalog.roll(unit:number,exclude:string?,rarity:string?): string
    assert(unit>=0 and unit<1,"Valid variant random sample required")
    local total=0
    for _,v in list do if v.Id~=exclude and Catalog.canAcquire(rarity or "Rare",v.Id,"Box") then total+=v.Weight end end
    assert(total>0,"No box variants for this rarity")
    local sample=unit*total
    for _,v in list do
        if v.Id==exclude or not Catalog.canAcquire(rarity or "Rare",v.Id,"Box") then continue end
        sample-=v.Weight
        if sample<0 then return v.Id end
    end
    return list[1].Id
end
return Catalog
