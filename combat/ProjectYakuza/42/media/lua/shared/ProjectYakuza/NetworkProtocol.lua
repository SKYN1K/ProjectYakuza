require "ProjectYakuza/Registry"
require "ProjectYakuza/NetworkExtensions"
local ProjectYakuza=ProjectYakuza
local P={module="ProjectYakuzaMP",version=2,range=60}
ProjectYakuza.NetworkProtocol=P
function P.number(v,low,high)return type(v)=="number" and v==v and v>=low and v<=high end
function P.integer(v,low,high)return P.number(v,low,high) and v==math.floor(v) end
local catalogs={}
local function catalog(style)
    local entries=ProjectYakuza.NetworkCatalog[style]
    if not entries then return nil end
    local cached=catalogs[style]
    if cached and cached.source==entries and cached.count==#entries then return cached end
    cached={source=entries,count=#entries,byId={},groups={}}
    for _,entry in ipairs(entries) do
        if not cached.byId[entry.id] then cached.byId[entry.id]=entry end
        local group=cached.groups[entry.group]
        if not group then group={};cached.groups[entry.group]=group end
        local conditions={}
        for _,condition in ipairs(entry.conditions) do
            conditions[#conditions+1]={name=condition.name,value=condition.value:lower()}
        end
        group[#group+1]={id=entry.id,conditions=conditions}
    end
    catalogs[style]=cached
    return cached
end
function P.clip(style,id)
    local cached=catalog(style);return cached and cached.byId[id] or nil
end
function P.selectors(style,group)
    local cached=catalog(style);return cached and cached.groups[group] or nil
end

function P.reaction(style,id)
    if type(id)~="string" or id=="" then return false end
    local s=ProjectYakuza.getStyle(style);if not s or not s.enemyReactions then return false end
    for _,move in ipairs(s.lightAttacks) do if move.reaction==id then return true end end
    for _,slot in pairs(s.actions) do
        if slot.reaction==id then return true end
        for _,move in pairs(slot.variants or {}) do if move.reaction==id then return true end end
    end
    return false
end
function P.kind(style,id)
    local clip=P.clip(style,id);local s=ProjectYakuza.getStyle(style)
    if not clip or not s then return nil end
    if ProjectYakuza.Weapons then
        for _,c in ipairs(clip.conditions) do if c.name=="ProjectYakuzaWeaponProfile" and c.value~="" then s=ProjectYakuza.Weapons.view(s,c.value) end end
    end
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
    local s=ProjectYakuza.getStyle(style);if not s then return nil end
    if ProjectYakuza.Weapons then
        for _,view in pairs(ProjectYakuza.Weapons.views[style] or {}) do local move=ProjectYakuza.Weapons.findMove(view,node);if move then return move end end
    end
    if ProjectYakuza.Weapons then return ProjectYakuza.Weapons.findMove(s,node) end
    for _,move in ipairs(s.lightAttacks) do if move.nodeValue==node then return move end end
    for _,move in ipairs(s.extremeLightAttacks or {})do if move.nodeValue==node then return move end end
    for _,move in ipairs(s.groundAttacks or {}) do if move.nodeValue==node then return move end end
    for _,slot in pairs(s.actions) do
        if slot.nodeValue==node then return slot end
        for _,move in pairs(slot.variants or {}) do if move.nodeValue==node then return move end end
    end
end
