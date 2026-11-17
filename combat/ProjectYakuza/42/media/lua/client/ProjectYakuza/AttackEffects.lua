require "ProjectYakuza/Runtime"
require "ProjectYakuza/WorldEffects"
require "ProjectYakuza/AttackTracks"
require "ProjectYakuza/AttackTrailCatalog"
local PY=ProjectYakuza
local F={states=setmetatable({}, {__mode="k"}),maxActors=8,maxTails=8,pointCount=30,historySize=24,trailMs=120,tails={},bursts={},maxBursts=16,serial=0}
PY.AttackEffects=F
local function valid(p,s)
    local style=PY.getPlayerStyle(p)
    return not p:isDead() and PY.isEquipped(p) and style and style.id==s.style
        and not p:getModData().ProjectYakuzaHitEffectsDisabled
        and not p:isOnFloor() and p:getHitReaction()==""
end

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
    if bone==4 and track.upperFrames then
        local a=track.upperFrames[index+1];local b=track.upperFrames[math.min(index+2,#track.upperFrames)]
        return a[1]+(b[1]-a[1])*fraction,a[2]+(b[2]-a[2])*fraction,a[3]+(b[3]-a[3])*fraction
    end
    local a=track.frames[index+1];local b=track.frames[math.min(index+2,#track.frames)]
    local offset=(bone-1)*3
    return a[offset+1]+(b[offset+1]-a[offset+1])*fraction,
        a[offset+2]+(b[offset+2]-a[offset+2])*fraction,
        a[offset+3]+(b[offset+3]-a[offset+3])*fraction
end

function F.project(x,y,z,angle,tile)
    local a=angle+math.pi/2;local c,s=math.cos(a),math.sin(a)
    local wx=(-x*c-z*s)*1.5;local wy=(-x*s+z*c)*1.5
    local wz=y*.61237234
    return (wx-wy)*32*tile,(wx+wy)*16*tile-wz*96*tile,wx,wy,wz
end

F.limbProviders={}
function F.registerLimbProvider(id,fn)
    assert(type(id)=="string" and id~="" and type(fn)=="function","limb provider requires ID and function")
    assert(not F.limbProviders[id] or F.limbProviders[id]==fn,"limb provider already registered")
    F.limbProviders[id]=fn
end
function F.removeLimbProvider(id,fn)
    if F.limbProviders[id] and (not fn or F.limbProviders[id]==fn) then F.limbProviders[id]=nil;return true end
    return false
end
function F.pose(p,s,time)
    local provider=F.limbProviders[s.config.limbProvider or "live"]
    if not provider or s.providerRetry and getTimestampMs()<s.providerRetry then return nil end
    local ok,x,y,z,hx,hy,hz,ux,uy,uz=pcall(provider,p,s.track.animation,time,s.track.limb)
    local values={x,y,z,hx,hy,hz,ux,uy,uz}
    for i=1,(ux~=nil or uy~=nil or uz~=nil)and 9 or 6 do local v=values[i]
        if not ok or type(v)~="number" or v~=v or math.abs(v)>10000000 then s.providerRetry=getTimestampMs()+1000;return nil end
    end
    return values
end
function F.sampleLimb(track,time,bone,pose)
    if pose then local i=(bone-1)*3;return pose[i+1],pose[i+2],pose[i+3] end
    return F.sample(track,time,bone)
end
function F.projectLimb(p,x,y,z,angle,tile,pose)
    if pose then
        local dx,dy,dz=x-p:getX(),y-p:getY(),z-p:getZ()
        return (dx-dy)*32*tile,(dx+dy)*16*tile-dz*96*tile,dx,dy,dz
    end
    return F.project(x,y,z,angle,tile)
end
function F.facing(p)

    return p:getAnimAngleRadians()
end
function F.dispose(s,tailOnly)
    for i,point in ipairs(s.points or {})do
        if point.instance and(not tailOnly or i<15 or i>26)then point.instance:Dispose();IsoSpriteInstance.add(point.instance);point.instance=nil end
    end
end
function F.syncHook()
    local any=#F.tails>0 or #F.bursts>0;for _ in pairs(F.states)do any=true;break end
    if any and not F.hooked then Events.OnTick.Add(F.tick);Events.OnPostRender.Add(F.render);F.hooked=true
    elseif not any and F.hooked then Events.OnTick.Remove(F.tick);Events.OnPostRender.Remove(F.render);F.hooked=false end
end
function F.clear(p)
    local s=F.states[p];if s then F.dispose(s);F.states[p]=nil end
    for i=#F.tails,1,-1 do if F.tails[i].owner==p then F.dispose(F.tails[i]);table.remove(F.tails,i)end end
    for i=#F.bursts,1,-1 do if F.bursts[i].owner==p then F.dispose(F.bursts[i]);table.remove(F.bursts,i)end end
    F.syncHook()
end
function F.finish(p)
    local s=F.states[p];if not s then return end;F.states[p]=nil
    local now=getTimestampMs();if not isGamePaused()then s.clock=s.clock+math.max(0,now-s.last)end;s.last=now
    if s.lastEmission and s.clock-s.lastEmission<F.trailMs and valid(p,s)then
        if #F.tails>=F.maxTails then F.dispose(F.tails[1]);table.remove(F.tails,1)end
        F.dispose(s,true);s.owner=p;s.last=getTimestampMs();F.tails[#F.tails+1]=s
    else F.dispose(s)end
    F.syncHook()
end
function F.clearAll()
    for _,s in pairs(F.states)do F.dispose(s)end
    for _,s in ipairs(F.tails)do F.dispose(s)end
    for _,s in ipairs(F.bursts)do F.dispose(s)end
    F.states=setmetatable({}, {__mode="k"});F.tails={};F.bursts={};F.syncHook()
end
function F.configuration(style,move)
    if not move then return end
    local catalog=style and PY.AttackEffectCatalog and PY.AttackEffectCatalog[style.id]
    return move.attackEffects or catalog and catalog[move.animation]
end
function F.start(p,style,step,move,stamp)
    local old=F.states[p]
    if stamp and old and old.stamp==stamp and old.family==move.animation then return end
    F.finish(p)
    local config=F.configuration(style,move)
    local track=config and PY.AttackTracks[config.track]
    if not track or track.animation~=move.animation then return end
    local count=0;for _ in pairs(F.states) do count=count+1 end
    if count>=F.maxActors then return end
    local seed=p.getOnlineID and p:getOnlineID()or 0
    local s={style=style.id,track=track,config=config,baseConfig=config,family=move.animation,move=move,stamp=stamp,seed=seed%97,timeout=math.max(1200,(config.duration or (#track.frames-1)/track.fps)*2000+500),chaos=type(config.chaos)=="number"and math.max(0,math.min(1,config.chaos))or .65,clock=0,last=getTimestampMs(),history={},historyHead=0,historyCount=0,joints={},scratch={}}
    for i=1,F.historySize do s.history[i]={}end
    if not valid(p,s) then return end
    F.states[p]=s
    if not F.hooked then Events.OnTick.Add(F.tick);Events.OnPostRender.Add(F.render);F.hooked=true end
end
function F.remote(p,style,packet)
    local animation=packet.clip
    if style and PY.NetworkProtocol then local clip=PY.NetworkProtocol.clip(style.id,packet.clip);animation=clip and clip.animation or animation end
    local catalog=style and PY.AttackEffectCatalog and PY.AttackEffectCatalog[style.id]
    local config=catalog and catalog[animation]
    local stamp=tostring(packet.action or 0)..":"..tostring(packet.swing or 0)..":"..tostring(animation)
    for i,move in ipairs(style and style.lightAttacks or {})do
        if move.attackEffects and animation==move.animation then F.start(p,style,i,move,stamp);return end
    end
    if config then F.start(p,style,0,{animation=config.actionAnimation or animation},stamp)else F.finish(p)end
end
function F.paired(p,source,move,clip,time,weight,contacts)
    local style=PY.getPlayerStyle(p);local catalog=style and PY.AttackEffectCatalog and PY.AttackEffectCatalog[style.id]
    local config=catalog and catalog[clip]
    if not config then F.endPaired(p,source);return end
    local s=F.states[p]
    if not s or s.heatSource~=source or s.track.animation~=clip then
        F.start(p,style,0,{animation=clip})
        s=F.states[p];if not s then return end
        s.heatSource=source;s.external=true;s.family=clip;s.timeout=math.max(s.timeout,(move.duration or config.duration)*4000+5000)
    end
    s.contactMask=contacts;s.externalAt=getTimestampMs()
    local native,nativeWeight,location=F.findTrack(p,clip,s.location)
    s.time=native or time;s.weight=nativeWeight or weight;s.location=location;s.seen=true
end
function F.endPaired(p,source,complete)
    local s=F.states[p];if not s or not s.external or source and s.heatSource~=source then return end
    if complete then F.finish(p)else F.clear(p)end
end
function F.playing(p,s)
    local now=getTimestampMs()
    if s.location and now<(s.nextResolve or 0)then
        local time,weight,location=F.findTrack(p,s.track.animation,s.location)
        if location then return time,weight,location end
    end
    s.nextResolve=now+100
    local catalog=PY.AttackEffectCatalog and PY.AttackEffectCatalog[s.style]
    local bestTime,bestWeight,bestLocation,bestConfig
    for layer=0,3 do for slot=0,7 do
        local name=p:dbgGetAnimTrackName(layer,slot);if not name or name==""then break end
        local config=name==s.family and s.baseConfig or catalog and catalog[name]
        local track=config and PY.AttackTracks[config.track]
        if track and track.animation==name and(name==s.family or config.actionAnimation==s.family)then
            local time=p:dbgGetAnimTrackTime(layer,slot);local weight=p:dbgGetAnimTrackWeight(layer,slot)
            if weight>=.05 and(not bestWeight or weight>bestWeight or weight==bestWeight and time<bestTime)then bestTime=time;bestWeight=weight;bestLocation={layer=layer,slot=slot};bestConfig=config end
        end
    end end
    if bestConfig and bestConfig~=s.config then
        s.config=bestConfig;s.track=PY.AttackTracks[bestConfig.track];s.windowRef=nil;s.historyCount=0;s.recordedAt=nil;s.lastEmission=nil;s.time=nil;s.seen=false
    end
    return bestTime,bestWeight,bestLocation
end
function F.window(s,time)
    if not s.config.windows then return s.config end
    for _,window in ipairs(s.config.windows)do if time>=window.from and time<=window.to and(not s.contactMask or s.contactMask[window.index])then return window end end
end

function F.tick()
    local now=getTimestampMs();local paused=isGamePaused()
    for p,s in pairs(F.states) do
        local dt=math.max(0,now-s.last);s.last=now
        if not paused then s.clock=s.clock+dt end
        if not valid(p,s) or s.clock>s.timeout then F.clear(p)
        elseif s.external then
            if not paused and now-s.externalAt>1500 then F.clear(p)end
        elseif not paused then
            local time,weight,location=F.playing(p,s)
            s.location=location
            if time and weight>=.05 then
                if s.seen and time+0.02<(s.time or 0) then s.historyCount=0;s.recordedAt=nil;s.lastEmission=nil;s.time=time
                elseif time>s.config.to+.12 then
                    if s.seen then F.finish(p)elseif s.clock>350 then F.clear(p) else s.location=nil end
                else s.time=time;s.weight=weight;s.seen=true end
            elseif s.seen then F.finish(p)elseif s.clock>350 then F.clear(p) end
        end
    end
end
local corePositions={.25,.62,1}
local trailPositions={.5,.75,1}
local function sprite(path)
    local result=IsoSprite.CreateSprite(nil);result:LoadFramesNoDirPageSimple(path);return result
end
local function allocate(s)
    if not F.glint then
        F.glint=sprite("media/textures/ProjectYakuza/HitGlint.png")
        F.spark=sprite("media/textures/ProjectYakuza/ChargeSpark.png")
        F.wispA=sprite("media/textures/ProjectYakuza/AttackFX/e_j_0073_aura_cA8L8.png")
        F.wispB=sprite("media/textures/ProjectYakuza/AttackFX/e_j_0073_aura_dA8L8.png")
        F.flame=IsoSprite.CreateSprite(nil)
        F.flame:LoadFramesNoDirPageDirect("media/textures/ProjectYakuza/ExtremeHeat","flame",64);F.flame:setAnimate(true)
    end
    local tile=Core.getTileScale();s.points={}
    for i=1,F.pointCount do
        local flame=i<=11 or i>=15 and i<=26
        local sp=flame and F.flame or i>=27 and F.spark or i==12 and F.wispA or i==13 and F.wispB or F.glint
        local scale=(i<=11 and .44 or i==14 and .18 or i<=14 and .13 or i<=26 and .35 or .16)*tile
        local instance=PY.WorldEffects.detached(sp,scale,flame and .72 or 0)
        s.points[i]={instance=instance,height=(flame or i>=27)and 32 or i<=13 and 128 or 64,scale=scale}
    end
end
function F.armPoint(joints,t)
    local ax,ay,az=joints[1],joints[2],joints[3]
    local ex,ey,ez=joints[4],joints[5],joints[6]
    local hx,hy,hz=joints[7],joints[8],joints[9]
    local first=math.sqrt((ex-ax)^2+(ey-ay)^2+(ez-az)^2)
    local second=math.sqrt((hx-ex)^2+(hy-ey)^2+(hz-ez)^2)
    local distance=math.max(0,math.min(1,t))*(first+second)
    if distance<=first and first>.000001 then local k=distance/first;return ax+(ex-ax)*k,ay+(ey-ay)*k,az+(ez-az)*k end
    if second>.000001 then local k=(distance-first)/second;return ex+(hx-ex)*k,ey+(hy-ey)*k,ez+(hz-ez)*k end
    return hx,hy,hz
end
function F.worldJoints(p,s,time,pose)
    local angle=F.facing(p);local x,y,z=p:getX(),p:getY(),p:getZ()
    local ex,ey,ez=F.sample(s.track,time,1)
    local hx,hy,hz=F.sample(s.track,time,2)
    local kx,ky,kz=F.sample(s.track,time,3)
    local ux,uy,uz=ex,ey,ez
    if s.track.upperFrames then ux,uy,uz=F.sample(s.track,time,4)end
    local _,_,uwx,uwy,uwz=F.project(ux,uy,uz,angle,1)
    local _,_,ewx,ewy,ewz=F.project(ex,ey,ez,angle,1)
    local _,_,hwx,hwy,hwz=F.project(hx+(kx-hx)*.35,hy+(ky-hy)*.35,hz+(kz-hz)*.35,angle,1)
    local j=s.joints
    if pose then
        j[1],j[2],j[3]=pose[7]or pose[1]+uwx-ewx,pose[8]or pose[2]+uwy-ewy,pose[9]or pose[3]+uwz-ewz
        j[4],j[5],j[6]=pose[1],pose[2],pose[3];j[7],j[8],j[9]=pose[4],pose[5],pose[6]
    else
        j[1],j[2],j[3]=x+uwx,y+uwy,z+uwz;j[4],j[5],j[6]=x+ewx,y+ewy,z+ewz;j[7],j[8],j[9]=x+hwx,y+hwy,z+hwz
    end
    if s.rootX and ((s.rootX-x)^2+(s.rootY-y)^2>1 or math.abs(s.rootZ-z)>.5)then s.historyCount=0;s.recordedAt=nil end
    s.rootX,s.rootY,s.rootZ=x,y,z
    return j
end
function F.record(s)
    if s.recordedAt and s.clock-s.recordedAt<8 then return end
    s.historyHead=s.historyHead%F.historySize+1
    local row=s.history[s.historyHead];row.at=s.clock
    for i=1,9 do row[i]=s.joints[i]end
    s.recordedAt=s.clock;s.historyCount=math.min(F.historySize,s.historyCount+1)
end
function F.historyPose(s,target,out)
    local newer
    for age=0,s.historyCount-1 do
        local row=s.history[(s.historyHead-age-1+F.historySize)%F.historySize+1]
        if target>=row.at then
            local k=newer and newer.at>row.at and math.max(0,math.min(1,(target-row.at)/(newer.at-row.at)))or 0
            for i=1,9 do out[i]=newer and row[i]+(newer[i]-row[i])*k or row[i]end
            return true
        end
        newer=row
    end
    return false
end
local function drawPoint(p,s,index,x,y,z,alpha,color)
    if alpha<=.001 then return end
    local point=s.points[index]
    if point.alpha~=alpha then point.instance:SetAlpha(alpha);point.instance:SetTargetAlpha(alpha);point.alpha=alpha end
    point.instance:render(p,x,y,z,IsoDirections.N,0,-point.height*point.scale/2,color)
end
function F.drawHistory(p,s,animate)
    if not s.lastEmission or s.clock-s.lastEmission>=F.trailMs then return end
    for i=15,26 do
        local lag=20+math.floor((i-15)/3)*26;local target=s.clock-lag
        if target<=s.lastEmission and F.historyPose(s,target,s.scratch)then
            local x,y,z=F.armPoint(s.scratch,trailPositions[(i-15)%3+1])
            if animate then F.flame:update(s.points[i].instance)end
            local fade=math.max(0,1-lag/F.trailMs)^1.5*math.max(0,1-(s.clock-s.lastEmission)/F.trailMs)
            drawPoint(p,s,i,x,y,z,.32*fade*(s.lastWeight or 1),s.lastColor)
        end
    end
end
function F.colors()
    if not F.normal then F.normal=ColorInfo.new(.70,.86,1,1);F.extreme=ColorInfo.new(.62,.76,1,1)end
end
function F.hit(p,victim,strong,charged,anchor)
    local style=PY.getPlayerStyle(p)
    if not style or style.hitEffects~="yakuza6" or p:getModData().ProjectYakuzaHitEffectsDisabled or p:isDead()then return end
    local s=F.states[p];local x,y,z
    if s then
        local time,weight,location=F.findTrack(p,s.track.animation,s.location)
        time=time or s.time
        local window=time and F.window(s,time)
        if window then
            s.track=PY.AttackTracks[window.track];s.location=location or s.location
            local joints=F.worldJoints(p,s,time,F.pose(p,s,time));x,y,z=F.armPoint(joints,1)
        end
    end
    if not x then
        if anchor then x,y,z=anchor.x,anchor.y,anchor.z
        elseif victim then x,y,z=victim:getX(),victim:getY(),victim:getZ()+.48
        else return end
    end
    local count=0;for _,b in ipairs(F.bursts)do if b.owner==p then count=count+1 end end
    if #F.bursts>=F.maxBursts or count>=3 then
        for i,b in ipairs(F.bursts)do if count<3 or b.owner==p then F.dispose(b);table.remove(F.bursts,i);break end end
    end
    if not F.streak then
        F.streak=sprite("media/textures/ProjectYakuza/AttackFX/e_j_0361_spark_b.png")
        F.fan=sprite("media/textures/ProjectYakuza/AttackFX/e_j_0332_sparks_a.png")
    end
    F.colors();F.serial=F.serial+1
    local seed=(F.serial*7919+math.floor(getTimestampMs())%65521)%2147483647
    local function random()seed=seed*48271%2147483647;return seed/2147483647 end
    local b={owner=p,style=style.id,x=x,y=y,z=z,last=getTimestampMs(),age=0,life=charged and 290 or strong and 250 or 210,color=PY.Heat.isExtreme(p)and F.extreme or F.normal,points={}}
    local tile=Core.getTileScale();local angle=random()*math.pi*2
    for i=1,7 do
        local scale=(i==7 and .28 or .10+random()*.08)*(strong and 1.18 or 1)*tile
        local instance=PY.WorldEffects.detached(i==7 and F.fan or F.streak,scale,0)
        local turn=angle+i*2.399963+random()*.7;local speed=.35+random()*.65
        b.points[i]={instance=instance,scale=scale,vx=math.cos(turn)*speed,vy=math.sin(turn)*speed,vz=.3+random()*.65,life=.7+random()*.3}
    end
    F.bursts[#F.bursts+1]=b;F.syncHook()
end
function F.drawBursts(now,paused,hidden)
    for i=#F.bursts,1,-1 do
        local b=F.bursts[i];local p=b.owner;local dt=math.max(0,now-b.last);b.last=now
        if not paused then b.age=b.age+dt end
        if b.age>=b.life or not valid(p,b)then F.dispose(b);table.remove(F.bursts,i)
        elseif not hidden then
            local t=b.age/1000
            for n,point in ipairs(b.points)do
                local k=b.age/(b.life*point.life)
                if k<1 then
                    local alpha=(n==7 and .68 or .85)*(1-k)^1.5
                    point.instance:SetAlpha(alpha);point.instance:SetTargetAlpha(alpha)
                    if n==7 then point.instance:render(p,b.x,b.y,b.z,IsoDirections.N,-64*point.scale,0,b.color)
                    else point.instance:render(p,b.x+point.vx*t,b.y+point.vy*t,b.z+point.vz*t-1.4*t*t,IsoDirections.N,0,-48*point.scale,b.color)end
                end
            end
        end
    end
end
function F.draw()
    F.colors()
    local now=getTimestampMs();local paused=isGamePaused()
    local hidden=ISWorldMap_instance and ISWorldMap_instance:isVisible()or false
    for p,s in pairs(F.states)do
        local dt=math.max(0,now-s.last);s.last=now;if not paused then s.clock=s.clock+dt end
        local time=s.time
        if not paused then
            local current,weight,location=F.playing(p,s)
            if current and weight>=.05 and(not time or not s.seen or current>=time-.02)then time=current;s.time=current;s.weight=weight;s.location=location end
        end
        local animate=not paused and s.lastFlameClock~=s.clock
        if not hidden and time and time>=s.config.from and time<=s.config.to+.12 then
            local window=F.window(s,time)
            if window then
                if s.windowRef~=window then s.windowRef=window;s.track=PY.AttackTracks[window.track];s.historyCount=0;s.recordedAt=nil end
                if not s.points then allocate(s)end
                local pose=F.pose(p,s,time);local joints=F.worldJoints(p,s,time,pose)
                if not paused then F.record(s)end
                local extreme=PY.Heat.isExtreme(p);local color=extreme and F.extreme or F.normal
                s.lastEmission=s.clock;s.lastColor=color;s.lastWeight=s.weight
                local fade=math.max(0,math.min(1,(time-window.from)/.04,(window.to+.06-time)/.06))*math.min(1,s.weight)
                for i=1,11 do
                    local t=(i-1)/10;local x,y,z=F.armPoint(joints,t);local envelope=math.sin(t*math.pi)*s.chaos
                    local noise=(math.sin(time*73+i*1.9+s.seed)*.012+math.sin(time*119-i*2.4+s.seed)*.008)*envelope
                    local dx,dy=joints[8]-joints[2],joints[1]-joints[7];local length=math.sqrt(dx*dx+dy*dy)
                    if length>.00001 then x=x+dx/length*noise;y=y+dy/length*noise end
                    z=z+math.sin(time*91+i*2.7+s.seed)*.009*envelope
                    if animate then F.flame:update(s.points[i].instance)end
                    drawPoint(p,s,i,x,y,z,fade*(extreme and .40 or .34)*(.84+.16*math.sin(s.clock*.019+i*1.7+s.seed)),color)
                end
                for i=12,14 do local x,y,z=F.armPoint(joints,corePositions[i-11]);drawPoint(p,s,i,x,y,z,fade*(extreme and .38 or .30)*(.78+.22*math.sin(s.clock*.027+i+s.seed)),color)end
                for i=27,30 do
                    local age=(s.clock+(i-27)*23)%92
                    if F.historyPose(s,s.clock-age,s.scratch)then
                        local x,y,z=F.armPoint(s.scratch,1);local k=age/92;local angle=(i-27)*math.pi/2+s.chaos*math.sin(time*67+i+s.seed)
                        drawPoint(p,s,i,x+math.cos(angle)*(.055+.035*s.chaos)*k,y+math.sin(angle)*(.055+.035*s.chaos)*k,z+(.035+.015*s.chaos)*k,fade*.55*(1-k),color)
                    end
                end
            end
        end
        if s.points and not hidden then F.drawHistory(p,s,animate)end
        if animate then s.lastFlameClock=s.clock end
    end
    for i=#F.tails,1,-1 do
        local s=F.tails[i];local p=s.owner;local dt=math.max(0,now-s.last);s.last=now;if not paused then s.clock=s.clock+dt end
        if not valid(p,s)or s.clock-s.lastEmission>=F.trailMs or (p:getX()-s.rootX)^2+(p:getY()-s.rootY)^2>1 or math.abs(p:getZ()-s.rootZ)>.5 then F.dispose(s);table.remove(F.tails,i)
        else local animate=not paused and s.lastFlameClock~=s.clock;if not hidden then F.drawHistory(p,s,animate)end;if animate then s.lastFlameClock=s.clock end end
    end
    F.drawBursts(now,paused,hidden)
    F.syncHook()
end
function F.render()
    local renderer=SpriteRenderer.instance;local previous=renderer:getDoAdditive();renderer:setDoAdditive(false)
    local ok,err=pcall(F.draw);renderer:setDoAdditive(previous)
    if not ok then F.clearAll();error(err)end
end
function F.committed(p,style,move,stamp)F.start(p,style,0,move,stamp)end
function F.category(p,style,step,move)
    local old=F.states[p]
    if old and old.stamp and old.move==move then return end
    F.start(p,style,step,move)
end
local function special(p,style,move)F.category(p,style,0,move)end
PY.on("attackCommitted",F.committed)
PY.on("lightAttackStarted",F.category)
PY.on("finisherStarted",F.category)
PY.on("runningAttackStarted",special)
PY.on("quickstepAttackStarted",special)
PY.on("chargedHeavyStarted",special)
PY.on("groundAttackStarted",special)
PY.on("throwStarted",function(p)F.start(p,PY.getPlayerStyle(p),0,{animation="ProjectYakuza_DD_Throw"})end)
PY.on("lightAttackFinished",F.finish)
PY.on("finisherFinished",F.finish)
PY.on("runningAttackFinished",F.finish)
PY.on("quickstepAttackFinished",F.finish)
PY.on("chargedHeavyFinished",F.finish)
PY.on("groundAttackFinished",F.finish)
PY.on("comboCancelled",F.clear)
PY.on("styleChanged",F.clear)
PY.on("actionCancelled",function(context)if context and F.states[context.player] and F.states[context.player].stamp==context then F.clear(context.player)end end)
PY.on("actionCompleted",function(context)if context and F.states[context.player] and F.states[context.player].stamp==context then F.finish(context.player)end end)
Events.OnSave.Add(F.clearAll)
Events.OnMainMenuEnter.Add(F.clearAll)
Events.OnGameStart.Add(F.clearAll)
