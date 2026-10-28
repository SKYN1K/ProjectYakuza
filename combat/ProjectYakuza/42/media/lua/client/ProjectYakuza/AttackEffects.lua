require "ProjectYakuza/Runtime"
require "ProjectYakuza/WorldEffects"
require "ProjectYakuza/AttackTracks"
local PY=ProjectYakuza
local F={states=setmetatable({}, {__mode="k"}),maxActors=8}
PY.AttackEffects=F
local function valid(p,s)
    local style=PY.getPlayerStyle(p)
    return not p:isDead() and PY.isEquipped(p) and style and style.id==s.style
        and not p:getModData().ProjectYakuzaHitEffectsDisabled
        and not p:isOnFloor() and p:getHitReaction()==""
end
-- These scalar debug accessors are exposed in B42; their returned bone/track objects are not.
-- Search a bounded set once, then use the cached layer/slot until the clip changes.
function F.findTrack(p,animation,cached)
    if cached and p:dbgGetAnimTrackName(cached.layer,cached.slot)==animation then
        return p:dbgGetAnimTrackTime(cached.layer,cached.slot),p:dbgGetAnimTrackWeight(cached.layer,cached.slot),cached
    end
    local bestTime,bestWeight,bestLocation
    for layer=0,3 do
        for slot=0,7 do
            local name=p:dbgGetAnimTrackName(layer,slot)
            if not name or name=="" then break end
            if name==animation then
                local time=p:dbgGetAnimTrackTime(layer,slot);local weight=p:dbgGetAnimTrackWeight(layer,slot)
                if weight>=.05 and (not bestTime or time<bestTime) then
                    bestTime=time;bestWeight=weight;bestLocation={layer=layer,slot=slot}
                end
            end
        end
    end
    return bestTime,bestWeight,bestLocation
end
function F.sample(track,time,bone)
    local frame=math.max(0,math.min(#track.frames-1,time*track.fps))
    local index=math.floor(frame);local fraction=frame-index
    local a=track.frames[index+1];local b=track.frames[math.min(index+2,#track.frames)]
    local offset=(bone-1)*3
    return a[offset+1]+(b[offset+1]-a[offset+1])*fraction,
        a[offset+2]+(b[offset+2]-a[offset+2])*fraction,
        a[offset+3]+(b[offset+3]-a[offset+3])*fraction
end
-- B42 Model.vectorToWorldCoords, including getRenderedAngle's +pi/2 and native scale.
function F.project(x,y,z,angle,tile)
    local a=angle+math.pi/2;local c,s=math.cos(a),math.sin(a)
    local wx=(-x*c-z*s)*1.5;local wy=(-x*s+z*c)*1.5
    return (wx-wy)*32*tile,(wx+wy)*16*tile-y*.61237234*96*tile
end
function F.clear(p)
    local s=F.states[p];if not s then return end
    for _,point in ipairs(s.points or {}) do point.instance:Dispose();IsoSpriteInstance.add(point.instance) end
    F.states[p]=nil
    local any=false;for _ in pairs(F.states) do any=true;break end
    if not any and F.hooked then
        Events.OnTick.Remove(F.tick);Events.OnPostRender.Remove(F.render);F.hooked=false
    end
end
function F.clearAll()
    for p in pairs(F.states) do F.clear(p) end
end
function F.start(p,style,step,move)
    F.clear(p)
    local config=move and move.attackEffects
    local track=config and PY.AttackTracks[config.track]
    if not track or track.animation~=move.animation then return end
    local count=0;for _ in pairs(F.states) do count=count+1 end
    if count>=F.maxActors then return end
    local s={style=style.id,track=track,config=config,clock=0,last=getTimestampMs()}
    if not valid(p,s) then return end
    F.states[p]=s
    if not F.hooked then Events.OnTick.Add(F.tick);Events.OnPostRender.Add(F.render);F.hooked=true end
end
function F.remote(p,style,packet)
    local move=style and style.lightAttacks and style.lightAttacks[1]
    if move and packet.clip==move.animation then F.start(p,style,1,move) else F.clear(p) end
end
function F.tick()
    local now=getTimestampMs();local paused=isGamePaused()
    for p,s in pairs(F.states) do
        local dt=math.max(0,now-s.last);s.last=now
        if not paused then s.clock=s.clock+dt end
        if not valid(p,s) or s.clock>1200 then F.clear(p)
        elseif not paused then
            local time,weight,location=F.findTrack(p,s.track.animation,s.location)
            s.location=location
            if time and weight>=.05 then
                if s.seen and time+0.02<(s.time or 0) then F.clear(p)
                elseif time>s.config.to+.12 then
                    if s.seen or s.clock>350 then F.clear(p) else s.location=nil end
                else s.time=time;s.weight=weight;s.seen=true end
            elseif s.seen or s.clock>350 then F.clear(p) end
        end
    end
end
local function sprite(path)
    local result=IsoSprite.CreateSprite(nil);result:LoadFramesNoDirPageSimple(path);return result
end
local function allocate(p,s)
    if not F.glint then
        F.glint=sprite("media/textures/ProjectYakuza/HitGlint.png")
        F.spark=sprite("media/textures/ProjectYakuza/ChargeSpark.png")
        F.flame=IsoSprite.CreateSprite(nil)
        F.flame:LoadFramesNoDirPageDirect("media/textures/ProjectYakuza/ExtremeHeat","flame",64);F.flame:setAnimate(true)
    end
    local tile=Core.getTileScale();s.points={}
    for i=1,10 do
        local sp=i==4 and F.flame or i>=8 and F.spark or F.glint
        local height=(i==4 or i>=8) and 32 or 64
        local scale=(i==1 and .16 or i==4 and .24 or i>=8 and .22 or .075)*tile
        local instance=PY.WorldEffects.attach(p,sp,height,scale,0,true,i==4 and .8 or 0)
        p:getAttachedAnimSprite():remove(instance)
        s.points[i]={instance=instance,height=height,scale=scale}
    end
end
local function drawPoint(p,point,x,y,alpha,color)
    point.instance:SetAlpha(alpha);point.instance:SetTargetAlpha(alpha)
    point.instance:render(p,p:getX(),p:getY(),p:getZ(),IsoDirections.N,
        p:getOffsetX()+Core.getTileScale()-x,p:getOffsetY()-89*Core.getTileScale()-y,color)
end
function F.draw()
    local tile=Core.getTileScale()
    if not F.normal then F.normal=ColorInfo.new(.18,.52,1,1);F.extreme=ColorInfo.new(.38,.24,1,1) end
    for p,s in pairs(F.states) do
        local time=s.time
        if time and time>=s.config.from and time<=s.config.to+.12 then
            if not s.points then allocate(p,s) end
            local angle=p:getAnimAngleRadians()
            local extreme=PY.Heat.isExtreme(p);local color=extreme and F.extreme or F.normal
            local fade=math.min(1,(time-s.config.from)/.035,math.max(0,(s.config.to+.06-time)/.06))*math.min(1,s.weight)
            local strength=extreme and .80 or .52
            local wx,wy,wz=F.sample(s.track,time,2);local kx,ky,kz=F.sample(s.track,time,3)
            local hx,hy=F.project(wx+(kx-wx)*.6,wy+(ky-wy)*.6,wz+(kz-wz)*.6,angle,tile)
            drawPoint(p,s.points[1],hx,hy,fade*strength,color)
            local ax,ay,az=F.sample(s.track,time,1)
            for i=2,3 do
                local t=(i==2 and .55 or .85)
                local x,y=F.project(ax+(wx-ax)*t,ay+(wy-ay)*t,az+(wz-az)*t,angle,tile)
                drawPoint(p,s.points[i],x,y,fade*strength*.5,color)
            end
            if not isGamePaused() then F.flame:update(s.points[4].instance) end
            drawPoint(p,s.points[4],hx,hy,fade*strength*.7,color)
            for i=5,7 do
                local lag=(i-4)*.018;local x,y,z=F.sample(s.track,math.max(s.config.from,time-lag),3)
                local dx,dy=F.project(x,y,z,angle,tile)
                drawPoint(p,s.points[i],dx,dy,fade*strength*(8-i)*.14,color)
            end
            for i=8,10 do
                local point=s.points[i];local birth=(i-4)/30;local age=time-birth
                if age>=0 and age<.12 then
                    if not point.x then
                        local x,y,z=F.sample(s.track,birth,3)
                        point.x,point.y=F.project(x,y,z,angle,tile);point.px=p:getX();point.py=p:getY();point.pz=p:getZ()
                    end
                    local t=age/.12;local dx=p:getX()-point.px;local dy=p:getY()-point.py;local dz=p:getZ()-point.pz
                    local x=point.x-(dx-dy)*32*tile+(i-9)*9*t*tile
                    local y=point.y-(dx+dy)*16*tile+dz*96*tile-(5+(i-8)*3)*t*tile
                    drawPoint(p,point,x,y,(1-t)*strength,color)
                end
            end
        end
    end
end
function F.render()
    local renderer=SpriteRenderer.instance;local previous=renderer:getDoAdditive();renderer:setDoAdditive(false)
    local ok,err=pcall(F.draw);renderer:setDoAdditive(previous)
    if not ok then F.clearAll();error(err) end
end
PY.on("lightAttackStarted",F.start)
PY.on("lightAttackFinished",F.clear)
PY.on("comboCancelled",F.clear)
PY.on("styleChanged",F.clear)
PY.on("finisherStarted",F.clear)
PY.on("runningAttackStarted",F.clear)
PY.on("quickstepAttackStarted",F.clear)
PY.on("chargedHeavyStarted",F.clear)
PY.on("groundAttackStarted",F.clear)
Events.OnSave.Add(F.clearAll)
Events.OnMainMenuEnter.Add(F.clearAll)
Events.OnGameStart.Add(F.clearAll)
