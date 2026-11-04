require "ProjectYakuza/Registry"
local G={locks=setmetatable({},{__mode="k"}),origins=setmetatable({},{__mode="k"})};ProjectYakuza.GrabRules=G
function G.captureLock(z)
    if not G.locks[z]then G.origins[z]=z:getCurrentStateName()or ""end
    return G.locks[z]==true
end
function G.releaseLock(z,old)
    if G.locks[z]then z:setStateMachineLocked(old.locked==true);G.locks[z]=old.locked==true or nil end
    if not G.locks[z]then G.origins[z]=nil end
end
function G.unavailable(z)
    local name=z:getCurrentStateName()or ""
    return G.locks[z]==true or string.find(string.lower(name),"hitreaction",1,true)~=nil
end
function G.capture(z)
    return {useless=z:isUseless(),ignore=z:getIgnoreMovement(),deferred=z:isDeferredMovementEnabled(),target=z:getTarget(),locked=G.captureLock(z)}
end
function G.latch(z)
    local name=z:getCurrentStateName()
    if G.locks[z]then return true end
    if G.origins[z]and name~=G.origins[z]and name and string.find(string.lower(name),"hitreaction",1,true)then z:setStateMachineLocked(true);G.locks[z]=true;return true end
    return false
end
function G.keep(z)
    z:setTarget(nil);z:setUseless(true);z:setIgnoreMovement(true);z:setDeferredMovementEnabled(false);z:setAttackOutcome("fail")
    G.latch(z)
end
function G.retainAfterHit(z)
    if z:isDead()then return end
    z:setKnockedDown(false);z:setOnFloor(false);z:setStaggerBack(false);z:setHitForce(0);z:setHitReaction("ProjectYakuzaGrabbed");G.keep(z)
end
function G.restore(z,old)
    G.releaseLock(z,old)
    z:setUseless(old.useless==true);z:setIgnoreMovement(old.ignore==true);z:setDeferredMovementEnabled(old.deferred~=false)
    if not z:isDead()and z:getTarget()==nil then z:setTarget(old.target)end
end
function G.phase(value)
    return value=="enter"or value=="hold"or value=="throw"or value=="strike1"or value=="strike2"or value=="strike3"or value=="strike4"
end
function G.damage(p,move)
    local held=p:getPrimaryHandItem();if not held then return end
    local base=ProjectYakuza.HeatRushRules
    if base then return base.amount({contacts={{damageMultiplier=move.damageMultiplier or .65}}},1,held)end
    return .4
end
function G.wall(p,z,move)
    if not p or not z or not move or p:isDead()or p:isOnFloor()or p:isKnockedDown()or p:isClimbing()or (p:getHitReaction()or "")~=""or z:isDead()or z:isOnFloor()or z:isKnockedDown()or math.abs(p:getZ()-z:getZ())>.25 then return end
    local paths=ProjectYakuza.PairedMotions and ProjectYakuza.PairedMotions[move.motionId];if not paths then return end
    local depth=paths.wallDepth or .8;local cell=getCell();if not cell then return end
    local best,bestDistance
    local function candidate(sq,other,x,y,nx,ny)
        if not sq or not other or not sq:isWallTo(other)or sq:isWindowTo(other)or sq:isDoorTo(other)then return end
        local dx,dy=z:getX()-x,z:getY()-y;local distance=dx*dx+dy*dy;if distance>.85*.85 then return end
        local pose={x=x-nx*depth,y=y-ny*depth,fx=ny,fy=-nx,motion=paths,duration=move.duration}
        local shift=(pose.x-p:getX())^2+(pose.y-p:getY())^2
        if shift>1.2*1.2 or bestDistance and shift>=bestDistance or not ProjectYakuza.HeatRushRules.space(p,pose)then return end
        best,bestDistance=pose,shift
    end
    local x,y,level=math.floor(z:getX()),math.floor(z:getY()),math.floor(z:getZ())
    for ox=-1,1 do for oy=-1,1 do
        local gx,gy=x+ox,y+oy;local sq=cell:getGridSquare(gx,gy,level)
        local tx=math.max(gx+.15,math.min(gx+.85,p:getX()));local ty=math.max(gy+.15,math.min(gy+.85,p:getY()))
        candidate(sq,cell:getGridSquare(gx,gy-1,level),tx,gy,0,p:getY()<gy and 1 or -1)
        candidate(sq,cell:getGridSquare(gx-1,gy,level),gx,ty,p:getX()<gx and 1 or -1,0)
    end end
    return best
end
