local loaded={}
require=function(name)
    if loaded[name] then return loaded[name] end
    loaded[name]=true
    if modules[name] then loaded[name]=modules[name]() or true end
    return loaded[name]
end
local count=0
local function check(ok,message)count=count+1;if not ok then error(message) end end
local clock=10000
getTimestampMs=function()return clock end
isClient=function()return false end
instanceof=function(_,class)return class=="IsoPlayer" end
local function event()
    local handlers={}
    return {Add=function(fn)handlers[#handlers+1]=fn end,
        fire=function(...)for _,fn in ipairs(handlers)do fn(...) end end}
end
Events=setmetatable({}, {__index=function(t,k)local e=event();rawset(t,k,e);return e end})
require "ProjectYakuza/Registry"
local P=ProjectYakuza
P.Bindings={attackGates={},down=function()return false end,pressed=function()return false end}
require "ProjectYakuza/Runtime"
require "ProjectYakuzaMadDog/Style"
require "ProjectYakuzaMadDog/Movement"
require "ProjectYakuza/NetworkProtocol"
local ID="project_yakuza.mad_dog_of_shimano"
local style=P.getStyle(ID)
check(style and P.validateStyle(style),"Mad Dog validates against production registry")
check(#P.styleOrder==2,"addon registers one style without replacing DoD")
check(#style.lightAttacks==4 and #style.groundAttacks==1,"four lights and ground slash registered")
check(style.music==false and style.combatVoices==false and not style.tigerDrop and not style.heatAura,
    "no Kiryu music, voices, counter or aura inherited")
local bad={id="bad",name="Bad",lightAttacks=style.lightAttacks,weaponSprite=""}
check(not P.validateStyle(bad),"empty weapon model rejected")
local function weapon()
    local w={sprite="ProjectYakuza_EmptyHand",minimum=.35,maximum=.65,data={}}
    function w:getFullType()return P.TOKEN end
    function w:getWeaponSprite()return self.sprite end
    function w:setWeaponSprite(v)self.sprite=v end
    function w:setOriginalWeaponSprite(v)self.original=v end
    function w:getMaxHitCount()return self.maxHit or 1 end
    function w:setMaxHitCount(v)self.maxHit=v end
    function w:getModData()return self.data end
    function w:getMinDamage()return self.minimum end
    function w:getMaxDamage()return self.maximum end
    function w:setMinDamage(v)self.minimum=v end
    function w:setMaxDamage(v)self.maximum=v end
    return w
end
local function player(index)
    local p={data={ProjectYakuzaStyle=ID},vars={},token=weapon(),index=index,block=false,ignore=false}
    function p:getModData()return self.data end
    function p:getPrimaryHandItem()return self.token end
    function p:getPlayerNum()return self.index end
    function p:isLocalPlayer()return true end
    function p:setVariable(n,v)self.vars[n]=tostring(v)end
    function p:GetVariable(n)return self.vars[n]end
    function p:isBlockMovement()return self.block end
    function p:setBlockMovement(v)self.block=v end
    function p:getIgnoreMovement()return self.ignore end
    function p:setIgnoreMovement(v)self.ignore=v end
    function p:isAiming()return true end
    function p:isDead()return self.dead end
    function p:isOnFloor()return self.floor end
    function p:isKnockedDown()return self.knocked end
    function p:getVehicle()return self.vehicle end
    function p:isClimbing()return self.climbing end
    function p:getHitReaction()return self.hit or "" end
    function p:isAimAtFloor()return self.floorAim==true end
    function p:isAttackStarted()return self.attacking==true end
    function p:isPerformingAttackAnimation()return self.attacking==true end
    function p:isWeaponReady()return true end
    function p:AttemptAttack()self.attacking=true;Events.OnWeaponSwing.fire(self,self.token);return false end
    function p:isIgnoreStaggerBack()return self.stagger==true end
    function p:setIgnoreStaggerBack(v)self.stagger=v end
    function p:setMeleeDelay(v)self.delay=v end
    function p:setPerformingAttackAnimation(v)self.attacking=v end
    function p:reportEvent(e)self.reported=e end
    function p:isAuthorizeMeleeAction()return true end
    function p:hasTimedActions()return false end
    return p
end
local p=player(0)
check(P.prepareToken(p.token,p),"first prepare displays native knife")
check(p.token.sprite=="HuntingKnife" and p.token.original=="HuntingKnife" and p.token.maxHit==3,"model/identity/hit cap agree")
check(not P.prepareToken(p.token,p),"idle prepare does not rebuild model every tick")
local base=P.getStyle("dragon_of_dojima")
check(P.prepareTokenAppearance(p.token,base) and p.token.sprite=="ProjectYakuza_EmptyHand","shared server helper restores DoD hands")
check(P.prepareTokenAppearance(p.token,style) and p.token.sprite=="HuntingKnife","shared server helper selects Mad Dog knife")
check(not P.prepareTokenAppearance(nil,style),"missing equipment safe")
local foreign={getFullType=function()return "Base.HuntingKnife"end}
check(not P.prepareTokenAppearance(foreign,style),"ordinary equipment not modified")
local function finish()
    p.attacking=false;clock=clock+100
    Events.OnPlayerAttackFinished.fire(p,p.token)
end
-- Real Runtime.OnWeaponSwing and Combo state, including scoped full-body leases.
for i=1,4 do
    P.Combo.press(P.stateFor(p),4,1)
    p:AttemptAttack()
    check(P.stateFor(p).step==i and p.block,"original light "..i.." accepted with planted legs")
    check(p.vars.ProjectYakuzaStyle==ID and p.vars.ProjectYakuzaMove==style.lightAttacks[i].nodeValue,"style-specific selector "..i)
    check(math.abs(p.token.minimum-.35*.95)<.00001,"light damage applied once "..i)
    finish()
    check(not p.block and math.abs(p.token.minimum-.35)<.00001,"light completion restores controls/damage "..i)
end
P.resetPlayer(p,"test")
for branch=1,4 do
    local s=P.stateFor(p);s.step=branch;s.finishedAt=clock
    local ok,why=P.requestAction(p,"finisher","after_"..branch)
    check(ok,"native finisher "..branch.." starts: "..tostring(why))
    check(s.finisherMove==style.actions.finisher.variants["after_"..branch],"correct finisher branch "..branch)
    finish()
    check(not P.activeActions[p] and not p.block,"finisher ownership/control cleanup "..branch)
end
-- A queued light can release recovery only after both original markers.
P.resetPlayer(p,"recovery");p:AttemptAttack()
local s=P.stateFor(p);P.Combo.press(s,4,1)
check(not P.tryRecoveryCancel(p,style,s),"no early exit before contact")
p.vars.ProjectYakuzaChainReady=style.lightAttacks[1].nodeValue
check(not P.tryRecoveryCancel(p,style,s),"chain marker alone cannot shorten attack")
p.vars.ProjectYakuzaHitMarker=style.lightAttacks[1].nodeValue
check(P.tryRecoveryCancel(p,style,s) and p.reported=="ActiveAnimFinishing","post-contact queue releases native recovery")
finish();check(not p.block,"early native exit restores planted legs")
-- Interruption cases restore only the lock owned by this addon.
for _,reason in ipairs({"damage","death","unequip","vehicle","knockdown","floor","timeout","world_exit","save"}) do
    P.resetPlayer(p,"before");p.attacking=false;p.block=false;p:AttemptAttack()
    if reason=="damage" then p.hit="Hit"
    elseif reason=="death"then p.dead=true
    elseif reason=="unequip"then p.data.ProjectYakuzaStyle="none"
    elseif reason=="vehicle"then p.vehicle={}
    elseif reason=="knockdown"then p.knocked=true
    elseif reason=="floor"then p.floor=true
    elseif reason=="world_exit"then Events.OnMainMenuEnter.fire()
    elseif reason=="save"then Events.OnSave.fire()
    else P.resetPlayer(p,reason) end
    P.MadDogMovement.watch(p)
    check(not p.block and not P.MadDogMovement.locks[p],reason.." restores movement")
    p.hit=nil;p.dead=false;p.data.ProjectYakuzaStyle=ID;p.vehicle=nil;p.knocked=false;p.floor=false
    P.resetPlayer(p,"after");p.attacking=false
end
p.block=true;P.MadDogMovement.start(p,style);P.MadDogMovement.restore(p)
check(p.block,"cleanup preserves a pre-existing movement restriction");p.block=false
P.groundNext[0]=2
check(P.selectStyle(p,ID) and P.groundNext[0]==1,"DoD-to-Mad-Dog switch resets ground variant")
P.groundNext[0]=2;Events.OnCreatePlayer.fire(0,p)
check(P.groundNext[0]==1,"saved Mad Dog character resets native ground variant")
p:AttemptAttack()
check(not P.selectStyle(p,"dragon_of_dojima"),"cannot change style during attack")
finish()
check(P.selectStyle(p,"dragon_of_dojima"),"switch back to DoD when idle")
P.prepareToken(p.token,p)
check(p.token.sprite=="ProjectYakuza_EmptyHand","returning to DoD restores empty hands")
p:AttemptAttack();check(not P.MadDogMovement.locks[p] and not p.block,"DoD lights do not acquire Mad Dog locks");finish()
P.selectStyle(p,ID)
local other=player(1);P.stateFor(other).active=true;P.MadDogMovement.start(other,style)
P.MadDogMovement.restore(p);check(other.block,"split-screen leases remain independent");P.MadDogMovement.restore(other)
-- Registry, catalog and protocol must resolve precisely the same moves.
local nodes={}
for _,entry in ipairs(P.NetworkCatalog[ID])do
    check(not nodes[entry.id],"unique observer id "..entry.id);nodes[entry.id]=true
    check(P.NetworkProtocol.clip(ID,entry.id)==entry,"protocol resolves clip "..entry.id)
    check(not P.NetworkProtocol.clip("dragon_of_dojima",entry.id),"clip isolated from DoD "..entry.id)
end
for _,direction in ipairs({"forward","backward","left","right"})do
    local q=style.actions.quickstep.variants[direction]
    local kind,move=P.NetworkProtocol.kind(ID,q.animation)
    check(kind=="quickstep" and move==q,"server resolves dodge "..direction)
    check(P.NetworkProtocol.move(ID,style.actions.quickstepAttack.variants[direction].nodeValue),"server resolves evasive slash "..direction)
end
for _,variant in ipairs({"left","right","knee","dropkick"})do
    local r=style.actions.runningAttack.variants[variant]
    check(r.animation=="ProjectYakuza_MD_RunningSlash" and r.variant==variant,"running trigger uses Mad Dog slash "..variant)
end
P.stateFor(p).active=false
check(not P.requestAction(p,"grab"),"disabled grab not inherited")
check(not P.requestAction(p,"parry"),"Kiryu counter not inherited")
return "PASS: "..count.." Mad Dog Kahlua assertions (production registry/runtime/heat/combo/protocol and addon)"
