require "DCF/Registry"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
local DCF=DragonCombat
local P={tracked=setmetatable({}, {__mode="k"}),players=setmetatable({}, {__mode="k"}),flights={}}
DCF.TigerDrop=P
P.windowMs=200
P.cooldownMs=60000
local function now()return getTimestampMs()end
local function var(z,n)return z:GetVariable(n) or "" end
local function bool(z,n)return var(z,n)=="true" end
function P.remaining(p)return math.max(0,(tonumber(p:getModData().DCFTigerDropReadyAt) or 0)-now())end
function P.ready(p)
    local style=DCF.getPlayerStyle(p)
    if not style or style.tigerDrop~=true then return false end
    return p:isLocalPlayer() and DCF.isEquipped(p) and p:isAiming() and not p:isDead() and not DCF.isBusy(p)
        and not p:isOnFloor() and not p:isKnockedDown() and not p:isClimbing() and not p:getVehicle()
        and not p:hasTimedActions() and not p:isBlockMovement() and not p:getIgnoreMovement()
        and (p:getHitReaction() or "")=="" and not isGamePaused() and P.remaining(p)==0
end
function P.inRange(p,z)
    if not z or not instanceof(z,"IsoZombie") or z:isDead() or z:isOnFloor() or z:isKnockedDown()
        or math.abs(z:getZ()-p:getZ())>.5 or z:getTarget()~=p then return false end
    local dx,dy=z:getX()-p:getX(),z:getY()-p:getY()
    local d=dx*dx+dy*dy
    if d<.0001 or d>1.5*1.5 then return false end
    local f=p:getForwardDirection();local fx,fy=f:getX(),f:getY()
    local length=math.sqrt(fx*fx+fy*fy)
    return length>.001 and (dx*fx+dy*fy)/(math.sqrt(d)*length)>=.35
end
function P.validTarget(p,z)
    local s=P.tracked[z]
    local outcome=z and z:getAttackOutcome()
    return s and s.player==p and (outcome=="start" or outcome=="success") and P.inRange(p,z) and z:isAttacking()
        and not z:getAttackDidDamage() and bool(z,"DCFTigerWindow")
        and not bool(z,"ZombieBiteDone")
end
function P.track(p)
    local t=now();local ps=P.players[p]
    if not ps then ps={};P.players[p]=ps end
    if t<(ps.nextScan or 0) then return end
    ps.nextScan=t+50
    -- Only 25 nearby squares, only while the local style user can counter.
    -- Enable the native bite marker nodes before attack entry, never midway through a bite.
    local canCounter=P.ready(p) or (DCF.Guard and DCF.Guard.canTrack(p))
    if canCounter then
        local cell=getCell();local x,y,z=math.floor(p:getX()),math.floor(p:getY()),math.floor(p:getZ())
        for ox=-2,2 do for oy=-2,2 do
            local sq=cell:getGridSquare(x+ox,y+oy,z)
            local objects=sq and sq:getMovingObjects()
            if objects then for i=0,objects:size()-1 do
                local victim=objects:get(i)
                if instanceof(victim,"IsoZombie") and not victim:isDead() and not victim:isOnFloor()
                    and not victim:isAttacking() and not P.tracked[victim] then
                    local dx,dy=victim:getX()-p:getX(),victim:getY()-p:getY()
                    if dx*dx+dy*dy<=4.41 then
                        P.tracked[victim]={player=p}
                        victim:setVariable("DCFTigerTracked",true)
                    end
                end
            end end
        end end
    end
    for victim,s in pairs(P.tracked) do if s.player==p then
        local dx,dy=victim:getX()-p:getX(),victim:getY()-p:getY()
        if victim:isDead() or ((not canCounter or dx*dx+dy*dy>9) and not victim:isAttacking()) then
            victim:setVariable("DCFTigerTracked",false);victim:setVariable("DCFTigerWindow",false)
            P.tracked[victim]=nil
        end
    end end
end
function P.tryCounter(p)
    if not P.ready(p) then return false end
    local target,best
    for z,s in pairs(P.tracked) do if P.validTarget(p,z) then
        local d=(z:getX()-p:getX())^2+(z:getY()-p:getY())^2
        if not best or d<best then target,best=z,d end
    end end
    if not target then return false end
    return DCF.requestAction(p,"parry",nil,target)
end
local function unhook()
    if #P.flights==0 and P.flightHook then Events.OnTick.Remove(P.tick);P.flightHook=false end
end
function P.tick()
    if isGamePaused() then
        local t=now();for _,s in ipairs(P.flights) do s.last=t end
        return
    end
    local t=now()
    for i=#P.flights,1,-1 do
        local s=P.flights[i];local z=s.zombie
        local dt=math.max(0,math.min(50,t-s.last));s.last=t
        local amount=math.min(.16,2.5-s.moved,dt*.01)
        local canMove=DCF.Quicksteps and DCF.Quicksteps.canMove
        if t>=s.untilAt or not z:getCurrentSquare() or z:isRagdollSimulationActive()
            or not canMove or not canMove(z,s.dx*amount,s.dy*amount) then
            table.remove(P.flights,i)
        elseif amount>0 then
            -- Native collision movement only; stop once ragdoll physics takes ownership.
            z:moveUnmodded(s.dx*amount,s.dy*amount);s.moved=s.moved+amount
        end
    end
    unhook()
end
function P.kill(p,z)
    if isClient() and DCF.Network then DCF.Network.send(p,"counter",{zombie=z:getOnlineID()});return end
    local dx,dy=z:getX()-p:getX(),z:getY()-p:getY()
    local n=math.sqrt(dx*dx+dy*dy);dx,dy=dx/n,dy/n
    z:setAttackOutcome("fail");z:setVariable("DCFTigerWindow",false)
    z:setTarget(nil)
    if DCF.Reactions then DCF.Reactions.clear(z) end
    z:setAttackedBy(p);z:setHitFromBehind(false);z:setFallOnFront(false)
    z:getHitDir():set(dx,dy);z:setHitForce(12)
    z:setUsePhysicHitReaction(true);z:setHitReaction("ShotBelly")
    z:Kill(p)
    z:reportEvent("wasHit")
    P.tracked[z]=nil
    local t=now()
    table.insert(P.flights,{zombie=z,dx=dx,dy=dy,last=t,untilAt=t+300,moved=0})
    if not P.flightHook then Events.OnTick.Add(P.tick);P.flightHook=true end
    DCF.emit("combatHit",p,z,p:getPrimaryHandItem(),0,0)
    DCF.emit("tigerDrop",p,z)
end
local A=ISBaseTimedAction:derive("DCFTigerDropAction")
P.Action=A
function A:isValid()
    local p=self.character
    return DCF.isEquipped(p) and not p:isDead() and not p:isOnFloor() and not p:isKnockedDown()
        and not p:isClimbing() and not p:getVehicle() and (p:getHitReaction() or "")==""
end
function A:adjustMaxTime(value)return value end
function A:isUsingTimeout()return false end
function A:start()
    local p=self.character
    self.started=true;self.startedAt=now()
    self.oldBlock=p:isBlockMovement();self.oldIgnore=p:getIgnoreMovement()
    p:setBlockMovement(true);p:setIgnoreMovement(true)
    p:setVariable("DCFTigerStarted","");p:setVariable("DCFTigerDone","")
    self:setActionAnim(self.context.action.animation)
    self.action:setOverrideHandModelsObject(p:getPrimaryHandItem(),nil,false)
end
function A:cleanup(completed)
    if self.cleaned then return end
    self.cleaned=true;local p=self.character
    if self.started then
        p:setBlockMovement(self.oldBlock==true);p:setIgnoreMovement(self.oldIgnore==true)
        p:setVariable("DCFTigerStarted","");p:setVariable("DCFTigerDone","")
    end
    if DCF.activeActions[p]==self.context then
        if completed then DCF.completeAction(p) else DCF.cancelAction(p,"tiger_drop_interrupted") end
    end
end
function A:update()
    if self.cleaned then return end
    if not self:isValid() then self:forceStop();return end
    local elapsed=now()-self.startedAt
    if var(self.character,"DCFTigerDone")=="true" then self:forceComplete()
    elseif elapsed>1600 or (elapsed>500 and var(self.character,"DCFTigerStarted")~="true") then self:forceStop() end
end
function A:perform()self:cleanup(true);ISBaseTimedAction.perform(self)end
function A:stop()self:cleanup(false);ISBaseTimedAction.stop(self)end
function A:forceCancel()if not self.cleaned then self:forceStop() end end
function A:new(context)
    local o=ISBaseTimedAction.new(self,context.player)
    o.context=context;o.maxTime=-1;o.stopOnWalk=false;o.stopOnRun=false;o.stopOnAim=false
    o.ignoreHandsWounds=true
    return o
end
DCF.registerActionHandler("parry",{
    canStart=function(c)
        if not P.ready(c.player) then return false,"not_ready" end
        if not P.validTarget(c.player,c.target) then return false,"counter_window_closed" end
        return true
    end,
    start=function(c)
        local action=A:new(c);c.timedAction=action
        local ok,queue=pcall(ISTimedActionQueue.add,action)
        if not ok or not queue then action:cleanup(false);return false,"queue_rejected" end
        DCF.resetPlayer(c.player,"tiger_drop_started")
        local extra={}
        if DCF.MultiHit then
            local origin=DCF.MultiHit.origin(c.player,1.5)
            if origin then extra=DCF.MultiHit.targets(c.player,origin,false,{[c.target]=true},DCF.MAX_HIT_COUNT-1) end
        end
        P.kill(c.player,c.target)
        for _,entry in ipairs(extra) do if not entry.victim:isDead() then P.kill(c.player,entry.victim) end end
        c.player:getModData().DCFTigerDropReadyAt=now()+P.cooldownMs
        return true
    end,
    cancel=function(c)if c.timedAction then c.timedAction:forceCancel()end end,
})
