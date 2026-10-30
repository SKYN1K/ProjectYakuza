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
local start=clock;clock=start+300;check(P.validTarget(p,z),'0.3-second window includes its boundary')
clock=start+301;z.vars.ProjectYakuzaTigerWindow='true';check(not P.validTarget(p,z),'legacy marker cannot extend window beyond 0.3 seconds')
z.attacking=false;clock=clock+60;P.track(p,true)
check(not P.tracked[z].startedAt,'idle clears observed attack clock')
z.attacking=true;clock=clock+60;P.track(p,true);z.damaged=true
check(not P.validTarget(p,z),'attack that already damaged player cannot be countered')
z.damaged=false;z.vars.ZombieBiteDone='true';check(not P.validTarget(p,z),'completed bite cannot be countered')
z.vars.ZombieBiteDone='false';z.x=-.7;check(not P.validTarget(p,z),'counter requires frontal target')
z.x=.7;z.outcome='fail';check(not P.validTarget(p,z),'failed attack cannot open counter')
z.outcome='start';z.attacking=false;P.track(p,true);clock=clock+60;z.attacking=true;P.track(p,true)
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
check(P.remaining(p)==60000 and not P.tryCounter(p),'existing one-minute cooldown retained')
PY.cancelAction(p,'test');PY.ChargedHeavy=nil;PY.Bindings.options=nil;mouse[2]=false
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
function emitter:stopSoundLocal()self.playing=false end
function emitter:setPlayRemoteEvents()end;function emitter:set3D()end;function emitter:tick()end
function emitter:setVolume(_,v)self.volume=v end
function emitter:isPlaying()return self.playing end
FMODSoundEmitter={new=function()return emitter end}
ZombRand=function()return 0 end
do local _="ProjectYakuzaFixture:MUSIC" end
local M=PY.CombatMusic;local theme=PY.getStyle('dragon_of_dojima').music[1]
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
return true,'PASS '..checks..' heavy-button Tiger Drop window/cooldown/MP age and independent combat music gain checks'
