require "ProjectYakuza/Runtime"
require "ProjectYakuza/Defense"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
local PY=ProjectYakuza
local H={gestures=setmetatable({}, {__mode="k"}),pending=setmetatable({}, {__mode="k"})}
PY.ChargedHeavy=H
local function now()return getTimestampMs()end
local A=ISBaseTimedAction:derive("ProjectYakuzaHeavyChargeAction")
H.Action=A
function A:adjustMaxTime(v)return v end
function A:isUsingTimeout()return false end
function A:isValid()
    local p=self.character
    return PY.isEquipped(p) and PY.getPlayerStyle(p)==self.context.style and p:isAiming()
        and not p:isDead() and not p:isOnFloor() and not p:isKnockedDown()
        and not p:isClimbing() and not p:getVehicle() and not p:isAsleep()
        and not p:isDraggingCorpse() and (p:getHitReaction() or "")==""
end
function A:holdPosition()
    local p=self.character
    PY.Defense.snapActor(p,self.anchorX,self.anchorY)
    p:getMovementLastFrame():set(0,0);p:setMoving(false);p:setRunning(false);p:setSprinting(false)
end
function A:start()
    self.started=true;self.startedAt=now();self.lastAt=self.startedAt
    local p=self.character
    self.oldBlock=p:isBlockMovement();self.oldIgnore=p:getIgnoreMovement();self.oldDeferred=p:isDeferredMovementEnabled()
    self.anchorX,self.anchorY=p:getX(),p:getY()
    p:setBlockMovement(true);p:setIgnoreMovement(true);p:setDeferredMovementEnabled(false);self:holdPosition()
    p:setVariable("ProjectYakuzaChargeClip","")
    self:setActionAnim(self.context.action.animation)
    self.action:setOverrideHandModelsObject(p:getPrimaryHandItem(),nil,false)
    PY.emit("heavyChargeStarted",p,self.context.style,self.context.action)
end
function A:cleanup(completed)
    if self.cleaned then return end
    self.cleaned=true;local p=self.character
    if self.started then
        p:setBlockMovement(self.oldBlock==true);p:setIgnoreMovement(self.oldIgnore==true)
        p:setDeferredMovementEnabled(self.oldDeferred);p:setVariable("ProjectYakuzaChargeClip","")
    end
    if PY.activeActions[p]==self.context then
        if completed then PY.completeAction(p,self.context) else PY.cancelAction(p,"charge_interrupted",self.context) end
    end
    H.gestures[p]=nil
    if completed and self.started and self:isValid() then H.pending[p]={expiresAt=now()+600,consumed=false} end
    if self.started then PY.emit("heavyChargeStopped",p,completed==true) end
end
function A:perform()self:cleanup(true);ISBaseTimedAction.perform(self)end
function A:stop()self:cleanup(false);ISBaseTimedAction.stop(self)end
function A:cancel()
    if self.cleaned then return end
    self:cleanup(false)
    if self.action then self:forceStop()
    elseif self.context.queue and self.context.queue.removeFromQueue then self.context.queue:removeFromQueue(self) end
end
function A:update()
    if self.cleaned then return end
    local t=now();local dt=math.max(0,t-self.lastAt);self.lastAt=t
    if isGamePaused() then self.startedAt=self.startedAt+dt;return end
    if not self:isValid() then self:forceStop();return end
    self:holdPosition()
    local age=t-self.startedAt
    local clip=self.character:GetVariable("ProjectYakuzaChargeClip") or ""
    if clip=="started" then self.seenClip=true end
    if age>600 and not self.seenClip then self:forceStop();return end
    if self.seenClip and age>=(self.context.action.minChargeMs or 350)
        and (not PY.Bindings.down("finisher") or age>=self.context.action.duration*1000) then self:forceComplete() end
end
function A:new(c)
    local o=ISBaseTimedAction.new(self,c.player);o.context=c;o.maxTime=-1
    o.stopOnWalk=false;o.stopOnRun=false;o.stopOnAim=false;o.ignoreHandsWounds=true
    return o
end
PY.registerActionHandler("heavyCharge",{
    canStart=function(c)
        local p=c.player
        return p:isLocalPlayer() and p:isAiming() and not isGamePaused() and not p:hasTimedActions()
            and not p:isDead() and not p:isOnFloor() and not p:isKnockedDown() and not p:isClimbing()
            and not p:getVehicle() and not p:isAsleep() and not p:isDraggingCorpse()
            and not p:isBlockMovement() and not p:getIgnoreMovement()
            and not p:isAttackStarted() and not p:isPerformingAttackAnimation()
            and (p:getHitReaction() or "")=="","not_ready"
    end,
    start=function(c)
        PY.resetPlayer(c.player,"heavy_charge_started")
        local a=A:new(c);c.timedAction=a;c.requestedAt=now()
        local ok,q=pcall(ISTimedActionQueue.add,a)
        if not ok or not q then a:cancel();return false,"queue_rejected" end
        c.queue=q;return true
    end,
    cancel=function(c)if c.timedAction then c.timedAction:cancel() end end,
})
function H.watch(p,c)
    if not c.timedAction.started and now()-c.requestedAt>600 then PY.cancelAction(p,"charge_start_timeout",c) end
    if c.timedAction.started and not c.timedAction.cleaned then c.timedAction:holdPosition() end
    return PY.activeActions[p]==c
end
function H.input(p,down,pressed,s,style)
    local slot=style.actions.heavyCharge
    if not slot or not slot.enabled then return false end
    if not p:isAiming() or isGamePaused() then H.gestures[p]=nil;H.pending[p]=nil;return true end
    local move=s.finisherMove or s.pendingFinisher
    if move and (move.runningAttack or move.quickstepAttack or move.chargedHeavy) then H.gestures[p]=nil;return true end
    local ticket=H.pending[p]
    if ticket then
        if now()>ticket.expiresAt or ticket.consumed then H.pending[p]=nil;return true end
        local ok,reason=PY.requestAction(p,"chargedHeavy",nil,ticket)
        if ok or (reason~="native_attack_busy" and reason~="busy" and reason~="native_attack_rejected") then H.pending[p]=nil end
        return true
    end
    if pressed then H.gestures[p]={at=now()} end
    local gesture=H.gestures[p]
    if not gesture then return true end
    if not down then
        H.gestures[p]=nil;PY.queueFinisher(p);return true
    end
    if now()-gesture.at>=(slot.holdMs or 350) and not s.active and not s.starting and not PY.activeActions[p] then
        PY.requestAction(p,"heavyCharge")
    end
    return true
end
function H.clearPlayer(p)
    H.gestures[p]=nil;H.pending[p]=nil
end
PY.on("comboCancelled",function(p,reason)if reason~="heavy_charge_started" then H.clearPlayer(p) end end)
function H.clear()
    local players={};for p,c in pairs(PY.activeActions) do if c.kind=="heavyCharge" then players[#players+1]=p end end
    for _,p in ipairs(players) do PY.cancelAction(p,"world_exit") end
    H.gestures=setmetatable({}, {__mode="k"});H.pending=setmetatable({}, {__mode="k"})
end
Events.OnSave.Add(H.clear)
Events.OnMainMenuEnter.Add(H.clear)
