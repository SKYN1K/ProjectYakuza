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
    if not F.spark then
        F.spark=IsoSprite.CreateSprite(nil);F.spark:LoadFramesNoDirPageSimple("media/textures/ProjectYakuza/ChargeSpark.png")
        F.flame=IsoSprite.CreateSprite(nil);F.flame:LoadFramesNoDirPageDirect("media/textures/ProjectYakuza/ExtremeHeat","flame",64);F.flame:setAnimate(true)
        F.core=IsoSprite.CreateSprite(nil);F.core:LoadFramesNoDirPageSimple("media/textures/ProjectYakuza/HitGlint.png")
    end
    s={instances={},points={},track=track,power=math.max(0,math.min(1,power)),clock=0,last=getTimestampMs(),updated=getTimestampMs()};F.states[p]=s
    local tile=Core.getTileScale()
    for _,limb in ipairs(track.limbs) do
        for i=1,6 do
            local sp=i<=3 and F.core or i<=5 and F.flame or F.spark
            local height=i<=3 and 64 or 32;local scale=(i<=3 and .15 or i<=5 and .40 or .23)*tile
            local instance=PY.WorldEffects.detached(sp,scale,i==4 and .9 or i==5 and 1.1 or 0)
            s.instances[#s.instances+1]=instance;s.points[#s.points+1]={instance=instance,sprite=sp,height=height,scale=scale,limb=limb,index=i}
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
    if not F.color then F.color=ColorInfo.new(.60,.80,1,1) end
    local tile=Core.getTileScale();local now=getTimestampMs()
    for p,s in pairs(F.states) do
        if p:isDead() or (not isGamePaused() and now-s.updated>2000) then F.clear(p)
        else
            local dt=math.max(0,math.min(100,now-s.last));s.last=now
            if not isGamePaused() then s.clock=s.clock+dt end
            local phase,weight
            if s.track.fixed then phase=0;weight=1
            elseif s.location or now>=(s.retryTrackAt or 0) then
                local location
                phase,weight,location=PY.AttackEffects.findTrack(p,s.track.animation,s.location)
                s.location=location;s.retryTrackAt=now+120
            end

            if not phase then phase=math.min(s.clock*.001,(#s.track.frames-1)/s.track.fps);weight=1 end
            if phase then
                local angle=p:getAnimAngleRadians();local fade=math.min(1,s.clock/120)*math.min(1,weight or 1)
                for _,point in ipairs(s.points) do
                    local ax,ay,az=PY.AttackEffects.sample(s.track,phase,point.limb)
                    local bx,by,bz=PY.AttackEffects.sample(s.track,phase,point.limb+1)
                    local i=point.index;local t=i<=3 and (.12+i*.19) or i==4 and .38 or i==5 and .70 or (.18+.55*((s.clock/360)%1))
                    local x,y,wx,wy,wz=PY.AttackEffects.project(ax+(bx-ax)*t,ay+(by-ay)*t,az+(bz-az)*t,angle,tile)
                    y=y+2*tile
                    local alpha=fade*(.55+.30*s.power)*(i<=3 and .8 or i<=5 and .9 or 1)
                    SpriteRenderer.instance:setDoAdditive(i<=3)
                    if i==6 then x=x+math.sin(s.clock*.025)*tile;y=y+math.cos(s.clock*.025)*tile end
                    point.instance:SetAlpha(alpha);point.instance:SetTargetAlpha(alpha)
                    if (i==4 or i==5) and not isGamePaused() then point.sprite:update(point.instance) end
                    PY.WorldEffects.renderCentered(p,point.instance,point.height,point.scale,x,y,F.color,wx+.06,wy+.06,wz)
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
