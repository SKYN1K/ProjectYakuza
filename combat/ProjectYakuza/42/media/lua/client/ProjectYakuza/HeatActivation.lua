require "ProjectYakuza/Runtime"
require "ProjectYakuza/Defense"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
local ProjectYakuza=ProjectYakuza
local E={active=setmetatable({}, {__mode="k"}),last=setmetatable({}, {__mode="k"})}
ProjectYakuza.HeatActivation=E
local function now()return getTimestampMs()end
function E.restore(p)
    local d=p:getModData()
    if d.ProjectYakuzaActivationOldGhost~=nil then p:setGhostMode(d.ProjectYakuzaActivationOldGhost);d.ProjectYakuzaActivationOldGhost=nil end
    if d.ProjectYakuzaActivationOldInvincible~=nil then p:setInvincible(d.ProjectYakuzaActivationOldInvincible);d.ProjectYakuzaActivationOldInvincible=nil end
end
function E.ready(p)
    return ProjectYakuza.Sandbox.enabled("ExtremeHeat")and ProjectYakuza.Defense.ready(p) and ProjectYakuza.Heat.enabled(p) and not ProjectYakuza.Heat.isExtreme(p) and ProjectYakuza.Heat.stocks(p)>=1
end
function E.protect(z)
    if not z or not instanceof(z,"IsoZombie") or z:isDead() then return end
    local p=z:getTarget();local a=p and E.active[p]
    if not a then return end
    if math.abs(z:getZ()-p:getZ())>.5 or (z:getX()-p:getX())^2+(z:getY()-p:getY())^2>9 then return end
    a.targets[z]=true
    z:setTarget(nil);z:setAttackOutcome("fail");z:setVariable("ProjectYakuzaTigerWindow",false)
    if z:isAttacking() then z:setHitReaction("BiteDefended");z:reportEvent("wasHit") end
end
function E.scan(p)
    local cell=getCell();local x,y,z=math.floor(p:getX()),math.floor(p:getY()),math.floor(p:getZ())
    for ox=-2,2 do for oy=-2,2 do
        local sq=cell:getGridSquare(x+ox,y+oy,z);local objects=sq and sq:getMovingObjects()
        if objects then for i=0,objects:size()-1 do E.protect(objects:get(i)) end end
    end end
end
function E.holdPositions()
    for p,a in pairs(E.active) do if a.started and not a.cleaned then a:holdPosition() end end
end
local A=ISBaseTimedAction:derive("ProjectYakuzaHeatActivationAction")
E.Action=A
function A:adjustMaxTime(v)return v end
function A:isUsingTimeout()return false end
function A:isValid()
    local p=self.character
    return ProjectYakuza.Sandbox.enabled("ExtremeHeat")and ProjectYakuza.isEquipped(p) and not p:isDead() and not p:isOnFloor() and not p:isKnockedDown()
        and not p:isClimbing() and not p:getVehicle() and (p:getHitReaction() or "")==""
end
function A:start()
    local p=self.character;local d=p:getModData()
    self.started=true;self.startedAt=now();self.lastAt=self.startedAt
    self.oldBlock=p:isBlockMovement();self.oldIgnore=p:getIgnoreMovement()
    self.oldDeferred=p:isDeferredMovementEnabled()
    self.anchorX,self.anchorY=p:getX(),p:getY()
    local protection=ProjectYakuza.HeatActions;local grace=protection and protection.active[p]
    if grace and not grace.playing then protection.restore(p,grace)end
    d.ProjectYakuzaActivationOldGhost=p:isGhostMode();d.ProjectYakuzaActivationOldInvincible=p:isInvincible()
    p:setBlockMovement(true);p:setIgnoreMovement(true)
    p:setDeferredMovementEnabled(false)
    self:holdPosition()

    if ProjectYakuza.HeatActions.useGhostProtection()then p:setGhostMode(true)end;p:setInvincible(true)
    E.active[p]=self
    if not E.hooked then Events.OnZombieUpdate.Add(E.protect);Events.OnTick.Add(E.holdPositions);E.hooked=true end
    E.scan(p)
    p:setVariable("ProjectYakuzaHeatActivation","")
    self:setActionAnim(self.context.action.animation)
    self.action:setOverrideHandModelsObject(p:getPrimaryHandItem(),nil,false)
    ProjectYakuza.emit("heatActivationStarted",p)
end
function A:holdPosition()
    local p=self.character
    ProjectYakuza.Defense.snapActor(p,self.anchorX,self.anchorY)
    p:getMovementLastFrame():set(0,0)
    p:setMoving(false);p:setRunning(false);p:setSprinting(false)
end
function A:cleanup(completed)
    if self.cleaned then return end
    self.cleaned=true;local p=self.character
    if self.started then
        E.restore(p)
        p:setBlockMovement(self.oldBlock==true);p:setIgnoreMovement(self.oldIgnore==true)
        p:setDeferredMovementEnabled(self.oldDeferred)
        p:setVariable("ProjectYakuzaHeatActivation","")
        for z in pairs(self.targets) do if not z:isDead() and z:getTarget()==nil and not p:isDead() then z:setTarget(p) end end
        ProjectYakuza.emit("heatActivationStopped",p,completed==true)
    end
    E.active[p]=nil
    local any=false;for _ in pairs(E.active) do any=true;break end
    if not any and E.hooked then Events.OnZombieUpdate.Remove(E.protect);Events.OnTick.Remove(E.holdPositions);E.hooked=false end
    if ProjectYakuza.activeActions[p]==self.context then
        if completed then ProjectYakuza.completeAction(p) else ProjectYakuza.cancelAction(p,"heat_activation_interrupted") end
    end
end
function A:perform()
    local ok=ProjectYakuza.Heat.start(self.character,self.context)
    self:cleanup(ok==true);ISBaseTimedAction.perform(self)
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
    local marker=self.character:GetVariable("ProjectYakuzaHeatActivation") or ""
    if marker=="started" or marker=="flare" or marker=="done" then self.seenClip=true end
    if marker=="flare" and not self.flared then self.flared=true;ProjectYakuza.emit("heatActivationFlare",self.character) end
    if marker=="done" and self.seenClip then self:forceComplete()
    elseif t-self.startedAt>self.context.action.duration*1000+800 or (t-self.startedAt>600 and not self.seenClip) then self:forceStop() end
end
function A:new(c)
    local o=ISBaseTimedAction.new(self,c.player);o.context=c;o.targets=setmetatable({}, {__mode="k"})
    o.maxTime=-1;o.stopOnWalk=false;o.stopOnRun=false;o.stopOnAim=false;o.ignoreHandsWounds=true
    return o
end
ProjectYakuza.registerActionHandler("heatActivation",{
    canStart=function(c)
        if type(c.action.duration)~="number" or c.action.duration<=0 then return false,"animation_duration_required" end
        return E.ready(c.player),"not_ready"
    end,
    start=function(c)
        ProjectYakuza.resetPlayer(c.player,"heat_activation_started")
        local a=A:new(c);c.timedAction=a;c.requestedAt=now()
        local ok,q=pcall(ISTimedActionQueue.add,a)
        if not ok or not q then a:cancel();return false,"queue_rejected" end
        c.queue=q
        E.last[c.player]={style=c.style.id,variant=c.variant};return true
    end,
    cancel=function(c)if c.timedAction then c.timedAction:cancel() end end,
})
function E.request(p)
    if not E.ready(p) then return false,"not_ready" end
    local style=ProjectYakuza.getPlayerStyle(p);local slot=style.actions.heatActivation
    if not slot or slot.enabled~=true then return false,"not_implemented" end
    if not slot.variants then return ProjectYakuza.requestAction(p,"heatActivation") end
    local keys,choices={},{}
    local previous=E.last[p]
    for id,action in pairs(slot.variants) do
        if action.enabled~=false then
            keys[#keys+1]=id
            if not previous or previous.style~=style.id or previous.variant~=id then choices[#choices+1]=id end
        end
    end
    if #choices==0 then choices=keys end
    if #choices==0 then return false,"not_implemented" end
    table.sort(choices,function(a,b)return tostring(a)<tostring(b)end)
    return ProjectYakuza.requestAction(p,"heatActivation",choices[ZombRand(#choices)+1])
end
function E.clear()
    local players={};for p,c in pairs(ProjectYakuza.activeActions) do if c.kind=="heatActivation" then players[#players+1]=p end end
    for _,p in ipairs(players) do ProjectYakuza.cancelAction(p,"world_exit");E.restore(p) end
end
function E.watch(p,c)
    if not c.timedAction.started and now()-c.requestedAt>600 then ProjectYakuza.cancelAction(p,"activation_start_timeout") end
    if c.timedAction.started and not c.timedAction.cleaned then c.timedAction:holdPosition() end
end
function E.recover()
    for i=0,3 do local p=getSpecificPlayer(i);if p and not E.active[p] then E.restore(p) end end
end
Events.OnSave.Add(E.clear)
Events.OnMainMenuEnter.Add(E.clear)
Events.OnGameStart.Add(E.recover)
Events.OnCreatePlayer.Add(function(index,p)if p and not E.active[p] then E.restore(p) end end)
