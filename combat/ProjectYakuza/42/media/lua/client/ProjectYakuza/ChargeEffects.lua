require "ProjectYakuza/Runtime"
require "ProjectYakuza/WorldEffects"
local PY=ProjectYakuza
local F={states=setmetatable({}, {__mode="k"})}
PY.ChargeEffects=F
function F.clear(p)
    local s=F.states[p];if not s then return end
    for _,instance in ipairs(s.instances) do instance:Dispose();IsoSpriteInstance.add(instance) end
    F.states[p]=nil
    local any=false;for _ in pairs(F.states) do any=true;break end
    if not any and F.hooked then Events.OnPostRender.Remove(F.render);F.hooked=false end
end
function F.update(p)
    if not p or not instanceof(p,"IsoPlayer") then return end
    local style=PY.getPlayerStyle(p)
    local c=PY.activeActions[p]
    local localCharge=c and c.kind=="heavyCharge" and c.timedAction and c.timedAction.started
    local clip=p:GetVariable("ProjectYakuzaRemoteClip") or ""
    local remote=not p:isLocalPlayer() and (clip=="ProjectYakuza_DD_ChargeLoop" or string.match(clip,"^ProjectYakuza_DD_ChargeWindup0[1-4]$")~=nil or string.match(clip,"^ProjectYakuza_DD_ChargeHold0[1-4]$")~=nil)
    local wanted=PY.isEquipped(p) and not p:isDead() and style and style.hitEffects=="yakuza6"
        and not p:getModData().ProjectYakuzaHitEffectsDisabled and (localCharge or remote)
    if not wanted then F.clear(p);return end
    local ready=localCharge and c.timedAction.ready or string.match(clip,"^ProjectYakuza_DD_ChargeHold0[1-4]$")~=nil
    if F.states[p] then
        local s=F.states[p];s.updated=getTimestampMs()
        if ready and not s.readyClock then s.readyClock=s.clock end
        return
    end
    if not F.sprite then F.sprite=IsoSprite.CreateSprite(nil);F.sprite:LoadFramesNoDirPageSimple("media/textures/ProjectYakuza/ChargeSpark.png") end
    if not F.flame then
        F.flame=IsoSprite.CreateSprite(nil);F.flame:LoadFramesNoDirPageDirect("media/textures/ProjectYakuza/ExtremeHeat","flame",64);F.flame:setAnimate(true)
        F.core=IsoSprite.CreateSprite(nil);F.core:LoadFramesNoDirPageSimple("media/textures/ProjectYakuza/HitGlint.png")
    end
    local s={instances={},clock=0,last=getTimestampMs(),updated=getTimestampMs(),readyClock=ready and 0 or nil};F.states[p]=s
    for i=1,10 do
        local instance=PY.WorldEffects.attach(p,F.sprite,32,.28*Core.getTileScale(),26*Core.getTileScale(),true,0)
        p:getAttachedAnimSprite():remove(instance);s.instances[i]=instance
    end
    for _,point in ipairs({{sprite=F.flame,height=32,scale=.38,speed=64/(1.3*60)},{sprite=F.core,height=64,scale=.20,speed=0}}) do
        local instance=PY.WorldEffects.attach(p,point.sprite,point.height,point.scale*Core.getTileScale(),26*Core.getTileScale(),true,point.speed)
        p:getAttachedAnimSprite():remove(instance);s.instances[#s.instances+1]=instance
    end
    if not F.hooked then Events.OnPostRender.Add(F.render);F.hooked=true end
end
function F.render()
    local renderer=SpriteRenderer.instance;local previous=renderer:getDoAdditive();renderer:setDoAdditive(false)
    local ok,err=pcall(F.draw);renderer:setDoAdditive(previous)
    if not ok then error(err) end
end
function F.draw()
    if not F.color then F.color=ColorInfo.new(.28,.66,1,1) end
    local tile=Core.getTileScale();local t=getTimestampMs()
    for p,s in pairs(F.states) do
        if p:isDead() or (not isGamePaused() and t-s.updated>2000) then F.clear(p)
        else
        local dt=math.max(0,math.min(100,t-s.last));s.last=t
        if not isGamePaused() then s.clock=s.clock+dt end
        local v=p:getForwardDirection();local fx,fy=v:getX(),v:getY()
        local x=((fx-fy)*9+(fx+fy)*5)*tile
        local y=((fx+fy)*4+(fy-fx)*2)*tile
        for i=1,10 do
            local instance=s.instances[i]
            local phase=(s.clock/420+i/10)%1
            local angle=i*2.399963
            local radius=phase*10*tile
            local alpha=math.sin(phase*math.pi)*.65*math.min(1,s.clock/200)
            instance:SetAlpha(alpha);instance:SetTargetAlpha(alpha)
            instance:render(p,p:getX(),p:getY(),p:getZ(),IsoDirections.N,
                p:getOffsetX()+tile+x+math.cos(angle)*radius,
                p:getOffsetY()-89*tile+y+math.sin(angle)*radius-phase*5*tile,F.color)
        end
        local flame,core=s.instances[11],s.instances[12]
        if not isGamePaused() then F.flame:update(flame) end
        local ready=s.readyClock and math.max(0,1-(s.clock-s.readyClock)/280) or 0
        local fade=math.min(1,s.clock/200)
        local flameAlpha=(.55+.15*math.sin(s.clock*.012))*fade
        flame:SetAlpha(flameAlpha);flame:SetTargetAlpha(flameAlpha)
        flame:render(p,p:getX(),p:getY(),p:getZ(),IsoDirections.N,p:getOffsetX()+tile+x,p:getOffsetY()-89*tile+y,F.color)
        local coreAlpha=(.22+.08*math.sin(s.clock*.016)+ready*.35)*fade
        core:SetAlpha(coreAlpha);core:SetTargetAlpha(coreAlpha)
        core:render(p,p:getX(),p:getY(),p:getZ(),IsoDirections.N,p:getOffsetX()+tile+x,p:getOffsetY()-89*tile+y,F.color)
        end
    end
end
function F.ready(p)local s=F.states[p];if s and not s.readyClock then s.readyClock=s.clock end end
PY.on("heavyChargeReady",F.ready)
function F.clearAll()
    local players={};for p in pairs(F.states) do players[#players+1]=p end
    for _,p in ipairs(players) do F.clear(p) end
end
PY.on("heavyChargeStopped",F.clear)
Events.OnPlayerUpdate.Add(F.update)
Events.OnSave.Add(F.clearAll)
Events.OnMainMenuEnter.Add(F.clearAll)
