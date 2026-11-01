require "ProjectYakuza/NetworkServer"
require "ProjectYakuza/HeatRushRules"
local PY=ProjectYakuza;local R=PY.HeatRushRules;local P=PY.NetworkProtocol;local S=PY.NetworkServer
local H={leases={},held=setmetatable({}, {__mode="k"}),serial=0};PY.HeatRushServer=H
local function now()return getTimestampMs()end
function H.reply(p,command,a)a.player=p:getOnlineID();sendServerCommand(p,P.module,command,a)end
function H.finish(p,completed)
    local job=H.leases[p];if not job then return end
    H.leases[p]=nil;H.held[job.z]=nil;local z=job.z
    z:setVariable("ProjectYakuzaHeatRushVictim",false);z:setUseless(job.useless);z:setIgnoreMovement(job.ignore);z:setDeferredMovementEnabled(job.deferred)
    if z:getHitReaction()=="ProjectYakuzaHeatRushVictim"then z:setHitReaction("");z:reportEvent("ActiveAnimFinishing")end
    if not z:isDead()and z:getTarget()==nil then z:setTarget(job.target)end
    if completed and job.hits[#job.definition.prompts]and not z:isDead()then z:setKnockedDown(true);z:setFallOnFront(false)end
    S.fanout(p,"heatRushEnd",{player=p:getOnlineID(),action=job.action,zombie=z:getOnlineID(),useless=job.useless,ignore=job.ignore,deferred=job.deferred,completed=completed==true})
end
function H.record(s,job,z,swing)
    if not job.extreme or job.profile and job.profile~=""or not job.move.extremeHeat or job.move.afterLight or job.move.nodeValue=="dd_heat_rush"then return end
    local style=PY.getStyle(job.style);if not style or not style.heatRush then return end
    local t=now();if s.rushSwing==swing then
        if s.rushCount>=style.heatRush.hits and not s.rushVictim and R.validTarget(p,z)then s.rushVictim=z:getOnlineID()end
        return
    end
    local count=t-(s.rushAt or 0)<1200 and (s.rushCount or 0)or 0
    local expected=style.extremeLightAttacks and style.extremeLightAttacks[count+1]
    if expected and expected.nodeValue==job.move.nodeValue then count=count+1
    else count=style.extremeLightAttacks[1].nodeValue==job.move.nodeValue and 1 or 0 end
    s.rushCount=count;s.rushAt=t;s.rushSwing=swing;s.rushVictim=R.validTarget(p,z)and z:getOnlineID()or nil
end
function H.command(p,command,a,s)
    local job=H.leases[p];local t=now()
    if command=="heatRushBegin"then
        local style=PY.getStyle(s.packet.style);local cfg=style and style.heatRush;local z=cfg and P.zombie(p,a.zombie)
        if not P.integer(a.request,1,1000000000)or job or not cfg or not s.packet.extreme or s.packet.weaponProfile~=""or (s.rushCount or 0)<cfg.hits or s.rushVictim~=a.zombie or t-(s.rushAt or 0)>1200 or H.held[z]or not R.validTarget(p,z)then H.reply(p,"heatRushDenied",{request=a.request});return end
        local f=p:getForwardDirection();local pose={x=p:getX(),y=p:getY(),fx=f:getX(),fy=f:getY()}
        if not P.path(p,z:getX(),z:getY())or not R.space(p,pose)then H.reply(p,"heatRushDenied",{request=a.request});return end
        H.serial=H.serial+1;pose.action=H.serial;pose.p=p;pose.z=z;pose.weapon=p:getPrimaryHandItem();pose.style=style.id;pose.expires=t+7000;pose.presses={};pose.hits={};pose.definition=style.actions.heatAction.qte;pose.useless=z:isUseless();pose.ignore=z:getIgnoreMovement();pose.deferred=z:isDeferredMovementEnabled();pose.target=z:getTarget()
        H.leases[p]=pose;H.held[z]=pose;s.rushCount=0
        H.reply(p,"heatRushGranted",{request=a.request,action=pose.action,zombie=z:getOnlineID(),x=pose.x,y=pose.y,fx=pose.fx,fy=pose.fy});return
    end
    if not job or job.action~=a.action then return end
    if job.weapon~=p:getPrimaryHandItem()or job.style~=s.packet.style or t>job.expires then H.finish(p,false);return end
    if command=="heatRushReady"then
        if job.started then return end;job.started=t;job.expires=t+R.duration*1000+1000
        job.z:setTarget(nil);job.z:setUseless(true);job.z:setIgnoreMovement(true);job.z:setDeferredMovementEnabled(false);job.z:setVariable("ProjectYakuzaHeatRushVictim",true);job.z:setHitReaction("ProjectYakuzaHeatRushVictim");job.z:reportEvent("wasHit")
        S.fanout(p,"heatRushPose",{player=p:getOnlineID(),action=job.action,zombie=job.z:getOnlineID(),x=job.x,y=job.y,fx=job.fx,fy=job.fy,age=0});return
    end
    if command=="heatRushEnd"then H.finish(p,a.completed==true and job.started and t-job.started>=R.duration*1000-150);return end
    if not job.started or not P.integer(a.index,1,#job.definition.prompts)then return end
    local age=(t-job.started)/1000;local contact=job.definition.prompts[a.index].atMs/1000
    if command=="heatRushPress"then
        if not job.presses[a.index]and PY.QTE.window(job.definition,a.index,age*1000,100,120) then job.presses[a.index]=true end;return
    end
    if command=="heatRushHit"then
        if not job.presses[a.index]or job.hits[a.index]or age<contact-.1 or age>contact+.65 or job.z:isDead()or not P.near(p,job.z,2)or not P.path(p,job.z:getX(),job.z:getY())then return end
        job.hits[a.index]=true
        local amount=R.amount(PY.getStyle(job.style).actions.heatAction,a.index);if not amount then return end
        S.damage(p,job.z,amount,false,false,s,PY.getStyle(job.style).actions.heatAction,job.style)
        S.fanout(p,"heatRushContact",{player=p:getOnlineID(),action=job.action,index=a.index,zombie=job.z:getOnlineID()})
    end
end
function H.tick(t,online)
    for p,job in pairs(H.leases)do
        local z=job.z;local peer=S.players[p:getOnlineID()]
        if not online[p]or p:isDead()or z:isDead()or t>job.expires or not peer or not peer.packet or not peer.packet.equipped or peer.packet.style~=job.style or p:getPrimaryHandItem()~=job.weapon or (p:getHitReaction()or"")~=""then H.finish(p,false)
        elseif job.started then
            local age=math.min(R.duration,(t-job.started)/1000);local x,y=R.point(job,PY.HeatRushPaths.victim,age)
            if not P.near(p,z,3)or not P.path(z,x,y)then H.finish(p,false)
            else z:setX(x);z:setY(y);z:setNextX(x);z:setNextY(y);z:setTarget(nil)
                S.fanout(p,"heatRushPose",{player=p:getOnlineID(),action=job.action,zombie=z:getOnlineID(),x=job.x,y=job.y,fx=job.fx,fy=job.fy,age=age})end
        end
    end
end
Events.OnSave.Add(function()local players={};for p in pairs(H.leases)do players[#players+1]=p end;for _,p in ipairs(players)do H.finish(p,false)end end)
