require "ProjectYakuza/Runtime"
local PY=ProjectYakuza
local L={states=setmetatable({}, {__mode="k"}),polls=setmetatable({}, {__mode="k"}),combat=setmetatable({}, {__mode="k"}),pollMs=250}
PY.LowHealthFeedback=L
local tickEvent=Events.OnTickEvenPaused or Events.OnTick
local function eligible(p)
    if not p or not p:isLocalPlayer()or p:isDead()or not PY.isEquipped(p)or p:getVehicle()or p:isAsleep()then return end
    local style=PY.getPlayerStyle(p);local cfg=PY.LowHealthRules.forStyle(style)
    if cfg then return style,cfg end
end
function L.stopAudio(s)
    if s.sound then s.emitter:stopSoundLocal(s.sound);s.emitter:tick();s.sound=nil end
    s.audioGain=0;s.lastGain=nil
end
function L.syncHook()
    local any=false;for _ in pairs(L.states)do any=true;break end
    if any and not L.hooked then tickEvent.Add(L.tick);L.hooked=true
    elseif not any and L.hooked then tickEvent.Remove(L.tick);L.hooked=false end
end
function L.clear(p)
    local s=L.states[p]
    if s then L.stopAudio(s);L.states[p]=nil;PY.emit("lowHealthEnded",p)end
    L.syncHook()
end
function L.clearAll()
    for p in pairs(L.states)do L.clear(p)end
    L.polls=setmetatable({}, {__mode="k"});L.combat=setmetatable({}, {__mode="k"})
end
function L.markCombat(p)
    if p and p:isLocalPlayer()then L.combat[p]=getTimestampMs()end
end
function L.advance(s,t)
    local elapsed=math.max(0,t-s.last);s.last=t
    local paused=isGamePaused()
    if paused then s.paused=true;return 0 end
    if s.paused then elapsed=0;s.paused=false end
    local dt=math.min(250,elapsed);s.clock=s.clock+dt
    local target=s.recovering and 0 or s.level
    local rate=dt/(target>s.fade and 300 or 400)
    if target>s.fade then s.fade=math.min(target,s.fade+rate)else s.fade=math.max(target,s.fade-rate)end
    return dt
end
function L.update(p,force)
    if not p or not p:isLocalPlayer()then return end
    local t=getTimestampMs()
    if not force and t<(L.polls[p]or 0)then return end;L.polls[p]=t+L.pollMs
    local style,cfg=eligible(p);local s=L.states[p]
    if not cfg then L.clear(p);L.combat[p]=nil;return end
    if s and(s.style~=style.id or s.cfg~=cfg)then L.clear(p);s=nil end
    local health=p:getBodyDamage():getOverallBodyHealth()
    if type(health)~="number"or health~=health then L.clear(p);return end
    health=math.max(0,math.min(100,health))
    if not s and health>cfg.threshold then return end
    local started=not s
    if not s then s={style=style.id,cfg=cfg,last=t,clock=0,fade=0,audioGain=0};L.states[p]=s end
    s.health=health;s.recovering=health>=cfg.recover
    s.level=math.max(.2,math.min(1,(cfg.threshold-health)/(cfg.threshold-cfg.critical)))
    s.critical=health<=cfg.critical;s.period=1200-350*s.level
    local stats=p:getStats()
    if stats:getNumChasingZombies()>0 or stats:getNumVeryCloseZombies()>0 and stats:getNumVisibleZombies()>0 then L.combat[p]=t end
    local native=GameSounds.getSound("HeartBeat")
    s.nativeHeartbeat=stats:get(CharacterStat.PANIC)>0 and native and native:getUserVolume()>0 and p:getEmitter():isPlaying("HeartBeat")or false
    if started then L.syncHook();PY.emit("lowHealthStarted",p,health)end
end
function L.sample(p)
    local s=L.states[p];if not s or not s.cfg.hud then return 0 end
    if isGamePaused()then L.advance(s,getTimestampMs());L.stopAudio(s)end
    local elapsed=isGamePaused()and 0 or math.max(0,math.min(250,getTimestampMs()-s.last))
    local wave=(.5+.5*math.sin((s.clock+elapsed)/s.period*math.pi*2))^4
    return s.fade*(.25+.75*wave),s.critical,s.health
end
function L.audio(p,s,t,dt)
    local cfg=s.cfg;local style=PY.getPlayerStyle(p);local name=cfg.soundKey and style.sounds and style.sounds[cfg.soundKey]
    local combat=L.combat[p];local wanted=not s.recovering and not s.nativeHeartbeat and combat and t-combat<=cfg.quietMs and type(name)=="string"and name~=""
    local target=wanted and cfg.volume*s.fade or 0
    local step=dt/300
    if target>s.audioGain then s.audioGain=math.min(target,s.audioGain+step)else s.audioGain=math.max(target,s.audioGain-step)end
    if s.audioGain<=.001 then L.stopAudio(s);return end
    if s.sound and not s.emitter:isPlaying(s.sound)then s.sound=nil end
    if not s.sound and t>=math.max(s.retryAt or 0,s.nextBeat or 0)then
        if not s.emitter then s.emitter=FMODSoundEmitter.new();getSoundManager():unregisterEmitter(s.emitter);s.emitter:setPlayRemoteEvents(false)end
        local id=s.emitter:playSoundImpl(name,false,nil)
        if type(id)~="number"or id==0 then s.retryAt=t+30000;return end
        s.sound=id;s.nextBeat=t+s.period;s.emitter:set3D(id,false);s.lastGain=nil
    end
    if s.sound and(s.lastGain==nil or math.abs(s.lastGain-s.audioGain)>=.001)then s.emitter:setVolume(s.sound,s.audioGain);s.lastGain=s.audioGain end
    if s.emitter then s.emitter:tick()end
end
function L.tick()
    local t=getTimestampMs()
    for p,s in pairs(L.states)do
        local style,cfg=eligible(p)
        if not style or style.id~=s.style or cfg~=s.cfg then L.clear(p)
        else
            local dt=L.advance(s,t)
            if isGamePaused()then
                L.stopAudio(s)
                if L.combat[p]then L.combat[p]=L.combat[p]+math.max(0,t-(s.pauseAt or t))end;s.pauseAt=t
            else
                s.pauseAt=nil
                if s.recovering and s.fade<=0 then L.clear(p)else L.audio(p,s,t,dt)end
            end
        end
    end
end
PY.on("combatHit",L.markCombat)
PY.on("guardHit",L.markCombat)
PY.on("styleChanged",function(p)L.clear(p);L.polls[p]=nil;L.combat[p]=nil end)
if Events.OnPlayerGetDamage then Events.OnPlayerGetDamage.Add(function(p)L.markCombat(p);L.update(p,true)end)end
Events.OnPlayerUpdate.Add(L.update)
Events.OnSave.Add(L.clearAll)
Events.OnMainMenuEnter.Add(L.clearAll)
