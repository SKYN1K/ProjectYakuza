require "ProjectYakuza/Registry"
require "ProjectYakuza/HeatRushPaths"
require "ProjectYakuza/KatanaHeatPaths"
require "ProjectYakuza/BottleHeatPaths"
local R={duration=224/30,targetRange=2}
ProjectYakuza.HeatRushRules=R
function R.motion(action)
    return action and action.motionId and ProjectYakuza.PairedMotions[action.motionId] or ProjectYakuza.HeatRushPaths
end
function R.durationFor(action)return action and action.duration or R.duration end
function R.contacts(action)return action.contacts or action.qte and action.qte.prompts or {}end
function R.promptContact(action,index)
    if not action.contacts then return index end
    for i,contact in ipairs(action.contacts)do if contact.qteIndex==index then return i end end
end
function R.noCombo(s,style,time)
    if s.active or s.starting or (s.queued or 0)>0 or s.finisherMove or s.pendingFinisher or s.groundMove or s.directionalLight or s.queuedFinisher or s.queuedDouble or s.queuedWeaponHeavy then return false end
    local ended=s.finisherFinishedAt or s.finishedAt
    return (s.step or 0)==0 and not s.finisherBranch or ended~=nil and time-ended>style.comboResetMs
end
function R.weaponAllowed(p,style,action)
    local held=p:getPrimaryHandItem()
    if not action or not action.weaponHeat or not held or not ProjectYakuza.Weapons.profile(style.id,held)then return false end
    for _,id in ipairs(action.weaponItems or {})do if held:getFullType()==id then return true end end
    return false
end
function R.sample(path,time)
    local f=math.max(0,math.min(#path-1,time*30));local i=math.floor(f)+1;local a=path[i];local b=path[math.min(i+1,#path)];local t=f-math.floor(f)
    return a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t
end
function R.point(job,path,time)
    local forward,right=R.sample(path,time)
    return job.x+job.fx*forward+job.fy*right,job.y+job.fy*forward-job.fx*right
end
function R.targetKind(z)
    if z and instanceof(z,"IsoZombie")then return "zombie"end
    if z and instanceof(z,"IsoPlayer")then return "player"end
end
function R.playerAllowed(p,z)
    if p==z or z:isGodMod()or z:isInvincible()or z:isGhostMode()then return false end
    if isClient()or isServer and isServer()then
        if not getServerOptions or not NonPvpZone or not Faction then return false end
        local options=getServerOptions()
        if not options:getBoolean("PVP")then return false end
        if options:getBoolean("SafetySystem")and p:getSafety():isEnabled()and z:getSafety():isEnabled()then return false end
        if NonPvpZone.getNonPvpZone(math.floor(p:getX()),math.floor(p:getY()))or NonPvpZone.getNonPvpZone(math.floor(z:getX()),math.floor(z:getY()))then return false end
        local faction=Faction.getPlayerFaction(p)
        if faction and faction==Faction.getPlayerFaction(z)and not p:isFactionPvp()and not z:isFactionPvp()then return false end
        return true
    end
    return IsoPlayer and IsoPlayer.getCoopPVP()or false
end
function R.target(p,id,kind)
    if kind=="player"then return getPlayerByOnlineID(id)end
    return ProjectYakuza.NetworkProtocol.zombie(p,id)
end
function R.validTarget(p,z,range)
    local kind=R.targetKind(z)
    if not p or not kind or z:isDead()or z:isOnFloor()or z:isKnockedDown()or math.abs(z:getZ()-p:getZ())>.25 then return false end
    if kind=="zombie"then
        if z:isUseless()and not ProjectYakuza.HitResponses.stuns[z]then return false end
    elseif not R.playerAllowed(p,z)or z:getVehicle()or z:isClimbing()then return false end
    local dx,dy=z:getX()-p:getX(),z:getY()-p:getY();local n=math.sqrt(dx*dx+dy*dy);local f=p:getForwardDirection()
    return n>.01 and n<=(range or R.targetRange)and (dx*f:getX()+dy*f:getY())/n>=.5
end
function R.capture(z)
    local old={ignore=z:getIgnoreMovement(),deferred=z:isDeferredMovementEnabled()}
    if R.targetKind(z)=="zombie"then old.useless=z:isUseless();old.target=z:getTarget()
    else old.block=z:isBlockMovement();local gate=ProjectYakuza.Bindings and ProjectYakuza.Bindings.attackGates[z];old.authorize=gate and gate.allowed;if old.authorize==nil then old.authorize=z:isAuthorizeMeleeAction()end;old.performing=z:GetVariable("PerformingAction")or"";old.action=z:GetVariable("IsPerformingAnAction")=="true"end
    return old
end
function R.hold(z)
    z:setIgnoreMovement(true);z:setDeferredMovementEnabled(false)
    if R.targetKind(z)=="zombie"then z:setTarget(nil);z:setUseless(true);z:setAttackOutcome("fail")
    else z:setBlockMovement(true);z:setAuthorizeMeleeAction(false)end
end
function R.lock(z,clip)
    if ProjectYakuza.Reactions then ProjectYakuza.Reactions.clear(z)end
    ProjectYakuza.HitResponses.releaseStun(z)
    local old=R.capture(z)
    if R.targetKind(z)=="player"and z:isLocalPlayer()and ProjectYakuza.isEquipped(z)then ProjectYakuza.resetPlayer(z,"heat_rush_victim")end
    R.hold(z);z:setVariable("ProjectYakuzaPairedVictimClip",clip or "ProjectYakuza_DD_HeatRushVictim");z:setVariable("ProjectYakuzaHeatRushVictim",true)
    if R.targetKind(z)=="player"then z:setVariable("PerformingAction","ProjectYakuzaHeatRushVictim");z:setVariable("IsPerformingAnAction",true)end
    z:setHitReaction("ProjectYakuzaHeatRushVictim");z:reportEvent("wasHit")
    return old
end
function R.restore(z,old)
    z:setVariable("ProjectYakuzaPairedVictimClip","");z:setVariable("ProjectYakuzaHeatRushVictim",false);z:setIgnoreMovement(old.ignore==true);z:setDeferredMovementEnabled(old.deferred~=false)
    if R.targetKind(z)=="zombie"then
        z:setUseless(old.useless==true)
        if not z:isDead()and z:getTarget()==nil then z:setTarget(old.target)end
    else
        if ProjectYakuza.Bindings then ProjectYakuza.Bindings.restore(z)end
        z:setBlockMovement(old.block==true);z:setAuthorizeMeleeAction(old.authorize~=false)
        if z:GetVariable("PerformingAction")=="ProjectYakuzaHeatRushVictim"then z:setVariable("PerformingAction",old.performing or"");z:setVariable("IsPerformingAnAction",old.action==true)end
    end
    if z:getHitReaction()=="ProjectYakuzaHeatRushVictim"then z:setHitReaction("");z:reportEvent("ActiveAnimFinishing")end
end
function R.space(p,job)
    local P=ProjectYakuza.NetworkProtocol;local paths=job.motion or ProjectYakuza.HeatRushPaths
    for _,path in ipairs({paths.actor,paths.victim})do
        for i=1,#path,8 do local x,y=R.point(job,path,(i-1)/30);if not P.path(p,x,y)then return false end end
        local x,y=R.point(job,path,job.duration or R.duration);if not P.path(p,x,y)then return false end
    end
    return true
end
function R.amount(action,index,held,success)
    local prompt=R.contacts(action)[index];if not prompt then return end
    local multiplier=prompt.damageMultiplier or 1
    if prompt.sumQTE then
        multiplier=0
        for i,v in ipairs(action.qte.prompts)do if success and success[R.promptContact(action,i)]then multiplier=multiplier+(v.damageMultiplier or 1)end end
    end
    if action.weaponHeat then
        if not held then return end
        local data=held:getModData()
        local low=data.ProjectYakuzaHeatOriginalMin or held:getMinDamage()
        local high=data.ProjectYakuzaHeatOriginalMax or held:getMaxDamage()
        return math.max(0,math.min(20,(low+high)*.5))*multiplier
    end
    if not R.base then R.base=instanceItem(ProjectYakuza.TOKEN)end
    if not R.base then return end
    return math.max(0,math.min(2,(R.base:getMinDamage()+R.base:getMaxDamage())*.5))*multiplier*1.5
end
