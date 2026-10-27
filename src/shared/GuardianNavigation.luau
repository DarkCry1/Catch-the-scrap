--!strict
-- Static 2D navigation for the flat yard. Expanded scenery bounds keep the
-- entire robot body out of scrap heaps. No jumping or paths outside its stage.
local Config=require("./Config")
local Rules=require("./GuardianRules")
export type Point=Rules.Point
export type Obstacle={x:number,z:number,halfX:number,halfZ:number}
local Nav={}
Nav.__index=Nav
local function distance(a:Point,b:Point): number return math.sqrt((a.x-b.x)^2+(a.z-b.z)^2) end
Nav.distance=distance
function Nav.obstacles(parts:{any},height:number): {Obstacle}
    local result={}
    for _,p in parts do
        if not p.collidable then continue end
        local cx,sx=math.cos(math.rad(p.pitch or 0)),math.sin(math.rad(p.pitch or 0))
        local cy,sy=math.cos(math.rad(p.yaw or 0)),math.sin(math.rad(p.yaw or 0))
        local cz,sz=math.cos(math.rad(p.roll or 0)),math.sin(math.rad(p.roll or 0))
        local a,b,c=p.size[1]/2,p.size[2]/2,p.size[3]/2
        local hy=math.abs(cx*sz+sx*sy*cz)*a+math.abs(cx*cz-sx*sy*sz)*b+math.abs(sx*cy)*c
        if p.position[2]+hy<.8 or p.position[2]-hy>height then continue end
        local hx=math.abs(cy*cz)*a+math.abs(cy*sz)*b+math.abs(sy)*c
        local hz=math.abs(sx*sz-cx*sy*cz)*a+math.abs(sx*cz+cx*sy*sz)*b+math.abs(cx*cy)*c
        table.insert(result,{x=p.position[1],z=p.position[3],halfX=hx,halfZ=hz})
    end
    return result
end
local function intersects(a:Point,b:Point,box:Obstacle,padding:number): boolean
    local t0,t1=0,1
    for _,axis in {{a.x,b.x,box.x,box.halfX},{a.z,b.z,box.z,box.halfZ}} do
        local lo,hi=axis[3]-axis[4]-padding,axis[3]+axis[4]+padding
        local delta=axis[2]-axis[1]
        if math.abs(delta)<1e-8 then
            if axis[1]<lo or axis[1]>hi then return false end
        else
            local v0,v1=(lo-axis[1])/delta,(hi-axis[1])/delta
            if v0>v1 then v0,v1=v1,v0 end
            t0=math.max(t0,v0);t1=math.min(t1,v1)
            if t0>t1 then return false end
        end
    end
    return true
end
function Nav.clear(self:any,a:Point,b:Point,padding:number?): boolean
    local inset=padding or self.radius
    local x0,x1,z0,z1=Rules.bounds(self.stage,inset+.5)
    for _,p in {a,b} do if not (p.x>=x0 and p.x<=x1 and p.z>=z0 and p.z<=z1) then return false end end
    for _,box in self.obstacles do if intersects(a,b,box,inset) then return false end end
    return true
end
function Nav.new(stage:number,parts:{any})
    local self:any=setmetatable({stage=stage,radius=Rules.radius(stage),cells={},lookup={},obstacles={}},Nav)
    local _,_,z0,z1=Rules.bounds(stage)
    for _,box in Nav.obstacles(parts,Rules.height(stage)) do
        if box.z+box.halfZ>=z0 and box.z-box.halfZ<=z1 then table.insert(self.obstacles,box) end
    end
    local grid=Config.Guardians.Grid
    local x0,x1,first,last=Rules.bounds(stage,self.radius+1)
    for ix=math.ceil(x0/grid),math.floor(x1/grid) do
        for iz=math.ceil((first-z0)/grid),math.floor((last-z0)/grid) do
            local p={x=ix*grid,z=z0+iz*grid,ix=ix,iz=iz,neighbors={},component=0}
            if self:clear(p,p) then
                table.insert(self.cells,p);self.lookup[ix..":"..iz]=#self.cells
            end
        end
    end
    for i,p in self.cells do
        for dx=-1,1 do for dz=-1,1 do
            if dx==0 and dz==0 then continue end
            local j=self.lookup[(p.ix+dx)..":"..(p.iz+dz)]
            if j and self:clear(p,self.cells[j]) then table.insert(p.neighbors,j) end
        end end
    end
    local component=0
    for i,p in self.cells do
        if p.component~=0 then continue end
        component+=1;p.component=component;local queue={i};local head=1
        while head<=#queue do
            local cell=self.cells[queue[head]];head+=1
            for _,j in cell.neighbors do if self.cells[j].component==0 then self.cells[j].component=component;table.insert(queue,j) end end
        end
    end
    return self
end
function Nav.nearest(self:any,point:Point,component:number?,visibleFrom:Point?): number?
    local best,score=nil,math.huge
    for i,p in self.cells do
        local d=(p.x-point.x)^2+(p.z-point.z)^2
        if d<score and (not component or p.component==component) and (not visibleFrom or self:clear(visibleFrom,p)) then best,score=i,d end
    end
    return best
end
function Nav.route(self:any,from:Point,to:Point): {Point}
    if self:clear(from,to) then return {to} end
    local first=self:nearest(from,nil,from)
    if not first then return {} end
    local last=self:nearest(to,self.cells[first].component)
    if not last then return {} end
    local open:{[number]:boolean}={[first]=true};local closed:{[number]:boolean}={};local costs:{[number]:number}={[first]=0};local prev:{[number]:number}={};local reached=false
    while next(open) do
        local current,score=first,math.huge
        for i in open do
            local s=costs[i]+distance(self.cells[i],self.cells[last])
            if s<score then current,score=i,s end
        end
        if current==last then reached=true;break end
        open[current]=nil;closed[current]=true
        for _,i in self.cells[current].neighbors do
            if closed[i] then continue end
            local cost=costs[current]+distance(self.cells[current],self.cells[i])
            if cost<(costs[i] or math.huge) then costs[i]=cost;prev[i]=current;open[i]=true end
        end
    end
    if not reached then return {} end
    local route:{Point}={};local current:number?=last
    while current do table.insert(route,1,self.cells[current]);current=prev[current] end
    if self:clear(route[#route],to) then table.insert(route,to) end
    local smooth:{Point}={};local anchor=from;local index=1
    while index<=#route do
        local far=index
        for j=index+1,#route do if self:clear(anchor,route[j]) then far=j end end
        table.insert(smooth,{x=route[far].x,z=route[far].z});anchor=route[far];index=far+1
    end
    return smooth
end
return Nav
