require "ProjectYakuza/Runtime"
require "ProjectYakuza/WorldEffects"
require "ProjectYakuza/AttackEffects"
require "ProjectYakuza/ChargeTracks"
local PY=ProjectYakuza
local F={states=setmetatable({}, {__mode="k"}),owners=setmetatable({}, {__mode="k"}),maxActors=8}
PY.ChargeEffects=F
function F.clear(p)
    F.owners[p]=nil
    local s=F.states[p];if not s then return end
    for _,instance in ipairs(s.instances) do instance:Dispose();IsoSpriteInstance.add(instance) end
    F.states[p]=nil
    local any=false;for _ in pairs(F.states) do any=true;break end
    if not any and F.hooked then Events.OnPostRender.Remove(F.render);F.hooked=false end
end
function F.update(p)
    if not p or not instanceof(p,"IsoPlayer") then return end
    local style=PY.getPlayerStyle(p);local c=PY.activeActions[p] or F.owners[p]
    local localCharge=c and c.kind=="heavyCharge" and c.timedAction and c.timedAction.started and not c.timedAction.cleaned
    local animation=localCharge and (c.timedAction.holding and c.action.holdAnimation or c.action.animation)
        or not p:isLocalPlayer() and p:GetVariable("ProjectYakuzaRemoteClip") or ""
    local track=PY.ChargeTracks[animation]
    local wanted=track and PY.isEquipped(p) and not p:isDead() and style and style.hitEffects=="yakuza6"
        and not p:getModData().ProjectYakuzaHitEffectsDisabled
    if not wanted then F.clear(p);return end
    local power=localCharge and c.timedAction.power or tonumber(p:GetVariable("ProjectYakuzaRemoteChargePower")) or 0
    local s=F.states[p]
    if s and #s.track.limbs~=#track.limbs then F.clear(p);s=nil end
    if s then
        if s.track~=track then s.location=nil;s.retryTrackAt=0 end
        s.track=track;s.power=math.max(0,math.min(1,power));s.updated=getTimestampMs();return
    end
    local count=0;for _ in pairs(F.states) do count=count+1 end;if count>=F.maxActors then return end
    local effects=PY.AttackEffects;effects.loadSprites()
    F.spark=effects.spark;F.smoke=effects.smoke;F.wisp=effects.gaidenSmoke
    s={instances={},points={},track=track,power=math.max(0,math.min(1,power)),clock=0,last=getTimestampMs(),updated=getTimestampMs(),seed=(getTimestampMs()+(p.getOnlineID and p:getOnlineID()or 0)*97)%997};F.states[p]=s
    local tile=Core.getTileScale()
    for _,limb in ipairs(track.limbs) do
        for i=1,18 do
            local smoke=i<=12;local wisp=i==13 or i==14;local sp=smoke and F.smoke or wisp and F.wisp or F.spark
            local scale=(i<=6 and .18 or smoke and .27 or wisp and .09 or .065)*tile*1.10
            local speed=.52+(s.seed+i*17)%31*.025
            local instance=PY.WorldEffects.detached(sp,scale,smoke and speed or 0)
            if smoke then PY.WorldEffects.phase(instance,.5+(s.seed+i*17)%31*.9,speed)end
            local point={instance=instance,sprite=sp,height=wisp and 128 or smoke and 64 or 32,baseScale=scale,scale=scale,limb=limb,index=i,animated=smoke,additive=i>14,texture=wisp and sp:getTextureForFrame(0,IsoDirections.N)or nil,widthScale=wisp and 64/65 or 1}
            instance:setScale(scale*point.widthScale,scale)
            s.instances[#s.instances+1]=instance;s.points[#s.points+1]=point
        end
    end
    if not F.hooked then Events.OnPostRender.Add(F.render);F.hooked=true end
end
function F.render()
    local renderer=SpriteRenderer.instance;local previous=renderer:getDoAdditive();renderer:setDoAdditive(false)
    local ok,err=pcall(F.draw);renderer:setDoAdditive(previous)
    if not ok then F.clearAll();error(err) end
end
function F.draw()
    if not F.color then F.color=ColorInfo.new(.94,.97,1,1)end
    local tile=Core.getTileScale();local now=getTimestampMs();local paused=isGamePaused()
    for p,s in pairs(F.states) do
        if p:isDead()or(not paused and now-s.updated>2000)then F.clear(p)
        else
            local dt=math.max(0,math.min(100,now-s.last));s.last=now
            if not paused then s.clock=s.clock+dt end
            local phase,weight
            if s.track.fixed then phase=0;weight=1
            elseif s.location or now>=(s.retryTrackAt or 0)then
                local location
                phase,weight,location=PY.AttackEffects.findTrack(p,s.track.animation,s.location)
                s.location=location;s.retryTrackAt=now+120
            end
            if not phase then phase=math.min(s.clock*.001,(#s.track.frames-1)/s.track.fps);weight=1 end
            local angle=p:getAnimAngleRadians();local fade=math.min(1,s.clock/120)*math.min(1,weight or 1)
            local power=.65+.35*s.power;local ready=s.power>=1 and .5+.5*math.sin(s.clock*.028)or 0
            for _,point in ipairs(s.points)do
                local ax,ay,az=PY.AttackEffects.sample(s.track,phase,point.limb)
                local bx,by,bz=PY.AttackEffects.sample(s.track,phase,point.limb+1)
                local i=point.index;local t=i<=12 and(.12+((i-1)%6)/5*.91)or i<=14 and(i==13 and .45 or .86)or .35+((s.clock*.0015+i*.19)%1)*.68
                local wave=s.clock*(.018+(i%4)*.006)+s.seed*.71+i*2.399963
                local radius=(i>14 and .018 or i>6 and .010 or .003)*power*math.sin(math.min(1,t)*math.pi)
                local ox,oy,oz=math.cos(wave)*radius,math.sin(wave*1.19)*radius,math.sin(wave*.83)*radius*.6
                local x,y,wx,wy,wz=PY.AttackEffects.project(ax+(bx-ax)*t+ox,ay+(by-ay)*t+oy,az+(bz-az)*t+oz,angle,tile)
                y=y+2*tile+PY.AttackEffects.coatOffset()
                local pulse=.83+.12*math.sin(wave)+.05*math.sin(wave*1.71)
                local alpha=fade*power*pulse*(i<=6 and(.22+.04*ready)or i<=12 and .075 or i<=14 and .18 or .42)
                local scale=point.baseScale*(.82+.16*pulse+.12*s.power)
                if point.scale~=scale then point.instance:setScale(scale*point.widthScale,scale);point.scale=scale end
                if PY.WorldEffects.ready(point.instance)then
                    if point.texture then point.texture:setWidth(65)end
                    SpriteRenderer.instance:setDoAdditive(point.additive)
                    point.instance:SetAlpha(alpha);point.instance:SetTargetAlpha(alpha)
                    if point.animated and not paused and dt>0 then point.sprite:update(point.instance)end
                    PY.WorldEffects.renderCentered(p,point.instance,point.height,scale,x,y,F.color,wx+.06,wy+.06,wz)
                end
            end
        end
    end
end
function F.ready(p)local s=F.states[p];if s then s.power=1 end end
PY.on("heavyChargeReady",F.ready)
function F.clearAll()
    local players={};for p in pairs(F.states) do players[#players+1]=p end
    for _,p in ipairs(players) do F.clear(p) end
    F.owners=setmetatable({}, {__mode="k"})
end
function F.begin(p,style,move,context)
    F.clear(p)
    if context then F.owners[p]=context end
    F.update(p)
end
PY.on("heavyChargeStarted",F.begin)
PY.on("heavyChargeStopped",F.clear)
Events.OnPlayerUpdate.Add(F.update)
Events.OnSave.Add(F.clearAll)
Events.OnMainMenuEnter.Add(F.clearAll)
