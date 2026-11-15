require "ProjectYakuza/Runtime"
require "ProjectYakuza/SoundVariety"
local ProjectYakuza=ProjectYakuza
local F={states=setmetatable({}, {__mode="k"}),pending=setmetatable({}, {__mode="k"}),stocks=setmetatable({}, {__mode="k"}),activationSounds=setmetatable({}, {__mode="k"})}
ProjectYakuza.Feedback=F
F.heatMix={charge=.28,flare=.50,layer=.32,finish=.42,fadeMs=140,layerDelayMs=300,tailMs=2800}
function F.sound(p,key)
    local style=p and ProjectYakuza.getPlayerStyle(p)
    return style and type(style.sounds)=="table" and style.sounds[key] or nil
end
function F.play(p,name,volume)
    if type(name)~="string" or name=="" or not p or not p:isLocalPlayer() then return end
    local variety=ProjectYakuza.SoundVariety;local style=ProjectYakuza.getPlayerStyle(p)
    local index=variety and variety.next(p,style,name)
    if index then
        local handle=variety.play(p,style,name,index,volume or 1)
        if type(handle)=="number"then
            if isClient()and ProjectYakuza.Network and ProjectYakuza.Network.sound then ProjectYakuza.Network.sound(p,name,index,volume or 1)end
            return handle
        end
    end
    local id=p:playSound(name)
    if type(id)=="number" and id~=0 then p:getEmitter():setVolume(id,volume or 1) end
    return id
end
function F.notice(p,text)
    if p and p:isLocalPlayer() then F.states[p]={text=text,untilAt=getTimestampMs()+1100} end
end
local function unhook()
    local any=false;for _ in pairs(F.pending) do any=true;break end
    if not any then for _ in pairs(F.activationSounds) do any=true;break end end
    if not any and F.ticking then Events.OnTick.Remove(F.tick);F.ticking=false end
end
function F.cancel(p)F.pending[p]=nil;unhook()end
local function hook()
    if not F.ticking then Events.OnTick.Add(F.tick);F.ticking=true end
end
function F.stopActivation(p)
    local session=F.activationSounds[p]
    if session then for id in pairs(session.handles) do p:getEmitter():stopSound(id) end end
    F.activationSounds[p]=nil;unhook()
end
function F.activationSound(p,name,volume)
    local id=F.play(p,name,volume)
    local session=F.activationSounds[p]
    if type(id)=="number" and id~=0 then
        if session then session.handles[id]=true end
        return id
    end
end
function F.startActivation(p)
    if not p or not p:isLocalPlayer() or not ProjectYakuza.isEquipped(p) then return end
    local action=ProjectYakuza.HeatActivation and ProjectYakuza.HeatActivation.active[p]
    local old=F.activationSounds[p]
    if old and not old.completed and old.action==action then return end
    F.stopActivation(p)
    local time=getTimestampMs()
    local session={action=action,style=ProjectYakuza.getPlayerStyle(p).id,handles={},last=time,deadline=time+6000}
    F.activationSounds[p]=session
    session.charge=F.activationSound(p,F.sound(p,"heatStart"),F.heatMix.charge)
    F.notice(p,"EXTREME HEAT");hook()
end
function F.flareActivation(p)
    local session=F.activationSounds[p]
    if not session or session.flared then return end
    session.flared=true;local time=getTimestampMs();session.last=time
    session.fadeAt=time
    F.activationSound(p,F.sound(p,"heatOnA"),F.heatMix.flare)
    local second=F.sound(p,"heatOnB")
    if second then session.second=second;session.due=time+F.heatMix.layerDelayMs end
    hook()
end
function F.finishActivation(p,complete)
    local session=F.activationSounds[p]
    if not session then return end
    if not complete then F.stopActivation(p);return end
    if session.completed then return end

    if not session.flared then F.flareActivation(p) end
    session.completed=true;session.last=getTimestampMs();session.deadline=session.last+F.heatMix.tailMs
end
function F.updateActivation(p,session,time,paused)
    local dt=math.max(0,time-session.last);session.last=time
    local style=ProjectYakuza.getPlayerStyle(p)
    if p:isDead() or not ProjectYakuza.isEquipped(p) or not style or style.id~=session.style then F.stopActivation(p);return end
    if paused then
        session.deadline=session.deadline+dt
        if session.due then session.due=session.due+dt end
        if session.fadeAt then session.fadeAt=session.fadeAt+dt end
        return
    end
    local emitter=p:getEmitter()
    if session.charge and session.fadeAt then
        local fraction=math.max(0,math.min(1,(time-session.fadeAt)/F.heatMix.fadeMs))
        emitter:setVolume(session.charge,F.heatMix.charge*(1-fraction))
        if fraction>=1 then
            emitter:stopSound(session.charge);session.handles[session.charge]=nil;session.charge=nil
        end
    end
    if session.second and time>=session.due then
        F.activationSound(p,session.second,F.heatMix.layer);session.second=nil;session.due=nil
    end
    if session.completed and not session.second and not session.charge then
        local playing=false
        if emitter.isPlaying then for id in pairs(session.handles) do if emitter:isPlaying(id) then playing=true;break end end
        else playing=time<session.deadline end
        if not playing then F.activationSounds[p]=nil;return end
    end
    if time>=session.deadline then F.stopActivation(p) end
end
function F.swing(p,style,step,move)
    if style.weaponProfile then return end
    local s=ProjectYakuza.stateFor(p);local kick=move.kick or move.neutralHeavy or move.groundAttack or move.runningAttack or move.quickstepAttack or move.afterLight or move.chargedFinisher
    local hit=ProjectYakuza.Heat.isExtreme(p) and F.sound(p,"heatImpact") or kick and F.sound(p,"kickImpact") or F.sound(p,"punchImpact") or "BareHandsHit"

    local token=p:getPrimaryHandItem()
    if token and ProjectYakuza.isStyleToken(token) then token:setZombieHitSound(hit) end
    local swing=kick and F.sound(p,"kickSwing") or F.sound(p,"punchSwing")
    if not swing then return end
    local heatSpeed=ProjectYakuza.Heat.attackHeatMultiplier and ProjectYakuza.Heat.attackHeatMultiplier(p)or 1
    local duration=move.duration/(ProjectYakuza.Heat.isExtreme(p) and ProjectYakuza.Heat.config.extremeSpeed or 1)/heatSpeed
    local delay=math.max(0,((move.impact or .2)*duration-.07)*1000)
    local time=getTimestampMs()
    F.pending[p]={stamp=s.multiHitToken or s.startedAt,due=time+delay,last=time,sound=swing}
    local sourceDuration=move.duration*(move.speed or style.attackSpeed or 1)
    if type(move.animation)=="string" and p.dbgGetAnimTrackName and ProjectYakuza.AttackEffects and sourceDuration>0 then
        local job=F.pending[p];job.animation=move.animation
        job.sourceTime=math.max(0,(move.impact or .2)*sourceDuration-.07*(move.speed or style.attackSpeed or 1)*heatSpeed)
        job.sourceEnd=math.min(sourceDuration,job.sourceTime+.18*(move.speed or style.attackSpeed or 1)*heatSpeed);job.waitMs=0
        job.timeout=math.min(5000,math.max(350,duration*1000+500))
    end
    local effect=move.attackEffects
    if effect and type(effect.swingFrame)=="number" and ProjectYakuza.AttackEffects then
        local job=F.pending[p]
        job.animation=move.animation;job.sourceTime=effect.swingFrame/30;job.sourceEnd=effect.to;job.waitMs=0;job.timeout=350
    end
    if not F.ticking then Events.OnTick.Add(F.tick);F.ticking=true end
end
function F.tick()
    local time=getTimestampMs();local paused=isGamePaused()
    for p,job in pairs(F.pending) do
        local dt=math.max(0,time-job.last);job.last=time
        local s=ProjectYakuza.stateFor(p)
        if not ProjectYakuza.isEquipped(p) or p:isDead() or not s.active or (s.multiHitToken or s.startedAt)~=job.stamp
            then F.pending[p]=nil
        elseif paused then job.due=job.due+dt
        elseif job.animation then
            local phase,weight,location=ProjectYakuza.AttackEffects.findTrack(p,job.animation,job.location)
            job.location=location;job.waitMs=job.waitMs+dt
            if phase and weight>=.05 and phase>=job.sourceTime and phase<=job.sourceEnd then
                F.play(p,job.sound,.65)
                F.pending[p]=nil
            elseif job.waitMs>(job.timeout or 350) then F.pending[p]=nil
            elseif phase and phase>job.sourceEnd then job.location=nil end
        elseif time>=job.due then F.play(p,job.sound,.65);F.pending[p]=nil end
    end
    for p,session in pairs(F.activationSounds) do F.updateActivation(p,session,time,paused) end
    unhook()
end
function F.hit(p,z,weapon,damage)
    if not p or not ProjectYakuza.isEquipped(p) or type(damage)~="number" or damage<=0 then return end
    local s=ProjectYakuza.stateFor(p);local move=s.groundMove or s.finisherMove
    local style=ProjectYakuza.getPlayerStyle(p)
    if style and style.weaponProfile then
        if style.nativeWeaponSounds then return end
        if not s.active or not move then return end
        local stamp=s.multiHitToken or s.startedAt
        if s.feedbackStamp==stamp then return end
        s.feedbackStamp=stamp
        F.play(p,move.groundAttack and F.sound(p,"groundImpact")or F.sound(p,"heavyImpact")or F.sound(p,"finisher"),style.impactFeedback=="blade"and .25 or .32)
        return
    end
    if not s.active or not move or (not move.neutralHeavy and not move.afterLight and not move.groundAttack and not move.chargedHeavy) then return end
    local stamp=s.multiHitToken or s.startedAt
    if s.feedbackStamp==stamp then return end
    s.feedbackStamp=stamp
    local cue=move.groundAttack and F.sound(p,"kickImpact")or move.double and F.sound(p,"doubleFinisher")or move.chargedHeavy and F.sound(p,"chargedImpact")or move.neutralHeavy and F.sound(p,"heavyImpact")or F.sound(p,"finisher")
    F.play(p,cue,move.double and .55 or .45)
end
function F.heatChanged(p)
    if not p or not p:isLocalPlayer() then return end
    local current=ProjectYakuza.Heat.stocks(p);local previous=F.stocks[p];F.stocks[p]=current
    if previous==nil or current<=previous or ProjectYakuza.Heat.isExtreme(p) or not ProjectYakuza.isEquipped(p) then return end
    F.play(p,current>=(ProjectYakuza.Heat.rules and ProjectYakuza.Heat.rules(p)or ProjectYakuza.Heat.config).maxStocks and F.sound(p,"heatFull") or F.sound(p,"heatGain"),.55)
end
function F.initialise()
    for i=0,3 do local p=getSpecificPlayer(i);if p then F.stocks[p]=ProjectYakuza.Heat.stocks(p) end end
end
function F.clear()
    F.pending=setmetatable({}, {__mode="k"});unhook()
    for p in pairs(F.activationSounds) do F.stopActivation(p) end
end
ProjectYakuza.on("lightAttackStarted",F.swing)
ProjectYakuza.on("finisherStarted",F.swing)
local function specialSwing(p,style,move)F.swing(p,style,0,move)end
ProjectYakuza.on("quickstepAttackStarted",specialSwing)
ProjectYakuza.on("runningAttackStarted",specialSwing)
ProjectYakuza.on("chargedHeavyStarted",specialSwing)
ProjectYakuza.on("groundAttackStarted",specialSwing)
ProjectYakuza.on("comboCancelled",F.cancel)
ProjectYakuza.on("combatHit",F.hit)
ProjectYakuza.on("heatChanged",F.heatChanged)
ProjectYakuza.on("grabHeld",function(p)F.play(p,F.sound(p,"grab"),.65);F.notice(p,"GRAB - "..ProjectYakuza.Bindings.label("grab")..": throw")end)
ProjectYakuza.on("grabBroken",function(p)F.play(p,F.sound(p,"guardBreak"),.45);F.notice(p,"GRAB BROKEN")end)
ProjectYakuza.on("throwHit",function(p)F.play(p,F.sound(p,"throwImpact"),.8);F.notice(p,"THROW")end)
ProjectYakuza.on("guardHit",function(p)F.play(p,F.sound(p,"guardHit"),.4)end)
ProjectYakuza.on("guardBroken",function(p)F.play(p,F.sound(p,"guardBreak"),.75);F.notice(p,"GUARD BROKEN")end)
ProjectYakuza.on("tigerDrop",function(p)
    local s=F.states[p];local time=getTimestampMs()
    if s and s.text=="TIGER DROP" and time<s.untilAt then return end
    F.play(p,F.sound(p,"parryImpact")or F.sound(p,"finisher"),.9);F.notice(p,"TIGER DROP")
end)
ProjectYakuza.on("heatActivationStarted",F.startActivation)
ProjectYakuza.on("heatActivationFlare",F.flareActivation)
ProjectYakuza.on("heatActivationStopped",F.finishActivation)
ProjectYakuza.on("extremeHeatEnded",function(p,reason)
    F.stopActivation(p)
    if (not reason or reason=="depleted") and not p:isDead() and ProjectYakuza.isEquipped(p) then
        F.play(p,F.sound(p,"heatOff"),F.heatMix.finish)
    end
end)
ProjectYakuza.on("styleChanged",F.stopActivation)
Events.OnGameStart.Add(F.initialise)
Events.OnSave.Add(F.clear)
Events.OnMainMenuEnter.Add(F.clear)
