require "ProjectYakuza/Runtime"
require "ProjectYakuza/WorldEffects"
local ProjectYakuza=ProjectYakuza
local A={states=setmetatable({}, {__mode="k"}),fadeInMs=350,flashMs=260,flashStrength=0.035,flashes=setmetatable({}, {__mode="k"})}
ProjectYakuza.HeatAura=A
-- Four tight overlapping patches on the upper body; no waist/leg emitters.
A.layout={
    {x=0,height=39.6,kind="a",speed=1.00,scale=0.25875},
    {x=-6.9,height=38.3,kind="b",speed=0.96,scale=0.207},
    {x=6.9,height=38.3,kind="c",speed=1.04,scale=0.207},
    {x=0,height=52.6,kind="b",speed=0.98,scale=0.1656},
}
-- Extreme Heat replaces, rather than overlays, the normal profile. Geometry
-- stays identical; use different supplied 32-frame wisps and livelier playback.
A.extremeLayout={
    {x=0,height=39.6,kind="c",speed=1.20,scale=0.25875},
    {x=-6.9,height=38.3,kind="a",speed=1.16,scale=0.207},
    {x=6.9,height=38.3,kind="b",speed=1.24,scale=0.207},
    {x=0,height=52.6,kind="c",speed=1.18,scale=0.1656},
}
A.extremeGlow=0.16
A.flashLayout={
    {kind="wispL",x=-7,height=40,scale=.30,frameHeight=128,drift=-2,lift=5,alpha=.22},
    {kind="wispR",x=7,height=41,scale=.30,frameHeight=128,drift=2,lift=6,alpha=.22},
    {kind="wispL",x=0,height=53,scale=.22,frameHeight=128,drift=0,lift=4,alpha=.15},
    {kind="spark",x=-9,height=39,scale=.25,frameHeight=64,drift=-3,lift=8,alpha=.30},
    {kind="spark",x=9,height=40,scale=.25,frameHeight=64,drift=3,lift=9,alpha=.30},
}
function A.releaseFlash(p)
    local f=A.flashes[p]
    if f then for _,e in ipairs(f.emitters or {}) do e.instance:Dispose();IsoSpriteInstance.add(e.instance) end end
    A.flashes[p]=nil
end
function A.flash(player)
    if not player then return end
    A.releaseFlash(player)
    local f={remaining=A.flashMs,last=getTimestampMs(),emitters={}}
    A.flashes[player]=f;A.update(player)
    if A.flashes[player]~=f then return end
    A.flashSprites=A.flashSprites or {}
    local tile=Core.getTileScale()
    for _,point in ipairs(A.flashLayout) do
        local sprite=A.flashSprites[point.kind]
        if not sprite then
            sprite=IsoSprite.CreateSprite(nil)
            sprite:LoadFramesNoDirPageDirect("media/textures/ProjectYakuza/TauntBurst",point.kind,1)
            sprite:setAnimate(false);A.flashSprites[point.kind]=sprite
        end
        local instance=ProjectYakuza.WorldEffects.attach(player,sprite,point.frameHeight,tile*point.scale,point.height*tile,false,0,point.x*tile)
        player:getAttachedAnimSprite():remove(instance)
        instance:SetAlpha(0);instance:SetTargetAlpha(0)
        f.emitters[#f.emitters+1]={instance=instance,point=point}
    end
end
function A.drawFlash(p,f)
    if not A.particleColor then A.particleColor=ColorInfo.new(.18,.65,1,1) end
    local t=math.max(0,math.min(1,1-f.remaining/A.flashMs));local tile=Core.getTileScale()
    local fade=math.sin(math.pi*t)*(1-.35*t)
    for _,e in ipairs(f.emitters) do
        local point=e.point;local alpha=point.alpha*fade
        e.instance:SetAlpha(alpha);e.instance:SetTargetAlpha(alpha)
        e.instance:render(p,p:getX(),p:getY(),p:getZ(),IsoDirections.N,
            p:getOffsetX()+tile+point.drift*t*tile,p:getOffsetY()-89*tile-point.lift*t*tile,A.particleColor)
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
function A.draw(p,s,additive,flashStrength)
    local tile=Core.getTileScale()
    local color=s.extreme and (additive and A.extremeGlowColor or A.extremeColor) or A.color
    for _,e in ipairs(s.emitters) do
        if e.instance and e.instance:getParentSprite()==e.sprite then
            local alpha=s.opacity
            if flashStrength then alpha=alpha*flashStrength
            elseif additive then alpha=alpha*A.extremeGlow*(0.94+0.06*math.sin(s.clock*0.006)) end
            -- Additive passes reuse the exact same frame, never advance twice.
            if not additive and not flashStrength and not isGamePaused() then e.sprite:update(e.instance) end
            if e.opacity~=alpha then e.instance:SetAlpha(alpha);e.instance:SetTargetAlpha(alpha);e.opacity=alpha end
            e.instance:render(p,p:getX(),p:getY(),p:getZ(),IsoDirections.N,
                p:getOffsetX()+tile,p:getOffsetY()-89*tile,color)
        end
    end
end
function A.render()
    -- One native world-render path for every facing; never use character-direction rendering.
    if not A.color then
        A.color=ColorInfo.new(1,1,1,1)
        A.extremeColor=ColorInfo.new(.90,.98,1,1)
        A.extremeGlowColor=ColorInfo.new(.72,.93,1,1)
    end
    for p,s in pairs(A.states) do
    if not p:isDead() and s.fadeElapsed then
    local time=getTimestampMs()
    local elapsed=math.max(0,time-s.fadeLast);s.fadeLast=time
    local flash=A.flashes[p]
    local flashElapsed=flash and math.max(0,time-flash.last) or 0
    if flash then flash.last=time end
    if not isGamePaused() then
        if flash then
            flash.remaining=flash.remaining-flashElapsed
            if flash.remaining<=0 then A.releaseFlash(p);s.flashing=false end
        end
        s.clock=s.clock+elapsed
        s.fadeElapsed=math.min(A.fadeInMs,s.fadeElapsed+elapsed)
    end
    if s.fadeElapsed<=A.fadeInMs then
        local fraction=s.fadeElapsed/A.fadeInMs
        s.opacity=fraction*fraction*(3-2*fraction)
    end
    if not s.flashing and not s.extreme and ProjectYakuza.Heat.stocks(p)<1 then
        A.clear(p)
    else
    A.draw(p,s,false)
    local strength=flash and flash.remaining>0 and A.flashStrength*math.sin(math.pi*(1-flash.remaining/A.flashMs)) or 0
    if s.extreme or strength>0.002 or (flash and flash.remaining>0) then
        local renderer=SpriteRenderer.instance;local previous=renderer:getDoAdditive()
        renderer:setDoAdditive(true)
        local ok,err=pcall(function()
            if s.extreme then A.draw(p,s,true) end
            -- Taunt completion flashes only the currently selected profile.
            -- Extreme Heat never draws the normal profile underneath it.
            if strength>0.002 then A.draw(p,s,true,strength) end
            if flash and flash.remaining>0 then A.drawFlash(p,flash) end
        end)
        renderer:setDoAdditive(previous)
        if not ok then error(err) end
    end
    end
    end
    end
end
function A.clear(player)
    A.releaseFlash(player)
    local s=A.states[player]
    if not s then return end
    for _,e in ipairs(s.emitters) do
        if e.instance then e.instance:Dispose();IsoSpriteInstance.add(e.instance);e.instance=nil end
    end
    s.fadeElapsed=nil;s.fadeLast=nil;s.opacity=nil
    A.syncRenderHook()
end
function A.update(player)
    if not player or not instanceof(player,"IsoPlayer") then return end
    local flashing=A.flashes[player]~=nil
    local wanted=not player:isDead() and ProjectYakuza.isEquipped(player) and not player:getVehicle()
        and ProjectYakuza.getPlayerStyle(player).heatAura=="kiryu" and ProjectYakuza.Heat.enabled(player)
        and not player:getModData().ProjectYakuzaHeatAuraDisabled
        and (flashing or ProjectYakuza.Heat.stocks(player)>=1 or (ProjectYakuza.Heat.isExtreme(player) and ProjectYakuza.Heat.display(player)>0))
    if not wanted then A.clear(player);return end
    local s=A.states[player]
    if not s then s={emitters={}};A.states[player]=s end
    s.flashing=flashing;s.extreme=ProjectYakuza.Heat.isExtreme(player)
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
    for i,point in ipairs(layout) do
        local e=s.emitters[i]
        if not e then e={sprites={}};s.emitters[i]=e end
        if not e.sprites[profile] then
            local sprite=IsoSprite.CreateSprite(nil)
            sprite:LoadFramesNoDirPageDirect("media/textures/ProjectYakuza/HeatWisp",point.kind,32)
            sprite:setAnimate(true);e.sprites[profile]=sprite
        end
        e.sprite=e.sprites[profile]
        if not e.instance then
            e.instance=ProjectYakuza.WorldEffects.attach(player,e.sprite,256,tile*point.scale,point.height*tile,true,
                point.speed*32/(1.2*60),point.x*tile)
            -- Transfer ownership without disposing/pooling the instance. It is drawn only by A.render.
            player:getAttachedAnimSprite():remove(e.instance)
            e.instance:SetAlpha(s.opacity);e.instance:SetTargetAlpha(s.opacity);e.opacity=s.opacity
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
ProjectYakuza.on("styleChanged",A.update)
ProjectYakuza.on("tauntStopped",function(p,completed)if completed then A.flash(p) end end)
Events.OnSave.Add(A.clearAll)
Events.OnMainMenuEnter.Add(A.clearAll)
