require "ProjectYakuza/Registry"
local ProjectYakuza = ProjectYakuza
local R = { states = setmetatable({}, {__mode="k"}) }
ProjectYakuza.Reactions = R
function R.remote(victim,clip)
    if type(clip)~="string" or clip=="" or victim:isDead() or victim:isOnFloor() or victim:isKnockedDown() then return end
    victim:setVariable("ProjectYakuzaEnemyReaction",true);victim:setVariable("ProjectYakuzaEnemyHitClip",clip)
    R.states[victim]={clip=clip,startedAt=getTimestampMs(),seenReaction=false}
    -- Observer variables alone cannot select a node in the hitreaction group.
    -- Enter the native reaction state without replaying Hit or damage.
    victim:setHitFromBehind(false)
    victim:setHitReaction("HeadLeft")
    victim:reportEvent("wasHit")
end
function R.clear(zombie)
    if not R.states[zombie] then return end
    zombie:setVariable("ProjectYakuzaEnemyReaction", false)
    zombie:setVariable("ProjectYakuzaEnemyHitClip", "")
    R.states[zombie] = nil
end
function R.onHit(attacker, victim, weapon, damage)
    if not victim or not instanceof(victim, "IsoZombie") then return end
    if attacker and instanceof(attacker,"IsoPlayer") and not attacker:isLocalPlayer() then return end
    if not attacker or not instanceof(attacker, "IsoPlayer") or not attacker:isLocalPlayer()
        or not weapon or not ProjectYakuza.isStyleToken(weapon) or not ProjectYakuza.isEquipped(attacker) then R.clear(victim);return end
    if victim:isDead() or victim:isOnFloor() or victim:isKnockedDown() then R.clear(victim);return end
    local style = ProjectYakuza.getPlayerStyle(attacker)
    if not style.enemyReactions then R.clear(victim);return end
    local s = ProjectYakuza.stateFor(attacker)
    local move = s.finisherMove or style.lightAttacks[s.step]
    if not move or not move.reaction then R.clear(victim);return end
    local state=R.states[victim]
    if not state then
        state={};R.states[victim]=state
        victim:setVariable("ProjectYakuzaEnemyReaction",true)
    end
    if state.clip~=move.reaction then victim:setVariable("ProjectYakuzaEnemyHitClip",move.reaction);state.clip=move.reaction end
    state.startedAt=getTimestampMs();state.seenReaction=false
end
function R.update(zombie, time)
    local state = R.states[zombie]
    if not state then return end
    local elapsed = (time or getTimestampMs()) - state.startedAt
    local reacting = string.find(string.lower(tostring(zombie:getCurrentStateName())), "hitreaction", 1, true) ~= nil
    if reacting then state.seenReaction = true end
    if zombie:isDead() or zombie:isOnFloor() or zombie:isKnockedDown()
        or (not reacting and (state.seenReaction or elapsed > 750)) or elapsed > 5000 then R.clear(zombie) end
end
Events.OnWeaponHitCharacter.Add(R.onHit)
function R.tick()
    local hasVictim=false
    for _ in pairs(R.states) do hasVictim=true;break end
    if not hasVictim then return end
    local time=getTimestampMs()
    if time<(R.nextUpdate or 0) then return end
    R.nextUpdate=time+50
    for zombie in pairs(R.states) do R.update(zombie,time) end
end
Events.OnTick.Add(R.tick)
