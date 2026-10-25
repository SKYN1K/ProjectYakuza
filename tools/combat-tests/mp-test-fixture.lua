local count=0
local function check(ok,msg)count=count+1;if not ok then error(msg) end end
require=function()end
local clock=10000
getTimestampMs=function()return clock end
isClient=function()return true end;isServer=function()return true end
local function event()local e={};e.Add=function(fn)e[fn]=true end;e.Remove=function(fn)e[fn]=nil end;return e end
Events={OnTick=event(),OnClientCommand=event(),OnServerCommand=event(),OnPlayerUpdate=event(),OnZombieUpdate=event(),OnMainMenuEnter=event(),OnWeaponHitCharacter=event()}
local actors={}
local function list(t)return {size=function()return #t end,get=function(_,i)return t[i+1]end}end
local nextItem=1000
local function tokenItem(id)
 return {getID=function()return id end,getFullType=function()return 'DragonCombat.StyleToken' end,
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
local DCF=DragonCombat;local P=DCF.NetworkProtocol;local server=DCF.NetworkServer
local step=0;local seq=0;local eventID=0
local function snapshot(who,extra)
 seq=math.max(seq,(server.players[who.id] and server.players[who.id].seq or 0))+1;clock=clock+60
 local a={seq=seq,style='dragon_of_dojima',equipped=true,heat=30,fuel=30,extreme=false,clip='DCF_DD_Light01',move='dd_light_01',swing=1}
 for k,v in pairs(extra or {})do a[k]=v end
 server.command(P.module,'state',who,a);return a
end
local function command(name,args,who)
 eventID=eventID+1;args=args or {};args.event=eventID;server.command(P.module,name,who or p,args)
end
check(not P.number(0/0,0,1) and not P.integer(1.1,0,2),'reject NaN and fractional IDs')
check(P.clip('dragon_of_dojima','DCF_DD_Light01')~=nil,'catalogue has known attack')
check(P.clip('dragon_of_dojima','arbitrary_clip')==nil,'unknown animation rejected')
snapshot(p);local s=server.players[1]
check(s.packet.clip=='DCF_DD_Light01','known state accepted')
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
clock=clock+1100;snapshot(p,{phase='enter',clip='DCF_DD_GrabEnter'})
command('grabRequest',{zombie=z1.id});check(s.grab and z1.useless and z1.ignore,'server grants and freezes one grab lease')
snapshot(remote);command('grabRequest',{zombie=z1.id},remote)
check(server.players[2].grab==nil,'second player cannot grab leased zombie')
snapshot(p,{phase='hold',clip='DCF_DD_GrabHold'});server.tick()
check(z1.x==.7 and z1.nextX==.7,'server aligns paired current and next position')
snapshot(p,{phase='throw',clip='DCF_DD_Throw'});command('throw',{zombie=z1.id})
check(z1.hits==1 and z1.knock and s.grab==nil and not z1.useless and not z1.ignore,'throw hits once and releases AI lease')
command('throw',{zombie=z1.id});check(z1.hits==1,'repeated throw does not damage twice')
z1.health=1;clock=clock+1100;snapshot(p);command('grabRequest',{zombie=z1.id})
check(s.grab~=nil,'can acquire another grab after release')
clock=clock+9000;server.tick();check(s.grab==nil and not z1.useless,'lease timeout restores zombie AI')
clock=clock+1100;snapshot(p);z1.attacking=true;z1.target=p
command('counter',{zombie=z1.id});check(z1.kills==1 and z1.force==12,'valid attacking target is killed on server with hit force')
command('counter',{zombie=z1.id});check(z1.kills==1,'counter victim deduplicated')
z2.health=1;z2.attacking=true;z2.target=p;clock=clock+500;snapshot(p)
command('counter',{zombie=z2.id});check(not z2.kills,'counter cannot reopen within 60 second server cooldown')
clock=clock+61000;snapshot(p);command('counter',{zombie=z2.id});check(z2.kills==1,'counter ready after server cooldown')
z3.health=1;z3.target=p;snapshot(p,{clip='DCF_DD_GuardLoop',phase='hold'})
command('guard',{zombie=z3.id});check(z3.outcome=='fail','validated guard cancels bite outcome')
clock=clock+1100;snapshot(p);z4.health=1;command('grabRequest',{zombie=z4.id});check(s.grab~=nil,'disconnect test owns lease')
actors[1]=nil;server.tick();check(server.players[1]==nil and not z4.useless,'disconnect restores AI and removes session')
actors[1]=p
snapshot(p,{clip='DCF_DD_HeatActivate01',heat=40})
check(p.ghost and p.invincible and server.players[1].packet.protected,'activation gets a bounded server protection lease')
clock=clock+4000;server.tick();check(not p.ghost and not p.invincible,'expired activation restores original server flags')
snapshot(p,{clip='DCF_DD_HeatActivate01',heat=40});check(not p.invincible,'same held activation cannot renew invulnerability')
snapshot(p,{clip='',heat=40});snapshot(p,{clip='DCF_DD_HeatActivate01',heat=40})
check(p.invincible,'a later distinct activation can acquire protection')
snapshot(p,{clip='',heat=40});check(not p.ghost and not p.invincible,'activation completion restores flags immediately')
DCF.stateFor=function(who)who.combo=who.combo or {active=true,step=1};return who.combo end
DCF.Heat={states={},stocks=function(who)return math.floor((who.data.DCFHeat or 0)*6/100)end,display=function(who)return who.data.DCFHeat or 0 end,isExtreme=function()return false end,playback=function(who,e)who.speed=e and 1.92 or 1.6 end,onHit=function()end}
DCF.HeatAura={flash=function(who)who.flashes=(who.flashes or 0)+1 end,update=function(who)who.auraUpdates=(who.auraUpdates or 0)+1 end,clear=function(who)who.auraCleared=true end}
local effects=0;DCF.HitEffects={spawn=function()effects=effects+1 end}
-- REACTIONS_MODULE
DCF.Defense={snapActor=function(z,x,y)z.x=x;z.y=y;z.nextX=x;z.nextY=y end}
DCF.requestAction=function()return true end
DCF.cancelAction=function()end
DCF.prepareToken=function(item)item:setMaxHitCount(DCF.MAX_HIT_COUNT)end
-- CLIENT_MODULE
local client=DCF.Network
remote.data.DCFStyle='dragon_of_dojima';remote.equipped=false
local packet={player=2,seq=1,style='dragon_of_dojima',equipped=true,heat=40,fuel=35,extreme=true,clip='DCF_DD_Light01',move='dd_light_01',swing=1}
client.command(P.module,'state',packet)
check(DCF.isEquipped(remote) and remote.data.DCFHeat==40 and remote.vars.DCFRemoteClip=='DCF_DD_Light01','remote style heat and safe observer animation applied')
check(remote.auraUpdates==1 and remote.vars.DCFRemoteObserver,'observer starts once')
for i=1,20 do client.update(remote)end
check(remote.auraUpdates==1,'unchanged remote updates do not restart clips or poll aura repeatedly')
local impact={player=2,zombie=z3.id,event=1,strong=true,reaction='enemy_01',style='dragon_of_dojima'}
client.command(P.module,'impact',impact);client.command(P.module,'impact',impact)
check(effects==1 and z3.vars.DCFEnemyHitClip=='enemy_01' and z3.reaction=='HeadLeft' and z3.lastEvent=='wasHit','remote impact renders once and enters actual native hit reaction state')
local damage={player=2,zombie=z3.id,event=1,health=.25,amount=.4,kill=false,knock=false}
local hitsBefore=z3.hits
client.command(P.module,'damage',damage);client.command(P.module,'damage',damage)
check(z3.health==.25 and z3.hits==hitsBefore and effects==2,'server result mirrors absolute health without observer Hit calls')
packet={player=2,seq=2,style='dragon_of_dojima',equipped=true,heat=40,fuel=35,extreme=true,clip='DCF_DD_Light01',move='dd_light_01',swing=2}
client.command(P.module,'state',packet);check(client.remote[2].swing==2,'same clip tracks a new attack serial')
packet.seq=3;packet.clip='DCF_DD_Quickstep01';client.command(P.module,'state',packet)
check(remote.vars.PerformingAction=='DCF_MP' and remote.vars.IsPerformingAnAction,'timed observer uses BaseAction native action variables')
packet.seq=4;packet.taunt=1;packet.clip='';client.command(P.module,'state',packet)
check(remote.flashes==1,'new completion counter flashes remote aura')
packet.seq=5;client.command(P.module,'state',packet);check(remote.flashes==1,'heartbeat does not repeat completion flash')
packet.seq=6;packet.clip='DCF_DD_Taunt01';client.command(P.module,'state',packet)
packet.seq=7;packet.clip='';client.command(P.module,'state',packet);check(remote.flashes==1,'interrupted taunt without completion never flashes')
packet.seq=8;packet.taunt='invalid';client.command(P.module,'state',packet);check(remote.flashes==1,'malformed completion serial rejected')
clock=clock+4100;client.tick();check(remote.auraCleared and remote.vars.PerformingAction=='' and not DCF.isEquipped(remote),'stale observer state clears animation and aura')
p.equipped=true;p.data.DCFStyle='dragon_of_dojima';p.data.DCFHeat=20
p.vars.DCFActive='true';p.vars.DCFMove='dd_light_01';p.vars.AimFloorAnim='false'
client.localState(p).equipReady=p.token;client.localState(p).equipStyle='dragon_of_dojima'
client.swing(p);check(#outgoing>0,'local attack sends snapshot without changing position')
local outCount=#outgoing;client.capture(p);client.capture(p);check(#outgoing==outCount,'unchanged local snapshots throttle redundant sends')
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
-- Two different states in the same millisecond must both survive the relay.
clock=clock+1100;snapshot(p,{clip='DCF_DD_Quickstep01',action=1})
local firstSeq=server.players[1].seq
server.command(P.module,'state',p,{seq=firstSeq+1,style='dragon_of_dojima',equipped=true,heat=30,fuel=30,
 clip='DCF_DD_Quickstep02',move='dd_light_01',swing=2,action=2})
check(server.players[1].packet.clip=='DCF_DD_Quickstep02' and server.players[1].packet.action==2,'same-tick action transition is not discarded by a 50ms gate')

-- Simulate a server with no copy of the saved client-only token. The two
-- inventories are separate and native inventory delivery can lag the Lua ack.
clock=clock+1100
local serverActor=player(3,0);serverActor.inventoryItems={};serverActor.hand=nil;serverActor.equipped=false
local owner=player(3,0);owner.localPlayer=true;owner.data.DCFStyle='dragon_of_dojima'
nativeAdds={};nativeEquips={};outgoing={};replies={}
check(not DCF.isEquipped(owner),'unregistered client weapon cannot start combat')
check(#outgoing==1 and outgoing[1].command=='equip','saved client-only token requests a server-issued item')
local request=outgoing[1].args
server.command(P.module,'equip',serverActor,request)
local issued=serverActor:getPrimaryHandItem()
check(issued and serverActor:getInventory():getItemWithID(issued:getID())==issued,'issued weapon ID is present in authoritative server inventory')
check(#nativeAdds==1 and #nativeEquips==1 and nativeEquips[1].item==issued,'server synchronizes inventory before native equip')
local ack=replies[#replies].args
client.command(P.module,'equipReady',ack)
check(not DCF.isEquipped(owner) and owner:getPrimaryHandItem()~=issued,'early equip ack waits for native inventory delivery')
owner.inventoryItems[#owner.inventoryItems+1]=issued
check(DCF.isEquipped(owner) and owner:getPrimaryHandItem()==issued and owner.equipSent==1,'combat unlocks only after both peers resolve the same item ID')
clock=clock+250;local adds=#nativeAdds;client.equip(owner,'dragon_of_dojima')
server.command(P.module,'equip',serverActor,outgoing[#outgoing].args)
check(#serverActor.inventoryItems==1 and #nativeAdds==adds,'reselecting a style reuses acknowledged item without duplicate inventory delivery')
client.command(P.module,'equipReady',replies[#replies].args)
local hand=owner:getPrimaryHandItem()
client.command(P.module,'equipReady',{player=3,request=1,style='dragon_of_dojima',item=101})
check(owner:getPrimaryHandItem()==hand,'stale equip acknowledgements cannot restore old token')
clock=clock+250
server.command(P.module,'equip',serverActor,{request=100,style='unknown'})
check(serverActor:getPrimaryHandItem()==issued,'server rejects unknown style provisioning')
client.equip(owner,'none');server.command(P.module,'equip',serverActor,outgoing[#outgoing].args)
client.command(P.module,'equipReady',replies[#replies].args)
check(serverActor:getPrimaryHandItem()==nil and owner:getPrimaryHandItem()==nil,'disabling style unequips both peers')
actors[3]=nil;server.players[3]=nil

-- A new serial must restart the same action without replaying gameplay events.
clock=clock+1100
local repeated={player=2,seq=100,style='dragon_of_dojima',equipped=true,heat=30,fuel=30,
 extreme=false,clip='DCF_DD_Quickstep01',move='',swing=8,action=10}
client.command(P.module,'state',repeated)
local cycle=remote.vars.DCFRemoteCycle
repeated.seq=101;repeated.action=11;client.command(P.module,'state',repeated)
check(remote.vars.DCFRemoteCycle~=cycle and client.remote[2].action==11,'same-direction quickstep selects a fresh observer cycle')
local events=z3.events or 0
client.command(P.module,'impact',{player=2,zombie=z3.id,event=20,strong=true,reaction='not_registered',style='dragon_of_dojima'})
check(z3.events==events,'unregistered zombie clips cannot enter reaction state')
local beforeHits=z3.hits
client.command(P.module,'impact',{player=2,zombie=z3.id,event=21,strong=true,reaction='enemy_02',style='dragon_of_dojima'})
check(z3.vars.DCFEnemyHitClip=='enemy_02' and z3.events==events+1 and z3.hits==beforeHits,'repeat hit enters reaction state without applying Hit again')
DCF.Reactions.update(z3,clock+500)
check(DCF.Reactions.states[z3]~=nil,'reaction survives a delayed native state entry')
DCF.Reactions.update(z3,clock+800)
check(DCF.Reactions.states[z3]==nil,'reaction that never enters native state times out')

-- The quickstep stream is bounded by the registered move, path and server quota.
clock=clock+1100;p.x=0;p.y=0;remote.x=0;remote.y=0;replies={}
snapshot(p,{clip='DCF_DD_Quickstep01',action=20})
local function sample(id,x,finished)
 command('step',{step=id,clip='DCF_DD_Quickstep01',x=x,y=0,z=0,fx=1,fy=0,finished=finished})
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
clock=clock+15001;snapshot(p,{clip='DCF_DD_Quickstep01',action=21});sample(4,0,false)
check(server.players[1].lastStep==4,'quickstep quota releases after rolling window')
local progress=server.players[1].step.travel
command('step',{step=4,clip='DCF_DD_Quickstep01',x=0/0,y=0,z=0,fx=1,fy=0})
check(server.players[1].step.travel==progress,'nonfinite step position rejected')

-- Interpolate only a remote actor. Late or reordered samples never rewind it.
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
local previousCycle=remote.vars.DCFRemoteCycle
client.command(P.module,'state',repeated)
check(remote.vars.DCFRemoteCycle~=previousCycle,'simultaneous swing and action increments still restart observer clip')
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
DCF.Quicksteps={facing=function()return 1,0 end}
local stepAction={started=true,context={action={animation='DCF_DD_Quickstep01'}}}
outgoing={};local updates=p.nativeUpdates or 0
client.step(p,stepAction,false)
check(outgoing[#outgoing].command=='step' and p.nativeUpdates==updates+1,'quickstep uses exposed player setter to request native reliable position update')
local messages=#outgoing;client.step(p,stepAction,false)
check(#outgoing==messages,'quickstep progress transmission is limited to 20Hz')
client.step(p,stepAction,true)
check(#outgoing>messages and outgoing[#outgoing].args.finished,'terminal position bypasses progress throttle')
return 'PASS '..count..' MP authority, duplicate, range, lease, cooldown, observer and throttle checks'
