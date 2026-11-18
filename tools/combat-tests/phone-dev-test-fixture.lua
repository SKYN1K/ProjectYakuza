require=function()end
local clock=1000
getTimestampMs=function()return clock end
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b,e)return math.abs(a-b)<(e or .00002)end
local function event()local e={hooks={}};function e.Add(fn)e.hooks[fn]=true end;return e end
Events={OnGameStart=event(),OnSave=event(),OnMainMenuEnter=event()}
ProjectYakuza={VERSION="0.127.0"}
do local _="ProjectYakuzaFixture:PHONEASSETS" end
do local _="ProjectYakuzaFixture:PHONEMATH" end
local PY=ProjectYakuza;local D=PY.PhoneDev;local M=D.Math
local refs="ProjectYakuzaFixture:PHONEREFS"
local mult=math.exp(.2)*160/1.82
for _,r in ipairs(refs)do
 local pose,point,native=r.pose,r.point,r.native
 local x,y,z=M.transform(pose,point[1],point[2],point[3])
 check(near(x,native[3],.00002)and near(y,native[4],.00002)and near(z,native[5],.00002),'phone transform matches native JOML')
 check(near(r.width/2+z*mult*r.width/1366,native[1],.001)and near(r.height/2-y*mult*r.width/1366,native[2],.001),'screen projection matches actual native UI3DScene')
 local generated=M.pose(r.open,r.px,r.py,r.reduce,true)
 for _,key in ipairs({'rx','ry','rz','scale','x','y','z'})do check(near(generated[key],pose[key]),'production opening/tilt pose matches the native test inputs')end
end
for first=1,#refs,13 do
 local q={};for corner=1,4 do local p=refs[first+corner-1].native;q[corner]={p[1],p[2]}end
 local source=refs[first];local scene={sceneToUIX=function(_,x,y,z)return source.width/2+z*mult*source.width/1366 end,sceneToUIY=function(_,x,y,z)return source.height/2-y*mult*source.width/1366 end}
 local projected=M.project(scene,source.pose);for corner=1,4 do check(near(projected[corner][1],q[corner][1],.001)and near(projected[corner][2],q[corner][2],.001),'production screen corners coincide with the native model projection')end
 for index=1,9 do local p=refs[first+3+index].native;check(M.hit(q,p[1],p[2])==index,'inverse screen input follows every native app centre during motion')end
end
for _,name in ipairs({'styles','equipment','combat','heat','audio','effects','grabs','controls','settings'})do
 local asset=D.assets[name];local x,y,w,h=M.iconRect(asset,57,202,46);local b=asset.bounds
 check(near(x+(b[1]+b[3])/2*w/asset.width,57)and near(y+(b[2]+b[4])/2*h/asset.height,202),'visible icon alpha bounds are centred')
 check(w*(b[3]-b[1])/asset.width<=46.00001 and h*(b[4]-b[2])/asset.height<=46.00001,'visible icon fits its tile')
end
local mouseX,mouseY=300,400
getMouseX=function()return mouseX end;getMouseY=function()return mouseY end
getPlayerScreenLeft=function()return 0 end;getPlayerScreenTop=function()return 0 end
local viewportWidth,viewportHeight=1600,900
getPlayerScreenWidth=function()return viewportWidth end;getPlayerScreenHeight=function()return viewportHeight end
local textEntry=false
getCore=function()return {isDoingTextEntry=function()return textEntry end}end
getGameTime=function()return {getTimeOfDay=function()return 14.5 end}end
UIFont={Small=1,Medium=2}
Keyboard={KEY_ESCAPE=1,KEY_RETURN=28,KEY_NUMPADENTER=156,KEY_TAB=15,KEY_LEFT=203,KEY_RIGHT=205,KEY_UP=200,KEY_DOWN=208,KEY_W=17}
Joypad={AButton=0,BButton=1,YButton=3};JoypadState={players={}}
local sounds,equipped,assigned,saves,volumes,draws,legacy=0,0,0,0,{musicVolume=100,hitVolume=100,voiceVolume=100},0,0
local manager={};local failModel=false
local function vector()return {set=function(self,x,y,z)self.x=x;self.y=y;self.z=z end}end
local function native(owner)
 local n={rotation=vector(),translation=vector(),scale=vector()}
 function n:fromLua1(name,arg)
  if name=='getObjectRotation'then return self.rotation elseif name=='getObjectTranslation'then return self.translation elseif name=='getObjectScale'then return self.scale end
  check(name=='setZoom'or name=='setView'or name=='setGizmoVisible'or string.find(name,'setDraw')==1,'only verified native scene controls are used');return nil
 end
 function n:fromLua2(name,id,value)
  if name=='createModel'then if failModel then error('injected model load failure')end;check(value=='ProjectYakuzaPhoneDev.Xperia','original Xperia model selected')
  else check((name=='setModelUseWorldAttachment'or name=='setModelWeaponRotationHack')and value==false,'native model has no weapon-attachment transforms')end
 end
 function n:sceneToUIX(x,y,z)return owner.width/2+z*mult*owner.width/1366 end
 function n:sceneToUIY(x,y,z)return owner.height/2-y*mult*owner.width/1366 end
 return n
end
local Base={};Base.__index=Base
function Base:derive(name)local c={Type=name};c.__index=c;setmetatable(c,{__index=self});return c end
function Base:new(x,y,w,h)return setmetatable({x=x,y=y,width=w,height=h,children={}},self)end
function Base:initialise()if not self.javaObject then self.javaObject=native(self)end end
function Base:addChild(child)child.parent=self;child:initialise();self.children[#self.children+1]=child end
function Base:addToUIManager()manager[self]=true end
function Base:removeFromUIManager()manager[self]=nil end
function Base:bringToTop()end
function Base:setWantKeyEvents(v)self.wantsKeys=v end
function Base:update()end
function Base:getAbsoluteX()return self.x+(self.parent and self.parent:getAbsoluteX()or 0)end
function Base:getAbsoluteY()return self.y+(self.parent and self.parent:getAbsoluteY()or 0)end
function Base:getMouseX()return mouseX-self:getAbsoluteX()end
function Base:getMouseY()return mouseY-self:getAbsoluteY()end
function Base:setStencilRect()self.stencil=true end
function Base:clearStencilRect()self.stencil=false end
function Base:drawRect(x,y,w,h,a)check(w>=0 and h>=0 and a>=0 and a<=1,'UI rectangles stay finite and translucent');draws=draws+1 end
function Base:drawText(text)check(type(text)=='string','UI labels stay readable strings');draws=draws+1 end
Base.drawTextCentre=Base.drawText
function Base:drawTextureAllPoint(texture,x1,y1,x2,y2,x3,y3,x4,y4,r,g,b,a)check(texture~=nil and a>=0 and a<=1 and x1==x1 and y4==y4,'projected original textures stay finite');draws=draws+1 end
function Base:drawTextureScaled()draws=draws+1 end
function Base:drawSubTexture()draws=draws+1 end
ISPanel=Base:derive('ISPanel');ISPanelJoypad=Base:derive('ISPanelJoypad');ISUI3DScene=Base:derive('ISUI3DScene')
getTexture=function(path)return path end
local dragon={id='dragon_of_dojima',name='Dragon of Dojima'};local other={id='other',name='Other Style'}
PY.styles={dragon_of_dojima=dragon,other=other};PY.getStyle=function(id)return PY.styles[id]end;PY.listStyles=function()return {dragon,other}end
PY.getPlayerStyle=function(p)return PY.styles[p.style]or dragon end;PY.isEquipped=function(p)return p.equipped end;PY.isStyleToken=function(item)return item.token==true end;PY.isBusy=function(p)return p.busy==true end
PY.equipStyle=function(p,id)equipped=equipped+1;p.style=id;p.equipped=true end;PY.unequipStyle=function(p)p.equipped=false end
PY.StyleSlots={get=function(p)return p.slots end,id=function(p,s)return p.slots[s]end,assign=function(p,s,id)p.slots[s]=id;assigned=assigned+1;return true end}
PY.Heat={stocks=function()return 2 end,isExtreme=function()return false end,rules=function()return {maxStocks=6,idleGraceMs=3000}end}
PY.Sandbox={enabled=function()return true end,tigerDrop=function()return true end,tigerWindowMs=function()return 160 end,tigerCooldownMs=function()return 20000 end}
PY.Bindings={definitions={{id='light',name='Light attack'},{id='grab',name='Grab / throw'}},label=function(id)return id=='grab'and'G'or'LMB'end}
PY.HitEffects={toggle=function(p)p.md.ProjectYakuzaHitEffectsDisabled=not p.md.ProjectYakuzaHitEffectsDisabled end};PY.HeatAura={toggle=function(p)p.md.ProjectYakuzaHeatAuraDisabled=not p.md.ProjectYakuzaHeatAuraDisabled end}
PY.UIAudio={play=function()sounds=sounds+1 end}
local options={getOption=function(self,id)return self[id]end,apply=function()end}
for id,value in pairs(volumes)do options[id]={min=0,max=200,value=value,getValue=function(self)return self.value end,setValue=function(self,v)self.value=v end}end
PZAPI={ModOptions={getOptions=function()return options end,save=function()saves=saves+1 end}}
local inventory={items={}}
function inventory:getItems()return {size=function()return #self.items end,get=function(_,i)return self.items[i+1]end}end
function inventory:contains(item)return not item.missing end
for i=1,25 do local item={kind='HandWeapon',name='Weapon '..i};function item:getDisplayName()return self.name end;function item:getConditionMax()return 100 end;function item:getCondition()return 75 end;function item:isTwoHandWeapon()return true end;inventory.items[i]=item end
instanceof=function(o,kind)return o and o.kind==kind end
local p={md={},style=dragon.id,equipped=true,slots={left=dragon.id},dead=false,busy=false,joypad=-1}
function p:getModData()return self.md end;function p:getPlayerNum()return 0 end;function p:getInventory()return inventory end;function p:getPrimaryHandItem()return inventory.items[1]end
function p:isDead()return self.dead end;function p:getVehicle()return self.vehicle end;function p:isLocalPlayer()return true end;function p:getJoypadBind()return self.joypad end
function p:getBodyDamage()return {getOverallBodyHealth=function()return 83 end}end
local inventoryOpened=false
getPlayerInventory=function()return {setVisible=function()inventoryOpened=true end}end
ISInventoryPaneContextMenu={equipWeapon=function()equipped=equipped+1 end}
PY.StyleSelector={allowed=function(who)return who and not who.dead and not who.busy and not who.vehicle end,loadAssets=function()end,styleIcon=function()return nil end}
local original=function(who)legacy=legacy+1;PY.StyleSelector.setup={legacy=true,close=function()PY.StyleSelector.setup=nil end};return true end
PY.StyleSelector.openSetup=original
setJoypadFocus=function(num,panel)local state=JoypadState.players[num+1];state.focus=panel;if panel and panel.onGainJoypadFocus then panel:onGainJoypadFocus(state)end end
do local _="ProjectYakuzaFixture:PHONEDATA" end
do local _="ProjectYakuzaFixture:PHONEPANEL" end
do local _="ProjectYakuzaFixture:PHONEBOOT" end
check(D.compatible('0.127.0')and D.compatible('1.0.0')and not D.compatible('0.126.0')and not D.compatible('invalid'),'dev menu enforces its shared polished combat baseline')
D.install();D.install();check(PY.StyleSelector.openSetup==D.open and D.legacyOpenSetup==original,'menu hook installs once and preserves the original settings')
local function advance(ms)for i=1,math.ceil(ms/20)do clock=clock+20;if D.panel then D.panel:update()end end end
local function open()check(D.open(p),'phone opens through the optional menu hook');advance(600);return D.panel end
local panel=open();check(panel.page==2 and panel.wantsKeys and manager[panel],'equipment is the saved-reference default and input belongs to the visible phone')
panel:prerender();panel.screen:prerender();panel.rows:prerender();check(draws>50 and not panel.rows.stencil,'native phone screen and page draw without leaking clipping')
check(panel.rows:onMouseWheel(3)==true and panel.rows.offset>0 and panel:onMouseWheel(1)==true,'inventory wheel scrolls and cannot zoom the world')
panel.focusRows=false;panel:onKeyPress(Keyboard.KEY_RIGHT);check(panel.page==3,'arrow navigation changes phone apps');panel:onKeyPress(Keyboard.KEY_TAB);check(panel.focusRows,'Tab moves to the page rows')
panel:selectPage(5);panel.row=1;panel.focusRows=true;panel:onKeyPress(Keyboard.KEY_RIGHT);check(options.musicVolume:getValue()==110 and saves==1,'audio adjusts and persists through the existing mod-options API')
for i=1,30 do panel:onKeyPress(Keyboard.KEY_RIGHT)end;check(options.musicVolume:getValue()==200,'volume is clamped to the shared option limit')
panel:selectPage(6);panel.row=1;panel:activateRow();check(p.md.ProjectYakuzaHitEffectsDisabled,'effect setting uses the core toggle');panel:activateRow();check(not p.md.ProjectYakuzaHitEffectsDisabled,'effect toggle restores the shared setting')
panel:selectPage(1);panel.row=4;panel:activateRow();check(assigned==1,'style quick slots use the existing style-slot API')
panel.row=2;local before=equipped;panel:activateRow();check(panel.closing and equipped==before,'equip waits for the closing animation');advance(400);check(not D.panel and not PY.StyleSelector.setup and not panel.wantsKeys and not manager[panel]and equipped==before+1,'closing releases input and then runs the selected combat action')
panel=open();panel:selectPage(2);panel.row=2;before=equipped;panel:activateRow();p.dead=true;advance(20);check(not D.panel and equipped==before,'death cancels a pending equip callback');p.dead=false
panel=open();panel:selectPage(2);local weapon=inventory.items[1];weapon.missing=true;panel.row=2;panel:activateRow();check(not panel.closing and panel.message~=nil,'a removed inventory item cannot be equipped through a stale row');weapon.missing=false
panel:selectPage(9);panel.row=3;panel:activateRow();advance(400);check(legacy==1 and PY.StyleSelector.setup.legacy and not D.panel,'advanced settings hands off to the original mod menu');PY.StyleSelector.setup:close()
panel=open();panel:selectPage(9);panel.row=1;panel:activateRow();check(D.preferences(p).tilt==false,'phone tilt preference toggles');panel.row=2;panel:activateRow();check(D.preferences(p).reduceMotion,'reduced-motion preference toggles');D.clear();check(not D.panel and not manager[panel],'saving or leaving removes the optional phone immediately')
panel=open();ISWorldMap_instance={isVisible=function()return true end};advance(20);check(not D.panel,'opening the map clears the phone');ISWorldMap_instance=nil
panel=open();textEntry=true;advance(20);check(not D.panel,'chat text entry releases phone input');textEntry=false
panel=open();viewportWidth=1280;advance(20);check(not D.panel,'viewport changes close the phone cleanly');viewportWidth=1600
viewportWidth=900;viewportHeight=1000;panel=open();check(panel.panelW>300 and panel.scene.width<viewportWidth*.5,'narrow viewports retain a usable phone and page panel');D.clear();viewportWidth=1600;viewportHeight=900
p.joypad=0;local prior={};JoypadState.players[1]={focus=prior};panel=open();check(panel.gamepad and JoypadState.players[1].focus==panel,'controller focus moves to the dev menu');panel:onJoypadDown(Joypad.YButton);check(panel.focusRows,'controller focus changes between phone and list');panel:onJoypadDown(Joypad.BButton);advance(400);check(JoypadState.players[1].focus==prior and not D.panel,'closing restores the previous controller focus');p.joypad=-1;JoypadState.players[1]=nil
failModel=true;check(D.open(p)and legacy==2 and D.panel==nil and PY.StyleSelector.setup.legacy,'a native model failure restores the old menu without retaining input');failModel=false;PY.StyleSelector.setup:close()
check(panel:isKeyConsumed(Keyboard.KEY_ESCAPE)and not panel:isKeyConsumed(Keyboard.KEY_W),'phone keys are consumed without disabling player movement')
check(PY.VERSION=='0.127.0'and PY.Heat.stocks(p)==2,'dev interface does not replace combat version or grant heat')
return 'PASS '..checks..' native projection, inverse input, alpha centring, pages, scrolling, options, actions, fallback and lifecycle assertions'
