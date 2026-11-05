require "ProjectYakuza/Runtime"
require "ProjectYakuza/HeatOutline"
require "ProjectYakuza/WorldEffects"
local ProjectYakuza=ProjectYakuza
local A={states=setmetatable({}, {__mode="k"}),fadeInMs=350,flashMs=450,flashes=setmetatable({}, {__mode="k"})}
ProjectYakuza.HeatAura=A

A.layout={
    {x=0,height=39.6,kind="a",speed=1.00,scale=0.25875},
    {x=-6.9,height=38.3,kind="b",speed=0.96,scale=0.207},
    {x=6.9,height=38.3,kind="c",speed=1.04,scale=0.207},
    {x=0,height=52.6,kind="b",speed=0.98,scale=0.1656},
}

A.extremeLayout={
    {x=0,height=39.6,kind="flame",frames=64,frameHeight=32,speed=.55*64/(.65*60),scale=.95,alpha=.85,drift=.6,lift=1.2},
    {x=-6.9,height=38.3,kind="flame",frames=64,frameHeight=32,speed=.55*64/(.73*60),scale=.80,alpha=.75,drift=.5,lift=1},
    {x=6.9,height=38.3,kind="flame",frames=64,frameHeight=32,speed=.55*64/(.81*60),scale=.80,alpha=.80,drift=.5,lift=1.1},
    {x=0,height=52.6,kind="flame",frames=64,frameHeight=32,speed=.55*64/(.59*60),scale=.65,alpha=.70,drift=.4,lift=.8},
    {x=-7,height=6,kind="smoke",frames=64,frameHeight=64,speed=64/(1.6*60),scale=.40,alpha=.22,drift=-4,lift=9,smoke=true,cycleMs=1600},
    {x=7,height=7,kind="smoke",frames=64,frameHeight=64,speed=64/(1.85*60),scale=.40,alpha=.18,drift=4,lift=10,smoke=true,cycleMs=1850},
}

A.tauntLayout={
    {kind="flame",x=-6,height=31,scale=1.25,frameHeight=32,drift=-12,lift=18,alpha=.46,speed=.95},
    {kind="flame",x=6,height=38,scale=1.30,frameHeight=32,drift=12,lift=20,alpha=.42,speed=.85},
    {kind="flame",x=0,height=48,scale=1.05,frameHeight=32,drift=2,lift=16,alpha=.36,speed=1.05},
    {kind="smoke",x=-9,height=16,scale=.64,frameHeight=64,drift=-16,lift=18,alpha=.25,speed=.70},
    {kind="smoke",x=9,height=20,scale=.62,frameHeight=64,drift=16,lift=20,alpha=.23,speed=.65},
    {kind="smoke",x=0,height=37,scale=.58,frameHeight=64,drift=-3,lift=23,alpha=.20,speed=.75},
}
function A.makeTaunt()
    local f=A.makeBurst(A.tauntLayout,A.flashMs)
    if not A.tauntColor then A.tauntColor=ColorInfo.new(.28,.62,1,1)end
    f.color=A.tauntColor;return f
end
function A.drawTaunt(p,f,s)A.drawFlash(p,f)end
A.activationLayout={
    {kind="flame",x=-8,height=26,scale=1.40,frameHeight=32,drift=-14,lift=25,alpha=.48,speed=.95},
    {kind="flame",x=8,height=36,scale=1.35,frameHeight=32,drift=14,lift=24,alpha=.44,speed=.85},
    {kind="flame",x=0,height=49,scale=1.10,frameHeight=32,drift=2,lift=19,alpha=.38,speed=1.05},
    {kind="smoke",x=-10,height=5,scale=.78,frameHeight=64,drift=-19,lift=15,alpha=.32,speed=.70},
    {kind="smoke",x=10,height=5,scale=.78,frameHeight=64,drift=19,lift=17,alpha=.30,speed=.65},
    {kind="smoke",x=0,height=17,scale=.72,frameHeight=64,drift=-2,lift=25,alpha=.24,speed=.75},
}
function A.releaseBurst(f)
    if f then for _,e in ipairs(f.emitters or {}) do e.instance:Dispose();IsoSpriteInstance.add(e.instance) end end
end
function A.releaseFlash(p)
    A.releaseBurst(A.flashes[p]);A.flashes[p]=nil
end
function A.makeBurst(layout,duration)
    local f={remaining=duration,duration=duration,last=getTimestampMs(),emitters={}}
    A.burstSprites=A.burstSprites or {};local tile=Core.getTileScale()
    for _,point in ipairs(layout) do
        local key=point.source or point.kind;local sprite=A.burstSprites[key]
        if not sprite then
            sprite=IsoSprite.CreateSprite(nil)
            if point.source then sprite:LoadFramesNoDirPageSimple(point.source)else sprite:LoadFramesNoDirPageDirect("media/textures/ProjectYakuza/ExtremeHeat",point.kind,point.frames or 64)end
            sprite:setAnimate(not point.source);A.burstSprites[key]=sprite
        end
        local scale=tile*point.scale
        local instance=ProjectYakuza.WorldEffects.detached(sprite,scale,point.speed or (point.frames or 64)/((duration/1000)*60))
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
    A.flashes[player]=A.makeTaunt()
    if A.states[player].extreme then A.flashes[player].color=A.extremeColor end
end
A.entryLayout={
    {kind="flame",x=-7,height=30,scale=1.20,frameHeight=32,drift=-13,lift=20,alpha=.44,speed=.95},
    {kind="flame",x=7,height=39,scale=1.25,frameHeight=32,drift=13,lift=21,alpha=.40,speed=.85},
    {kind="flame",x=0,height=49,scale=1.00,frameHeight=32,drift=1,lift=15,alpha=.34,speed=1.05},
    {kind="smoke",x=-9,height=5,scale=.68,frameHeight=64,drift=-17,lift=15,alpha=.28,speed=.70},
    {kind="smoke",x=9,height=6,scale=.68,frameHeight=64,drift=17,lift=17,alpha=.26,speed=.65},
    {kind="smoke",x=0,height=26,scale=.58,frameHeight=64,drift=-2,lift=22,alpha=.20,speed=.75},
}
function A.entry(player)
    A.releaseFlash(player)
    A.flashes[player]={remaining=380,duration=380,last=getTimestampMs(),emitters={}}
    A.update(player)
    local state=A.states[player];if not state or not state.fadeElapsed then return end
    if not A.entryColor then A.entryColor=ColorInfo.new(.28,.62,1,1)end
    A.releaseBurst(state.entryBurst);state.entryBurst=A.makeBurst(A.entryLayout,380);state.entryBurst.color=state.extreme and A.extremeColor or A.entryColor
end
function A.drawFlash(p,f)
    local t=math.max(0,math.min(1,1-f.remaining/f.duration));local tile=Core.getTileScale()
    local fade=math.sin(math.pi*t)
    for _,e in ipairs(f.emitters) do
        local point=e.point;local alpha=point.alpha*fade
        local scale=tile*point.scale*(.75+.55*t)
        e.instance:setScale(scale,scale)
        e.instance:SetAlpha(alpha);e.instance:SetTargetAlpha(alpha)
        if not isGamePaused() then e.sprite:update(e.instance) end
        ProjectYakuza.WorldEffects.renderCentered(p,e.instance,point.frameHeight,scale,
            (point.x+point.drift*t)*tile,(-point.height-point.lift*t)*tile,
            f.color or A.extremeColor)
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
function A.draw(p,s)
    local tile=Core.getTileScale()
    local color=s.extreme and A.extremeColor or A.color
    local x,y,z=p:getX(),p:getY(),p:getZ()
    local offsetX,offsetY=p:getOffsetX()+tile,p:getOffsetY()-89*tile
    local paused=isGamePaused()
    for _,e in ipairs(s.emitters) do
        if e.instance and e.instance:getParentSprite()==e.sprite then
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
            if not paused and e.frames>1 then e.sprite:update(e.instance) end
            if e.opacity~=alpha then e.instance:SetAlpha(alpha);e.instance:SetTargetAlpha(alpha);e.opacity=alpha end
            e.instance:render(p,x,y,z,IsoDirections.N,
                offsetX+dx*tile,offsetY-dy*tile,e.point.smoke and A.smokeColor or color)
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
            if s.entryBurst and not A.advanceBurst(s.entryBurst,time)then A.releaseBurst(s.entryBurst);s.entryBurst=nil end
            if not isGamePaused() then
                s.clock=s.clock+elapsed;s.fadeElapsed=math.min(A.fadeInMs,s.fadeElapsed+elapsed)
            end
            local fraction=s.fadeElapsed/A.fadeInMs;s.opacity=fraction*fraction*(3-2*fraction)
            if not s.flashing and not s.entryBurst and not s.extreme and ProjectYakuza.Heat.stocks(p)<1 then A.clear(p)
            else
                if ProjectYakuza.HeatOutline then ProjectYakuza.HeatOutline.draw(p) end
                if s.extreme or ProjectYakuza.Heat.stocks(p)>=1 then A.draw(p,s) end
                if s.activationBurst then A.drawFlash(p,s.activationBurst) end
                if s.entryBurst then A.drawFlash(p,s.entryBurst)end
                if flash then
                    A.drawTaunt(p,flash,s)

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
    if not s or (s.fadeElapsed==nil and not s.activationBurst and not s.activating) then return end
    A.releaseBurst(s.activationBurst);s.activationBurst=nil;s.activating=false
    A.releaseBurst(s.entryBurst);s.entryBurst=nil
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
        A.releaseBurst(s.activationBurst);s.activationBurst=A.makeBurst(A.activationLayout,1000)
    elseif not s.extreme and s.activationBurst then A.releaseBurst(s.activationBurst);s.activationBurst=nil end
    if ProjectYakuza.HeatOutline then
        ProjectYakuza.HeatOutline.update(player,s.extreme)
        ProjectYakuza.HeatOutline.draw(player)
    end
    local profile=s.extreme and "extreme" or "normal"
    local fresh=not s.emitters[1] or not s.emitters[1].instance
    local changed=fresh or s.profile~=profile
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
        table.remove(s.emitters,i);changed=true
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

            player:getAttachedAnimSprite():remove(e.instance)
            local opacity=s.opacity*(s.extreme and point.alpha or 1)
            e.instance:SetAlpha(opacity);e.instance:SetTargetAlpha(opacity);e.opacity=opacity
        end
    end
    if changed then A.syncRenderHook() end
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
ProjectYakuza.on("styleEntryStarted",A.entry)
ProjectYakuza.on("tauntStopped",function(p,completed)if completed then A.flash(p) end end)
Events.OnSave.Add(A.clearAll)
Events.OnMainMenuEnter.Add(A.clearAll)
