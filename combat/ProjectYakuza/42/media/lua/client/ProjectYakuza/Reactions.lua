require "ProjectYakuza/Registry"
require "ProjectYakuza/Juggling"
local PY=ProjectYakuza
local R={states=setmetatable({}, {__mode="k"}),pending=setmetatable({}, {__mode="k"}),seen=setmetatable({}, {__mode="k"}),swings=setmetatable({}, {__mode="k"})}
PY.Reactions=R
local function hook()
    if not R.hooked then Events.OnTick.Add(R.tick);R.lastTick=getTimestampMs();R.hooked=true end
end
local function unhook()
    for _ in pairs(R.states) do return end
    for _ in pairs(R.pending) do return end
    if R.hooked then Events.OnTick.Remove(R.tick);R.hooked=false end
end
function R.clear(zombie)
    if R.states[zombie] then
        zombie:setVariable("ProjectYakuzaEnemyReaction",false);zombie:setVariable("ProjectYakuzaEnemyHitClip","")
        R.states[zombie]=nil
    end
    R.pending[zombie]=nil;unhook()
end
function R.protected(victim)
    return PY.GrabRules and PY.GrabRules.locks[victim]==true or victim.GetVariable and(victim:GetVariable("ProjectYakuzaGrabbed")=="true"or victim:GetVariable("ProjectYakuzaHeatRushVictim")=="true")
end
function R.remote(victim,clip)
    if type(clip)~="string"or clip==""or victim:isDead()or victim:isOnFloor()or victim:isKnockedDown()or R.protected(victim)
        or PY.HitResponses.stuns[victim]or victim.isStaggerBack and victim:isStaggerBack()then return false end
    local state=R.states[victim]
    if state and getTimestampMs()-state.startedAt<90 then return true end
    victim:setVariable("ProjectYakuzaEnemyReaction",true);victim:setVariable("ProjectYakuzaEnemyHitClip",clip)
    R.states[victim]={clip=clip,startedAt=getTimestampMs(),seenReaction=false}
    victim:setHitFromBehind(false);victim:setHitReaction("HeadLeft");victim:reportEvent("wasHit");hook()
    return true
end
function R.queue(attacker,victim,response,before,juggle,stamp,clip)
    if not response and not juggle and not clip and not PY.Juggling.get(victim) then return end
    if response and not PY.HitResponses.valid(response.kind,response.force) then return end
    R.pending[victim]={attacker=attacker,response=response,before=before,juggle=juggle,stamp=stamp,clip=clip,at=getTimestampMs()};hook()
end

function R.confirmed(attacker,victim,kind,force,clip)
    if R.protected(victim)then R.clear(victim);return false end
    if PY.Juggling.get(victim) then R.clear(victim);return true end
    if not PY.HitResponses.valid(kind,force) then return false end
    if kind=="flinch"then
        if PY.HitResponses.stuns[victim]or victim.isStaggerBack and victim:isStaggerBack()then return false end
        if clip and not R.remote(victim,clip)then return false end
    else R.clear(victim)end
    R.queue(attacker,victim,{kind=kind,force=force});return true
end
function R.onHit(attacker,victim,weapon,damage)
    if not victim or not instanceof(victim,"IsoZombie") then return end
    if attacker and instanceof(attacker,"IsoPlayer") and not attacker:isLocalPlayer() then return end
    if not attacker or not instanceof(attacker,"IsoPlayer") or not attacker:isLocalPlayer()
        or not weapon or not (PY.isStyleToken(weapon) or (PY.Weapons and PY.Weapons.matches(attacker,weapon))) or not PY.isEquipped(attacker) then R.clear(victim);return end
    if victim:isDead() or victim:isOnFloor() or victim:isKnockedDown() then R.clear(victim);return end
    if R.protected(victim)then R.clear(victim);return end
    local style=PY.getPlayerStyle(attacker);local s=PY.stateFor(attacker)
    local move=s.finisherMove or s.activeLightMove or style.lightAttacks[s.step]
    if not s.active or type(damage)~="number" or damage~=damage or damage<=0 or not move then return end
    local response=PY.HitResponses.resolve(style,move)
    local stamp=s.multiHitToken or s.startedAt
    local last=R.seen[victim]
    if stamp and last and last.attacker==attacker and last.stamp==stamp then return end
    R.seen[victim]={attacker=attacker,stamp=stamp}
    local swing=R.swings[attacker]
    if not swing or swing.stamp~=stamp then swing={stamp=stamp,serial=(swing and swing.serial or 0)+1};R.swings[attacker]=swing end
    local network=PY.Network
    local serial=isClient()and network and network.localState and network.localState(attacker).swing or swing.serial
    local clip=PY.HitResponses.reaction(style,move,PY.HitResponses.reactionSeed(victim,serial))
    if response and response.kind~="flinch" then R.clear(victim)
    elseif not clip then R.clear(victim)end

    if response and response.kind=="stun"then
        PY.HitResponses.apply(attacker,victim,response)
        R.queue(attacker,victim,response,nil,PY.Juggling.plan(style,move),stamp)
    elseif not isClient()then R.queue(attacker,victim,response,victim:getHealth(),PY.Juggling.plan(style,move),stamp,clip)end
end
function R.update(zombie,time)
    local state=R.states[zombie];if not state then return end
    local elapsed=(time or getTimestampMs())-state.startedAt
    local reacting=string.find(string.lower(tostring(zombie:getCurrentStateName())),"hitreaction",1,true)~=nil
    if reacting then state.seenReaction=true;state.leftAt=nil
    elseif state.seenReaction and not state.leftAt then state.leftAt=time or getTimestampMs()end
    if zombie:isDead() or zombie:isOnFloor() or zombie:isKnockedDown()or R.protected(zombie)
        or PY.HitResponses.stuns[zombie]or zombie.isStaggerBack and zombie:isStaggerBack()
        or (not reacting and(state.leftAt and(time or getTimestampMs())-state.leftAt>=80 or not state.seenReaction and elapsed>750))or elapsed>5000 then R.clear(zombie) end
end
function R.tick()
    local time=getTimestampMs();local elapsed=math.max(0,time-(R.lastTick or time));R.lastTick=time
    if isGamePaused()then
        for _,state in pairs(R.states)do state.startedAt=state.startedAt+elapsed;if state.leftAt then state.leftAt=state.leftAt+elapsed end end
        for _,job in pairs(R.pending)do job.at=job.at+elapsed end
        return
    end
    local pending=R.pending;R.pending=setmetatable({}, {__mode="k"})
    for z,job in pairs(pending) do
        local blocked=job.response and job.response.kind=="flinch"and(PY.HitResponses.stuns[z]or z.isStaggerBack and z:isStaggerBack())
        if not blocked and not R.protected(z)and time-job.at<=1000 and (not job.before or z:getHealth()<job.before) then
            local _,juggling=PY.Juggling.hit(job.attacker,z,job.juggle,job.stamp)
            if juggling then R.clear(z)else
                if job.clip then R.remote(z,job.clip)end
                PY.HitResponses.apply(job.attacker,z,job.response)
            end
        end
    end
    if time>=(R.nextUpdate or 0) then
        R.nextUpdate=time+50;for zombie in pairs(R.states) do R.update(zombie,time) end
    end
    unhook()
end
function R.clearAll()
    for z in pairs(R.states) do R.clear(z) end
    R.pending=setmetatable({}, {__mode="k"});R.seen=setmetatable({}, {__mode="k"});R.swings=setmetatable({}, {__mode="k"});unhook()
end
Events.OnWeaponHitCharacter.Add(R.onHit)
Events.OnSave.Add(R.clearAll)
Events.OnMainMenuEnter.Add(R.clearAll)
