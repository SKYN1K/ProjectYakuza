Events.OnGameStart=event()
local tokenData={}
function token:getModData()return tokenData end
function base:forceStop()self:stop()end
do local _="ProjectYakuzaFixture:TIGER" end
local P=PY.TigerDrop
local z={attacking=true,target=p,outcome='start',vars={ZombieBiteDone='false',ProjectYakuzaTigerWindow='false'},x=.7,y=0}
function z:isDead()return false end;function z:isOnFloor()return false end;function z:isKnockedDown()return false end
function z:getX()return self.x end;function z:getY()return self.y end;function z:getZ()return 0 end
function z:getTarget()return self.target end;function z:isAttacking()return self.attacking end
function z:getAttackOutcome()return self.outcome end;function z:getAttackDidDamage()return self.damaged==true end
function z:GetVariable(k)return self.vars[k]end;function z:setVariable(k,v)self.vars[k]=tostring(v)end
function z:getOnlineID()return 1 end
getCell=function()return {getGridSquare=function(_,x,y)if x==0 and y==0 then return {getMovingObjects=function()return {size=function()return 1 end,get=function()return z end}end}end end}end
P.track(p,true)
check(P.validTarget(p,z),'already-attacking target is tracked without requiring replaced animation marker')
local start=clock;clock=start+160;check(P.validTarget(p,z),'160 ms window includes its boundary')
clock=start+161;z.vars.ProjectYakuzaTigerWindow='true';check(not P.validTarget(p,z),'legacy marker cannot extend window beyond 160 ms')
z.attacking=false;clock=clock+60;P.track(p,true)
check(not P.tracked[z].startedAt,'idle clears observed attack clock')
z.attacking=true;clock=clock+60;P.track(p,true);z.damaged=true
check(not P.validTarget(p,z),'attack that already damaged player cannot be countered')
z.damaged=false;z.vars.ZombieBiteDone='true';check(not P.validTarget(p,z),'completed bite cannot be countered')
z.vars.ZombieBiteDone='false';z.x=-.7;check(not P.validTarget(p,z),'counter requires frontal target')
z.x=.7;z.outcome='fail';check(not P.validTarget(p,z),'failed attack cannot open counter')
z.outcome='start';z.attacking=false;P.track(p,true);clock=clock+60;z.attacking=true;P.track(p,true)
SandboxVars={ProjectYakuza={DragonTigerDropWindowMs=40,DragonTigerDropCooldownSeconds=2.5}};local observed=P.tracked[z].startedAt;clock=observed+40;check(P.validTarget(p,z),'configured Tiger Drop window includes boundary');clock=observed+41;check(not P.validTarget(p,z),'configured Tiger Drop window closes immediately after boundary');SandboxVars.ProjectYakuza.DragonTigerDrop=false;check(not P.ready(p),'disabled Dragon Tiger Drop never arms');SandboxVars=nil;clock=observed
local killed=0;local realKill=P.kill
P.kill=function(_,target)killed=killed+1;P.tracked[target]=nil end
local cleared=0;PY.ChargedHeavy={clearPlayer=function()cleared=cleared+1 end,input=function()error('counter must take priority over charged heavy')end}
PY.Bindings.options={getOption=function(_,key)
 if key=='input_counter' then return {getValue=function()return 4 end}end
 if key=='key_counter' then return {getValue=function()return 999 end}end
end}
mouse[2]=true;fire('OnPlayerUpdate',p)
check(killed==1 and PY.activeActions[p] and PY.activeActions[p].kind=='parry','actual heavy input triggers Tiger Drop even with separate counter binding')
check(cleared==1 and not PY.stateFor(p).finisherMove,'counter consumes heavy input and clears charge gesture')
check(P.remaining(p)==20000 and not P.tryCounter(p),'successful counter starts its twenty-second cooldown')
PY.cancelAction(p,'test');PY.ChargedHeavy=nil;PY.Bindings.options=nil;mouse[2]=false
p.data.ProjectYakuzaTigerDropReadyAt=nil;SandboxVars={ProjectYakuza={DragonTigerDropWindowMs=60,DragonTigerDropCooldownSeconds=2.5}};P.tracked[z]={player=p,startedAt=clock};check(P.tryCounter(p)and P.remaining(p)==2500,'actual counter uses the configured fractional-second cooldown');PY.cancelAction(p,'sandbox_test');SandboxVars=nil
P.kill=realKill;isClient=function()return true end
local sent
PY.Network={send=function(_,command,args)sent={command=command,args=args}end}
P.tracked[z]={player=p,startedAt=clock-150};P.kill(p,z)
check(sent.command=='counter' and sent.args.age==150,'primary MP counter sends bounded observed age')
P.tracked[z]=nil;P.kill(p,z);check(sent.args.age==nil,'supplementary victim shares existing server burst instead of claiming new window')
isClient=function()return false end;PY.Network=nil
p.data.ProjectYakuzaTigerDropReadyAt=nil
local musicOption,nativeMusic,ownLevel=0,0,1
getCore=function()return {isDoingTextEntry=function()return false end,getOptionMusicVolume=function()return musicOption end}end
getSoundManager=function()return {getMusicVolume=function()return nativeMusic end,setMusicVolume=function(_,v)nativeMusic=v end,unregisterEmitter=function()end}end
PY.SoundSettings={musicLevel=function()return ownLevel end}
local emitter={playing=true}
function emitter:playSoundImpl()self.playing=true;self.id=(self.id or 0)+1;return self.id end
function emitter:stopSoundLocal(id)if id==self.id then self.playing=false end end
function emitter:setPlayRemoteEvents()end;function emitter:set3D()end;function emitter:tick()end
function emitter:setVolume(_,v)self.volume=v end
function emitter:isPlaying()return self.playing end
local emitterAllocations=0
FMODSoundEmitter={new=function()emitterAllocations=emitterAllocations+1;return emitter end}
local musicWarmups={}
PY.TextureWarmup={add=function(key,fn)musicWarmups[#musicWarmups+1]=fn end}
ZombRand=function()return 0 end
do local _="ProjectYakuzaFixture:MUSIC" end
local M=PY.CombatMusic
check(M.quietMs==22000 and M.fadeOut==1.25,'music waits ten additional seconds before its unchanged fade')
check(#musicWarmups==1,'combat music registers one bounded setup job')
musicWarmups[1]();M.prepare();check(emitterAllocations==1 and M.emitter==emitter and not M.sound,'emitter warm-up is silent, idempotent and ready before the first hit')
local theme=PY.getStyle('dragon_of_dojima').music[1]
check(M.start(p,theme,clock) and M.sound,'PZ music slider zero does not mute mod soundtrack')
for i=1,4 do clock=clock+250;M.tick()end
check(emitter.volume==1 and nativeMusic==0,'mod slider alone controls track gain while vanilla music remains muted')
musicOption=5;clock=clock+50;M.tick();check(emitter.volume==1,'changing vanilla music slider cannot change soundtrack gain')
ownLevel=.4;clock=clock+50;M.tick();check(emitter.volume==.4,'own slider changes current soundtrack immediately without squared gain')
M.stop();check(nativeMusic==.5,'vanilla music option is still respected when restoring it')
ownLevel=0;check(not M.start(p,theme,clock),'own zero slider mutes mod soundtrack independently')
ownLevel=2;musicOption=0;nativeMusic=0;M.start(p,theme,clock)
for i=1,4 do clock=clock+250;M.tick()end
check(emitter.volume==2,'own 200-percent slider is not multiplied by vanilla music volume')
M.stop()
ownLevel=1;M.start(p,theme,clock);local musicStarted=clock
for i=1,4 do clock=clock+250;M.tick()end
clock=musicStarted+21999;M.tick();check(M.sound and M.mix==1,'combat music remains fully audible until the new quiet deadline')
clock=musicStarted+22000;M.tick();check(M.sound and M.mix<1,'combat music begins fading at twenty-two quiet seconds')
for i=1,6 do clock=clock+250;M.tick()end
check(not M.sound,'music still releases its emitter after the fade');M.stop()
do
 local paused=false;isGamePaused=function()return paused end
 M.clear();local playlist=M.playlist(p);check(#playlist==20,'music control exposes the equipped style playlist')
 check(not M.play(p,0)and not M.play(p,1.5)and not M.play(p,999),'invalid selections cannot start audio')
 check(M.play(p,1)and M.manual and M.current(p).track==playlist[1],'manual playback starts the selected original sound')
 local first=M.sound;clock=clock+1000;M.tick();check(M.current(p).position==1,'elapsed position advances in real seconds')
 paused=true;clock=clock+5000;M.tick();check(M.current(p).position==1,'paused game time is excluded from elapsed progress');paused=false
 paused=true;clock=clock+5000;M.pauseTick();paused=false;clock=clock+20;M.tick();check(math.abs(M.current(p).position-1.02)<.00001,'paused-event polling excludes pauses even when normal ticks are suspended')
 check(M.skip(p,1)and M.theme==playlist[2]and M.sound~=first and emitter.playing and M.current(p).position==0,'next replaces the old sound without stopping the new channel')
 check(M.skip(p,-1)and M.theme==playlist[1],'previous follows the style playlist order')
 check(M.skip(p,-1)and M.theme==playlist[#playlist],'previous wraps to the final track')
 clock=clock+60000;M.tick();check(M.sound and M.manual,'manual music continues outside the combat quiet deadline')
 emitter.playing=false;clock=clock+50;M.tick();check(M.sound and M.manual and emitter.playing,'manual playlist advances naturally after a track ends')
 M.play(p,3);emitter.playing=false;clock=clock+50;M.tick();check(M.theme==playlist[4],'manual playback advances in playlist order while combat retains shuffled selection')
 local last=M.theme;M.userStop(p);check(not M.sound and not M.current(p).automatic and M.current(p).track==last,'stop retains selected metadata and suppresses automatic restart')
 M.automatic(p);check(M.current(p).automatic and not M.manual,'automatic mode restores combat ownership')
 M.play(p,1);M.automatic(p);clock=clock+23000;for i=1,7 do clock=clock+250;M.tick()end;check(not M.sound,'automatic mode returns to the existing combat fade lifecycle')
 local other={};check(not M.current(other).playing and M.current(other).track==nil,'another local player cannot read ownership as their own stream')
 M.clear();check(not M.lastSelection and not M.blockedOwner and not M.sound,'world cleanup clears manual playback and UI selection ownership')
 local duration=playlist[1].duration;playlist[1].duration=-1;check(not PY.validateStyle(PY.getStyle('dragon_of_dojima')),'negative duration metadata is rejected');playlist[1].duration=duration
end
do
 M.clear();local prefs=M.preferences(p);prefs.shuffle=false;prefs.repeatMode='all';local playlist=M.playlist(p)
 check(M.setShuffle(p,true)and M.current(p).shuffle,'shuffle preference is exposed without starting a stream')
 M.play(p,1);local heard={[playlist[1].sound]=true};local sound=M.sound
 for i=2,#playlist do check(M.skip(p,1),'shuffle selects another supplied track');check(not heard[M.theme.sound],'shuffle plays every song once before refilling');heard[M.theme.sound]=true end
 local previous=M.theme;M.skip(p,1);check(M.theme~=previous,'refilling a shuffle bag avoids an immediate repeat')
 local last=M.theme;M.skip(p,-1);check(M.theme==previous,'previous follows actual shuffled playback history');M.skip(p,1);check(M.theme==last,'next returns along existing history')
 sound=M.sound;M.setShuffle(p,false);M.setRepeat(p,'one');check(M.sound==sound,'changing modes does not restart current audio')
 local prior=emitter.playSoundImpl
 emitter.playSoundImpl=function()return 0 end;check(not M.skip(p,1)and M.sound==sound,'failed selection leaves the playing track intact');emitter.playSoundImpl=prior;M.failedUntil=nil
 M.play(p,3);emitter.playing=false;clock=clock+50;M.tick();check(M.theme==playlist[3]and M.current(p).position==0,'repeat one restarts only after the recording ends')
 M.skip(p,1);check(M.theme==playlist[4],'explicit next overrides repeat one')
 M.setRepeat(p,'off');M.play(p,#playlist);emitter.playing=false;clock=clock+50;M.tick();check(not M.sound,'repeat off ends an ordered playlist without wrapping')
 M.setShuffle(p,true);M.setRepeat(p,'off');M.play(p,1);local count=1
 while M.sound and count<=#playlist do emitter.playing=false;clock=clock+50;M.tick();if M.sound then count=count+1 end end
 check(count==#playlist and not M.sound,'repeat off also finishes a complete shuffle bag exactly once')
 M.toggleFavorite(p,playlist[2].sound);check(M.preferences(p).favorites[playlist[2].sound]==true,'favorites use stable sound IDs')
 check(not M.toggleFavorite(p,'unregistered')and not M.setShuffle(p,'yes')and not M.setRepeat(p,'infinite')and not M.setShuffle(nil,true),'invalid settings cannot change playback')
 M.clear();check(M.preferences(p).favorites[playlist[2].sound]and M.preferences(p).shuffle and M.preferences(p).repeatMode=='off','preferences survive playback/world cleanup through character data')
 M.toggleFavorite(p,playlist[2].sound);check(not M.preferences(p).favorites[playlist[2].sound],'favorite toggle removes its stored entry')
 prefs.shuffle=nil;prefs.repeatMode='all';check(not M.shuffled(p,true)and M.shuffled(p,false),'unset defaults preserve sequential manual listening and shuffled combat')
end
return true,'PASS '..checks..' heavy-button Tiger Drop window/cooldown/MP age and independent combat music gain checks'
