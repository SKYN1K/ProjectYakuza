require "ProjectYakuza/Runtime"
require "ProjectYakuza/MultiHit"
require "ProjectYakuza/TigerDrop"
require "ProjectYakuza/GrabRules"
require "ProjectYakuza/AttackEffects"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
local ProjectYakuza=ProjectYakuza
local D={input=setmetatable({}, {__mode="k"}),held=setmetatable({}, {__mode="k"}),recovering={}}
ProjectYakuza.Defense=D
ProjectYakuza.Guard=D
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
    if not a or a.cleaned or not (a.phaseName=="hold"or a.strikeMove~=nil or a.phaseName=="throw") or isGamePaused() then return end
    if not a:isValid() or not a:alignPair(true) then a:cancel() end
end
function D.followHook()
    local active=false;for _ in pairs(D.held) do active=true;break end
    if active and not D.following then Events.OnZombieUpdate.Add(D.followZombie);Events.OnTick.Add(D.holdStance);D.following=true
    elseif not active and D.following then Events.OnZombieUpdate.Remove(D.followZombie);Events.OnTick.Remove(D.holdStance);D.following=false end
end
function D.holdStance()
    for _,action in pairs(D.held)do
        if not action.cleaned then
            if not action:isValid()then action:cancel()
            else action.character:setIsAiming(true)end
        end
    end
end
function D.safe(p,keepGrab)
    return ProjectYakuza.isEquipped(p) and (keepGrab or p:isAiming()) and not p:isDead() and not p:isOnFloor()
        and not p:isKnockedDown() and not p:isClimbing() and not p:getVehicle()
        and not p:isDraggingCorpse() and not p:isAsleep() and (p:getHitReaction() or "")==""
end
function D.ready(p)
    return D.safe(p) and not isGamePaused() and not ProjectYakuza.isBusy(p) and not p:hasTimedActions()
        and not p:isBlockMovement() and not p:getIgnoreMovement()
        and not p:isAttackStarted() and not p:isPerformingAttackAnimation()
end
function D.canTrack(p)
    local c=ProjectYakuza.activeActions[p]
    return D.safe(p) and ((c and c.kind=="block") or (D.ready(p) and ProjectYakuza.Bindings.down("block")))
end
function D.target(p)
    if not ProjectYakuza.MultiHit then return nil end
    local origin=ProjectYakuza.MultiHit.origin(p,1.05)
    if not origin then return nil end
    for _,entry in ipairs(ProjectYakuza.MultiHit.targets(p,origin,false,{},math.huge)) do
        local z=entry.victim
        if not D.held[z] and not ProjectYakuza.GrabRules.unavailable(z) and not z:isAttacking() and not z:isUseless() and (z:getHitReaction() or "")=="" then return z end
    end
end
function D.reachable(p,z)
    if not z or z:isDead()or z:isOnFloor()or z:isKnockedDown()or math.abs(z:getZ()-p:getZ())>=.5 then return false end
    local origin=ProjectYakuza.MultiHit.origin(p,1.3);if not origin then return false end
    local dx,dy=z:getX()-p:getX(),z:getY()-p:getY();local distance=math.sqrt(dx*dx+dy*dy)
    return distance>=.25 and distance<=origin.range and(dx*origin.fx+dy*origin.fy)/distance>=.5
        and p:CanSee(z)and ProjectYakuza.MultiHit.clearPath(p,origin,dx,dy)
end
function D.restoreTargets()
    for i=#D.recovering,1,-1 do
        local r=D.recovering[i]
        if r.z:isDead() or now()>=r.untilAt or not r.z:isAttacking() then
            if not r.z:isDead() and not r.p:isDead() and ProjectYakuza.isEquipped(r.p) and r.z:getTarget()==nil
                and (r.z:getX()-r.p:getX())^2+(r.z:getY()-r.p:getY())^2<9 then r.z:setTarget(r.p) end
            table.remove(D.recovering,i)
        end
    end
    if #D.recovering==0 and D.ticking then Events.OnTick.Remove(D.restoreTargets);D.ticking=false end
end
local A=ISBaseTimedAction:derive("ProjectYakuzaDefenseAction")
D.Action=A
function A:adjustMaxTime(v)return v end
function A:isUsingTimeout()return false end
function A:phase(name)
    self.phaseName=name;self.phaseAt=now()
    self.character:setVariable("ProjectYakuzaDefensePhase",name)
    self.character:setVariable("ProjectYakuzaDefenseMarker","")
    if self.context.kind=="grab" then
        local z=self.context.target
        if z then z:setVariable("ProjectYakuzaGrabPhase",name);z:setVariable("ProjectYakuzaGrabMarker","")end
        self:setGrabMoving(false)
        local walking=name=="hold"
        self.character:setBlockMovement(not walking)
        self.character:setIgnoreMovement(not walking)
        self.character:setDeferredMovementEnabled(walking and self.oldDeferred~=false)
        if not walking then self.character:getMovementLastFrame():set(0,0);self.character:setMoving(false);self.character:setRunning(false);self.character:setSprinting(false)end
        self.lastX=self.character:getX();self.lastY=self.character:getY()
    end
end
function A:setGrabMoving(moving,direction)
    if self.grabMoving~=moving then
        self.character:setVariable("ProjectYakuzaGrabMoving",moving)
        if self.context.target then self.context.target:setVariable("ProjectYakuzaGrabMoving",moving)end
        self.grabMoving=moving
    end
    if direction and self.walkDirection~=direction then
        self.context.target:setVariable("ProjectYakuzaGrabWalkDirection",direction);self.walkDirection=direction
    end
end
function A:alignPair(snap)
    local p,z=self.character,self.context.target
    D.followVector=D.followVector or Vector2.new()
    local f=snap=="throw" and p:getForwardDirection() or p:getAnimForwardDirection(D.followVector)
    local fx,fy=f:getX(),f:getY()
    if self.phaseName~="hold"and self.phaseName~="enter"then fx,fy=self.context.fx,self.context.fy end
    local n=math.sqrt(fx*fx+fy*fy)
    if n<.001 then return false end
    fx,fy=fx/n,fy/n
    local offset=ProjectYakuza.GrabRules.alignment(self.context.action,self.phaseName,self,now())
    local x,y=p:getX()+fx*offset.forward+fy*offset.right,p:getY()+fy*offset.forward-fx*offset.right
    local dx,dy=x-z:getX(),y-z:getY()
    local origin={x=z:getX(),y=z:getY(),z=z:getZ()}
    if not ProjectYakuza.MultiHit.clearPath(z,origin,dx,dy) then return false end

    D.snapActor(z,x,y)
    self.context.fx,self.context.fy=fx,fy
    if self.phaseName~="hold"and self.phaseName~="enter"then p:setTargetAndCurrentDirection(fx,fy)end
    z:setTargetAndCurrentDirection(-fx,-fy)
    return true
end
function A:start()
    self.started=true;self.startedAt=now();self.lastAt=self.startedAt
    local p=self.character;self.held=p:getPrimaryHandItem()
    self.oldBlock=p:isBlockMovement();self.oldIgnore=p:getIgnoreMovement();self.oldDeferred=p:isDeferredMovementEnabled()
    p:setBlockMovement(self.context.kind~="block");p:setIgnoreMovement(self.context.kind~="block")
    self:setActionAnim(self.context.action.animation)
    self.action:setOverrideHandModelsObject(p:getPrimaryHandItem(),nil,false)
    if self.context.kind=="grab"and not self.context.attempt then self:attach(self.context.target)end
    self:phase(self.context.attempt and "attempt"or "enter")
end
function A:attach(z)
    local p=self.character
    self.context.target=z;self.boundAt=now();self.awaitingGrab=false
    self.entryAt=self.boundAt;self.entryX=z:getX();self.entryY=z:getY()
    p:setIsAiming(true);self.ownsAim=true
    self.victimState=ProjectYakuza.GrabRules.capture(z)
    local saved=isClient()and ProjectYakuza.Network and ProjectYakuza.Network.grabStates and ProjectYakuza.Network.grabStates[p]
    if saved then self.grabId=saved.grabId;self.victimState.useless=saved.useless;self.victimState.ignore=saved.ignore;self.victimState.deferred=saved.deferred;self.victimState.locked=saved.locked end
    D.held[z]=self
    D.followHook()
    z:setAttackOutcome("fail");z:setTarget(nil);z:setUseless(true);z:setIgnoreMovement(true)
    z:setDeferredMovementEnabled(false)
    if ProjectYakuza.Reactions then ProjectYakuza.Reactions.clear(z) end
    z:setVariable("ProjectYakuzaGrabbed",true)
    z:setHitReaction("ProjectYakuzaGrabbed")
    z:setForwardDirection(-self.context.fx,-self.context.fy)
    z:reportEvent("wasHit")
    z:setVariable("ProjectYakuzaGrabPhase","enter");z:setVariable("ProjectYakuzaGrabMarker","")
end
function A:acceptGrab(z)
    if self.cleaned or not self.started or not self.context.attempt or not self.awaitingGrab or self.candidate~=z or not self:isValid()or not D.reachable(self.character,z)then return false end
    self:attach(z);self:phase("enter");return true
end
function A:isValid()
    if not ProjectYakuza.Sandbox.actionAllowed(self.context.style,self.context.kind)then return false end
    if not D.safe(self.character,self.context.kind=="grab"and self.context.action.releaseOnAimLoss==false) then return false end
    if self.context.kind=="grab" then
        local z=self.context.target;local style=ProjectYakuza.getPlayerStyle(self.character)
        if not style or style.id~=self.context.style.id or self.started and self.character:getPrimaryHandItem()~=self.held then return false end
        if self.context.attempt and not self.victimState then return true end
        return z and not z:isDead() and not z:isKnockedDown() and not z:isOnFloor()
            and math.abs(z:getZ()-self.character:getZ())<.5
            and (z:getX()-self.character:getX())^2+(z:getY()-self.character:getY())^2<2.25
            and (z:getHitReaction()=="ProjectYakuzaGrabbed" or (z:getHitReaction() or "")=="")
    end
    return true
end
function A:cleanup(completed)
    if self.cleaned then return end
    self.cleaned=true
    local p=self.character
    if self.context.kind=="grab" and isClient() and ProjectYakuza.Network then ProjectYakuza.Network.releaseGrab(p) end
    if self.started then
        if self.ownsAim then p:setIsAiming(p:isAimControlActive());self.ownsAim=nil end
        p:setBlockMovement(self.oldBlock==true);p:setIgnoreMovement(self.oldIgnore==true);p:setDeferredMovementEnabled(self.oldDeferred~=false)
        p:setVariable("ProjectYakuzaDefensePhase","");p:setVariable("ProjectYakuzaDefenseMarker","")
        p:setVariable("ProjectYakuzaGrabMoving",false)
        local z=self.context.target
        if self.victimState and z and D.held[z]==self then
            D.held[z]=nil
            D.followHook()
            z:setVariable("ProjectYakuzaGrabbed",false);z:setVariable("ProjectYakuzaGrabPhase","");z:setVariable("ProjectYakuzaGrabMarker","")
            z:setVariable("ProjectYakuzaGrabMoving",false);z:setVariable("ProjectYakuzaGrabWalkDirection","")
            ProjectYakuza.GrabRules.restore(z,self.victimState)
            if self.impacted and self.phaseName=="throw"then ProjectYakuza.GrabRules.land(z)
            elseif z:getHitReaction()=="ProjectYakuzaGrabbed" then z:setHitReaction("");z:reportEvent("ActiveAnimFinishing") end
            if not z:isDead() and z:getTarget()==nil and self.victimState.target then z:setTarget(self.victimState.target) end
        end
    end
    if ProjectYakuza.activeActions[p]==self.context then
        if completed then ProjectYakuza.completeAction(p) else ProjectYakuza.cancelAction(p,"defense_interrupted") end
    end
end
function A:stop()self:cleanup(false);ISBaseTimedAction.stop(self)end
function A:perform()self:cleanup(true);ISBaseTimedAction.perform(self)end
function A:cancel()if not self.cleaned then self:cleanup(false);if self.action then self:forceStop() end end end
function A:guard(dt)
    local p=self.character
    if self.phaseName=="exit" then
        if var(p,"ProjectYakuzaDefenseMarker")=="exit_done" then self:forceComplete() end
        return
    end
    if not ProjectYakuza.Bindings.down("block") then self:phase("exit");return end
    spend(p,dt*.008)
    if endurance(p)<.08 then
        local input=D.input[p];if input then input.brokenUntil=now()+1200;input.mustRelease=true end
        ProjectYakuza.emit("guardBroken",p);self:phase("exit");return
    end
    if self.phaseName=="enter" and var(p,"ProjectYakuzaDefenseMarker")=="enter_ready" then self:phase("hold") end
    if self.phaseName=="hit" and var(p,"ProjectYakuzaDefenseMarker")=="hit_ready" then self:phase("hold") end
    if (self.phaseName=="hold" or self.phaseName=="hit") and var(p,"ProjectYakuzaDefenseMarker")==self.phaseName.."_started" then self.guardStarted=true end
    if not self.guardStarted then return end
    for z,s in pairs(ProjectYakuza.TigerDrop.tracked) do
        if s.player==p and ProjectYakuza.TigerDrop.validGuardTarget(p,z) then
            if endurance(p)<.10 then
                local input=D.input[p];if input then input.brokenUntil=now()+1200;input.mustRelease=true end
                ProjectYakuza.emit("guardBroken",p);self:phase("exit");return
            end
            spend(p,.08)
            z:setAttackOutcome("fail");z:setVariable("ProjectYakuzaTigerWindow",false);z:setTarget(nil)
            z:setHitReaction("BiteDefended");z:reportEvent("wasHit")
            D.recovering[#D.recovering+1]={z=z,p=p,untilAt=now()+800}
            if not D.ticking then D.ticking=true;Events.OnTick.Add(D.restoreTargets) end
            if self.phaseName~="hit" then self:phase("hit") end
            ProjectYakuza.emit("guardHit",p,z)
        end
    end
end
function A:escape()
    if self.cleaned or not self.started or self.phaseName=="escape"or not self.context.action.breakout then return false end
    self.strikeMove=nil;self.escapeSeen=false;self.escapeSlot=nil;self:phase("escape")
    ProjectYakuza.emit("grabBroken",self.character,self.context.target)
    return true
end
function A:throw()
    if self.phaseName~="hold" or not self.paired then return false end
    if endurance(self.character)<.08 then self:forceStop();return false end
    if not self:alignPair("throw") then self:forceStop();return false end
    spend(self.character,.06);self:phase("throw");ProjectYakuza.emit("throwStarted",self.character,self.context.target);return true
end
function A:grab(dt)
    local p,z=self.character,self.context.target
    spend(p,dt*.012)
    if endurance(p)<.05 then self:forceStop();return end
    if self.context.attempt and not self.victimState then
        local slot=self.context.action
        local time,weight=ProjectYakuza.AttackEffects.findTrack(p,slot.attemptAnimation)
        if time and weight>=.35 then
            self.attemptSeen=true
            if not self.reachResolved and time*1000>=slot.attemptContactMs then
                self.reachResolved=true
                if time*1000<=(slot.attemptContactEndMs or slot.attemptDurationMs)then self.candidate=D.target(p)end
                ProjectYakuza.emit("grabReach",p,self.candidate)
                if self.candidate then
                    local dx,dy=self.candidate:getX()-p:getX(),self.candidate:getY()-p:getY();local length=math.sqrt(dx*dx+dy*dy)
                    if length>=.25 then
                        self.context.fx,self.context.fy=dx/length,dy/length
                        if isClient()then
                            self.awaitingGrab=true;self.gripRequestedAt=now()
                            if not ProjectYakuza.Network then self.awaitingGrab=false
                            elseif ProjectYakuza.Network.requestGrab(p,self.candidate)then self:acceptGrab(self.candidate)end
                        else self:attach(self.candidate);self:phase("enter")end
                    end
                end
            end
        end
        if self.victimState then return end
        if self.awaitingGrab then
            local network=ProjectYakuza.Network
            if now()-self.gripRequestedAt>1500 or not(network and network.pending and network.pending[p])then self.awaitingGrab=false else return end
        end
        if self.attemptSeen and(var(p,"ProjectYakuzaDefenseMarker")=="attempt_done"or time and time*1000>=slot.attemptDurationMs-20 or not time and now()-self.startedAt>=slot.attemptDurationMs)then self:forceComplete()
        elseif now()-self.startedAt>slot.attemptDurationMs+500 then self:forceStop()end
        return
    end
    ProjectYakuza.GrabRules.keep(z)
    local age=now()-(self.boundAt or self.startedAt)
    if self.phaseName=="enter" then

        local x,y,progress=ProjectYakuza.GrabRules.entryPosition(p,z,self.context.action,self,now(),self.context.fx,self.context.fy)
        if not ProjectYakuza.MultiHit.clearPath(z,{x=z:getX(),y=z:getY(),z=z:getZ()},x-z:getX(),y-z:getY())then self:forceStop();return end
        D.snapActor(z,x,y)
        local playerReady=var(p,"ProjectYakuzaDefenseMarker")=="enter_ready"
        local victimReady=var(z,"ProjectYakuzaGrabMarker")=="enter_ready"
        if playerReady and victimReady and progress>=1 then self.paired=true;self:phase("hold");ProjectYakuza.emit("grabHeld",p,z)
        elseif age>1000 then self:forceStop() end
    elseif self.phaseName=="hold" then
        if not isClient()and ProjectYakuza.GrabRules.escapeDue(self,self.context.action,now())then self:escape();return end
        if not self:alignPair(true) then self:forceStop();return end
        local dx,dy=p:getX()-self.lastX,p:getY()-self.lastY
        self.lastX,self.lastY=p:getX(),p:getY()
        if dx*dx+dy*dy>.000001 then self.lastMovedAt=now() end
        local moving=self.lastMovedAt~=nil and now()-self.lastMovedAt<120
        local fx,fy=-self.context.fx,-self.context.fy
        local forward,right=dx*fx+dy*fy,dx*(-fy)+dy*fx
        local direction=math.abs(forward)>=math.abs(right) and (forward>=0 and "forward" or "backward") or (right>=0 and "right" or "left")
        self:setGrabMoving(moving,direction)

    elseif self.phaseName=="escape"then
        if not self:alignPair(true)then self:forceStop();return end
        local move=self.context.action.breakout
        local time,weight,slot=ProjectYakuza.AttackEffects.findTrack(p,move.animation,self.escapeSlot);self.escapeSlot=slot
        if time and weight>=.35 then self.escapeSeen=true;if time>=move.duration-.03 then self:forceComplete();return end end
        if self.escapeSeen and var(p,"ProjectYakuzaDefenseMarker")=="escape_done"and var(z,"ProjectYakuzaGrabMarker")=="escape_done"then self:forceComplete();return end
        if now()-self.phaseAt>(move.duration+1)*1000 then self:forceStop()end
    elseif self.strikeMove then
        if not self:alignPair(true)then self:forceStop();return end
        local phase,weight=ProjectYakuza.AttackEffects.findTrack(p,self.strikeMove.animation)
        if phase and weight>=.35 then
            self.strikeSeen=true
            if not self.strikeImpacted and phase*1000>=self.strikeMove.contactMs then self.strikeImpacted=true;if ProjectYakuza.GrabCombat then ProjectYakuza.GrabCombat.hit(self)end end
            if phase>=self.strikeMove.duration-.03 then self.strikeMove=nil;self:phase("hold")end
        elseif self.strikeSeen and var(p,"ProjectYakuzaDefenseMarker")=="strike_done"then self.strikeMove=nil;self:phase("hold")end
        if self.strikeMove and now()-self.phaseAt>(self.strikeMove.duration+1)*1000 then self:forceStop()end
    elseif self.phaseName=="throw" then
        if not self:alignPair(true)then self:forceStop();return end
        p:setTargetAndCurrentDirection(self.context.fx,self.context.fy)
        z:setTargetAndCurrentDirection(-self.context.fx,-self.context.fy)
        if not self.impacted and var(p,"ProjectYakuzaDefenseMarker")=="throw_impact" and var(z,"ProjectYakuzaGrabMarker")=="throw_impact" then
            self.impacted=true

            ProjectYakuza.GrabRules.releaseLock(z,self.victimState);z:setIgnoreMovement(self.victimState.ignore);z:setUseless(self.victimState.useless)
            if isClient() and ProjectYakuza.Network then ProjectYakuza.Network.send(p,"throw",{zombie=z:getOnlineID(),grabId=self.grabId})
            else
                z:Hit(p:getPrimaryHandItem(),p,.7,false,1)
                ProjectYakuza.GrabRules.land(z)
                for _,victim in ipairs(ProjectYakuza.GrabRules.crowd(p,z,self.context.action,self.context.fx,self.context.fy))do ProjectYakuza.GrabRules.collide(p,victim,self.context.action.throwCrowd)end
                ProjectYakuza.emit("throwHit",p,z)
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
        self.startedAt=self.startedAt+elapsed;self.phaseAt=self.phaseAt+elapsed
        for _,key in ipairs({"boundAt","entryAt","gripRequestedAt","escapeNext"})do if self[key]then self[key]=self[key]+elapsed end end
        return
    end
    if not self:isValid() then self:forceStop();return end
    if self.context.kind=="block" then self:guard(dt) else self:grab(dt) end
    if not self.cleaned and ((self.phaseName=="enter" and not self.awaitingGrab and t-(self.boundAt or self.phaseAt)>1000)
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
            if c.action.attemptContactMs then
                local f=c.player:getForwardDirection();c.fx,c.fy=f:getX(),f:getY();c.attempt=true;c.target=nil;return true
            end
            if isClient() and (not ProjectYakuza.Network or not ProjectYakuza.Network.requestGrab(c.player,c.target)) then return false,"grab_server_pending" end
            local leased=isClient() and ProjectYakuza.Network and ProjectYakuza.Network.leases[c.player]==c.target:getOnlineID()
            if not leased and c.target~=D.target(c.player) then return false,"invalid_target" end
            local dx,dy=c.target:getX()-c.player:getX(),c.target:getY()-c.player:getY()
            local n=math.sqrt(dx*dx+dy*dy);if n<.25 then return false,"too_close" end
            c.fx,c.fy=dx/n,dy/n
        end
        return true
    end,
    start=function(c)
        ProjectYakuza.resetPlayer(c.player,"defense_started")
        local a=A:new(c);c.timedAction=a;c.requestedAt=now()
        local ok,q=pcall(ISTimedActionQueue.add,a)
        if not ok or not q then a:cancel();return false,"queue_rejected" end
        return true
    end,
    cancel=function(c)if c.timedAction then c.timedAction:cancel() end end,
}
ProjectYakuza.registerActionHandler("block",handler)
ProjectYakuza.registerActionHandler("grab",handler)
function D.update(p)
    local input=D.input[p]
    if not input then input={};D.input[p]=input end
    local x,g=ProjectYakuza.Bindings.down("block"),ProjectYakuza.Bindings.down("grab")
    local grabPressed=g and not input.g
    local light=ProjectYakuza.Bindings.down("light");local lightPressed=light and not input.light
    local heat=ProjectYakuza.Bindings.down("heatAction");local heatPressed=heat and not input.heat
    input.g=g;input.light=light;input.heat=heat
    if not x then input.mustRelease=false end
    local c=ProjectYakuza.activeActions[p]
    if c and (c.kind=="grab" or c.kind=="block") then
        local a=c.timedAction
        if not D.safe(p,c.kind=="grab"and c.action.releaseOnAimLoss==false) or (not a.started and now()-c.requestedAt>600) then ProjectYakuza.cancelAction(p,"invalid_defense")
        elseif c.kind=="grab" then
            if grabPressed then a:throw()
            elseif ProjectYakuza.GrabCombat then ProjectYakuza.GrabCombat.input(p,a,lightPressed,heatPressed)end
            if not a.cleaned and a.started and a.phaseName=="hold" and not isGamePaused() then D.followZombie(c.target) end
        end
        return true
    end
    local style=ProjectYakuza.getPlayerStyle(p)
    local block=style and style.actions.block
    local grab=style and style.actions.grab
    local canBlock=block and block.enabled==true
    local canGrab=grab and grab.enabled==true and ProjectYakuza.Sandbox.enabled("Grabs")
    if (not canBlock and not canGrab) or not D.ready(p) then return false end
    if canBlock and x and not input.mustRelease and now()>=(input.brokenUntil or 0) then return ProjectYakuza.requestAction(p,"block") end
    if canGrab and grabPressed then
        if grab.attemptContactMs then return ProjectYakuza.requestAction(p,"grab")end
        local z=D.target(p)
        if z then return ProjectYakuza.requestAction(p,"grab",nil,z) end
    end
    return false
end
function D.clear()
    local actions={}
    for p,c in pairs(ProjectYakuza.activeActions) do if c.kind=="grab" or c.kind=="block" then actions[#actions+1]=p end end
    for _,p in ipairs(actions) do ProjectYakuza.cancelAction(p,"world_exit") end
    for _,r in ipairs(D.recovering) do if not r.z:isDead() and not r.p:isDead() and r.z:getTarget()==nil then r.z:setTarget(r.p) end end
    D.recovering={};D.restoreTargets();D.input=setmetatable({}, {__mode="k"})
end
Events.OnSave.Add(D.clear)
Events.OnMainMenuEnter.Add(D.clear)
function D.bindSafetyInput()

    if D.safetyWrapped or not ISEquippedItem or not ISEquippedItem.onKeyPressed then return end
    local original=ISEquippedItem.onKeyPressed
    D.safetyWrapped=true
    Events.OnKeyPressed.Remove(original)
    Events.OnKeyPressed.Add(function(key)
        local p=getPlayer();local c=p and ProjectYakuza.activeActions[p]
        if ProjectYakuza.Sandbox.enabled("Grabs")and ProjectYakuza.Bindings.matches("grab",key) and p and ProjectYakuza.isEquipped(p) and (p:isAiming()or c and c.kind=="grab") and not p:getVehicle() then return end
        original(key)
    end)
end
Events.OnGameStart.Add(D.bindSafetyInput)
