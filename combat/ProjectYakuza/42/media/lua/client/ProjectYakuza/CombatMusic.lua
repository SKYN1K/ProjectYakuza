require "ProjectYakuza/Runtime"
require "ProjectYakuza/TextureWarmup"
local ProjectYakuza=ProjectYakuza
local M={themes={},orders=setmetatable({}, {__mode="k"}),quietMs=22000,fadeIn=0.8,fadeOut=1.25}
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
    M.originalMusic=nil;M.originalOption=nil;M.manual=false;M.elapsedMs=0
    if M.ticking then Events.OnTick.Remove(M.tick);if Events.OnTickEvenPaused then Events.OnTickEvenPaused.Remove(M.pauseTick)end;M.ticking=false end
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
    if M.sound and M.sound~=sound then M.emitter:stopSoundLocal(M.sound)end
    M.emitter:set3D(sound,false);M.emitter:setVolume(sound,0)

    if not continuing then
        M.originalMusic=getSoundManager():getMusicVolume();M.originalOption=optionVolume()
        M.mix=0;M.lastCombat=t
    end
    M.sound=sound;M.owner=p;M.theme=theme;M.lastTick=t;M.elapsedMs=0;M.lastSelection={owner=p,track=theme}
    M.lastGain=nil;M.lastDuck=nil
    if not M.ticking then Events.OnTick.Add(M.tick);if Events.OnTickEvenPaused then Events.OnTickEvenPaused.Add(M.pauseTick)end;M.ticking=true end
    return true
end
function M.contains(playlist,theme)
    for _,entry in ipairs(playlist) do if entry.sound==theme.sound then return true end end
    return false
end
function M.playlist(p)
    return eligible(p)or {}
end
function M.preferences(p)
    if not p or not p.getModData then return {repeatMode="all",favorites={}}end
    local data=p:getModData()
    if type(data.ProjectYakuzaMusic)~="table"then data.ProjectYakuzaMusic={}end
    local settings=data.ProjectYakuzaMusic
    if type(settings.shuffle)~="boolean"then settings.shuffle=nil end
    if settings.repeatMode~="off"and settings.repeatMode~="one"then settings.repeatMode="all"end
    if type(settings.favorites)~="table"then settings.favorites={}end
    return settings
end
function M.shuffled(p,manual)
    local setting=M.preferences(p).shuffle
    if setting~=nil then return setting end
    return not manual
end
function M.setShuffle(p,value)
    if not p or not p.getModData or not p:isLocalPlayer()then return false,"Choose a local player."end
    if type(value)~="boolean"then return false,"Choose shuffle on or off."end
    if M.owner and M.owner~=p then return false,"Another local player owns music playback."end
    M.preferences(p).shuffle=value;M.orders[p]=nil;return true
end
function M.setRepeat(p,value)
    if not p or not p.getModData or not p:isLocalPlayer()then return false,"Choose a local player."end
    if value~="off"and value~="all"and value~="one"then return false,"Choose repeat off, all or one."end
    if M.owner and M.owner~=p then return false,"Another local player owns music playback."end
    M.preferences(p).repeatMode=value;return true
end
function M.toggleFavorite(p,sound)
    local allowed=false;for _,track in ipairs(M.playlist(p))do if track.sound==sound then allowed=true;break end end
    if not allowed then return false,"Choose a song from the equipped style."end
    local favorites=M.preferences(p).favorites;favorites[sound]=not favorites[sound]or nil;return true
end
function M.current(p)
    local active=M.sound~=nil and M.owner==p
    local selected=active and M.theme or M.lastSelection and M.lastSelection.owner==p and M.lastSelection.track or nil
    if selected and not M.contains(M.playlist(p),selected)then selected=nil end
    local elapsed=active and(M.elapsedMs or 0)or 0
    if active and not isGamePaused()then elapsed=elapsed+math.max(0,now()-M.lastTick)end
    local duration=selected and tonumber(selected.duration)or nil
    if duration then elapsed=math.min(elapsed,duration*1000)end
    local settings=M.preferences(p)
    return {playing=active,track=selected,position=elapsed/1000,duration=duration,manual=active and M.manual==true,automatic=M.blockedOwner~=p,estimated=true,
        shuffle=M.shuffled(p,not active or M.manual==true),repeatMode=settings.repeatMode,favorite=selected and settings.favorites[selected.sound]==true or false}
end
function M.order(p,playlist,manual)
    local names={};for _,track in ipairs(playlist)do names[#names+1]=track.sound end
    local signature=table.concat(names,"|")..tostring(M.shuffled(p,manual));local order=M.orders[p]
    if not order or order.signature~=signature then
        order={signature=signature,bag={},history={},cursor=0};M.orders[p]=order
        local current=M.current(p).track
        for _,track in ipairs(playlist)do if not current or track.sound~=current.sound then order.bag[#order.bag+1]=track.sound end end
        if current then order.history[1]=current.sound;order.cursor=1 end
    end
    return order
end
function M.remember(p,playlist,manual,track,navigation)
    local order=M.order(p,playlist,manual)
    if navigation then order.cursor=navigation;return end
    if order.history[order.cursor]~=track.sound then
        for i=#order.history,order.cursor+1,-1 do order.history[i]=nil end
        order.history[#order.history+1]=track.sound;order.cursor=#order.history
        if #order.history>128 then table.remove(order.history,1);order.cursor=order.cursor-1 end
    end
    for i=#order.bag,1,-1 do if order.bag[i]==track.sound then table.remove(order.bag,i)end end
end
function M.candidate(p,direction,natural,manual)
    local playlist=M.playlist(p);if #playlist==0 then return nil,nil,"Equip a style with a playlist first."end
    local current=M.current(p).track;local index=direction==1 and 0 or 1
    local function locate(sound)for i,track in ipairs(playlist)do if track.sound==sound then return i end end end
    if current then index=locate(current.sound)or index end
    local mode=M.preferences(p).repeatMode
    if natural and mode=="one"and current then return index end
    local order=M.order(p,playlist,manual)
    local cursor=order.cursor+direction
    if cursor>=1 and cursor<=#order.history then return locate(order.history[cursor]),cursor end
    if not M.shuffled(p,manual)then
        local nextIndex=index+direction
        if natural and mode=="off"and(nextIndex<1 or nextIndex>#playlist)then return nil,nil,"End of playlist."end
        return (nextIndex-1+#playlist)%#playlist+1
    end
    if #order.bag==0 then
        if natural and mode=="off"then return nil,nil,"End of playlist."end
        for _,track in ipairs(playlist)do if not current or track.sound~=current.sound then order.bag[#order.bag+1]=track.sound end end
    end
    if #order.bag==0 then return index end
    return locate(order.bag[ZombRand(#order.bag)+1])
end
local function playSelected(p,index,manual,navigation)
    local playlist=M.playlist(p)
    if type(index)~="number"or index~=math.floor(index)or not playlist[index]then return false,"Choose a song from the equipped style."end
    if M.owner and M.owner~=p then return false,"Another local player owns music playback."end
    if not M.start(p,playlist[index],now(),M.sound~=nil)then return false,"Music is muted or could not start."end
    M.manual=manual~=false;M.blockedOwner=nil;M.remember(p,playlist,M.manual,playlist[index],navigation)
    return true
end
function M.play(p,index,manual)return playSelected(p,index,manual)end
function M.skip(p,direction)
    if direction~=-1 and direction~=1 then return false,"Invalid track direction."end
    local manual=not M.sound or M.manual==true
    local index,navigation,message=M.candidate(p,direction,false,manual)
    if not index then return false,message end
    return playSelected(p,index,manual,navigation)
end
function M.userStop(p)
    if M.owner and M.owner~=p then return false,"Another local player owns music playback."end
    M.stop();M.blockedOwner=p;return true
end
function M.automatic(p)
    if M.owner and M.owner~=p then return false,"Another local player owns music playback."end
    M.blockedOwner=nil;M.manual=false;return true
end
function M.onHit(p,victim,weapon,damage)
    local theme=eligible(p)
    if M.blockedOwner==p or not theme or not victim or not instanceof(victim,"IsoZombie") or type(damage)~="number" or damage<=0 then return end
    local t=now()
    if M.sound then
        if not M.contains(theme,M.theme) then M.stop()
        else M.owner=p;M.lastCombat=t;return end
    end
    local index,navigation=M.candidate(p,1,false,false)
    if index then playSelected(p,index,false,navigation)end
end
function M.tick()
    if not M.sound then return end
    local theme=eligible(M.owner)
    if not theme or not M.contains(theme,M.theme) or musicLevel()<=0 then M.stop();return end
    M.emitter:tick()
    local t=now();local elapsed=math.max(0,t-M.lastTick);M.lastTick=t
    if isGamePaused() then M.lastCombat=M.lastCombat+elapsed;return end
    local dt=math.min(0.25,elapsed/1000)
    M.elapsedMs=(M.elapsedMs or 0)+elapsed
    local active=M.manual==true or t-M.lastCombat<M.quietMs
    if not M.emitter:isPlaying(M.sound) then
        local index,navigation
        if active then index,navigation=M.candidate(M.owner,1,true,M.manual==true)end
        if not index or not playSelected(M.owner,index,M.manual==true,navigation)then M.stop();return end
    end
    if active then M.mix=math.min(1,M.mix+dt/M.fadeIn)
    else M.mix=math.max(0,M.mix-dt/M.fadeOut) end
    if not active and M.mix<=0 then M.stop();return end
    local base=baseVolume();local gain=musicLevel()*M.mix;local duck=base*(1-M.mix)
    if not M.lastGain or math.abs(gain-M.lastGain)>=0.001 then M.emitter:setVolume(M.sound,gain);M.lastGain=gain end
    if not M.lastDuck or math.abs(duck-M.lastDuck)>=0.001 then getSoundManager():setMusicVolume(duck);M.lastDuck=duck end
end
function M.pauseTick()
    if not M.sound or not isGamePaused()then return end
    local t=now();M.lastCombat=M.lastCombat+math.max(0,t-M.lastTick);M.lastTick=t
end
ProjectYakuza.on("combatHit",M.onHit)
ProjectYakuza.on("styleChanged",function(p)if M.owner==p then M.stop()end;if M.blockedOwner==p then M.blockedOwner=nil end;if M.lastSelection and M.lastSelection.owner==p then M.lastSelection=nil end;M.orders[p]=nil end)
function M.clear()M.stop();M.blockedOwner=nil;M.lastSelection=nil;M.orders=setmetatable({}, {__mode="k"})end
Events.OnSave.Add(M.clear)
Events.OnMainMenuEnter.Add(M.clear)
Events.OnGameStart.Add(M.clear)

if ProjectYakuza.TextureWarmup and ProjectYakuza.TextureWarmup.add then ProjectYakuza.TextureWarmup.add("music emitter",M.prepare)end
