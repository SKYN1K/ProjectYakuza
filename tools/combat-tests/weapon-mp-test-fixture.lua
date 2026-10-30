local count=0
local function check(ok,msg)count=count+1;if not ok then error(msg) end end
require=function()end
local clock=10000
getTimestampMs=function()return clock end
isGamePaused=function()return false end
isClient=function()return true end;isServer=function()return true end
local function event()local e={};e.Add=function(fn)e[fn]=true end;e.Remove=function(fn)e[fn]=nil end;return e end
Events={OnSave=event(),OnTick=event(),OnClientCommand=event(),OnServerCommand=event(),OnPlayerUpdate=event(),OnZombieUpdate=event(),OnMainMenuEnter=event(),OnWeaponHitCharacter=event()}
local actors={}
local function list(t)return {size=function()return #t end,get=function(_,i)return t[i+1]end}end
local nextItem=1000
local function tokenItem(id)
 return {getID=function()return id end,getFullType=function()return 'ProjectYakuza.StyleToken' end,
 getMinDamage=function()return .3 end,getMaxDamage=function()return .5 end,
 setMaxHitCount=function(self,v)self.maxHit=v end,setWeaponSprite=function(self,v)self.sprite=v end,
 setOriginalWeaponSprite=function(self,v)self.originalSprite=v end}
end
local function player(id,x)
 local p={id=id,x=x,y=0,z=0,vars={},data={},localPlayer=id==1,health=1,token=tokenItem(100+id)}
 p.hand=p.token;p.inventoryItems={p.token}
 p.inventory={getItems=function()return list(p.inventoryItems)end,getItemWithID=function(_,id)
  for _,item in ipairs(p.inventoryItems)do if item:getID()==id then return item end end
 end,AddItem=function()nextItem=nextItem+1;local item=tokenItem(nextItem);p.inventoryItems[#p.inventoryItems+1]=item;return item end}
 function p:getInventory()return self.inventory end
 function p:setPrimaryHandItem(item)self.hand=item;self.equipped=item~=nil end
 function p:setSecondaryHandItem(item)self.secondary=item end
 function p:resetModelNextFrame()self.modelsReset=true end
 function p:updateHandEquips()self.equipSent=(self.equipSent or 0)+1 end
 function p:setIgnoreMovement(v)self.ignore=v;if v then self.nativeUpdates=(self.nativeUpdates or 0)+1 end end
 function p:getOnlineID()return self.id end
 function p:getX()return self.x end;function p:getY()return self.y end;function p:getZ()return self.z end
 function p:isDead()return self.dead==true end;function p:getVehicle()return self.vehicle end
 function p:isLocalPlayer()return self.localPlayer end;function p:getModData()return self.data end
 function p:getPrimaryHandItem()return self.equipped~=false and self.hand or nil end
 function p:setX(v)self.x=v end;function p:setY(v)self.y=v end
 function p:setNextX(v)self.nextX=v end;function p:setNextY(v)self.nextY=v end
 function p:setTargetAndCurrentDirection(x,y)self.fx=x;self.fy=y end
 function p:getForwardDirection()return {getX=function()return 1 end,getY=function()return 0 end}end
 function p:GetVariable(k)local v=self.vars[k];if type(v)=='boolean' then return tostring(v) end;return v or '' end
 function p:setVariable(k,v)self.vars[k]=v end
 function p:isPerformingStompAnimation()return false end
 function p:StartTimedActionAnim(name)self.anim=name;self.starts=(self.starts or 0)+1 end
 function p:StopTimedActionAnim()self.anim=nil;self.stops=(self.stops or 0)+1 end
 function p:isMoving()return false end
 function p:isGhostMode()return self.ghost==true end;function p:setGhostMode(v)self.ghost=v end
 function p:isInvincible()return self.invincible==true end;function p:setInvincible(v)self.invincible=v end
 actors[id]=p;return p
end
local p=player(1,0);local remote=player(2,1)
local zombies={}
local function zombie(id,x)
 local z={id=id,x=x,y=0,z=0,health=1,hits=0,vars={},target=p,deferred=true}
 function z:getOnlineID()return self.id end
 function z:getX()return self.x end;function z:getY()return self.y end;function z:getZ()return self.z end
 function z:setX(v)self.x=v end;function z:setY(v)self.y=v end
 function z:setNextX(v)self.nextX=v end;function z:setNextY(v)self.nextY=v end
 function z:isDead()return self.health<=0 end;function z:isOnFloor()return false end;function z:isKnockedDown()return false end
 function z:isAttacking()return self.attacking==true end;function z:getAttackDidDamage()return self.didDamage==true end
 function z:getTarget()return self.target end;function z:setTarget(v)self.target=v end
 function z:isUseless()return self.useless==true end;function z:setUseless(v)self.useless=v end
 function z:getIgnoreMovement()return self.ignore==true end;function z:setIgnoreMovement(v)self.ignore=v end
 function z:isDeferredMovementEnabled()return self.deferred end;function z:setDeferredMovementEnabled(v)self.deferred=v end
 function z:setAttackOutcome(v)self.outcome=v end
 function z:setAttackedBy(v)self.attacker=v end
 function z:getHitDir()return {set=function(_,x,y)z.dx=x;z.dy=y end}end
 function z:setStaggerBack(v)self.stagger=v end
 function z:setHitForce(v)self.force=v end;function z:setUsePhysicHitReaction(v)self.physics=v end
 function z:getHitForce()return self.force or 1 end
 function z:setHitReaction(v)self.reaction=v end;function z:getHitReaction()return self.reaction end
 function z:setHitFromBehind(v)self.behind=v end
 function z:getCurrentStateName()return self.state or 'idle' end
 function z:Kill(v)self.kills=(self.kills or 0)+1;self.health=0 end
 function z:Hit(item,attacker,damage)self.hits=self.hits+1;self.health=math.max(0,self.health-damage)end
 function z:getHealth()return self.health end;function z:setHealth(v)self.health=v end
 function z:setKnockedDown(v)self.knock=v end;function z:setFallOnFront(v)self.front=v end
 function z:setVariable(k,v)self.vars[k]=v end;function z:reportEvent(name)self.lastEvent=name;self.events=(self.events or 0)+1 end
 function z:setTargetAndCurrentDirection(x,y)self.fx=x;self.fy=y end
 function z:isRemoteZombie()return self.remote==true end
 zombies[#zombies+1]=z;return z
end
local z1=zombie(10,.8);local z2=zombie(11,1);local z3=zombie(12,1.2);local z4=zombie(13,1.1)
instanceof=function(obj,kind)return kind=='IsoZombie' and obj.hits~=nil or kind=='IsoPlayer' and obj.token~=nil end
local wall=false
local square={TreatAsSolidFloor=function()return true end,isSolid=function()return false end,isSolidTrans=function()return false end,testCollideAdjacent=function()return wall end,getMovingObjects=function()return list(zombies)end}
getCell=function()return {getGridSquare=function()return square end}end
getOnlinePlayers=function()local all={};for _,a in pairs(actors) do all[#all+1]=a end;return list(all)end
getPlayerByOnlineID=function(id)return actors[id]end
InventoryItemFactory={CreateItem=function()return p.token end}
local replies,outgoing={},{}
local nativeAdds,nativeEquips={},{}
sendAddItemToContainer=function(inv,item)nativeAdds[#nativeAdds+1]={inventory=inv,item=item}end
sendEquip=function(who)nativeEquips[#nativeEquips+1]={player=who,item=who:getPrimaryHandItem()}end
sendServerCommand=function(to,module,command,args)replies[#replies+1]={to=to,module=module,command=command,args=args}end
sendClientCommand=function(from,module,command,args)outgoing[#outgoing+1]={from=from,module=module,command=command,args=args}end
-- SHARED_AND_SERVER
ProjectYakuza.FEATURES.grab=true;ProjectYakuza.styles.dragon_of_dojima.actions.grab.enabled=true -- isolate dormant grab lifecycle tests
local ProjectYakuza=ProjectYakuza;local P=ProjectYakuza.NetworkProtocol;local server=ProjectYakuza.NetworkServer
local step=0;local seq=0;local eventID=0
local function snapshot(who,extra)
 seq=math.max(seq,(server.players[who.id] and server.players[who.id].seq or 0))+1;clock=clock+60
 local a={seq=seq,style='dragon_of_dojima',equipped=true,heat=30,fuel=30,extreme=false,clip='ProjectYakuza_DD_Light01',move='dd_light_01',swing=1}
 for k,v in pairs(extra or {})do a[k]=v end
 server.command(P.module,'state',who,a);return a
end
local function command(name,args,who)
 eventID=eventID+1;args=args or {};args.event=eventID;server.command(P.module,name,who or p,args)
end

local function realWeapon(id,name)
 local w={min=.8,max=1.2,condition=10}
 function w:getID()return id end;function w:getFullType()return name end
 function w:getMaxRange()return self.range or 1.25 end
 function w:getMinDamage()return self.min end;function w:getMaxDamage()return self.max end
 function w:getCondition()return self.condition end;function w:isTwoHandWeapon()return name=='Base.BaseballBat' or name=='Base.Katana' end
 return w
end
local bat=realWeapon(700,'Base.BaseballBat');local pipe=realWeapon(701,'Base.MetalPipe')
p.inventoryItems[#p.inventoryItems+1]=bat;p.inventoryItems[#p.inventoryItems+1]=pipe
p:setPrimaryHandItem(bat);p.data.ProjectYakuzaStyle='dragon_of_dojima'
server.command(P.module,'equip',p,{style='dragon_of_dojima',weaponProfile='bat',item=700,request=1})
local ack=replies[#replies].args
check(p.hand==bat and p.secondary==bat and ack.item==700 and ack.weaponProfile=='bat','server keeps actual two-handed bat and acknowledges its inventory ID')
check(#nativeAdds==0,'weapon handshake never creates a replacement item')
local a=snapshot(p,{weaponProfile='bat',clip='ProjectYakuza_DD_BatLight01',move='dd_bat_light_01'})
local state=server.players[p.id]
check(state.packet.equipped and state.packet.weaponProfile=='bat' and state.packet.move=='dd_bat_light_01','server accepts DoD plus real weapon')
local accepted=state.seq
snapshot(p,{weaponProfile='bat',clip='ProjectYakuza_DD_Light01',move='dd_light_01'})
check(state.seq==accepted,'armed snapshot cannot use unarmed light moves')
snapshot(p,{weaponProfile='missing',clip='ProjectYakuza_DD_BatHeavy',move='dd_bat_heavy'})
check(state.seq==accepted,'forged weapon profile rejected')
snapshot(p,{weaponProfile='bat',clip='ProjectYakuza_DD_HeatActivate01',move='dd_bat_light_01'})
check(state.seq==accepted,'unavailable armed actions rejected')
check(P.move('dragon_of_dojima','dd_bat_heavy').damageMultiplier==1.25,'network resolver knows weapon heavy')
check(P.kind('dragon_of_dojima','ProjectYakuza_DD_BatGuardLoop')=='block','network resolver knows weapon guard')
z1.attacking=true;z1.target=p;command('counter',{zombie=z1.id})
check(not z1.kills,'armed profile cannot invoke the unarmed Tiger Drop server command')
snapshot(p,{weaponProfile='bat',clip='ProjectYakuza_DD_BatGuardLoop',move='dd_bat_light_01',phase='hold'})
check(state.packet.clip=='ProjectYakuza_DD_BatGuardLoop','weapon guard phase clip is accepted through its action animation contract')
clock=clock+1100;snapshot(p,{weaponProfile='bat',clip='ProjectYakuza_DD_BatHeavy',move='dd_bat_heavy'})
command('impact',{swing=1,zombie=z1.id})
check(z1.hits==0,'primary bat hit remains native and is never duplicated')
z2.health=10
command('extra',{swing=1,zombie=z2.id})
check(z2.hits==1 and math.abs(z2.health-8.75)<.00001,'extra bat victim uses actual server weapon damage times heavy multiplier')
command('extra',{swing=1,zombie=z2.id})
check(z2.hits==1,'extra bat victim deduplicated')
p:setPrimaryHandItem(pipe)
command('extra',{swing=1,zombie=z3.id})
check(z3.hits==0,'same-profile weapon swap invalidates old swing item ownership')
p:setPrimaryHandItem(bat);bat.condition=0
local beforeBroken=state.seq
snapshot(p,{weaponProfile='bat',clip='ProjectYakuza_DD_BatHeavy',move='dd_bat_heavy'})
check(state.seq==beforeBroken,'broken item snapshot rejected')
bat.condition=10
-- Actual client handshake: never exchange weapon for token, and discard a stale equipment acknowledgement.
ProjectYakuza.stateFor=function()return {active=false,step=0}end
ProjectYakuza.Heat={stocks=function()return 0 end,display=function()return 0 end,isExtreme=function()return false end}
ProjectYakuza.prepareToken=function()end
-- CLIENT_MODULE
local N=ProjectYakuza.Network
p:setPrimaryHandItem(bat)
N.equip(p,'dragon_of_dojima',true)
local sent=outgoing[#outgoing].args
check(sent.item==700 and sent.weaponProfile=='bat','client asks to retain real weapon')
local localState=N.localState(p)
localState.equipReply={style='dragon_of_dojima',weaponProfile='bat',item=700}
check(N.finishEquipment(p,localState) and p.hand==bat and p.secondary==bat,'client applies matching acknowledgement without clearing either hand')
N.equip(p,'dragon_of_dojima',false);p:setPrimaryHandItem(pipe)
localState.equipReply={style='dragon_of_dojima',weaponProfile='bat',item=700}
check(not N.finishEquipment(p,localState) and p.hand==pipe and not localState.equipReply,'late acknowledgement cannot overwrite newer equipment')
check(not N.ensureEquipment(p,'dragon_of_dojima'),'changed weapon needs fresh readiness acknowledgement')
check(outgoing[#outgoing].args.item==701,'fresh handshake identifies replacement pipe')
-- Disabling style leaves the ordinary held weapon in place on both peers.
clock=clock+1100;server.command(P.module,'equip',p,{style='none',weaponProfile='',item=-1,request=2})
check(p.hand==pipe,'server disable preserves the real weapon')
localState.equipReply={style='none',weaponProfile='',item=-1}
check(N.finishEquipment(p,localState) and p.hand==pipe,'client disable preserves real weapon and hand models')

local knife=realWeapon(702,'Base.HuntingKnife');knife.range=.9
local sword=realWeapon(703,'Base.Katana');sword.range=1.4;sword.min=8;sword.max=8
p.inventoryItems[#p.inventoryItems+1]=knife;p.inventoryItems[#p.inventoryItems+1]=sword
clock=clock+2000;p:setPrimaryHandItem(knife)
server.command(P.module,'equip',p,{style='dragon_of_dojima',weaponProfile='knife',item=702,request=3})
check(p.hand==knife and replies[#replies].args.weaponProfile=='knife','MP real knife handshake uses its own profile')
snapshot(p,{weaponProfile='knife',clip='ProjectYakuza_DD_KnifeLight01',move='dd_knife_light_01'})
check(state.packet.weaponProfile=='knife' and state.packet.clip=='ProjectYakuza_DD_KnifeLight01','MP knife source animation accepted')
local priorSeq=state.seq
snapshot(p,{weaponProfile='knife',clip='ProjectYakuza_DD_BladeLight01',move='dd_blade_light_01'})
check(state.seq==priorSeq,'knife cannot borrow sword clips/moves')
z1.health=10;local before=z2.hits
command('impact',{swing=2,zombie=z1.id})
command('extra',{swing=2,zombie=z2.id})
check(z2.hits==before,'knife extra victim outside actual .9 reach rejected')
z2.x=.85;z2.health=10;command('extra',{swing=2,zombie=z2.id})
check(z2.hits==before+1 and math.abs(z2.health-9)<.00001,'knife extra victim inside real reach gets native server weapon damage')
clock=clock+2000;p:setPrimaryHandItem(sword)
server.command(P.module,'equip',p,{style='dragon_of_dojima',weaponProfile='blade',item=703,request=4})
check(p.hand==sword and p.secondary==sword,'MP preserves actual two-handed sword')
snapshot(p,{weaponProfile='blade',clip='ProjectYakuza_DD_BladeHeavy',move='dd_blade_heavy'})
z1.health=10;z2.health=100;z2.x=1.1
command('impact',{swing=3,zombie=z1.id});command('extra',{swing=3,zombie=z2.id})
check(math.abs(z2.health-90)<.00001,'katana extra heavy uses 8 x 1.25 instead of old unarmed damage cap')
z4.x=1.5;before=z4.hits;command('extra',{swing=3,zombie=z4.id})
check(z4.hits==before,'sword extras remain within actual 1.4 range')
snapshot(p,{weaponProfile='blade',clip='ProjectYakuza_DD_BladeGuardLoop',move='dd_blade_light_01',phase='hold'})
check(state.packet.clip=='ProjectYakuza_DD_BladeGuardLoop','source blade guard phase accepted')
check(P.kind('dragon_of_dojima','ProjectYakuza_DD_BladeGuardLoop')=='block','blade guard resolves through shared action contract')
N.equip(p,'dragon_of_dojima',false);localState.equipReply={style='dragon_of_dojima',weaponProfile='blade',item=703}
check(N.finishEquipment(p,localState) and p.hand==sword and p.secondary==sword,'client retains sword and both hand bindings')
remote.data.ProjectYakuzaStyle='dragon_of_dojima';N.remote[remote.id]={packet={equipped=true,weaponProfile='knife'}}
check(ProjectYakuza.getPlayerStyle(remote).weaponProfile=='knife','remote presentation resolves validated knife view before native hand replication')
return true,'PASS '..count..' sharp/blunt MP equipment, observers, reach, damage and stale-swing checks'
