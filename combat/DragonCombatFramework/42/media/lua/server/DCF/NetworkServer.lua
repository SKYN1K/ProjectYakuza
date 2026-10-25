if not isServer() then return end
require "DCF/Styles/DragonOfDojima"
require "DCF/NetworkProtocol"
local DCF=DragonCombat;local P=DCF.NetworkProtocol
local S={players={},grabs={},nextTick=0}
DCF.NetworkServer=S
local function now()return getTimestampMs()end
local function alive(p)return p and not p:isDead() and not p:getVehicle() end
local function reply(p,command,args)sendServerCommand(p,P.module,command,args)end
function S.fanout(p,command,args)
    local all=getOnlinePlayers()
    for i=0,all:size()-1 do local other=all:get(i)
        if math.abs(other:getZ()-p:getZ())<2 and (other:getX()-p:getX())^2+(other:getY()-p:getY())^2<=P.range^2 then reply(other,command,args) end
    end
end
local function state(p)
    local id=p:getOnlineID();local s=S.players[id]
    if not s or s.player~=p then s={player=p,seq=-1,event=-1,swings={}};S.players[id]=s end
    return s
end
local function token(p)local item=p:getPrimaryHandItem();return item and item:getFullType()==DCF.TOKEN and item end
function S.restoreProtection(p,s)
    local protection=s.protection;if not protection then return end
    p:setGhostMode(protection.ghost);p:setInvincible(protection.invincible);s.protection=nil
end
function S.release(p)
    local s=S.players[p:getOnlineID()];local lease=s and s.grab
    if not lease then return end
    local z=lease.z;S.grabs[z]=nil;s.grab=nil
    z:setUseless(lease.useless);z:setIgnoreMovement(lease.ignore);z:setDeferredMovementEnabled(lease.deferred)
    if not z:isDead() and z:getTarget()==nil and lease.target then z:setTarget(lease.target) end
    S.fanout(p,"grabEnd",{player=p:getOnlineID(),zombie=z:getOnlineID(),useless=lease.useless,ignore=lease.ignore,deferred=lease.deferred})
end
function S.snapshot(p,a,s)
    if not P.integer(a.seq,0,1000000000) or a.seq<=s.seq then return end
    -- Short action/attack transitions can share a millisecond. Dropping the
    -- second state leaves observers on an old clip until the idle heartbeat.
    local t=now()
    if t-(s.stateBucketAt or 0)>=1000 then s.stateBucketAt=t;s.stateBucket=0 end
    s.stateBucket=(s.stateBucket or 0)+1;if s.stateBucket>80 then return end
    if type(a.style)~="string" or #a.style>100 or (a.style~="none" and not DCF.getStyle(a.style)) then return end
    if not P.number(a.heat,0,100) or not P.number(a.fuel,0,100) then return end
    local equipped=a.equipped==true and DCF.getStyle(a.style)~=nil and alive(p) and token(p)~=nil
    local clip=equipped and type(a.clip)=="string" and P.clip(a.style,a.clip) or nil
    local style=DCF.getStyle(a.style)
    local kind,activation
    if clip then kind,activation=P.kind(a.style,clip.id) end
    if not equipped or kind~="heatActivation" then S.restoreProtection(p,s);s.wasActivation=false
    elseif not s.wasActivation then
        s.wasActivation=true
        if a.heat>=100/6 and activation then
            s.protection={ghost=p:isGhostMode(),invincible=p:isInvincible(),expires=now()+math.min(3500,(activation.duration or 2)*1000+500)}
            p:setGhostMode(true);p:setInvincible(true)
        end
    end
    local packet={player=p:getOnlineID(),seq=a.seq,style=a.style,equipped=equipped,
        heat=equipped and a.heat or 0,fuel=equipped and a.fuel or 0,extreme=equipped and a.extreme==true and style.heat==true,
        clip=clip and clip.id or "",move=equipped and type(a.move)=="string" and P.move(a.style,a.move) and a.move or "",
        swing=P.integer(a.swing,0,1000000000) and a.swing or 0,
        action=P.integer(a.action,0,1000000000) and a.action or 0,
        taunt=equipped and style.actions.taunt and P.integer(a.taunt,0,1000000000) and a.taunt or 0,
        protected=s.protection~=nil,grabMoving=a.grabMoving==true,
        grabDirection=(a.grabDirection=="forward" or a.grabDirection=="backward" or a.grabDirection=="left" or a.grabDirection=="right") and a.grabDirection or "forward",
        linked=a.linked==true,ground=a.ground==true,phase=(a.phase=="enter" or a.phase=="hold" or a.phase=="hit" or a.phase=="throw" or a.phase=="exit") and a.phase or ""}
    s.seq=a.seq;s.packet=packet;s.seen=now()
    p:getModData().DCFStyle=a.style;p:getModData().DCFHeat=packet.heat
    if not equipped then S.release(p) end
    S.fanout(p,"state",packet)
end
function S.equip(p,a,s)
    if not alive(p) or not P.integer(a.request,1,1000000000) or type(a.style)~="string"
        or (a.style~="none" and not DCF.getStyle(a.style)) then return end
    if a.request<(s.equipRequest or 0) then return end
    if now()<(s.nextEquip or 0) then return end
    s.equipRequest=a.request;s.nextEquip=now()+200
    local item
    if a.style~="none" then
        local inventory=p:getInventory();local items=inventory:getItems()
        for i=0,items:size()-1 do
            local candidate=items:get(i)
            if candidate:getFullType()==DCF.TOKEN then item=candidate;break end
        end
        local created=not item
        if not item then item=inventory:AddItem(DCF.TOKEN) end
        if not item then return end
        item:setMaxHitCount(DCF.MAX_HIT_COUNT)
        item:setWeaponSprite("DCF_EmptyHand");item:setOriginalWeaponSprite("DCF_EmptyHand")
        -- These B42 globals only send from a server. Native equip/hit packets
        -- subsequently resolve this exact server inventory ID.
        if created or a.item~=item:getID() then sendAddItemToContainer(inventory,item) end
        p:setSecondaryHandItem(nil);p:setPrimaryHandItem(item)
    elseif token(p) then p:setPrimaryHandItem(nil) end
    p:getModData().DCFStyle=a.style
    sendEquip(p)
    reply(p,"equipReady",{player=p:getOnlineID(),request=a.request,style=a.style,item=item and item:getID() or -1})
    if a.style=="none" then
        S.restoreProtection(p,s);S.release(p)
        if s.packet then s.packet.equipped=false;s.packet.clip="";S.fanout(p,"state",s.packet) end
    end
end
function S.step(p,a,s)
    if not P.integer(a.step,1,1000000000) or type(a.clip)~="string" then return end
    local kind,move=P.kind(s.packet.style,a.clip)
    if kind~="quickstep" or not move or not P.number(move.distance,0,3) then return end
    if not P.number(a.x,p:getX()-2,p:getX()+2) or not P.number(a.y,p:getY()-2,p:getY()+2)
        or not P.number(a.z,p:getZ()-.1,p:getZ()+.1) or not P.number(a.fx,-1,1) or not P.number(a.fy,-1,1) then return end
    local t=now();local step=s.step
    if not step or a.step~=step.id then
        if a.step<=(s.lastStep or 0) then return end
        local history={}
        for _,stamp in ipairs(s.steps or {}) do if t-stamp<15000 then history[#history+1]=stamp end end
        if #history>=3 then return end
        history[#history+1]=t;s.steps=history
        step={id=a.step,clip=a.clip,x=a.x,y=a.y,travel=0,expires=t+(move.duration or .5)*1000+750}
        s.step=step;s.lastStep=a.step
    end
    if step.finished or step.clip~=a.clip or t>step.expires then return end
    if not a.finished and t<(step.nextSample or 0) then return end
    local dx,dy=a.x-step.x,a.y-step.y;local length=math.sqrt(dx*dx+dy*dy)
    if step.travel+length>move.distance+.15 or not P.path(p,a.x,a.y) then return end
    local f=math.sqrt(a.fx*a.fx+a.fy*a.fy);if f<.9 or f>1.1 then return end
    step.travel=step.travel+length;step.x=a.x;step.y=a.y;step.nextSample=t+30;step.finished=a.finished==true
    S.fanout(p,"step",{player=p:getOnlineID(),event=a.event,step=a.step,x=a.x,y=a.y,z=a.z,
        fx=a.fx/f,fy=a.fy/f,finished=step.finished})
end
function S.validVictim(p,id,range,cone)
    local z=P.zombie(p,id)
    if not z or z:isDead() or not P.near(p,z,range) or not P.path(p,z:getX(),z:getY()) then return nil end
    local f=p:getForwardDirection();local dx,dy=z:getX()-p:getX(),z:getY()-p:getY()
    local distance=math.sqrt(dx*dx+dy*dy);local length=math.sqrt(f:getX()^2+f:getY()^2)
    if distance<.001 or length<.001 or (dx*f:getX()+dy*f:getY())/(distance*length)<(cone or .5) then return nil end
    return z
end
function S.damage(p,z,amount,knock,kill,s)
    local item=token(p);if not item then return end
    local dx,dy=z:getX()-p:getX(),z:getY()-p:getY();local n=math.sqrt(dx*dx+dy*dy)
    if n<.001 then return end
    z:setAttackedBy(p);z:getHitDir():set(dx/n,dy/n)
    if kill then z:setAttackOutcome("fail");z:setTarget(nil);z:setHitForce(12);z:setUsePhysicHitReaction(true);z:setHitReaction("ShotBelly");z:Kill(p)
    else S.processing=true;local ok,err=pcall(z.Hit,z,item,p,amount,false,1);S.processing=false
        if not ok then print("[DCF] server hit failed: "..tostring(err));return end end
    if knock then z:setKnockedDown(true);z:setFallOnFront(false) end
    s.result=(s.result or 0)+1
    local move=P.move(s.packet.style,s.packet.move)
    S.fanout(p,"damage",{player=p:getOnlineID(),event=s.result,zombie=z:getOnlineID(),health=math.max(0,z:getHealth()),amount=amount,knock=knock==true,kill=kill==true,
        dx=dx/n,dy=dy/n,force=z:getHitForce(),hitReaction=z:getHitReaction() or "ShotBelly",reaction=move and move.reaction or "",style=s.packet.style})
end
function S.command(module,command,p,a)
    if module~=P.module or type(a)~="table" or not p then return end
    local s=state(p);local t=now()
    if command=="equip" then S.equip(p,a,s);return end
    if command=="hello" then
        if t<(s.nextHello or 0) then return end;s.nextHello=t+2000
        for _,other in pairs(S.players) do if other.packet and other.player~=p and P.near(p,other.player,P.range) then reply(p,"state",other.packet) end end
        return
    end
    if command=="state" then S.snapshot(p,a,s);return end
    if not alive(p) or not token(p) or not s.packet or not s.packet.equipped or t-(s.seen or 0)>4000 then return end
    if not P.integer(a.event,0,1000000000) or a.event<=s.event then return end
    s.event=a.event
    s.bucketAt=s.bucketAt or t;s.bucket=s.bucket or 0
    if t-s.bucketAt>=1000 then s.bucketAt=t;s.bucket=0 end
    s.bucket=s.bucket+1;if s.bucket>60 then return end
    if command=="step" then S.step(p,a,s);return end
    if command=="grabRequest" then
        local slot=DCF.getStyle(s.packet.style).actions.grab
        local z=slot and slot.enabled and S.validVictim(p,a.zombie,1.3)
        if not z or S.grabs[z] or s.grab or z:isAttacking() or z:isOnFloor() or z:isKnockedDown() then reply(p,"grabDenied",{});return end
        local lease={z=z,player=p,expires=t+8000,useless=z:isUseless(),ignore=z:getIgnoreMovement(),deferred=z:isDeferredMovementEnabled(),target=z:getTarget()}
        S.grabs[z]=lease;s.grab=lease;z:setUseless(true);z:setIgnoreMovement(true);z:setDeferredMovementEnabled(false);z:setAttackOutcome("fail");z:setTarget(nil)
        S.fanout(p,"grabStart",{player=p:getOnlineID(),zombie=z:getOnlineID(),useless=lease.useless,ignore=lease.ignore,deferred=lease.deferred});return
    end
    if command=="grabRelease" then S.release(p);return end
    if command=="throw" then
        local lease=s.grab
        if not lease or lease.z:getOnlineID()~=a.zombie or lease.thrown or not S.validVictim(p,a.zombie,1.5) or s.packet.phase~="throw" then return end
        lease.thrown=true;S.damage(p,lease.z,.7,true,false,s);S.release(p);return
    end
    if command=="guard" then
        local clip=P.clip(s.packet.style,s.packet.clip);local z=S.validVictim(p,a.zombie,1.6,.35)
        if not clip or P.kind(s.packet.style,clip.id)~="block" or not z or (z:getTarget()~=nil and z:getTarget()~=p) or z:getAttackDidDamage() then return end
        z:setAttackOutcome("fail");S.fanout(p,"guard",{player=p:getOnlineID(),zombie=z:getOnlineID()});return
    end
    if command=="counter" then
        local style=DCF.getStyle(s.packet.style);local z=S.validVictim(p,a.zombie,1.6,.35)
        if not style.tigerDrop or not z or z:isOnFloor() or z:isKnockedDown() then return end
        if not s.counterUntil or t>s.counterUntil then
            if t<(s.counterReady or 0) or z:getTarget()~=p or not z:isAttacking() or z:getAttackDidDamage() then return end
            s.counterReady=t+60000;s.counterUntil=t+400;s.counterSeen={};s.counterCount=0
        end
        if s.counterSeen[a.zombie] or s.counterCount>=DCF.MAX_HIT_COUNT then return end
        s.counterSeen[a.zombie]=true;s.counterCount=s.counterCount+1;S.damage(p,z,0,false,true,s);return
    end
    if command=="impact" or command=="extra" then
        if not P.integer(a.swing,1,1000000000) then return end
        local move=P.move(s.packet.style,s.packet.move);if not move then return end
        local job=s.swings[a.swing]
        if command=="extra" and not job then return end
        if not job then
            if a.swing<=(s.lastSwing or 0) then return end
            s.lastSwing=a.swing;job={seen={},count=0,expires=t+2500,move=move,style=s.packet.style};s.swings[a.swing]=job
        end
        if t>job.expires or job.count>=DCF.MAX_HIT_COUNT or job.seen[a.zombie] then return end
        local z=S.validVictim(p,a.zombie,1.65)
        if not z and command=="impact" then
            local evidence=s.evidence and s.evidence[a.zombie]
            if evidence and t-evidence.time<2000 and P.near(p,evidence.z,1.65) and P.path(p,evidence.z:getX(),evidence.z:getY()) then z=evidence.z end
        end
        if not z then return end
        if command=="extra" and ((z:isOnFloor() or z:isKnockedDown())~=(job.move.groundAttack==true)) then return end
        job.seen[a.zombie]=true;job.count=job.count+1
        if command=="impact" then
            S.fanout(p,"impact",{player=p:getOnlineID(),event=a.event,zombie=a.zombie,style=job.style,reaction=job.move.reaction or "",strong=job.move.afterLight~=nil})
        else
            -- Extra victims use server weapon data; primary native hits are never re-applied.
            if not S.baseWeapon then S.baseWeapon=InventoryItemFactory.CreateItem(DCF.TOKEN) end
            local item=S.baseWeapon;local factor=job.move.damageMultiplier or 1
            if not item then return end
            local base=math.max(0,math.min(2,(item:getMinDamage()+item:getMaxDamage())*.5))
            S.damage(p,z,base*factor*(s.packet.extreme and 1.5 or 1),false,false,s)
        end
    end
end
function S.tick()
    local t=now();if t<S.nextTick then return end;S.nextTick=t+100
    local online={};local players=getOnlinePlayers();for i=0,players:size()-1 do online[players:get(i)]=true end
    for id,s in pairs(S.players) do
        local p=s.player
        if s.protection and (t>s.protection.expires or not online[p] or not alive(p)) then
            S.restoreProtection(p,s)
            if s.packet then s.packet.protected=false;S.fanout(p,"state",s.packet) end
        end
        for key,job in pairs(s.swings) do if t>job.expires then s.swings[key]=nil end end
        for key,entry in pairs(s.evidence or {}) do if t-entry.time>2500 then s.evidence[key]=nil end end
        if not online[p] or not alive(p) or t-(s.seen or 0)>5000 then
            S.release(p)
            if s.packet and s.packet.equipped then s.packet.equipped=false;s.packet.clip="";S.fanout(p,"state",s.packet) end
            if not online[p] then S.players[id]=nil end
        elseif s.grab then
            local lease=s.grab;local z=lease.z
            if t>lease.expires or z:isDead() or not P.near(p,z,2) then S.release(p)
            else
                local f=p:getForwardDirection();local x,y=p:getX()+f:getX()*.7,p:getY()+f:getY()*.7
                local sq=getCell():getGridSquare(math.floor(x),math.floor(y),math.floor(p:getZ()))
                if not sq or not P.path(z,x,y) then S.release(p)
                else z:setX(x);z:setY(y);z:setNextX(x);z:setNextY(y);z:setTarget(nil)
                    S.fanout(p,"grabPose",{player=id,zombie=z:getOnlineID(),x=x,y=y,fx=f:getX(),fy=f:getY(),phase=s.packet.phase,
                        moving=s.packet.grabMoving,direction=s.packet.grabDirection,useless=lease.useless,ignore=lease.ignore,deferred=lease.deferred}) end
            end
        end
    end
end
Events.OnClientCommand.Add(S.command)
Events.OnTick.Add(S.tick)
Events.OnWeaponHitCharacter.Add(function(p,z,weapon)
    if S.processing or not p or not instanceof(p,"IsoPlayer") or not z or not instanceof(z,"IsoZombie") or not token(p) then return end
    local s=state(p);s.evidence=s.evidence or {};s.evidence[z:getOnlineID()]={z=z,time=now()}
end)
