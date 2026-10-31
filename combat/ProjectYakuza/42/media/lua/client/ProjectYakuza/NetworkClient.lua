require "ProjectYakuza/Juggling"
require "ProjectYakuza/Runtime"
require "ProjectYakuza/NetworkProtocol"
require "ProjectYakuza/TauntReactions"
require "ProjectYakuza/SoundVariety"
local ProjectYakuza=ProjectYakuza;local P=ProjectYakuza.NetworkProtocol
local N={locals=setmetatable({}, {__mode="k"}),remote={},leases=setmetatable({}, {__mode="k"}),pending=setmetatable({}, {__mode="k"}),seen={},victims={},deferred={},sessions={},nextRemote=0}
ProjectYakuza.Network=N
local function now()return getTimestampMs()end
function N.localState(p)
    local s=N.locals[p];if not s then s={seq=0,event=0,swing=0};N.locals[p]=s end;return s
end
function N.equip(p,style,playEntry)
    if not isClient() or not p:isLocalPlayer() then return end
    local s=N.localState(p)
    s.entryWanted=playEntry==true or (playEntry==nil and s.equipWanted==style and s.entryWanted) or false
    s.equipWanted=style;s.equipReady=nil;s.equipReply=nil
    s.equipRequest=(s.equipRequest or 0)+1;s.nextEquip=now()+1000
    local item=p:getPrimaryHandItem()
    s.equipSource=item
    local profile=ProjectYakuza.Weapons and ProjectYakuza.Weapons.profile(style,item)
    s.equipTarget=profile and item or nil
    if not profile and (not item or not ProjectYakuza.isStyleToken(item)) then
        local items=p:getInventory():getItems()
        for i=0,items:size()-1 do if ProjectYakuza.isStyleToken(items:get(i)) then item=items:get(i);break end end
    end
    sendClientCommand(p,P.module,"equip",{style=style,request=s.equipRequest,
        weaponProfile=profile or "",item=item and (profile or ProjectYakuza.isStyleToken(item)) and item:getID() or -1})
end
function N.finishEquipment(p,s)
    local a=s.equipReply;if not a then return false end
    local item=a.item~=-1 and p:getInventory():getItemWithID(a.item) or nil
    local armed=a.weaponProfile and a.weaponProfile~=""
    if armed and (s.equipTarget~=p:getPrimaryHandItem() or not item or item~=s.equipTarget) then
        s.equipReply=nil;s.equipWanted=nil;s.equipTarget=nil;s.entryWanted=nil;s.nextEquip=0;return false
    end
    if a.item~=-1 and (not item or (armed and (not ProjectYakuza.Weapons or ProjectYakuza.Weapons.profile(a.style,item)~=a.weaponProfile)) or (not armed and not ProjectYakuza.isStyleToken(item))) then return false end
    if item then ProjectYakuza.prepareToken(item) end
    local held=p:getPrimaryHandItem()
    if not armed and a.style~="none" and held~=s.equipSource and held~=item then
        s.equipReply=nil;s.equipWanted=nil;s.entryWanted=nil;s.nextEquip=0;return false
    end
    if not armed and (a.style~="none" or ProjectYakuza.isStyleToken(held)) then p:setSecondaryHandItem(nil);p:setPrimaryHandItem(item) end
    p:resetModelNextFrame()
    p:updateHandEquips()
    local entry=s.entryWanted;s.entryWanted=nil
    s.equipReady=item;s.equipStyle=a.style;s.equipReply=nil;s.equipWanted=nil
    if ProjectYakuza.StyleItem then ProjectYakuza.StyleItem.remember(p) end
    if entry and item and ProjectYakuza.StyleEntry then ProjectYakuza.StyleEntry.request(p,a.style) end
    return true
end
function N.ensureEquipment(p,style)
    local s=N.localState(p)
    if s.equipReply then N.finishEquipment(p,s) end
    if s.equipReady==p:getPrimaryHandItem() and s.equipStyle==style then return true end
    if now()>=(s.nextEquip or 0) then N.equip(p,style) end
    return false
end
function N.equipmentReady(p)
    local style=ProjectYakuza.getPlayerStyle(p)
    return style and N.ensureEquipment(p,style.id) or false
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
    local context=ProjectYakuza.activeActions[p]
    if not s.active and not (context and context.timedAction and context.timedAction.started) then return "" end
    local group=s.active and (s.groundMove and p:isPerformingStompAnimation() and "stomp" or "melee") or "actions"
    local values={}
    for _,entry in ipairs(P.selectors(style.id,group) or {}) do
        local matches=true
        for _,condition in ipairs(entry.conditions) do
            local value=values[condition.name]
            if value==nil then value=tostring(p:GetVariable(condition.name) or ""):lower();values[condition.name]=value end
            if value~=condition.value then matches=false;break end
        end
        if matches then return entry.id end
    end
    return ""
end
function N.capture(p,force,onlyChanged)
    if not isClient() or not p or not p:isLocalPlayer() then return end
    local s=N.localState(p);local t=now()
    if s.equipReply then N.finishEquipment(p,s) end
    if s.equipWanted then
        if t>=(s.nextEquip or 0) then N.equip(p,s.equipWanted) end
        return
    end
    if not force and t<(s.nextCapture or 0) then return end;s.nextCapture=t+50
    local style=ProjectYakuza.getPlayerStyle(p);local combo=ProjectYakuza.stateFor(p);local equipped=ProjectYakuza.isEquipped(p) and not p:isDead()
    if s.equipWanted then return end
    local action=ProjectYakuza.activeActions[p]
    if equipped and not N.ensureEquipment(p,style.id) then return end
    if action~=s.actionRef then
        s.actionRef=action
        if action then s.action=(s.action or 0)+1 end
    end
    local move=combo.groundMove or combo.finisherMove or combo.activeLightMove or (style and style.lightAttacks[combo.step>0 and combo.step or 1])
    local packet={style=style and style.id or "none",weaponProfile=style and style.weaponProfile or "",equipped=equipped,heat=ProjectYakuza.getHeat(p),fuel=ProjectYakuza.Heat.display(p),extreme=ProjectYakuza.Heat.isExtreme(p),
        clip=equipped and N.pickClip(p,style,combo) or "",move=equipped and move and move.nodeValue or "",
        chargePower=action and action.kind=="heavyCharge" and action.timedAction and (action.timedAction.power or 0) or move and move.chargePower or 0,
        swing=s.swing,action=s.action or 0,taunt=s.taunt or 0,linked=p:GetVariable("ProjectYakuzaLinkedDouble")=="true",ground=combo.groundMove~=nil,phase=p:GetVariable("ProjectYakuzaDefensePhase") or "",
        grabMoving=p:GetVariable("ProjectYakuzaGrabMoving")=="true",grabDirection=action and action.kind=="grab" and action.target:GetVariable("ProjectYakuzaGrabWalkDirection") or "forward"}
    local key=packet.style..tostring(equipped)..math.floor(packet.heat)..math.floor(packet.fuel)..tostring(ProjectYakuza.Heat.stocks(p))..tostring(packet.extreme)..packet.clip..packet.move..packet.phase..tostring(packet.linked)..tostring(packet.grabMoving)..packet.grabDirection..tostring(packet.taunt)..":"..packet.swing..":"..packet.action
    key=key..":"..packet.weaponProfile..":"..math.floor(packet.chargePower*10)
    if (force and not onlyChanged) or key~=s.key or t>=(s.heartbeat or 0) then
        s.seq=s.seq+1;packet.seq=s.seq;sendClientCommand(p,P.module,"state",packet)
        s.key=key;s.heartbeat=t+1000
    end
    if not s.hello then sendClientCommand(p,P.module,"hello",{});s.hello=true end
end
function N.step(p,action,finished)
    if not isClient() or not p:isLocalPlayer() or not action.started then return end
    local t=now()
    if not finished and t<(action.nextNetwork or 0) then return end
    action.nextNetwork=t+50
    local s=N.localState(p)
    if not action.networkID then s.step=(s.step or 0)+1;action.networkID=s.step end
    local fx,fy=ProjectYakuza.Quicksteps.facing(p);if not fx then return end
    N.send(p,"step",{step=action.networkID,clip=action.context.action.animation,
        x=p:getX(),y=p:getY(),z=p:getZ(),fx=fx,fy=fy,finished=finished==true})

    p:setIgnoreMovement(true)
end
function N.updateStep(p,s)
    local step=s.step
    if not step then return end
    local t=now()
    if t>step.expires or not s.packet.equipped or p:isDead() or p:getVehicle() then s.step=nil;return end
    local factor=math.max(0,math.min(1,(t-step.at)/50))
    local x=step.fromX+(step.x-step.fromX)*factor
    local y=step.fromY+(step.y-step.fromY)*factor
    if math.abs(p:getZ()-step.z)>.5 or (p:getX()-x)^2+(p:getY()-y)^2>2.5^2 then s.step=nil;return end

    ProjectYakuza.Defense.snapActor(p,x,y)
    p:setTargetAndCurrentDirection(step.fx,step.fy)
end
function N.send(p,command,args)
    if not isClient() or not p:isLocalPlayer() then return false end
    N.capture(p,true,true)
    local s=N.localState(p);s.event=s.event+1;args.event=s.event
    sendClientCommand(p,P.module,command,args);return true
end
function N.swing(p)
    if not isClient() or not p:isLocalPlayer() then return end
    local s=N.localState(p);s.swing=s.swing+1;N.capture(p,true)
end
function N.sound(p,cue,index,gain)return N.send(p,"sfx",{cue=cue,index=index,gain=gain})end
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
    if s.actionOverride and p:GetVariable("PerformingAction")=="ProjectYakuza_MP" then
        p:setVariable("PerformingAction","");p:setVariable("IsPerformingAnAction",false)
    end
    s.actionOverride=nil
end
function N.clearRemote(id)
    local s=N.remote[id];if not s then return end
    local p=s.actor or getPlayerByOnlineID(id)
    if s.grab then
        local z=s.grab;local restore=s.grabRestore or {}
        z:setVariable("ProjectYakuzaGrabbed",false);z:setVariable("ProjectYakuzaGrabPhase","");z:setVariable("ProjectYakuzaGrabMoving",false)
        z:setUseless(restore.useless==true);z:setIgnoreMovement(restore.ignore==true);z:setDeferredMovementEnabled(restore.deferred~=false)
    end
    if p and not p:isLocalPlayer() then
        N.stopObserver(p,s)
        p:setVariable("ProjectYakuzaRemoteClip","");p:setVariable("ProjectYakuzaActive",false);p:setVariable("ProjectYakuzaStyle","")
        p:setVariable("ProjectYakuzaRemoteObserver",false)
        p:setVariable("ProjectYakuzaRemoteCycle","")
        p:setVariable("ProjectYakuzaMove","");p:setVariable("ProjectYakuzaWeaponProfile","")
        p:setVariable("ProjectYakuzaLinkedDouble",false);p:setVariable("DFCGroundEnabled",false);p:setVariable("ProjectYakuzaRemoteChargePower","0")
        if ProjectYakuza.HeatAura then ProjectYakuza.HeatAura.clear(p) end
        if ProjectYakuza.AttackEffects then ProjectYakuza.AttackEffects.clear(p)end
        if ProjectYakuza.ChargeEffects then ProjectYakuza.ChargeEffects.clear(p)end
        ProjectYakuza.Heat.states[p]=nil
    end
    N.remote[id]=nil
    N.protectionHook()
end
function N.resetPeerEvents(id)
    for key in pairs(N.seen)do if tonumber(string.match(key,"^[^:]+:(%d+):"))==id then N.seen[key]=nil end end
    for key,entry in pairs(N.deferred)do if entry.args.player==id then N.deferred[key]=nil end end
end
function N.acceptSession(id,session)
    if session==nil then return true end
    if not P.integer(session,1,1000000000)then return false end
    local previous=N.sessions[id]
    if previous and session<previous then return false end
    if previous~=session then
        if previous then N.clearRemote(id);N.resetPeerEvents(id)end
        N.sessions[id]=session
    end
    return true
end
function N.applyState(p,packet,s)
    if p:isLocalPlayer() then return end
    p:getModData().ProjectYakuzaStyle=packet.style;p:getModData().ProjectYakuzaHeat=packet.heat
    ProjectYakuza.Heat.states[p]=ProjectYakuza.Heat.states[p] or {}
    local heat=ProjectYakuza.Heat.states[p];heat.extreme=packet.extreme;heat.fuel=packet.fuel
    p:setVariable("ProjectYakuzaActive",packet.equipped);p:setVariable("ProjectYakuzaStyle",packet.equipped and packet.style or "")
    p:setVariable("ProjectYakuzaLinkedDouble",packet.linked);p:setVariable("DFCGroundEnabled",packet.ground)
    p:setVariable("ProjectYakuzaMove",packet.move)
    p:setVariable("ProjectYakuzaWeaponProfile",packet.equipped and (packet.weaponProfile or "") or "")
    p:setVariable("ProjectYakuzaRemoteChargePower",tostring(packet.chargePower or 0))
    p:setVariable("ProjectYakuzaRemoteObserver",packet.equipped)
    ProjectYakuza.Heat.playback(p,packet.extreme)
    local clip=P.clip(packet.style,packet.clip)
    local serialChanged=clip and (clip.group=="actions" and s.action~=(packet.action or 0) or clip.group~="actions" and s.swing~=packet.swing)
    if s.style~=packet.style or s.clip~=packet.clip or serialChanged then
        N.stopObserver(p,s)
        p:setVariable("ProjectYakuzaRemoteClip",packet.clip)
        s.cycle=((s.cycle or 0)+1)%2
        p:setVariable("ProjectYakuzaRemoteCycle",tostring(s.cycle))
        if clip and clip.group=="actions" then

            p:setVariable("PerformingAction","ProjectYakuza_MP");p:setVariable("IsPerformingAnAction",true)
            s.actionOverride=true
        end
        if ProjectYakuza.AttackEffects then ProjectYakuza.AttackEffects.remote(p,ProjectYakuza.getPlayerStyle(p),packet) end
    end
    s.style=packet.style;s.clip=packet.clip;s.swing=packet.swing;s.action=packet.action or 0
    if ProjectYakuza.HeatAura then
        if s.taunt~=nil and (packet.taunt or 0)>s.taunt then ProjectYakuza.HeatAura.flash(p) end
        ProjectYakuza.HeatAura.update(p)
    end
    s.taunt=packet.taunt or 0
    s.applied=packet.seq;s.actor=p
end
function N.defer(command,a)
    if command~="impact" and command~="damage" and command~="juggle"and command~="taunt"then return end
    if not P.integer(a.event,0,1000000000)then return end
    if command=="taunt"then if type(a.zombies)~="table"or #a.zombies<1 or #a.zombies>8 then return end
    elseif not P.integer(a.zombie,-32768,32767)then return end
    local key=command..":"..a.player..":"..a.event
    if N.seen[key] or N.deferred[key] then return end
    local count=0;for _ in pairs(N.deferred) do count=count+1 end
    if count<128 then N.deferred[key]={command=command,args=a,expires=now()+750} end
end
function N.command(module,command,a)
    if module~=P.module or type(a)~="table" then return end
    if command=="equipReady" then
        if not P.integer(a.player,0,32767) or not P.integer(a.item,-2147483648,2147483647) then return end
        local p=getPlayerByOnlineID(a.player)
        if not p or not p:isLocalPlayer() then return end
        local s=N.localState(p)
        if a.request~=s.equipRequest or a.style~=s.equipWanted then return end
        if not N.acceptSession(a.player,a.session)then return end
        s.equipReply=a;N.finishEquipment(p,s);return
    end
    if command=="grabDenied" then
        for p in pairs(N.pending) do N.pending[p]=nil end;return
    end
    if not P.integer(a.player,0,32767) then return end
    local p=getPlayerByOnlineID(a.player)
    if command~="state"and not N.acceptSession(a.player,a.session)then return end
    if command=="sfx"then
        if not p or p:isLocalPlayer()or not P.integer(a.event,0,1000000000)or not P.number(a.gain,0,1)then return end
        local style=ProjectYakuza.getStyle(a.style);if not style then return end
        if ProjectYakuza.Weapons then style=ProjectYakuza.Weapons.view(style,a.weaponProfile)end
        if not ProjectYakuza.SoundVariety.allowed(style,a.cue,a.index)then return end
        local key="sfx:"..a.player..":"..a.event;if N.seen[key]then return end;N.seen[key]=now()
        ProjectYakuza.SoundVariety.play(p,style,a.cue,a.index,a.gain);return
    end
    if command=="step" then
        if not p or p:isLocalPlayer() then return end
        local s=N.remote[a.player];if not s or not s.packet.equipped then return end
        if not P.integer(a.step,1,1000000000) or not P.integer(a.event,0,1000000000)
            or not P.number(a.x,p:getX()-2.5,p:getX()+2.5) or not P.number(a.y,p:getY()-2.5,p:getY()+2.5)
            or not P.number(a.z,p:getZ()-.1,p:getZ()+.1) or not P.number(a.fx,-1,1) or not P.number(a.fy,-1,1) then return end
        local old=s.step
        if (s.stepEvent or -1)>=a.event or (s.stepID or 0)>a.step then return end
        s.stepEvent=a.event;s.stepID=a.step
        local x,y=p:getX(),p:getY()
        if old then N.updateStep(p,s);x,y=p:getX(),p:getY() end
        s.step={id=a.step,at=now(),expires=now()+(a.finished and 100 or 350),
            fromX=x,fromY=y,x=a.x,y=a.y,z=a.z,fx=a.fx,fy=a.fy}
        return
    end
    if command=="state" then
        if a.chargePower~=nil and not P.number(a.chargePower,0,1) then return end
        if not P.integer(a.seq,0,1000000000) or not P.number(a.heat,0,100) or not P.number(a.fuel,0,100) then return end
        if a.taunt~=nil and not P.integer(a.taunt,0,1000000000) then return end
        if not N.acceptSession(a.player,a.session)then return end
        local s=N.remote[a.player]
        if s and p and s.actor and s.actor~=p then N.clearRemote(a.player);N.resetPeerEvents(a.player);s=nil end
        if s and a.seq<s.packet.seq then return end
        if type(a.style)~="string"or (a.style~="none"and not ProjectYakuza.getStyle(a.style))then N.clearRemote(a.player);return end
        if p and p:isLocalPlayer() then return end
        if not s then s={};N.remote[a.player]=s end
        s.packet=a;s.last=now()
        N.protectionHook()
        if p then N.applyState(p,a,s) end
        return
    end
    if not p then N.defer(command,a);return end
    if command=="taunt"then
        local cfg=ProjectYakuza.TauntReactions.config(ProjectYakuza.getStyle(a.style))
        if not cfg or not P.integer(a.event,0,1000000000)or type(a.zombies)~="table"or #a.zombies<1 or #a.zombies>cfg.maxTargets then return end
        local key="taunt:"..a.player..":"..a.event;if N.seen[key]then return end
        local ids={};local count=0
        for _,id in ipairs(a.zombies)do if not P.integer(id,-32768,32767)or id==-1 or ids[id]then return end;ids[id]=true;count=count+1 end
        local matched=0
        for _,z in ipairs(ProjectYakuza.TauntReactions.targets(p,cfg,ids))do
            matched=matched+1;local targetKey="tauntTarget:"..a.player..":"..a.event..":"..z:getOnlineID()
            if not N.seen[targetKey]then N.seen[targetKey]=now();ProjectYakuza.TauntReactions.apply(p,z,cfg)end
        end
        if matched<count then N.defer(command,a)else N.seen[key]=now();N.deferred[key]=nil end
        return
    end
    local z=P.zombie(p,a.zombie)
    local recent=N.victims[a.zombie]
    if not z and recent and now()-recent.time<1500 and P.near(p,recent.z,3) then z=recent.z end
    if not z then N.defer(command,a);return end
    if command=="impact" or command=="damage" or command=="juggle" then N.deferred[command..":"..a.player..":"..tostring(a.event)]=nil end
    if command=="grabStart" then
        if p:isLocalPlayer() then
            N.leases[p]=a.zombie;N.pending[p]=nil
            local ok=ProjectYakuza.requestAction(p,"grab",nil,z)
            if not ok then N.releaseGrab(p) end
        else
            local s=N.remote[a.player];if s then s.grab=z;s.grabRestore=a end
            z:setVariable("ProjectYakuzaGrabbed",true);z:setVariable("ProjectYakuzaGrabPhase","enter");z:setHitReaction("ProjectYakuzaGrabbed")
            z:reportEvent("wasHit")
        end
    elseif command=="grabEnd" then
        N.leases[p]=nil
        if p:isLocalPlayer() then local c=ProjectYakuza.activeActions[p];if c and c.kind=="grab" then ProjectYakuza.cancelAction(p,"server_released") end end
        if not p:isLocalPlayer() then
            z:setVariable("ProjectYakuzaGrabbed",false);z:setVariable("ProjectYakuzaGrabPhase","");z:setVariable("ProjectYakuzaGrabMoving",false)
            z:setUseless(a.useless==true);z:setIgnoreMovement(a.ignore==true);z:setDeferredMovementEnabled(a.deferred==true)
            if z:getHitReaction()=="ProjectYakuzaGrabbed" then z:setHitReaction("");z:reportEvent("ActiveAnimFinishing") end
            local s=N.remote[a.player];if s then s.grab=nil end
        end
    elseif command=="grabPose" then
        if not P.number(a.x,p:getX()-2,p:getX()+2) or not P.number(a.y,p:getY()-2,p:getY()+2) then return end
        if not p:isLocalPlayer() then
            local s=N.remote[a.player];if s then s.grab=z;s.grabRestore=a end
            ProjectYakuza.Defense.snapActor(z,a.x,a.y);z:setTargetAndCurrentDirection(-a.fx,-a.fy)
            z:setUseless(true);z:setIgnoreMovement(true);z:setDeferredMovementEnabled(false)
            z:setVariable("ProjectYakuzaGrabbed",true);z:setVariable("ProjectYakuzaGrabPhase",a.phase)
            z:setVariable("ProjectYakuzaGrabMoving",a.moving==true);z:setVariable("ProjectYakuzaGrabWalkDirection",a.direction or "forward")
        end
    elseif command=="guard" then z:setAttackOutcome("fail");z:setTarget(nil)
        if not p:isLocalPlayer() and ProjectYakuza.HitEffects then ProjectYakuza.HitEffects.guard(p,z) end
    elseif command=="juggle" then
        local key="juggle:"..a.player..":"..tostring(a.event)
        if N.seen[key] then return end;N.seen[key]=now()
        ProjectYakuza.Juggling.receive(p,z,a.juggle)
    elseif command=="impact" then
        local key="impact:"..a.player..":"..tostring(a.event)
        if N.seen[key] then return end;N.seen[key]=now()
        ProjectYakuza.Juggling.receive(p,z,a.juggle)
        local clip=P.reaction(a.style,a.reaction) and a.reaction or nil
        local response=ProjectYakuza.Reactions and ProjectYakuza.Reactions.confirmed(p,z,a.responseKind,a.responseForce,clip)
        if p:isLocalPlayer() then return end
        if ProjectYakuza.HitEffects then ProjectYakuza.HitEffects.spawn(p,z,a.strong,a.charged) end
        if not response and ProjectYakuza.Reactions and clip then ProjectYakuza.Reactions.remote(z,clip) end
    elseif command=="damage" then
        local key="damage:"..a.player..":"..tostring(a.event)
        if N.seen[key] then return end;N.seen[key]=now()
        if not P.number(a.health,0,1000) then return end

        z:setHealth(math.min(z:getHealth(),a.health));z:setAttackedBy(p)
        if P.number(a.dx,-1,1) and P.number(a.dy,-1,1) then z:getHitDir():set(a.dx,a.dy) end
        if P.number(a.force,0,12) then z:setHitForce(a.force) end
        if type(a.hitReaction)=="string" and #a.hitReaction<80 then z:setHitReaction(a.hitReaction);z:reportEvent("wasHit") end
        if a.kill then z:getHitDir():set(a.dx,a.dy);z:setHitForce(12);z:setUsePhysicHitReaction(true);z:setHitReaction("ShotBelly") end
        if a.knock then z:setKnockedDown(true);z:setFallOnFront(false) end
        ProjectYakuza.Juggling.receive(p,z,a.juggle)
        if not a.kill and not a.knock and ProjectYakuza.Reactions then
            local clip=P.reaction(a.style,a.reaction) and a.reaction or nil
            if not ProjectYakuza.Reactions.confirmed(p,z,a.responseKind,a.responseForce,clip) and clip then ProjectYakuza.Reactions.remote(z,clip) end
        end
        if p:isLocalPlayer() then
            N.replaying=true
            if a.kill then ProjectYakuza.emit("tigerDrop",p,z)
            elseif a.knock then ProjectYakuza.emit("throwHit",p,z)
            elseif P.number(a.amount,0,10) then
                local combo=ProjectYakuza.stateFor(p);ProjectYakuza.Heat.onHit(p,z,a.amount,combo)
                ProjectYakuza.emit("combatHit",p,z,p:getPrimaryHandItem(),a.amount,combo.step)
            end
            N.replaying=false
        elseif ProjectYakuza.HitEffects then ProjectYakuza.HitEffects.spawn(p,z,true) end
    end
end
function N.update(p)
    if not isClient() then return end
    if p:isLocalPlayer() then N.capture(p);return end
    local s=N.remote[p:getOnlineID()]
    if s then N.updateStep(p,s) end
    if s and now()-s.last<4000 and (s.applied~=s.packet.seq or s.actor~=p) then N.applyState(p,s.packet,s) end
end
function N.tick()
    if not isClient() then return end
    if now()>=(N.nextDeferred or 0) then
        N.nextDeferred=now()+50
        local queued={};for key,entry in pairs(N.deferred) do queued[#queued+1]={key=key,entry=entry} end
        for _,job in ipairs(queued) do
            if now()>job.entry.expires then N.deferred[job.key]=nil
            else N.command(P.module,job.entry.command,job.entry.args) end
        end
    end
    if now()<N.nextRemote then return end;N.nextRemote=now()+500
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
    N.locals=setmetatable({}, {__mode="k"});N.seen={};N.victims={};N.deferred={};N.sessions={};N.pending=setmetatable({}, {__mode="k"})
end
ProjectYakuza.on("lightAttackStarted",N.swing)
ProjectYakuza.on("finisherStarted",N.swing)
ProjectYakuza.on("runningAttackStarted",N.swing)
ProjectYakuza.on("quickstepAttackStarted",N.swing)
ProjectYakuza.on("chargedHeavyStarted",N.swing)
ProjectYakuza.on("groundAttackStarted",N.swing)
ProjectYakuza.on("tauntStopped",function(p,completed)
    if completed and isClient() and p:isLocalPlayer() then
        local s=N.localState(p);s.taunt=(s.taunt or 0)+1;N.capture(p,true)
    end
end)
ProjectYakuza.on("combatHit",N.hit)
ProjectYakuza.on("guardHit",function(p,z)if isClient() then N.send(p,"guard",{zombie=z:getOnlineID()}) end end)
Events.OnServerCommand.Add(N.command)
Events.OnPlayerUpdate.Add(N.update)
Events.OnTick.Add(N.tick)
Events.OnMainMenuEnter.Add(N.clear)
Events.OnWeaponHitCharacter.Add(function(p,z)
    if isClient() and z and instanceof(z,"IsoZombie") then N.victims[z:getOnlineID()]={z=z,time=now()} end
end)
