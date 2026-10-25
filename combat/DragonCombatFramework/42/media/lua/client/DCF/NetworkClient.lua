require "DCF/Runtime"
require "DCF/NetworkProtocol"
local DCF=DragonCombat;local P=DCF.NetworkProtocol
local N={locals=setmetatable({}, {__mode="k"}),remote={},leases=setmetatable({}, {__mode="k"}),pending=setmetatable({}, {__mode="k"}),seen={},victims={},nextRemote=0}
DCF.Network=N
local function now()return getTimestampMs()end
function N.localState(p)
    local s=N.locals[p];if not s then s={seq=0,event=0,swing=0};N.locals[p]=s end;return s
end
function N.remoteEquipped(p)
    if p:isLocalPlayer() then return nil end
    local s=N.remote[p:getOnlineID()];return s and s.packet.equipped==true or false
end
function N.protectionHook()
    local active=false
    for _,s in pairs(N.remote) do if s.packet.protected then active=true;break end end
    if active and not N.protectionActive then Events.OnZombieUpdate.Add(N.protect);N.protectionActive=true
    elseif not active and N.protectionActive then Events.OnZombieUpdate.Remove(N.protect);N.protectionActive=false end
end
function N.pickClip(p,style,s)
    if not style then return "" end
    local context=DCF.activeActions[p]
    if not s.active and not (context and context.timedAction and context.timedAction.started) then return "" end
    local group=s.active and (s.groundMove and p:isPerformingStompAnimation() and "stomp" or "melee") or "actions"
    for _,entry in ipairs(DCF.NetworkCatalog[style.id] or {}) do if entry.group==group then
        local matches=true
        for _,condition in ipairs(entry.conditions) do
            if tostring(p:GetVariable(condition.name) or ""):lower()~=condition.value:lower() then matches=false;break end
        end
        if matches then return entry.id end
    end end
    return ""
end
function N.capture(p,force)
    if not isClient() or not p or not p:isLocalPlayer() then return end
    local s=N.localState(p);local t=now()
    if not force and t<(s.nextCapture or 0) then return end;s.nextCapture=t+100
    local style=DCF.getPlayerStyle(p);local combo=DCF.stateFor(p);local equipped=DCF.isEquipped(p) and not p:isDead()
    local action=DCF.activeActions[p]
    local move=combo.groundMove or combo.finisherMove or (style and style.lightAttacks[combo.step>0 and combo.step or 1])
    local packet={style=style and style.id or "none",equipped=equipped,heat=DCF.getHeat(p),fuel=DCF.Heat.display(p),extreme=DCF.Heat.isExtreme(p),
        clip=equipped and N.pickClip(p,style,combo) or "",move=equipped and move and move.nodeValue or "",
        swing=s.swing,taunt=s.taunt or 0,linked=p:GetVariable("DCFLinkedDouble")=="true",ground=combo.groundMove~=nil,phase=p:GetVariable("DCFDefensePhase") or "",
        grabMoving=p:GetVariable("DCFGrabMoving")=="true",grabDirection=action and action.kind=="grab" and action.target:GetVariable("DCFGrabWalkDirection") or "forward"}
    local key=packet.style..tostring(equipped)..math.floor(packet.heat)..math.floor(packet.fuel)..tostring(DCF.Heat.stocks(p))..tostring(packet.extreme)..packet.clip..packet.move..packet.phase..tostring(packet.linked)..tostring(packet.grabMoving)..packet.grabDirection..tostring(packet.taunt)
    if force or key~=s.key or t>=(s.heartbeat or 0) then
        s.seq=s.seq+1;packet.seq=s.seq;sendClientCommand(p,P.module,"state",packet)
        s.key=key;s.heartbeat=t+1000
    end
    if not s.hello then sendClientCommand(p,P.module,"hello",{});s.hello=true end
end
function N.send(p,command,args)
    if not isClient() or not p:isLocalPlayer() then return false end
    N.capture(p,true)
    local s=N.localState(p);s.event=s.event+1;args.event=s.event
    sendClientCommand(p,P.module,command,args);return true
end
function N.swing(p)
    if not isClient() or not p:isLocalPlayer() then return end
    local s=N.localState(p);s.swing=s.swing+1;N.capture(p,true)
end
function N.hit(p,z,weapon,damage)
    if N.replaying or not isClient() or not p or not p:isLocalPlayer() or not z or not instanceof(z,"IsoZombie") or type(damage)~="number" or damage<=0 then return end
    local s=N.localState(p);if s.swing<1 then return end
    N.send(p,"impact",{zombie=z:getOnlineID(),swing=s.swing})
end
function N.extra(p,z)
    return N.send(p,"extra",{zombie=z:getOnlineID(),swing=N.localState(p).swing})
end
function N.requestGrab(p,z)
    if N.leases[p]==z:getOnlineID() then return true end
    local job=N.pending[p]
    if not job or now()-job.at>1500 then N.pending[p]={z=z,at=now()};N.send(p,"grabRequest",{zombie=z:getOnlineID()}) end
    return false
end
function N.releaseGrab(p)
    if not isClient() or not p:isLocalPlayer() then return end
    if N.leases[p] then N.send(p,"grabRelease",{}) end
    N.leases[p]=nil;N.pending[p]=nil
end
function N.stopObserver(p,s)
    if s.actionOverride and p:GetVariable("PerformingAction")=="DCF_MP" then
        p:setVariable("PerformingAction","");p:setVariable("IsPerformingAnAction",false)
    end
    s.actionOverride=nil
end
function N.clearRemote(id)
    local s=N.remote[id];if not s then return end
    local p=getPlayerByOnlineID(id)
    if s.grab then
        local z=s.grab;local restore=s.grabRestore or {}
        z:setVariable("DCFGrabbed",false);z:setVariable("DCFGrabPhase","");z:setVariable("DCFGrabMoving",false)
        z:setUseless(restore.useless==true);z:setIgnoreMovement(restore.ignore==true);z:setDeferredMovementEnabled(restore.deferred~=false)
    end
    if p and not p:isLocalPlayer() then
        N.stopObserver(p,s)
        p:setVariable("DCFRemoteClip","");p:setVariable("DCFActive",false);p:setVariable("DCFStyle","")
        p:setVariable("DCFRemoteObserver",false)
        if DCF.HeatAura then DCF.HeatAura.clear(p) end
    end
    N.remote[id]=nil
    N.protectionHook()
end
function N.applyState(p,packet,s)
    if p:isLocalPlayer() then return end
    p:getModData().DCFStyle=packet.style;p:getModData().DCFHeat=packet.heat
    DCF.Heat.states[p]=DCF.Heat.states[p] or {}
    local heat=DCF.Heat.states[p];heat.extreme=packet.extreme;heat.fuel=packet.fuel
    p:setVariable("DCFActive",packet.equipped);p:setVariable("DCFStyle",packet.equipped and packet.style or "")
    p:setVariable("DCFLinkedDouble",packet.linked);p:setVariable("DFCGroundEnabled",packet.ground)
    p:setVariable("DCFMove",packet.move)
    p:setVariable("DCFRemoteObserver",packet.equipped)
    DCF.Heat.playback(p,packet.extreme)
    if s.clip~=packet.clip or (packet.clip~="" and s.swing~=packet.swing) then
        N.stopObserver(p,s)
        p:setVariable("DCFRemoteClip",packet.clip)
        local clip=P.clip(packet.style,packet.clip)
        if clip and clip.group=="actions" then
            -- Match BaseAction.setActionAnim's actual native variables. The melee/stomp
            -- observers stay in their native action groups and use PZ attack replication.
            p:setVariable("PerformingAction","DCF_MP");p:setVariable("IsPerformingAnAction",true)
            s.actionOverride=true
        end
        s.clip=packet.clip;s.swing=packet.swing
    end
    if DCF.HeatAura then
        if s.taunt~=nil and (packet.taunt or 0)>s.taunt then DCF.HeatAura.flash(p) end
        DCF.HeatAura.update(p)
    end
    s.taunt=packet.taunt or 0
    s.applied=packet.seq;s.actor=p
end
function N.command(module,command,a)
    if module~=P.module or type(a)~="table" then return end
    if command=="grabDenied" then
        for p in pairs(N.pending) do N.pending[p]=nil end;return
    end
    if not P.integer(a.player,0,32767) then return end
    local p=getPlayerByOnlineID(a.player)
    if command=="state" then
        if not P.integer(a.seq,0,1000000000) or not P.number(a.heat,0,100) or not P.number(a.fuel,0,100) then return end
        if a.taunt~=nil and not P.integer(a.taunt,0,1000000000) then return end
        local s=N.remote[a.player]
        if s and a.seq<s.packet.seq then return end
        if p and p:isLocalPlayer() then return end
        if not s then s={};N.remote[a.player]=s end
        s.packet=a;s.last=now()
        N.protectionHook()
        if p then N.applyState(p,a,s) end
        return
    end
    if not p then return end
    local z=P.zombie(p,a.zombie)
    local recent=N.victims[a.zombie]
    if not z and recent and now()-recent.time<1500 and P.near(p,recent.z,3) then z=recent.z end
    if not z then return end
    if command=="grabStart" then
        if p:isLocalPlayer() then
            N.leases[p]=a.zombie;N.pending[p]=nil
            local ok=DCF.requestAction(p,"grab",nil,z)
            if not ok then N.releaseGrab(p) end
        else
            local s=N.remote[a.player];if s then s.grab=z;s.grabRestore=a end
            z:setVariable("DCFGrabbed",true);z:setVariable("DCFGrabPhase","enter");z:setHitReaction("DCFGrabbed")
            z:reportEvent("wasHit")
        end
    elseif command=="grabEnd" then
        N.leases[p]=nil
        if p:isLocalPlayer() then local c=DCF.activeActions[p];if c and c.kind=="grab" then DCF.cancelAction(p,"server_released") end end
        if not p:isLocalPlayer() then
            z:setVariable("DCFGrabbed",false);z:setVariable("DCFGrabPhase","");z:setVariable("DCFGrabMoving",false)
            z:setUseless(a.useless==true);z:setIgnoreMovement(a.ignore==true);z:setDeferredMovementEnabled(a.deferred==true)
            if z:getHitReaction()=="DCFGrabbed" then z:setHitReaction("");z:reportEvent("ActiveAnimFinishing") end
            local s=N.remote[a.player];if s then s.grab=nil end
        end
    elseif command=="grabPose" then
        if not P.number(a.x,p:getX()-2,p:getX()+2) or not P.number(a.y,p:getY()-2,p:getY()+2) then return end
        if not p:isLocalPlayer() then
            local s=N.remote[a.player];if s then s.grab=z;s.grabRestore=a end
            DCF.Defense.snapActor(z,a.x,a.y);z:setTargetAndCurrentDirection(-a.fx,-a.fy)
            z:setUseless(true);z:setIgnoreMovement(true);z:setDeferredMovementEnabled(false)
            z:setVariable("DCFGrabbed",true);z:setVariable("DCFGrabPhase",a.phase)
            z:setVariable("DCFGrabMoving",a.moving==true);z:setVariable("DCFGrabWalkDirection",a.direction or "forward")
        end
    elseif command=="guard" then z:setAttackOutcome("fail");z:setTarget(nil)
    elseif command=="impact" then
        if p:isLocalPlayer() then return end
        local key="impact:"..a.player..":"..tostring(a.event)
        if N.seen[key] then return end;N.seen[key]=now()
        if DCF.HitEffects then DCF.HitEffects.spawn(p,z,a.strong) end
        if DCF.Reactions then DCF.Reactions.remote(z,a.reaction) end
    elseif command=="damage" then
        local key="damage:"..a.player..":"..tostring(a.event)
        if N.seen[key] then return end;N.seen[key]=now()
        if not P.number(a.health,0,1000) then return end
        -- Absolute server result only. Observers never call Hit/Kill or award damage twice.
        z:setHealth(math.min(z:getHealth(),a.health));z:setAttackedBy(p)
        if P.number(a.dx,-1,1) and P.number(a.dy,-1,1) then z:getHitDir():set(a.dx,a.dy) end
        if P.number(a.force,0,12) then z:setHitForce(a.force) end
        if type(a.hitReaction)=="string" and #a.hitReaction<80 then z:setHitReaction(a.hitReaction);z:reportEvent("wasHit") end
        if a.kill then z:getHitDir():set(a.dx,a.dy);z:setHitForce(12);z:setUsePhysicHitReaction(true);z:setHitReaction("ShotBelly") end
        if a.knock then z:setKnockedDown(true);z:setFallOnFront(false) end
        if not a.kill and not a.knock and DCF.Reactions then DCF.Reactions.remote(z,a.reaction) end
        if p:isLocalPlayer() then
            N.replaying=true
            if a.kill then DCF.emit("tigerDrop",p,z)
            elseif a.knock then DCF.emit("throwHit",p,z)
            elseif P.number(a.amount,0,10) then
                local combo=DCF.stateFor(p);DCF.Heat.onHit(p,z,a.amount,combo)
                DCF.emit("combatHit",p,z,p:getPrimaryHandItem(),a.amount,combo.step)
            end
            N.replaying=false
        elseif DCF.HitEffects then DCF.HitEffects.spawn(p,z,true) end
    end
end
function N.update(p)
    if not isClient() then return end
    if p:isLocalPlayer() then N.capture(p);return end
    local s=N.remote[p:getOnlineID()]
    if s and now()-s.last<4000 and (s.applied~=s.packet.seq or s.actor~=p) then N.applyState(p,s.packet,s) end
end
function N.tick()
    if not isClient() or now()<N.nextRemote then return end;N.nextRemote=now()+500
    for id,s in pairs(N.remote) do if now()-s.last>4000 then N.clearRemote(id) end end
    for key,t in pairs(N.seen) do if now()-t>5000 then N.seen[key]=nil end end
    for key,entry in pairs(N.victims) do if now()-entry.time>1500 then N.victims[key]=nil end end
end
function N.protect(z)
    if not isClient() or z:isRemoteZombie() then return end
    local p=z:getTarget();local s=p and not p:isLocalPlayer() and N.remote[p:getOnlineID()]
    local clip=s and P.clip(s.packet.style,s.packet.clip)
    if clip and s.packet.protected and P.kind(s.packet.style,clip.id)=="heatActivation" and now()-s.last<3000 and P.near(p,z,3) then
        z:setAttackOutcome("fail");z:setTarget(nil)
    end
end
function N.clear()
    for id in pairs(N.remote) do N.clearRemote(id) end
    for p in pairs(N.leases) do N.releaseGrab(p) end
    N.locals=setmetatable({}, {__mode="k"});N.seen={};N.victims={};N.pending=setmetatable({}, {__mode="k"})
end
DCF.on("lightAttackStarted",N.swing)
DCF.on("finisherStarted",N.swing)
DCF.on("runningAttackStarted",N.swing)
DCF.on("quickstepAttackStarted",N.swing)
DCF.on("groundAttackStarted",N.swing)
DCF.on("tauntStopped",function(p,completed)
    if completed and isClient() and p:isLocalPlayer() then
        local s=N.localState(p);s.taunt=(s.taunt or 0)+1;N.capture(p,true)
    end
end)
DCF.on("combatHit",N.hit)
DCF.on("guardHit",function(p,z)if isClient() then N.send(p,"guard",{zombie=z:getOnlineID()}) end end)
Events.OnServerCommand.Add(N.command)
Events.OnPlayerUpdate.Add(N.update)
Events.OnTick.Add(N.tick)
Events.OnMainMenuEnter.Add(N.clear)
Events.OnWeaponHitCharacter.Add(function(p,z)
    if isClient() and z and instanceof(z,"IsoZombie") then N.victims[z:getOnlineID()]={z=z,time=now()} end
end)
