require "ProjectYakuza/Registry"
require "ProjectYakuza/Juggling"
local PY=ProjectYakuza
local R={states=setmetatable({}, {__mode="k"}),pending=setmetatable({}, {__mode="k"}),seen=setmetatable({}, {__mode="k"})}
PY.Reactions=R
local function hook()
    if not R.hooked then Events.OnTick.Add(R.tick);R.hooked=true end
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
function R.remote(victim,clip)
    if type(clip)~="string" or clip=="" or victim:isDead() or victim:isOnFloor() or victim:isKnockedDown() then return end
    victim:setVariable("ProjectYakuzaEnemyReaction",true);victim:setVariable("ProjectYakuzaEnemyHitClip",clip)
    R.states[victim]={clip=clip,startedAt=getTimestampMs(),seenReaction=false}
    victim:setHitFromBehind(false);victim:setHitReaction("HeadLeft");victim:reportEvent("wasHit");hook()
end
function R.queue(attacker,victim,response,before,juggle,stamp)
    if not response and not juggle and not PY.Juggling.get(victim) then return end
    if response and not PY.HitResponses.valid(response.kind,response.force) then return end
    R.pending[victim]={attacker=attacker,response=response,before=before,juggle=juggle,stamp=stamp,at=getTimestampMs()};hook()
end

function R.confirmed(attacker,victim,kind,force,clip)
    if PY.Juggling.get(victim) then R.clear(victim);return true end
    if not PY.HitResponses.valid(kind,force) then return false end
    if kind=="flinch" then R.remote(victim,clip) else R.clear(victim) end
    R.queue(attacker,victim,{kind=kind,force=force});return true
end
function R.onHit(attacker,victim,weapon,damage)
    if not victim or not instanceof(victim,"IsoZombie") then return end
    if attacker and instanceof(attacker,"IsoPlayer") and not attacker:isLocalPlayer() then return end
    if not attacker or not instanceof(attacker,"IsoPlayer") or not attacker:isLocalPlayer()
        or not weapon or not (PY.isStyleToken(weapon) or (PY.Weapons and PY.Weapons.matches(attacker,weapon))) or not PY.isEquipped(attacker) then R.clear(victim);return end
    if victim:isDead() or victim:isOnFloor() or victim:isKnockedDown() then R.clear(victim);return end
    local style=PY.getPlayerStyle(attacker);local s=PY.stateFor(attacker)
    local move=s.finisherMove or style.lightAttacks[s.step]
    if not s.active or type(damage)~="number" or damage~=damage or damage<=0 or not move then return end
    local response=PY.HitResponses.resolve(style,move)
    local stamp=s.multiHitToken or s.startedAt
    local last=R.seen[victim]
    if stamp and last and last.attacker==attacker and last.stamp==stamp then return end
    R.seen[victim]={attacker=attacker,stamp=stamp}
    if response and response.kind~="flinch" then R.clear(victim)
    elseif style.enemyReactions and move.reaction then
        victim:setVariable("ProjectYakuzaEnemyReaction",true);victim:setVariable("ProjectYakuzaEnemyHitClip",move.reaction)
        R.states[victim]={clip=move.reaction,startedAt=getTimestampMs(),seenReaction=false};hook()
    else R.clear(victim) end

    if not isClient() then R.queue(attacker,victim,response,victim:getHealth(),PY.Juggling.plan(style,move),stamp) end
end
function R.update(zombie,time)
    local state=R.states[zombie];if not state then return end
    local elapsed=(time or getTimestampMs())-state.startedAt
    local reacting=string.find(string.lower(tostring(zombie:getCurrentStateName())),"hitreaction",1,true)~=nil
    if reacting then state.seenReaction=true end
    if zombie:isDead() or zombie:isOnFloor() or zombie:isKnockedDown()
        or (not reacting and (state.seenReaction or elapsed>750)) or elapsed>5000 then R.clear(zombie) end
end
function R.tick()
    if isGamePaused() then return end
    local time=getTimestampMs();local pending=R.pending;R.pending=setmetatable({}, {__mode="k"})
    for z,job in pairs(pending) do
        if time-job.at<=1000 and (not job.before or z:getHealth()<job.before) then
            local _,juggling=PY.Juggling.hit(job.attacker,z,job.juggle,job.stamp)
            if juggling then R.clear(z) else PY.HitResponses.apply(job.attacker,z,job.response) end
        end
    end
    if time>=(R.nextUpdate or 0) then
        R.nextUpdate=time+50;for zombie in pairs(R.states) do R.update(zombie,time) end
    end
    unhook()
end
function R.clearAll()
    for z in pairs(R.states) do R.clear(z) end
    R.pending=setmetatable({}, {__mode="k"});R.seen=setmetatable({}, {__mode="k"});unhook()
end
Events.OnWeaponHitCharacter.Add(R.onHit)
Events.OnSave.Add(R.clearAll)
Events.OnMainMenuEnter.Add(R.clearAll)
