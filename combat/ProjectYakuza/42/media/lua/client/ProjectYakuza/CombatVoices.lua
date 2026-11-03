require "ProjectYakuza/Runtime"
require "ProjectYakuza/CVFCombatLines"
local ProjectYakuza=ProjectYakuza;local C=ProjectYakuza.CombatVoiceLines
local V={states=setmetatable({}, {__mode="k"})}
local stunWords={"stun","stagger","knock","trip","bump"}
ProjectYakuza.CombatVoices=V
function V.ready()
    return C.register() and type(CustomVoice.playLine)=="function"
end
function V.allowed(p)
    if not p or not instanceof(p,"IsoPlayer") or not p:isLocalPlayer() or p:isDead() or p:isAsleep() or not ProjectYakuza.isEquipped(p) then return false end
    local style=ProjectYakuza.getPlayerStyle(p)
    return style and style.combatVoices~=false and not p:getVehicle()
end
function V.play(p,id)
    if not C.byId[id] or not V.allowed(p) or not V.ready() or not C.accepted[id] then return false,"unavailable" end

    local level=ProjectYakuza.SoundSettings and ProjectYakuza.SoundSettings.voiceLevel() or 1
    local style=ProjectYakuza.getPlayerStyle(p)
    local gain=style.combatVoiceGains and style.combatVoiceGains[id]or 1
    local scale=(style.combatVoiceVolume or 1)*gain*level
    if scale<=0 then return false,"muted" end
    local ok,played,reason=pcall(CustomVoice.playLine,p,C.modId,id)
    if not ok then return false,"provider_error" end
    if played==true and type(reason)=="number" and reason~=0 then
        if type(scale)=="number" and scale>0 and scale~=1 then

            local emitter=p:getEmitter()
            pcall(emitter.setVolume,emitter,reason,scale)
        end
    end
    return played==true,reason
end
function V.hasRecording(p,id)
    if not C.byId[id] or not V.allowed(p) or not V.ready() or not C.accepted[id] then return false end
    local line=CustomVoice.getLine(C.modId,id)
    local descriptor=p:getDescriptor();local scripts=getScriptManager()
    local prefix=descriptor and descriptor:getVoicePrefix()
    return line and prefix and scripts and scripts:getGameSound(prefix..line.suffix)~=nil or false
end
local function state(p)
    local s=V.states[p]
    if not s then s={};V.states[p]=s end
    return s
end
function V.queue(p,id)
    if not V.allowed(p) or not V.ready() then return end
    local combo=ProjectYakuza.stateFor(p)
    state(p).pending={id=id,stamp=combo.multiHitToken or combo.startedAt,at=getTimestampMs()+20}
end
function V.contact(p,id)
    local played,reason=V.play(p,id)
    local s=V.states[p]
    if played then if s then s.contact=nil end;return end
    local context=ProjectYakuza.activeActions and ProjectYakuza.activeActions[p]
    if context and context.kind=="heatAction"and(reason=="cooldown"or reason=="voice busy")then
        local time=getTimestampMs();state(p).contact={id=id,context=context,deadline=time+600,nextTry=time+75}
    end
end
function V.stunned(p)
    if p:isKnockedDown() then return true end
    local reaction=string.lower((p:getHitReaction() or "").." "..(p:getCurrentStateName() or ""))
    for _,word in ipairs(stunWords) do
        if reaction:find(word,1,true) then return true end
    end
    return false
end
function V.update(p)
    if not p or not p:isLocalPlayer() then return end
    if not V.ready() then V.states[p]=nil;return end
    local time=getTimestampMs();local s=V.states[p]
    if s and not s.pending and time<(s.nextPoll or 0) then return end
    if not V.allowed(p) then V.states[p]=nil;return end
    s=state(p);s.nextPoll=time+75
    local stunned=V.stunned(p);local aiming=p:isAiming()
    if s.contact then
        local job=s.contact
        if stunned or time>job.deadline or not ProjectYakuza.activeActions or ProjectYakuza.activeActions[p]~=job.context then s.contact=nil
        elseif time>=job.nextTry then
            local played,reason=V.play(p,job.id);job.nextTry=time+75
            if played or(reason~="cooldown"and reason~="voice busy")then s.contact=nil end
        end
    end
    if s.activation then
        local a=s.activation;local active=ProjectYakuza.HeatActivation and ProjectYakuza.HeatActivation.active[p]
        if time>a.deadline or (a.action and active~=a.action) or stunned then s.activation=nil
        elseif time>=a.nextTry then
            local played,reason=V.play(p,"CombatExtremeHeatActivation");a.nextTry=time+100
            if played or (reason~="cooldown" and reason~="voice busy") then s.activation=nil end
        end
        s.aiming=aiming;return
    end
    if stunned and not s.stunned then V.play(p,"CombatGettingStunned") end
    s.stunned=stunned
    if s.pending and getTimestampMs()>=s.pending.at then
        local pending=s.pending;s.pending=nil
        local combo=ProjectYakuza.stateFor(p)
        if not stunned and combo.active and (combo.multiHitToken or combo.startedAt)==pending.stamp then
            local id=pending.id

            if combo.groundMove then id="CombatHeavyAttack" end
            V.play(p,id)
        end

    end
    s.aiming=aiming
end
local acute={ZOMBIEBITE=true,ZOMBIESCRATCH=true,ZOMBIELACERATION=true,ZOMBIEATTACK=true,
    WEAPONHIT=true,CARCRASH=true,FALLDOWN=true,FALL=true,HIT=true,BITE=true,SCRATCH=true,LACERATION=true}
function V.onDamage(p,kind,damage)
    if not V.allowed(p) or type(damage)~="number" or damage~=damage or damage<=0 or not acute[string.upper(tostring(kind))] then return end
    local stunned=V.stunned(p)
    if stunned then state(p).stunned=true end
    V.play(p,stunned and "CombatGettingStunned" or "CombatGettingHit")
end
function V.taunt(p)
    if not V.allowed(p) or ProjectYakuza.isBusy(p) then return false,"not_ready" end
    return V.play(p,"CombatTaunt")
end
function V.clear()V.states=setmetatable({}, {__mode="k"})end
ProjectYakuza.on("lightAttackStarted",function(p)V.queue(p,"CombatLightAttack")end)
ProjectYakuza.on("finisherStarted",function(p)V.queue(p,"CombatHeavyAttack")end)
ProjectYakuza.on("chargedHeavyStarted",function(p)V.queue(p,"CombatHeavyAttack")end)
ProjectYakuza.on("groundAttackStarted",function(p)V.queue(p,"CombatHeavyAttack")end)
ProjectYakuza.on("runningAttackStarted",function(p)V.queue(p,"CombatSpecialMove")end)
ProjectYakuza.on("quickstepAttackStarted",function(p)V.queue(p,"CombatSpecialMove")end)
ProjectYakuza.on("actionStarted",function(c)
    if c.kind=="quickstep" and ProjectYakuza.getPlayerStyle(c.player).quickstepVoices==false or c.kind=="heatAction"and c.action and(c.action.heatRush or c.action.weaponHeat)then return end
    if c.kind=="quickstep" or c.kind=="parry" or c.kind=="grab" or c.kind=="heatAction" then V.play(c.player,"CombatSpecialMove") end
end)
ProjectYakuza.on("heatRushHit",function(p,z,index,contact)if contact and contact.voice then V.contact(p,contact.voice)end end)
local function endContact(context)local s=V.states[context.player];if s and s.contact and s.contact.context==context then s.contact=nil end end
ProjectYakuza.on("actionCompleted",endContact)
ProjectYakuza.on("actionCancelled",endContact)
ProjectYakuza.on("throwStarted",function(p)V.play(p,"CombatSpecialMove")end)
function V.activation(p)
    if not V.allowed(p) then return end
    local s=state(p);s.pending=nil;s.activation=nil
    local played,reason=V.play(p,"CombatExtremeHeatActivation")
    if not played and (reason=="cooldown" or reason=="voice busy") then
        local action=ProjectYakuza.HeatActivation and ProjectYakuza.HeatActivation.active[p]
        s.activation={action=action,deadline=getTimestampMs()+1500,nextTry=getTimestampMs()+100}
    end
end
ProjectYakuza.on("heatActivationStarted",V.activation)
ProjectYakuza.on("heatActivationStopped",function(p)local s=V.states[p];if s then s.activation=nil end end)
ProjectYakuza.on("tauntStarted",function(p)V.play(p,"CombatTaunt")end)
ProjectYakuza.on("styleEntryStarted",function(p)V.play(p,"CombatStanceEntry")end)
ProjectYakuza.on("guardBroken",function(p)if V.allowed(p) then state(p).stunned=true;V.play(p,"CombatGettingStunned") end end)
ProjectYakuza.on("comboCancelled",function(p)local s=V.states[p];if s then s.pending=nil end end)
ProjectYakuza.on("styleChanged",function(p)V.states[p]=nil end)
Events.OnPlayerUpdate.Add(V.update)
Events.OnPlayerGetDamage.Add(V.onDamage)
Events.OnGameStart.Add(function()C.register();V.clear()end)
Events.OnMainMenuEnter.Add(V.clear)
