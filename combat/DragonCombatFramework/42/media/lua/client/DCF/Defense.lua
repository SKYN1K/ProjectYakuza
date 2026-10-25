require "DCF/Runtime"
require "DCF/MultiHit"
require "DCF/TigerDrop"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
local DCF=DragonCombat
local D={input=setmetatable({}, {__mode="k"}),held=setmetatable({}, {__mode="k"}),recovering={}}
DCF.Defense=D
DCF.Guard=D
local function now()return getTimestampMs()end
local function var(p,n)return p:GetVariable(n) or "" end
local function endurance(p)return p:getStats():get(CharacterStat.ENDURANCE)end
local function spend(p,n)p:getStats():remove(CharacterStat.ENDURANCE,n)end
function D.snapActor(actor,x,y)
    actor:setX(x);actor:setY(y)
    actor:setNextX(x);actor:setNextY(y)
    actor:setLastX(x);actor:setLastY(y)
    actor:setCurrentSquareFromPosition();actor:setMovingSquareNow()
end
function D.followZombie(z)
    local a=D.held[z]
    if not a or a.cleaned or a.phaseName~="hold" or isGamePaused() then return end
    if not a:isValid() or not a:alignPair(true) then a:cancel() end
end
function D.followHook()
    local active=false;for _ in pairs(D.held) do active=true;break end
    if active and not D.following then Events.OnZombieUpdate.Add(D.followZombie);D.following=true
    elseif not active and D.following then Events.OnZombieUpdate.Remove(D.followZombie);D.following=false end
end
function D.safe(p)
    return DCF.isEquipped(p) and p:isAiming() and not p:isDead() and not p:isOnFloor()
        and not p:isKnockedDown() and not p:isClimbing() and not p:getVehicle()
        and not p:isDraggingCorpse() and not p:isAsleep() and (p:getHitReaction() or "")==""
end
function D.ready(p)
    return D.safe(p) and not isGamePaused() and not DCF.isBusy(p) and not p:hasTimedActions()
        and not p:isBlockMovement() and not p:getIgnoreMovement()
        and not p:isAttackStarted() and not p:isPerformingAttackAnimation()
end
function D.canTrack(p)
    local c=DCF.activeActions[p]
    return D.safe(p) and ((c and c.kind=="block") or (D.ready(p) and DCF.Bindings.down("block")))
end
function D.target(p)
    if not DCF.MultiHit then return nil end
    local origin=DCF.MultiHit.origin(p,1.05)
    if not origin then return nil end
    for _,entry in ipairs(DCF.MultiHit.targets(p,origin,false,{},8)) do
        local z=entry.victim
        if not D.held[z] and not z:isAttacking() and not z:isUseless() and (z:getHitReaction() or "")=="" then return z end
    end
end
function D.restoreTargets()
    for i=#D.recovering,1,-1 do
        local r=D.recovering[i]
        if r.z:isDead() or now()>=r.untilAt or not r.z:isAttacking() then
            if not r.z:isDead() and not r.p:isDead() and DCF.isEquipped(r.p) and r.z:getTarget()==nil
                and (r.z:getX()-r.p:getX())^2+(r.z:getY()-r.p:getY())^2<9 then r.z:setTarget(r.p) end
            table.remove(D.recovering,i)
        end
    end
    if #D.recovering==0 and D.ticking then Events.OnTick.Remove(D.restoreTargets);D.ticking=false end
end
local A=ISBaseTimedAction:derive("DCFDefenseAction")
D.Action=A
function A:adjustMaxTime(v)return v end
function A:isUsingTimeout()return false end
function A:phase(name)
    self.phaseName=name;self.phaseAt=now()
    self.character:setVariable("DCFDefensePhase",name)
    self.character:setVariable("DCFDefenseMarker","")
    if self.context.kind=="grab" then
        local z=self.context.target
        z:setVariable("DCFGrabPhase",name);z:setVariable("DCFGrabMarker","")
        self:setGrabMoving(false)
        local walking=name=="hold"
        self.character:setBlockMovement(not walking)
        self.character:setIgnoreMovement(not walking)
        self.lastX=self.character:getX();self.lastY=self.character:getY()
    end
end
function A:setGrabMoving(moving,direction)
    if self.grabMoving~=moving then
        self.character:setVariable("DCFGrabMoving",moving)
        self.context.target:setVariable("DCFGrabMoving",moving)
        self.grabMoving=moving
    end
    if direction and self.walkDirection~=direction then
        self.context.target:setVariable("DCFGrabWalkDirection",direction);self.walkDirection=direction
    end
end
function A:alignPair(snap)
    local p,z=self.character,self.context.target
    D.followVector=D.followVector or Vector2.new()
    local f=snap=="throw" and p:getForwardDirection() or p:getAnimForwardDirection(D.followVector)
    local fx,fy=f:getX(),f:getY()
    local n=math.sqrt(fx*fx+fy*fy)
    if n<.001 then return false end
    fx,fy=fx/n,fy/n
    local dx,dy=p:getX()+fx*.7-z:getX(),p:getY()+fy*.7-z:getY()
    local origin={x=z:getX(),y=z:getY(),z=z:getZ()}
    if not DCF.MultiHit.clearPath(z,origin,dx,dy) then return false end
    -- Movement requests are deferred by PZ. Commit all current/next/render positions
    -- together after the swept path check so the held actor cannot trail behind.
    D.snapActor(z,p:getX()+fx*.7,p:getY()+fy*.7)
    self.context.fx,self.context.fy=fx,fy
    if snap=="throw" then p:setTargetAndCurrentDirection(fx,fy) end
    z:setTargetAndCurrentDirection(-fx,-fy)
    return true
end
function A:start()
    self.started=true;self.startedAt=now();self.lastAt=self.startedAt
    local p=self.character
    self.oldBlock=p:isBlockMovement();self.oldIgnore=p:getIgnoreMovement()
    p:setBlockMovement(self.context.kind~="block");p:setIgnoreMovement(self.context.kind~="block")
    self:setActionAnim(self.context.action.animation)
    self.action:setOverrideHandModelsObject(p:getPrimaryHandItem(),nil,false)
    if self.context.kind=="grab" then
        local z=self.context.target
        self.victimState={useless=z:isUseless(),ignore=z:getIgnoreMovement(),target=z:getTarget(),deferred=z:isDeferredMovementEnabled()}
        D.held[z]=self
        D.followHook()
        z:setAttackOutcome("fail");z:setTarget(nil);z:setUseless(true);z:setIgnoreMovement(true)
        z:setDeferredMovementEnabled(false)
        if DCF.Reactions then DCF.Reactions.clear(z) end
        z:setVariable("DCFGrabbed",true)
        z:setHitReaction("DCFGrabbed")
        z:setForwardDirection(-self.context.fx,-self.context.fy)
        z:reportEvent("wasHit")
    end
    self:phase("enter")
end
function A:isValid()
    if not D.safe(self.character) then return false end
    if self.context.kind=="grab" then
        local z=self.context.target
        return z and not z:isDead() and not z:isKnockedDown() and not z:isOnFloor()
            and math.abs(z:getZ()-self.character:getZ())<.5
            and (z:getX()-self.character:getX())^2+(z:getY()-self.character:getY())^2<2.25
            and (z:getHitReaction()=="DCFGrabbed" or (z:getHitReaction() or "")=="")
    end
    return true
end
function A:cleanup(completed)
    if self.cleaned then return end
    self.cleaned=true
    local p=self.character
    if self.context.kind=="grab" and isClient() and DCF.Network then DCF.Network.releaseGrab(p) end
    if self.started then
        p:setBlockMovement(self.oldBlock==true);p:setIgnoreMovement(self.oldIgnore==true)
        p:setVariable("DCFDefensePhase","");p:setVariable("DCFDefenseMarker","")
        p:setVariable("DCFGrabMoving",false)
        local z=self.context.target
        if self.victimState and z and D.held[z]==self then
            D.held[z]=nil
            D.followHook()
            z:setVariable("DCFGrabbed",false);z:setVariable("DCFGrabPhase","");z:setVariable("DCFGrabMarker","")
            z:setVariable("DCFGrabMoving",false);z:setVariable("DCFGrabWalkDirection","")
            z:setUseless(self.victimState.useless);z:setIgnoreMovement(self.victimState.ignore)
            z:setDeferredMovementEnabled(self.victimState.deferred)
            if z:getHitReaction()=="DCFGrabbed" then z:setHitReaction("");z:reportEvent("ActiveAnimFinishing") end
            if not z:isDead() and z:getTarget()==nil and self.victimState.target then z:setTarget(self.victimState.target) end
        end
    end
    if DCF.activeActions[p]==self.context then
        if completed then DCF.completeAction(p) else DCF.cancelAction(p,"defense_interrupted") end
    end
end
function A:stop()self:cleanup(false);ISBaseTimedAction.stop(self)end
function A:perform()self:cleanup(true);ISBaseTimedAction.perform(self)end
function A:cancel()if not self.cleaned then self:cleanup(false);if self.action then self:forceStop() end end end
function A:guard(dt)
    local p=self.character
    if self.phaseName=="exit" then
        if var(p,"DCFDefenseMarker")=="exit_done" then self:forceComplete() end
        return
    end
    if not DCF.Bindings.down("block") then self:phase("exit");return end
    spend(p,dt*.008)
    if endurance(p)<.08 then
        local input=D.input[p];if input then input.brokenUntil=now()+1200;input.mustRelease=true end
        DCF.emit("guardBroken",p);self:phase("exit");return
    end
    if self.phaseName=="enter" and var(p,"DCFDefenseMarker")=="enter_ready" then self:phase("hold") end
    if self.phaseName=="hit" and var(p,"DCFDefenseMarker")=="hit_ready" then self:phase("hold") end
    if (self.phaseName=="hold" or self.phaseName=="hit") and var(p,"DCFDefenseMarker")==self.phaseName.."_started" then self.guardStarted=true end
    if not self.guardStarted then return end
    for z,s in pairs(DCF.TigerDrop.tracked) do
        if s.player==p and DCF.TigerDrop.validTarget(p,z) then
            if endurance(p)<.10 then
                local input=D.input[p];if input then input.brokenUntil=now()+1200;input.mustRelease=true end
                DCF.emit("guardBroken",p);self:phase("exit");return
            end
            spend(p,.08)
            z:setAttackOutcome("fail");z:setVariable("DCFTigerWindow",false);z:setTarget(nil)
            z:setHitReaction("BiteDefended");z:reportEvent("wasHit")
            D.recovering[#D.recovering+1]={z=z,p=p,untilAt=now()+800}
            if not D.ticking then D.ticking=true;Events.OnTick.Add(D.restoreTargets) end
            if self.phaseName~="hit" then self:phase("hit") end
            DCF.emit("guardHit",p,z)
        end
    end
end
function A:throw()
    if self.phaseName~="hold" or not self.paired then return false end
    if endurance(self.character)<.08 then self:forceStop();return false end
    if not self:alignPair("throw") then self:forceStop();return false end
    spend(self.character,.06);self:phase("throw");DCF.emit("throwStarted",self.character,self.context.target);return true
end
function A:grab(dt)
    local p,z=self.character,self.context.target
    spend(p,dt*.012)
    if endurance(p)<.05 then self:forceStop();return end
    local age=now()-self.startedAt
    if self.phaseName=="enter" then
        -- Bring the pair together through the same swept collision checks as dashes.
        local x=p:getX()+self.context.fx*.7-z:getX()
        local y=p:getY()+self.context.fy*.7-z:getY()
        local distance=math.sqrt(x*x+y*y)
        if distance>.02 then
            local amount=math.min(distance,.06)
            local dx,dy=x/distance*amount,y/distance*amount
            if not DCF.Quicksteps or not DCF.Quicksteps.canMove(z,dx,dy) then self:forceStop();return end
            z:moveUnmodded(dx,dy)
        end
        local playerReady=var(p,"DCFDefenseMarker")=="enter_ready"
        local victimReady=var(z,"DCFGrabMarker")=="enter_ready"
        if playerReady and victimReady then self.paired=true;self:phase("hold");DCF.emit("grabHeld",p,z)
        elseif age>1000 then self:forceStop() end
    elseif self.phaseName=="hold" then
        if not self:alignPair(true) then self:forceStop();return end
        local dx,dy=p:getX()-self.lastX,p:getY()-self.lastY
        self.lastX,self.lastY=p:getX(),p:getY()
        if dx*dx+dy*dy>.000001 then self.lastMovedAt=now() end
        local moving=self.lastMovedAt~=nil and now()-self.lastMovedAt<120
        local fx,fy=-self.context.fx,-self.context.fy
        local forward,right=dx*fx+dy*fy,dx*(-fy)+dy*fx
        local direction=math.abs(forward)>=math.abs(right) and (forward>=0 and "forward" or "backward") or (right>=0 and "right" or "left")
        self:setGrabMoving(moving,direction)
        if age>3500 then self:forceStop() end
    elseif self.phaseName=="throw" then
        p:setTargetAndCurrentDirection(self.context.fx,self.context.fy)
        z:setTargetAndCurrentDirection(-self.context.fx,-self.context.fy)
        if not self.impacted and var(p,"DCFDefenseMarker")=="throw_impact" and var(z,"DCFGrabMarker")=="throw_impact" then
            self.impacted=true
            -- A single native weapon hit; armor and health remain native PZ calculations.
            z:setIgnoreMovement(self.victimState.ignore);z:setUseless(self.victimState.useless)
            if isClient() and DCF.Network then DCF.Network.send(p,"throw",{zombie=z:getOnlineID()})
            else
                z:Hit(p:getPrimaryHandItem(),p,.7,false,1)
                z:setKnockedDown(true);z:setFallOnFront(false)
                DCF.emit("throwHit",p,z)
            end
            self:forceComplete();return
        end
        if now()-self.phaseAt>3300 then self:forceStop() end
    end
end
function A:update()
    if self.cleaned then return end
    local t=now();local elapsed=math.max(0,t-self.lastAt)
    local dt=math.min(.1,elapsed/1000);self.lastAt=t
    if isGamePaused() then
        self.startedAt=self.startedAt+elapsed;self.phaseAt=self.phaseAt+elapsed;return
    end
    if not self:isValid() then self:forceStop();return end
    if self.context.kind=="block" then self:guard(dt) else self:grab(dt) end
    if not self.cleaned and ((self.phaseName=="enter" and t-self.phaseAt>1000)
        or (self.context.kind=="block" and self.phaseName~="hold" and t-self.phaseAt>1200)) then self:forceStop() end
end
function A:new(c)
    local o=ISBaseTimedAction.new(self,c.player)
    o.context=c;o.maxTime=-1;o.stopOnWalk=false;o.stopOnRun=false;o.stopOnAim=false;o.ignoreHandsWounds=true
    return o
end
local handler={
    canStart=function(c)
        if not D.ready(c.player) or endurance(c.player)<.12 then return false,"not_ready" end
        if c.kind=="grab" then
            if isClient() and (not DCF.Network or not DCF.Network.requestGrab(c.player,c.target)) then return false,"grab_server_pending" end
            local leased=isClient() and DCF.Network and DCF.Network.leases[c.player]==c.target:getOnlineID()
            if not leased and c.target~=D.target(c.player) then return false,"invalid_target" end
            local dx,dy=c.target:getX()-c.player:getX(),c.target:getY()-c.player:getY()
            local n=math.sqrt(dx*dx+dy*dy);if n<.25 then return false,"too_close" end
            c.fx,c.fy=dx/n,dy/n
        end
        return true
    end,
    start=function(c)
        DCF.resetPlayer(c.player,"defense_started")
        local a=A:new(c);c.timedAction=a;c.requestedAt=now()
        local ok,q=pcall(ISTimedActionQueue.add,a)
        if not ok or not q then a:cancel();return false,"queue_rejected" end
        return true
    end,
    cancel=function(c)if c.timedAction then c.timedAction:cancel() end end,
}
DCF.registerActionHandler("block",handler)
DCF.registerActionHandler("grab",handler)
function D.update(p,throwPressed)
    local input=D.input[p]
    if not input then input={};D.input[p]=input end
    local x,g=DCF.Bindings.down("block"),DCF.Bindings.down("grab")
    local grabPressed=g and not input.g
    input.g=g
    if not x then input.mustRelease=false end
    local c=DCF.activeActions[p]
    if c and (c.kind=="grab" or c.kind=="block") then
        local a=c.timedAction
        if not D.safe(p) or (not a.started and now()-c.requestedAt>600) then DCF.cancelAction(p,"invalid_defense")
        elseif c.kind=="grab" then
            if grabPressed then DCF.cancelAction(p,"released") elseif throwPressed then a:throw() end
            if not a.cleaned and a.started and a.phaseName=="hold" and not isGamePaused() then D.followZombie(c.target) end
        end
        return true
    end
    local style=DCF.getPlayerStyle(p)
    local block=style and style.actions.block
    local grab=style and style.actions.grab
    local canBlock=block and block.enabled==true
    local canGrab=grab and grab.enabled==true
    if (not canBlock and not canGrab) or not D.ready(p) then return false end
    if canBlock and x and not input.mustRelease and now()>=(input.brokenUntil or 0) then return DCF.requestAction(p,"block") end
    if canGrab and grabPressed then
        local z=D.target(p)
        if z then return DCF.requestAction(p,"grab",nil,z) end
    end
    return false
end
function D.clear()
    local actions={}
    for p,c in pairs(DCF.activeActions) do if c.kind=="grab" or c.kind=="block" then actions[#actions+1]=p end end
    for _,p in ipairs(actions) do DCF.cancelAction(p,"world_exit") end
    for _,r in ipairs(D.recovering) do if not r.z:isDead() and not r.p:isDead() and r.z:getTarget()==nil then r.z:setTarget(r.p) end end
    D.recovering={};D.restoreTargets();D.input=setmetatable({}, {__mode="k"})
end
Events.OnSave.Add(D.clear)
Events.OnMainMenuEnter.Add(D.clear)
function D.bindSafetyInput()
    -- G is also vanilla's safety toggle. Scope interception to this style while
    -- aiming; every other key and situation still reaches the original callback.
    if D.safetyWrapped or not ISEquippedItem or not ISEquippedItem.onKeyPressed then return end
    local original=ISEquippedItem.onKeyPressed
    D.safetyWrapped=true
    Events.OnKeyPressed.Remove(original)
    Events.OnKeyPressed.Add(function(key)
        local p=getPlayer()
        if DCF.Bindings.matches("grab",key) and p and DCF.isEquipped(p) and p:isAiming() and not p:getVehicle() then return end
        original(key)
    end)
end
Events.OnGameStart.Add(D.bindSafetyInput)
