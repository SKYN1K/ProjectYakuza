if not isServer() then return end
require "ProjectYakuza/Styles/DragonOfDojima"
require "ProjectYakuza/NetworkProtocol"
require "ProjectYakuza/Juggling"
require "ProjectYakuza/BarrageRules"
require "ProjectYakuza/TauntReactions"
require "ProjectYakuza/SoundVariety"
local ProjectYakuza=ProjectYakuza;local P=ProjectYakuza.NetworkProtocol
local S={players={},grabs={},nextTick=0,reactions={},nextSession=0}
ProjectYakuza.NetworkServer=S
local function now()return getTimestampMs()end
local function alive(p)return p and not p:isDead() and not p:getVehicle() end
local function reply(p,command,args)sendServerCommand(p,P.module,command,args)end
function S.fanout(p,command,args)
    local peer=S.players[p:getOnlineID()]
    if peer and peer.player~=p then return end
    if peer then args.session=peer.session end
    local all=getOnlinePlayers()
    for i=0,all:size()-1 do local other=all:get(i)
        if math.abs(other:getZ()-p:getZ())<2 and (other:getX()-p:getX())^2+(other:getY()-p:getY())^2<=P.range^2 then reply(other,command,args) end
    end
end
local function state(p)
    local id=p:getOnlineID();local s=S.players[id]
    if s and s.player~=p then S.restoreProtection(s.player,s);S.release(s.player)end
    if not s or s.player~=p then S.nextSession=S.nextSession+1;s={player=p,seq=-1,event=-1,swings={},session=S.nextSession};S.players[id]=s end
    return s
end
local function token(p)local item=p:getPrimaryHandItem();return item and (ProjectYakuza.isStyleToken(item) or (ProjectYakuza.Weapons and ProjectYakuza.Weapons.matches(p,item))) and item end
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
function S.extremeMoveAllowed(s,style,move,swing,active)
    if not move or not move.extremeHeat or active then return true end
    local previous=s.packet
    if previous and previous.equipped and previous.style==style.id and previous.move==move.nodeValue and previous.swing==swing then return true end
    if not move.double and previous and previous.equipped and previous.style==style.id and previous.extreme
        and now()-(s.seen or 0)<=250 then return true end
    local first=s.extremeFinisher
    return move.double==true and first~=nil and first.style==style.id and first.branch==move.afterLight and now()<=first.expires
end
function S.snapshot(p,a,s)
    if not P.integer(a.seq,0,1000000000) or a.seq<=s.seq then return end

    local t=now()
    if t-(s.stateBucketAt or 0)>=1000 then s.stateBucketAt=t;s.stateBucket=0 end
    s.stateBucket=(s.stateBucket or 0)+1;if s.stateBucket>80 then return end
    if type(a.style)~="string" or #a.style>100 or (a.style~="none" and not ProjectYakuza.getStyle(a.style)) then return end
    if not P.number(a.heat,0,100) or not P.number(a.fuel,0,100) then return end
    if a.chargePower~=nil and not P.number(a.chargePower,0,1) then return end
    local held=p:getPrimaryHandItem()
    local profile=ProjectYakuza.Weapons and ProjectYakuza.Weapons.profile(a.style,held) or nil
    if a.weaponProfile~=nil and (type(a.weaponProfile)~="string" or a.weaponProfile~=(profile or "")) then return end
    local equipped=a.equipped==true and ProjectYakuza.getStyle(a.style)~=nil and alive(p) and (ProjectYakuza.isStyleToken(held) or profile~=nil)
    local clip=equipped and type(a.clip)=="string" and P.clip(a.style,a.clip) or nil
    local style=ProjectYakuza.getStyle(a.style)
    if profile then style=ProjectYakuza.Weapons.view(style,profile) end
    if equipped and ProjectYakuza.Weapons then
        if a.move~="" and not ProjectYakuza.Weapons.findMove(style,a.move) then return end
        if clip then
            local supported=false
            local actionAnim
            for _,c in ipairs(clip.conditions) do if c.name=="PerformingAction" then actionAnim=c.value end end
            for _,move in ipairs(style.lightAttacks or {}) do if move.animation==clip.animation then supported=true end end
            for _,move in ipairs(style.extremeLightAttacks or {})do if move.animation==clip.animation then supported=true end end
            for _,move in pairs(style.directionalAttacks and style.directionalAttacks.moves or {})do if move.animation==clip.animation then supported=true end end
            for _,move in ipairs(style.groundAttacks or {}) do if move.animation==clip.animation then supported=true end end
            for _,slot in pairs(style.actions) do
                if slot.enabled and slot.animation==(actionAnim or clip.animation) then supported=true end
                if slot.enabled then for _,move in pairs(slot.variants or {}) do if move.enabled~=false and move.animation==(actionAnim or clip.animation) then supported=true end end end
            end
            if not supported then return end
        end
    end
    local kind,activation
    local move=equipped and P.move(a.style,a.move) or nil
    if move and not S.extremeMoveAllowed(s,style,move,a.swing,a.extreme==true and style.heat==true) then return end
    if clip then kind,activation=P.kind(a.style,clip.id) end
    if not equipped or kind~="heatActivation" then S.restoreProtection(p,s);s.wasActivation=false
    elseif not s.wasActivation then
        s.wasActivation=true
        if a.heat>=100/6 and activation then
            s.protection={ghost=p:isGhostMode(),invincible=p:isInvincible(),expires=now()+math.min(3500,(activation.duration or 2)*1000+500)}
            p:setGhostMode(true);p:setInvincible(true)
        end
    end
    local packet={player=p:getOnlineID(),session=s.session,seq=a.seq,style=a.style,weaponProfile=profile or "",equipped=equipped,
        heat=equipped and a.heat or 0,fuel=equipped and a.fuel or 0,extreme=equipped and a.extreme==true and style.heat==true,
        clip=clip and clip.id or "",move=equipped and type(a.move)=="string" and P.move(a.style,a.move) and a.move or "",
        chargePower=equipped and (a.chargePower or 0) or 0,
        swing=P.integer(a.swing,0,1000000000) and a.swing or 0,
        action=P.integer(a.action,0,1000000000) and a.action or 0,
        taunt=equipped and style.actions.taunt and P.integer(a.taunt,0,1000000000) and a.taunt or 0,
        protected=s.protection~=nil,grabMoving=a.grabMoving==true,
        grabDirection=(a.grabDirection=="forward" or a.grabDirection=="backward" or a.grabDirection=="left" or a.grabDirection=="right") and a.grabDirection or "forward",
        linked=a.linked==true,ground=a.ground==true,phase=(a.phase=="enter" or a.phase=="hold" or a.phase=="hit" or a.phase=="throw" or a.phase=="exit") and a.phase or ""}
    local previous=s.packet
    if kind=="barrage" then
        if not move or move~=activation or not ProjectYakuza.BarrageRules.valid(move) or profile or not P.integer(a.action,1,1000000000) then return end
        local lease=s.barrage
        if not lease or lease.action~=a.action then
            if a.action<=(s.lastBarrage or 0) or not (packet.extreme or previous and previous.extreme and previous.equipped and previous.style==packet.style and t-(s.seen or 0)<=250) then return end
            s.lastBarrage=a.action;s.barrage={action=a.action,move=move,weapon=held,style=packet.style,start=t,expires=t+move.duration*1000+800,index=0}
        elseif lease.weapon~=held or lease.move~=move or t>lease.expires then return end
    elseif s.barrage then s.barrage=nil end
    if move and (not previous or previous.move~=packet.move or previous.swing~=packet.swing) then
        if move.extremeHeat and move.afterLight and not move.double then
            s.extremeFinisher={style=style.id,branch=move.afterLight,expires=now()+(move.duration or 2)*1000+style.comboResetMs+500}
        else s.extremeFinisher=nil end
    elseif not equipped then s.extremeFinisher=nil end
    s.seq=a.seq;s.packet=packet;s.seen=now()
    p:getModData().ProjectYakuzaStyle=a.style;p:getModData().ProjectYakuzaHeat=packet.heat
    if not equipped then S.release(p) end
    S.fanout(p,"state",packet)
    S.tauntUpdate(p,packet,s,style,kind,activation,previous)
end
function S.tauntUpdate(p,packet,s,style,kind,action,previous)
    local cfg=packet.equipped and ProjectYakuza.TauntReactions.config(style);local t=now()
    if not cfg then s.tauntLease=nil;return end
    local held=p:getPrimaryHandItem();local lease=s.tauntLease
    if lease and (lease.style~=packet.style or lease.weapon~=held or t>lease.expires)then lease=nil;s.tauntLease=nil end
    if kind=="taunt"and packet.action>0 and packet.action>(s.lastTauntAction or 0)then
        s.lastTauntAction=packet.action
        lease={action=packet.action,style=packet.style,weapon=held,started=t,duration=action.duration*1000,expires=t+action.duration*1000+1000};s.tauntLease=lease
    end
    if previous and packet.taunt>(previous.taunt or 0)then
        s.tauntLease=nil
        if not lease or packet.taunt~=(previous.taunt or 0)+1 or t-lease.started<lease.duration-250 then return end
        local targets=ProjectYakuza.TauntReactions.react(p,style);local ids={};local seen={}
        for _,z in ipairs(targets)do local id=z:getOnlineID();if P.integer(id,-32768,32767)and id~=-1 and not seen[id]then ids[#ids+1]=id;seen[id]=true end end
        if #ids>0 then s.tauntResult=(s.tauntResult or 0)+1;S.fanout(p,"taunt",{player=p:getOnlineID(),event=s.tauntResult,style=packet.style,zombies=ids})end
    elseif lease and packet.clip~=""and kind~="taunt"then s.tauntLease=nil end
end
function S.equip(p,a,s)
    if not alive(p) or not P.integer(a.request,1,1000000000) or type(a.style)~="string"
        or (a.style~="none" and not ProjectYakuza.getStyle(a.style)) then return end
    if a.request<(s.equipRequest or 0) then return end
    if now()<(s.nextEquip or 0) then return end
    s.equipRequest=a.request;s.nextEquip=now()+200
    local item
    local armed=a.weaponProfile and a.weaponProfile~=""
    if armed then
        if not P.integer(a.item,-2147483648,2147483647) then return end
        item=p:getInventory():getItemWithID(a.item)
        if not item or not ProjectYakuza.Weapons or ProjectYakuza.Weapons.profile(a.style,item)~=a.weaponProfile then return end
        p:setPrimaryHandItem(item)
        p:setSecondaryHandItem(item:isTwoHandWeapon() and item or nil)
    elseif a.style~="none" then
        local inventory=p:getInventory();local items=inventory:getItems()
        for i=0,items:size()-1 do
            local candidate=items:get(i)
            if ProjectYakuza.isStyleToken(candidate) then item=candidate;break end
        end
        local created=not item
        if not item then item=inventory:AddItem(ProjectYakuza.TOKEN) end
        if not item then return end
        if ProjectYakuza.StyleItem then ProjectYakuza.StyleItem.clean(item) end
        item:setMaxHitCount(ProjectYakuza.MAX_HIT_COUNT)
        item:setWeaponSprite("ProjectYakuza_EmptyHand");item:setOriginalWeaponSprite("ProjectYakuza_EmptyHand")

        if created or a.item~=item:getID() then sendAddItemToContainer(inventory,item) end
        p:setSecondaryHandItem(nil);p:setPrimaryHandItem(item)
    elseif ProjectYakuza.isStyleToken(p:getPrimaryHandItem()) then p:setPrimaryHandItem(nil) end
    p:getModData().ProjectYakuzaStyle=a.style
    s.extremeFinisher=nil
    if ProjectYakuza.StyleItem then ProjectYakuza.StyleItem.removeUnused(p,not armed and item or nil) end
    sendEquip(p)
    reply(p,"equipReady",{player=p:getOnlineID(),session=s.session,request=a.request,style=a.style,weaponProfile=armed and a.weaponProfile or "",item=item and item:getID() or -1})
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
function S.damage(p,z,amount,knock,kill,s,hitMove,hitStyle,jugglePlan,swing,barrage)
    local item=token(p);if not item then return end
    local dx,dy=z:getX()-p:getX(),z:getY()-p:getY();local n=math.sqrt(dx*dx+dy*dy)
    if n<.001 then return end
    z:setAttackedBy(p);z:getHitDir():set(dx/n,dy/n)
    if kill then z:setAttackOutcome("fail");z:setTarget(nil);z:setHitForce(12);z:setUsePhysicHitReaction(true);z:setHitReaction("ShotBelly");z:Kill(p)
    else S.processing=true;local ok,err=pcall(z.Hit,z,item,p,amount,false,1);S.processing=false
        if not ok then print("[ProjectYakuza] server hit failed: "..tostring(err));return end end
    if knock then z:setKnockedDown(true);z:setFallOnFront(false) end
    s.result=(s.result or 0)+1
    local styleId=hitStyle or s.packet.style
    local move=hitMove or P.move(styleId,s.packet.move)
    local style=ProjectYakuza.getStyle(styleId)
    if ProjectYakuza.Weapons then style=ProjectYakuza.Weapons.view(style,ProjectYakuza.Weapons.profile(styleId,item))end
    local response=not kill and not knock and ProjectYakuza.HitResponses.resolve(style,move)
    local juggle,juggling=ProjectYakuza.Juggling.hit(p,z,not kill and not knock and (jugglePlan or ProjectYakuza.Juggling.plan(style,move)) or nil,swing)
    if response and not juggling then ProjectYakuza.HitResponses.apply(p,z,response) end
    S.fanout(p,"damage",{player=p:getOnlineID(),event=s.result,zombie=z:getOnlineID(),health=math.max(0,z:getHealth()),amount=amount,knock=knock==true,kill=kill==true,
        dx=dx/n,dy=dy/n,force=z:getHitForce(),hitReaction=z:getHitReaction() or "ShotBelly",reaction=move and move.reaction or "",style=styleId,juggle=juggle,responseKind=response and response.kind,responseForce=response and response.force,
        barrage=barrage~=nil,terminal=barrage and barrage.terminal,action=barrage and barrage.action,index=barrage and barrage.index,move=barrage and move.nodeValue})
end
function S.barrageHit(p,a,s)
    local lease=s.barrage;local t=now()
    if not lease or lease.action~=a.action or lease.weapon~=p:getPrimaryHandItem() or lease.style~=s.packet.style or s.packet.move~=lease.move.nodeValue or t>lease.expires then return end
    local move=lease.move;local R=ProjectYakuza.BarrageRules
    if not P.integer(a.index,1,#move.contactFrames) or a.index<=lease.index or type(a.zombies)~="table" or #a.zombies>ProjectYakuza.MAX_HIT_COUNT then return end
    local expected=R.time(move,a.index);local age=t-lease.start
    if age<expected-80 or age>expected+650 then return end
    lease.index=a.index
    if not S.baseWeapon then S.baseWeapon=InventoryItemFactory.CreateItem(ProjectYakuza.TOKEN)end
    if not S.baseWeapon then return end
    local damage=R.damage(move,a.index,(S.baseWeapon:getMinDamage()+S.baseWeapon:getMaxDamage())*.5,s.packet.extreme)
    local seen={};local terminal=a.index==#move.contactFrames
    for _,id in ipairs(a.zombies)do
        if P.integer(id,-32768,32767) and not seen[id]then
            seen[id]=true;local z=S.validVictim(p,id,move.range)
            if z and not z:isOnFloor() and not z:isKnockedDown()then S.damage(p,z,damage,terminal,false,s,move,lease.style,nil,nil,{terminal=terminal,action=a.action,index=a.index})end
        end
    end
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
    if command=="barrage"then S.barrageHit(p,a,s);return end
    if command=="sfx"then
        local style=ProjectYakuza.getStyle(s.packet.style);local profile=ProjectYakuza.Weapons and ProjectYakuza.Weapons.profile(style.id,p:getPrimaryHandItem())or""
        if (profile or"")~=(s.packet.weaponProfile or"")then return end
        if ProjectYakuza.Weapons then style=ProjectYakuza.Weapons.view(style,profile)end
        if not P.number(a.gain,0,1)or not ProjectYakuza.SoundVariety.allowed(style,a.cue,a.index)then return end
        if t-(s.sfxAt or 0)>=1000 then s.sfxAt=t;s.sfxCount=0 end
        s.sfxCount=(s.sfxCount or 0)+1;if s.sfxCount>12 then return end
        S.fanout(p,"sfx",{player=p:getOnlineID(),event=a.event,style=style.id,weaponProfile=profile or"",cue=a.cue,index=a.index,gain=a.gain});return
    end
    if command=="grabRequest" then
        if ProjectYakuza.FEATURES.grab==false then S.release(p);reply(p,"grabDenied",{});return end
        local slot=ProjectYakuza.getStyle(s.packet.style).actions.grab
        local z=slot and slot.enabled and S.validVictim(p,a.zombie,1.3)
        if not z or S.grabs[z] or s.grab or z:isAttacking() or z:isOnFloor() or z:isKnockedDown() then reply(p,"grabDenied",{});return end
        local lease={z=z,player=p,expires=t+8000,useless=z:isUseless(),ignore=z:getIgnoreMovement(),deferred=z:isDeferredMovementEnabled(),target=z:getTarget()}
        S.grabs[z]=lease;s.grab=lease;z:setUseless(true);z:setIgnoreMovement(true);z:setDeferredMovementEnabled(false);z:setAttackOutcome("fail");z:setTarget(nil)
        S.fanout(p,"grabStart",{player=p:getOnlineID(),zombie=z:getOnlineID(),useless=lease.useless,ignore=lease.ignore,deferred=lease.deferred});return
    end
    if command=="grabRelease" then S.release(p);return end
    if command=="throw" then
        if ProjectYakuza.FEATURES.grab==false then S.release(p);return end
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
        local style=ProjectYakuza.getStyle(s.packet.style)
        if ProjectYakuza.Weapons then style=ProjectYakuza.Weapons.view(style,s.packet.weaponProfile) end
        local z=S.validVictim(p,a.zombie,1.6,.35)
        if not style.tigerDrop or not z or z:isOnFloor() or z:isKnockedDown() then return end
        if not s.counterUntil or t>s.counterUntil then
            if not P.number(a.age,0,300) then return end
            if t<(s.counterReady or 0) or z:getTarget()~=p or not z:isAttacking() or z:getAttackDidDamage() then return end
            s.counterReady=t+60000;s.counterUntil=t+400;s.counterSeen={};s.counterCount=0
        end
        if s.counterSeen[a.zombie] or s.counterCount>=ProjectYakuza.MAX_HIT_COUNT then return end
        s.counterSeen[a.zombie]=true;s.counterCount=s.counterCount+1;S.damage(p,z,0,false,true,s);return
    end
    if command=="impact" or command=="extra" then
        if not P.integer(a.swing,1,1000000000) then return end
        local move=P.move(s.packet.style,s.packet.move);if not move then return end
        if move.contactFrames then return end
        local held=token(p);if not held then return end
        local profile=ProjectYakuza.Weapons and ProjectYakuza.Weapons.profile(s.packet.style,held) or ""
        if (profile or "")~=(s.packet.weaponProfile or "") then return end
        local view=ProjectYakuza.Weapons and ProjectYakuza.Weapons.view(ProjectYakuza.getStyle(s.packet.style),profile) or ProjectYakuza.getStyle(s.packet.style)
        if ProjectYakuza.Weapons and not ProjectYakuza.Weapons.findMove(view,s.packet.move) then return end
        local job=s.swings[a.swing]
        if command=="extra" and not job then return end
        if not job then
            if a.swing<=(s.lastSwing or 0) then return end
            if move.chargedHeavy then
                local scaled={};for key,value in pairs(move) do scaled[key]=value end
                scaled.damageMultiplier=ProjectYakuza.ChargeRules.damage(move,s.packet.chargePower)
                scaled.chargePower=s.packet.chargePower
                move=scaled
            end
            s.lastSwing=a.swing;job={seen={},count=0,expires=t+2500,weapon=held,extreme=s.packet.extreme,profile=profile,move=move,style=s.packet.style,juggle=ProjectYakuza.Juggling.plan(view,move)};s.swings[a.swing]=job
        end
        if job.weapon~=held or t>job.expires or job.count>=ProjectYakuza.MAX_HIT_COUNT or job.seen[a.zombie] then return end
        local range=command=="extra" and profile~="" and ProjectYakuza.Weapons and ProjectYakuza.Weapons.hitRange(held) or 1.65
        local z=S.validVictim(p,a.zombie,range)
        if not z and command=="impact" then
            local evidence=s.evidence and s.evidence[a.zombie]
            if evidence and t-evidence.time<2000 and P.near(p,evidence.z,1.65) and P.path(p,evidence.z:getX(),evidence.z:getY()) then z=evidence.z end
        end
        if not z then return end
        if command=="extra" and ((z:isOnFloor() or z:isKnockedDown())~=(job.move.groundAttack==true)) then return end
        job.seen[a.zombie]=true;job.count=job.count+1
        if command=="impact" then
            local response=ProjectYakuza.HitResponses.resolve(view,job.move)
            local packet={player=p:getOnlineID(),event=a.event,zombie=a.zombie,style=job.style,reaction=job.move.reaction or "",strong=job.move.neutralHeavy==true or job.move.afterLight~=nil or job.move.chargedHeavy==true,charged=job.move.chargedHeavy==true,
                responseKind=response and response.kind,responseForce=response and response.force}
            if response or job.juggle or ProjectYakuza.Juggling.get(z) then

                if #S.reactions<128 then S.reactions[#S.reactions+1]={player=p,zombie=z,response=response,packet=packet,at=t,juggle=job.juggle,swing=a.swing}
                else packet.responseKind=nil;packet.responseForce=nil;S.fanout(p,"impact",packet) end
            else S.fanout(p,"impact",packet) end
        else

            if not S.baseWeapon then S.baseWeapon=InventoryItemFactory.CreateItem(ProjectYakuza.TOKEN) end
            local item=job.profile and job.profile~="" and job.weapon or S.baseWeapon;local factor=job.move.damageMultiplier or 1
            if not item then return end
            local cap=job.profile and job.profile~="" and 20 or 2
            local base=math.max(0,math.min(cap,(item:getMinDamage()+item:getMaxDamage())*.5))
            S.damage(p,z,base*factor*(job.extreme and 1.5 or 1),false,false,s,job.move,job.style,job.juggle,a.swing)
        end
    end
end
function S.tick()
    local t=now();if t<S.nextTick then return end;S.nextTick=t+100
    local reactions=S.reactions;S.reactions={}
    for _,job in ipairs(reactions) do
        local z=job.zombie
        if t-job.at<=1000 and alive(job.player) and P.near(job.player,z,2.5) then
            local juggle,juggling=ProjectYakuza.Juggling.hit(job.player,z,job.juggle,job.swing)
            job.packet.juggle=juggle
            if not juggling then ProjectYakuza.HitResponses.apply(job.player,z,job.response) end
            S.fanout(job.player,"impact",job.packet)
        end
    end
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

ProjectYakuza.on("juggleEnded",function(p,z,a)
    if not a.fromHit and p and z then S.fanout(p,"juggle",{player=p:getOnlineID(),zombie=z:getOnlineID(),event=a.seq,juggle=a}) end
end)
