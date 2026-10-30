require "ProjectYakuza/Runtime"
require "ProjectYakuza/Defense"
require "ISUI/ISEmoteRadialMenu"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
local ProjectYakuza=ProjectYakuza
local T={active=setmetatable({}, {__mode="k"}),consumed={}}
ProjectYakuza.Taunts=T
local function now()return getTimestampMs()end
function T.available(p)
    if not p or not ProjectYakuza.isEquipped(p) then return false end
    local slot=ProjectYakuza.getPlayerStyle(p).actions.taunt
    return slot and slot.enabled==true or false
end
function T.request(p)
    if not T.available(p) or not ProjectYakuza.Defense.ready(p) then return false,"not_ready" end
    if getCore():isDoingTextEntry() then return false,"text_entry" end
    return ProjectYakuza.requestAction(p,"taunt")
end
function T.holdPositions()
    if isGamePaused() then return end
    for _,a in pairs(T.active) do if not a.cleaned then a:holdPosition() end end
end
local A=ISBaseTimedAction:derive("ProjectYakuzaTauntAction")
T.Action=A
function A:adjustMaxTime(v)return v end
function A:isUsingTimeout()return false end
function A:isValid()
    local p=self.character
    return ProjectYakuza.isEquipped(p) and ProjectYakuza.getPlayerStyle(p).id==self.context.style.id
        and not p:isDead() and not p:isOnFloor() and not p:isKnockedDown()
        and not p:isClimbing() and not p:getVehicle() and not p:isAsleep()
        and not p:isDraggingCorpse() and (p:getHitReaction() or "")==""
end
function A:holdPosition()
    local p=self.character
    ProjectYakuza.Defense.snapActor(p,self.anchorX,self.anchorY)
    p:getMovementLastFrame():set(0,0)
    p:setMoving(false);p:setRunning(false);p:setSprinting(false)
end
function A:start()
    local p=self.character
    self.started=true;self.startedAt=now();self.lastAt=self.startedAt
    self.oldBlock=p:isBlockMovement();self.oldIgnore=p:getIgnoreMovement()
    self.oldDeferred=p:isDeferredMovementEnabled()
    self.anchorX,self.anchorY=p:getX(),p:getY()
    p:setBlockMovement(true);p:setIgnoreMovement(true);p:setDeferredMovementEnabled(false)
    self:holdPosition()
    p:setVariable("ProjectYakuzaTaunt","")
    self:setActionAnim(self.context.action.animation)
    self.action:setOverrideHandModelsObject(p:getPrimaryHandItem(),nil,false)
    T.active[p]=self
    if not T.hooked then Events.OnTick.Add(T.holdPositions);T.hooked=true end
    ProjectYakuza.emit("tauntStarted",p)
end
function A:cleanup(completed)
    if self.cleaned then return end
    self.cleaned=true;local p=self.character
    T.active[p]=nil
    if self.started then
        p:setBlockMovement(self.oldBlock==true);p:setIgnoreMovement(self.oldIgnore==true)
        p:setDeferredMovementEnabled(self.oldDeferred);p:setVariable("ProjectYakuzaTaunt","")
    end
    local any=false;for _ in pairs(T.active) do any=true;break end
    if not any and T.hooked then Events.OnTick.Remove(T.holdPositions);T.hooked=false end
    if ProjectYakuza.activeActions[p]==self.context then
        if completed then ProjectYakuza.completeAction(p) else ProjectYakuza.cancelAction(p,"taunt_interrupted") end
    end
    if self.started then ProjectYakuza.emit("tauntStopped",p,completed==true) end
end
function A:perform()
    if self.cleaned then return end

    local complete=self.started and self.seenClip and self.character:GetVariable("ProjectYakuzaTaunt")=="done" and self:isValid()
    if complete and not ProjectYakuza.Heat.isExtreme(self.character) then
        ProjectYakuza.setHeat(self.character,ProjectYakuza.getHeat(self.character)+ProjectYakuza.Heat.stockSize())
    end
    self:cleanup(complete==true);ISBaseTimedAction.perform(self)
end
function A:stop()self:cleanup(false);ISBaseTimedAction.stop(self)end
function A:cancel()
    if self.cleaned then return end
    self:cleanup(false)
    if self.action then self:forceStop()
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
    local marker=self.character:GetVariable("ProjectYakuzaTaunt") or ""
    if marker=="started" then self.seenClip=true end
    if marker=="done" and self.seenClip then self:forceComplete()
    elseif t-self.startedAt>self.context.action.duration*1000+800 or (t-self.startedAt>600 and not self.seenClip) then self:forceStop() end
end
function A:new(c)
    local o=ISBaseTimedAction.new(self,c.player);o.context=c
    o.maxTime=-1;o.stopOnWalk=false;o.stopOnRun=false;o.stopOnAim=false;o.ignoreHandsWounds=true
    return o
end
ProjectYakuza.registerActionHandler("taunt",{
    canStart=function(c)
        if type(c.action.duration)~="number" or c.action.duration<=0 then return false,"animation_duration_required" end
        return ProjectYakuza.Defense.ready(c.player),"not_ready"
    end,
    start=function(c)
        ProjectYakuza.resetPlayer(c.player,"taunt_started")
        local a=A:new(c);c.timedAction=a;c.requestedAt=now()
        local ok,q=pcall(ISTimedActionQueue.add,a)
        if not ok or not q then a:cancel();return false,"queue_rejected" end
        c.queue=q;return true
    end,
    cancel=function(c)if c.timedAction then c.timedAction:cancel() end end,
})
function T.watch(p,c)
    if not c.timedAction.started and now()-c.requestedAt>600 then ProjectYakuza.cancelAction(p,"taunt_start_timeout") end
    if c.timedAction.started and not c.timedAction.cleaned then c.timedAction:holdPosition() end
end
function T.bindInput()
    if T.bound then return end
    T.bound=true

    local handlers={{"onKeyPressed",Events.OnKeyStartPressed},{"onKeyRepeat",Events.OnKeyKeepPressed},{"onKeyReleased",Events.OnKeyPressed}}
    for index,entry in ipairs(handlers) do
        local name,event=entry[1],entry[2];local original=ISEmoteRadialMenu[name];local phase=index
        event.Remove(original)
        local wrapper=function(key)
            if phase==1 then
                local p=getSpecificPlayer(0)
                if ProjectYakuza.Bindings.matches("taunt",key) and T.available(p) and p:isAiming() and not p:getVehicle()
                    and not getCore():isDoingTextEntry() and not isGamePaused() then
                    T.consumed[key]=true;return
                end
            elseif T.consumed[key] then
                if phase==3 then T.consumed[key]=nil end
                return
            end
            original(key)
        end
        ISEmoteRadialMenu[name]=wrapper;event.Add(wrapper)
    end
end
function T.poll(p)
    if p and p:isLocalPlayer() and ProjectYakuza.Bindings.pressed(p,"taunt") then T.request(p) end
end
Events.OnPlayerUpdate.Add(T.poll)
function T.clear()
    local players={};for p,c in pairs(ProjectYakuza.activeActions) do if c.kind=="taunt" then players[#players+1]=p end end
    for _,p in ipairs(players) do ProjectYakuza.cancelAction(p,"world_exit") end
    T.consumed={}
end
Events.OnGameStart.Add(T.bindInput)
Events.OnSave.Add(T.clear)
Events.OnMainMenuEnter.Add(T.clear)
