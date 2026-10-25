require "DCF/Registry"
require "DCF/NetworkCatalog"
local DCF=DragonCombat
local P={module="DragonCombatMP",version=1,range=60}
DCF.NetworkProtocol=P
function P.number(v,low,high)return type(v)=="number" and v==v and v>=low and v<=high end
function P.integer(v,low,high)return P.number(v,low,high) and v==math.floor(v) end
function P.clip(style,id)
    for _,entry in ipairs(DCF.NetworkCatalog[style] or {}) do if entry.id==id then return entry end end
end
function P.kind(style,id)
    local clip=P.clip(style,id);local s=DCF.getStyle(style)
    if not clip or not s then return nil end
    local anim
    for _,c in ipairs(clip.conditions) do if c.name=="PerformingAction" then anim=c.value end end
    if not anim then return nil end
    for kind,slot in pairs(s.actions) do
        if slot.animation==anim then return kind,slot end
        for _,move in pairs(slot.variants or {}) do if move.animation==anim then return kind,move end end
    end
end
function P.near(a,b,range)
    return a and b and math.abs(a:getZ()-b:getZ())<.5 and (a:getX()-b:getX())^2+(a:getY()-b:getY())^2<=range*range
end
function P.zombie(p,id)
    if not p or not P.integer(id,-32768,32767) or id==-1 then return nil end
    local cell=getCell();if not cell then return nil end
    local x,y,z=math.floor(p:getX()),math.floor(p:getY()),math.floor(p:getZ())
    for ox=-3,3 do for oy=-3,3 do
        local square=cell:getGridSquare(x+ox,y+oy,z);local list=square and square:getMovingObjects()
        if list then for i=0,list:size()-1 do
            local obj=list:get(i)
            if instanceof(obj,"IsoZombie") and obj:getOnlineID()==id then return obj end
        end end
    end end
end
function P.path(p,x,y)
    local sx,sy=p:getX(),p:getY();local dx,dy=x-sx,y-sy;local length=math.sqrt(dx*dx+dy*dy)
    if length<.001 then return true end
    local cell=getCell();local z=math.floor(p:getZ());local steps=math.ceil(length/.08)
    for i=1,steps do
        local nx,ny=p:getX()+dx*i/steps,p:getY()+dy*i/steps
        local a=cell:getGridSquare(math.floor(sx),math.floor(sy),z);local b=cell:getGridSquare(math.floor(nx),math.floor(ny),z)
        if not a or not b or not b:TreatAsSolidFloor() or b:isSolid() or b:isSolidTrans() then return false end
        local tx,ty=math.floor(nx)-math.floor(sx),math.floor(ny)-math.floor(sy)
        if (tx~=0 or ty~=0) and a:testCollideAdjacent(p,tx,ty,0) then return false end
        sx,sy=nx,ny
    end
    return true
end
function P.move(style,node)
    local s=DCF.getStyle(style);if not s then return nil end
    for _,move in ipairs(s.lightAttacks) do if move.nodeValue==node then return move end end
    for _,move in ipairs(s.groundAttacks or {}) do if move.nodeValue==node then return move end end
    for _,slot in pairs(s.actions) do
        if slot.nodeValue==node then return slot end
        for _,move in pairs(slot.variants or {}) do if move.nodeValue==node then return move end end
    end
end
