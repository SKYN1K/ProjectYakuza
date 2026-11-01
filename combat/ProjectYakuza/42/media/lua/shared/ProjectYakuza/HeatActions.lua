require "ProjectYakuza/Registry"
local H={active=setmetatable({}, {__mode="k"})};ProjectYakuza.HeatActions=H
function H.restore(p,job)
    if H.active[p]~=job then return false end
    p:setInvincible(job.invincible);p:setGhostMode(job.ghost);H.active[p]=nil
    return true
end
function H.begin(p,key,definition)
    if not p or not key or p:isDead()then return false end
    local duration=definition and definition.duration or 5;local grace=definition and definition.targetGraceMs or 500
    if type(duration)~="number"or duration~=duration or duration<=0 or duration>120 or type(grace)~="number"or grace~=grace or grace<0 or grace>2000 then return false end
    local job=H.active[p]
    if job and job.playing and job.key~=key then return false end
    job=job or {invincible=p:isInvincible(),ghost=p:isGhostMode()}
    job.key=key;job.playing=true;job.graceMs=grace
    job.expires=getTimestampMs()+(duration*1000)+1000
    H.active[p]=job;p:setInvincible(true);p:setGhostMode(true)
    if not H.hooked then Events.OnTick.Add(H.tick);if Events.OnZombieUpdate then Events.OnZombieUpdate.Add(H.zombie)end;H.hooked=true;H.lastTick=getTimestampMs();H.paused=false end
    return true
end
function H.finish(p,key)
    local job=H.active[p];if not job or job.key~=key or not job.playing then return false end
    job.playing=false;p:setInvincible(job.invincible);job.expires=getTimestampMs()+job.graceMs
    if job.graceMs==0 then H.restore(p,job)end
    return true
end
function H.tick()
    local t=getTimestampMs();local paused=isGamePaused();local dt=math.max(0,t-(H.lastTick or t));H.lastTick=t
    if paused or H.paused then for _,job in pairs(H.active)do job.expires=job.expires+dt end end
    H.paused=paused;if paused then return end
    local any=false
    for p,job in pairs(H.active)do
        if p:isDead()or t>=job.expires then H.restore(p,job)
        else any=true;p:setGhostMode(true);if job.playing then p:setInvincible(true)end end
    end
    if not any and H.hooked then Events.OnTick.Remove(H.tick);if Events.OnZombieUpdate then Events.OnZombieUpdate.Remove(H.zombie)end;H.hooked=false end
end
function H.zombie(z)
    local target=z:getTarget()
    if target and H.active[target]then z:setTarget(nil);z:setAttackOutcome("fail")end
end
function H.clear()
    for p,job in pairs(H.active)do H.restore(p,job)end
    if H.hooked then Events.OnTick.Remove(H.tick);if Events.OnZombieUpdate then Events.OnZombieUpdate.Remove(H.zombie)end;H.hooked=false end
end
Events.OnSave.Add(H.clear)
Events.OnMainMenuEnter.Add(H.clear)
