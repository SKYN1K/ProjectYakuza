require "ProjectYakuzaEmotes/EmoteSpears"
local PY=ProjectYakuzaEmotes
local F={states=setmetatable({}, {__mode="k"}),bursts={},maxBursts=8,life=240}
PY.SpearSparks=F
local function dispose(b)
    for _,point in ipairs(b.points)do point.instance:Dispose();IsoSpriteInstance.add(point.instance)end
end
function F.clear()
    for _,b in ipairs(F.bursts)do dispose(b)end
    F.bursts={};F.states=setmetatable({}, {__mode="k"})
    if F.rendering then Events.OnPostRender.Remove(F.render);F.rendering=false end
end
function F.point(impact,time)
    local frame=math.max(0,math.min(#impact.points-1,(time-impact.at)*impact.fps));local index=math.floor(frame);local t=frame-index;local a=impact.points[index+1];local b=impact.points[math.min(index+2,#impact.points)]
    return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t}
end
function F.spawn(p,impact,time)
    local contact=F.point(impact,time)
    if #F.bursts>=F.maxBursts then dispose(table.remove(F.bursts,1))end
    if not F.sprite then F.sprite=IsoSprite.CreateSprite(nil);F.sprite:LoadFramesNoDirPageSimple("media/textures/ProjectYakuzaEmotes/e_f_0006_spark01.png")end
    local a=p:getAnimAngleRadians()+math.pi/2;local c,s=math.cos(a),math.sin(a);local x,z=contact[1],contact[3]
    local b={owner=p,x=p:getX()+(-x*c-z*s)*1.5,y=p:getY()+(-x*s+z*c)*1.5,z=p:getZ()+math.max(0,contact[2])*.61237234,age=0,last=getTimestampMs(),points={}}
    local seed=(p:getOnlineID()or 0)%17
    for i=1,9 do
        local angle=i*math.pi*2/9+seed*.37;local speed=.28+(i%4)*.13;local instance=IsoSpriteInstance.get(F.sprite)
        instance:setFrameSpeedPerFrame(0)
        b.points[#b.points+1]={instance=instance,vx=math.cos(angle)*speed,vy=math.sin(angle)*speed,vz=.32+(i%3)*.12,scale=.20+(i%4)*.035}
    end
    F.bursts[#F.bursts+1]=b
    if not F.rendering then Events.OnPostRender.Add(F.render);F.rendering=true end
end
function F.observe(p)
    if not p or p:isDead()or not p:getVariableBoolean("EmotePlaying")then if p then F.states[p]=nil end;return end
    local item=p:getPrimaryHandItem();if not item or p:isHideWeaponModel()or p:isHideEquippedHandR()then F.states[p]=nil;return end
    local clip=PY.SpearClips[item:getFullType()]or "ProjectYakuza_LauSpearGround";local impact=PY.SpearImpacts[clip];local time,weight
    for layer=0,3 do
        for slot=0,7 do
            local name=p:dbgGetAnimTrackName(layer,slot);if not name or name==""then break end
            if name==clip then
                local w=p:dbgGetAnimTrackWeight(layer,slot)
                if w>=.05 and(not weight or w>weight)then time=p:dbgGetAnimTrackTime(layer,slot);weight=w end
            end
        end
    end
    if not time or not impact then F.states[p]=nil;return end
    local deadline=impact.at+.12
    local state=F.states[p]
    if not state or state.clip~=clip or time<.1 and state.time>deadline then state={clip=clip,time=time,fired=time>deadline};F.states[p]=state end
    if not state.fired and time>=impact.at then
        state.fired=true
        if time<=deadline then F.spawn(p,impact,time)end
    end
    state.time=time
end
function F.tick()
    local now=getTimestampMs();local paused=isGamePaused()
    for i=#F.bursts,1,-1 do
        local b=F.bursts[i];local dt=math.max(0,now-b.last);b.last=now;if not paused then b.age=b.age+dt end
        if b.age>=F.life or b.owner:isDead()then dispose(b);table.remove(F.bursts,i)end
    end
    if #F.bursts==0 and F.rendering then Events.OnPostRender.Remove(F.render);F.rendering=false end
    if paused then return end
    local seen={}
    for i=0,getNumActivePlayers()-1 do local p=getSpecificPlayer(i);if p then seen[p]=true;F.observe(p)end end
    local players=getOnlinePlayers()
    if players then for i=0,players:size()-1 do local p=players:get(i);if p and not seen[p]then F.observe(p)end end end
end
function F.draw()
    if ISWorldMap_instance and ISWorldMap_instance:isVisible()then return end
    if not F.color then F.color=ColorInfo.new(1,.82,.48,1)end
    local tile=Core.getTileScale()
    for _,b in ipairs(F.bursts)do
        local t=b.age/F.life;local seconds=b.age/1000;local opacity=(1-t)*(1-t)
        for _,point in ipairs(b.points)do
            local scale=point.scale*tile*(1-.5*t);local height=math.max(0,point.vz*seconds-seconds*seconds)
            point.instance:setScale(scale,scale);point.instance:SetAlpha(opacity);point.instance:SetTargetAlpha(opacity)
            point.instance:render(b.owner,b.x+point.vx*seconds,b.y+point.vy*seconds,b.z+height,IsoDirections.N,0,-16*scale,F.color)
        end
    end
end
function F.render()
    local renderer=SpriteRenderer.instance;local previous=renderer:getDoAdditive();renderer:setDoAdditive(false)
    local ok,err=pcall(F.draw);renderer:setDoAdditive(previous)
    if not ok then F.clear();error(err)end
end
Events.OnTick.Add(F.tick)
Events.OnGameStart.Add(F.clear)
Events.OnMainMenuEnter.Add(F.clear)
