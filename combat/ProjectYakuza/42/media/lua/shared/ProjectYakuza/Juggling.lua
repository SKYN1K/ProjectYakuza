require "ProjectYakuza/Registry"
local PY=ProjectYakuza

local J={states=setmetatable({}, {__mode="k"}),cooldowns=setmetatable({}, {__mode="k"}),received=setmetatable({}, {__mode="k"}),sequence=0,maxTargets=64}
PY.Juggling=J
local function now()return getTimestampMs() end
local function activeCount()local n=0;for _ in pairs(J.states) do n=n+1 end;return n end
local function flags(z,s)
    if s then z:setVariable("ProjectYakuzaEnemyReaction",false);z:setVariable("ProjectYakuzaEnemyHitClip","") end
    z:setVariable("ProjectYakuzaJuggleActive",s~=nil)
    z:setVariable("ProjectYakuzaJugglePhase",s and s.phase or "")
    z:setVariable("ProjectYakuzaJuggleStyle",s and s.style or "")
    z:setVariable("ProjectYakuzaJugglePresentation",s and s.presentation or "")
    z:setVariable("ProjectYakuzaJuggleHits",s and tostring(s.hits) or "0")
end
local function hook()
    if not J.hooked then
        J.tickEvent=Events.OnTickEvenPaused or Events.OnTick
        J.tickEvent.Add(J.tick);J.hooked=true
    end
end
local function unhook()
    if activeCount()==0 and J.hooked then J.tickEvent.Remove(J.tick);J.hooked=false end
end
local function packet(s,phase,reason)
    J.sequence=J.sequence+1
    return {seq=J.sequence,style=s.style,phase=phase,reason=reason or "",hits=s.hits,
        relaunches=s.relaunches,remaining=math.max(0,s.expires-now()),hardRemaining=math.max(0,s.hardEnd-now()),
        presentation=s.presentation}
end
local function emit(p,z,a)
    PY.emit(a.phase=="launch" and "juggleStarted" or a.phase=="end" and "juggleEnded" or "juggleHit",p,z,a)
end
function J.plan(style,move)
    local c=style and style.juggling;local v=move and move.juggle
    if type(c)~="table" or c.enabled==false or type(v)~="table" or move.groundAttack then return nil end
    return {style=style.id,kind=v.kind,windowMs=v.windowMs or c.windowMs or 650,maxHits=c.maxHits or 4,
        maxDurationMs=c.maxDurationMs or 1800,maxRelaunches=c.maxRelaunches or 1,
        landingCooldownMs=c.landingCooldownMs or 500,presentation=c.presentation or ""}
end
function J.get(victim)
    local s=J.states[victim];if not s then return nil end
    return {owner=s.owner,style=s.style,phase=s.phase,hits=s.hits,relaunches=s.relaunches,
        remaining=math.max(0,s.expires-now()),hardRemaining=math.max(0,s.hardEnd-now()),presentation=s.presentation}
end
function J.finish(z,reason,fromHit)
    local s=J.states[z];if not s then return nil end
    J.states[z]=nil;J.cooldowns[z]=now()+s.cooldown;flags(z,nil);unhook()
    local a=packet(s,"end",reason);a.fromHit=fromHit==true
    emit(s.owner,z,a);return a
end
function J.hit(p,z,plan,stamp)
    if isClient and isClient() and not (isServer and isServer()) then return nil,false end
    local s=J.states[z];local t=now()
    if not p or p:isDead() or not z or z:isDead() or z:isOnFloor() or z:isKnockedDown() then
        return z and J.finish(z,"landed",true) or nil,false
    end
    if s and (t>=s.expires or t>=s.hardEnd) then return J.finish(z,"timeout",true),false end
    if s and s.owner==p and stamp~=nil and s.lastStamp==stamp then return nil,true end
    if not plan then return J.finish(z,"unmarked_hit",true),false end
    if s and (s.owner~=p or s.style~=plan.style) then return J.finish(z,"interrupted",true),false end
    if plan.kind=="ender" then return J.finish(z,"ender",true),false end
    if not s then
        if plan.kind~="launch" or t<(J.cooldowns[z] or 0) or activeCount()>=J.maxTargets then return nil,false end
        s={owner=p,style=plan.style,phase="launch",hits=0,relaunches=0,expires=t+plan.windowMs,
            hardEnd=t+plan.maxDurationMs,maxHits=plan.maxHits,maxRelaunches=plan.maxRelaunches,
            cooldown=plan.landingCooldownMs,presentation=plan.presentation,lastStamp=stamp,lastTick=t}
        J.states[z]=s;flags(z,s);hook()
        local a=packet(s,"launch");emit(p,z,a);return a,true
    end
    if plan.kind=="launch" then
        if s.relaunches>=s.maxRelaunches then return J.finish(z,"relaunch_limit",true),false end
        s.relaunches=s.relaunches+1
    elseif plan.kind~="followup" then return J.finish(z,"invalid_move",true),false end
    s.hits=s.hits+1;s.lastStamp=stamp
    if s.hits>=s.maxHits then return J.finish(z,"hit_limit",true),false end
    s.expires=math.min(s.hardEnd,t+plan.windowMs);s.phase="hit";flags(z,s)
    local a=packet(s,"hit");emit(p,z,a);return a,true
end
local function integer(v,lo,hi)return type(v)=="number" and v==v and v>=lo and v<=hi and v==math.floor(v) end
local function duration(v)return type(v)=="number" and v==v and v>=0 and v<=6000 end
function J.receive(p,z,a)
    if type(a)~="table" or not integer(a.seq,1,1000000000) or type(a.style)~="string"
        or not PY.getStyle(a.style) or not integer(a.hits,0,12) or not integer(a.relaunches,0,3)
        or not duration(a.remaining) or not duration(a.hardRemaining)
        or type(a.presentation)~="string" or #a.presentation>100
        or (a.phase~="launch" and a.phase~="hit" and a.phase~="end")
        or type(a.reason)~="string" or #a.reason>40 then return false end
    local style=PY.getStyle(a.style);local c=style.juggling
    if type(c)~="table" or c.enabled==false or a.presentation~=(c.presentation or "") then return false end
    if a.phase~="end" and not J.states[z] and activeCount()>=J.maxTargets then return false end
    if a.seq<=(J.received[z] or 0) then return J.states[z]~=nil end
    J.received[z]=a.seq
    if a.phase=="end" or z:isDead() or z:isOnFloor() or z:isKnockedDown() then
        J.states[z]=nil;flags(z,nil);unhook();emit(p,z,a);return false
    end
    local t=now();J.states[z]={owner=p,style=a.style,phase=a.phase,hits=a.hits,relaunches=a.relaunches,
        expires=t+math.min(a.remaining,a.hardRemaining,2000,c.maxDurationMs or 1800),hardEnd=t+math.min(a.hardRemaining,c.maxDurationMs or 1800),
        cooldown=c.landingCooldownMs or 500,presentation=a.presentation,remote=true,lastTick=t}
    flags(z,J.states[z]);hook();emit(p,z,a);return true
end
function J.tick()
    local t=now();local paused=isGamePaused and isGamePaused()
    for z,s in pairs(J.states) do
        local dt=math.max(0,t-s.lastTick);s.lastTick=t
        if paused then s.expires=s.expires+dt;s.hardEnd=s.hardEnd+dt
        elseif z:isDead() or z:isOnFloor() or z:isKnockedDown() then J.finish(z,"landed",false)
        elseif not s.owner or s.owner:isDead() or not PY.isEquipped(s.owner) or PY.getPlayerStyle(s.owner).id~=s.style then J.finish(z,"owner_changed",false)
        elseif t>=s.expires or t>=s.hardEnd then J.finish(z,"timeout",false) end
    end
end
function J.clearAll()
    for z in pairs(J.states) do J.finish(z,"world_exit",false) end
    J.cooldowns=setmetatable({}, {__mode="k"});J.received=setmetatable({}, {__mode="k"});unhook()
end
if Events.OnSave then Events.OnSave.Add(J.clearAll) end
if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(J.clearAll) end
