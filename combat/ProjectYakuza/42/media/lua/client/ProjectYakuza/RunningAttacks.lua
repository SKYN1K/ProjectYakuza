require "ProjectYakuza/Runtime"
require "ProjectYakuza/Quicksteps"
local ProjectYakuza=ProjectYakuza
local R={players=setmetatable({}, {__mode="k"}),tickets=setmetatable({}, {__mode="k"}),active=setmetatable({}, {__mode="k"})}
ProjectYakuza.RunningAttacks=R
local function now()return getTimestampMs()end
local function key(id)local code=getCore():getKey(id:getId());return code and code>0 and isKeyDown(code)end
function R.variant(heavy)
    if heavy then return "dropkick" end
    local roll=ZombRand(3)
    return roll==0 and "left" or roll==1 and "right" or "knee"
end
local function resetRun(s)s.runMs=0;s.x=nil;s.y=nil;s.z=nil;s.time=nil;s.dx=nil;s.dy=nil;s.lastMovedAt=nil;s.pending=nil end
function R.pause(p)
    local s=R.players[p]
    if s then resetRun(s);s.light=ProjectYakuza.Bindings.down("light");s.heavy=ProjectYakuza.Bindings.down("finisher") end
end
function R.ready(p)
    return ProjectYakuza.isEquipped(p) and not isMouseButtonDown(1) and not p:isAiming()
        and (p:isRunning() or p:isSprinting()) and not p:isDead() and not p:isOnFloor() and not p:isKnockedDown()
        and not p:isClimbing() and not p:getVehicle() and not p:isDraggingCorpse() and not p:isAsleep()
        and not p:hasTimedActions() and not p:isBlockMovement() and not p:getIgnoreMovement() and (p:getHitReaction() or "")==""
end
function R.beforeStart(context)
    local p,t=context.player,context.target
    t.oldIgnore=p:getIgnoreMovement();t.oldBlock=p:isBlockMovement()
    t.move=context.action;t.arming=true;t.startedAt=now()
    R.active[p]=t
    p:setIgnoreMovement(true)
    p:setRunning(false);p:setSprinting(false);p:setMoving(false)
    p:setVariable("ProjectYakuzaRunningAttack",true)
    p:setForwardDirection(t.dx,t.dy)
    p:DirectionFromVector(p:getForwardDirection())
end
function R.onSwing(p,move)
    local t=R.tickets[p]
    if not t then return end
    t.move=move;t.arming=false;t.moved=0;t.blocked=false;t.startedAt=now()
    R.active[p]=t
    p:setIgnoreMovement(true)
    p:setVariable("ProjectYakuzaRunProgress","0")
    p:setVariable("ProjectYakuzaRunRecover", "")
end
function R.finish(p)
    R.pause(p)
    if R.tickets[p] or R.active[p] then p:setVariable("ProjectYakuzaRunningAttack",false) end
    local t=R.active[p]
    if t then
        p:setIgnoreMovement(t.oldIgnore==true);p:setBlockMovement(t.oldBlock==true)
        p:setVariable("ProjectYakuzaRunProgress","")
        p:setVariable("ProjectYakuzaRunRecover","")
    end
    R.active[p]=nil;R.tickets[p]=nil
end
function R.advance(p)
    local t=R.active[p]
    if not t then return end
    local hit=p:getHitReaction()
    if not ProjectYakuza.isEquipped(p) or p:isDead() or p:isOnFloor() or p:isKnockedDown() or p:isClimbing()
        or p:getVehicle() or (hit and hit~="") then ProjectYakuza.resetPlayer(p,"running_attack_interrupted");return end
    if t.arming then

        p:setRunning(false);p:setSprinting(false);p:setMoving(false)
        if now()>t.expiresAt then ProjectYakuza.resetPlayer(p,"running_attack_start_timeout");return end
        local state=p:getCurrentActionContextStateName()
        if state=="idle" or state=="movement" then
            t.arming=false;t.submitted=true
            ProjectYakuza.stateFor(p).startRequestedAt=now()
            ProjectYakuza.attemptAttack(p)
            if not ProjectYakuza.stateFor(p).active and not p:isAttackStarted() then ProjectYakuza.resetPlayer(p,"running_attack_rejected") end
        end
        return
    end
    if not t.moved then return end
    local progress=math.max(0,math.min(1,tonumber(p:GetVariable("ProjectYakuzaRunProgress")) or 0))
    local combo=ProjectYakuza.stateFor(p)
    if t.move.variant~="dropkick" and not combo.recoveryReleased and p:GetVariable("ProjectYakuzaRunRecover")==t.move.nodeValue
        and p:GetVariable("ProjectYakuzaHitMarker")==t.move.nodeValue
        and (isMouseButtonDown(1)or key(KeybindId.FORWARD) or key(KeybindId.BACKWARD) or key(KeybindId.LEFT) or key(KeybindId.RIGHT)) then
        combo.recoveryReleased=true
        R.finish(p)
        p:setMeleeDelay(0)
        p:setPerformingAttackAnimation(false)
        p:reportEvent("ActiveAnimFinishing")
        return
    end
    local amount=math.min(0.08,math.max(0,t.move.distance*progress-t.moved))
    if amount>0 and not t.blocked then
        local dx,dy=t.dx*amount,t.dy*amount
        if ProjectYakuza.Quicksteps.canMove(p,dx,dy) then p:moveUnmodded(dx,dy);t.moved=t.moved+amount
        else t.blocked=true end
    end
end
function R.update(p)
    local s=R.players[p]
    if not s then s={runMs=0};R.players[p]=s end
    local light,heavy=ProjectYakuza.Bindings.down("light"),ProjectYakuza.Bindings.down("finisher")
    local lightPress,heavyPress=light and not s.light,heavy and not s.heavy
    s.light,s.heavy=light,heavy
    if R.active[p] then R.advance(p);resetRun(s);return end
    if ProjectYakuza.isBusy(p) or not R.ready(p) then resetRun(s);return end
    local style=ProjectYakuza.getPlayerStyle(p);local slot=style.actions.runningAttack
    if not slot or not slot.enabled then resetRun(s);return end
    local t,x,y,z=now(),p:getX(),p:getY(),p:getZ()
    if lightPress or heavyPress then s.pending={heavy=heavyPress,expiresAt=t+(slot.inputBufferMs or 180),style=style.id}end
    if s.pending and(t>s.pending.expiresAt or s.pending.style~=style.id)then s.pending=nil end
    if not s.x then s.x,s.y,s.z,s.time=x,y,z,t;return end
    local dx,dy=x-s.x,y-s.y;local elapsed=math.max(0,math.min(100,t-s.time))
    s.x,s.y,s.time=x,y,t
    local length=math.sqrt(dx*dx+dy*dy)
    if math.abs(z-s.z)>0.05 or length>1 then resetRun(s);return end
    s.z=z
    if length>=0.00001 then
        s.runMs=s.runMs+elapsed;s.dx,s.dy=dx/length,dy/length;s.lastMovedAt=t
    elseif not s.lastMovedAt or t-s.lastMovedAt>80 then s.runMs=0;s.dx=nil;s.dy=nil end
    if s.runMs<(slot.runupMs or 250)or not s.pending or not s.dx then return end
    local pending=s.pending;local name=pending.variant or R.variant(pending.heavy);pending.variant=name
    local ticket={variant=name,dx=s.dx,dy=s.dy,expiresAt=t+500}
    R.tickets[p]=ticket
    local ok,reason=ProjectYakuza.requestAction(p,"runningAttack",name,ticket)
    if not ok then
        R.tickets[p]=nil
        if R.active[p]then R.finish(p)end
        if reason=="native_attack_busy"and s.pending==pending then return end
        resetRun(s);return
    end
    resetRun(s);R.advance(p)
end
