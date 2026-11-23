require "ProjectYakuza/Registry"
require "ProjectYakuza/AttackEffects"
require "ProjectYakuza/HeatScreenEffects"
require "ProjectYakuza/HeatPresentationData"
require "ProjectYakuza/OpenGrabHeatPresentation"
local PY=ProjectYakuza
local C={states=setmetatable({}, {__mode="k"}),maxActors=8,lateMs=100,remoteLateMs=350,prepareMs=160}
PY.HeatActionPresentation=C
function C.sync()
    local any=false;for _ in pairs(C.states)do any=true;break end
    if any and not C.hooked then Events.OnPostRender.Add(C.tick);C.hooked=true
    elseif not any and C.hooked then Events.OnPostRender.Remove(C.tick);C.hooked=false end
end
function C.stop(p,source,complete)
    local s=C.states[p];if not s or source and s.source~=source then return end
    if not complete then for _,h in ipairs(s.handles)do if h.emitter:isPlaying(h.id)then h.emitter:stopSound(h.id)end end end
    if PY.AttackEffects.endPaired then PY.AttackEffects.endPaired(p,s.source,complete)end
    C.states[p]=nil;C.sync()
end
function C.start(p,z,move,source)
    if not p or not z or not move or not move.animation then return end
    local style=PY.getPlayerStyle(p);if not style then return end
    local old=C.states[p];if old and old.source==source then return end
    C.stop(p)
    local count=0;for _ in pairs(C.states)do count=count+1 end;if count>=C.maxActors then return end
    C.states[p]={victim=z,move=move,source=source,handles={},audio={},voices={},authored={},effects={},last=0,waitAt=getTimestampMs(),style=style.id};C.sync()
end
function C.definition(s,ending)
    local clip=ending and s.move.qteFailure.animation or s.move.animation
    local data=PY.HeatPresentationData.moves[clip]
    if data then return clip,data.contacts,data.effects end
    if ending then local f=s.move.qteFailure;return clip,{{atMs=f.contactMs,index=#PY.HeatRushRules.contacts(s.move)}}end
    return clip,PY.HeatRushRules.contacts(s.move)
end
function C.anchor(p,z,point)
    if not point then return end
    local _,_,x,y,h=PY.AttackEffects.project(point[1],point[2],point[3],p:getAnimAngleRadians(),1)
    return {x=z:getX()+x,y=z:getY()+y,z=z:getZ()+h}
end
function C.prepare(p,s,contact,meta)
    local style=PY.getPlayerStyle(p);local base=meta.base and PY.getStyle(style.id)or style
    local key=meta.cue or contact.cue or "heavyImpact";local name=base and base.sounds and base.sounds[key]or style.sounds and style.sounds.heavyImpact
    local function entry(name,gain)
        local sound=name and GameSounds.getSound(name);local clip=sound and sound:getRandomClip()
        if clip then return {clip=clip,lead=PY.HeatPresentationData.leads[clip:getFile()]or 35,gain=gain}end
    end
    local out=entry(name,.55)or {done=true};out.layers={}
    for _,key in ipairs(meta.layers or contact.layers or {})do local e=entry(style.sounds and style.sounds[key],.3);if e then out.layers[#out.layers+1]=e end end
    return out
end
function C.play(p,s,entry,anchor)
    local world=getWorld();if not world then return end
    local emitter=world:getFreeEmitter(anchor and anchor.x or p:getX(),anchor and anchor.y or p:getY(),anchor and anchor.z or p:getZ());if not emitter then return end
    local id=emitter:playClip(entry.clip,p)
    if type(id)=="number"and id~=0 then emitter:setVolume(id,entry.gain);s.handles[#s.handles+1]={emitter=emitter,id=id}end
end
function C.late(s)return s.source.remote and C.remoteLateMs or C.lateMs end
function C.allowed(s,contact,index)
    if not contact then return false end
    if not contact.qteIndex then return true end
    if s.source.remote then return s.source.confirmedContacts and s.source.confirmedContacts[index]==true or false end
    return s.source.qte and s.source.qte.accepted[contact.qteIndex]or false
end
function C.track(p,s,clip)
    if s.source.remote then
        if s.source.failed then return math.max(0,(getTimestampMs()-s.source.failureAt)/1000),1 end
        return PY.HeatRushRules.time(s.move,s.source.age)+math.max(0,getTimestampMs()-s.source.at)/1000,1
    end
    return PY.AttackEffects.findTrack(p,clip,s.location)
end
function C.authoredEvents(p,s,time,definition)
    local move=definition or s.move
    local style=PY.getPlayerStyle(p)
    for i,event in ipairs(move.audioEvents or {})do
        local audio=s.authored[i]
        if audio==nil and time>=event.atMs-C.prepareMs then
            local name=style.sounds and style.sounds[event.cue];local sound=name and GameSounds.getSound(name);local clip=sound and sound:getRandomClip()
            audio=clip and {clip=clip,gain=event.gain or .55}or {done=true};s.authored[i]=audio
        end
        if audio and not audio.done and time>=event.atMs then
            audio.done=true
            if time-event.atMs<=C.late(s) then
                local target=event.target=="victim"and s.victim or p
                C.play(p,s,audio,{x=target:getX(),y=target:getY(),z=target:getZ()})
            end
        end
    end
    if p:isLocalPlayer()and PY.CombatVoices then for i,event in ipairs(move.voiceEvents or {})do
        if not s.voices[i]and time>=event.atMs then
            s.voices[i]=true
            if time-event.atMs<=C.late(s) then PY.CombatVoices.contact(p,event.entry)end
        end
    end end
end
function C.tick()
    if isGamePaused()then return end
    for p,s in pairs(C.states)do
        local style=PY.getPlayerStyle(p)
        if p:isDead()or not PY.isEquipped(p)or not style or style.id~=s.style or s.source.cleaned or s.source.failed and not PY.HeatRushRules.pairedFailure(s.move)then C.stop(p,s.source)
        else
            local ending=s.source.failed and PY.HeatRushRules.pairedFailure(s.move)
            local clip,contacts,effects=C.definition(s,ending)
            if s.clip~=clip then s.clip=clip;s.audio={};s.voices={};s.authored={};s.effects={};s.sceneEffects={};s.location=nil;s.last=0;s.waitAt=getTimestampMs()end
            local phase,weight,slot=C.track(p,s,clip);s.location=slot
            if phase and weight>=.05 then
                local time=s.move.pacedAnimation and not ending and PY.HeatRushRules.sourceTime(s.move,phase)*1000 or phase*1000
                if s.source.remote then time=math.max(s.last,time)end
                if time+20<s.last then C.stop(p,s.source)
                else
                    s.last=time;s.waitAt=getTimestampMs()
                    s.limbContacts=s.limbContacts or {}
                    for i,contact in ipairs(PY.HeatRushRules.contacts(s.move))do s.limbContacts[i]=C.allowed(s,contact,i)end
                    if PY.AttackEffects.paired then PY.AttackEffects.paired(p,s.source,s.move,clip,phase,weight,s.limbContacts)end
                    local definition=ending and s.move.qteFailure or s.move
                    C.authoredEvents(p,s,time,definition)
                    for i,meta in ipairs(contacts)do
                        local index=meta.index or i;local contact=PY.HeatRushRules.contacts(s.move)[index]
                        local allowed=C.allowed(s,contact,index)
                        if allowed then
                            if definition.audioEvents==nil and s.audio[i]==nil and time>=meta.atMs-C.prepareMs then s.audio[i]=C.prepare(p,s,contact,meta)end
                            local audio=s.audio[i]
                            if audio and not audio.done and time>=meta.atMs-audio.lead then
                                audio.done=true
                                if time-(meta.atMs-audio.lead)<=C.late(s) then C.play(p,s,audio,C.anchor(p,s.victim,meta.point))end
                            end
                            if audio then for _,layer in ipairs(audio.layers)do
                                if not layer.done and time>=meta.atMs-layer.lead then layer.done=true;if time-(meta.atMs-layer.lead)<=C.late(s) then C.play(p,s,layer,C.anchor(p,s.victim,meta.point))end end
                            end end
                            if not s.effects[i]and time>=meta.atMs then
                                s.effects[i]=true
                                if time-meta.atMs<=C.late(s) then
                                    if effects~=nil then
                                        local impact=false;for _,event in ipairs(effects)do if event.index==index and event.impact then impact=true;break end end
                                        if not impact and PY.AttackEffects.hit then PY.AttackEffects.hit(p,s.victim,contact.strong~=false,contact.charged==true,C.anchor(p,s.victim,meta.point))end
                                        PY.emit("heatRushHit",p,s.victim,index,contact,C.anchor(p,s.victim,meta.point))
                                    else PY.HeatRush.present(p,s.victim,s.move,index,true,true,C.anchor(p,s.victim,meta.point),meta.feedback,meta.bloodOnly)end
                                end
                            end
                        end
                    end
                    for i,event in ipairs(effects or {})do
                        local contact=PY.HeatRushRules.contacts(s.move)[event.index]
                        if not s.sceneEffects[i]and time>=event.atMs and C.allowed(s,contact,event.index)then
                            s.sceneEffects[i]=true
                            if time-event.atMs<=C.late(s)then
                                local anchor=C.anchor(p,s.victim,event.point)
                                if event.impact and PY.HitEffects then PY.HitEffects.spawn(p,s.victim,contact.strong~=false,contact.charged==true,false,event.feedback,anchor)
                                elseif PY.BloodEffects then PY.BloodEffects.spawn(p,s.victim,contact.strong~=false,contact.charged==true,event.feedback,anchor)end
                            end
                        end
                    end
                end
            elseif getTimestampMs()-s.waitAt>1500 then C.stop(p,s.source)end
        end
    end
end
function C.clearAll()
    for p in pairs(C.states)do C.stop(p)end
end
Events.OnSave.Add(C.clearAll)
Events.OnMainMenuEnter.Add(C.clearAll)
