local tests=0
local function check(ok,msg)tests=tests+1;if not ok then error(msg)end end
require=function()end
local function event()local e={callbacks={}};e.Add=function(fn)e.callbacks[#e.callbacks+1]=fn end;e.Remove=function()end;return e end
Events={OnGameBoot=event(),OnGameStart=event(),OnPlayerUpdate=event(),OnPlayerGetDamage=event(),OnMainMenuEnter=event(),OnSave=event(),OnTick=event()}
LuaEventManager={AddEvent=function()end};triggerEvent=function()end
local clock=10000;local paused,policy=false,true
getTimestampMs=function()return clock end;isGamePaused=function()return paused end
local sounds={}
getScriptManager=function()return {getGameSound=function(_,name)return sounds[name]end}end
local p={data={ProjectYakuzaStyle='dragon_of_dojima',CVF_voice='TestVoice'},prefix='SelectedVoice',combo={active=false,step=1},localPlayer=true,aim=false,calls={}}
function p:isLocalPlayer()return self.localPlayer end;function p:isDead()return self.dead==true end
function p:isAsleep()return self.asleep==true end;function p:getVehicle()return self.vehicle end
function p:getModData()return self.data end
function p:getPrimaryHandItem()return self.equipped~=false and(self.held or {getFullType=function()return 'ProjectYakuza.StyleToken' end})or nil end
function p:getDescriptor()return {getVoicePrefix=function()return self.prefix end}end
function p:getEmitter()return {setVolume=function(self,handle,volume)p.voiceMix=volume end,isPlaying=function()return self.voiceBusy==true end}end
function p:transmitPlayerVoiceSound(suffix)self.calls[#self.calls+1]={prefix=self.prefix,suffix=suffix};return self.refuse and 0 or #self.calls end
function p:isAiming()return self.aim end;function p:isKnockedDown()return self.knocked==true end
function p:getHitReaction()return self.reaction or ''end
function p:getCurrentStateName()return self.nativeState or 'IdleState'end
instanceof=function(obj,kind)return kind=='IsoPlayer' and obj==p end
sendClientCommand=function()error('CVF voices must not be sent through ProjectYakuza RPC')end
sendServerCommand=sendClientCommand
do local _="ProjectYakuzaFixture:CVF_PROJECT" end
local ProjectYakuza=ProjectYakuza;local V=ProjectYakuza.CombatVoices;local C=ProjectYakuza.CombatVoiceLines
ProjectYakuza.stateFor=function(who)return who.combo end
ProjectYakuza.isBusy=function(who)return who.busy==true or who.combo.active==true end
check(not V.ready(),'framework absent is optional')
check(not V.play(p,'CombatLightAttack') and #p.calls==0,'missing CVF has no audio or combat side effects')
V.update(p)
do local _="ProjectYakuzaFixture:CVF_UPSTREAM" end
CVF_Client={isVoiceAllowed=function()return policy end}
check(V.ready(),'late-loaded actual CVF 1.1 API detected')
check(#CustomVoice.getLines()==8,'all eight reserved entries registered')
for _,d in ipairs(C.definitions)do
 local line=CustomVoice.getLine(C.modId,d.id)
 check(line and line.id:sub(1,6)=='Combat' and line.modId==C.modId and line.wheel==false and line.cooldown==d.cooldown,'namespaced reserved metadata matches canonical definition')
end
C.register();check(#CustomVoice.getLines()==8,'registration is idempotent')
check(not V.play(p,'CombatLightAttack') and #p.calls==0,'missing recordings remain silent')
check(not V.hasRecording(p,'CombatTaunt'),'taunt menu stays hidden without audio')
local function supply(prefix)
 for _,d in ipairs(C.definitions)do sounds[prefix..CustomVoice.getLineSuffix(C.modId,d.id)]=true end
end
supply(p.prefix)
check(V.hasRecording(p,'CombatTaunt'),'taunt available only for current prefix recording')
local function suffix(id)return CustomVoice.getLineSuffix(C.modId,id)end
local function last(id)return p.calls[#p.calls] and p.calls[#p.calls].suffix==suffix(id)end
local serial=0
local function attack(event)
 clock=clock+6000;serial=serial+1;p.combo={active=true,step=1,multiHitToken=serial};ProjectYakuza.emit(event,p)
 clock=clock+25;V.update(p)
end
attack('lightAttackStarted');check(last('CombatLightAttack'),'actual light swing uses light entry');check(p.voiceMix==nil or p.voiceMix==1,'Dragon voice has no style loudness override')
attack('finisherStarted');check(last('CombatHeavyAttack'),'finisher uses heavy entry')
clock=clock+6000;serial=serial+1;p.combo={active=true,step=1,multiHitToken=serial};local before=#p.calls
ProjectYakuza.emit('lightAttackStarted',p);p.combo.groundMove={groundAttack=true};ProjectYakuza.emit('groundAttackStarted',p);clock=clock+25;V.update(p)
check(#p.calls==before+1 and last('CombatHeavyAttack'),'ground correction chooses heavy exactly once')
attack('runningAttackStarted');check(last('CombatSpecialMove'),'running attacks use special entry')
attack('quickstepAttackStarted');check(last('CombatSpecialMove'),'quickstep attacks use special entry')
clock=clock+6000;local rushBefore=#p.calls
ProjectYakuza.emit('actionStarted',{kind='heatAction',player=p,action={heatRush=true}})
check(#p.calls==rushBefore,'rush entrance does not consume the generic special-move voice')
ProjectYakuza.emit('heatRushHit',p,nil,1,{voice='CombatLightAttack'});check(last('CombatLightAttack'),'source-timed rush punches use the attack voice pool')
clock=clock+6000;ProjectYakuza.emit('heatRushHit',p,nil,7,{voice='CombatHeavyAttack'});check(last('CombatHeavyAttack'),'finishing kick uses the heavy attack voice pool')

for _,kind in ipairs({'parry','grab','heatAction'})do clock=clock+6000;ProjectYakuza.emit('actionStarted',{player=p,kind=kind});check(last('CombatSpecialMove'),kind..' accepted action uses special entry')end
clock=clock+6000;local stepBefore=#p.calls;ProjectYakuza.emit('actionStarted',{player=p,kind='quickstep'});check(#p.calls==stepBefore,'Dragon quicksteps have no voice cue')
clock=clock+6000;ProjectYakuza.emit('throwStarted',p);check(last('CombatSpecialMove'),'throw start uses special entry')
before=#p.calls;ProjectYakuza.emit('throwHit',p);ProjectYakuza.emit('tigerDrop',p);ProjectYakuza.emit('tigerDrop',p)
check(#p.calls==before,'per-victim throw/counter effects never duplicate voices')
clock=clock+6000;ProjectYakuza.emit('heatActivationStarted',p);check(last('CombatExtremeHeatActivation'),'actual activation start uses heat entry')
before=#p.calls;ProjectYakuza.emit('extremeHeatStarted',p);ProjectYakuza.emit('heatChanged',p)
check(#p.calls==before,'heat state notifications do not replay activation voice')
clock=clock+6000;p.combo.active=false;check(V.taunt(p) and last('CombatTaunt'),'voice-only menu taunt uses reserved entry')
clock=clock+6000;ProjectYakuza.emit('tauntStarted',p);check(last('CombatTaunt'),'future accepted taunt event is supported')
V.clear();p.aim=false;before=#p.calls;V.update(p);clock=clock+6000;p.aim=true;V.update(p)
check(#p.calls==before,'RMB stance entry no longer plays a voice')
clock=clock+6000;ProjectYakuza.emit('styleEntryStarted',p)
check(#p.calls==before+1 and last('CombatStanceEntry'),'actual style selection animation uses the existing stance line')
before=#p.calls;V.update(p);V.update(p);p.aim=false;V.update(p);clock=clock+6000;p.aim=true;V.update(p)
check(#p.calls==before,'raising RMB again cannot repeat the selection voice')
clock=clock+6000;V.onDamage(p,'WEAPONHIT',.4);check(last('CombatGettingHit'),'confirmed acute damage uses hit entry')
before=#p.calls;for _,kind in ipairs({'BLEEDING','THIRST','HUNGRY','SICKNESS','POISON'})do V.onDamage(p,kind,1)end
V.onDamage({},'WEAPONHIT',1);V.onDamage(p,'WEAPONHIT',0)
check(#p.calls==before,'passive/zero damage and non-player victims are ignored')
clock=clock+6000;p.knocked=true;V.update(p);check(last('CombatGettingStunned'),'knockdown entry uses stun entry')
before=#p.calls;V.update(p);V.update(p);check(#p.calls==before,'held stun does not repeat')
p.knocked=false;clock=clock+100;V.update(p);clock=clock+6000;p.nativeState='StaggerBackState';V.update(p)
check(last('CombatGettingStunned'),'native stagger reaction uses stun entry')
p.reaction='';p.nativeState='IdleState';clock=clock+100;V.update(p);clock=clock+6000;ProjectYakuza.emit('guardBroken',p)
check(last('CombatGettingStunned'),'guard break uses stun entry')
clock=clock+6000;p.localPlayer=false;before=#p.calls;check(not V.play(p,'CombatLightAttack'),'remote requests rejected');V.update(p);p.localPlayer=true
check(#p.calls==before,'observers never relay/replay local-player voice')
paused=true;check(not V.play(p,'CombatLightAttack'),'actual CVF pause guard respected');paused=false
policy=false;check(not V.play(p,'CombatLightAttack'),'actual CVF server policy respected');policy=true
p.voiceBusy=true;check(not V.play(p,'CombatLightAttack'),'actual CVF voice-busy guard respected');p.voiceBusy=false
clock=clock+6000;check(V.play(p,'CombatLightAttack'),'voice can play after guards clear');before=#p.calls
check(not V.play(p,'CombatHeavyAttack') and #p.calls==before,'actual CVF global cooldown prevents overlap')
p.prefix='AnotherSelectedCharacter';check(not V.play(p,'CombatLightAttack'),'missing alternate-prefix recording has no Kiryu fallback')
supply(p.prefix);clock=clock+6000;check(V.play(p,'CombatHeavyAttack') and p.calls[#p.calls].prefix==p.prefix,'selected character voice prefix is resolved at playback')
clock=clock+6000;serial=serial+1;p.combo={active=true,step=1,multiHitToken=serial};before=#p.calls
ProjectYakuza.emit('lightAttackStarted',p);ProjectYakuza.emit('comboCancelled',p);clock=clock+25;V.update(p)
check(#p.calls==before,'cancelled attacks discard pending voice')
clock=clock+6000;ProjectYakuza.emit('lightAttackStarted',p);p.combo.multiHitToken=serial+1;clock=clock+25;V.update(p)
check(#p.calls==before,'stale attack tokens cannot play later')
local original=CustomVoice.playLine;CustomVoice.playLine=nil
check(not V.play(p,'CombatLightAttack'),'incompatible playback API disables adapter');CustomVoice.playLine=original
ProjectYakuza.registerStyle({id='voice.optout',name='Opt-out',combatVoices=false,lightAttacks={{animation='Native',nodeValue='optout',duration=1}}})
p.data.ProjectYakuzaStyle='voice.optout';check(not V.play(p,'CombatLightAttack'),'style can opt out of CVF combat voices');p.data.ProjectYakuzaStyle='dragon_of_dojima'
check(not V.play(p,'NotReserved'),'unregistered IDs cannot be played through combat adapter')
local native=CustomVoice
CustomVoice={getLine=native.getLine,getLineSuffix=native.getLineSuffix,log=native.log,playLine=native.playLine,registerLine=function(def)if def.id=='CombatTaunt' then return false,'conflict' end;return native.registerLine(def)end}
check(V.ready() and not C.accepted.CombatTaunt and C.accepted.CombatLightAttack,'one registration conflict does not disable other entries')
CustomVoice=native;C.register();check(C.accepted.CombatTaunt,'compatible provider registration can recover')
p.data.ProjectYakuzaStyle='dragon_of_dojima';p.combo.active=false;p.voiceBusy=false;p.nativeState='IdleState';p.knocked=false
local level=0;ProjectYakuza.SoundSettings={voiceLevel=function()return level end}
clock=clock+6000;before=#p.calls;check(not V.play(p,'CombatLightAttack') and #p.calls==before,'Voices zero prevents combat-only playback')
level=.5;check(V.play(p,'CombatLightAttack') and p.voiceMix==.5,'Voices slider controls unboosted combat lines without altering general voice')
level=1;clock=clock+6000;p.voiceBusy=true
local activation={};ProjectYakuza.HeatActivation={active={[p]=activation}}
ProjectYakuza.emit('heatActivationStarted',p);check(V.states[p].activation~=nil,'busy provider defers activation voice briefly')
clock=clock+125;p.voiceBusy=false;before=#p.calls;V.update(p)
check(#p.calls==before+1 and last('CombatExtremeHeatActivation') and not V.states[p].activation,'activation retries once when provider clears')
clock=clock+125;V.update(p);check(#p.calls==before+1,'activation line does not repeat')
clock=clock+6000;p.voiceBusy=true;ProjectYakuza.emit('heatActivationStarted',p);ProjectYakuza.emit('heatActivationStopped',p,false)
p.voiceBusy=false;clock=clock+125;before=#p.calls;V.update(p);check(#p.calls==before,'cancelled activation cannot play a late voice')
local nativeSounds={}
function p:playSound(name)nativeSounds[#nativeSounds+1]=name;return 2000+#nativeSounds end
ZombRand=function()return 0 end;isClient=function()return false end
do local _="ProjectYakuzaFixture:HEAT_FEEDBACK" end
local H=ProjectYakuza.HeatRush
for _,case in ipairs({{item='ProjectYakuza.IntactBeerBottle',profile='bottle'},{item='Base.Katana',profile='blade'}})do
 p.held={getFullType=function()return case.item end,getCondition=function()return 10 end}
 local view=ProjectYakuza.getPlayerStyle(p);local move=view.actions.heatAction;check(view.weaponProfile==case.profile,'actual weapon view resolves Heat Action sounds '..case.profile)
 local context={player=p,kind='heatAction',action=move};ProjectYakuza.activeActions={[p]=context};clock=clock+6000;p.voiceBusy=false
 before=#p.calls;ProjectYakuza.emit('actionStarted',context);check(#p.calls==before,'weapon Heat Action entrance leaves the voice channel for attack contacts')
 local started=clock
 for i,contact in ipairs(move.contacts)do
  clock=started+contact.atMs;local audio=#nativeSounds;before=#p.calls;H.present(p,nil,move,i,false)
  check(#nativeSounds==audio+1 and nativeSounds[#nativeSounds]==view.sounds[contact.cue],'actual Heat Action resolver plays registered impact '..case.profile..i)
  check(contact.voice and #p.calls==before+1 and last(contact.voice)or not contact.voice and #p.calls==before,'actual CVF playback receives the configured source contact voice '..case.profile..i)
 end
end
do local _="ProjectYakuzaFixture:SCENE_VOICES" end
local context=ProjectYakuza.activeActions[p];context.action=ProjectYakuza.Weapons.views.dragon_of_dojima.bottle.actions.heatAction;clock=clock+6000;p.voiceBusy=true;before=#p.calls
local sourceVoice=context.action.voiceEvents[1]
local function sceneContact()ProjectYakuza.HeatSceneVoiceProbe.authoredEvents(p,{move={voiceEvents={sourceVoice}},voices={},authored={}},sourceVoice.atMs)end
sceneContact()
check(#p.calls==before and V.states[p].contact~=nil,'busy actual provider queues Heat Action contact voice')
clock=clock+300;p.voiceBusy=false;V.update(p)
check(#p.calls==before+1 and last(sourceVoice.entry)and not V.states[p].contact,'source-timed voice retries after the actual provider clears')
clock=clock+100;V.update(p);check(#p.calls==before+1,'successful contact retry plays only once')
clock=clock+6000;p.voiceBusy=true;sceneContact();ProjectYakuza.emit('actionCancelled',context)
clock=clock+300;p.voiceBusy=false;before=#p.calls;V.update(p);check(#p.calls==before and not V.states[p].contact,'cancelled paired action discards pending contact voice')
clock=clock+6000;p.voiceBusy=true;sceneContact();clock=clock+700;p.voiceBusy=false;before=#p.calls;V.update(p)
check(#p.calls==before and not V.states[p].contact,'expired contact voice cannot speak long after its hit')
clock=clock+6000;p.voiceBusy=true;sceneContact();ProjectYakuza.activeActions[p]={player=p,kind='heatAction'};clock=clock+300;p.voiceBusy=false;before=#p.calls;V.update(p)
check(#p.calls==before and not V.states[p].contact,'replaced action cannot consume an old contact voice')
p.held=nil;ProjectYakuza.activeActions[p]=nil
return 'PASS '..tests..' checks against actual CVF registry/playback, Heat Action sound resolution and combat adapter'
