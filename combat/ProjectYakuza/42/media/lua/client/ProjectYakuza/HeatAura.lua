require "ProjectYakuza/Runtime"
require "ProjectYakuza/HeatOutline"
require "ProjectYakuza/WorldEffects"
local ProjectYakuza=ProjectYakuza
local A={states=setmetatable({}, {__mode="k"}),fadeInMs=350,flashMs=480,flashes=setmetatable({}, {__mode="k"})}
ProjectYakuza.HeatAura=A
-- Four tight overlapping patches on the upper body; no waist/leg emitters.
A.layout={
    {x=0,height=39.6,kind="a",speed=1.00,scale=0.25875},
    {x=-6.9,height=38.3,kind="b",speed=0.96,scale=0.207},
    {x=6.9,height=38.3,kind="c",speed=1.04,scale=0.207},
    {x=0,height=52.6,kind="b",speed=0.98,scale=0.1656},
}
-- Original Yakuza 6 A8L8 flame alpha: normal blending, without black-backed RGB.
-- Four fast upper-body flames, without static wisps or a broad bloom layer.
A.extremeLayout={
    {x=0,height=39.6,kind="flame",frames=64,frameHeight=32,speed=.55*64/(.65*60),scale=.95,alpha=.85,drift=.6,lift=1.2},
    {x=-6.9,height=38.3,kind="flame",frames=64,frameHeight=32,speed=.55*64/(.73*60),scale=.80,alpha=.75,drift=.5,lift=1},
    {x=6.9,height=38.3,kind="flame",frames=64,frameHeight=32,speed=.55*64/(.81*60),scale=.80,alpha=.80,drift=.5,lift=1.1},
    {x=0,height=52.6,kind="flame",frames=64,frameHeight=32,speed=.55*64/(.59*60),scale=.65,alpha=.70,drift=.4,lift=.8},
    {x=-7,height=6,kind="smoke",frames=64,frameHeight=64,speed=64/(1.6*60),scale=.40,alpha=.22,drift=-4,lift=9,smoke=true,cycleMs=1600},
    {x=7,height=7,kind="smoke",frames=64,frameHeight=64,speed=64/(1.85*60),scale=.40,alpha=.18,drift=4,lift=10,smoke=true,cycleMs=1850},
}
-- Completion-only torso flare: animated supplied flames plus small departing sparks.
-- Detached instances keep per-particle centring independent of shared sprite offsets.
A.flashLayout={
    {kind="flame",x=-6,height=38,scale=.65,frameHeight=32,drift=-2,lift=5,alpha=.52},
    {kind="flame",x=6,height=39,scale=.65,frameHeight=32,drift=2,lift=6,alpha=.52},
    {kind="flame",x=0,height=48,scale=.56,frameHeight=32,drift=0,lift=4,alpha=.46},
    {kind="flame",x=0,height=33,scale=.70,frameHeight=32,drift=0,lift=7,alpha=.48},
    {kind="spark",x=-7,height=38,scale=.20,frameHeight=32,drift=-5,lift=9,alpha=.55},
    {kind="spark",x=7,height=39,scale=.20,frameHeight=32,drift=5,lift=8,alpha=.55},
    {kind="spark",x=-3,height=46,scale=.18,frameHeight=32,drift=-3,lift=10,alpha=.52},
    {kind="spark",x=3,height=46,scale=.18,frameHeight=32,drift=3,lift=11,alpha=.52},
}
A.activationLayout={
    {kind="smoke",x=-11,height=3,scale=.62,frameHeight=64,drift=-9,lift=11,alpha=.38},
    {kind="smoke",x=-4,height=7,scale=.66,frameHeight=64,drift=-4,lift=15,alpha=.34},
    {kind="smoke",x=5,height=6,scale=.66,frameHeight=64,drift=5,lift=14,alpha=.34},
    {kind="smoke",x=12,height=2,scale=.60,frameHeight=64,drift=9,lift=10,alpha=.38},
}
function A.releaseBurst(f)
    if f then for _,e in ipairs(f.emitters or {}) do e.instance:Dispose();IsoSpriteInstance.add(e.instance) end end
end
function A.releaseFlash(p)
    A.releaseBurst(A.flashes[p]);A.flashes[p]=nil
end
function A.makeBurst(p,layout,duration)
    local f={remaining=duration,duration=duration,last=getTimestampMs(),emitters={}}
    A.burstSprites=A.burstSprites or {};local tile=Core.getTileScale()
    for _,point in ipairs(layout) do
        local sprite=A.burstSprites[point.kind]
        if not sprite then
            sprite=IsoSprite.CreateSprite(nil)
            if point.kind=="spark" then sprite:LoadFramesNoDirPageSimple("media/textures/ProjectYakuza/ChargeSpark.png")
            else sprite:LoadFramesNoDirPageDirect("media/textures/ProjectYakuza/ExtremeHeat",point.kind,64) end
            sprite:setAnimate(point.kind~="spark");A.burstSprites[point.kind]=sprite
        end
        local scale=tile*point.scale
        local instance=ProjectYakuza.WorldEffects.detached(sprite,scale,point.kind=="spark" and 0 or 64/((duration/1000)*60))
        instance:SetAlpha(0);instance:SetTargetAlpha(0)
        f.emitters[#f.emitters+1]={instance=instance,point=point,sprite=sprite}
    end
    return f
end
function A.advanceBurst(f,time)
    local elapsed=math.max(0,time-f.last);f.last=time
    if not isGamePaused() then f.remaining=f.remaining-elapsed end
    return f.remaining>0
end
function A.flash(player)
    if not player then return end
    A.releaseFlash(player)
    local f={remaining=A.flashMs,last=getTimestampMs(),emitters={}}
    A.flashes[player]=f;A.update(player)
    if A.flashes[player]~=f then return end
    A.flashes[player]=A.makeBurst(player,A.flashLayout,A.flashMs)
end
function A.drawFlash(p,f)
    if not A.particleColor then
        A.particleColor=ColorInfo.new(.60,.80,1,1)
        A.burstSmokeColor=A.extremeColor
    end
    local t=math.max(0,math.min(1,1-f.remaining/f.duration));local tile=Core.getTileScale()
    local fade=math.sin(math.pi*t)
    for _,e in ipairs(f.emitters) do
        local point=e.point;local alpha=point.alpha*fade
        local scale=tile*point.scale*(point.kind=="smoke" and (.75+.55*t) or (.9+.15*t))
        e.instance:setScale(scale,scale)
        e.instance:SetAlpha(alpha);e.instance:SetTargetAlpha(alpha)
        if point.kind~="spark" and not isGamePaused() then e.sprite:update(e.instance) end
        ProjectYakuza.WorldEffects.renderCentered(p,e.instance,point.frameHeight,scale,
            (point.x+point.drift*t)*tile,(-point.height-point.lift*t)*tile,
            point.kind=="smoke" and A.burstSmokeColor or A.particleColor)
    end
end

function A.syncRenderHook()
    local active=false
    for _,s in pairs(A.states) do
        for _,e in ipairs(s.emitters) do if e.instance then active=true;break end end
        if active then break end
    end
    if active and not A.rendering then Events.OnPostRender.Add(A.render);A.rendering=true
    elseif not active and A.rendering then Events.OnPostRender.Remove(A.render);A.rendering=false end
end
function A.draw(p,s,pulse)
    local tile=Core.getTileScale()
    local color=s.extreme and A.extremeColor or A.color
    for _,e in ipairs(s.emitters) do
        if e.instance and e.instance:getParentSprite()==e.sprite and not (pulse and e.point.smoke) then
            local alpha=s.opacity
            local dx,dy=0,0
            if s.extreme then
                local phase=s.clock*.0016+e.index*1.3
                alpha=alpha*e.point.alpha*(.92+.08*math.sin(phase))
                dx=e.point.drift*math.sin(phase*.7)
                dy=e.point.lift*math.sin(phase*.9)
                if e.point.smoke then
                    local cycle=(s.clock/e.point.cycleMs+e.index*.37)%1
                    alpha=s.opacity*e.point.alpha*math.sin(math.pi*cycle)
                    dx=e.point.drift*cycle;dy=e.point.lift*cycle
                end
            end
            if pulse then alpha=alpha*pulse end
            if not pulse and not isGamePaused() and e.frames>1 then e.sprite:update(e.instance) end
            if e.opacity~=alpha then e.instance:SetAlpha(alpha);e.instance:SetTargetAlpha(alpha);e.opacity=alpha end
            e.instance:render(p,p:getX(),p:getY(),p:getZ(),IsoDirections.N,
                p:getOffsetX()+tile+dx*tile,p:getOffsetY()-89*tile-dy*tile,e.point.smoke and A.smokeColor or color)
        end
    end
end
function A.renderBody()
    if not A.color then
        A.color=ColorInfo.new(1,1,1,1)
        A.extremeColor=ColorInfo.new(.25,.15,1,1)
        A.smokeColor=A.extremeColor
    end
    local time=getTimestampMs()
    for p,s in pairs(A.states) do
        if not p:isDead() and s.fadeElapsed then
            local elapsed=math.max(0,time-s.fadeLast);s.fadeLast=time
            local flash=A.flashes[p]
            if flash and not A.advanceBurst(flash,time) then A.releaseFlash(p);s.flashing=false;flash=nil end
            if s.activationBurst and not A.advanceBurst(s.activationBurst,time) then
                A.releaseBurst(s.activationBurst);s.activationBurst=nil
            end
            if not isGamePaused() then
                s.clock=s.clock+elapsed;s.fadeElapsed=math.min(A.fadeInMs,s.fadeElapsed+elapsed)
            end
            local fraction=s.fadeElapsed/A.fadeInMs;s.opacity=fraction*fraction*(3-2*fraction)
            if not s.flashing and not s.extreme and ProjectYakuza.Heat.stocks(p)<1 then A.clear(p)
            else
                if ProjectYakuza.HeatOutline then ProjectYakuza.HeatOutline.draw(p) end
                A.draw(p,s)
                if s.activationBurst then A.drawFlash(p,s.activationBurst) end
                if flash then
                    A.drawFlash(p,flash)
                    -- Brief, low-gain pulse of the actual aura, only after taunt completion.
                    local pulse=.12*math.sin(math.pi*(1-flash.remaining/flash.duration))
                    if pulse>.002 then
                        SpriteRenderer.instance:setDoAdditive(true)
                        A.draw(p,s,pulse)
                        SpriteRenderer.instance:setDoAdditive(false)
                    end
                end
            end
        elseif p:isDead() then A.clear(p) end
    end
end
function A.render()
    local renderer=SpriteRenderer.instance;local previous=renderer:getDoAdditive()
    renderer:setDoAdditive(false)
    local ok,err=pcall(A.renderBody);renderer:setDoAdditive(previous)
    if not ok then error(err) end
end

function A.clear(player)
    if ProjectYakuza.HeatOutline then ProjectYakuza.HeatOutline.clear(player) end
    A.releaseFlash(player)
    local s=A.states[player]
    if not s then return end
    A.releaseBurst(s.activationBurst);s.activationBurst=nil;s.activating=false
    for _,e in ipairs(s.emitters) do
        if e.instance then e.instance:Dispose();IsoSpriteInstance.add(e.instance);e.instance=nil end
    end
    s.fadeElapsed=nil;s.fadeLast=nil;s.opacity=nil
    A.syncRenderHook()
end
function A.isActivating(player)
    local activation=ProjectYakuza.HeatActivation and ProjectYakuza.HeatActivation.active and ProjectYakuza.HeatActivation.active[player]
    if activation and activation.started and not activation.cleaned then return true end
    local clip=player:GetVariable("ProjectYakuzaRemoteClip") or ""
    return not player:isLocalPlayer() and string.match(clip,"^ProjectYakuza_DD_HeatActivate0[1-4]$")~=nil
end
function A.update(player)
    if not player or not instanceof(player,"IsoPlayer") then return end
    local flashing=A.flashes[player]~=nil
    local activating=A.isActivating(player)
    local wanted=not player:isDead() and ProjectYakuza.isEquipped(player) and not player:getVehicle()
        and ProjectYakuza.getPlayerStyle(player).heatAura=="kiryu" and ProjectYakuza.Heat.enabled(player)
        and not player:getModData().ProjectYakuzaHeatAuraDisabled
        and (activating or flashing or ProjectYakuza.Heat.stocks(player)>=1 or (ProjectYakuza.Heat.isExtreme(player) and ProjectYakuza.Heat.display(player)>0))
    if not wanted then A.clear(player);return end
    local s=A.states[player]
    if not s then s={emitters={}};A.states[player]=s end
    local firstActivation=activating and not s.activating
    s.flashing=flashing;s.activating=activating;s.extreme=activating or ProjectYakuza.Heat.isExtreme(player)
    if firstActivation then
        A.releaseBurst(s.activationBurst);s.activationBurst=A.makeBurst(player,A.activationLayout,1000)
    elseif not s.extreme and s.activationBurst then A.releaseBurst(s.activationBurst);s.activationBurst=nil end
    if ProjectYakuza.HeatOutline then
        ProjectYakuza.HeatOutline.update(player,s.extreme)
        ProjectYakuza.HeatOutline.draw(player)
    end
    local profile=s.extreme and "extreme" or "normal"
    local fresh=not s.emitters[1] or not s.emitters[1].instance
    if not fresh and s.profile~=profile then
        for _,e in ipairs(s.emitters) do
            if e.instance then e.instance:Dispose();IsoSpriteInstance.add(e.instance);e.instance=nil end
        end
    end
    s.profile=profile
    if fresh then s.fadeElapsed=0;s.fadeLast=getTimestampMs();s.opacity=0;s.clock=0 end
    local tile=Core.getTileScale()
    local layout=s.extreme and A.extremeLayout or A.layout
    for i=#s.emitters,#layout+1,-1 do
        local e=s.emitters[i]
        if e.instance then e.instance:Dispose();IsoSpriteInstance.add(e.instance) end
        table.remove(s.emitters,i)
    end
    for i,point in ipairs(layout) do
        local e=s.emitters[i]
        if not e then e={sprites={}};s.emitters[i]=e end
        e.point=point;e.index=i;e.frames=point.frames or 32
        if not e.sprites[profile] then
            local sprite=IsoSprite.CreateSprite(nil)
            local source=s.extreme and "media/textures/ProjectYakuza/ExtremeHeat" or "media/textures/ProjectYakuza/HeatWisp"
            sprite:LoadFramesNoDirPageDirect(source,point.kind,e.frames)
            sprite:setAnimate(e.frames>1);e.sprites[profile]=sprite
        end
        e.sprite=e.sprites[profile]
        if not e.instance then
            e.instance=ProjectYakuza.WorldEffects.attach(player,e.sprite,point.frameHeight or 256,tile*point.scale,point.height*tile,true,
                s.extreme and point.speed or point.speed*32/(1.2*60),point.x*tile)
            -- Transfer ownership without disposing/pooling the instance. It is drawn only by A.render.
            player:getAttachedAnimSprite():remove(e.instance)
            local opacity=s.opacity*(s.extreme and point.alpha or 1)
            e.instance:SetAlpha(opacity);e.instance:SetTargetAlpha(opacity);e.opacity=opacity
        end
    end
    A.syncRenderHook()
end
function A.toggle(player)
    local d=player:getModData();d.ProjectYakuzaHeatAuraDisabled=not d.ProjectYakuzaHeatAuraDisabled
    A.update(player)
end
function A.clearAll()
    for p in pairs(A.states) do A.clear(p) end
    A.flashes=setmetatable({}, {__mode="k"})
end
ProjectYakuza.on("heatChanged",A.update)
ProjectYakuza.on("extremeHeatStarted",A.update)
ProjectYakuza.on("extremeHeatEnded",A.update)
ProjectYakuza.on("heatActivationStarted",A.update)
ProjectYakuza.on("heatActivationStopped",A.update)
ProjectYakuza.on("styleChanged",A.update)
ProjectYakuza.on("tauntStopped",function(p,completed)if completed then A.flash(p) end end)
Events.OnSave.Add(A.clearAll)
Events.OnMainMenuEnter.Add(A.clearAll)
