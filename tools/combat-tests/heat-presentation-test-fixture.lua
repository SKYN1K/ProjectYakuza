local C=PY.HeatActionPresentation;local D=PY.HeatPresentationData
local limbDriven,limbStopped,limbSparks=0,0,0
PY.AttackEffects.hit=function()limbSparks=limbSparks+1 end
PY.AttackEffects.paired=function(actor,source,move,clip,time,weight,mask)
 check(actor==p and type(clip)=='string'and type(time)=='number'and weight>=.05,'presentation drives paired limbs with its live phase')
 for i,contact in ipairs(PY.HeatRushRules.contacts(move))do check(not not mask[i]==not not C.allowed({source=source},contact,i),'limb driver shares local and remote confirmed-contact gating')end
 limbDriven=limbDriven+1
end
PY.AttackEffects.endPaired=function(actor,source,complete)check(actor==p and source~=nil,'paired cleanup owns exact heat source');limbStopped=limbStopped+1 end
local builtin=PY.getStyle('dragon_of_dojima')
local sourceMoves={builtin.actions.heatAction,builtin.actions.grabHeat.variants.default,builtin.actions.grabHeat.variants.open,builtin.actions.groundHeat}
for _,profile in ipairs({'bottle','crate','blade','bat','bicycle','knife'})do sourceMoves[#sourceMoves+1]=PY.Weapons.views.dragon_of_dojima[profile].actions.heatAction end
Events.OnPostRender=event()
local activeStyle={id='presentation',sounds={heavyImpact='impact',punchImpact='punch',kickImpact='kick',throwImpact='fall'}}
PY.getPlayerStyle=function()return activeStyle end;PY.getStyle=function()return activeStyle end
PY.isEquipped=function(a)return a.equipped~=false end
local plays,fx,emitted={},{},0
local file;for name in pairs(D.leads)do file=name;break end
local lead=D.leads[file]
GameSounds={getSound=function(name)return {getRandomClip=function()return {name=name,getFile=function()return file end}end}end}
getWorld=function()return {getFreeEmitter=function(_,x,y,z)
 local emitter={x=x,y=y,z=z}
 function emitter:playClip(clip,a)local id=#plays+1;plays[id]={time=phase*1000,name=clip.name,actor=a,emitter=self};return id end
 function emitter:setVolume(id,gain)plays[id].gain=gain end
 function emitter:isPlaying(id)return not plays[id].stopped end
 function emitter:stopSound(id)plays[id].stopped=true end
 return emitter
end}end
PY.AttackEffects.project=function(x,y,z,angle,tile)return 0,0,x*math.cos(angle)-z*math.sin(angle),x*math.sin(angle)+z*math.cos(angle),y end
PY.BloodEffects={spawn=function(a,v,strong,charged,feedback,anchor)fx[#fx+1]={time=phase*1000,anchor=anchor,feedback=feedback,blood=true}end}
PY.HitEffects.spawn=function(a,v,strong,charged,ground,feedback,anchor)fx[#fx+1]={time=phase*1000,anchor=anchor,feedback=feedback}end
PY.emit=function(name)if name=='heatRushHit'then emitted=emitted+1 end end
function p:getAnimAngleRadians()return self.angle or 0 end
p.dead=false;p.equipped=true;z.dead=false;paused=false;weight=1
local function step(ms)phase=(ms+.00001)/1000;clock=clock+16;C.tick()end
local total,effectTotal=0,0;local move,source
for animation,data in pairs(D.moves)do
 move={animation=animation,contacts={},audioEvents={}}
 for i,meta in ipairs(data.contacts)do move.contacts[meta.index]={atMs=meta.atMs,cue=meta.cue,layers={'heavyImpact'}}end
 C.clearAll();plays={};fx={};source={};phase=0;C.start(p,z,move,source);C.tick()
 local times={};for _,effect in ipairs(data.effects)do times[effect.atMs]=true end
 local sorted={};for at in pairs(times)do sorted[#sorted+1]=at end;table.sort(sorted)
 for _,at in ipairs(sorted)do
  local expected=0;for _,effect in ipairs(data.effects)do if effect.atMs==at then expected=expected+1 end end
  local before=#fx;step(at);check(#fx==before+expected,'all source emitters start at their own frame '..animation)
  for i=before+1,#fx do check(fx[i].anchor~=nil and (fx[i].blood==true or animation=='ProjectYakuza_DD_GroundHeat'),'emitter uses existing supplied effects and sampled bone attachment')end
  step(at);check(#fx==before+expected,'source emitters cannot duplicate on repeated render')
 end
 check(#fx==#data.effects and #plays==0,'source effect count is exact and generic sounds are suppressed')
 effectTotal=effectTotal+#fx
 for _,meta in ipairs(data.contacts)do
  C.clearAll();plays={};fx={};source={};phase=0;C.start(p,z,move,source);C.tick()
  C.start(p,z,move,source);check(C.states[p].source==source,'MP snapshots preserve presentation session')
  local at=meta.atMs
  local before=emitted;local previous=limbSparks;local impact=false;for _,effect in ipairs(data.effects)do if effect.index==meta.index and effect.impact then impact=true end end
  step(at);check(emitted==before+1,'canonical contact emits once independently of source particles')
  check(limbSparks==previous+(impact and 0 or 1),'source-only blood scenes also emit one coloured limb-spark burst per contact')
  local count=#fx;local sparks=limbSparks;step(at+1);check(#fx==count and limbSparks==sparks,'contact and limb sparks cannot duplicate on next render')
  H.present(p,z,move,meta.index,true);check(#fx==count,'damage/network echo cannot replay presentation')
  total=total+1
 end
end
check(total==38 and effectTotal==130,'all main and failure-ending contacts, 129 source blood emitters and one stomp impact covered')
C.clearAll();move={animation='Custom',contacts={{atMs=500,cue='punchImpact',layers={'kickImpact'}}}};source={};plays={};fx={};phase=0;C.start(p,z,move,source);step(500-lead)
check(#plays==2 and plays[1].gain==.55 and plays[2].gain==.3,'custom styles retain primary and layered sound gains')
step(500);check(#fx==1 and fx[1].anchor==nil,'custom action without numeric sample retains legacy placement')
local count=#plays;paused=true;step(600);check(#plays==count,'pause cannot emit sound');paused=false
C.stop(p,{});check(C.states[p]~=nil,'stale remote cleanup cannot end active action')
C.stop(p,source);check(not C.states[p]and plays[1].stopped and plays[2].stopped,'interruption stops session sounds and drops hooks')
phase=0;plays={};fx={};source={};C.start(p,z,move,source);step(850)
check(#plays==0 and #fx==0,'late render drops stale impacts instead of catch-up bursts')
C.stop(p,source,true)
phase=0;source={};C.start(p,z,move,source);step(400);clock=clock+2000;step(401);weight=0;clock=clock+100;C.tick()
check(C.states[p]~=nil,'missing-track grace starts from last observed track');weight=1
p.equipped=false;C.tick();check(not C.states[p],'unequip cleans controller');p.equipped=true
phase=0;source={};C.start(p,z,move,source);source.cleaned=true;C.tick();check(not C.states[p],'action cleanup cancels presentation')
for i=0,7 do p.angle=i*math.pi/4;local a=C.anchor(p,z,{.2,.7,-.3});check(a.modelAnchor==true,'source bone anchors explicitly select the character-camera correction');check(math.abs(a.z-z:getZ()-.7)<.00001,'native height remains constant in all rotations');check(math.abs((a.x-z:getX())^2+(a.y-z:getY())^2-.13)<.00001,'world anchor rotates around victim')end
p.angle=0;C.clearAll();check(not C.hooked,'no idle render hook remains')
move={animation='Custom',contacts={{atMs=500,cue='punchImpact',qteIndex=1}}};source={qte={accepted={}}};phase=0;plays={};fx={};C.start(p,z,move,source);step(500)
check(#plays==0 and #fx==0,'unaccepted custom QTE contact cannot present')
C.clearAll();source.qte.accepted[1]=true;phase=0;C.start(p,z,move,source);step(500-lead);step(500)
check(#plays==1 and #fx==1,'accepted custom QTE keeps its authored contact')
C.clearAll();local ending;for name in pairs(D.moves)do if name:find('Fail')then ending=name;break end end
check(ending~=nil,'original paired failure data present')
move={animation='Custom',contacts={{atMs=500,cue='kickImpact'}},qteFailure={paired=true,animation=ending,contactMs=D.moves[ending].contacts[1].atMs}};source={failed=true};phase=0;plays={};fx={};C.start(p,z,move,source);step(0)
check(C.states[p].clip==ending,'paired failure switches to its own animation clock')
C.clearAll();move={animation='Custom',contacts={{atMs=500,cue='punchImpact'}}};source={};phase=0;plays={};fx={}
local localMethod=p.isLocalPlayer;p.isLocalPlayer=function()return false end;C.start(p,z,move,source);step(500-lead);step(500)
check(#plays==1 and #fx==1,'observer reconstructs presentation without owner-only sound packets');p.isLocalPlayer=localMethod
C.stop(p,source,true);check(not plays[1].stopped,'natural completion preserves current impact tail')
C.clearAll();plays={};fx={};phase=-1
p.isLocalPlayer=function()return false end
move={animation='RemoteCustom',contacts={{atMs=500,cue='punchImpact',qteIndex=1}}}
source={remote=true,age=.3,at=clock,confirmedContacts={}}
C.start(p,z,move,source);C.tick();clock=clock+250;C.tick()
check(#fx==0 and #plays==0,'observer cannot present a QTE contact without server confirmation')
source.confirmedContacts[1]=true;clock=clock+100;C.tick()
check(#fx==1 and #plays==1,'observer reconstructs source time from pose age even when its native animation phase is unavailable')
C.tick();check(#fx==1 and #plays==1,'confirmed remote contact is replay safe')
source.age=.1;source.at=clock;C.tick()
check(C.states[p]~=nil and #fx==1,'jittered observer clock cannot reset and duplicate presentation')
C.clearAll();plays={};fx={};phase=-1
source={remote=true,age=.9,at=clock,confirmedContacts={[1]=true}}
C.start(p,z,move,source);C.tick();check(#fx==0 and #plays==0,'observer suppresses stale contact effects beyond its bounded network grace')
C.clearAll();p.isLocalPlayer=localMethod
local katana=PY.Weapons.views.dragon_of_dojima.blade.actions.heatAction
check(#katana.contacts==3 and katana.contacts[4]==nil,'katana has exactly three damaging contacts')
for i=1,3 do check(katana.contacts[i].damageMultiplier==({.375,.375,.75})[i],'katana uses original 1:1:2 damage weighting with unchanged total')end
check(#D.moves[katana.animation].contacts==3,'katana numeric timeline contains only three presented contacts')
check(D.moves[katana.animation].contacts[1].bone=='Bip01_Spine1'and D.moves[katana.animation].contacts[2].bone=='Bip01_Head'and D.moves[katana.animation].contacts[3].bone=='Bip01_Spine','katana effects follow original chest, face and lower-torso particle bones contacts')
plays={};fx={};local eventCount=emitted;H.present(p,z,katana,4,true,true,{x=0,y=0,z=1})
check(#plays==0 and #fx==0 and emitted==eventCount,'removed fourth katana contact cannot present sounds, effects or voices')
C.clearAll();plays={};fx={};local voices={};PY.CombatVoices={contact=function(a,entry)voices[#voices+1]={at=phase*1000,entry=entry}end}
for _,key in ipairs({'heatKatanaSwing','heatKatanaSlash','heatKatanaPunch','heatKatanaThrust','heatKatanaBodyFall'})do activeStyle.sounds[key]=key end
phase=0;source={};C.start(p,z,katana,source);step(0)
local events={};for _,event in ipairs(katana.audioEvents)do events[#events+1]={at=event.atMs,audio=true}end
for _,event in ipairs(katana.voiceEvents)do events[#events+1]={at=event.atMs}end
for _,event in ipairs(katana.contacts)do events[#events+1]={at=event.atMs}end
for _,event in ipairs(D.moves[katana.animation].effects)do events[#events+1]={at=event.atMs}end
table.sort(events,function(a,b)return a.at<b.at end)
local seen={};for _,event in ipairs(events)do if not seen[event.at]then seen[event.at]=true;step(math.max(0,event.at-1));local before=#plays;step(event.at);step(event.at);local expected=0;for _,audio in ipairs(katana.audioEvents)do if audio.atMs==event.at then expected=expected+1 end end;check(#plays==before+expected,'source cues fire exactly at authored starts once, without generic preroll')end end
check(#plays==5 and #fx==16 and #voices==2,'five original cues, sixteen source emitters and two original voice events remain independent')
for i,effect in ipairs(fx)do check(effect.blood==true and math.abs(effect.time-D.moves[katana.animation].effects[i].atMs)<.001,'katana blood follows original emitter frames without generic sparks')end
check(voices[1].entry=='CombatHeavyAttack'and voices[2].entry=='CombatSpecialMove','original source voice roles use existing CVF combat entries')
C.clearAll()
local style=PY.Weapons.views.dragon_of_dojima.blade;local audio,voice=katana.audioEvents,katana.voiceEvents
check(PY.validateStyle(style),'authored source sound and voice event arrays validate')
for _,bad in ipairs({{atMs=-1,cue='punchImpact'},{atMs=1,cue='punchImpact',gain=2},{atMs=1,cue='punchImpact',target='other'},{atMs=katana.duration*1000+1,cue='punchImpact'}})do katana.audioEvents={bad};check(not PY.validateStyle(style),'invalid authored audio event rejected')end
katana.audioEvents=audio;katana.voiceEvents={{atMs=1,entry='UnrelatedVoice'}};check(not PY.validateStyle(style),'authored voice must use Combat prefix')
katana.voiceEvents=voice
for key,value in pairs(PY.HeatSceneData.sounds)do activeStyle.sounds[key]=value end
local function runSource(action,failed)
 local definition=failed and action.qteFailure or action
 local animation=definition.animation;local samples=D.moves[animation]
 C.clearAll();plays={};fx={};voices={};source={failed=failed};phase=0;C.start(p,z,action,source)
 local at={};for _,event in ipairs(definition.audioEvents)do at[event.atMs]=true end
 for _,event in ipairs(definition.voiceEvents)do at[event.atMs]=true end
 for _,event in ipairs(samples.effects)do at[event.atMs]=true end
 for _,event in ipairs(samples.contacts)do at[event.atMs]=true end
 local ordered={};for time in pairs(at)do ordered[#ordered+1]=time end;table.sort(ordered)
 for _,time in ipairs(ordered)do step(time);local a,b,c=#plays,#fx,#voices;step(time);check(#plays==a and #fx==b and #voices==c,'source event cannot duplicate '..animation)end
 check(#plays==#definition.audioEvents and #voices==#definition.voiceEvents and #fx==#samples.effects,'complete original scene audio, voice and effect timeline '..animation)
 for i,event in ipairs(definition.audioEvents)do check(math.abs(plays[i].time-event.atMs)<.001,'each original sound uses its source start '..animation)end
 for i,event in ipairs(definition.voiceEvents)do check(voices[i].entry==event.entry and math.abs(voices[i].at-event.atMs)<.001,'actor voice source starts remain independent '..animation)end
 C.clearAll();plays={};fx={};voices={};source={failed=failed};phase=0;C.start(p,z,action,source);step(definition.duration*1000+200)
 check(#plays==0 and #fx==0 and #voices==0,'late scene cannot burst old sounds, emitters or voices '..animation)
end
for _,action in ipairs(sourceMoves)do
 runSource(action,false)
 if action.qteFailure and action.qteFailure.paired then
  runSource(action,true)
  C.clearAll();plays={};fx={};voices={};source={};phase=0;C.start(p,z,action,source);step(500)
  local first=#plays;source.failed=true;phase=0;step(0)
  check(C.states[p].clip==action.qteFailure.animation and #plays>=first,'failure switches event clocks without a rewind cancellation')
  local failure=action.qteFailure;local old=failure.audioEvents;failure.audioEvents={{atMs=failure.duration*1000+1,cue='punchImpact'}}
  local owner=action==builtin.actions.heatAction and builtin or PY.Weapons.views.dragon_of_dojima.crate
  check(not PY.validateStyle(owner),'invalid failure-ending source event rejected');failure.audioEvents=old;check(PY.validateStyle(owner),'restored source ending validates')
 end
end
local stomp=builtin.actions.groundHeat;local se=stomp.audioEvents[1]
check(se.atMs==875 and se.atMs+se.attackLeadMs==stomp.contacts[1].atMs,'stomp PCM transient aligns with native frame-30 contact')
for _,remote in ipairs({false,true})do
 C.clearAll();plays={};fx={};phase=0;source={remote=remote,age=0,at=clock};local before=emitted
 C.start(p,z,stomp,source)
 local function advance(ms)
  phase=ms/1000;clock=clock+16;source.age=phase;source.at=clock;C.tick()
 end
 advance(0);advance(874);check(#plays==0 and #fx==0,'stomp has no opening impact on owner or observer')
 advance(875);check(#plays==1 and #fx==0,'stomp starts unchanged original PCM 125ms before foot contact')
 advance(999);check(#plays==1 and #fx==0,'stomp does not show impact before landing')
 advance(1000);check(#fx==1 and not fx[1].blood and fx[1].anchor~=nil and emitted==before+1,'landing shows one anchored existing impact on owner and observer')
 advance(1000);advance(1016);check(#fx==1 and #plays==1 and emitted==before+1,'stomp landing cannot duplicate')
 C.clearAll();plays={};fx={};source={remote=remote,age=0,at=clock};phase=0;C.start(p,z,stomp,source)
 advance(0);paused=true;advance(1000);check(#plays==0 and #fx==0,'pause suppresses stomp cues');paused=false
 C.stop(p,source);advance(1000);check(#plays==0 and #fx==0,'interruption cancels stomp sound and impact')
end
C.clearAll()
check(limbDriven>100 and limbStopped>10,'all paired scene lifecycle paths drive and stop limbs')
return true,'PASS '..checks..' paired Heat Action timing, 38 native contacts, 129 source blood emitters and one stomp contact effect, independent cues and voices, replay suppression and lifecycle checks'
