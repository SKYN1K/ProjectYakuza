require "ProjectYakuza/Runtime"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
local ProjectYakuza = ProjectYakuza
local Q = { input={}, nextAllowed={}, pending=setmetatable({}, {__mode="k"}),shoveDown=setmetatable({}, {__mode="k"}),shoveAuth=setmetatable({}, {__mode="k"}) }
ProjectYakuza.Quicksteps = Q
local function now() return getTimestampMs() end
Q.limit=3;Q.windowMs=15000
function Q.quota(p)
    local t=now();local d=p:getModData();local history=d.ProjectYakuzaQuickstepTimes or {};local keep={}
    for _,stamp in ipairs(history) do if type(stamp)=="number" and stamp>t-Q.windowMs and stamp<=t then keep[#keep+1]=stamp end end
    d.ProjectYakuzaQuickstepTimes=keep
    return math.max(0,Q.limit-#keep),#keep>=Q.limit and math.max(0,keep[1]+Q.windowMs-t) or 0
end
function Q.spend(p)
    local available=Q.quota(p);if available<=0 then return false end
    local times=p:getModData().ProjectYakuzaQuickstepTimes;times[#times+1]=now();return true
end
local function var(player, name) return player:GetVariable(name) or "" end
function Q.facing(player)
    local vector=player:getForwardDirection()
    if not vector then return nil end
    -- Kahlua exposes Vector2 getters; its public Java fields are not Lua properties.
    local x,y=vector:getX(),vector:getY()
    if type(x)~="number" or type(y)~="number" then return nil end
    return x,y
end
function Q.direction(fx, fy, dx, dy)
    if type(fx)~="number" or type(fy)~="number" or type(dx)~="number" or type(dy)~="number" then return nil end
    local length = math.sqrt(dx*dx + dy*dy)
    if length < 0.001 then return nil end
    dx,dy = dx/length,dy/length
    local facingLength = math.sqrt(fx*fx + fy*fy)
    if facingLength < 0.001 then return nil end
    fx,fy = fx/facingLength,fy/facingLength
    local forward, right = dx*fx+dy*fy, dx*(-fy)+dy*fx
    if math.abs(forward) >= math.abs(right) then return forward>=0 and "forward" or "backward",dx,dy,fx,fy end
    return right>=0 and "right" or "left",dx,dy,fx,fy
end
function Q.canMove(player, dx, dy, originX, originY)
    local x,y,z=originX or player:getX(),originY or player:getY(),math.floor(player:getZ())
    local cell=getCell()
    local source=cell:getGridSquare(math.floor(x),math.floor(y),z)
    local target=cell:getGridSquare(math.floor(x+dx),math.floor(y+dy),z)
    if not source or not target or not target:TreatAsSolidFloor() or target:isSolid() or target:isSolidTrans() then return false end
    local tx,ty=math.floor(x+dx)-math.floor(x),math.floor(y+dy)-math.floor(y)
    if (tx~=0 or ty~=0) and source:testCollideAdjacent(player,tx,ty,0) then return false end
    return true
end
local A = ISBaseTimedAction:derive("ProjectYakuzaQuickstepAction")
Q.Action = A
function A:isValid()
    local p=self.character
    local hit=p:getHitReaction()
    return ProjectYakuza.isEquipped(p) and (p:isAiming() or self.context.shove) and not p:isDead() and not p:isOnFloor()
        and not p:isKnockedDown() and not p:isClimbing() and p:getVehicle()==nil
        and not p:isAttackStarted() and not p:isPerformingAttackAnimation() and (not hit or hit=="")
end
function A:adjustMaxTime(value) return value end
function A:isUsingTimeout() return false end
function A:start()
    local p=self.character
    if not Q.spend(p) then self:forceStop();return end
    self.started=true; self.startedAt=now(); self.moved=0; self.blocked=false
    self.oldBlock=p:isBlockMovement(); self.oldIgnore=p:getIgnoreMovement()
    p:setBlockMovement(true);p:setIgnoreMovement(true)
    p:setVariable("ProjectYakuzaQuickstepProgress","0")
    p:setVariable("ProjectYakuzaQuickstepStarted","")
    p:setVariable("ProjectYakuzaQuickstepDone","")
    self:setActionAnim(self.context.action.animation)
    -- A native hand-model override also prevents native melee submission during the action.
    self.action:setOverrideHandModelsObject(p:getPrimaryHandItem(),nil,false)
    if ProjectYakuza.Network then ProjectYakuza.Network.step(p,self,false) end
    if p:getModData().ProjectYakuzaDiagnostics then print("[ProjectYakuza] quickstep "..self.context.action.direction) end
end
function A:cleanup(completed, reason)
    if self.cleaned then return end
    self.cleaned=true
    local p=self.character
    if self.started then
        if ProjectYakuza.Network then ProjectYakuza.Network.step(p,self,true) end
        p:setBlockMovement(self.oldBlock==true);p:setIgnoreMovement(self.oldIgnore==true)
        p:setVariable("ProjectYakuzaQuickstepProgress","")
        p:setVariable("ProjectYakuzaQuickstepStarted","")
        p:setVariable("ProjectYakuzaQuickstepDone","")
    end
    Q.nextAllowed[p:getPlayerNum()]=now()+(self.context.style.actions.quickstep.cooldownMs or 180)
    if ProjectYakuza.activeActions[p]==self.context then
        if completed then ProjectYakuza.completeAction(p) else ProjectYakuza.cancelAction(p,reason or "interrupted") end
    end
end
function Q.pollAttack(player,context)
    local down=ProjectYakuza.Bindings.down("quickstepAttack")
    if player:isAiming() and down and not context.lastAttackDown then context.timedAction.attackRequested=true end
    context.lastAttackDown=down
end
function A:update()
    if self.cleaned then return end
    if not self:isValid() then self:forceStop();return end
    local p,move=self.character,self.context.action
    local elapsed=now()-self.startedAt
    local started=var(p,"ProjectYakuzaQuickstepStarted")==move.nodeValue
    if not started and elapsed>500 then self:forceStop();return end
    if elapsed>move.duration*1000+1000 then self:forceStop();return end
    if started then
        local progress=math.max(0,math.min(1,tonumber(var(p,"ProjectYakuzaQuickstepProgress")) or 0))
        if self.attackRequested and progress>=0.25 then
            self.attackHandover=true
            self:forceComplete();return
        end
        local remaining=math.max(0,move.distance*progress-self.moved)
        local moved=0;local x,y=p:getX(),p:getY()
        while remaining>.000001 and not self.blocked do
            local step=math.min(.08,remaining)
            if Q.canMove(p,self.context.dx*step,self.context.dy*step,x+self.context.dx*moved,y+self.context.dy*moved) then
                moved=moved+step;remaining=remaining-step
            else self.blocked=true end
        end
        if moved>0 then
            p:moveUnmodded(self.context.dx*moved,self.context.dy*moved)
            self.moved=self.moved+moved
        end
        if ProjectYakuza.Network then ProjectYakuza.Network.step(p,self,false) end
    end
    if var(p,"ProjectYakuzaQuickstepDone")==move.nodeValue then self:forceComplete() end
end
function A:perform()
    local p=self.character
    self:cleanup(true)
    ISBaseTimedAction.perform(self)
    if self.attackHandover and ProjectYakuza.isEquipped(p) and p:isAiming() and not p:isDead() then
        Q.pending[p]={direction=self.context.action.direction,expiresAt=now()+500}
    end
end
function A:stop()
    self:cleanup(false,"quickstep_interrupted")
    ISBaseTimedAction.stop(self)
end
function A:forceCancel() self:cleanup(false,"quickstep_cancelled") end
function A:new(context)
    local o=ISBaseTimedAction.new(self,context.player)
    o.context=context;o.maxTime=-1;o.stopOnWalk=false;o.stopOnRun=false;o.stopOnAim=false
    o.ignoreHandsWounds=true;o.caloriesModifier=1
    return o
end
ProjectYakuza.registerActionHandler("quickstep",{
    canStart=function(context)
        local p=context.player
        context.shove=type(context.target)=="table" and context.target.shove==true
        local hit=p:getHitReaction()
        if not p:isLocalPlayer() or (not p:isAiming() and not context.shove) or p:isDead() or p:isOnFloor() or p:isKnockedDown()
            or p:isClimbing() or p:getVehicle() or p:isDraggingCorpse() or p:isAsleep()
            or p:hasTimedActions() or p:isAttackStarted() or p:isPerformingAttackAnimation()
            or p:isBlockMovement() or p:getIgnoreMovement() or (hit and hit~="") then return false,"not_ready" end
        if Q.quota(p)<=0 then return false,"quickstep_limit" end
        if ProjectYakuza.Network and isClient() and not ProjectYakuza.Network.equipmentReady(p) then return false,"equipment_pending" end
        if now()<(Q.nextAllowed[p:getPlayerNum()] or 0) then return false,"cooldown" end
        return true
    end,
    start=function(context)
        local p=context.player
        local fx,fy=Q.facing(p);if not fx then return false,"no_facing" end
        local n=math.sqrt(fx*fx+fy*fy);if n<0.001 then return false,"no_facing" end;fx,fy=fx/n,fy/n
        local name=context.action.direction
        local dx,dy=fx,fy
        if name=="backward" then dx,dy=-fx,-fy
        elseif name=="left" then dx,dy=fy,-fx
        elseif name=="right" then dx,dy=-fy,fx end
        if context.target and context.target.dx and context.target.dy then
            local length=math.sqrt(context.target.dx^2+context.target.dy^2)
            if length<0.001 then return false,"no_direction" end
            dx,dy=context.target.dx/length,context.target.dy/length
        end
        context.dx,context.dy=dx,dy
        context.lastAttackDown=ProjectYakuza.Bindings.down("quickstepAttack")
        if not Q.canMove(p,dx*0.08,dy*0.08) then return false,"blocked" end
        ProjectYakuza.resetPlayer(p,"quickstep_started")
        local action=A:new(context);context.timedAction=action;context.requestedAt=now()
        local ok,queue=pcall(ISTimedActionQueue.add,action)
        if not ok or not queue then action:cleanup(false,"queue_rejected");return false,"queue_rejected" end
        return true
    end,
    cancel=function(context,reason)
        local action=context.timedAction
        if action and not action.cleaned then
            action:cleanup(false,reason)
            if action.action then action:forceStop() end
        end
    end,
})
local function key(id) local code=getCore():getKey(id:getId());return code and code>0 and isKeyDown(code) end
function Q.restoreShove(player)
    local saved=Q.shoveAuth[player]
    if saved then player:setAuthorizeMeleeAction(saved.allowed);Q.shoveAuth[player]=nil end
    Q.shoveDown[player]=nil
end
function Q.movement()
    local dx,dy=0,0
    if key(KeybindId.FORWARD) then dx,dy=dx-1,dy-1 end
    if key(KeybindId.BACKWARD) then dx,dy=dx+1,dy+1 end
    if key(KeybindId.LEFT) then dx,dy=dx-1,dy+1 end
    if key(KeybindId.RIGHT) then dx,dy=dx+1,dy-1 end
    return dx,dy
end
function Q.pollShove(player)
    local active=ProjectYakuza.activeActions[player]
    if active and active.kind=="styleEntry" then
        Q.shoveDown[player]=ProjectYakuza.Bindings.down("quickstep");return false
    end
    local style=ProjectYakuza.getPlayerStyle(player);local slot=style and style.actions.quickstep
    local scoped=ProjectYakuza.isEquipped(player) and slot and slot.enabled==true and not player:isDead()
        and not player:getVehicle() and not player:isOnFloor() and not player:isKnockedDown()
        and not player:isClimbing() and not player:isDraggingCorpse() and not player:isAsleep()
        and not getCore():isDoingTextEntry()
    if not scoped then Q.restoreShove(player);return false end
    local down=ProjectYakuza.Bindings.down("quickstep")
    if not down then Q.restoreShove(player);return false end
    if not Q.shoveAuth[player] then Q.shoveAuth[player]={allowed=(ProjectYakuza.Bindings.attackGates[player] and ProjectYakuza.Bindings.attackGates[player].allowed) or player:isAuthorizeMeleeAction()} end
    -- Gate native shove only while its key is held. Framework attacks temporarily
    -- lift our gate because PZ DoAttack also checks this permission.
    player:setAuthorizeMeleeAction(false)
    local pressed=not Q.shoveDown[player]
    Q.shoveDown[player]=down
    if not pressed or isGamePaused() then return false end
    local fx,fy=Q.facing(player);if not fx then return false end
    local dx,dy=Q.movement()
    if dx==0 and dy==0 then dx,dy=-fx,-fy end
    local direction,x,y=Q.direction(fx,fy,dx,dy)
    if not direction then return false end
    local ok,reason=ProjectYakuza.requestAction(player,"quickstep",direction,{dx=x,dy=y,shove=true})
    if not ok and reason=="quickstep_limit" and ProjectYakuza.Feedback then
        local _,wait=Q.quota(player);ProjectYakuza.Feedback.notice(player,"QUICKSTEP - "..math.ceil(wait/1000).."s")
    end
    return ok
end
function Q.restoreAllShoves()
    for player in pairs(Q.shoveAuth) do Q.restoreShove(player) end
end
function Q.update(player)
    if not player or not instanceof(player,"IsoPlayer") or not player:isLocalPlayer() then return end
    if Q.pollShove(player) then return end
    local pending=Q.pending[player]
    if pending then
        if not ProjectYakuza.isEquipped(player) or not player:isAiming() or player:isDead() or player:isOnFloor() or player:isKnockedDown()
            or player:isClimbing() or player:getVehicle() or player:isDraggingCorpse() or player:isAsleep() or now()>pending.expiresAt or (player:getHitReaction() or "")~="" then
            Q.pending[player]=nil
        elseif not ProjectYakuza.activeActions[player] and not player:hasTimedActions() and player:isWeaponReady() then
            local ok,reason=ProjectYakuza.requestAction(player,"quickstepAttack",pending.direction,pending)
            if ok or (reason~="busy" and reason~="native_attack_busy" and reason~="native_attack_rejected") then Q.pending[player]=nil end
        end
        return
    end
    local context=ProjectYakuza.activeActions[player]
    if context and context.kind=="quickstep" then
        local action=context.timedAction
        if not ProjectYakuza.isEquipped(player) or player:isDead() or (not player:isAiming() and not context.shove)
            or (not action.started and now()-context.requestedAt>500) then ProjectYakuza.cancelAction(player,"quickstep_cancelled") end
    end
end
Events.OnPlayerUpdate.Add(Q.update)
Events.OnSave.Add(Q.restoreAllShoves)
Events.OnMainMenuEnter.Add(Q.restoreAllShoves)
