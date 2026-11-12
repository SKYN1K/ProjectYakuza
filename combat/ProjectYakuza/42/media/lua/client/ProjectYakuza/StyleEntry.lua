require "ProjectYakuza/ActionAnimation"
require "ProjectYakuza/Runtime"
require "ProjectYakuza/Defense"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
local PY=ProjectYakuza
local E={active=setmetatable({}, {__mode="k"}),pending=setmetatable({}, {__mode="k"})}
PY.StyleEntry=E
local function now()return getTimestampMs()end
local A=ISBaseTimedAction:derive("ProjectYakuzaStyleEntryAction")
E.Action=A
function A:adjustMaxTime(v)return v end
function A:isUsingTimeout()return false end
function A:isValid()
    local p=self.character
    return PY.isEquipped(p) and PY.getPlayerStyle(p).id==self.context.style.id
        and not p:isDead() and not p:isOnFloor() and not p:isKnockedDown()
        and not p:isClimbing() and not p:getVehicle() and not p:isAsleep()
        and not p:isDraggingCorpse() and (p:getHitReaction() or "")==""
end
function A:start()
    self.started=true;self.startedAt=now();self.lastAt=self.startedAt
    local p=self.character
    self.oldBlock=p:isBlockMovement();self.oldIgnore=p:getIgnoreMovement()
    self.oldDeferred=p:isDeferredMovementEnabled()
    self.anchorX,self.anchorY=p:getX(),p:getY()
    p:setBlockMovement(true);p:setIgnoreMovement(true);p:setDeferredMovementEnabled(false)
    self:holdPosition()
    PY.setVisual(p,true,"");p:setVariable("ProjectYakuzaStyle",self.context.style.id)
    p:setVariable("ProjectYakuzaWeaponProfile",self.context.style.weaponProfile or "")
    self.character:setVariable("ProjectYakuzaStyleEntry","")
    self:setActionAnim(self.context.action.animation)
    self.action:setOverrideHandModelsObject(p:getPrimaryHandItem(),nil,false)
    E.active[self.character]=self
    if not E.hooked then Events.OnTick.Add(E.holdPositions);E.hooked=true end
    PY.emit("styleEntryStarted",self.character,self.context.style)
end
function A:holdPosition()
    local p=self.character
    PY.Defense.snapActor(p,self.anchorX,self.anchorY)
    p:getMovementLastFrame():set(0,0)
    p:setMoving(false);p:setRunning(false);p:setSprinting(false)
end
function E.holdPositions()
    if isGamePaused() then return end
    for _,a in pairs(E.active) do if not a.cleaned then a:holdPosition() end end
end
function A:cleanup(completed)
    if self.cleaned then return end
    self.cleaned=true;local p=self.character
    E.active[p]=nil
    if self.started then
        p:setBlockMovement(self.oldBlock==true);p:setIgnoreMovement(self.oldIgnore==true)
        p:setDeferredMovementEnabled(self.oldDeferred);p:setVariable("ProjectYakuzaStyleEntry","")
        PY.releaseActionAnimation(p,self,false)
    end
    local any=false;for _ in pairs(E.active) do any=true;break end
    if not any and E.hooked then Events.OnTick.Remove(E.holdPositions);E.hooked=false end
    if PY.activeActions[p]==self.context then
        if completed then PY.completeAction(p) else PY.cancelAction(p,"style_entry_interrupted") end
    end
    if self.started then PY.emit("styleEntryStopped",p,completed==true) end
end
function A:perform()self:cleanup(true);ISBaseTimedAction.perform(self)end
function A:stop()self:cleanup(false);ISBaseTimedAction.stop(self)end
function A:forceCancel()self:cleanup(false)end
function A:cancel()
    if self.cleaned then return end
    self:cleanup(false)
    if self.action then
        local list=self.character:getCharacterActions()
        if list:size()==1 and list:contains(self.action) then

            self.character:StopAllActionQueue()
        else self:forceStop() end
    elseif self.context.queue then
        local q=self.context.queue
        if q.current==self and q.onCompleted then q:onCompleted(self)
        elseif q.removeFromQueue then q:removeFromQueue(self) end
    end
end
function A:update()
    if self.cleaned then return end
    local t=now();local elapsed=math.max(0,t-self.lastAt);self.lastAt=t
    if isGamePaused() then self.startedAt=self.startedAt+elapsed;return end
    if not self:isValid() then self:forceStop();return end
    self:holdPosition()
    local marker=self.character:GetVariable("ProjectYakuzaStyleEntry") or ""
    if marker=="started" then self.seenClip=true end
    if self.seenClip and (marker=="done"or t-self.startedAt>=self.context.action.duration*1000)then self:forceComplete()
    elseif t-self.startedAt>self.context.action.duration*1000+800 or (t-self.startedAt>600 and not self.seenClip) then self:forceStop() end
end
function A:new(c)
    local o=ISBaseTimedAction.new(self,c.player);o.context=c;o.maxTime=-1
    o.stopOnWalk=false;o.stopOnRun=false;o.stopOnAim=false;o.ignoreHandsWounds=true
    return o
end
PY.registerActionHandler("styleEntry",{
    canStart=function(c)
        local p=c.player
        return type(c.action.duration)=="number" and c.action.duration>0
            and p:isLocalPlayer() and not isGamePaused() and not p:hasTimedActions()
            and not p:isDead() and not p:isOnFloor() and not p:isKnockedDown()
            and not p:isClimbing() and not p:getVehicle() and not p:isAsleep()
            and not p:isDraggingCorpse() and not p:isBlockMovement() and not p:getIgnoreMovement()
            and not p:isAttackStarted() and not p:isPerformingAttackAnimation()
            and (not p.isWeaponReady or p:isWeaponReady())
            and (p:getHitReaction() or "")=="","not_ready"
    end,
    start=function(c)
        if c.variant=="switch" and type(c.action.switchDuration)=="number" and c.action.switchDuration>0 then
            local action={};for key,value in pairs(c.action)do action[key]=value end
            action.duration=math.min(action.duration,action.switchDuration);c.action=action
        end
        PY.resetPlayer(c.player,"style_entry_started")
        local a=A:new(c);c.timedAction=a;c.requestedAt=now()
        local ok,q=pcall(ISTimedActionQueue.add,a)
        if not ok or not q then a:cancel();return false,"queue_rejected" end
        c.queue=q;return true
    end,
    cancel=function(c)if c.timedAction then c.timedAction:cancel() end end,
})
function E.request(p,styleId,hadStyle)
    local style=PY.getPlayerStyle(p)
    if not style or style.id~=styleId then return false,"style_changed" end
    if not style.actions.styleEntry or not style.actions.styleEntry.enabled then return false,"not_implemented" end
    local ok,reason=PY.requestAction(p,"styleEntry",hadStyle==true and "switch" or nil)
    if ok then return true end
    if reason~="not_ready" and reason~="style_not_equipped" then return false,reason end
    if reason=="not_ready" and not p:hasTimedActions() and (not p.isWeaponReady or p:isWeaponReady()) then return false,reason end
    E.pending[p]={style=styleId,hadStyle=hadStyle==true,item=p:getPrimaryHandItem(),expires=now()+2000,nextTry=now()+50,last=now()}
    if not E.pendingHook then Events.OnTick.Add(E.retry);E.pendingHook=true end
    if PY.Bindings then PY.Bindings.update(p) end
    return true,"pending_equipment"
end
function E.retry()
    if isGamePaused() then
        local t=now();for _,job in pairs(E.pending) do job.expires=job.expires+math.max(0,t-(job.last or t));job.last=t end
        return
    end
    local t=now()
    for p,job in pairs(E.pending) do
        local style=PY.getPlayerStyle(p)
        if p:isDead() or p:getVehicle() or (p:getHitReaction() or "")~="" or not style or style.id~=job.style or p:getPrimaryHandItem()~=job.item then E.pending[p]=nil
        elseif t>job.expires then
            E.pending[p]=nil;print("[ProjectYakuza] style entry timed out waiting for equipment/actions: "..job.style)
        elseif t>=job.nextTry then
            E.pending[p]=nil
            local ok,reason=PY.requestAction(p,"styleEntry",job.hadStyle and "switch" or nil)
            if not ok and (reason=="not_ready" or reason=="busy" or reason=="style_not_equipped") then job.nextTry=t+50;job.last=t;E.pending[p]=job end
        end
    end
    local any=false;for _ in pairs(E.pending) do any=true;break end
    if not any and E.pendingHook then Events.OnTick.Remove(E.retry);E.pendingHook=false end
end
function E.watch(p,c)
    if not c.timedAction.started and now()-c.requestedAt>600 then PY.cancelAction(p,"style_entry_start_timeout");return false end
    if c.timedAction.started and not c.timedAction.cleaned then c.timedAction:holdPosition() end
    return PY.activeActions[p]==c
end
function E.clear()
    E.pending=setmetatable({}, {__mode="k"})
    if E.pendingHook then Events.OnTick.Remove(E.retry);E.pendingHook=false end
    local players={};for p,c in pairs(PY.activeActions) do if c.kind=="styleEntry" then players[#players+1]=p end end
    for _,p in ipairs(players) do PY.cancelAction(p,"world_exit") end
end
PY.on("styleChanged",function(p)E.pending[p]=nil;E.retry()end)
Events.OnSave.Add(E.clear)
Events.OnMainMenuEnter.Add(E.clear)
