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
function G.latch(z,paired)
    local name=z:getCurrentStateName()
    if G.locks[z]then return true end
    if (paired or G.origins[z]and name~=G.origins[z])and name and string.find(string.lower(name),"hitreaction",1,true)then z:setStateMachineLocked(true);G.locks[z]=true;return true end
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
    return value=="attempt"or value=="enter"or value=="hold"or value=="escape"or value=="throw"or value=="strike1"or value=="strike2"or value=="strike3"or value=="strike4"
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
        local pose={x=x-nx*depth,y=y-ny*depth,fx=nx,fy=ny,motion=paths,duration=move.duration,wallX=x,wallY=y,wallNX=nx,wallNY=ny}
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

function G.wallPresent(p,pose)
    if not pose.wallX or not pose.wallY or not pose.wallNX or not pose.wallNY then return false end
    local cell=getCell();if not cell then return false end
    local x,y=math.floor(pose.wallX),math.floor(pose.wallY);local level=math.floor(p:getZ())
    local sq=cell:getGridSquare(x,y,level);local other=cell:getGridSquare(x-(pose.wallNX~=0 and 1 or 0),y-(pose.wallNY~=0 and 1 or 0),level)
    return sq~=nil and other~=nil and sq:isWallTo(other)and not sq:isWindowTo(other)and not sq:isDoorTo(other)
end

function G.heatDefinition(slot,variant)
    if not slot or not slot.enabled then return end
    if slot.variants then return slot.variants[variant or "default"]end
    if variant==nil or variant=="default"then return slot end
end
function G.heatSelection(p,z,slot)
    local move=G.heatDefinition(slot)
    if not move or not move.enabled or not move.grabHeat then return end
    local pose=move.requiresWall~=false and G.wall(p,z,move)or move.requiresWall==false and ProjectYakuza.HeatRushRules.placement(p,z,move)
    if pose then return move,pose,"default"end
    move=G.heatDefinition(slot,"open")
    if not move or not move.enabled or not move.grabHeat or move.requiresWall~=false then return end
    if not p or not z or p:isDead()or p:isOnFloor()or p:isKnockedDown()or p:isClimbing()or(p:getHitReaction()or "")~=""or z:isDead()or z:isOnFloor()or z:isKnockedDown()or math.abs(p:getZ()-z:getZ())>.25 then return end
    pose=ProjectYakuza.HeatRushRules.placement(p,z,move)
    if pose then return move,pose,"open"end
end

function G.spacing(slot)return math.max(.25,math.min(1,slot and slot.distance or .7))end
function G.entryPosition(p,z,slot,state,t,fx,fy)
    if not state.entryAt then state.entryAt=t;state.entryX=z:getX();state.entryY=z:getY()end
    local fraction=math.max(0,math.min(1,(t-state.entryAt)/(slot.entryBlendMs or 180)))
    local blend=fraction*fraction*(3-2*fraction);local offset=G.offset(slot,"enter")
    local x=p:getX()+fx*offset.forward+fy*offset.right;local y=p:getY()+fy*offset.forward-fx*offset.right
    return state.entryX+(x-state.entryX)*blend,state.entryY+(y-state.entryY)*blend,fraction
end

function G.offset(slot,phase,moving)
    local strike=slot and slot.strikes and slot.strikes[tonumber(string.match(phase or "","^strike(%d)$"))]
    local offset=phase=="throw"and slot and slot.throwOffset or strike and strike.pairOffset or slot and(moving and slot.walkOffset or slot.holdOffset)
    return {forward=offset and offset.forward or G.spacing(slot),right=offset and offset.right or slot and slot.lateral or 0}
end
function G.alignment(slot,phase,state,t)
    local moving=phase=="hold"and state.grabMoving==true
    local target=G.offset(slot,phase,moving)
    if state.pairPhase~=phase or state.pairMoving~=moving then state.pairFrom=state.pairOffset or G.offset(slot,"hold");state.pairAt=t;state.pairPhase=phase;state.pairMoving=moving end
    local f=math.max(0,math.min(1,(t-state.pairAt)/120));f=f*f*(3-2*f)
    local source=state.pairFrom
    state.pairOffset={forward=source.forward+(target.forward-source.forward)*f,right=source.right+(target.right-source.right)*f}
    return state.pairOffset
end

function G.land(z)
    if not z or z:isDead()then return end
    z:setHitReaction("");z:setStaggerBack(false);z:setHitForce(0);z:setKnockedDown(true);z:setFallOnFront(false);z:setOnFloor(true)
    if ZombieOnGroundState and z.changeState then z:changeState(ZombieOnGroundState.instance())end
end

function G.crowd(p,thrown,slot,fx,fy)
    local cfg=slot and slot.throwCrowd
    if not cfg or cfg==false then return {}end
    if not fx or not fy then local f=p:getForwardDirection();fx,fy=f:getX(),f:getY()end
    local length=math.sqrt(fx*fx+fy*fy);if length<.001 then return {}end;fx,fy=fx/length,fy/length
    local cx,cy=thrown:getX()+fx*cfg.forward,thrown:getY()+fy*cfg.forward
    local cell=getCell();if not cell then return {}end
    local range=math.ceil(cfg.radius);local level=math.floor(thrown:getZ());local seen={};local result={}
    for ox=-range,range do for oy=-range,range do
        local square=cell:getGridSquare(math.floor(cx)+ox,math.floor(cy)+oy,level);local objects=square and square:getMovingObjects()
        if objects then for i=0,objects:size()-1 do
            local v=objects:get(i)
            if not seen[v]then
                seen[v]=true
                if v~=thrown and instanceof(v,"IsoZombie")and not v:isDead()and not v:isOnFloor()and not v:isKnockedDown()and not v:isUseless()and math.abs(v:getZ()-thrown:getZ())<.25
                    and not G.unavailable(v)and v:GetVariable("ProjectYakuzaGrabbed")~="true"and v:GetVariable("ProjectYakuzaHeatRushVictim")~="true"then
                    local dx,dy=v:getX()-cx,v:getY()-cy;local distance=dx*dx+dy*dy
                    if distance<=cfg.radius*cfg.radius and (v:getX()-thrown:getX())*fx+(v:getY()-thrown:getY())*fy>=-.2
                        and ProjectYakuza.NetworkProtocol.path(thrown,v:getX(),v:getY())then result[#result+1]={victim=v,distance=distance}end
                end
            end
        end end
    end end
    table.sort(result,function(a,b)return a.distance<b.distance end)
    local victims={};for i=1,math.min(#result,cfg.maxTargets)do victims[i]=result[i].victim end
    return victims
end
function G.collide(p,v,cfg)
    if not cfg or not ProjectYakuza.HitResponses.apply(p,v,{kind="knockdown",force=cfg.force})then return false end
    v:setAttackedBy(p);v:setAttackOutcome("fail");v:setTarget(nil);v:reportEvent("wasHit")
    return true
end

function G.escapeDue(state,slot,t,roll)
    local cfg=slot and slot.breakout;if not cfg or cfg==false or cfg.chance==0 then return false end
    if not state.escapeNext then state.escapeNext=t+(cfg.firstCheckMs or cfg.intervalMs)end
    if t<state.escapeNext then return false end
    state.escapeNext=t+cfg.intervalMs
    return (roll or ZombRand)(10000)<cfg.chance*10000
end
