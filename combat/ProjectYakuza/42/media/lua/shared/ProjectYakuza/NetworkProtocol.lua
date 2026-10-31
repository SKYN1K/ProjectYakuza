require "ProjectYakuza/Registry"
require "ProjectYakuza/NetworkExtensions"
local ProjectYakuza=ProjectYakuza
local P={module="ProjectYakuzaMP",version=2,range=60}
ProjectYakuza.NetworkProtocol=P
function P.number(v,low,high)return type(v)=="number" and v==v and v>=low and v<=high end
function P.integer(v,low,high)return P.number(v,low,high) and v==math.floor(v) end
local catalogs={}
local definitions=setmetatable({}, {__mode="k"})
local offsets={}
for x=-3,3 do for y=-3,3 do offsets[#offsets+1]={x=x,y=y,d=x*x+y*y}end end
table.sort(offsets,function(a,b)if a.d==b.d then if a.x==b.x then return a.y<b.y end;return a.x<b.x end;return a.d<b.d end)
local function definition(style)
    local cached=definitions[style]
    if cached and cached.sourceActions==style.actions and cached.lights==style.lightAttacks and cached.extreme==style.extremeLightAttacks and cached.directional==style.directionalAttacks and cached.ground==style.groundAttacks then return cached end
    cached={sourceActions=style.actions,lights=style.lightAttacks,extreme=style.extremeLightAttacks,directional=style.directionalAttacks,ground=style.groundAttacks,direct={},enabled={},actions={}}
    local function direct(move)if move.animation then cached.direct[move.animation]=true end end
    for _,move in ipairs(style.lightAttacks or {})do direct(move)end
    for _,move in ipairs(style.extremeLightAttacks or {})do direct(move)end
    for _,move in pairs(style.directionalAttacks and style.directionalAttacks.moves or {})do direct(move)end
    for _,move in ipairs(style.groundAttacks or {})do direct(move)end
    for kind,slot in pairs(style.actions or {})do
        local function add(move,enabled)
            if not move.animation then return end
            if not cached.actions[move.animation]then cached.actions[move.animation]={kind=kind,move=move}end
            if enabled then cached.enabled[move.animation]=true end
        end
        add(slot,slot.enabled)
        for _,move in pairs(slot.variants or {})do add(move,slot.enabled and move.enabled~=false)end
    end
    definitions[style]=cached;return cached
end
ProjectYakuza.on("styleRegistered",function(style)definitions[style]=nil end)
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
    local action=definition(s).actions[anim]
    if action then return action.kind,action.move end
end
function P.supports(style,clip)
    if not style or not clip then return false end
    local cached=definition(style)
    if cached.direct[clip.animation]then return true end
    local anim=clip.animation
    for _,condition in ipairs(clip.conditions)do if condition.name=="PerformingAction"then anim=condition.value end end
    return cached.enabled[anim]==true
end
function P.near(a,b,range)
    return a and b and math.abs(a:getZ()-b:getZ())<.5 and (a:getX()-b:getX())^2+(a:getY()-b:getY())^2<=range*range
end
function P.zombie(p,id)
    if not p or not P.integer(id,-32768,32767) or id==-1 then return nil end
    local cell=getCell();if not cell then return nil end
    local x,y,z=math.floor(p:getX()),math.floor(p:getY()),math.floor(p:getZ())
    for _,offset in ipairs(offsets)do
        local square=cell:getGridSquare(x+offset.x,y+offset.y,z);local list=square and square:getMovingObjects()
        if list then for i=0,list:size()-1 do
            local obj=list:get(i)
            if instanceof(obj,"IsoZombie") and obj:getOnlineID()==id then return obj end
        end end
    end
end
function P.path(p,x,y)
    local sx,sy=p:getX(),p:getY();local dx,dy=x-sx,y-sy;local length=math.sqrt(dx*dx+dy*dy)
    if length<.001 then return true end
    local cell=getCell();if not cell then return false end
    local z=math.floor(p:getZ());local steps=math.ceil(length/.08)
    local ox,oy=sx,sy;local cx,cy=math.floor(sx),math.floor(sy)
    local square=cell:getGridSquare(cx,cy,z);if not square then return false end
    local checked=false
    for i=1,steps do
        local nx,ny=math.floor(ox+dx*i/steps),math.floor(oy+dy*i/steps)
        local tx,ty=nx-cx,ny-cy
        if tx~=0 or ty~=0 then
            local nextSquare=cell:getGridSquare(nx,ny,z)
            if not nextSquare or not nextSquare:TreatAsSolidFloor()or nextSquare:isSolid()or nextSquare:isSolidTrans()or square:testCollideAdjacent(p,tx,ty,0)then return false end
            square=nextSquare;cx,cy=nx,ny;checked=true
        elseif not checked then
            if not square:TreatAsSolidFloor()or square:isSolid()or square:isSolidTrans()then return false end
            checked=true
        end
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
    for _,move in pairs(s.directionalAttacks and s.directionalAttacks.moves or {})do if move.nodeValue==node then return move end end
    for _,move in ipairs(s.groundAttacks or {}) do if move.nodeValue==node then return move end end
    for _,slot in pairs(s.actions) do
        if slot.nodeValue==node then return slot end
        for _,move in pairs(slot.variants or {}) do if move.nodeValue==node then return move end end
    end
end
