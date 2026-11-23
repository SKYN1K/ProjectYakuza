require=function()end
local count=0
local function check(v,message)count=count+1;assert(v,message)end
local function near(a,b)return math.abs(a-b)<.00001 end
local clock,paused=1000,false
getTimestampMs=function()return clock end
isGamePaused=function()return paused end
local tickHook
Events={OnTick={Add=function(fn)tickHook=fn end,Remove=function(fn)if tickHook==fn then tickHook=nil end end},OnGameStart={Add=function()end},OnSave={Add=function()end},OnMainMenuEnter={Add=function()end}}
local calls,volumes,stopped,playing={},{},{},{}
local emitter={setVolume=function(_,id,v)volumes[id]=v end,stopSound=function(_,id)stopped[id]=(stopped[id] or 0)+1;playing[id]=false end,isPlaying=function(_,id)return playing[id]==true end}
local p={localPlayer=true,equipped=true,dead=false}
function p:isLocalPlayer()return self.localPlayer end
function p:isDead()return self.dead end
function p:playSound(name)local id=#calls+1;calls[id]=name;playing[id]=true;return id end
function p:getEmitter()return emitter end
local style={id='test',sounds={heatStart='Charge',heatOnA='Flare',heatOnB='Layer',heatOff='End',punchSwing='Swing'}}
local combo={active=true,multiHitToken={}}
ProjectYakuza={listeners={},HeatActivation={active={}},Heat={config={extremeSpeed=1,maxStocks=6},isExtreme=function()return true end,stocks=function()return 1 end},
 getPlayerStyle=function()return style end,isEquipped=function(who)return who.equipped end,stateFor=function()return combo end,isStyleToken=function()return false end}
function ProjectYakuza.on(name,fn)ProjectYakuza.listeners[name]=ProjectYakuza.listeners[name] or {};table.insert(ProjectYakuza.listeners[name],fn)end
local function emit(name,...)for _,fn in ipairs(ProjectYakuza.listeners[name] or {})do fn(...)end end
do local _="ProjectYakuzaFixture:FEEDBACK" end
local F=ProjectYakuza.Feedback
local function start(extra)
 F.clear();p.equipped=true;p.dead=false;p.localPlayer=true;style.id='test';style.sounds={heatStart='Charge',heatOnA='Flare',heatOnB='Layer',heatOff='End',punchSwing='Swing'}
 if extra then style.sounds.heatStartLayer='Windup';style.sounds.heatIgnition='Ignition';style.sounds.heatSurge='Surge'end
 ProjectYakuza.HeatActivation.active[p]={};clock=clock+10000
 emit('heatActivationStarted',p);return #calls
end
local charge=start();check(calls[charge]=='Charge' and near(volumes[charge],.45),'actual start uses original charge at softer level')
check(tickHook==F.tick,'only an active sound sequence installs tick callback')
local n=#calls;emit('heatActivationStarted',p);check(#calls==n,'duplicate same-action start does not layer charge sounds')
clock=clock+500;emit('heatActivationFlare',p);local flare=#calls
check(calls[flare]=='Flare' and near(volumes[flare],.80),'native flare plays original burst at restrained level')
emit('heatActivationFlare',p);check(#calls==flare,'duplicate flare is ignored')
clock=clock+70;F.tick();check(near(volumes[charge],.225) and not stopped[charge],'charge fades into flare instead of overlapping at full level')
clock=clock+70;F.tick();check(stopped[charge]==1 and volumes[charge]==0,'charge stops once after 140ms fade')
clock=clock+159;F.tick();check(#calls==flare,'second layer waits for original 300ms source delay')
clock=clock+1;F.tick();local layer=#calls
check(calls[layer]=='Layer' and near(volumes[layer],.50),'second original layer is quieter and timed once')
F.tick();check(#calls==layer,'repeated ticks do not replay delayed layer')
emit('heatActivationStopped',p,true)
playing[flare]=false;playing[layer]=false;F.tick()
check(not F.activationSounds[p] and tickHook==nil,'finished native tails release references and idle callback')

charge=start();clock=clock+400;emit('heatActivationFlare',p);flare=#calls
clock=clock+100;emit('heatActivationStopped',p,true)
F.pending[p]={stamp=combo.multiHitToken,sound='Swing',last=clock,due=clock}
F.tick();check(calls[#calls]=='Swing','ordinary swing job remains independent of activation tail')
clock=clock+200;F.tick();check(calls[#calls]=='Layer','completed animation retains delayed activation layer')
check(F.activationSounds[p] and F.activationSounds[p].completed,'native SFX tails remain owned after success')

charge=start();clock=clock+300;emit('heatActivationFlare',p);flare=#calls
paused=true;clock=clock+5000;F.tick();paused=false
check(#calls==flare and volumes[charge]==.45,'pause does not advance delay/fade')
clock=clock+299;F.tick();check(#calls==flare,'unpaused remainder of source delay is retained')
clock=clock+1;F.tick();check(calls[#calls]=='Layer','layer resumes after its unpaused delay')

charge=start();clock=clock+1000;emit('heatActivationStopped',p,true);flare=#calls
check(calls[flare]=='Flare','successful completion provides safe missing-flare fallback')
emit('heatActivationStopped',p,true);emit('heatActivationFlare',p)
check(#calls==flare,'duplicate success/late flare never stacks bursts')
clock=clock+300;F.tick();check(calls[#calls]=='Layer','fallback preserves original second layer')

charge=start();clock=clock+300;emit('heatActivationFlare',p);flare=#calls
emit('heatActivationStopped',p,false);n=#calls;clock=clock+1000;F.tick()
check(#calls==n and stopped[charge] and stopped[flare] and not F.activationSounds[p] and not tickHook,'interruption stops owned sounds and removes delayed jobs')
charge=start();emit('styleChanged',p,'another');check(stopped[charge] and not F.activationSounds[p],'style change clears old style activation')
charge=start();p.dead=true;F.tick();check(stopped[charge] and not tickHook,'death clears active sequence');p.dead=false
charge=start();p.equipped=false;F.tick();check(stopped[charge] and not tickHook,'unequip clears active sequence');p.equipped=true
charge=start();F.clear();check(stopped[charge] and not F.activationSounds[p] and not tickHook,'save/menu cleanup silences tracked tails')
charge=start();emit('heatActivationStopped',p,true);clock=clock+2800;F.tick();check(not F.activationSounds[p] and not tickHook,'tail watchdog bounds tracking even if native handle remains playing')

n=#calls;emit('extremeHeatEnded',p,'depleted');check(#calls==n+1 and calls[#calls]=='End' and near(volumes[#calls],.65),'real mode depletion uses original softer ending')
n=#calls;emit('extremeHeatEnded',p,'death');emit('extremeHeatEnded',p,'style_changed');emit('extremeHeatEnded',p,'unequipped')
check(#calls==n,'lifecycle cleanup does not play misleading mode-ending flourish')
p.localPlayer=false;n=#calls;emit('heatActivationStarted',p);emit('heatActivationFlare',p);emit('heatActivationStopped',p,true)
check(#calls==n and not F.activationSounds[p],'remote observer never duplicates owner SFX');p.localPlayer=true
F.clear();check(tickHook==nil,'idle has no sound tick subscription')
charge=start();playing[99999]=true;emit('heatActivationStopped',p,false)
check(playing[99999] and not stopped[99999],'cleanup preserves unrelated music/voice/emitter handles')
local nativePlay=p.playSound
function p:playSound()return 0 end
start();clock=clock+400;emit('heatActivationFlare',p);clock=clock+300;F.tick();emit('heatActivationStopped',p,true);F.tick()
check(not F.activationSounds[p] and not volumes[0] and not stopped[0],'missing/failed native sound handles never receive fade or stop calls')
p.playSound=nativePlay
start();F.clear();style.sounds=false;n=#calls
emit('heatActivationStarted',p);emit('heatActivationStopped',p,true);F.tick()
check(#calls==n and not F.activationSounds[p] and not tickHook,'styles without heat SFX remain silent and clean up')
local allowed={Charge=true,Flare=true,Layer=true,End=true,Swing=true}
local onlyEffects=true;for _,name in ipairs(calls)do if not allowed[name]then onlyEffects=false end end
check(onlyEffects,'activation routes contain only supplied SFX, never character voice cues')
check(#calls>0,'fixture exercised supplied cue routes without voice playback')

local windup=start(true);charge=windup-1
check(calls[charge]=='Charge'and calls[windup]=='Windup'and near(volumes[windup],.80),'supplied windy whoosh layers clearly with existing Y6 charge')
n=#calls;emit('heatActivationStarted',p);check(#calls==n,'layered activation still starts only once')
clock=clock+500;emit('heatActivationFlare',p);local ignition=#calls;flare=ignition-1
check(calls[flare]=='Flare'and calls[ignition]=='Ignition'and near(volumes[ignition],.45),'native flare adds the supplied Kiwami ignition once')
emit('heatActivationFlare',p);check(#calls==ignition,'duplicate flare cannot stack ignition')
clock=clock+70;F.tick();check(near(volumes[charge],.225)and near(volumes[windup],.80),'charge fades while the windy whoosh retains its audible swell')
clock=clock+70;F.tick();check(stopped[charge]==1 and not stopped[windup]and playing[windup],'flare leaves the full original whoosh playing')
emit('heatActivationStopped',p,true)
clock=clock+160;F.tick();check(calls[#calls]=='Layer','existing Y6 flare layer keeps its 300ms delay')
clock=clock+349;F.tick();check(calls[#calls]=='Layer','surge waits through the end of the activation')
clock=clock+1;F.tick();local surge=#calls;check(calls[surge]=='Surge'and near(volumes[surge],.35),'successful activation retains restrained 650ms Kiwami surge')
F.tick();check(#calls==surge,'surge plays once')
playing[flare]=false;playing[ignition]=false;playing[surge-1]=false;playing[surge]=false;F.tick()
check(F.activationSounds[p]and playing[windup],'completed activation retains ownership of the original whoosh tail')
playing[windup]=false;F.tick()
check(not F.activationSounds[p]and not tickHook,'layered activation releases all completed handles')
windup=start(true);clock=clock+300;emit('heatActivationFlare',p);n=#calls
paused=true;clock=clock+5000;F.tick();paused=false;clock=clock+300;F.tick()
check(calls[#calls]=='Layer'and #calls==n+1,'pause preserves both scheduled layer delays')
clock=clock+350;F.tick();check(calls[#calls]=='Surge','surge resumes after its remaining unpaused delay')
windup=start(true);emit('heatActivationFlare',p);n=#calls;emit('heatActivationStopped',p,false);clock=clock+1000;F.tick()
check(#calls==n and stopped[windup]and not F.activationSounds[p],'interruption cancels all added cues')
start(true);emit('heatActivationFlare',p);n=#calls;clock=clock+1000;F.tick()
check(#calls==n,'late frame drops delayed layers instead of stacking old sounds')
start(true);emit('heatActivationFlare',p);n=#calls;emit('styleChanged',p);clock=clock+650;F.tick()
check(#calls==n and not F.activationSounds[p],'style change cancels delayed Kiwami surge')
start(true);F.clear();n=#calls;clock=clock+650;F.tick();check(#calls==n and not tickHook,'save/menu cleanup cancels every added cue')

F.clear();style.weaponProfile='bat';style.impactFeedback='blunt';style.sounds={heavyImpact='BluntHeavy',groundImpact='BluntGround'}
combo.active=true;combo.finisherMove={duration=1};combo.multiHitToken={};combo.feedbackStamp=nil
local weaponSoundCalls=#calls
F.hit(p,{}, {},1)
check(calls[#calls]=='BluntHeavy'and near(volumes[#calls],.32),'blunt heavy adds restrained supplied accent')
F.hit(p,{}, {},1);check(#calls==weaponSoundCalls+1,'multihit heavy accent plays once per swing')
combo.multiHitToken={};combo.finisherMove=nil;F.hit(p,{}, {},1)
check(#calls==weaponSoundCalls+1,'weapon lights keep native impact without extra punch layer')
combo.groundMove={groundAttack=true};F.hit(p,{}, {},1)
check(calls[#calls]=='BluntGround','grounded weapon hit has explicit profile accent')
style.weaponProfile='blade';style.impactFeedback='blade';style.sounds={heavyImpact='BladeHeavy'}
combo.groundMove=nil;combo.finisherMove={};combo.multiHitToken={};F.hit(p,{}, {},1)
check(calls[#calls]=='BladeHeavy'and near(volumes[#calls],.25),'blade uses quieter separate heavy accent')
n=#calls;combo.multiHitToken={};F.hit(p,{}, {},0);check(#calls==n,'non-damaging weapon hit has no accent')
p.localPlayer=false;F.hit(p,{}, {},1);check(#calls==n,'remote combat events do not duplicate owner accent');p.localPlayer=true
combo.multiHitToken={};combo.active=false;F.hit(p,{}, {},1);check(#calls==n,'inactive weapon state cannot emit accent')
combo.active=true;combo.multiHitToken={};style.sounds=false;F.hit(p,{}, {},1);check(#calls==n,'custom profile can omit all extra accents')


F.clear();style.weaponProfile=nil;style.impactFeedback=nil;style.sounds={heatStart='Charge',heatOnA='Flare',heatOnB='Layer',heatOff='End'}
local oldNative=p.playSound;local direct=0
p.playSound=function()return 0 end
emitter.playSoundImpl=function(_,name,owner)check(owner==p,'direct activation emitter keeps its owner');direct=direct+1;return oldNative(p,name)end
emit('extremeHeatStarted',p)
check(direct==2 and F.activationSounds[p]and F.activationSounds[p].completed,'actual mode entry restores missing activation audio even when character playback returns zero')
local before=#calls;emit('extremeHeatStarted',p);check(#calls==before,'duplicate mode event cannot stack activation cues')
emit('extremeHeatEnded',p,'depleted');check(calls[#calls]=='End'and direct==3,'mode ending uses the same reliable native emitter path')
emitter.playSoundImpl=nil;p.playSound=oldNative;F.clear()
style.sounds={chargeStart='Charge',chargeReady='Ready',chargeRelease='Release'}
ProjectYakuza.activeActions={};local context={kind='heavyCharge'};ProjectYakuza.activeActions[p]=context
emit('heavyChargeStarted',p,style,{},context);local hold=#calls
check(calls[hold]=='Charge'and near(volumes[hold],.55)and F.chargeSounds[p]and tickHook,'actual charged windup starts its supplied cue and tracks ownership')
n=#calls;emit('heavyChargeStarted',p,style,{},context);check(#calls==n,'duplicate charge start cannot stack windups')
emit('heavyChargeReady',p);local ready=#calls;emit('heavyChargeReady',p)
check(calls[ready]=='Ready'and #calls==ready and near(volumes[ready],.45),'full-charge cue plays once at the actual ready event')
emit('heavyChargeStopped',p,true)
check(stopped[hold]and not stopped[ready]and playing[ready]and calls[#calls]=='Release'and not F.chargeSounds[p]and not tickHook,'automatic release stops the windup but lets the full-charge cue ring out with its release accent')
n=#calls;emit('heavyChargeStopped',p,true);check(#calls==n,'duplicate completion cannot replay release')
emit('heavyChargeStarted',p,style,{},context);hold=#calls;n=#calls;emit('heavyChargeStopped',p,false)
check(stopped[hold]and #calls==n and not F.chargeSounds[p],'interrupted charge stops silently without a release accent')
emit('heavyChargeStarted',p,style,{},context);hold=#calls;ProjectYakuza.activeActions[p]=nil;F.tick()
check(stopped[hold]and not F.chargeSounds[p]and not tickHook,'lost action ownership cleans up charging sounds')
ProjectYakuza.activeActions[p]=context;emit('heavyChargeStarted',p,style,{},context);hold=#calls;emit('styleChanged',p)
check(stopped[hold]and not F.chargeSounds[p],'style switch silences the previous charge')
p.localPlayer=false;n=#calls;emit('heavyChargeStarted',p,style,{},context);emit('heavyChargeReady',p);emit('heavyChargeStopped',p,true)
check(#calls==n and not F.chargeSounds[p],'observer events do not duplicate charge audio');p.localPlayer=true
emit('heavyChargeStarted',p,style,{},context);hold=#calls;F.clear()
check(stopped[hold]and not F.chargeSounds[p]and not tickHook,'save/menu cleanup restores silent charging state')
return 'PASS '..count..' activation SFX timing, fade, tails, pause, cleanup and owner-only checks'
