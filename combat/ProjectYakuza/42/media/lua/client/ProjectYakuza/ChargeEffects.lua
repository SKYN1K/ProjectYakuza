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
    local remote=not p:isLocalPlayer() and p:GetVariable("ProjectYakuzaRemoteClip")=="ProjectYakuza_DD_ChargeLoop"
    local wanted=PY.isEquipped(p) and not p:isDead() and style and style.hitEffects=="yakuza6"
        and not p:getModData().ProjectYakuzaHitEffectsDisabled and (localCharge or remote)
    if not wanted then F.clear(p);return end
    if F.states[p] then F.states[p].updated=getTimestampMs();return end
    if not F.sprite then F.sprite=IsoSprite.CreateSprite(nil);F.sprite:LoadFramesNoDirPageSimple("media/textures/ProjectYakuza/ChargeSpark.png") end
    local s={instances={},clock=0,last=getTimestampMs(),updated=getTimestampMs()};F.states[p]=s
    for i=1,6 do
        local instance=PY.WorldEffects.attach(p,F.sprite,32,.28*Core.getTileScale(),26*Core.getTileScale(),true,0)
        p:getAttachedAnimSprite():remove(instance);s.instances[i]=instance
    end
    if not F.hooked then Events.OnPostRender.Add(F.render);F.hooked=true end
end
function F.render()
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
        for i,instance in ipairs(s.instances) do
            local phase=(s.clock/420+i/6)%1
            local angle=i*2.399963
            local radius=phase*10*tile
            local alpha=math.sin(phase*math.pi)*.65*math.min(1,s.clock/200)
            instance:SetAlpha(alpha);instance:SetTargetAlpha(alpha)
            instance:render(p,p:getX(),p:getY(),p:getZ(),IsoDirections.N,
                p:getOffsetX()+tile+x+math.cos(angle)*radius,
                p:getOffsetY()-89*tile+y+math.sin(angle)*radius-phase*5*tile,F.color)
        end
        end
    end
end
function F.clearAll()
    local players={};for p in pairs(F.states) do players[#players+1]=p end
    for _,p in ipairs(players) do F.clear(p) end
end
PY.on("heavyChargeStopped",F.clear)
Events.OnPlayerUpdate.Add(F.update)
Events.OnSave.Add(F.clearAll)
Events.OnMainMenuEnter.Add(F.clearAll)
