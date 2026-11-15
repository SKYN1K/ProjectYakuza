local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local function event()return {callbacks={},Add=function()end,Remove=function()end}end
Events={OnTick=event(),OnSave=event(),OnMainMenuEnter=event()}
local clock,paused=0,false
getTimestampMs=function()return clock end
isGamePaused=function()return paused end
require=function()end
ProjectYakuza={NetworkProtocol={integer=function(v,a,b)return type(v)=='number'and v==math.floor(v)and v>=a and v<=b end,number=function(v,a,b)return type(v)=='number'and v==v and v>=a and v<=b end}}
local plays,items,objects=0,{},{}
GameSounds={getSound=function(name)check(name=='ProjectYakuza_BicycleBreak','dedicated original bicycle break cue');return {getRandomClip=function()return {}end}end}
getWorld=function()return {getFreeEmitter=function(_,x,y,z)return {playClip=function()plays=plays+1;return plays end,setVolume=function(_,id,volume)check(volume==.8,'audible break volume')end}end}end
local square={getX=function()return 10 end,getY=function()return 20 end}
function square:AddWorldInventoryItem(item,x,y,h,transmit,synchSpawn)
 check(transmit==false and synchSpawn==false,'cosmetic fragments never transmit inventory or spawn packets')
 local object={x=x,y=y,height=h}
 function object:setNoPicking(v)self.noPicking=v end
 function object:setOffX(v)self.x=v end;function object:setOffY(v)self.y=v end;function object:setOffZ(v)self.height=v end
 function object:removeFromWorld()self.worldRemovals=(self.worldRemovals or 0)+1 end
 function object:removeFromSquare()self.squareRemovals=(self.squareRemovals or 0)+1 end
 item.world=object;objects[#objects+1]=object;return item
end
getCell=function()return {getGridSquare=function()return square end}end
instanceItem=function(name)
 check(name=='ProjectYakuza.BicycleFrontWheel'or name=='ProjectYakuza.BicycleRearWheel'or name=='ProjectYakuza.BicycleHandlebars','only supplied original wheel and handlebar fragments instantiate')
 local item={name=name};function item:getWorldItem()return self.world end;function item:setWorldItem(v)self.world=v end;function item:setWorldZRotation(v)self.rotation=v end;function item:getContainer()return self.container end;items[#items+1]=item;return item
end
do local _="ProjectYakuzaFixture:BICYCLE_BREAK" end
local lastEmitter
local priorWorld=getWorld
getWorld=function()local world=priorWorld();local emit=world.getFreeEmitter;world.getFreeEmitter=function(self,x,y,z)lastEmitter={x=x,y=y,z=z};return emit(self,x,y,z)end;return world end
local E=ProjectYakuza.BicycleBreak;local p={getX=function()return 10.3 end,getY=function()return 20.4 end,getZ=function()return 0 end}
E.remote(p,{session='one',action=5,weaponBroken=true,breakX=10.6,breakY=20.7,breakZ=0});check(#E.parts==3 and plays==1,'one authoritative break produces one cue and three parts')
check(lastEmitter.x==10.6 and lastEmitter.y==20.7,'multiplayer fragments and break cue originate at confirmed victim impact')
for _,object in ipairs(objects)do check(object.noPicking,'temporary parts cannot be selected for pickup')end
E.remote(p,{session='one',action=5,weaponBroken=true});E.remote(p,{session='one',action=4,weaponBroken=true});check(#E.parts==3 and plays==1,'duplicate and older break packets cannot replay sound or parts')
E.remote(p,{session='one',action=6,weaponBroken=false});check(#E.parts==3 and plays==1,'ordinary action completion does not shatter a bicycle')
paused=true;clock=500;E.tick();check(E.parts[1].age==0 and E.parts[1].height==.3,'pause freezes fragment physics and cleanup age');paused=false
for i=1,12 do clock=clock+50;E.tick()end
check(objects[1].height<.3 and objects[1].height>=.005 and items[1].rotation~=nil,'supplied parts fall, spin and remain above the floor')
for action=6,20 do E.remote(p,{session='one',action=action,weaponBroken=true})end
check(#E.parts==E.maxParts,'simultaneous multiplayer breaks have a strict part limit')
for i=1,40 do clock=clock+50;E.tick()end
check(#E.parts==0 and not E.hooked,'all effects expire and release their update hook')
for _,object in ipairs(objects)do check(object.worldRemovals==1 and object.squareRemovals==1,'each temporary world object is removed exactly once')end
for _,item in ipairs(items)do check(item.world==nil,'expired effect items retain no world links')end
E.remote(p,{session='two',action=1,weaponBroken=true});check(#E.parts==3,'new server sessions can restart their action counter');local taken=E.parts[1].item;taken.container={Remove=function(_,item)check(item==taken,'cleanup removes only its cosmetic item');taken.removed=true end};E.clear();check(#E.parts==0 and not E.hooked and taken.removed,'save/menu cleanup also removes a fragment moved into a container')
return true,'PASS '..checks..' bicycle break sound, supplied parts, no pickup/networking, MP replay safety, pause, limits and cleanup checks'
