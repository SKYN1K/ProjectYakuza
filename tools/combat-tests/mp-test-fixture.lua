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
InventoryItemFactory=nil
instanceItem=function(name)check(name==ProjectYakuza.TOKEN,'MP damage uses B42 instanceItem token factory');return p.token end
local replies,outgoing={},{}
local nativeAdds,nativeEquips={},{}
sendAddItemToContainer=function(inv,item)nativeAdds[#nativeAdds+1]={inventory=inv,item=item}end
sendEquip=function(who)nativeEquips[#nativeEquips+1]={player=who,item=who:getPrimaryHandItem()}end
sendServerCommand=function(to,module,command,args)replies[#replies+1]={to=to,module=module,command=command,args=args}end
sendClientCommand=function(from,module,command,args)outgoing[#outgoing+1]={from=from,module=module,command=command,args=args}end
do local _="ProjectYakuzaFixture:SHARED_AND_SERVER" end
ProjectYakuza.FEATURES.grab=true;ProjectYakuza.styles.dragon_of_dojima.actions.grab.enabled=true
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
check(not P.number(0/0,0,1) and not P.integer(1.1,0,2),'reject NaN and fractional IDs')
check(P.clip('dragon_of_dojima','ProjectYakuza_DD_Light01')~=nil,'catalogue has known attack')
check(P.clip('dragon_of_dojima','arbitrary_clip')==nil,'unknown animation rejected')
check(P.clip('dragon_of_dojima','ProjectYakuza_DD_ChargeLoop').loop==true,'original charge hold is available to observers')
check(P.move('dragon_of_dojima','dd_charged_heavy').damageMultiplier==2,'server resolves charged hit from shared style definition')
snapshot(p);local s=server.players[1]
check(s.packet.clip=='ProjectYakuza_DD_Light01','known state accepted')
local accepted=s.seq;snapshot(p,{seq=accepted});check(s.seq==accepted,'stale state rejected')
snapshot(p,{heat=math.huge});check(s.seq==accepted,'infinite heat rejected')
snapshot(p,{style='missing'});check(s.seq==accepted,'unknown styles rejected')
snapshot(p)
command('extra',{swing=1,zombie=z2.id});check(z2.hits==0,'supplement without primary report rejected')
command('impact',{swing=1,zombie=z1.id});check(z1.hits==0,'native primary report never reapplies damage')
command('extra',{swing=1,zombie=z2.id});check(z2.hits==1,'server applies extra victim once')
command('extra',{swing=1,zombie=z2.id});check(z2.hits==1,'duplicate extra target ignored')
command('extra',{swing=1,zombie=z3.id});command('extra',{swing=1,zombie=z4.id})
check(z3.hits==1 and z4.hits==0,'native and supplemental victims share three-target cap')
local past=s.event;server.command(P.module,'extra',p,{event=past,swing=1,zombie=z4.id});check(z4.hits==0,'replayed command ID ignored')
clock=clock+1100;snapshot(p);command('impact',{swing=2,zombie=z1.id})
z4.x=3;command('extra',{swing=2,zombie=z4.id});check(z4.hits==0,'out-of-range target rejected')
z4.x=1.1;wall=true;command('extra',{swing=2,zombie=z4.id});wall=false
check(z4.hits==0,'wall collision rejects extra damage')
clock=clock+1100;snapshot(p,{phase='enter',clip='ProjectYakuza_DD_GrabEnter'})
command('grabRequest',{zombie=z1.id});check(s.grab and z1.useless and z1.ignore,'server grants and freezes one grab lease')
snapshot(remote);command('grabRequest',{zombie=z1.id},remote)
check(server.players[2].grab==nil,'second player cannot grab leased zombie')
snapshot(p,{phase='hold',clip='ProjectYakuza_DD_GrabHold'});server.tick()
check(z1.x==.7 and z1.nextX==.7,'server aligns paired current and next position')
snapshot(p,{phase='throw',clip='ProjectYakuza_DD_Throw'});command('throw',{zombie=z1.id})
check(z1.hits==1 and z1.knock and s.grab==nil and not z1.useless and not z1.ignore,'throw hits once and releases AI lease')
command('throw',{zombie=z1.id});check(z1.hits==1,'repeated throw does not damage twice')
z1.health=1;clock=clock+1100;snapshot(p);command('grabRequest',{zombie=z1.id})
check(s.grab~=nil,'can acquire another grab after release')
clock=clock+9000;server.tick();check(s.grab==nil and not z1.useless,'lease timeout restores zombie AI')
clock=clock+1100;snapshot(p);z1.attacking=true;z1.target=p
command('counter',{zombie=z1.id,age=301});check(not z1.kills,'server rejects counter age outside 0.3 seconds')
command('counter',{zombie=z1.id,age=0});check(z1.kills==1 and z1.force==12,'valid attacking target is killed on server with hit force')
command('counter',{zombie=z1.id,age=0});check(z1.kills==1,'counter victim deduplicated')
z2.health=1;z2.attacking=true;z2.target=p;clock=clock+500;snapshot(p)
command('counter',{zombie=z2.id,age=0});check(not z2.kills,'counter cannot reopen within 60 second server cooldown')
clock=clock+61000;snapshot(p);command('counter',{zombie=z2.id,age=0});check(z2.kills==1,'counter ready after server cooldown')
z3.health=1;z3.target=p;snapshot(p,{clip='ProjectYakuza_DD_GuardLoop',phase='hold'})
command('guard',{zombie=z3.id});check(z3.outcome=='fail','validated guard cancels bite outcome')
clock=clock+1100;snapshot(p);z4.health=1;command('grabRequest',{zombie=z4.id});check(s.grab~=nil,'disconnect test owns lease')
actors[1]=nil;server.tick();check(server.players[1]==nil and not z4.useless,'disconnect restores AI and removes session')
actors[1]=p
snapshot(p,{clip='ProjectYakuza_DD_HeatActivate01',heat=40})
check(p.ghost and p.invincible and server.players[1].packet.protected,'activation gets a bounded server protection lease')
clock=clock+4000;server.tick();check(not p.ghost and not p.invincible,'expired activation restores original server flags')
snapshot(p,{clip='ProjectYakuza_DD_HeatActivate01',heat=40});check(not p.invincible,'same held activation cannot renew invulnerability')
snapshot(p,{clip='',heat=40});snapshot(p,{clip='ProjectYakuza_DD_HeatActivate01',heat=40})
check(p.invincible,'a later distinct activation can acquire protection')
snapshot(p,{clip='',heat=40});check(not p.ghost and not p.invincible,'activation completion restores flags immediately')
ProjectYakuza.stateFor=function(who)who.combo=who.combo or {active=true,step=1};return who.combo end
ProjectYakuza.Heat={states={},stocks=function(who)return math.floor((who.data.ProjectYakuzaHeat or 0)*6/100)end,display=function(who)return who.data.ProjectYakuzaHeat or 0 end,isExtreme=function()return false end,playback=function(who,e)who.speed=e and 1.92 or 1.6 end,onHit=function()end}
ProjectYakuza.HeatAura={flash=function(who)who.flashes=(who.flashes or 0)+1 end,update=function(who)who.auraUpdates=(who.auraUpdates or 0)+1 end,clear=function(who)who.auraCleared=true end}
local effects=0;ProjectYakuza.HitEffects={spawn=function()effects=effects+1 end}
do local _="ProjectYakuzaFixture:REACTIONS_MODULE" end
ProjectYakuza.Defense={snapActor=function(z,x,y)z.x=x;z.y=y;z.nextX=x;z.nextY=y end}
ProjectYakuza.requestAction=function()return true end
ProjectYakuza.cancelAction=function()end
ProjectYakuza.prepareToken=function(item)item:setMaxHitCount(ProjectYakuza.MAX_HIT_COUNT)end
do local _="ProjectYakuzaFixture:CLIENT_MODULE" end
local client=ProjectYakuza.Network
remote.data.ProjectYakuzaStyle='dragon_of_dojima';remote.equipped=false
local packet={player=2,seq=1,style='dragon_of_dojima',equipped=true,heat=40,fuel=35,extreme=true,clip='ProjectYakuza_DD_Light01',move='dd_light_01',swing=1}
client.command(P.module,'state',packet)
check(ProjectYakuza.isEquipped(remote) and remote.data.ProjectYakuzaHeat==40 and remote.vars.ProjectYakuzaRemoteClip=='ProjectYakuza_DD_Light01','remote style heat and safe observer animation applied')
check(remote.auraUpdates==1 and remote.vars.ProjectYakuzaRemoteObserver,'observer starts once')
for i=1,20 do client.update(remote)end
check(remote.auraUpdates==1,'unchanged remote updates do not restart clips or poll aura repeatedly')
local impact={player=2,zombie=z3.id,event=1,strong=true,reaction='enemy_01',style='dragon_of_dojima'}
client.command(P.module,'impact',impact);client.command(P.module,'impact',impact)
check(effects==1 and z3.vars.ProjectYakuzaEnemyHitClip=='enemy_01' and z3.reaction=='HeadLeft' and z3.lastEvent=='wasHit','remote impact renders once and enters actual native hit reaction state')
local damage={player=2,zombie=z3.id,event=1,health=.25,amount=.4,kill=false,knock=false}
local hitsBefore=z3.hits
client.command(P.module,'damage',damage);client.command(P.module,'damage',damage)
check(z3.health==.25 and z3.hits==hitsBefore and effects==2,'server result mirrors absolute health without observer Hit calls')
packet={player=2,seq=2,style='dragon_of_dojima',equipped=true,heat=40,fuel=35,extreme=true,clip='ProjectYakuza_DD_Light01',move='dd_light_01',swing=2}
client.command(P.module,'state',packet);check(client.remote[2].swing==2,'same clip tracks a new attack serial')
packet.seq=3;packet.clip='ProjectYakuza_DD_Quickstep01';client.command(P.module,'state',packet)
check(remote.vars.PerformingAction=='ProjectYakuza_MP' and remote.vars.IsPerformingAnAction,'timed observer uses BaseAction native action variables')
packet.seq=4;packet.taunt=1;packet.clip='';client.command(P.module,'state',packet)
check(remote.flashes==1,'new completion counter flashes remote aura')
packet.seq=5;client.command(P.module,'state',packet);check(remote.flashes==1,'heartbeat does not repeat completion flash')
packet.seq=6;packet.clip='ProjectYakuza_DD_Taunt01';client.command(P.module,'state',packet)
packet.seq=7;packet.clip='';client.command(P.module,'state',packet);check(remote.flashes==1,'interrupted taunt without completion never flashes')
packet.seq=8;packet.taunt='invalid';client.command(P.module,'state',packet);check(remote.flashes==1,'malformed completion serial rejected')
clock=clock+4100;client.tick();check(remote.auraCleared and remote.vars.PerformingAction=='' and not ProjectYakuza.isEquipped(remote),'stale observer state clears animation and aura')
p.equipped=true;p.data.ProjectYakuzaStyle='dragon_of_dojima';p.data.ProjectYakuzaHeat=20
p.vars.ProjectYakuzaActive='true';p.vars.ProjectYakuzaMove='dd_light_01';p.vars.AimFloorAnim='false'
client.localState(p).equipReady=p.token;client.localState(p).equipStyle='dragon_of_dojima'
client.swing(p);check(#outgoing>0,'local attack sends snapshot without changing position')
local outCount=#outgoing;client.capture(p);client.capture(p);check(#outgoing==outCount,'unchanged local snapshots throttle redundant sends')
client.capture(p,true);local wireCount=#outgoing;client.send(p,'auditProbe',{});client.send(p,'auditProbe',{})
check(#outgoing==wireCount+2 and outgoing[#outgoing].command=='auditProbe','combat commands reuse unchanged current state without duplicate snapshots')
p.vars.ProjectYakuzaMove='dd_light_02';p.combo.step=2;wireCount=#outgoing;client.send(p,'auditProbe',{})
check(#outgoing==wireCount+2 and outgoing[#outgoing-1].command=='state','changed combat state is sent before its dependent command')
p.vars.ProjectYakuzaMove='dd_light_01';p.combo.step=1
local z=zombie(22,1);client.requestGrab(p,z);check(client.pending[p]~=nil,'grab waits asynchronously for server')
client.command(P.module,'grabDenied',{});check(client.pending[p]==nil,'denied grab releases pending request')
client.clear();local remaining=0;for _ in pairs(client.remote)do remaining=remaining+1 end;for _ in pairs(client.locals)do remaining=remaining+1 end
check(remaining==0,'menu cleanup clears peer caches')
server.players[1]=nil;replies={};outgoing={};z1.health=1;z2.health=1
client.localState(p).equipReady=p.token;client.localState(p).equipStyle='dragon_of_dojima'
local wireHits=z2.hits
local function flush()
 local batch=outgoing;outgoing={}
 for _,packet in ipairs(batch)do server.command(packet.module,packet.command,packet.from,packet.args)end
 local batchReplies=replies;replies={}
 for _,packet in ipairs(batchReplies)do if packet.to==p then client.command(packet.module,packet.command,packet.args)end end
end
clock=clock+1100;client.swing(p);flush()
check(server.players[1] and server.players[1].packet.move=='dd_light_01','client snapshot traverses real command handler and server validation')
client.hit(p,z1,p.token,.3);flush();client.extra(p,z2);flush()
check(z2.hits==wireHits+1,'client supplemental request and server result perform exactly one Hit across the wire')
check(z1.health==1,'native primary is not applied by command replay')

clock=clock+1100;snapshot(p,{clip='ProjectYakuza_DD_Quickstep01',action=1})
local firstSeq=server.players[1].seq
server.command(P.module,'state',p,{seq=firstSeq+1,style='dragon_of_dojima',equipped=true,heat=30,fuel=30,
 clip='ProjectYakuza_DD_Quickstep02',move='dd_light_01',swing=2,action=2})
check(server.players[1].packet.clip=='ProjectYakuza_DD_Quickstep02' and server.players[1].packet.action==2,'same-tick action transition is not discarded by a 50ms gate')

clock=clock+1100
local serverActor=player(3,0);serverActor.inventoryItems={};serverActor.hand=nil;serverActor.equipped=false
local owner=player(3,0);owner.localPlayer=true;owner.data.ProjectYakuzaStyle='dragon_of_dojima'
nativeAdds={};nativeEquips={};outgoing={};replies={}
check(not ProjectYakuza.isEquipped(owner),'unregistered client weapon cannot start combat')
check(#outgoing==1 and outgoing[1].command=='equip','saved client-only token requests a server-issued item')
local request=outgoing[1].args
server.command(P.module,'equip',serverActor,request)
local issued=serverActor:getPrimaryHandItem()
check(issued and serverActor:getInventory():getItemWithID(issued:getID())==issued,'issued weapon ID is present in authoritative server inventory')
check(#nativeAdds==1 and #nativeEquips==1 and nativeEquips[1].item==issued,'server synchronizes inventory before native equip')
local ack=replies[#replies].args
client.command(P.module,'equipReady',ack)
check(not ProjectYakuza.isEquipped(owner) and owner:getPrimaryHandItem()~=issued,'early equip ack waits for native inventory delivery')
owner.inventoryItems[#owner.inventoryItems+1]=issued
check(ProjectYakuza.isEquipped(owner) and owner:getPrimaryHandItem()==issued and owner.equipSent==1,'combat unlocks only after both peers resolve the same item ID')
check(owner.styleEntries==nil,'automatic equipment repair does not play entry')
clock=clock+250;local adds=#nativeAdds;ProjectYakuza.StyleEntry={request=function(who,id)who.styleEntries=(who.styleEntries or 0)+1 end}
client.equip(owner,'dragon_of_dojima',true)
check(owner.styleEntries==nil,'explicit selection waits for authoritative equip acknowledgement')
server.command(P.module,'equip',serverActor,outgoing[#outgoing].args)
check(#serverActor.inventoryItems==1 and #nativeAdds==adds,'reselecting a style reuses acknowledged item without duplicate inventory delivery')
client.command(P.module,'equipReady',replies[#replies].args)
check(owner.styleEntries==1,'explicit selection entry begins after equipment acknowledgement')
local hand=owner:getPrimaryHandItem()
client.command(P.module,'equipReady',{player=3,request=1,style='dragon_of_dojima',item=101})
check(owner:getPrimaryHandItem()==hand,'stale equip acknowledgements cannot restore old token')
check(owner.styleEntries==1,'equipment repair and stale replies do not replay entry')
clock=clock+250
server.command(P.module,'equip',serverActor,{request=100,style='unknown'})
check(serverActor:getPrimaryHandItem()==issued,'server rejects unknown style provisioning')
client.equip(owner,'none');server.command(P.module,'equip',serverActor,outgoing[#outgoing].args)
client.command(P.module,'equipReady',replies[#replies].args)
check(serverActor:getPrimaryHandItem()==nil and owner:getPrimaryHandItem()==nil,'disabling style unequips both peers')
actors[3]=nil;server.players[3]=nil

clock=clock+1100
local repeated={player=2,seq=100,style='dragon_of_dojima',equipped=true,heat=30,fuel=30,
 extreme=false,clip='ProjectYakuza_DD_Quickstep01',move='',swing=8,action=10}
client.command(P.module,'state',repeated)
local cycle=remote.vars.ProjectYakuzaRemoteCycle
repeated.seq=101;repeated.action=11;client.command(P.module,'state',repeated)
check(remote.vars.ProjectYakuzaRemoteCycle~=cycle and client.remote[2].action==11,'same-direction quickstep selects a fresh observer cycle')
local events=z3.events or 0
client.command(P.module,'impact',{player=2,zombie=z3.id,event=20,strong=true,reaction='not_registered',style='dragon_of_dojima'})
check(z3.events==events,'unregistered zombie clips cannot enter reaction state')
local beforeHits=z3.hits
client.command(P.module,'impact',{player=2,zombie=z3.id,event=21,strong=true,reaction='enemy_02',style='dragon_of_dojima'})
check(z3.vars.ProjectYakuzaEnemyHitClip=='enemy_02' and z3.events==events+1 and z3.hits==beforeHits,'repeat hit enters reaction state without applying Hit again')
ProjectYakuza.Reactions.update(z3,clock+500)
check(ProjectYakuza.Reactions.states[z3]~=nil,'reaction survives a delayed native state entry')
ProjectYakuza.Reactions.update(z3,clock+800)
check(ProjectYakuza.Reactions.states[z3]==nil,'reaction that never enters native state times out')

clock=clock+1100;p.x=0;p.y=0;remote.x=0;remote.y=0;replies={}
snapshot(p,{clip='ProjectYakuza_DD_Quickstep01',action=20})
local function sample(id,x,finished)
 command('step',{step=id,clip='ProjectYakuza_DD_Quickstep01',x=x,y=0,z=0,fx=1,fy=0,finished=finished})
end
sample(1,0,false);clock=clock+50;sample(1,.4,false)
local sampleReply=replies[#replies]
check(sampleReply.command=='step' and server.players[1].step.travel==.4,'server accepts collision-checked quickstep samples')
local travel=server.players[1].step.travel
clock=clock+50;sample(1,1.6,false)
check(server.players[1].step.travel==travel,'over-distance scripted step rejected')
wall=true;clock=clock+50;sample(1,1.1,false);wall=false
check(server.players[1].step.travel==travel,'step cannot cross a wall')
clock=clock+50;sample(1,.8,true)
check(server.players[1].step.finished and math.abs(server.players[1].step.travel-.8)<.001,'terminal sample is accepted and closes step stream: '..tostring(server.players[1].step.finished)..' / '..tostring(server.players[1].step.travel))
local closedTravel=server.players[1].step.travel
clock=clock+50;sample(1,.9,false)
check(server.players[1].step.travel==closedTravel,'late samples cannot reopen completed quickstep')
clock=clock+50;sample(2,0,true);clock=clock+50;sample(3,0,true);clock=clock+50;sample(4,0,false)
check(server.players[1].lastStep==3,'server independently enforces three quicksteps per 15 seconds')
clock=clock+15001;snapshot(p,{clip='ProjectYakuza_DD_Quickstep01',action=21});sample(4,0,false)
check(server.players[1].lastStep==4,'quickstep quota releases after rolling window')
local progress=server.players[1].step.travel
command('step',{step=4,clip='ProjectYakuza_DD_Quickstep01',x=0/0,y=0,z=0,fx=1,fy=0})
check(server.players[1].step.travel==progress,'nonfinite step position rejected')

remote.x=0;remote.y=0
local position={player=2,event=100,step=10,x=1,y=0,z=0,fx=1,fy=0}
client.command(P.module,'step',position);clock=clock+25;client.updateStep(remote,client.remote[2])
check(math.abs(remote.x-.5)<.001 and remote.nextX==remote.x,'observer smooths current and next quickstep positions')
clock=clock+25;client.updateStep(remote,client.remote[2])
check(remote.x==1,'observer reaches received position')
position.event=99;position.x=0;client.command(P.module,'step',position)
check(client.remote[2].step.x==1,'out-of-order sample cannot rewind a remote step')
clock=clock+400;client.updateStep(remote,client.remote[2])
check(client.remote[2].step==nil,'missing final sample cannot leave movement override running')
position.player=1;position.event=200;position.x=1
local localX=p.x;client.command(P.module,'step',position)
check(p.x==localX,'observer movement never rewrites the owning player')
repeated.seq=102;repeated.swing=9;repeated.action=12
local previousCycle=remote.vars.ProjectYakuzaRemoteCycle
client.command(P.module,'state',repeated)
check(remote.vars.ProjectYakuzaRemoteCycle~=previousCycle,'simultaneous swing and action increments still restart observer clip')
local effectCount=effects
client.command(P.module,'impact',{player=2,event=501,zombie=100,strong=true,reaction='enemy_03',style='dragon_of_dojima'})
check(client.deferred['impact:2:501']~=nil and effects==effectCount,'hit arriving before zombie streams in is retained')
local streamed=zombie(100,1)
clock=clock+50;client.tick()
check(client.deferred['impact:2:501']==nil and streamed.lastEvent=='wasHit' and effects==effectCount+1,'streamed victim receives one deferred reaction')
clock=clock+50;client.tick();check(effects==effectCount+1,'deferred reaction is not replayed twice')
client.command(P.module,'damage',{player=2,event=502,zombie=101,health=.2,style='dragon_of_dojima'})
clock=clock+800;client.tick()
check(client.deferred['damage:2:502']==nil,'unresolved zombie updates expire rather than accumulating')
ProjectYakuza.Quicksteps={facing=function()return 1,0 end}
local stepAction={started=true,context={action={animation='ProjectYakuza_DD_Quickstep01'}}}
outgoing={};local updates=p.nativeUpdates or 0
client.step(p,stepAction,false)
check(outgoing[#outgoing].command=='step' and p.nativeUpdates==updates+1,'quickstep uses exposed player setter to request native reliable position update')
local messages=#outgoing;client.step(p,stepAction,false)
check(#outgoing==messages,'quickstep progress transmission is limited to 20Hz')
client.step(p,stepAction,true)
check(#outgoing>messages and outgoing[#outgoing].args.finished,'terminal position bypasses progress throttle')
ProjectYakuza.FEATURES.grab=false;ProjectYakuza.styles.dragon_of_dojima.actions.grab.enabled=false
clock=clock+2000;snapshot(p);command('grabRequest',{zombie=z4.id})
check(not server.players[p.id].grab,'disabled server grab request cannot acquire a lease')

clock=clock+2000;snapshot(p,{clip='ProjectYakuza_DD_ChargedFinisher01',move='dd_charged_finisher_01',chargePower=.5})
check(server.players[1].packet.chargePower==.5,'server preserves a bounded partial charge')
local chargePrimary=zombie(150,p.x+1);local chargeExtra=zombie(151,p.x+1.1)
function chargeExtra:Hit(item,attacker,damage)self.received=damage;self.hits=self.hits+1 end
command('impact',{swing=1000,zombie=150})
command('extra',{swing=1000,zombie=151})
local base=math.min(2,(server.baseWeapon:getMinDamage()+server.baseWeapon:getMaxDamage())*.5)
check(chargeExtra.received and math.abs(chargeExtra.received-base*1.625)<.00001,'server extra victim receives partial-charge damage, not full power')
snapshot(p,{clip='ProjectYakuza_DD_ChargedFinisher01',move='dd_charged_finisher_01',chargePower=1})
check(server.players[1].swings[1000].move.damageMultiplier==1.625,'later snapshots cannot change power of an existing multihit swing')
snapshot(p,{clip='ProjectYakuza_DD_ChargedFinisher01',move='dd_charged_finisher_01',chargePower=.5})

local saved=server.players[1].seq;snapshot(p,{chargePower=2})
check(server.players[1].seq==saved,'server rejects charge above full power')
local halfMove=ProjectYakuza.styles.dragon_of_dojima.actions.chargedHeavy.variants.after_1
check(ProjectYakuza.ChargeRules.damage(halfMove,server.players[1].packet.chargePower)==1.625,'extra victims use the same partial damage rule')
local oldRemote=client.remote[2].packet.seq
local invalid={player=2,seq=oldRemote+1,style='dragon_of_dojima',equipped=true,heat=0,fuel=0,chargePower=0/0}
client.command(P.module,'state',invalid)
check(client.remote[2].packet.seq==oldRemote,'remote state rejects nonfinite charging power')

local H=ProjectYakuza.HitResponses;local R=ProjectYakuza.Reactions
local style=ProjectYakuza.getStyle('dragon_of_dojima')
local function copy(t)local v={};for k,x in pairs(t)do v[k]=x end;return v end
for i,move in ipairs(style.lightAttacks)do check(H.resolve(style,move).kind=='flinch','each light retains a short flinch '..i)end
local first=style.actions.finisher.variants.after_1
local second=style.actions.finisher.variants.double_after_1
local charged=copy(style.actions.chargedHeavy.variants.after_1)
check(H.resolve(style,first).kind=='stagger' and H.resolve(style,first).force==.65,'first finishers select native backward stagger')
check(H.resolve(style,second).kind=='knockdown','double finishers select knockdown')
for _,power in ipairs({0,.2,.5,.99})do charged.chargePower=power;check(H.resolve(style,charged).kind=='stagger','partial charges never get full-power knockdown')end
charged.chargePower=1;check(H.resolve(style,charged).kind=='knockdown' and H.resolve(style,charged).force==1,'full charge selects strongest knockdown')
charged.chargePower=0/0;check(H.resolve(style,charged).kind=='stagger','nonfinite charge cannot gain full-power response')
check(not H.resolve(style,style.groundAttacks[1]) and not H.resolve(style,style.actions.runningAttack.variants.knee),'ground/running behavior remains unchanged')
local custom=copy(first);custom.hitResponse=false;check(not H.resolve(style,custom),'a move can opt out')
custom.hitResponse='light';check(H.resolve(style,custom).kind=='flinch','a move can select a named custom profile')
local bad=copy(style);bad.hitResponses={broken={kind='teleport',force=2}}
check(not ProjectYakuza.validateStyle(bad),'style validation rejects unknown/unsafe response data')
bad.hitResponses={broken={kind='stagger',force=.5,fullChargeAt=2,fullChargeKind='knockdown',fullChargeForce=1}}
check(not ProjectYakuza.validateStyle(bad),'style validation rejects invalid full-charge thresholds')
bad.hitResponses={broken={kind='stagger',force=0/0}};check(not ProjectYakuza.validateStyle(bad),'style validation rejects NaN force')
local addon={lightAttacks=style.lightAttacks};check(not H.resolve(addon,first),'unconfigured addon styles do not inherit DoD responses')
R.clearAll();isClient=function()return false end
local function responseVictim(id)
 local v=zombie(id,p.x+1)
 function v:isOnFloor()return self.floor==true end;function v:isKnockedDown()return self.knock==true end
 return v
end
local v=responseVictim(200)
p.data.ProjectYakuzaStyle='dragon_of_dojima';p.equipped=true;p.hand=p.token
local combo=ProjectYakuza.stateFor(p);combo.active=true;combo.step=1;combo.finisherMove=first;combo.multiHitToken={}
local health=v.health;local hitCount=v.hits
R.onHit(p,v,p.token,.2)
check(R.pending[v] and not v.stagger,'native pre-damage event only stages the response')
v.health=v.health-.2;v.force=.1;R.tick()
check(v.stagger and v.force==.65 and v.reaction=='' and not v.knock,'deferred response survives native force calculation')
check(v.health==health-.2 and v.hits==hitCount and v.kills==nil and v.x==p.x+1,'response never damages, kills or teleports a zombie')
R.onHit(p,v,p.token,.2);check(not R.pending[v],'duplicate same-swing event cannot restart stagger')
combo.multiHitToken={};combo.finisherMove=second;R.onHit(p,v,p.token,.2);v.health=v.health-.2;R.tick()
check(v.knock and v.front==false and v.force==.85,'second finisher knocks a standing target down through native flags')
local floor=responseVictim(201);floor.floor=true
check(not H.apply(p,floor,{kind='knockdown',force=1}) and floor.knock==nil,'floor targets are never lifted or forced into a standing reaction')
local dead=responseVictim(202);dead.health=0;check(not H.apply(p,dead,{kind='stagger',force=1}),'native deaths take priority')
local blocked=responseVictim(203);combo.multiHitToken={};R.onHit(p,blocked,p.token,.2);R.tick()
check(blocked.force==nil and blocked.stagger==nil,'no health loss after a blocked native hit means no forced response')
combo.multiHitToken={};R.onHit(p,blocked,p.token,0);R.onHit(p,blocked,p.token,0/0)
check(not R.pending[blocked],'zero/NaN damage cannot schedule a response')
combo.multiHitToken={};combo.finisherMove=nil;R.onHit(p,blocked,p.token,.2);blocked.health=.8;R.tick()
check(blocked.vars.ProjectYakuzaEnemyHitClip=='enemy_01' and blocked.force==.25 and not blocked.stagger,'lights preserve supplied Y6 flinches instead of native heavy stagger')
local frozen=responseVictim(204);combo.multiHitToken={};combo.finisherMove=first;R.onHit(p,frozen,p.token,.2);frozen.health=.8
isGamePaused=function()return true end;R.tick();check(R.pending[frozen] and not frozen.stagger,'pause does not apply a pending response')
isGamePaused=function()return false end;R.tick();check(frozen.stagger,'pending response applies after resume')
R.clearAll();check(not R.hooked,'idle response controller removes its tick hook')
local expired=responseVictim(205);R.queue(p,expired,{kind='stagger',force=.65});clock=clock+1001;R.tick()
check(not expired.stagger and not R.hooked,'expired response cannot hit later or leave an idle hook')
local overlap=responseVictim(206);overlap.x=p.x;check(not H.apply(p,overlap,{kind='stagger',force=.65}),'overlapping origins avoid nonfinite knockback direction')
isClient=function()return true end
local authoritative=responseVictim(207);combo.multiHitToken={};combo.finisherMove=first
R.onHit(p,authoritative,p.token,.2);check(not R.pending[authoritative] and not authoritative.stagger,'MP hit waits for a server-confirmed physics response')
local beforeEffects=effects
local responsePacket={player=1,event=9001,zombie=207,style='dragon_of_dojima',reaction='enemy_01',responseKind='stagger',responseForce=.65}
client.command(P.module,'impact',responsePacket);R.tick()
check(authoritative.stagger and authoritative.force==.65 and effects==beforeEffects,'owning client accepts server response without duplicating its hit VFX')
client.command(P.module,'impact',responsePacket);check(not R.pending[authoritative],'duplicate server impact cannot queue another response')
local invalidTarget=responseVictim(208)
client.command(P.module,'impact',{player=1,event=9002,zombie=208,responseKind='knockdown',responseForce=12})
check(not R.pending[invalidTarget] and not invalidTarget.knock,'invalid packet force cannot force knockdown')

clock=clock+2000;server.reactions={};replies={}
snapshot(p,{move='dd_charged_finisher_01',clip='ProjectYakuza_DD_ChargedFinisher01',chargePower=.5})
local primary=responseVictim(209);local extra=responseVictim(210)
command('impact',{swing=1100,zombie=209});check(#server.reactions==1 and not primary.stagger,'server defers primary response until native processing has finished')
snapshot(p,{move='dd_charged_finisher_01',clip='ProjectYakuza_DD_ChargedFinisher01',chargePower=1})
command('extra',{swing=1100,zombie=210})
check(extra.stagger and not extra.knock and extra.force==.75 and extra.hits==1,'supplement uses locked partial power despite later full-charge snapshot')
clock=clock+101;server.tick()
check(primary.stagger and not primary.knock and primary.force==.75 and primary.hits==0,'primary uses the same locked partial response without reapplying damage')
local wire
for _,message in ipairs(replies)do if message.command=='impact' and message.args.zombie==209 then wire=message.args end end
check(wire and wire.responseKind=='stagger' and wire.responseForce==.75,'server fans out only its resolved response kind/force')
clock=clock+1100;snapshot(p,{move='dd_charged_finisher_01',clip='ProjectYakuza_DD_ChargedFinisher01',chargePower=1})
local full=responseVictim(211);command('impact',{swing=1101,zombie=211});clock=clock+101;server.tick()
check(full.knock and full.force==1 and full.hits==0,'full-charge primary knocks down without calling Hit')
local observer=responseVictim(212);observer.x=remote.x+1;local oldHits=observer.hits
client.command(P.module,'damage',{player=2,event=9003,zombie=212,health=.7,amount=.3,style='dragon_of_dojima',reaction='enemy_02',responseKind='knockdown',responseForce=.85})
R.tick();check(observer.knock and observer.health==.7 and observer.hits==oldHits,'observer applies native knockdown with absolute health only')
local lightVictim=responseVictim(213);combo.finisherMove=nil;combo.multiHitToken={}
R.onHit(p,lightVictim,p.token,.1);R.clearAll();check(lightVictim.vars.ProjectYakuzaEnemyReaction==false and not R.hooked,'world-exit cleanup releases all custom reaction flags and hooks')

local J=ProjectYakuza.Juggling
check(not style.juggling and not J.plan(style,style.lightAttacks[1]),'DoD has no juggling opt-in')
local future=copy(style);future.id='test.juggler';future.name='Test Juggler';future.actions={};future.lightAttacks={}
future.juggling={windowMs=500,maxDurationMs=1200,maxHits=3,maxRelaunches=1,landingCooldownMs=300,presentation='test.airborne'}
for i,move in ipairs(style.lightAttacks)do future.lightAttacks[i]=copy(move)end
future.lightAttacks[1].juggle={kind='launch'};future.lightAttacks[2].juggle={kind='followup'};future.lightAttacks[3].juggle={kind='ender'}
check(ProjectYakuza.validateStyle(future),'a future style can declare launcher/followup/ender moves')
future.juggling.enabled=false;check(ProjectYakuza.validateStyle(future) and not J.plan(future,future.lightAttacks[1]),'developers can disable a style juggle config without deleting its move declarations');future.juggling.enabled=true
ProjectYakuza.registerStyle(future);ProjectYakuza.NetworkCatalog[future.id]=ProjectYakuza.NetworkCatalog.dragon_of_dojima
local badFuture=copy(future);badFuture.juggling={maxHits=100};check(not ProjectYakuza.validateStyle(badFuture),'oversized juggle budgets rejected')
badFuture.juggling={windowMs=1500,maxDurationMs=1000};check(not ProjectYakuza.validateStyle(badFuture),'window cannot exceed hard duration')
badFuture.juggling=false;check(not ProjectYakuza.validateStyle(badFuture),'move spec requires a style opt-in')
badFuture=copy(future);badFuture.lightAttacks={copy(future.lightAttacks[1])};badFuture.lightAttacks[1].juggle={kind='teleport'}
check(not ProjectYakuza.validateStyle(badFuture),'unsupported juggle operations rejected')
badFuture.lightAttacks[1].juggle={kind='launch',windowMs=0/0};check(not ProjectYakuza.validateStyle(badFuture),'NaN window rejected')
local launch=J.plan(future,future.lightAttacks[1]);local follow=J.plan(future,future.lightAttacks[2]);local ending=J.plan(future,future.lightAttacks[3])
local unmarked=future.lightAttacks[4]
p.data.ProjectYakuzaStyle=future.id;combo.finisherMove=nil;combo.step=1;combo.active=true;combo.multiHitToken={}
R.clearAll();J.clearAll()
local jug=responseVictim(220);local priorX,priorY,priorHealth=jug.x,jug.y,jug.health
local a,active=J.hit(p,jug,follow,1);check(not a and not active and not J.get(jug),'followup cannot create a juggle')
a,active=J.hit(p,jug,launch,2)
check(a.phase=='launch' and active and J.get(jug).hits==0 and jug.vars.ProjectYakuzaJuggleActive,'launcher starts one bounded state and native animation variables')
check(jug.vars.ProjectYakuzaJugglePresentation=='test.airborne' and J.hooked,'addon presentation name and active-only tick hook are exposed')
check(jug.health==priorHealth and jug.x==priorX and jug.y==priorY and jug.hits==0,'logical launch never damages, lifts or teleports a zombie')
local stateView=J.get(jug);stateView.hits=100;check(J.get(jug).hits==0,'public state snapshot cannot mutate the hit budget')
a,active=J.hit(p,jug,follow,2);check(not a and active and J.get(jug).hits==0,'same-swing duplicate cannot count a juggling hit')
clock=clock+200;a,active=J.hit(p,jug,follow,3);check(a.phase=='hit' and active and J.get(jug).hits==1 and a.remaining==500,'followup refreshes only the soft window')
a,active=J.hit(p,jug,launch,4);check(active and J.get(jug).relaunches==1,'one configured relaunch is permitted')
a,active=J.hit(p,jug,launch,5);check(a.phase=='end' and a.reason=='relaunch_limit' and not active and not J.get(jug),'relaunch budget prevents infinite launcher loops')
check(not jug.vars.ProjectYakuzaJuggleActive,'ending clears victim presentation variables')
a=J.hit(p,jug,launch,6);check(not a and not J.get(jug),'landing cooldown prevents immediate restart')
clock=clock+301;J.hit(p,jug,launch,7);J.hit(p,jug,follow,8);J.hit(p,jug,follow,9);a,active=J.hit(p,jug,follow,10)
check(a.reason=='hit_limit' and not active and a.hits==3,'final permitted hit ends the juggle without adding damage')
clock=clock+301;J.hit(p,jug,launch,11);a,active=J.hit(p,jug,ending,12);check(a.reason=='ender' and not active,'landing ender closes the state')
clock=clock+301;J.hit(p,jug,launch,13);a=J.hit(p,jug,nil,14);check(a.reason=='unmarked_hit','unmarked attacks cannot keep an aerial window alive')
clock=clock+301;J.hit(p,jug,launch,15);a=J.hit(remote,jug,follow,16);check(a.reason=='interrupted','another player cannot take ownership of a juggle')
clock=clock+301;J.hit(p,jug,launch,17);clock=clock+501;J.tick();check(not J.get(jug) and not J.hooked,'soft timeout releases state and idle hook')
clock=clock+301;J.hit(p,jug,launch,18);local held=J.get(jug).remaining
isGamePaused=function()return true end;clock=clock+5000;J.tick();isGamePaused=function()return false end
check(J.get(jug).remaining==held,'pause-aware active tick preserves remaining window')
J.finish(jug,'test',false);clock=clock+301;J.hit(p,jug,launch,19);jug.floor=true;J.tick();check(not J.get(jug),'native landing immediately clears logical airborne state');jug.floor=false
clock=clock+301;J.hit(p,jug,launch,20);p.data.ProjectYakuzaStyle='dragon_of_dojima';J.tick();check(not J.get(jug),'style change cancels an active juggle');p.data.ProjectYakuzaStyle=future.id
clock=clock+301;J.hit(p,jug,launch,21);jug.health=0;J.tick();check(not J.get(jug),'native death clears state');jug.health=1
J.clearAll();local oldCap=J.maxTargets;J.maxTargets=1
local jug2=responseVictim(221);J.hit(p,jug,launch,22);J.hit(p,jug2,launch,23);check(not J.get(jug2),'tracked-target cap is enforced')
J.clearAll();J.maxTargets=oldCap
J.clearAll();J.hit(p,jug,launch,30);local hardDeadline=J.states[jug].hardEnd
clock=clock+400;J.hit(p,jug,follow,31);clock=clock+400;J.hit(p,jug,follow,32)
check(J.states[jug].hardEnd==hardDeadline and J.get(jug).remaining==400,'refresh never extends the hard juggling deadline')
clock=clock+401;J.tick();check(not J.get(jug),'hard deadline ends repeated refreshes')
J.clearAll()

isClient=function()return false end;combo.step=1;combo.multiHitToken={};jug.health=1
R.onHit(p,jug,p.token,.1);check(not J.get(jug) and R.pending[jug],'SP launcher waits until native hit returns')
jug.health=.9;R.tick();check(J.get(jug) and not jug.knock,'SP launcher opens the window after confirmed health loss')
check(jug.vars.ProjectYakuzaEnemyReaction==false and not R.states[jug],'juggle presentation replaces the ordinary custom flinch controller')
combo.step=2;combo.multiHitToken={};R.onHit(p,jug,p.token,.1);jug.health=.8;R.tick();check(J.get(jug).hits==1,'SP followup is counted once through the real hit pipeline')
combo.step=3;combo.multiHitToken={};R.onHit(p,jug,p.token,.1);jug.health=.7;R.tick();check(not J.get(jug),'SP ender closes the real pipeline state')
J.clearAll();R.clearAll();isClient=function()return true end

clock=clock+2000;server.reactions={};snapshot(p,{style=future.id,move='dd_light_01',clip='ProjectYakuza_DD_Light01'})
local networkJug=responseVictim(222);replies={};command('impact',{swing=1200,zombie=222});clock=clock+101;server.tick()
check(J.get(networkJug) and networkJug.hits==0,'MP primary launcher never calls Hit again')
local launchPacket
for _,message in ipairs(replies)do if message.command=='impact' and message.args.zombie==222 then launchPacket=message.args end end
check(launchPacket and launchPacket.juggle.phase=='launch','server window result is included in impact relay')
local hits=networkJug.hits;J.clearAll();client.command(P.module,'impact',launchPacket)
check(J.get(networkJug) and networkJug.hits==hits,'owner mirrors window result without replaying damage')
local oldSeq=J.received[networkJug];client.command(P.module,'impact',launchPacket);check(J.received[networkJug]==oldSeq,'duplicate impact cannot restart an observer window')
local malformed=copy(launchPacket.juggle);malformed.seq=malformed.seq+1;malformed.hits=13
check(not J.receive(p,networkJug,malformed) and J.received[networkJug]==oldSeq,'invalid juggle counters rejected before mutation')
local endPacket=copy(launchPacket.juggle);endPacket.seq=endPacket.seq+2;endPacket.phase='end';endPacket.reason='timeout'
client.command(P.module,'juggle',{player=1,zombie=222,event=endPacket.seq,juggle=endPacket})
check(not J.get(networkJug) and not networkJug.vars.ProjectYakuzaJuggleActive,'standalone timeout/landing result clears the observer')
check(not J.receive(p,networkJug,launchPacket.juggle) and not J.get(networkJug),'late launch cannot revive a state after a newer landing result')
J.clearAll();R.clearAll();p.data.ProjectYakuzaStyle='dragon_of_dojima'
local observer=player(50,0);observer.localPlayer=false
local fxClears,chargeClears=0,0
ProjectYakuza.AttackEffects={remote=function()end,clear=function(who)fxClears=fxClears+1;who.attackCleared=true end}
ProjectYakuza.ChargeEffects={clear=function(who)chargeClears=chargeClears+1;who.chargeCleared=true end}
local peer={player=50,session=1000,seq=900,style='dragon_of_dojima',equipped=true,heat=40,fuel=30,extreme=true,clip='ProjectYakuza_DD_Finisher01',move='dd_finisher_01',swing=10,action=10}
client.command(P.module,'state',peer)
local cycle=observer.vars.ProjectYakuzaRemoteCycle
peer=copy(peer);peer.seq=901;peer.action=11;client.command(P.module,'state',peer)
check(observer.vars.ProjectYakuzaRemoteCycle==cycle,'late action-context counter cannot restart a melee finisher')
peer=copy(peer);peer.seq=902;peer.swing=11;client.command(P.module,'state',peer)
check(observer.vars.ProjectYakuzaRemoteCycle~=cycle,'a new melee swing restarts the same supplied clip')
peer=copy(peer);peer.seq=903;peer.clip='ProjectYakuza_DD_HeatRush';peer.move='dd_heat_rush';client.command(P.module,'state',peer);cycle=observer.vars.ProjectYakuzaRemoteCycle
peer=copy(peer);peer.seq=904;peer.swing=12;client.command(P.module,'state',peer)
check(observer.vars.ProjectYakuzaRemoteCycle==cycle,'unrelated swing counter cannot restart a paired Heat Rush')
peer=copy(peer);peer.seq=905;peer.action=12;client.command(P.module,'state',peer)
check(observer.vars.ProjectYakuzaRemoteCycle~=cycle,'new timed-action serial restarts repeated paired action')
client.seen['damage:50:1']=clock;client.seen['heatRush:50:12:1']=clock;client.seen['damage:2:1']=clock
client.deferred['damage:50:2']={args={player=50},expires=clock+750}
peer=copy(peer);peer.seq=1;peer.session=1001;peer.action=1;peer.swing=1;client.command(P.module,'state',peer)
check(client.remote[50].packet.seq==1 and client.sessions[50]==1001,'new server session accepts restarted player sequence')
check(not client.seen['damage:50:1']and not client.seen['heatRush:50:12:1']and not client.deferred['damage:50:2']and client.seen['damage:2:1'],'new session clears only that peer replay/deferred caches')
local accepted=client.remote[50].packet
local oldPeer=copy(peer);oldPeer.session=1000;oldPeer.seq=999;client.command(P.module,'state',oldPeer)
check(client.remote[50].packet==accepted,'late old-session snapshot cannot overwrite respawn state')
local oldEffects=effects
client.command(P.module,'damage',{player=50,session=1000,zombie=z1.id,event=999,health=0,amount=1})
check(effects==oldEffects and client.sessions[50]==1001,'late old-session damage is discarded')
check(not client.acceptSession(50,0/0)and client.sessions[50]==1001,'invalid session cannot reset peer state')
local replacement=player(50,0);replacement.localPlayer=false
peer=copy(peer);peer.seq=0;client.command(P.module,'state',peer)
check(client.remote[50].actor==replacement and client.remote[50].packet.seq==0,'streamed replacement actor cannot inherit stale sequence rejection')
check(observer.attackCleared and observer.chargeCleared and not ProjectYakuza.Heat.states[observer],'previous actor effects and heat are released')
replacement.vars.ProjectYakuzaWeaponProfile='blade';replacement.vars.ProjectYakuzaRemoteChargePower='1';replacement.vars.ProjectYakuzaLinkedDouble=true
client.clearRemote(50)
check(not client.remote[50]and replacement.vars.ProjectYakuzaWeaponProfile==''and replacement.vars.ProjectYakuzaRemoteChargePower=='0'and replacement.vars.ProjectYakuzaLinkedDouble==false,'stale cleanup releases profile/charge/link flags')
check(replacement.attackCleared and replacement.chargeCleared and not ProjectYakuza.Heat.states[replacement],'stale cleanup releases limb effects and heat state')
peer=copy(peer);peer.seq=10;client.command(P.module,'state',peer)
local unavailable=copy(peer);unavailable.seq=11;unavailable.style='tests.not_installed';client.command(P.module,'state',unavailable)
check(not client.remote[50]and not ProjectYakuza.isEquipped(replacement),'missing addon style clears its observer without invoking incompatible aura/UI')
local originalPeer=player(60,0);snapshot(originalPeer);local firstSession=server.players[60].session
originalPeer.ghost=true;originalPeer.invincible=true;server.players[60].protection={ghost=false,invincible=false,expires=clock+3000}
local secondPeer=player(60,0);snapshot(secondPeer)
check(server.players[60].session>firstSession and server.players[60].packet.session==server.players[60].session,'server assigns fresh monotonic sessions to recycled player IDs')
check(not originalPeer.ghost and not originalPeer.invincible,'replacing a player actor releases its previous temporary protection')
replies={};server.fanout(originalPeer,'state',{player=60})
check(#replies==0,'old actor cannot fan out with replacement session')
server.fanout(secondPeer,'state',{player=60})
check(#replies>0 and replies[1].args.session==server.players[60].session,'server relays tag the authoritative current session')
client.clear();local sessionCount=0;for _ in pairs(client.sessions)do sessionCount=sessionCount+1 end;check(sessionCount==0,'world exit clears session ownership')
for _,z in ipairs(zombies)do
 z.health=0
 function z:addAggro(who,amount)self.aggro=(self.aggro or 0)+amount;self.aggroTarget=who end
end
p:setPrimaryHandItem(p.token);p.data.ProjectYakuzaStyle='dragon_of_dojima';server.players[p.id]=nil;clock=clock+2000
z1.health=100;z1.aggro=0;z1.attacking=false;z1.x=.8;z1.y=0;z1.target=nil
z2.health=100;z2.x=8;z3.health=100;z3.attacking=true;z4.health=100;z4.floor=true
function z4:isOnFloor()return self.floor==true end
snapshot(p,{clip='ProjectYakuza_DD_Taunt01',action=2000,taunt=0});local tauntState=server.players[p.id]
check(tauntState.tauntLease and tauntState.tauntLease.action==2000,'server observes source taunt action before authorizing reactions')
clock=clock+900;snapshot(p,{clip='',action=2000,taunt=1})
check(z1.aggro==0 and not tauntState.tauntLease,'too-early completion cannot draw zombie attention')
snapshot(p,{clip='ProjectYakuza_DD_Taunt01',action=2001,taunt=1});clock=clock+1850;replies={};local nativeHits=z1.hits
snapshot(p,{clip='',action=2001,taunt=2})
check(z1.aggro==3 and z1.target==p and z1.hits==nativeHits,'completed taunt adds native aggro without dealing damage')
check(not z2.aggro and not z3.aggro and not z4.aggro,'taunt skips distant, attacking and downed zombies')
local tauntPacket
for _,message in ipairs(replies)do if message.command=='taunt'then tauntPacket=message.args end end
check(tauntPacket and #tauntPacket.zombies==1 and tauntPacket.zombies[1]==z1.id,'server chooses and bounds taunt victim IDs')
snapshot(p,{clip='',action=2001,taunt=2});snapshot(p,{clip='',action=2001,taunt=3})
check(z1.aggro==3,'heartbeat/replayed completion cannot repeat native aggro')
client.command(P.module,'taunt',tauntPacket);client.command(P.module,'taunt',tauntPacket)
check(z1.aggro==6,'zombie-owning client applies each authorized taunt once')
local remoteTaunt=copy(tauntPacket);remoteTaunt.event=remoteTaunt.event+100;z1.remote=true;client.command(P.module,'taunt',remoteTaunt)
check(z1.aggro==6,'non-owning client does not override zombie AI');z1.remote=false
snapshot(p,{clip='ProjectYakuza_DD_Taunt01',action=2002,taunt=3});clock=clock+1850;z1.x=1.1;wall=true;snapshot(p,{clip='',action=2002,taunt=4});wall=false;z1.x=.8
check(z1.aggro==6,'blocked taunt paths do not acquire targets')
local missingTaunt=copy(tauntPacket);missingTaunt.event=missingTaunt.event+200;missingTaunt.zombies={1500};client.command(P.module,'taunt',missingTaunt)
local missingKey='taunt:'..p.id..':'..missingTaunt.event
check(client.deferred[missingKey]~=nil,'streaming-delayed taunt target is retained briefly')
local arriving=zombie(1500,.9);function arriving:addAggro(who,amount)self.aggro=(self.aggro or 0)+amount;self.target=who end
clock=clock+50;client.tick();check(arriving.aggro==3 and not client.deferred[missingKey],'native owner applies a streamed-in taunt target once')
clock=clock+50;client.tick();check(arriving.aggro==3,'deferred taunt cannot duplicate attention')
local cfg=ProjectYakuza.TauntReactions.config(ProjectYakuza.getStyle('dragon_of_dojima'));local pathCalls=0;local oldPath=P.path
P.path=function()pathCalls=pathCalls+1;return false end
for i=1,300 do local v=zombie(1600+i,.5);v.y=.2 end
local blockedTargets=ProjectYakuza.TauntReactions.targets(p,cfg)
check(#blockedTargets==0 and pathCalls<=32,'dense taunt path checks have a hard per-completion budget')
P.path=oldPath
check(not ProjectYakuza.TauntReactions.config({actions={},tauntReactions={radius=5,maxTargets=8}}),'other styles need an enabled taunt and explicit opt-in')
clock=clock+2000;replies={};snapshot(p)
command('sfx',{cue='ProjectYakuza_Y6_PunchSwing',index=2,gain=.65})
local soundPacket
for _,message in ipairs(replies)do if message.command=='sfx'then soundPacket=message.args end end
check(soundPacket and soundPacket.index==2 and soundPacket.gain==.65,'server relays a selected supplied SFX clip and existing gain')
local sent=#replies
command('sfx',{cue='ProjectYakuza_FunkGoesOn',index=1,gain=1});command('sfx',{cue='ProjectYakuza_Y6_PunchSwing',index=99,gain=.65});command('sfx',{cue='ProjectYakuza_Y6_PunchSwing',index=1,gain=2})
check(#replies==sent,'music, unregistered clips and excessive gains cannot be broadcast as combat SFX')
for i=1,13 do command('sfx',{cue='ProjectYakuza_Y6_PunchSwing',index=1,gain=.65})end
local soundResults=0;for _,message in ipairs(replies)do if message.to==p and message.command=='sfx'then soundResults=soundResults+1 end end
check(soundResults==12,'combat SFX have a separate twelve-per-second actor budget')
local variety=ProjectYakuza.SoundVariety;local oldPlay=variety.play;local heard=0;local heardIndex
variety.play=function(who,style,cue,index,gain)heard=heard+1;heardIndex=index;return 1 end
local remoteSound=copy(soundPacket);remoteSound.player=2;remoteSound.session=3000;remoteSound.event=999000
client.command(P.module,'sfx',remoteSound);client.command(P.module,'sfx',remoteSound)
check(heard==1 and heardIndex==2,'remote listener plays the exact selected clip once')
client.command(P.module,'sfx',soundPacket);check(heard==1,'owner echo cannot double its local SFX')
remoteSound=copy(remoteSound);remoteSound.event=999001;remoteSound.index=99;client.command(P.module,'sfx',remoteSound)
check(heard==1,'remote invalid clip cannot invoke playback')
variety.play=oldPlay
clock=clock+2000;p.x=0;p.y=0;p.equipped=true;p.hand=p.token;p.dead=false;p.data.ProjectYakuzaStyle='dragon_of_dojima';z1.x=1.1;z1.y=0;z1.health=10;z1.useless=false;z1.ignore=false;z1.deferred=true;z1.attacking=false
snapshot(p,{extreme=true,clip='ProjectYakuza_DD_BoostLight04',move='dd_boost_light_04',swing=1600})
local hs=server.players[p.id];local rush=ProjectYakuza.HeatRushServer;local rules=ProjectYakuza.HeatRushRules
hs.rushCount=0;command('heatRushBegin',{zombie=z1.id,request=1});check(not rush.leases[p],'MP QTE sequence requires eight confirmed boost contacts')
local boost=ProjectYakuza.getStyle('dragon_of_dojima').extremeLightAttacks[1]
local definition=ProjectYakuza.getStyle('dragon_of_dojima')
for i=1,8 do
 local move=definition.extremeLightAttacks[i]
 rush.input(hs,{equipped=true,extreme=true,weaponProfile='',swing=1700+i},definition,move);clock=clock+50
end
check(hs.rushCount==8 and not hs.rushVictim,'eight observed boost inputs qualify even when all earlier attacks miss')
rush.record(p,hs,{extreme=true,profile='',move=boost,style=definition.id},z1,1708)
check(hs.rushVictim==z1.id and hs.rushCount==8,'only the eighth input needs a native impact')
z2.health=10;z2.x=1.2;z2.y=0;z2.useless=false;z2.attacking=false
rush.record(p,hs,{extreme=true,profile='',move=boost,style=definition.id},z2,1708)
check(hs.rushVictim==z2.id and hs.rushCount==8,'last eighth-strike target replaces earlier targets without inflating the input counter')
rush.record(p,hs,{extreme=true,profile='',move=boost,style=definition.id},z1,1708)
z1.x=1.65;check(rules.validTarget(p,z1),'server accepts the same post-hit handoff margin as the owner')
wall=true;command('heatRushBegin',{zombie=z1.id,request=2});check(not rush.leases[p],'paired source motion cannot start through walls');wall=false
command('heatRushBegin',{zombie=z1.id,request=3});local lease=rush.leases[p];check(lease and rush.held[z1]==lease,'server grants one target/action lease')
command('heatRushReady',{action=lease.action});check(lease.started and z1.useless and z1.ignore,'server owns paired victim lock only after ready')
local before=z1.hits;command('heatRushHit',{action=lease.action,index=1,damage=999});check(z1.hits==before,'no QTE input means no hit')
for i,prompt in ipairs(lease.definition.prompts)do
 clock=lease.started+prompt.atMs-100;snapshot(p,{extreme=true,clip='ProjectYakuza_DD_HeatRush',move='dd_heat_rush',action=lease.action,swing=1800})
 command('heatRushPress',{action=lease.action,index=i});check(lease.presses[i],'source-time prompt accepted '..i)
 command('heatRushHit',{action=lease.action+1,index=i});check(z1.hits==before+i-1,'wrong action serial rejects QTE damage')
 clock=lease.started+prompt.atMs+10;command('heatRushHit',{action=lease.action,index=i,damage=999})
 check(z1.hits==before+i,'successful timed prompt applies exactly one canonical server hit')
 command('heatRushHit',{action=lease.action,index=i});check(z1.hits==before+i,'replayed QTE hit cannot duplicate damage')
end
check(math.abs(z1.health-7.75)<.000001,'server ignores arbitrary client damage and applies one Extreme bonus')
clock=lease.started+rules.duration*1000+10;command('heatRushEnd',{action=lease.action,completed=true})
check(not rush.leases[p]and not rush.held[z1]and not z1.useless and not z1.ignore and z1.deferred and z1.knock,'server completion restores victim state and terminal knockdown')
command('heatRushHit',{action=lease.action,index=3});check(z1.hits==before+3,'ended action cannot replay a QTE hit')
clock=clock+2000;p.x=0;p.y=0;p.equipped=true;p.hand=p.token;p.dead=false;p.data.ProjectYakuzaStyle='dragon_of_dojima'
snapshot(p,{clip='ProjectYakuza_DD_Light01',move='dd_light_01',swing=2100})
local speedPeer=server.players[p.id];check(speedPeer.packet.attackHeatSpeed==nil,'DoD server snapshots keep the heat-speed feature absent')
local speedStyle=ProjectYakuza.getStyle('dragon_of_dojima');check(speedStyle.heatAttackSpeed==nil,'current production style has no heat curve')
speedStyle.heatAttackSpeed={max=1.5}
snapshot(p,{clip='ProjectYakuza_DD_Light01',move='dd_light_01',swing=2101,heat=50,attackHeatSpeed=1.25})
check(speedPeer.packet.attackHeatSpeed==1.25,'opted-in style relays its captured attack multiplier')
snapshot(p,{clip='ProjectYakuza_DD_Light01',move='dd_light_01',swing=2101,heat=100,attackHeatSpeed=1.25})
check(speedPeer.packet.heat==100 and speedPeer.packet.attackHeatSpeed==1.25,'Heat may change while the current attack speed stays captured')
local speedSeq=speedPeer.seq
snapshot(p,{clip='ProjectYakuza_DD_Light01',move='dd_light_01',swing=2101,heat=100,attackHeatSpeed=1.5})
check(speedPeer.seq==speedSeq,'same attack cannot change its speed through a new packet')
snapshot(p,{clip='ProjectYakuza_DD_Light02',move='dd_light_02',swing=2102,attackHeatSpeed=2})
check(speedPeer.seq==speedSeq,'server rejects speed above the registered curve')
snapshot(p,{clip='ProjectYakuza_DD_Light02',move='dd_light_02',swing=2102,attackHeatSpeed=0/0})
check(speedPeer.seq==speedSeq,'server rejects nonfinite speed')
snapshot(p,{clip='ProjectYakuza_DD_Light02',move='dd_light_02',swing=2102,attackHeatSpeed=1.5})
check(speedPeer.packet.attackHeatSpeed==1.5,'next native attack may use the new heat value')
local oldPlayback=ProjectYakuza.Heat.playback;local receivedSpeed
ProjectYakuza.Heat.playback=function(who,extreme,factor)receivedSpeed=factor;who.speed=1.6*(extreme and 1.2 or 1)*(factor or 1)end
local remoteCurve={player=2,seq=10000,style='dragon_of_dojima',weaponProfile='',equipped=true,heat=50,fuel=0,extreme=false,clip='ProjectYakuza_DD_Light01',move='dd_light_01',swing=9000,action=0,attackHeatSpeed=1.25}
client.command(P.module,'state',remoteCurve);check(receivedSpeed==1.25 and remote.speed==2,'remote observer uses the relayed factor')
remoteCurve=copy(remoteCurve);remoteCurve.seq=10001;remoteCurve.heat=100;client.command(P.module,'state',remoteCurve);check(remote.speed==2,'remote Heat changes do not resample attack speed')
remoteCurve=copy(remoteCurve);remoteCurve.seq=10002;remoteCurve.attackHeatSpeed=10;client.command(P.module,'state',remoteCurve)
check(client.remote[2].packet.seq==10001,'observer rejects out-of-bounds factors')
ProjectYakuza.Heat.playback=oldPlayback;speedStyle.heatAttackSpeed=nil
local current=speedPeer.seq;snapshot(p,{clip='ProjectYakuza_DD_Light03',move='dd_light_03',swing=2103,attackHeatSpeed=1.5})
check(speedPeer.seq==current,'unconfigured style cannot use the speed feature')
snapshot(p,{clip='ProjectYakuza_DD_Light03',move='dd_light_03',swing=2103})
check(speedPeer.packet.attackHeatSpeed==nil,'opting out restores old packet shape')
;(function()
do
 local style=ProjectYakuza.getStyle('dragon_of_dojima')
 ProjectYakuza.registerStyle(style)
 local function baseline(view,clip)
  local actionAnim
  for _,c in ipairs(clip.conditions)do if c.name=='PerformingAction'then actionAnim=c.value end end
  for _,move in ipairs(view.lightAttacks or {})do if move.animation==clip.animation then return true end end
  for _,move in ipairs(view.extremeLightAttacks or {})do if move.animation==clip.animation then return true end end
  for _,move in pairs(view.directionalAttacks and view.directionalAttacks.moves or {})do if move.animation==clip.animation then return true end end
  for _,move in ipairs(view.groundAttacks or {})do if move.animation==clip.animation then return true end end
  for _,slot in pairs(view.actions)do
   if slot.enabled and slot.animation==(actionAnim or clip.animation)then return true end
   if slot.enabled then for _,move in pairs(slot.variants or {})do if move.enabled~=false and move.animation==(actionAnim or clip.animation)then return true end end end
  end
  return false
 end
 for _,clip in ipairs(ProjectYakuza.NetworkCatalog[style.id])do check(P.supports(style,clip)==baseline(style,clip),'indexed support agrees with source catalogue '..clip.id)end
 local clip=P.clip(style.id,'ProjectYakuza_DD_StyleEntry');P.supports(style,clip);P.kind(style.id,clip.id)
 local originalPairs,originalIpairs=pairs,ipairs;local scans=0
 pairs=function(t)if t==style.actions then scans=scans+1 end;return originalPairs(t)end
 ipairs=function(t)if t==style.lightAttacks or t==style.extremeLightAttacks or t==style.groundAttacks then scans=scans+1 end;return originalIpairs(t)end
 for n=1,1000 do check(P.supports(style,clip)and P.kind(style.id,clip.id)=='styleEntry','warm indexed action support')end
 pairs=originalPairs;ipairs=originalIpairs
 check(scans==0,'1000 warm action/support lookups do not rescan definition arrays')
 local slot=style.actions.styleEntry;local enabled=slot.enabled;slot.enabled=false
 ProjectYakuza.registerStyle(style)
 check(not P.supports(style,clip),'official same-table registration invalidates definition index')
 check(P.kind(style.id,clip.id)=='styleEntry','disabled action metadata remains available')
 slot.enabled=enabled;ProjectYakuza.registerStyle(style)
 check(P.supports(style,clip),'restored registered action rebuilds support')
end
do
 local oldCell=getCell;local grid,calls,collisions={},0,{}
 local missing,solid,trans,floorless,blocked
 local function key(x,y)return x..':'..y end
 local function square(x,y)
  local k=key(x,y)
  if not grid[k]then grid[k]={TreatAsSolidFloor=function()return floorless~=k end,isSolid=function()return solid==k end,isSolidTrans=function()return trans==k end,
   testCollideAdjacent=function(_,who,dx,dy)collisions[#collisions+1]=k..':'..dx..':'..dy;return blocked==k end}end
  return grid[k]
 end
 getCell=function()return {getGridSquare=function(_,x,y,z)calls=calls+1;if key(x,y)==missing then return nil end;return square(x,y)end}end
 local actor={x=.2,y=.2,getX=function(self)return self.x end,getY=function(self)return self.y end,getZ=function()return 0 end}
 local function oldPath(p,x,y)
  local sx,sy=p:getX(),p:getY();local dx,dy=x-sx,y-sy;local length=math.sqrt(dx*dx+dy*dy)
  if length<.001 then return true end
  local cell=getCell();local z=math.floor(p:getZ());local steps=math.ceil(length/.08)
  for i=1,steps do
   local nx,ny=p:getX()+dx*i/steps,p:getY()+dy*i/steps
   local a=cell:getGridSquare(math.floor(sx),math.floor(sy),z);local b=cell:getGridSquare(math.floor(nx),math.floor(ny),z)
   if not a or not b or not b:TreatAsSolidFloor()or b:isSolid()or b:isSolidTrans()then return false end
   local tx,ty=math.floor(nx)-math.floor(sx),math.floor(ny)-math.floor(sy)
   if (tx~=0 or ty~=0)and a:testCollideAdjacent(p,tx,ty,0)then return false end
   sx,sy=nx,ny
  end
  return true
 end
 for case=1,6 do
  missing=case==2 and '1:0'or nil;solid=case==3 and '0:0'or nil;trans=case==4 and '-1:0'or nil;floorless=case==5 and '0:1'or nil;blocked=case==6 and '0:0'or nil
  for origin=1,3 do
   actor.x=origin==1 and .2 or origin==2 and .99 or -.03;actor.y=origin==1 and .4 or origin==2 and .01 or -.98
   for direction=1,16 do
    local a=direction*math.pi/8;local x,y=actor.x+math.cos(a)*1.8,actor.y+math.sin(a)*1.8
    collisions={};local expected=oldPath(actor,x,y);local crossing=table.concat(collisions,',')
    collisions={};local actual=P.path(actor,x,y)
    check(actual==expected and table.concat(collisions,',')==crossing,'path result and wall crossing match in all directions')
   end
  end
 end
 missing=nil;solid=nil;trans=nil;floorless=nil;blocked=nil;actor.x=.2;actor.y=.2
 calls=0;oldPath(actor,1.8,.2);local oldCalls=calls
 calls=0;check(P.path(actor,1.8,.2),'optimized open path stays valid');local newCalls=calls
 check(oldCalls==40 and newCalls==2,'1.6-tile path reduces grid lookups from 40 to 2')
 local wanted=zombie(300,.3);local centre=0
 getCell=function()return {getGridSquare=function(_,x,y,z)centre=centre+1;return {getMovingObjects=function()return list(x==0 and y==0 and {wanted}or {})end}end}end
 check(P.zombie(actor,300)==wanted and centre==1,'nearest tile is checked first for a nearby zombie')
 centre=0;check(not P.zombie(actor,301)and centre==49,'unknown zombie search retains full 49-tile limit')
 getCell=oldCell
end
do
 local n=client.localState(p);local oldEquipped,oldStyle,oldState=ProjectYakuza.isEquipped,ProjectYakuza.getPlayerStyle,ProjectYakuza.stateFor
 local style=ProjectYakuza.getStyle('dragon_of_dojima');local equipped=true;local combo={active=false,step=1}
 ProjectYakuza.isEquipped=function()return equipped end;ProjectYakuza.getPlayerStyle=function()return style end;ProjectYakuza.stateFor=function()return combo end
 n.equipReady=p:getPrimaryHandItem();n.equipStyle=style.id;n.equipWanted=nil;n.equipReply=nil;n.lastPacket=nil;n.heartbeat=0;n.hello=true;n.nextCapture=0
 local function countStates()local total=0;for _,message in ipairs(outgoing)do if message.command=='state'then total=total+1 end end;return total end
 local before=countStates();client.capture(p,true);check(countStates()==before+1,'first active snapshot sends immediately')
 clock=clock+60;client.capture(p);check(countStates()==before+1,'unchanged typed snapshot is suppressed')
 combo.groundMove=style.lightAttacks[1];clock=clock+60;client.capture(p)
 check(countStates()==before+2,'ground-state-only changes cannot be hidden by snapshot comparison')
 equipped=false;clock=clock+60;client.capture(p);local start=clock;before=countStates()
 for i=1,29 do clock=start+i*100;client.capture(p)end
 check(countStates()==before,'inactive heartbeat has no intermediate one-second sends')
 clock=start+3000;client.capture(p);check(countStates()==before+1,'inactive heartbeat is retained at three seconds')
 equipped=true;clock=clock+60;client.capture(p);check(countStates()==before+2,'reactivation sends without waiting for inactive heartbeat')
 ProjectYakuza.isEquipped=oldEquipped;ProjectYakuza.getPlayerStyle=oldStyle;ProjectYakuza.stateFor=oldState
end


do
 local hook=client.protectionHook;local hookCalls=0
 client.protectionHook=function()hookCalls=hookCalls+1;return hook()end
 local packet=copy(client.remote[2].packet);packet.attackHeatSpeed=nil;packet.protected=false;packet.seq=packet.seq+100
 client.command(P.module,'state',packet);hookCalls=0
 for i=1,5 do local a=copy(packet);a.seq=packet.seq+i;client.command(P.module,'state',a)end
 check(hookCalls==0,'unchanged protection heartbeats do not rescan every remote actor')
 packet=copy(packet);packet.seq=packet.seq+6;packet.protected=true;client.command(P.module,'state',packet)
 check(hookCalls==1,'protection transition still synchronizes zombie hook')
 packet=copy(packet);packet.seq=packet.seq+1;packet.protected=false;client.command(P.module,'state',packet)
 check(hookCalls==2,'protection ending still removes the zombie hook')
 client.protectionHook=hook
 local command=client.command;local deferred=client.deferred;local nextRetry,nextRemote=client.nextDeferred,client.nextRemote;local calls=0
 client.deferred={first={command='audit',args={},expires=clock+100},second={command='audit',args={},expires=clock+100}}
 client.nextDeferred=0;client.nextRemote=clock+1000
 client.command=function()calls=calls+1;client.deferred={}end
 client.tick();check(calls==1,'retry batch skips entries removed by lifecycle cleanup')
 client.command=command;client.deferred=deferred;client.nextDeferred=nextRetry;client.nextRemote=nextRemote
end


do
 local style=ProjectYakuza.getStyle('dragon_of_dojima');local original=style.heatConfig
 style.heatConfig={maxStocks=2};ProjectYakuza.registerStyle(style)
 clock=clock+2000;snapshot(p,{clip='ProjectYakuza_DD_Light01',move='dd_light_01',heat=30})
 snapshot(p,{clip='ProjectYakuza_DD_HeatActivate01',move='dd_light_01',heat=30,action=15000})
 check(not server.players[p.id].protection,'server uses custom stock cost before granting activation protection')
 snapshot(p,{clip='ProjectYakuza_DD_Light01',move='dd_light_01',heat=60})
 snapshot(p,{clip='ProjectYakuza_DD_HeatActivate01',move='dd_light_01',heat=60,action=15001})
 check(server.players[p.id].protection~=nil,'server accepts activation at custom stock threshold')
 server.restoreProtection(p,server.players[p.id]);style.heatConfig=original;ProjectYakuza.registerStyle(style)
end

end)()

do
 local rush=ProjectYakuza.HeatRushServer;local definition=ProjectYakuza.getStyle('dragon_of_dojima')
 clock=clock+3000;p.x=0;p.y=0;p.equipped=true;p.hand=p.token;p.dead=false;remote.x=1.1;remote.y=0;remote.health=10;remote.ghost=false;remote.invincible=false
 function p:getSafety()return {isEnabled=function()return false end}end;function p:isFactionPvp()return false end;function p:getHitReaction()return ''end
 function remote:isGodMod()return false end;function remote:getSafety()return {isEnabled=function()return false end}end;function remote:isFactionPvp()return false end
 function remote:isOnFloor()return false end;function remote:isKnockedDown()return false end;function remote:isClimbing()return false end
 function remote:isBlockMovement()return self.blocked==true end;function remote:setBlockMovement(v)self.blocked=v end
 function remote:isAuthorizeMeleeAction()return self.authorize~=false end;function remote:setAuthorizeMeleeAction(v)self.authorize=v end
 function remote:getIgnoreMovement()return self.ignore==true end;function remote:isDeferredMovementEnabled()return self.deferred~=false end;function remote:setDeferredMovementEnabled(v)self.deferred=v end
 function remote:setHitReaction(v)self.reaction=v end;function remote:getHitReaction()return self.reaction or''end;function remote:reportEvent(v)self.event=v end
 function remote:Hit(item,attacker,amount)check(item==p.token and attacker==p,'MP player QTE uses the held native item and correct attacker');self.playerDamage=(self.playerDamage or 0)+amount end
 function remote:getTarget()error('MP paired player must not call zombie target APIs')end
 local pvp=true;getServerOptions=function()return {getBoolean=function(_,key)return key=='PVP'and pvp or key=='SafetySystem' end}end
 NonPvpZone={getNonPvpZone=function()return nil end};Faction={getPlayerFaction=function()return nil end}
 for i=1,8 do local move=definition.extremeLightAttacks[i];snapshot(p,{extreme=true,clip=move.animation,move=move.nodeValue,swing=5000+i})end
 local proof=server.players[p.id];check(proof.rushCount==8,'real state snapshots prove eight inputs without native impacts')
 pvp=false;command('heatRushPlayerHit',{swing=5008,zombie=remote.id});check(not proof.rushVictim,'PvP-off player impact cannot provide a target')
 pvp=true;command('heatRushPlayerHit',{swing=5008,zombie=remote.id});check(proof.rushVictim==remote.id and proof.rushTargetKind=='player','eighth native player contact is typed and recorded')
 command('heatRushBegin',{zombie=remote.id,targetKind='zombie',request=900});check(not rush.leases[p],'player ID cannot alias a zombie target')
 command('heatRushBegin',{zombie=remote.id,targetKind='player',request=901});local lease=rush.leases[p];check(lease and lease.z==remote,'server grants a permitted player-target lease')
 command('heatRushReady',{action=lease.action});check(remote.blocked and not remote.authorize and remote.ignore and not remote.deferred,'MP paired victim locks player movement and attacks')
 local prompt=lease.definition.prompts[1];clock=lease.started+prompt.atMs-100;command('heatRushPress',{action=lease.action,index=1});clock=lease.started+prompt.atMs+10
 command('heatRushHit',{action=lease.action,index=1});check(math.abs(remote.playerDamage-.45)<.000001,'MP player damage uses canonical contact value')
 command('heatRushHit',{action=lease.action,index=1});check(math.abs(remote.playerDamage-.45)<.000001,'MP player contact cannot replay')
 pvp=false;rush.tick(clock,{[p]=true});check(not rush.leases[p]and not remote.blocked and remote.authorize and not remote.ignore and remote.deferred,'disabling PvP interrupts the lease and restores player controls')
end
return 'PASS '..count..' MP authority, duplicate, range, lease, cooldown, observer and throttle checks'
