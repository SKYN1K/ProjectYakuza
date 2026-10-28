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
    for i=1,18 do
        local sp=(i==7 or i==8) and F.flame or i>=13 and F.spark or F.glint
        local height=(i==7 or i==8 or i>=13) and 32 or 64
        local scale=(i==6 and .12 or i==7 and .22 or i==8 and .27 or i>=13 and .20 or .075)*tile
        local instance=PY.WorldEffects.detached(sp,scale,(i==7 and 1 or i==8 and .85 or 0))
        s.points[i]={instance=instance,height=height,scale=scale}
    end
end
local function drawPoint(p,point,x,y,alpha,color)
    point.instance:SetAlpha(alpha);point.instance:SetTargetAlpha(alpha)
    PY.WorldEffects.renderCentered(p,point.instance,point.height,point.scale,x,y,color)
end
local function hand(track,time)
    local wx,wy,wz=F.sample(track,time,2);local kx,ky,kz=F.sample(track,time,3)
    return wx+(kx-wx)*.35,wy+(ky-wy)*.35,wz+(kz-wz)*.35
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
            local strength=extreme and .80 or .60
            local wx,wy,wz=F.sample(s.track,time,2);local ax,ay,az=F.sample(s.track,time,1)
            local fx,fy,fz=hand(s.track,time)
            local hx,hy=F.project(fx,fy,fz,angle,tile)
            -- Six overlapping centres lie within the elbow-to-fist path.
            for i=1,6 do
                local x,y
                if i==6 then x,y=hx,hy
                else local t=i*.2;x,y=F.project(ax+(wx-ax)*t,ay+(wy-ay)*t,az+(wz-az)*t,angle,tile) end
                drawPoint(p,s.points[i],x,y,fade*strength*(i==6 and 1 or .65),color)
            end
            for i=7,8 do
                if not isGamePaused() then F.flame:update(s.points[i].instance) end
                local x,y=hx,hy
                if i==7 then x,y=F.project(ax+(wx-ax)*.65,ay+(wy-ay)*.65,az+(wz-az)*.65,angle,tile) end
                drawPoint(p,s.points[i],x,y,fade*strength*.8,color)
            end
            for i=9,12 do
                local lag=(i-8)*.022;local x,y,z=hand(s.track,math.max(s.config.from,time-lag))
                local dx,dy=F.project(x,y,z,angle,tile)
                drawPoint(p,s.points[i],dx,dy,fade*strength*(13-i)*.10,color)
            end
            for i=13,18 do
                local point=s.points[i];local birth=(i-10)/30;local age=time-birth
                if age>=0 and age<.18 then
                    if not point.x then
                        local x,y,z=hand(s.track,birth)
                        point.x,point.y=F.project(x,y,z,angle,tile);point.px=p:getX();point.py=p:getY();point.pz=p:getZ()
                    end
                    local t=age/.18;local dx=p:getX()-point.px;local dy=p:getY()-point.py;local dz=p:getZ()-point.pz
                    local x=point.x-(dx-dy)*32*tile+((i-13)%3-1)*6*t*tile
                    local y=point.y-(dx+dy)*16*tile+dz*96*tile-(4+(i-13)*1.1)*t*tile
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
