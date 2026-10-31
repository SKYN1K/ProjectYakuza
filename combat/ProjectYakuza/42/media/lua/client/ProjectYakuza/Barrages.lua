require "ProjectYakuza/Runtime"
require "ProjectYakuza/BarrageRules"
require "ProjectYakuza/AttackEffects"
require "ProjectYakuza/MultiHit"
require "ProjectYakuza/Defense"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
local PY=ProjectYakuza;local R=PY.BarrageRules
local F={pending=setmetatable({}, {__mode="k"}),active=setmetatable({}, {__mode="k"})}
PY.Barrages=F
local function now()return getTimestampMs()end
local function eligible(p,style)
    return style and not style.weaponProfile and style.barrageInput and PY.Heat.isExtreme(p) and PY.isEquipped(p) and p:isAiming() and not p:isDead()
end
function F.input(p,s,style,heavyPressed)
    if not eligible(p,style) then F.pending[p]=nil;return false end
    if s.directionalLight then F.pending[p]=nil;return true end
    local cfg=style.barrageInput;local light=PY.Bindings.down("light") and not s.lastDown
    local turning=light and s.step==cfg.afterLights and PY.DirectionalAttacks and PY.DirectionalAttacks.select(p,s,style)
    if heavyPressed or (light and not turning and s.step==cfg.afterLights and (s.active or s.finishedAt and now()-s.finishedAt<=style.comboResetMs)) then
        F.pending[p]={variant=heavyPressed and cfg.heavyVariant or cfg.lightVariant,expires=now()+(cfg.bufferMs or 250)};s.queued=0
        if PY.Bindings then PY.Bindings.update(p)end
    end
    local job=F.pending[p];if not job then return false end
    if now()>job.expires then F.pending[p]=nil;return true end
    if s.active or s.starting or p:isAttackStarted() or p:isPerformingAttackAnimation() then return true end
    F.pending[p]=nil
    local ok,reason=PY.requestAction(p,"barrage",job.variant)
    if not ok and reason=="not_ready" then F.pending[p]=job end
    return true,ok
end
local A=ISBaseTimedAction:derive("ProjectYakuzaBarrageAction")
F.Action=A
function A:isUsingTimeout()return false end
function A:adjustMaxTime(v)return v end
function A:isValid()
    local p=self.character;local style=PY.getPlayerStyle(p)
    return PY.isEquipped(p) and style and style.id==self.context.style.id and not style.weaponProfile and p:getPrimaryHandItem()==self.held
        and not p:isDead() and not p:isOnFloor() and not p:isKnockedDown() and not p:isClimbing() and not p:getVehicle() and (p:getHitReaction()or"")==""
end
function A:hold()
    local p=self.character;PY.Defense.snapActor(p,self.x,self.y);p:getMovementLastFrame():set(0,0);p:setMoving(false);p:setRunning(false);p:setSprinting(false)
end
function A:start()
    local p=self.character;self.started=true;self.at=now();self.last=now();self.index=1;self.targets={}
    self.oldBlock=p:isBlockMovement();self.oldIgnore=p:getIgnoreMovement();self.oldDeferred=p:isDeferredMovementEnabled();self.x,self.y=p:getX(),p:getY()
    p:setBlockMovement(true);p:setIgnoreMovement(true);p:setDeferredMovementEnabled(false);self:hold()
    PY.setVisual(p,true,self.context.action.nodeValue);p:setVariable("ProjectYakuzaStyle",self.context.style.id);p:setVariable("ProjectYakuzaWeaponProfile","");p:setVariable("ProjectYakuzaBarrage","")
    self:setActionAnim(self.context.action.animation);self.action:setOverrideHandModelsObject(self.held,nil,false)
    PY.Heat.onSwing(p,self.context.action);F.active[p]=self
    PY.emit("barrageStarted",p,self.context.style,self.context.action)
    if PY.Network and isClient()then PY.Network.capture(p,true)end
end
function A:pulse(index)
    local p=self.character;local move=self.context.action;local origin=PY.MultiHit.origin(p,move.range);if not origin then return end
    local valid={}
    for _,v in ipairs(self.targets)do
        if not v:isDead() and not v:isOnFloor() and not v:isKnockedDown() and math.abs(v:getZ()-p:getZ())<.5 then
            local dx,dy=v:getX()-p:getX(),v:getY()-p:getY();local length=math.sqrt(dx*dx+dy*dy)
            if length>.001 and length<=move.range and (dx*origin.fx+dy*origin.fy)/length>=.5 and p:CanSee(v) and PY.MultiHit.clearPath(p,origin,dx,dy)then valid[#valid+1]=v end
        end
    end
    if #valid==0 then for _,entry in ipairs(PY.MultiHit.targets(p,origin,false,{},PY.MAX_HIT_COUNT))do valid[#valid+1]=entry.victim end end
    self.targets=valid
    if isClient()and PY.Network then
        PY.Network.capture(p,true,true)
        local ids={};for _,v in ipairs(valid)do ids[#ids+1]=v:getOnlineID()end
        PY.Network.send(p,"barrage",{index=index,action=PY.Network.localState(p).action,zombies=ids});return
    end
    if not F.base then F.base=instanceItem(PY.TOKEN)end
    if not F.base then return end
    local damage=R.damage(move,index,(F.base:getMinDamage()+F.base:getMaxDamage())*.5,PY.Heat.isExtreme(p));local hit=false
    for _,v in ipairs(valid)do
        local ok=pcall(v.Hit,v,self.held,p,damage,false,1)
        if ok then
            hit=true
            if index==#move.contactFrames then PY.HitResponses.apply(p,v,{kind="knockdown",force=.75})end
            if PY.HitEffects then PY.HitEffects.spawn(p,v,index==#move.contactFrames)end
            PY.emit("combatHit",p,v,self.held,damage,0)
        end
    end
    if hit then PY.emit("barragePulse",p,move,index,self.context)end
end
function A:update()
    if self.cleaned then return end
    local t=now();local dt=math.max(0,t-self.last);self.last=t
    if isGamePaused()then self.at=self.at+dt;return end
    if not self:isValid()then self:forceStop();return end
    self:hold()
    local marker=self.character:GetVariable("ProjectYakuzaBarrage")or""
    if marker=="done" and self.seen then self:forceComplete();return end
    local move=self.context.action;local phase,weight,slot=PY.AttackEffects.findTrack(self.character,move.animation,self.slot);self.slot=slot
    if phase and weight>=.35 then
        if self.phase and phase+.02<self.phase then self:forceStop();return end
        self.phase=phase;self.seen=true
        while self.index<=#move.contactFrames and phase>=move.contactFrames[self.index]/move.fps do
            local i=self.index;self.index=i+1
            if phase-move.contactFrames[i]/move.fps<=.1 then self:pulse(i)end
        end
    elseif self.seen or t-self.at>600 then self:forceStop();return end
    if marker=="done" and self.seen then self:forceComplete()
    elseif t-self.at>move.duration*1000+800 then self:forceStop()end
end
function A:cleanup(done)
    if self.cleaned then return end;self.cleaned=true;local p=self.character;F.active[p]=nil
    if self.started then
        p:setBlockMovement(self.oldBlock==true);p:setIgnoreMovement(self.oldIgnore==true);p:setDeferredMovementEnabled(self.oldDeferred);p:setVariable("ProjectYakuzaBarrage","")
        PY.Heat.endSwing(p)
    end
    local s=PY.stateFor(p);if s.barrageMove==self.context.action then s.barrageMove=nil;s.finisherMove=nil;s.lastDown=PY.Bindings.down("light")end
    if PY.activeActions[p]==self.context then if done then PY.completeAction(p)else PY.cancelAction(p,"barrage_interrupted")end end
    PY.emit("barrageFinished",p,self.context.action,done==true)
end
function A:perform()self:cleanup(true);ISBaseTimedAction.perform(self)end
function A:stop()self:cleanup(false);ISBaseTimedAction.stop(self)end
function A:cancel()self:cleanup(false);if self.action then self:forceStop()end end
function A:new(c)
    local a=ISBaseTimedAction.new(self,c.player);a.context=c;a.held=c.player:getPrimaryHandItem();a.maxTime=-1;a.stopOnWalk=false;a.stopOnRun=false;a.stopOnAim=false;a.ignoreHandsWounds=true;return a
end
PY.registerActionHandler("barrage",{
    canStart=function(c)
        local p=c.player
        return R.valid(c.action) and not p:isDead() and not p:isOnFloor() and not p:isKnockedDown() and not p:isClimbing() and not p:getVehicle() and (not c.action.extremeHeat or PY.Heat.isExtreme(p)) and p:isAiming() and p:isWeaponReady() and not p:hasTimedActions()
            and not p:isAttackStarted() and not p:isPerformingAttackAnimation() and not p:isBlockMovement() and not p:getIgnoreMovement() and (p:getHitReaction()or"")=="","not_ready"
    end,
    start=function(c)
        PY.resetPlayer(c.player,"barrage_started");local s=PY.stateFor(c.player);s.finisherMove=c.action;s.barrageMove=c.action
        local a=A:new(c);c.timedAction=a;c.requestedAt=now();local ok,q=pcall(ISTimedActionQueue.add,a)
        if not ok or not q then a:cleanup(false);return false,"queue_rejected"end
        return true
    end,
    cancel=function(c)if c.timedAction then c.timedAction:cancel()end end,
})
function F.watch(p,c)if not c.timedAction.started and now()-c.requestedAt>650 then PY.cancelAction(p,"barrage_start_timeout")end end
function F.clear()
    F.pending=setmetatable({}, {__mode="k"});local players={};for p in pairs(F.active)do players[#players+1]=p end
    for _,p in ipairs(players)do PY.cancelAction(p,"world_exit")end
end
PY.on("styleChanged",function(p)F.pending[p]=nil end)
PY.on("comboCancelled",function(p)F.pending[p]=nil end)
Events.OnSave.Add(F.clear);Events.OnMainMenuEnter.Add(F.clear)
