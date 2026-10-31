require "ProjectYakuza/NetworkProtocol"
local PY=ProjectYakuza;local R={offsets={}}
PY.TauntReactions=R
function R.config(style)
    local cfg=style and style.tauntReactions;local slot=style and style.actions and style.actions.taunt
    if type(cfg)~="table"or not slot or slot.enabled~=true then return end
    if not PY.NetworkProtocol.number(slot.duration,.05,10)then return end
    if not PY.NetworkProtocol.number(cfg.radius,1,6)or not PY.NetworkProtocol.integer(cfg.maxTargets,1,8)then return end
    return cfg
end
function R.valid(p,z,cfg)
    return z and instanceof(z,"IsoZombie")and not z:isDead()and not z:isOnFloor()and not z:isKnockedDown()and not z:isAttacking()and not z:isUseless()
        and PY.NetworkProtocol.near(p,z,cfg.radius)
end
function R.targets(p,cfg,filter)
    local cell=getCell();if not cell then return {}end
    local radius=math.ceil(cfg.radius);local offsets=R.offsets[radius]
    if not offsets then
        offsets={};for x=-radius,radius do for y=-radius,radius do offsets[#offsets+1]={x=x,y=y,d=x*x+y*y}end end
        table.sort(offsets,function(a,b)if a.d==b.d then if a.x==b.x then return a.y<b.y end;return a.x<b.x end;return a.d<b.d end);R.offsets[radius]=offsets
    end
    local x,y,z=math.floor(p:getX()),math.floor(p:getY()),math.floor(p:getZ());local seen={};local result={};local inspected=0
    for _,o in ipairs(offsets)do
        local sq=cell:getGridSquare(x+o.x,y+o.y,z);local list=sq and sq:getMovingObjects()
        if list then for i=0,list:size()-1 do
            local actor=list:get(i)
            if not seen[actor]then
                seen[actor]=true;inspected=inspected+1
                if R.valid(p,actor,cfg)and (not filter or filter[actor:getOnlineID()])then result[#result+1]=actor end
                if inspected>=256 then break end
            end
        end end
        if inspected>=256 then break end
    end
    table.sort(result,function(a,b)return (a:getX()-p:getX())^2+(a:getY()-p:getY())^2<(b:getX()-p:getX())^2+(b:getY()-p:getY())^2 end)
    local visible={}
    for i=1,math.min(#result,32)do
        local actor=result[i]
        if PY.NetworkProtocol.path(p,actor:getX(),actor:getY())then visible[#visible+1]=actor end
        if #visible>=cfg.maxTargets then break end
    end
    return visible
end
function R.apply(p,z,cfg)
    if not R.valid(p,z,cfg)or isClient()and z:isRemoteZombie()then return false end
    z:addAggro(p,3);z:setTarget(p);return true
end
function R.react(p,style)
    local cfg=R.config(style);if not cfg then return {}end
    local targets=R.targets(p,cfg)
    for _,z in ipairs(targets)do R.apply(p,z,cfg)end
    return targets
end
