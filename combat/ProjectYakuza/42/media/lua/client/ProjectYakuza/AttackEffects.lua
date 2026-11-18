require "ProjectYakuza/Runtime"
require "ProjectYakuza/WorldEffects"
require "ProjectYakuza/AttackTracks"
require "ProjectYakuza/AttackTrailCatalog"
require "ProjectYakuza/ParentPosePrediction"
local PY=ProjectYakuza
local F={states=setmetatable({}, {__mode="k"}),maxActors=8,maxTails=8,pointCount=48,historySize=24,trailMs=65,tails={},bursts={},maxBursts=24,maxActorBursts=4,serial=0,outerScale=.29,anchorScale=.17,dropFraction=.10}
PY.AttackEffects=F
local function valid(p,s)
    local style=PY.getPlayerStyle(p)
    return not p:isDead() and PY.isEquipped(p) and style and style.id==s.style
        and not p:getModData().ProjectYakuzaHitEffectsDisabled
        and not p:isOnFloor() and p:getHitReaction()==""
end

function F.findTrack(p,animation,cached)
    if cached and p:dbgGetAnimTrackName(cached.layer,cached.slot)==animation then
        local time,weight=p:dbgGetAnimTrackTime(cached.layer,cached.slot),p:dbgGetAnimTrackWeight(cached.layer,cached.slot)
        if weight>=.98 then return time,weight,cached end
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
function F.attachmentWeight(weight)
    return math.max(0,math.min(1,weight or 0))
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
        if point.instance and(not tailOnly or i<15 or i>38)then point.instance:Dispose();IsoSpriteInstance.add(point.instance);point.instance=nil end
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
    F.serial=F.serial+1
    local seed=((p.getOnlineID and p:getOnlineID()or 0)*97+F.serial*7919+getTimestampMs())%997
    local s={style=style.id,track=track,config=config,baseConfig=config,family=move.animation,move=move,stamp=stamp,seed=seed,timeout=math.max(1200,(config.duration or (#track.frames-1)/track.fps)*2000+500),chaos=type(config.chaos)=="number"and math.max(0,math.min(1,config.chaos))or .85,clock=0,last=getTimestampMs(),history={},historyHead=0,historyCount=0,joints={},scratch={}}
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
            if weight>=.05 and(not bestConfig or config==bestConfig and time<bestTime or config~=bestConfig and(weight>bestWeight or weight==bestWeight and time<bestTime))then bestTime=time;bestWeight=weight;bestLocation={layer=layer,slot=slot};bestConfig=config end
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
local compactTextures=setmetatable({}, {__mode="k"})
local function sprite(path,compact)
    local result=IsoSprite.CreateSprite(nil);result:LoadFramesNoDirPageSimple(path)
    if compact then
        local texture=result:getTextureForFrame(0,IsoDirections.N)
        texture:getHeight();texture:setWidth(65);compactTextures[result]=texture
    end
    return result
end
function F.loadSprites()
    if not F.smoke then
        F.spark=sprite("media/textures/ProjectYakuza/ChargeSpark.png")
        F.gaidenSmoke=sprite("media/textures/ProjectYakuza/AttackFX/e_n_5001_hitsmoke_small.png",true)
        F.smoke=IsoSprite.CreateSprite(nil)
        F.smoke:LoadFramesNoDirPageDirect("media/textures/ProjectYakuza/ExtremeHeat","smoke",64);F.smoke:setAnimate(true)
    end
end
local function allocate(s)
    F.loadSprites()
    local tile=Core.getTileScale();s.points={}
    for i=1,F.pointCount do
        local sp=i<=11 and F.smoke or i<=14 and F.gaidenSmoke or i<=38 and F.smoke or F.spark
        local scale=(i<=11 and .22 or i<=14 and .105 or i<=38 and F.outerScale*(i>26 and 1.22 or 1)or .085)*tile
        local phase=(s.seed+i*17)%64;local speed=(i<=11 and .65 or .43)*(.78+phase/100)
        local animated=i<=11 or i>=15 and i<=38
        local instance=PY.WorldEffects.detached(sp,scale,animated and speed or 0)
        local texture=compactTextures[sp];local widthScale=texture and 64/65 or 1;instance:setScale(scale*widthScale,scale)
        for n=1,phase do if animated then sp:update(instance)end end
        s.points[i]={instance=instance,sprite=sp,texture=texture,widthScale=widthScale,additive=i>=39,animated=animated,height=i>=12 and i<=14 and 128 or i<=38 and 64 or 32,scale=scale,baseScale=scale}
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
    local correction=not pose and PY.ParentPosePrediction.correction(p,s.track.animation,time)
    if correction then
        ux,uy,uz=PY.ParentPosePrediction.point(correction,ux,uy,uz)
        ex,ey,ez=PY.ParentPosePrediction.point(correction,ex,ey,ez)
        hx,hy,hz=PY.ParentPosePrediction.point(correction,hx,hy,hz)
        kx,ky,kz=PY.ParentPosePrediction.point(correction,kx,ky,kz)
    end
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
function F.coatOffset()
    return 64*F.anchorScale*F.dropFraction*Core.getTileScale()
end
local function drawPoint(p,s,index,x,y,z,alpha,color)
    if alpha<=.001 then return end
    local point=s.points[index]
    if point.alpha~=alpha then point.instance:SetAlpha(alpha);point.instance:SetTargetAlpha(alpha);point.alpha=alpha end
    SpriteRenderer.instance:setDoAdditive(point.additive==true)
    point.instance:render(p,x,y,z,IsoDirections.N,0,-point.height*point.scale/2-F.coatOffset(),color)
end
function F.swirl(s,index,t,clock,amount)
    local a=clock*(.017+(index%4)*.004)+s.seed*.71+index*2.399963
    local pulse=.5+.5*math.sin(clock*.031+index*1.73+s.seed)
    local envelope=math.sin(math.max(0,math.min(1,t))*math.pi)
    local radius=(.006+.018*pulse)*s.chaos*envelope*amount
    return math.cos(a)*radius,math.sin(a*1.19)*radius,math.sin(a*.83)*radius*.6,.86+.14*math.sin(a*1.37)
end
function F.resize(point,factor)
    if point.texture then point.texture:setWidth(65)end
    local scale=point.baseScale*factor
    if point.scale~=scale then point.instance:setScale(scale*(point.widthScale or 1),scale);point.scale=scale end
end
function F.drawHistory(p,s,animate)
    if not s.lastEmission or s.clock-s.lastEmission>=F.trailMs then return end
    for i=15,38 do
        local t=((i-15)%12)/11;local lag=6+(i%6)*5;local target=s.clock-lag
        local cx,cy,cz=F.armPoint(s.joints,t);local x,y,z=cx,cy,cz
        if target<=s.lastEmission and F.historyPose(s,target,s.scratch)then x,y,z=F.armPoint(s.scratch,t)end
        local dx,dy,dz=x-cx,y-cy,z-cz;local sx,sy=(dx-dy)*32,(dx+dy)*16-dz*96
        local distance=math.sqrt(sx*sx+sy*sy)
        local tether=i>26 and 4 or 2
        if distance>tether then local k=tether/distance;x=cx+dx*k;y=cy+dy*k;z=cz+dz*k end
        local ox,oy,oz,pulse=F.swirl(s,i,t,s.clock,1)
        local fade=math.max(0,1-(s.clock-s.lastEmission)/F.trailMs)
        local taper=1-.35*t*t
        local point=s.points[i];F.resize(point,(.90+.18*pulse)*taper*(.40+.60*fade))
        if animate and point.animated then point.sprite:update(point.instance)end
        drawPoint(p,s,i,x+ox,y+oy,z+oz,(i>26 and .065 or .16)*fade*pulse*(s.lastWeight or 1),s.lastColor)
    end
end
function F.colors()
    if not F.normal then
        F.normal=ColorInfo.new(.94,.97,1,1);F.extreme=ColorInfo.new(1,1,1,1)
        F.smokeNormal=ColorInfo.new(.84,.89,.96,1);F.smokeExtreme=ColorInfo.new(.93,.96,1,1)
        F.midNormal=ColorInfo.new(.95,.97,1,1);F.midExtreme=ColorInfo.new(1,1,1,1)
    end
end
function F.hit(p,victim,strong,charged,anchor)
    local style=PY.getPlayerStyle(p)
    if not style or style.hitEffects~="yakuza6" or p:getModData().ProjectYakuzaHitEffectsDisabled or p:isDead()then return end
    local s=F.states[p];local x,y,z;local drop=0
    if s then
        local time,weight,location=F.findTrack(p,s.track.animation,s.location)
        time=time or s.time
        local window=time and F.window(s,time)
        if window and F.attachmentWeight(weight)>=.05 then
            s.track=PY.AttackTracks[window.track];s.location=location or s.location
            local joints=F.worldJoints(p,s,time,F.pose(p,s,time));x,y,z=F.armPoint(joints,1);drop=F.coatOffset()
        end
    end
    if not x then
        if anchor then x,y,z=anchor.x,anchor.y,anchor.z
        elseif victim then x,y,z=victim:getX(),victim:getY(),victim:getZ()+.48
        else return end
    end
    local count=0;for _,b in ipairs(F.bursts)do if b.owner==p then count=count+1 end end
    if #F.bursts>=F.maxBursts or count>=F.maxActorBursts then
        for i,b in ipairs(F.bursts)do if count<F.maxActorBursts or b.owner==p then F.dispose(b);table.remove(F.bursts,i);break end end
    end
    F.loadSprites()
    if not F.streak then
        F.streak=sprite("media/textures/ProjectYakuza/AttackFX/e_j_0361_spark_b.png")
        F.gaidenSpark=sprite("media/textures/ProjectYakuza/AttackFX/e_f_d0004_spark.png")
        F.puffs={{sprite=sprite("media/textures/ProjectYakuza/AttackFX/e_j_0332_sparks_a.png"),ox=-64,oy=0,additive=true},{sprite=sprite("media/textures/ProjectYakuza/AttackFX/e_j_0073_aura_cA8L8.png",true),ox=0,oy=-64},{sprite=sprite("media/textures/ProjectYakuza/AttackFX/e_j_0073_aura_dA8L8.png",true),ox=0,oy=-64},{sprite=F.gaidenSmoke,ox=0,oy=-64}}
    end
    F.colors();F.serial=F.serial+1
    local seed=(F.serial*7919+math.floor(getTimestampMs())%65521)%2147483647
    local function random()seed=seed*48271%2147483647;return seed/2147483647 end
    local b={owner=p,style=style.id,x=x,y=y,z=z,drop=drop,last=getTimestampMs(),age=0,life=charged and 320 or strong and 290 or 240,color=PY.Heat.isExtreme(p)and F.extreme or F.normal,points={},variant=F.serial%4}
    local tile=Core.getTileScale();local angle=random()*math.pi*2;local puffStart=math.floor(random()*#F.puffs)
    local bx,by,bz=0,0,0
    if s and s.joints and F.historyPose(s,s.clock-18,s.scratch)then
        local px,py,pz=F.armPoint(s.scratch,1);bx,by,bz=x-px,y-py,z-pz
        local length=math.sqrt(bx*bx+by*by+bz*bz)
        if length>.00001 then bx,by,bz=bx/length,by/length,bz/length else bx,by,bz=0,0,0 end
    end
    b.smokeColor=PY.Heat.isExtreme(p)and F.smokeExtreme or F.smokeNormal
    if not F.flash then F.flash=sprite("media/textures/ProjectYakuza/HitGlint.png")end
    for i=1,16 do
        local puff=i>=13 and i<=15 and F.puffs[(puffStart+i-13)%#F.puffs+1]
        local flash=i==16;local gaiden=i<=12 and i%2==1
        local scale=(flash and .19 or puff and(.065+random()*.05)or .045+random()*.06)*(charged and 1.20 or strong and 1.10 or 1)*tile
        local sp=flash and F.flash or puff and puff.sprite or gaiden and F.gaidenSpark or F.streak
        local instance=PY.WorldEffects.detached(sp,scale,0)
        local texture=compactTextures[sp];local widthScale=texture and 64/65 or 1;instance:setScale(scale*widthScale,scale)
        local turn=angle+i*2.399963+random()*.8;local speed=.45+random()*.95;local drive=.25+random()*.65
        if b.variant==1 then turn=angle+(i-6.5)*.18+(random()-.5)*.6;speed=speed*1.2
        elseif b.variant==2 then speed=speed*.65;drive=drive*.6
        elseif b.variant==3 then turn=angle+(i%2==0 and 1 or -1)*(.5+random()*.8);speed=speed*1.05 end
        b.points[i]={instance=instance,scale=scale,baseScale=scale,texture=texture,widthScale=widthScale,puff=puff~=false and puff~=nil,flash=flash,additive=not puff or puff.additive==true,
            vx=math.cos(turn)*speed+bx*drive,vy=math.sin(turn)*speed+by*drive,vz=.25+random()*.9+bz*drive*.5,
            life=flash and .16 or puff and(.22+random()*.12)or .55+random()*.45,delay=puff and(i-13)*14 or 0,curve=(random()-.5)*(b.variant==3 and 5 or 3.2),
            ox=puff and puff.ox or 0,oy=puff and puff.oy or flash and -32 or gaiden and -32 or -48}
    end
    F.bursts[#F.bursts+1]=b;F.syncHook()
    return b
end
function F.drawBursts(now,paused,hidden)
    for i=#F.bursts,1,-1 do
        local b=F.bursts[i];local p=b.owner;local dt=math.max(0,now-b.last);b.last=now
        if not paused then b.age=b.age+dt end
        if b.age>=b.life or not valid(p,b)then F.dispose(b);table.remove(F.bursts,i)
        elseif not hidden then
            for _,point in ipairs(b.points)do
                local age=b.age-point.delay;local k=age/(b.life*point.life)
                if k>=0 and k<1 then
                    local t=age/1000
                    local alpha=(point.flash and .70 or point.puff and .20/(1+point.delay/15)or .72)*(1-k)^1.5
                    point.instance:SetAlpha(alpha);point.instance:SetTargetAlpha(alpha)
                    SpriteRenderer.instance:setDoAdditive(point.additive==true)
                    if point.puff or point.flash then
                        F.resize(point,point.flash and 1-.30*k or 1+.25*math.sin(k*math.pi)-.55*k)
                        point.instance:render(p,b.x+point.vx*t*.12,b.y+point.vy*t*.12,b.z+math.max(0,point.vz*t*.08),IsoDirections.N,point.ox*point.scale,point.oy*point.scale-b.drop,point.puff and b.smokeColor or b.color)
                    else
                        F.resize(point,1-.50*k)
                        point.instance:render(p,b.x+point.vx*t-point.vy*point.curve*t*t,b.y+point.vy*t+point.vx*point.curve*t*t,b.z+point.vz*t-1.4*t*t,IsoDirections.N,0,point.oy*point.scale-b.drop,b.color)
                    end
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
            s.poseWeight=0
            if current and weight>=.05 and(not time or not s.seen or current>=time-.02)then
                time=current;s.time=current;s.weight=weight;s.location=location;s.poseWeight=F.attachmentWeight(weight)
            end
            if s.poseWeight<=0 then s.historyCount=0;s.recordedAt=nil;s.lastEmission=nil end
        end
        local animate=not paused and s.lastFlameClock~=s.clock
        local anchored=false
        if not hidden and (s.poseWeight or 0)>0 and time and time>=s.config.from and time<=s.config.to+.12 then
            local window=F.window(s,time)
            if window then
                if s.windowRef~=window then s.windowRef=window;s.track=PY.AttackTracks[window.track];s.historyCount=0;s.recordedAt=nil end
                if not s.points then allocate(s)end
                local pose=F.pose(p,s,time);local joints=F.worldJoints(p,s,time,pose);anchored=true
                if not paused then F.record(s)end
                local extreme=PY.Heat.isExtreme(p);local color=extreme and F.extreme or F.normal
                local fade=math.max(0,math.min(1,(time-window.from)/.04,(window.to+.03-time)/.04))*s.poseWeight
                s.lastEmission=s.clock;s.lastColor=extreme and F.smokeExtreme or F.smokeNormal;s.lastWeight=fade
                for i=1,11 do
                    local t=(i-1)/10;local x,y,z=F.armPoint(joints,t)
                    local ox,oy,oz,pulse=F.swirl(s,i,t,s.clock,.35)
                    local point=s.points[i];F.resize(point,.92+.12*pulse)
                    if animate and point.animated then point.sprite:update(point.instance)end
                    drawPoint(p,s,i,x+ox,y+oy,z+oz,fade*(extreme and .23 or .18)*pulse,color)
                end
                for i=12,14 do
                    local t=corePositions[i-11];local x,y,z=F.armPoint(joints,t)
                    local ox,oy,oz,pulse=F.swirl(s,i,t,s.clock,.7)
                    local point=s.points[i];F.resize(point,.91+.14*pulse)
                    if animate and point.animated then point.sprite:update(point.instance)end
                    drawPoint(p,s,i,x+ox,y+oy,z+oz,fade*.28*pulse,extreme and F.midExtreme or F.midNormal)
                end
                for i=39,48 do
                    local x,y,z=F.armPoint(joints,.40+(i-39)*.065)
                    local a=s.clock*(.041+(i-39)*.004)+s.seed+i*2.399963
                    local k=.5+.5*math.sin(a*.71);local radius=.012+.025*k
                    drawPoint(p,s,i,x+math.cos(a)*radius,y+math.sin(a*1.23)*radius,z+math.sin(a*.87)*radius*.5,fade*.48*(.3+.7*k),color)
                end
            end
        end
        if s.points and not hidden and (s.poseWeight or 0)>0 then
            if not anchored and time and s.lastEmission then F.worldJoints(p,s,time,F.pose(p,s,time))end
            F.drawHistory(p,s,animate)
        end
        if animate then s.lastFlameClock=s.clock end
    end
    for i=#F.tails,1,-1 do
        local s=F.tails[i];local p=s.owner;local dt=math.max(0,now-s.last);s.last=now;if not paused then s.clock=s.clock+dt end
        local time,weight,location=s.time,s.weight,s.location
        if not paused then time,weight,location=F.findTrack(p,s.track.animation,s.location)end
        if not valid(p,s)or s.clock-s.lastEmission>=F.trailMs or not time or F.attachmentWeight(weight)<.7 or (p:getX()-s.rootX)^2+(p:getY()-s.rootY)^2>1 or math.abs(p:getZ()-s.rootZ)>.5 then F.dispose(s);table.remove(F.tails,i)
        else
            s.time=time;s.weight=weight;s.location=location;s.lastWeight=math.min(s.lastWeight,F.attachmentWeight(weight))
            local animate=not paused and s.lastFlameClock~=s.clock
            if not hidden then F.worldJoints(p,s,time,F.pose(p,s,time));F.drawHistory(p,s,animate)end
            if animate then s.lastFlameClock=s.clock end
        end
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
