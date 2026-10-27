--!strict
export type Style={Color:{number},Rank:number,Duration:number,Rings:number,Shards:number,Particles:number,Rainbow:boolean}
local Style={}
local data:{[string]:Style}={
 Common={Color={184,193,205},Rank=1,Duration=3.8,Rings=1,Shards=0,Particles=0,Rainbow=false},
 Uncommon={Color={65,226,133},Rank=2,Duration=4.4,Rings=2,Shards=0,Particles=0,Rainbow=false},
 Rare={Color={73,145,255},Rank=3,Duration=5.6,Rings=2,Shards=4,Particles=2,Rainbow=false},
 Epic={Color={181,77,255},Rank=4,Duration=7,Rings=3,Shards=8,Particles=4,Rainbow=false},
 Legendary={Color={255,188,42},Rank=5,Duration=8,Rings=4,Shards=12,Particles=7,Rainbow=false},
 Mythic={Color={255,62,125},Rank=6,Duration=9,Rings=5,Shards=16,Particles=9,Rainbow=false},
 Celestial={Color={126,234,255},Rank=7,Duration=10.5,Rings=6,Shards=20,Particles=12,Rainbow=true},
}
function Style.get(rarity:string): Style return assert(data[rarity],"Unknown rarity") end
function Style.rgb(rarity:string,time:number,phase:number?): {number}
 local profile=Style.get(rarity)
 if not profile.Rainbow then return profile.Color end
 local h=((time*.13+(phase or 0))%1)*6
 local x=1-math.abs(h%2-1)
 local r,g,b=0,0,0
 if h<1 then r,g,b=1,x,0 elseif h<2 then r,g,b=x,1,0 elseif h<3 then r,g,b=0,1,x elseif h<4 then r,g,b=0,x,1 elseif h<5 then r,g,b=x,0,1 else r,g,b=1,0,x end
 return {(r*.82+.18)*255,(g*.82+.18)*255,(b*.82+.18)*255}
end
function Style.key(rarity:string,variant:string): string return rarity..":"..variant end
return Style
