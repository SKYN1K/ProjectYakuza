require "DCF/Runtime"
require "DCF/Quicksteps"
local DCF=DragonCombat
local R={players=setmetatable({}, {__mode="k"}),tickets=setmetatable({}, {__mode="k"}),active=setmetatable({}, {__mode="k"})}
DCF.RunningAttacks=R
local function now()return getTimestampMs()end
local function key(id)local code=getCore():getKey(id:getId());return code and code>0 and isKeyDown(code)end
function R.variant(heavy)
    if heavy then return "dropkick" end
    local roll=ZombRand(3)
    return roll==0 and "left" or roll==1 and "right" or "knee"
end
local function resetRun(s)s.runMs=0;s.x=nil;s.y=nil;s.z=nil;s.time=nil end
function R.pause(p)
    local s=R.players[p]
    if s then resetRun(s);s.light=DCF.Bindings.down("runningLight");s.heavy=DCF.Bindings.down("dropkick") end
end
function R.ready(p)
    return DCF.isEquipped(p) and not isMouseButtonDown(1) and not p:isAiming()
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
    p:setVariable("DCFRunningAttack",true)
    p:setForwardDirection(t.dx,t.dy)
    p:DirectionFromVector(p:getForwardDirection())
end
function R.onSwing(p,move)
    local t=R.tickets[p]
    if not t then return end
    t.move=move;t.arming=false;t.moved=0;t.blocked=false;t.startedAt=now()
    R.active[p]=t
    p:setIgnoreMovement(true)
    p:setVariable("DCFRunProgress","0")
    p:setVariable("DCFRunRecover", "")
end
function R.finish(p)
    R.pause(p)
    if R.tickets[p] or R.active[p] then p:setVariable("DCFRunningAttack",false) end
    local t=R.active[p]
    if t then
        p:setIgnoreMovement(t.oldIgnore==true);p:setBlockMovement(t.oldBlock==true)
        p:setVariable("DCFRunProgress","")
        p:setVariable("DCFRunRecover","")
    end
    R.active[p]=nil;R.tickets[p]=nil
end
function R.advance(p)
    local t=R.active[p]
    if not t then return end
    local hit=p:getHitReaction()
    if not DCF.isEquipped(p) or p:isDead() or p:isOnFloor() or p:isKnockedDown() or p:isClimbing()
        or p:getVehicle() or (hit and hit~="") then DCF.resetPlayer(p,"running_attack_interrupted");return end
    if t.arming then
        -- Native run/sprint cannot enter melee. Release locomotion, then use the
        -- existing idle/movement-to-melee route on the following engine update.
        p:setRunning(false);p:setSprinting(false);p:setMoving(false)
        if now()>t.expiresAt then DCF.resetPlayer(p,"running_attack_start_timeout");return end
        local state=p:getCurrentActionContextStateName()
        if state=="idle" or state=="movement" then
            t.arming=false;t.submitted=true
            DCF.stateFor(p).startRequestedAt=now()
            DCF.attemptAttack(p)
            if not DCF.stateFor(p).active and not p:isAttackStarted() then DCF.resetPlayer(p,"running_attack_rejected") end
        end
        return
    end
    if not t.moved then return end
    local progress=math.max(0,math.min(1,tonumber(p:GetVariable("DCFRunProgress")) or 0))
    local combo=DCF.stateFor(p)
    if t.move.variant~="dropkick" and not combo.recoveryReleased and p:GetVariable("DCFRunRecover")==t.move.nodeValue
        and p:GetVariable("DCFHitMarker")==t.move.nodeValue
        and (key(KeybindId.FORWARD) or key(KeybindId.BACKWARD) or key(KeybindId.LEFT) or key(KeybindId.RIGHT)) then
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
        if DCF.Quicksteps.canMove(p,dx,dy) then p:moveUnmodded(dx,dy);t.moved=t.moved+amount
        else t.blocked=true end
    end
end
function R.update(p)
    local s=R.players[p]
    if not s then s={runMs=0};R.players[p]=s end
    local light,heavy=DCF.Bindings.down("runningLight"),DCF.Bindings.down("dropkick")
    local lightPress,heavyPress=light and not s.light,heavy and not s.heavy
    s.light,s.heavy=light,heavy
    if R.active[p] then R.advance(p);resetRun(s);return end
    if DCF.isBusy(p) or not R.ready(p) then resetRun(s);return end
    local style=DCF.getPlayerStyle(p);local slot=style.actions.runningAttack
    if not slot or not slot.enabled then resetRun(s);return end
    local t,x,y,z=now(),p:getX(),p:getY(),p:getZ()
    if not s.x then s.x,s.y,s.z,s.time=x,y,z,t;return end
    local dx,dy=x-s.x,y-s.y;local elapsed=math.max(0,math.min(100,t-s.time))
    s.x,s.y,s.time=x,y,t
    local length=math.sqrt(dx*dx+dy*dy)
    if math.abs(z-s.z)>0.05 or length<0.00001 or length>1 then s.runMs=0;s.z=z;return end
    s.z=z;s.runMs=s.runMs+elapsed
    if s.runMs<(slot.runupMs or 250) or not (lightPress or heavyPress) then return end
    local name=R.variant(heavyPress)
    if not name then return end
    local ticket={variant=name,dx=dx/length,dy=dy/length,expiresAt=t+500}
    R.tickets[p]=ticket
    local ok=DCF.requestAction(p,"runningAttack",name,ticket)
    if not ok then R.finish(p) end
    resetRun(s)
end
