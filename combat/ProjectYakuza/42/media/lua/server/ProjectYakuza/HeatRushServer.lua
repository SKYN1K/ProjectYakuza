require "ProjectYakuza/NetworkServer"
require "ProjectYakuza/HeatRushRules"
require "ProjectYakuza/HeatActions"
local PY=ProjectYakuza;local R=PY.HeatRushRules;local P=PY.NetworkProtocol;local S=PY.NetworkServer
local H={leases={},held=setmetatable({}, {__mode="k"}),serial=0};PY.HeatRushServer=H
local function now()return getTimestampMs()end
function H.reply(p,command,a)a.player=p:getOnlineID();sendServerCommand(p,P.module,command,a)end
function H.finish(p,completed)
    local job=H.leases[p];if not job then return end
    H.leases[p]=nil;if H.held[job.z]==job then H.held[job.z]=nil end;local z=job.z
    if job.started then PY.HeatActions.finish(p,job);if not job.victimRestored then R.restore(z,job.old);job.victimRestored=true end end
    if completed and not job.failed and job.pendingDamage and not z:isDead()and (R.targetKind(z)~="player"or R.playerAllowed(p,z))then
        local state=S.players[p:getOnlineID()]
        if state and state.packet then
            if R.targetKind(z)=="player"then S.processing=true;local ok,err=pcall(z.Hit,z,job.weapon,p,job.pendingDamage,false,1);S.processing=false;if not ok then print("[ProjectYakuza] deferred paired hit failed: "..tostring(err))end
            else S.damage(p,z,job.pendingDamage,false,false,state,job.move,job.style,nil,nil,true)end
        end
    end
    if completed and not job.failed and job.hits[#job.contacts]and not z:isDead()then z:setKnockedDown(true);z:setFallOnFront(false)end
    S.fanout(p,"heatRushEnd",{player=p:getOnlineID(),action=job.action,zombie=z:getOnlineID(),targetKind=R.targetKind(z),useless=job.old.useless,ignore=job.old.ignore,deferred=job.old.deferred,completed=completed==true})
end
function H.abort(job,index)
    if job.failed or not job.move.qteFailure then return end
    job.failed=true;job.failedIndex=index;job.failedAt=now();job.pendingDamage=nil;job.expires=job.failedAt+job.move.qteFailure.duration*1000+1000
    if H.held[job.z]==job then H.held[job.z]=nil end
    if not job.victimRestored then R.restore(job.z,job.old);job.victimRestored=true end
    S.fanout(job.p,"heatRushFailed",{player=job.p:getOnlineID(),action=job.action,index=index})
end
function H.results(job,age,requested)
    local definition=job.definition;if not definition or not definition.failureLimit then return end
    job.resultIndex=job.resultIndex or 1
    while definition.prompts[job.resultIndex]do
        local index=job.resultIndex;local prompt=definition.prompts[index]
        if age*1000<prompt.atMs+(requested and index<=requested and -100 or job.presses[index]and 0 or 180)then return end
        job.resultIndex=index+1
        if job.presses[index]then job.consecutiveFailures=0
        else job.failures=(job.failures or 0)+1;job.consecutiveFailures=(job.consecutiveFailures or 0)+1 end
        local count=definition.failureMode=="total"and (job.failures or 0)or(job.consecutiveFailures or 0)
        if count>=definition.failureLimit then H.abort(job,index);return end
    end
end
function H.input(s,packet,style,move)
    if not packet.equipped or not packet.extreme or packet.weaponProfile~=""or not style or not style.heatRush then s.rushCount=0;s.rushInputSwing=nil;return end
    if packet.swing==0 or packet.swing==s.rushInputSwing then return end
    local count=now()-(s.rushAt or 0)<=1200 and (s.rushCount or 0)or 0
    local expected=style.extremeLightAttacks and style.extremeLightAttacks[count+1]
    if move and move.extremeHeat and expected and expected.nodeValue==move.nodeValue then count=count+1
    else count=move and style.extremeLightAttacks[1].nodeValue==move.nodeValue and 1 or 0 end
    s.rushCount=count;s.rushAt=now();s.rushInputSwing=packet.swing;s.rushVictim=nil;s.rushTargetKind=nil
end
function H.record(p,s,job,z,swing)
    local style=PY.getStyle(job.style)
    if not style or not style.heatRush or not job.extreme or job.profile and job.profile~=""or not job.move.extremeHeat
        or s.rushCount~=style.heatRush.hits or s.rushInputSwing~=swing then return end
    s.rushVictim=R.validTarget(p,z)and z:getOnlineID()or nil;s.rushTargetKind=R.targetKind(z);s.rushAt=now()
end
function H.command(p,command,a,s)
    local job=H.leases[p];local t=now()
    if command=="heatRushPlayerHit"then
        local z=P.integer(a.zombie,0,32767)and getPlayerByOnlineID(a.zombie)
        local move=P.move(s.packet.style,s.packet.move)
        if z and P.integer(a.swing,1,1000000000)and move and P.near(p,z,2)and P.path(p,z:getX(),z:getY())and R.playerAllowed(p,z)then
            H.record(p,s,{style=s.packet.style,move=move,extreme=s.packet.extreme,profile=s.packet.weaponProfile},z,a.swing)
        end
        return
    end
    if command=="heatRushBegin"then
        local style=PY.getStyle(s.packet.style)
        if a.weaponHeat==true and style then style=PY.Weapons.view(style,s.packet.weaponProfile)end
        local cfg=style and style.heatRush;local move=style and style.actions.heatAction
        local weaponHeat=a.weaponHeat==true;local z=style and R.target(p,a.zombie,a.targetKind)
        local ready
        if weaponHeat then
            local cost=move and (move.heatStocks or 0)*PY.HeatRules.stockSize(style)or 0
            local available=move and move.useExtremeFuel and s.packet.extreme and s.packet.fuel or s.packet.heat
            ready=s.packet.rightAim==true and s.packet.comboBusy==false and R.weaponAllowed(p,style,move)and available>=cost
        else ready=cfg and s.packet.extreme and s.packet.weaponProfile==""and (s.rushCount or 0)>=cfg.hits and s.rushVictim==a.zombie and (a.targetKind or"zombie")== (s.rushTargetKind or"zombie")and t-(s.rushAt or 0)<=1200 end
        if not P.integer(a.request,1,1000000000)or job or not s.packet.equipped or not ready or H.held[p]or H.held[z]or H.leases[z]or not R.validTarget(p,z)then H.reply(p,"heatRushDenied",{request=a.request});return end
        local f=p:getForwardDirection();local pose={x=p:getX(),y=p:getY(),fx=f:getX(),fy=f:getY(),motion=R.motion(move),duration=R.durationFor(move)}
        if not P.path(p,z:getX(),z:getY())or not R.space(p,pose)then H.reply(p,"heatRushDenied",{request=a.request});return end
        H.serial=H.serial+1;pose.action=H.serial;pose.p=p;pose.z=z;pose.weapon=p:getPrimaryHandItem();pose.style=style.id;pose.expires=t+7000;pose.presses={};pose.hits={};pose.move=move;pose.definition=move.qte;pose.contacts=R.contacts(move);pose.old=R.capture(z)
        H.leases[p]=pose;H.held[z]=pose;s.rushCount=0
        H.reply(p,"heatRushGranted",{request=a.request,action=pose.action,zombie=z:getOnlineID(),targetKind=R.targetKind(z),x=pose.x,y=pose.y,fx=pose.fx,fy=pose.fy});return
    end
    if not job or job.action~=a.action then return end
    if job.weapon~=p:getPrimaryHandItem()or job.style~=s.packet.style or t>job.expires then H.finish(p,false);return end
    if command=="heatRushReady"then
        if job.started then return end;job.started=t;job.expires=t+job.duration*1000+1000
        job.old=R.lock(job.z,job.move.targetAnimation);PY.HeatActions.begin(p,job,job.move)
        S.fanout(p,"heatRushPose",{player=p:getOnlineID(),action=job.action,zombie=job.z:getOnlineID(),targetKind=R.targetKind(job.z),x=job.x,y=job.y,fx=job.fx,fy=job.fy,motionId=job.move.motionId,age=0});return
    end
    if command=="heatRushEnd"then H.finish(p,not job.failed and a.completed==true and job.started and t-job.started>=job.duration*1000-150);return end
    if job.failed then return end
    if not job.started then return end
    local age=(t-job.started)/1000
    if command=="heatRushFail"then
        if job.definition and P.integer(a.index,1,#job.definition.prompts)and not job.presses[a.index]then H.results(job,age,a.index)end
        return
    end
    H.results(job,age)
    if job.failed then return end
    if command=="heatRushPress"then
        if job.definition and P.integer(a.index,1,#job.definition.prompts)and not job.presses[a.index]and PY.QTE.window(job.definition,a.index,age*1000,100,120)then job.presses[a.index]=true end;return
    end
    if not P.integer(a.index,1,#job.contacts)then return end
    local entry=job.contacts[a.index];local contact=entry.atMs/1000
    local prompt=entry.qteIndex or not job.move.contacts and job.definition and a.index
    if command=="heatRushHit"then
        if prompt and not job.presses[prompt]or job.hits[a.index]or age<contact-.1 or age>contact+.65 or job.z:isDead()or R.targetKind(job.z)=="player"and not R.playerAllowed(p,job.z)or not P.near(p,job.z,2)or not P.path(p,job.z:getX(),job.z:getY())then return end
        job.hits[a.index]=true
        local amount=R.amount(job.move,a.index,job.weapon,job.hits);if not amount then return end
        if amount>0 then
        if job.move.deferFinalDamage then job.pendingDamage=amount
        elseif R.targetKind(job.z)=="player"then
            S.processing=true;local ok,err=pcall(job.z.Hit,job.z,job.weapon,p,amount,false,1);S.processing=false
            if not ok then print("[ProjectYakuza] paired player hit failed: "..tostring(err));H.finish(p,false);return end
        else S.damage(p,job.z,amount,false,false,s,job.move,job.style)end
        end
        S.fanout(p,"heatRushContact",{player=p:getOnlineID(),action=job.action,index=a.index,zombie=job.z:getOnlineID(),targetKind=R.targetKind(job.z),cue=entry.cue,presentation=job.move.deferFinalDamage==true or amount==0 or R.targetKind(job.z)=="player",strong=entry.strong~=false})
    end
end
function H.tick(t,online)
    for p,job in pairs(H.leases)do
        local z=job.z;local peer=S.players[p:getOnlineID()]
        if not online[p]or p:isDead()or not job.failed and z:isDead()and not job.hits[#job.contacts]or t>job.expires or not peer or not peer.packet or not peer.packet.equipped or peer.packet.style~=job.style or p:getPrimaryHandItem()~=job.weapon or not job.failed and R.targetKind(z)=="player"and not R.playerAllowed(p,z)or (p:getHitReaction()or"")~=""then H.finish(p,false)
        elseif job.started then
            local sourceAge=(t-job.started)/1000
            if not job.failed then H.results(job,sourceAge)end
            if job.failed then
                S.fanout(p,"heatRushFailed",{player=p:getOnlineID(),action=job.action,index=job.failedIndex})
                if t-job.failedAt>=job.move.qteFailure.duration*1000+150 then H.finish(p,false)end
            else
            local age=math.min(job.duration,(t-job.started)/1000);local x,y=R.point(job,job.motion.victim,age)
            if not z:isDead()and (not P.near(p,z,3)or not P.path(z,x,y))then H.finish(p,false)
            else if not z:isDead()then z:setX(x);z:setY(y);z:setNextX(x);z:setNextY(y);R.hold(z)end
                S.fanout(p,"heatRushPose",{player=p:getOnlineID(),action=job.action,zombie=z:getOnlineID(),targetKind=R.targetKind(z),x=job.x,y=job.y,fx=job.fx,fy=job.fy,motionId=job.move.motionId,age=age})end
            end
        end
    end
end
Events.OnSave.Add(function()local players={};for p in pairs(H.leases)do players[#players+1]=p end;for _,p in ipairs(players)do H.finish(p,false)end end)
