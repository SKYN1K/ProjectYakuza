require=function()end
local clock=1000
getTimestampMs=function()return clock end
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b,e)return math.abs(a-b)<(e or .00002)end
local function event()local e={hooks={}};function e.Add(fn)e.hooks[fn]=true end;return e end
Events={OnGameStart=event(),OnSave=event(),OnMainMenuEnter=event()}
ProjectYakuza={VERSION="0.133.0"}
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
 local projected=M.project(source.pose,source.width,source.height);for corner=1,4 do check(near(projected[corner][1],q[corner][1],.001)and near(projected[corner][2],q[corner][2],.001),'production screen corners coincide with the native model projection')end
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
UIFont={Small=1,Medium=2,SdfRegular=3,SdfBold=4}
local textDraws={};local textMeasures=0
local managerText={}
function managerText:getFontHeight()return 45 end
function managerText:MeasureStringX(font,text)
 textMeasures=textMeasures+1;local width=0
 for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*")do width=width+(char=="W"and 30 or(char=="i"or char=="l")and 8 or char==" "and 12 or 20)end
 return width
end
function managerText:DrawString(font,x,y,scale,text,r,g,b,a)
 check(font==UIFont.SdfRegular or font==UIFont.SdfBold,'all text uses the native proportional font enums')
 check(type(text)=='string'and scale>=0 and scale==scale and x==x and a>=0 and a<=1,'native text draws stay finite')
 textDraws[#textDraws+1]={text=text,x=x,y=y,width=self:MeasureStringX(font,text)*scale,height=45*scale,font=font}
end
getTextManager=function()return managerText end
Keyboard={KEY_ESCAPE=1,KEY_RETURN=28,KEY_NUMPADENTER=156,KEY_TAB=15,KEY_LEFT=203,KEY_RIGHT=205,KEY_UP=200,KEY_DOWN=208,KEY_W=17,KEY_F=33}
Joypad={AButton=0,BButton=1,YButton=3};JoypadState={players={}}
local uiSounds={}
getSoundManager=function()return {playUISound=function(_,name)uiSounds[#uiSounds+1]=name end}end
local sounds,equipped,assigned,saves,volumes,draws,legacy=0,0,0,0,{musicVolume=100,hitVolume=100,voiceVolume=100},0,0
local manager={};local failModel=false
local vectorWrites,projectionCalls,projectedDraws,inventoryScans,nameReads,fullOrbDraws=0,0,0,0,0,0
local function vector()return {set=function(self,x,y,z)vectorWrites=vectorWrites+1;self.x=x;self.y=y;self.z=z end}end
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
 function n:sceneToUIX(x,y,z)projectionCalls=projectionCalls+1;return owner.width/2+z*mult*owner.width/1366 end
 function n:sceneToUIY(x,y,z)projectionCalls=projectionCalls+1;return owner.height/2-y*mult*owner.width/1366 end
 return n
end
local Base={};Base.__index=Base
function Base:derive(name)local c={Type=name};c.__index=c;setmetatable(c,{__index=self});return c end
function Base:new(x,y,w,h)return setmetatable({x=x,y=y,width=w,height=h,children={}},self)end
function Base:initialise()if not self.javaObject then self.javaObject=native(self)end end
function Base:removeChild(child)for i=#self.children,1,-1 do if self.children[i]==child then table.remove(self.children,i)end end end
function Base:addChild(child)child.parent=self;child:initialise();self.children[#self.children+1]=child end
function Base:addToUIManager()manager[self]=true end
function Base:removeFromUIManager()manager[self]=nil end
function Base:bringToTop()end
function Base:setWantKeyEvents(v)self.wantsKeys=v end
function Base:update()end
function Base:setVisible(value)self.visible=value end
function Base:getAbsoluteX()return self.x+(self.parent and self.parent:getAbsoluteX()or 0)end
function Base:getAbsoluteY()return self.y+(self.parent and self.parent:getAbsoluteY()or 0)end
function Base:getMouseX()return mouseX-self:getAbsoluteX()end
function Base:getMouseY()return mouseY-self:getAbsoluteY()end
function Base:setStencilRect()self.stencil=true end
function Base:clearStencilRect()self.stencil=false end
function Base:drawRect(x,y,w,h,a)check(w>=0 and h>=0 and a>=0 and a<=1,'UI rectangles stay finite and translucent');draws=draws+1 end
function Base:drawText(text)check(type(text)=='string','UI labels stay readable strings');draws=draws+1 end
Base.drawTextCentre=Base.drawText
Base.drawTextRight=Base.drawText
function Base:drawTextureAllPoint(texture,x1,y1,x2,y2,x3,y3,x4,y4,r,g,b,a)check(texture~=nil and a>=0 and a<=1 and x1==x1 and y4==y4,'projected original textures stay finite');draws=draws+1;projectedDraws=projectedDraws+1;if texture.name=='ProjectYakuzaPhoneDevOrbFill'then fullOrbDraws=fullOrbDraws+1 end end
function Base:drawTextureScaled(texture,x,y,w,h,a)check(texture~=nil and w>=0 and h>=0 and a>=0 and a<=1,"native preview and item textures are finite");draws=draws+1 end
function Base:drawSubTexture()draws=draws+1 end
ISPanel=Base:derive('ISPanel');ISPanelJoypad=Base:derive('ISPanelJoypad');ISUI3DScene=Base:derive('ISUI3DScene')
local uiTextureSplits=0;local fontReady=true
getTexture=function(path)return {path=path,getWidth=function()return 512 end,getHeight=function()return 288 end,isReady=function()return fontReady end,split=function(self,name,x,y,w,h)uiTextureSplits=uiTextureSplits+1;return {path=self.path,name=name,x=x,y=y,w=w,h=h,isReady=function()return fontReady end}end}end
local glyphQuads={}
local originalQuad=Base.drawTextureAllPoint
function Base:drawTextureAllPoint(texture,x1,y1,x2,y2,x3,y3,x4,y4,r,g,b,a)
 originalQuad(self,texture,x1,y1,x2,y2,x3,y3,x4,y4,r,g,b,a)
 if texture.path==D.Glyphs.path then glyphQuads[#glyphQuads+1]={x1,y1,x2,y2,x3,y3,x4,y4}end
end
local dragon={id='dragon_of_dojima',name='Dragon of Dojima',description="Kiryu's four-hit chain with Extreme Heat boost attacks."};local other={id='other',name='Other Style',description='Another style.'}
PY.styles={dragon_of_dojima=dragon,other=other};PY.getStyle=function(id)return PY.styles[id]end;PY.listStyles=function()return {{id=dragon.id,name=dragon.name,description=dragon.description},{id=other.id,name=other.name,description=other.description}}end
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
function inventory:getItems()inventoryScans=inventoryScans+1;return {size=function()return #self.items end,get=function(_,i)return self.items[i+1]end}end
function inventory:contains(item)return not item.missing end
for i=1,25 do local item={kind='HandWeapon',name='Weapon '..i};function item:getDisplayName()nameReads=nameReads+1;return self.name end;function item:getConditionMax()return 100 end;function item:getCondition()return 75 end;function item:isTwoHandWeapon()return true end;function item:getDisplayCategory()return 'Weapon'end;function item:getTex()return getTexture('native weapon')end;function item:getActualWeight()return 1 end;inventory.items[i]=item end
instanceof=function(o,kind)return o and o.kind==kind end
local p={md={},style=dragon.id,equipped=true,slots={left=dragon.id},dead=false,busy=false,joypad=-1}
function p:getModData()return self.md end;function p:getPlayerNum()return 0 end;function p:getInventory()return inventory end;function p:getPrimaryHandItem()return inventory.items[1]end
function p:isDead()return self.dead end;function p:getVehicle()return self.vehicle end;function p:isLocalPlayer()return true end;function p:getJoypadBind()return self.joypad end
function p:getBodyDamage()return {getOverallBodyHealth=function()return 83 end}end
Perks={None=0};local perkList={}
for i=1,25 do
 local perk={id=i};function perk:getType()return self.id end;function perk:getName()return 'Skill '..self.id end;function perk:getParent()return 1 end;function perk:getXpForLevel(level)return level*100 end;perkList[i]=perk
end
PerkFactory={PerkList={size=function()return #perkList end,get=function(_,i)return perkList[i+1]end}}
function p:getPerkLevel()return 2 end;function p:getXp()return {getXP=function()return 450 end}end
local inventoryOpened=false
getPlayerInventory=function()return {setVisible=function()inventoryOpened=true end}end
ISInventoryPaneContextMenu={equipWeapon=function()equipped=equipped+1 end,createMenu=function()inventoryOpened=true end}
PY.StyleSelector={allowed=function(who)return who and not who.dead and not who.busy and not who.vehicle end,loadAssets=function()end,styleIcon=function()return nil end}
local original=function(who)legacy=legacy+1;PY.StyleSelector.setup={legacy=true,close=function()PY.StyleSelector.setup=nil end};return true end
PY.StyleSelector.openSetup=original
setJoypadFocus=function(num,panel)local state=JoypadState.players[num+1];state.focus=panel;if panel and panel.onGainJoypadFocus then panel:onGainJoypadFocus(state)end end
do local _="ProjectYakuzaFixture:PHONEDATA" end
do local _="ProjectYakuzaFixture:PHONEGLYPHS" end
do local _="ProjectYakuzaFixture:PHONEFONT" end
do local _="ProjectYakuzaFixture:PHONEITEMS" end
do local _="ProjectYakuzaFixture:PHONEPREVIEW" end
do local _="ProjectYakuzaFixture:PHONESTYLES" end
do local _="ProjectYakuzaFixture:PHONEMATERIAL" end
do local _="ProjectYakuzaFixture:PHONEPANEL" end
do local _="ProjectYakuzaFixture:PHONEBOOT" end
check(D.compatible('0.133.0')and D.compatible('1.0.0')and not D.compatible('0.132.0')and not D.compatible('invalid'),'dev menu enforces its shared polished combat baseline')
D.install();D.install();check(PY.StyleSelector.openSetup==D.open and D.legacyOpenSetup==original,'menu hook installs once and preserves the original settings')
check(D.open(p),'render timing regression opens the phone')
local smooth=D.panel;local priorOpen=0
for frame=1,6 do
 clock=clock+16;smooth:prerender();smooth.screen:prerender()
 check(smooth.open>priorOpen,'animation advances on every 16ms render without a single 100ms UI update');priorOpen=smooth.open
 check(near(smooth.rotation.x,-math.deg(smooth.pose.rz))and near(smooth.rotation.z,math.deg(smooth.pose.rx)),'model uses the newly rendered pose before its screen overlay')
 local x,y,z=M.screenPoint(smooth.pose,0,0)
 check(near(smooth.screen.quad[1][1],smooth.scene.width/2+z*mult*smooth.scene.width/1366,.001)and near(smooth.screen.quad[1][2],smooth.height/2-y*mult*smooth.scene.width/1366,.001),'screen and model remain on the same rendered frame')
end
check(projectionCalls==0,'rendering eliminates repeated native projection/matrix calculations')
D.clear()
local function advance(ms)for i=1,math.ceil(ms/20)do clock=clock+20;if D.panel then D.panel:prerender();D.panel:update();if D.panel and D.panel:submenu()then D.panel:submenu():prerender()end end end end
local function open()check(D.open(p),'phone opens through the optional menu hook');advance(600);return D.panel end
local panel=open();check(panel.page==2 and panel.wantsKeys and manager[panel],'equipment is the saved-reference default and input belongs to the visible phone')
panel:prerender();panel.screen:prerender();panel.rows:prerender();check(draws>50 and not panel.rows.stencil,'native phone screen and page draw without leaking clipping')
projectedDraws=0;panel.screen:prerender();check(projectedDraws<=310,'projected labels and phone tiles have a bounded draw budget')
check(panel.rows.items[1].level==2 and near(panel.rows.items[1].progress,.5),'Items preview shows actual PZ skill levels and XP progress')
for i,color in ipairs(D.appColors)do if i~=4 then check(color[1]<.9 and color[2]<.9 and color[3]<.9,'every monochrome app has a readable colour on its white tile')end end
local oldSplits=uiTextureSplits;textDraws={};panel.screen:prerender()
check(#textDraws==0 and uiTextureSplits==oldSplits,'handset captions reuse actual font glyphs on the screen without floating native strings')
local localQuad=M.project(M.pose(1,.5,-.4,false,true),600,900);glyphQuads={}
local beforeMeasures=textMeasures;D.Font.projected(panel.screen,localQuad,'WWW iii',160,100,1,20,180)
check(#glyphQuads==7 and textMeasures==beforeMeasures,'handset glyph layout uses real font advances without repeated native measurement')
for _,q in ipairs(glyphQuads)do
 local dx,dy=q[3]-q[1],q[4]-q[2];local ex,ey=localQuad[2][1]-localQuad[1][1],localQuad[2][2]-localQuad[1][2]
 check(math.abs(dx*ey-dy*ex)<.001,'every glyph baseline follows the physical screen edge')
 local dx,dy=q[7]-q[1],q[8]-q[2];local ex,ey=localQuad[4][1]-localQuad[1][1],localQuad[4][2]-localQuad[1][2]
 check(math.abs(dx*ey-dy*ex)<.001,'every glyph side follows the physical screen tilt')
end
local first=D.Font.handsetLayout('iii',20,180);local second=D.Font.handsetLayout('WWW',20,180)
check(first.width<second.width,'projected captions retain original proportional font metrics')
local wrapped=D.Font.wrap('Long localized description with words and line breaks\nSecond paragraph',22,170)
for _,line in ipairs(wrapped)do check(D.Font.measure(line,22)<=170.001,'native font metrics constrain wrapped text to the available width')end
check(D.Font.measure('iii',22)<D.Font.measure('WWW',22),'native proportional text preserves narrow and wide letter spacing')
local oldHeat=panel.heatStocks
for _,value in ipairs({0,2,6})do
 panel.heatStocks=value;fullOrbDraws=0;panel.screen:prerender();check(fullOrbDraws==value,'only full heat stocks draw the filled core')
end
panel.heatStocks=oldHeat;check(panel.orbFill.x==266 and panel.orbFill.y==72 and panel.orbFill.w==68,'filled stocks use the source luminous core rather than the empty glass')
local level,r,g,b,label=M.battery(100);check(level==1 and g>r and label=='100%','full-health battery is full and green')
level,r,g,b,label=M.battery(0);check(level==0 and r>g and label=='0%','zero-health battery is empty and red')
level,r,g,b,label=M.battery(50);check(level==.5 and label=='50%','battery fill and percentage follow overall health')
check(near(panel.batteryLevel,.83)and panel.batteryLabel=='83%','cached status bar uses actual overall body health')
panel.focusRows=false;panel:activatePage();check(panel.activeItems and not panel.focusRows,'pressing Items opens a separate categorized inventory')
local ix,iy=M.point(panel.screen.quad,160/320,313/568);panel.screen:onMouseDown(ix,iy);check(panel.page==2,'Items overlay blocks clicks on phone apps behind it')
panel.row=2;panel.rows:onMouseDown(50,0);check(panel.row==2,'Items overlay blocks clicks on preview rows behind it')
advance(200);nameReads=0;panel.activeItems:refresh();check(nameReads==#inventory.items,'categorized inventory reads each matching name once')
local scans=inventoryScans;advance(1200);check(inventoryScans==scans,'open inventory avoids repeated rescans between refresh intervals');advance(400);check(inventoryScans==scans+1,'open inventory continues to refresh live carried items')
panel:onKeyPress(Keyboard.KEY_ESCAPE);advance(200);check(not panel.activeItems and D.panel==panel,'Items back transition returns to the phone instead of closing it')
local pref=D.preferences(p);pref.tilt=false;advance(20);local writes=vectorWrites;advance(100);check(vectorWrites==writes,'settled phone avoids rewriting unchanged native model transforms');pref.tilt=true
check(panel.rows:onMouseWheel(3)==true and panel.rows.offset>0 and panel:onMouseWheel(1)==true,'inventory wheel scrolls and cannot zoom the world')
panel.focusRows=false;panel:onKeyPress(Keyboard.KEY_RIGHT);check(panel.page==3,'arrow navigation changes phone apps');panel:onKeyPress(Keyboard.KEY_TAB);check(panel.focusRows,'Tab moves to the page rows')
panel:selectPage(5);panel.row=1;panel.focusRows=true;panel:onKeyPress(Keyboard.KEY_RIGHT);check(options.musicVolume:getValue()==110 and saves==1,'audio adjusts and persists through the existing mod-options API')
for i=1,30 do panel:onKeyPress(Keyboard.KEY_RIGHT)end;check(options.musicVolume:getValue()==200,'volume is clamped to the shared option limit')
panel:selectPage(6);panel.row=1;panel:activateRow();check(p.md.ProjectYakuzaHitEffectsDisabled,'effect setting uses the core toggle');panel:activateRow();check(not p.md.ProjectYakuzaHitEffectsDisabled,'effect toggle restores the shared setting')
panel:selectPage(1);panel.row=4;panel:activateRow();check(assigned==1,'style quick slots use the existing style-slot API')
panel.row=2;local before=equipped;panel:activateRow();check(panel.closing and equipped==before,'equip waits for the closing animation');advance(400);check(not D.panel and not PY.StyleSelector.setup and not panel.wantsKeys and not manager[panel]and equipped==before+1,'closing releases input and then runs the selected combat action')
panel=open();panel:selectPage(2);panel:activatePage();advance(200);before=equipped;panel.activeItems:activate();p.dead=true;advance(20);check(not D.panel and equipped==before,'death cancels a pending equip callback');p.dead=false
panel=open();panel:selectPage(2);panel:activatePage();advance(200);local weapon=panel.activeItems.items[1].item;weapon.missing=true;panel.activeItems:activate();check(not panel.closing and panel.activeItems.message~=nil,'a removed inventory item cannot be equipped through a stale row');weapon.missing=false;panel.activeItems:close();advance(200)
panel:selectPage(9);for i,row in ipairs(panel.rows.items)do if row.label=='Advanced mod settings'then panel.row=i end end;panel:activateRow();advance(400);check(legacy==1 and PY.StyleSelector.setup.legacy and not D.panel,'advanced settings hands off to the original mod menu');PY.StyleSelector.setup:close()
panel=open();panel:selectPage(9);panel.row=1;panel:activateRow();check(D.preferences(p).tilt==false,'phone tilt preference toggles');panel.row=2;panel:activateRow();check(D.preferences(p).reduceMotion,'reduced-motion preference toggles');D.clear();check(not D.panel and not manager[panel],'saving or leaving removes the optional phone immediately')
panel=open();ISWorldMap_instance={isVisible=function()return true end};advance(20);check(not D.panel,'opening the map clears the phone');ISWorldMap_instance=nil
panel=open();textEntry=true;advance(20);check(not D.panel,'chat text entry releases phone input');textEntry=false
panel=open();viewportWidth=1280;advance(20);check(not D.panel,'viewport changes close the phone cleanly');viewportWidth=1600
viewportWidth=900;viewportHeight=1000;panel=open();check(panel.panelW>300 and panel.scene.width<viewportWidth*.5,'narrow viewports retain a usable phone and page panel');D.clear();viewportWidth=1600;viewportHeight=900
p.joypad=0;local prior={};JoypadState.players[1]={focus=prior};panel=open();check(panel.gamepad and JoypadState.players[1].focus==panel,'controller focus moves to the dev menu');panel:onJoypadDown(Joypad.YButton);check(panel.focusRows,'controller focus changes between phone and list');panel:onJoypadDown(Joypad.BButton);advance(400);check(JoypadState.players[1].focus==prior and not D.panel,'closing restores the previous controller focus');p.joypad=-1;JoypadState.players[1]=nil
failModel=true;check(D.open(p)and legacy==2 and D.panel==nil and PY.StyleSelector.setup.legacy,'a native model failure restores the old menu without retaining input');failModel=false;PY.StyleSelector.setup:close()
check(panel:isKeyConsumed(Keyboard.KEY_ESCAPE)and not panel:isKeyConsumed(Keyboard.KEY_W),'phone keys are consumed without disabling player movement')
panel=open();check(uiSounds[#uiSounds]=='ProjectYakuzaPhoneDev_PhoneOpen','opening the phone plays its dedicated local Y6 cue')
panel:selectPage(1);panel.focusRows=false;panel:activatePage();local styles=panel.activeStyles
check(panel:isKeyConsumed(Keyboard.KEY_F),'favorite key is consumed while Styles is open rather than toggling the game flashlight')
check(styles and #styles.styles==2 and styles.styles[1].name=='Dragon of Dojima','Styles opens the registered style names')
styles:toggleFavorite(1);check(D.preferences(p).favorites[dragon.id]==true,'heart favorites persist in per-character mod data')
styles:onKeyPress(Keyboard.KEY_F);check(not D.preferences(p).favorites[dragon.id],'keyboard toggles the same saved favorite')
styles:onMouseDown(styles.geometry.pad+styles.geometry.listW-24,styles.geometry.top+22)
check(D.preferences(p).favorites[dragon.id]and styles.selected==1,'heart click toggles a favorite without assigning or switching a style')
check(styles.heart.path=='media/textures/ProjectYakuzaPhoneDev/FavoriteHeart.png','heart comes from the requested icon pack rather than a game icon')

advance(200);check(styles.preview.path=='media/textures/ProjectYakuzaPhoneDev/DragonOfDojima.png'and #styles.description>0,'Dragon preview uses the supplied compressed image alongside its description')
check(panel.scene.visible==false and panel.rows.visible==false,'opaque submenus skip the hidden phone model and preview list')
local slotCount=assigned;styles:activate();check(assigned==slotCount+1 and p.slots.left==dragon.id and not panel.closing,'first action assigns the first slot without equipping')
styles:onKeyPress(Keyboard.KEY_RIGHT);styles:activate();check(p.slots.right==dragon.id and not panel.closing,'second action assigns the second slot without equipping')
check(#D.Styles.actions==2 and styles.geometry.tabRows==0,'Dragon has only two slot buttons and no preview tabs')
check(styles.theme.accent[3]==1 and styles.theme.accent[2]>.7,'Dragon uses its light blue theme')
styles:onKeyPress(Keyboard.KEY_DOWN);check(styles.selected==2 and #styles.styles[2].previews==0,'additional styles retain safe missing-preview states')
panel:onKeyPress(Keyboard.KEY_ESCAPE);advance(200);check(not panel:submenu()and D.panel==panel and panel.scene.visible,'back restores the phone and its model visibility')
D.clear()
local priorList=PY.listStyles
PY.listStyles=function()return {{id='z',name='Zulu',description=''},{id='b',name='alpha',description=''},{id='a',name='Alpha',description=''}}end
panel=open();panel:selectPage(1);panel:activatePage();styles=panel.activeStyles
check(styles.styles[1].id=='a'and styles.styles[2].id=='b'and styles.styles[3].id=='z','styles sort case-insensitively by name with deterministic ID ties')
D.clear();PY.listStyles=priorList
local front=M.pose(1,0,0,false,true);local _,_,frontZ=M.transform(front,-.39,0,3.6);local _,_,backZ=M.transform(front,.39,0,3.6)
check(near(front.ry,math.rad(6)),'original phone angle stays unchanged while the material gains lighting')
panel=open();panel.material:prerender();local lit=panel.material.draws
check(#lit>0 and #lit<=D.Material.maxFaces,'casing lighting uses a bounded set of original surface polygons')
local dark,bright=0,1;for _,face in ipairs(lit)do dark=math.max(dark,face.shade);bright=math.min(bright,face.shade);check(face.specular<=.27 and face.shade<=.45,'material response stays below an opaque or blown-out finish')end
check(dark-bright>.1,'different original casing normals receive distinct directional shading')
local beforeMaterial=projectedDraws;panel.material:prerender()
check(projectedDraws-beforeMaterial==#panel.material.draws,'each visible material polygon uses one combined light/shade draw')
for _,openAmount in ipairs({.1,.5,1})do for _,shade in ipairs({.05,.3,.45})do for _,spec in ipairs({0,.02,.26})do
 local dark=openAmount*shade;local shine=spec>.005 and openAmount*spec or 0;local alpha=dark+shine*(1-dark);local light=shine/alpha
 for _,base in ipairs({0,.3,1})do check(near(base*(1-dark)*(1-shine)+.91*shine,base*(1-alpha)+.91*light*alpha),'one material pass is algebraically identical to the previous two-layer composite')end
end end end
local cached=panel.material.draws;panel.material:prerender();check(panel.material.draws==cached,'settled lighting geometry is cached rather than transformed every frame');D.clear()
local firstFrame='media/textures/ProjectYakuza/HeatHUD/OriginalDragonAtlas.png'
local secondFrame='media/textures/ProjectYakuza/HeatHUD/OriginalCombatAtlas.png'
other.phoneMenu={theme={accent='#DD3366',background={.03,.01,.02},text={.98,.94,.95}},previews={{label='Stance',image=firstFrame},{label='Combo',animation={frames={firstFrame,secondFrame},durations={40,90},loops=0}}}}
other.description=string.rep('A long creator description wraps into readable lines and scrolls without covering the preview or buttons. ',12)
panel=open();panel:selectPage(1);panel:activatePage();advance(200);styles=panel.activeStyles;styles:select(2);styles:prerender()
check(near(styles.theme.accent[1],221/255)and styles.geometry.tabRows==1,'full registered style metadata supplies creator colours and preview tabs')
styles:onKeyPress(Keyboard.KEY_TAB);check(styles.previewIndex==2,'Tab selects an animated creator preview')
local texture,index=D.Preview.texture(styles.previewState,styles.previewState.at+39);check(index==1 and texture.path==firstFrame,'animated preview respects its first original frame delay')
texture,index=D.Preview.texture(styles.previewState,styles.previewState.at+40);check(index==2 and texture.path==secondFrame,'animated preview advances at the specified delay')
texture,index=D.Preview.texture(styles.previewState,styles.previewState.at+130);check(index==1,'animated preview loops on its own total duration')
local finite=D.Preview.animation({frames={firstFrame,secondFrame},durations={40,90},loops=1});check(D.Preview.frame(finite,10000)==2,'finite GIF previews retain their final frame')
check(not D.Preview.animation({frames={firstFrame},durations={0}}),'invalid frame timings do not enter playback')
local pending=styles.previewState.cache[secondFrame];pending.isReady=function()return false end
check(D.Preview.texture(styles.previewState,styles.previewState.at+40).path==firstFrame,'an unready preview frame retains the previous ready image')
fontReady=false;check(D.Preview.texture(styles.previewState,styles.previewState.at+40)==nil,'a reloading fallback image cannot draw a missing texture');fontReady=true;pending.isReady=function()return true end
styles:getMouseX();mouseX=styles:getAbsoluteX()+styles.geometry.x+10;styles:onMouseWheel(1);check(styles.descriptionOffset>0,'long descriptions scroll independently of style selection')
local g=styles.geometry;styles:onMouseDown(g.x+4,g.tabsY+4);check(styles.previewIndex==1,'preview tabs above the image select the matching static preview')
D.clear()
for _,viewport in ipairs({{640,480},{800,600},{1024,768},{1920,1080}})do
 viewportWidth,viewportHeight=viewport[1],viewport[2];panel=open();panel:selectPage(1);panel:activatePage();advance(200);styles=panel.activeStyles;styles:select(2)
 textDraws={};styles:prerender();g=styles.geometry
 check(g.imageY+g.imageH<=g.descriptionY and g.descriptionY+g.descriptionH<=g.buttonY+.001 and g.buttonY+g.buttonH<g.footerY,'preview, description, slot buttons and footer have separate bounded regions')
 for _,draw in ipairs(textDraws)do check(draw.x>=styles:getAbsoluteX()-1 and draw.x+draw.width<=styles:getAbsoluteX()+styles.width+1 and draw.y>=styles:getAbsoluteY()and draw.y+draw.height<=styles:getAbsoluteY()+styles.height,'native style text stays inside the actual viewport panel')end
 styles:select(1);check(styles.geometry.tabRows==0,'Dragon remains a single image without preview buttons at every viewport size');D.clear()
end
viewportWidth,viewportHeight=1600,900
check(PY.VERSION=='0.133.0'and PY.Heat.stocks(p)==2,'dev interface does not replace combat version or grant heat')
return 'PASS '..checks..' native projection, inverse input, alpha centring, pages, scrolling, options, actions, fallback and lifecycle assertions'
