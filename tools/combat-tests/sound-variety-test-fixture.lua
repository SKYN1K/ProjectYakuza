local client=false;isClient=function()return client end
local seed=71;ZombRand=function(n)seed=(seed*48271)%2147483647;return seed%n end
do local _="ProjectYakuzaFixture:VARIETY" end
do local _="ProjectYakuzaFixture:FEEDBACK" end
local V=ProjectYakuza.SoundVariety;local F=ProjectYakuza.Feedback
style.id='dragon_of_dojima';style.soundVariety=true;style.sounds={}
for cue in pairs(V.pools)do style.sounds[cue]=cue end
for cue,size in pairs(V.pools)do
 local previous
 for cycle=1,20 do
  local seen={}
  for j=1,size do
   local index=V.next(p,style,cue)
   check(index>=1 and index<=size and not seen[index],'every supplied clip selected once per bag')
   check(index~=previous,'no immediate repeat, including bag boundaries');seen[index]=true;previous=index
  end
 end
end
check(not V.allowed(style,'UnrelatedMusic',1)and not V.allowed(style,'ProjectYakuza_Y6_PunchSwing',0),'unconfigured cue/invalid index rejected')
check(not V.allowed(style,'ProjectYakuza_Y6_PunchSwing',0/0),'NaN clip selection rejected')
local disabled={id='other',sounds=style.sounds};check(not V.next(p,disabled,'ProjectYakuza_Y6_PunchSwing'),'other styles require explicit opt-in')
local ok=pcall(V.registerPool,'bad',40);check(not ok,'unbounded pools rejected')
V.registerPool('AddonSwing',2);style.sounds.addon='AddonSwing';check(V.allowed(style,'AddonSwing',2),'addons can register supplied native clip pools')
local nativeSounds={};GameSounds={getSound=function(cue)return nativeSounds[cue]end}
for cue,size in pairs(V.pools)do
 local sound={volume=.6,items={}}
 for i=1,size do sound.items[i]={parent=sound,index=i,volume=.44625,getFile=function()return string.format("source_%02d.wav",i)end}end
 sound.draws=0;sound.getRandomClip=function(self)self.draws=self.draws+1;return self.items[(self.draws-1)%#self.items+1]end;nativeSounds[cue]=sound
end
function p:getX()return 2 end;function p:getY()return 3 end;function p:getZ()return 0 end
local direct,relayed={},{};local handleZero=false
local pooled={playClip=function(_,clip,owner)local id=#direct+1;direct[id]={clip=clip,owner=owner};return handleZero and 0 or id end,setVolume=function(_,id,gain)direct[id].gain=gain end}
getWorld=function()return {getFreeEmitter=function(_,x,y,z)check(x==2 and y==3 and z==0,'one-shot sound is world-positioned at attacker');return pooled end}end
ProjectYakuza.Network={sound=function(who,cue,index,gain)relayed[#relayed+1]={p=who,cue=cue,index=index,gain=gain}end}
client=true;local baseCalls=#calls;local cue='ProjectYakuza_Y6_PunchSwing'
local first=F.play(p,cue,.65);check(first==1 and #direct==1 and #calls==baseCalls,'Feedback plays selected native clip without duplicate parent sound')
check(direct[1].clip.parent==nativeSounds[cue]and direct[1].gain==.65,'original parent volume and existing emitter gain retained')
check(#relayed==1 and relayed[1].index==direct[1].clip.index and relayed[1].cue==cue,'MP relays the selected clip index')
F.play(p,cue,.65);check(direct[1].clip~=direct[2].clip,'actual feedback path avoids a repeated whoosh')
nativeSounds[cue].volume=0;check(direct[1].clip.parent.volume==0,'native parent volume remains shared, including mute')
handleZero=true;F.play(p,cue,.65);check(#relayed==3 and #calls==baseCalls,'muted owner still relays for other listeners without fallback duplication');handleZero=false
local native=GameSounds.getSound(cue);table.remove(native.items);V.clips[cue]=nil;local before=#relayed;F.play(p,cue,.65)
check(#calls==baseCalls+1 and #relayed==before,'mismatched/missing clip pools use existing native cue fallback')
p.localPlayer=false;local beforeDirect=#direct;F.play(p,'ProjectYakuza_Y6_KickSwing',.65)
check(#direct==beforeDirect and #relayed==before,'remote actor does not originate another feedback packet');p.localPlayer=true
client=false;F.play(p,'ProjectYakuza_Y6_KickSwing',.65);check(#direct==beforeDirect+1 and #relayed==before,'SP uses selected clip without network traffic')
check(not V.play(p,style,'ProjectYakuza_Y6_KickSwing',1,2),'out-of-range playback gain rejected')
local draws=nativeSounds['ProjectYakuza_Y6_KickSwing'].draws;F.play(p,'ProjectYakuza_Y6_KickSwing',.65);check(nativeSounds['ProjectYakuza_Y6_KickSwing'].draws==draws,'native clip discovery is cached, not repeated per hit')
style.sounds.heavyImpact='ProjectYakuza_Y6_HeavyFinisher';style.sounds.chargedImpact=style.sounds.heavyImpact;style.sounds.finisher='SignatureFinisher'
for _,move in ipairs({{neutralHeavy=true},{chargedHeavy=true}})do
 combo.finisherMove=move;combo.multiHitToken={};local n=#direct;F.hit(p,nil,nil,1)
 check(#direct==n+1 and direct[#direct].clip.parent==nativeSounds[style.sounds.heavyImpact],'confirmed heavy/charged hit selects existing heavy pool')
 F.hit(p,nil,nil,1);check(#direct==n+1,'multihit does not stack heavy feedback per victim')
end
combo.finisherMove={afterLight=true};combo.multiHitToken={};F.hit(p,nil,nil,1);check(calls[#calls]=='SignatureFinisher','first finisher preserves its signature sound')
V.clear(p);check(not V.states[p],'style/world cleanup releases shuffle history')
do
 style.sounds.fullChargeImpact='ProjectYakuza_Y6_HeatImpact';style.sounds.parryImpact='DistinctCounter';style.sounds.counterImpact='ProjectYakuza_Y6_HeavyFinisher';style.sounds.guardHit='ProjectYakuza_Y6_GuardImpact';style.sounds.grabSwing='ReachWhoosh'
 combo.finisherMove={chargedHeavy=true,chargePower=1};combo.multiHitToken={};local n=#direct;F.hit(p,nil,nil,1)
 check(#direct==n+1 and direct[#direct].clip.parent==nativeSounds.ProjectYakuza_Y6_HeatImpact and direct[#direct].gain==.60,'full charge has a distinct existing heat-impact accent at confirmed contact')
 F.hit(p,nil,nil,1);check(#direct==n+1,'full-charge crowd contacts do not multiply the accent')
 combo.finisherMove={chargedHeavy=true,chargePower=.5};combo.multiHitToken={};F.hit(p,nil,nil,1)
 check(direct[#direct].clip.parent==nativeSounds.ProjectYakuza_Y6_HeavyFinisher,'partial charges retain the regular heavy sound')
 n=#direct;emit('guardHit',p);emit('guardHit',p);check(#direct==n+1,'simultaneous crowd blocks share one clear guard cue instead of clipping together')
 clock=clock+90;emit('guardHit',p);check(#direct==n+2,'a later actual block can play another varied guard cue')
 local native=#calls;n=#direct;emit('tigerDrop',p)
 check(#calls==native+1 and calls[#calls]=='DistinctCounter'and #direct==n+1,'Tiger Drop has a distinct counter transient plus the supplied heavy confirmation')
 emit('tigerDrop',p);check(#calls==native+1 and #direct==n+1,'duplicate counter events cannot double the feedback')
 native=#calls;emit('grabReach',p,nil);check(#calls==native+1 and calls[#calls]=='ReachWhoosh','a missed reach plays the same source-timed arm whoosh as a successful attempt')
 F.clear();check(not F.guardAt[p],'world cleanup clears guard cue throttling')
end
do
 ProjectYakuza.Bindings={label=function(id)return id end};style.sounds.grab='GripConfirm'
 local context={};local before=#calls
 emit('grabConnected',p,nil,context);emit('grabConnected',p,nil,context)
 check(#calls==before+1 and calls[#calls]=='GripConfirm'and F.states[p].text=='GRAB CONNECTED','authority connection gets one supplied grip cue and immediate feedback')
 check(F.states[p].untilAt-clock==650,'grab connection notice is brief')
 emit('grabHeld',p);check(#calls==before+1 and F.states[p].text:find('strike',1,true),'holding shows usable controls without replaying its connection sound')
 local missed={};before=#calls;emit('grabMissed',p,nil,missed);emit('grabMissed',p,nil,missed)
 check(#calls==before and F.states[p].text=='MISSED GRAB','miss has a distinct short notice and no invented impact sound')
 emit('grabEnded',p,nil,context);check(F.grabs[p].context==missed,'stale cleanup cannot clear a newer feedback session')
 emit('grabEnded',p,nil,missed);check(not F.grabs[p],'matching cleanup releases the feedback session')
end
do
 local draw;Events.OnPostUIDraw={Add=function(fn)draw=fn end};ProjectYakuza.StyleUI={render=function()return false end,releaseAll=function()end}
 getSpecificPlayer=function()return p end;function p:getModData()return {}end;function p:isAiming()return false end
 getCore=function()return {getScreenHeight=function()return 720 end}end;UIFont={Small=1};local text={}
 getTextManager=function()return {DrawString=function(_,font,x,y,value)text[#text+1]=value end}end
 do local _="ProjectYakuzaFixture:STATUSHUD" end
 F.notice(p,'MISSED GRAB',650);draw();check(text[#text]=='MISSED GRAB','feedback remains visible briefly after releasing aim')
 local n=#text;ISWorldMap_instance={isVisible=function()return true end};draw();check(#text==n,'map suppresses the brief notice');ISWorldMap_instance=nil
 ProjectYakuza.StyleSelector={setup={}};draw();check(#text==n,'phone and style menus suppress the notice');ProjectYakuza.StyleSelector.setup=nil
 clock=clock+651;draw();check(#text==n,'expired notice leaves no permanent HUD text')
 F.clear();check(not F.states[p]and not F.grabs[p],'world cleanup clears notices and grab sessions')
end
return true,'PASS '..count..' shuffle bags, source clip identity, native volumes, world playback, MP selection, mute/fallback and style isolation checks'
