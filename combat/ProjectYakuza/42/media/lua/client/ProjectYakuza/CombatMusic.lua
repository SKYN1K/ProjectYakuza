require "ProjectYakuza/Runtime"
require "ProjectYakuza/TextureWarmup"
local ProjectYakuza=ProjectYakuza
local M={themes={},quietMs=12000,fadeIn=0.8,fadeOut=1.25}
ProjectYakuza.CombatMusic=M
function M.registerStyle(style)
    local playlist=style.music
    M.themes[style.id]=type(playlist)=="table" and #playlist>0 and playlist or nil
end
for _,style in pairs(ProjectYakuza.styles) do M.registerStyle(style) end
ProjectYakuza.on("styleRegistered",M.registerStyle)
local function now()return getTimestampMs()end
local function optionVolume()return math.max(0,math.min(1,getCore():getOptionMusicVolume()/10))end
local function musicLevel()
    return ProjectYakuza.SoundSettings and ProjectYakuza.SoundSettings.musicLevel and ProjectYakuza.SoundSettings.musicLevel() or 1
end
local function eligible(p)
    if not p or not instanceof(p,"IsoPlayer") or not p:isLocalPlayer() or p:isDead()
        or not ProjectYakuza.isEquipped(p) or p:getVehicle() then return nil end
    local style=ProjectYakuza.getPlayerStyle(p)
    return style and M.themes[style.id]
end
local function baseVolume()
    local value=optionVolume()
    if value==M.originalOption then return M.originalMusic end
    return value
end
function M.stop()
    if M.sound then
        M.emitter:stopSoundLocal(M.sound)
        M.emitter:tick()
        getSoundManager():setMusicVolume(baseVolume())
    end
    M.sound=nil;M.owner=nil;M.theme=nil;M.mix=0;M.lastGain=nil;M.lastDuck=nil
    M.originalMusic=nil;M.originalOption=nil
    if M.ticking then Events.OnTick.Remove(M.tick);M.ticking=false end
end
function M.prepare()
    if not M.emitter then
        M.emitter=FMODSoundEmitter.new()
        getSoundManager():unregisterEmitter(M.emitter)
        M.emitter:setPlayRemoteEvents(false)
    end
end
function M.start(p,theme,t,continuing)
    if not theme or musicLevel()<=0 or (M.failedUntil and t<M.failedUntil) then return false end
    M.prepare()
    local sound=M.emitter:playSoundImpl(theme.sound,false,nil)
    if not sound or sound==0 then
        M.failedUntil=t+30000
        print("[ProjectYakuza] Combat music could not start: "..theme.sound)
        return false
    end
    M.emitter:set3D(sound,false);M.emitter:setVolume(sound,0)

    if not continuing then
        M.originalMusic=getSoundManager():getMusicVolume();M.originalOption=optionVolume()
        M.mix=0;M.lastCombat=t
    end
    M.sound=sound;M.owner=p;M.theme=theme;M.lastTick=t
    M.lastGain=nil;M.lastDuck=nil
    if not M.ticking then Events.OnTick.Add(M.tick);M.ticking=true end
    return true
end
function M.contains(playlist,theme)
    for _,entry in ipairs(playlist) do if entry.sound==theme.sound then return true end end
    return false
end
function M.choose(playlist,previous)
    local choices={}
    for _,entry in ipairs(playlist) do
        if not previous or entry.sound~=previous.sound then choices[#choices+1]=entry end
    end
    if #choices==0 then return nil end
    return choices[ZombRand(#choices)+1]
end
function M.onHit(p,victim,weapon,damage)
    local theme=eligible(p)
    if not theme or not victim or not instanceof(victim,"IsoZombie") or type(damage)~="number" or damage<=0 then return end
    local t=now()
    if M.sound then
        if not M.contains(theme,M.theme) then M.stop()
        else M.owner=p;M.lastCombat=t;return end
    end
    M.start(p,M.choose(theme),t)
end
function M.tick()
    if not M.sound then return end
    local theme=eligible(M.owner)
    if not theme or not M.contains(theme,M.theme) or musicLevel()<=0 then M.stop();return end
    M.emitter:tick()
    local t=now();local elapsed=math.max(0,t-M.lastTick);M.lastTick=t
    if isGamePaused() then M.lastCombat=M.lastCombat+elapsed;return end
    local dt=math.min(0.25,elapsed/1000)
    local active=t-M.lastCombat<M.quietMs
    if not M.emitter:isPlaying(M.sound) then
        local nextTheme=active and M.choose(theme,M.theme) or nil
        if not nextTheme or not M.start(M.owner,nextTheme,t,true) then M.stop();return end
    end
    if active then M.mix=math.min(1,M.mix+dt/M.fadeIn)
    else M.mix=math.max(0,M.mix-dt/M.fadeOut) end
    if not active and M.mix<=0 then M.stop();return end
    local base=baseVolume();local gain=musicLevel()*M.mix;local duck=base*(1-M.mix)
    if not M.lastGain or math.abs(gain-M.lastGain)>=0.001 then M.emitter:setVolume(M.sound,gain);M.lastGain=gain end
    if not M.lastDuck or math.abs(duck-M.lastDuck)>=0.001 then getSoundManager():setMusicVolume(duck);M.lastDuck=duck end
end
ProjectYakuza.on("combatHit",M.onHit)
ProjectYakuza.on("styleChanged",function(p)if M.owner==p then M.stop() end end)
Events.OnSave.Add(M.stop)
Events.OnMainMenuEnter.Add(M.stop)
Events.OnGameStart.Add(M.stop)

if ProjectYakuza.TextureWarmup and ProjectYakuza.TextureWarmup.add then ProjectYakuza.TextureWarmup.add("music emitter",M.prepare)end
