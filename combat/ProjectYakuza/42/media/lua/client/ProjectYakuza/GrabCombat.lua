require "ProjectYakuza/HeatRush"
require "ProjectYakuza/GrabRules"
local PY=ProjectYakuza;local R=PY.GrabRules
local G={pending=setmetatable({}, {__mode="k"}),previews=setmetatable({}, {__mode="k"})};PY.GrabCombat=G
local function now()return getTimestampMs()end
function G.candidate(p,force)
    if not p then return end
    local c=p and PY.activeActions[p];local a=c and c.kind=="grab"and c.timedAction
    local style=p and PY.getPlayerStyle(p);local move=style and style.actions.grabHeat
    if not isMouseButtonDown(1)or not a or not a.started or a.cleaned or a.phaseName~="hold"or not a.paired or not move or not move.enabled or not PY.Defense.safe(p)or not PY.HeatRules.canAfford(PY.actionHeat(p,move),(move.heatStocks or 0)*PY.Heat.stockSize(p))then G.previews[p]=nil;return end
    local previous=G.previews[p]
    if not force and previous and previous.a==a and now()<previous.next then if previous.pose then return c.target,move,previous.pose end;return end
    local pose=R.wall(p,c.target,move);G.previews[p]={a=a,pose=pose,next=now()+200}
    if pose then return c.target,move,pose end
end
function G.present(p,z)
    local move={contacts={{cue="punchImpact",voice="CombatLightAttack",strong=false}}}
    PY.HeatRush.present(p,z,move,1,true)
    if not p:isLocalPlayer()and PY.Feedback then PY.Feedback.play(p,PY.Feedback.sound(p,"punchImpact"),.55)end
end
function G.hit(a)
    local p,z=a.character,a.context.target;local move=a.strikeMove
    if not move or a.cleaned or z:isDead()then return end
    if isClient()then PY.Network.send(p,"grabStrikeHit",{zombie=z:getOnlineID(),serial=a.grabStrikeCount,grabId=a.grabId});G.present(p,z)
    else
        local amount=R.damage(p,move);local ok=amount~=nil
        if amount and amount>0 then ok=PY.HitResponses.nativeHit(p,z,p:getPrimaryHandItem(),amount,{noKnockback=true,hitResponse=false})end
        if ok then PY.Heat.onHit(p,z,amount,{active=true});G.present(p,z)end
    end
    R.retainAfterHit(z)
end
function G.input(p,a,lightPressed,heatPressed)
    if a.phaseName~="hold"or not a.paired then return false end
    if heatPressed then
        local z,move,pose=G.candidate(p,true)
        if z then
            PY.HeatRush.requestSerial=(PY.HeatRush.requestSerial or 0)+1
            G.serial=PY.HeatRush.requestSerial
            local job={z=z,move=move,pose=pose,request=G.serial,expires=now()+1500,fromGrab=true}
            G.pending[p]=job
            if isClient()then PY.Network.capture(p,true);PY.Network.send(p,"heatRushBegin",{request=job.request,zombie=z:getOnlineID(),targetKind="zombie",grabHeat=true})end
            return true
        end
    end
    if not lightPressed then return false end
    local moves=a.context.action.strikes;if not moves or #moves==0 then return false end
    if p:getStats():get(CharacterStat.ENDURANCE)<.08 then return true end
    local serial=(a.grabStrikeCount or 0)+1;local index=(serial-1)%#moves+1
    a.grabStrikeCount=serial;a.strikeMove=moves[index];a.strikeImpacted=false;a.strikeSeen=false
    p:getStats():remove(CharacterStat.ENDURANCE,.012);a:phase("strike"..index)
    PY.emit("attackCommitted",p,a.context.style,a.strikeMove,a.context,"light")
    if isClient()then PY.Network.capture(p,true);PY.Network.send(p,"grabStrike",{zombie=a.context.target:getOnlineID(),serial=serial,index=index,grabId=a.grabId})end
    return true
end
function G.updatePending(p)
    local job=G.pending[p];if not job then return false end
    if isGamePaused()then return true end
    if not isMouseButtonDown(1)or not PY.Defense.safe(p)or job.z:isDead()or now()>job.expires then
        if job.granted and PY.Network then PY.Network.send(p,"heatRushEnd",{action=job.granted.action})end
        G.pending[p]=nil;return false
    end
    if isClient()and not job.granted then return true end
    if not job.released then
        local c=PY.activeActions[p]
        if c and c.kind=="grab"then PY.cancelAction(p,"grab_heat_handoff")elseif c then if job.granted and PY.Network then PY.Network.send(p,"heatRushEnd",{action=job.granted.action})end;G.pending[p]=nil;return false end
        job.released=true
    end
    local ok,reason=PY.requestAction(p,"grabHeat",nil,job)
    if ok then G.pending[p]=nil;return true end
    if reason=="busy"or reason=="native_attack_busy"then return true end
    if job.granted and PY.Network then PY.Network.send(p,"heatRushEnd",{action=job.granted.action})end
    G.pending[p]=nil;return false
end
function G.receive(command,p,packet)
    local job=G.pending[p]
    if not p:isLocalPlayer()or not job then return false end
    if command=="heatRushEnd"and job.granted and packet.action==job.granted.action then G.pending[p]=nil;return true end
    if packet.request~=job.request then return false end
    if command=="heatRushDenied"then G.pending[p]=nil;return true end
    if command~="heatRushGranted"then return false end
    local P=PY.NetworkProtocol
    if packet.grabHeat~=true then return false end
    if packet.zombie~=job.z:getOnlineID()or not P.integer(packet.action,1,1000000000)or not P.number(packet.x,p:getX()-1.5,p:getX()+1.5)or not P.number(packet.y,p:getY()-1.5,p:getY()+1.5)or not P.number(packet.fx,-1,1)or not P.number(packet.fy,-1,1)then G.pending[p]=nil;return true end
    job.granted=packet;job.expires=now()+1500;return true
end
function G.clear()
    for p,job in pairs(G.pending)do if job.granted and PY.Network then PY.Network.send(p,"heatRushEnd",{action=job.granted.action})end end
    G.pending=setmetatable({}, {__mode="k"});G.previews=setmetatable({}, {__mode="k"})
end
Events.OnSave.Add(G.clear);Events.OnMainMenuEnter.Add(G.clear)
