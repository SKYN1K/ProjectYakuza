getKeyName=function(k)return tostring(k)end
local count=0
local function check(ok,message)count=count+1;if not ok then error(message) end end
require=function()end
local keys={};local paused,typing,busy=false,false,false
Keyboard={KEY_Z=44,KEY_LEFT=203,KEY_RIGHT=205,KEY_UP=200,KEY_DOWN=208,KEY_ESCAPE=1}
isKeyDown=function(key)return keys[key]==true end
isGamePaused=function()return paused end
local clock=1000
getTimestampMs=function()return clock end
getCore=function()return {isDoingTextEntry=function()return typing end}end
local mx,my=500,500
getMouseX=function()return mx end;getMouseY=function()return my end
getPlayerScreenLeft=function()return 0 end;getPlayerScreenTop=function()return 0 end
getPlayerScreenWidth=function()return 1280 end;getPlayerScreenHeight=function()return 720 end
UIFont={Small=1,Medium=2}
local function event()local e={listeners={}};e.Add=function(fn)e.listeners[fn]=true end;e.Remove=function(fn)e.listeners[fn]=nil end;return e end
Events={OnPlayerUpdate=event(),OnTick=event(),OnKeyStartPressed=event(),OnGameStart=event(),OnSave=event(),OnMainMenuEnter=event()}
local textures={}
getTexture=function(path)
 if not textures[path] then textures[path]={width=path:find('Background') and 1024 or path:find('Life') and 512 or 128,height=path:find('Background') and 512 or 128,path=path}end
 return textures[path]
end
local draws={}
local rectangles={}
function advance(ms)clock=clock+ms end
ISPanel={}
function ISPanel:derive(name)local t={Type=name};t.__index=t;setmetatable(t,{__index=self});return t end
function ISPanel:new(x,y,w,h)return setmetatable({x=x,y=y,width=w,height=h,children={}},self)end
function ISPanel:initialise()end
function ISPanel:prerender()end
function ISPanel:update()end
function ISPanel:addChild(child)table.insert(self.children,child)end
function ISPanel:setWantMouseEvents(value)self.mouseEvents=value end
function ISPanel:addToUIManager()self.added=true end
function ISPanel:removeFromUIManager()self.added=false end
function ISPanel:getX()return self.x end
function ISPanel:getY()return self.y end
function ISPanel:drawSubTexture(t,x,y,w,h,dx,dy,dw,dh,...)
 check(x>=0 and y>=0 and x+w<=t.width and y+h<=t.height,'atlas crop inside original pixels')
 if t.path:find('KiwamiLife') and x==0 and y==0 and w==43 and h==44 then check(dw>=80 and dh>=80,'style-ring artwork is used only at slot size, never as duplicated centre circles') end
 draws[#draws+1]={texture=t.path,x=x,y=y,w=w,h=h,dx=dx,dy=dy,dw=dw,dh=dh}
end
function ISPanel:drawTextureScaled(t,...)draws[#draws+1]={texture=t.path}end
function ISPanel:drawRect(x,y,w,h,a,r,g,b)
 check(w>=0 and h>=0 and a>=0 and a<=1,"valid backdrop bounds and alpha")
 rectangles[#rectangles+1]={x=x,y=y,w=w,h=h,a=a}
end
function ISPanel:drawTextCentre(...)end
function ISPanel:drawText(...)end
ISComboBox=ISPanel:derive('combo')
function ISComboBox:new(x,y,w,h)local o=ISPanel.new(self,x,y,w,h);o.options={};o.selected=1;return o end
function ISComboBox:addOptionWithData(label,data)table.insert(self.options,{text=label,data=data})end
function ISComboBox:getOptionData(index)return self.options[index].data end
ISButton=ISPanel:derive('button')
function ISButton:new(x,y,w,h,label,target,callback)local o=ISPanel.new(self,x,y,w,h);o.target=target;o.callback=callback;return o end
local p={data={},dead=false,vehicle=nil,equipped=false}
function p:getModData()return self.data end
function p:isLocalPlayer()return true end
function p:isDead()return self.dead end
function p:getVehicle()return self.vehicle end
function p:getPrimaryHandItem()return self.equipped and {getFullType=function()return ProjectYakuza.TOKEN end} or nil end
getSpecificPlayer=function()return p end
do local _="ProjectYakuzaFixture:MODULES" end
local ProjectYakuza=ProjectYakuza;local slots=ProjectYakuza.StyleSlots;local selector=ProjectYakuza.StyleSelector
ProjectYakuza.isBusy=function()return busy end
local equips=0
ProjectYakuza.equipStyle=function(player,id)local ok=ProjectYakuza.selectStyle(player,id);if ok then player.equipped=true;equips=equips+1 end end
ProjectYakuza.unequipStyle=function(player)player.equipped=false;return ProjectYakuza.selectStyle(player,'none')end
local function style(id,name)
 return {id=id,name=name,lightAttacks={{animation='Bob_AttackPunch01_Hit',nodeValue=id,duration=1}}}
end
ProjectYakuza.registerStyle(style('dragon_of_dojima','Dragon of Dojima'))
check(slots.id(p,'left')=='dragon_of_dojima' and slots.id(p,'right')==nil,'default DoD and empty second slot')
local saved=slots.get(p);check(slots.get(p)==saved,'assignments persist without reset')
check(not slots.assign(p,'top','dragon_of_dojima'),'top cannot be assigned')
check(not slots.assign(p,'bottom','dragon_of_dojima'),'bottom reserved for setup')
check(not slots.assign(p,'right','missing'),'unknown style rejected')
check(slots.direction(0,0)==nil,'deadzone cancels')
check(slots.direction(-60,0)=='left' and slots.direction(60,0)=='right','horizontal directions')
check(slots.direction(0,-60)=='top' and slots.direction(0,60)=='bottom','vertical directions')
keys[Keyboard.KEY_Z]=true
check(selector.open(p),'open while on foot')
check(selector.wheel.mouseEvents==false,'wheel never captures game mouse')
check(Events.OnTick.listeners[selector.tick],'tick installed only while open')
selector.wheel:prerender()
check(selector.wheel.focus.left==0,'opening begins without a selection snap')
advance(140);selector.wheel:prerender()
check(selector.wheel.focus.left>0 and selector.wheel.focus.left<1,'selection eases over render time')
advance(400);selector.wheel:prerender()
check(rectangles[1].a==0,'background begins transparent')
local dim=false
for _,rect in ipairs(rectangles) do if rect.w==1280 and rect.h==720 and rect.a>0 then dim=true end end
check(not dim,'compact wheel keeps gameplay visible without full-screen backdrop')
check(selector.wheel:onMouseDown()==false and selector.wheel:onRightMouseDown()==false,'animated wheel preserves mouse passthrough')
keys[Keyboard.KEY_Z]=false;selector.tick()
check(equips==1 and ProjectYakuza.isEquipped(p),'release equips default style')
check(selector.wheel==nil and not Events.OnTick.listeners[selector.tick],'release removes wheel and tick')
keys[Keyboard.KEY_Z]=true;selector.open(p);keys[Keyboard.KEY_UP]=true;selector.tick();keys[Keyboard.KEY_UP]=false;keys[Keyboard.KEY_Z]=false;selector.tick()
check(equips==1 and p.data.ProjectYakuzaStyle=='none' and not ProjectYakuza.isEquipped(p),'top unequips the active style')
keys[Keyboard.KEY_Z]=true;selector.open(p);keys[Keyboard.KEY_RIGHT]=true;selector.tick();keys[Keyboard.KEY_RIGHT]=false;keys[Keyboard.KEY_Z]=false;selector.tick()
check(equips==1,'empty right leaves current style alone')
keys[Keyboard.KEY_Z]=true;selector.open(p);keys[Keyboard.KEY_DOWN]=true;selector.tick();keys[Keyboard.KEY_DOWN]=false;keys[Keyboard.KEY_Z]=false;selector.tick()
check(selector.setup and selector.wheel==nil,'bottom release opens assignment menu')
check(#selector.setup.right.options==2,'only empty and registered styles listed')
selector.setup:prerender();advance(320);selector.setup:prerender()
check(selector.setup.background==false,'setup uses shared backdrop without vanilla opaque fill')
selector.setup.right.selected=2;selector.setup:close()
check(slots.id(p,'right')==nil,'cancel discards assignments')
ProjectYakuza.registerStyle(style('addon.example','Late registered style'))
selector.openSetup(p);check(#selector.setup.right.options==3,'late add-on appears automatically')
selector.setup.right.selected=3;selector.setup:save()
check(slots.id(p,'right')=='addon.example' and equips==1,'save configures slot without equipping')
keys[Keyboard.KEY_Z]=true;selector.open(p);keys[Keyboard.KEY_RIGHT]=true;selector.tick();keys[Keyboard.KEY_RIGHT]=false;keys[Keyboard.KEY_Z]=false;selector.tick()
check(equips==2 and ProjectYakuza.getPlayerStyle(p).id=='addon.example','right selects assigned add-on style')
keys[Keyboard.KEY_Z]=true;selector.open(p);selector.wheel:prerender();keys[Keyboard.KEY_ESCAPE]=true;selector.tick();keys[Keyboard.KEY_ESCAPE]=false
check(selector.wheel==nil and equips==2,'escape cancels without switching')
for _,flag in ipairs({'typing','paused','busy','dead','vehicle'}) do
 typing=flag=='typing';paused=flag=='paused';busy=flag=='busy';p.dead=flag=='dead';p.vehicle=flag=='vehicle' and {} or nil
 check(not selector.open(p),'blocked while '..flag)
end
typing=false;paused=false;busy=false;p.dead=false;p.vehicle=nil
keys[Keyboard.KEY_Z]=true;selector.open(p);busy=true;keys[Keyboard.KEY_Z]=false;selector.tick();busy=false
check(selector.wheel==nil and equips==2,'attack beginning while open cancels wheel')
selector.openSetup(p);ProjectYakuza.styles['addon.example']=nil;selector.setup.right.selected=3
selector.setup:save();check(selector.setup~=nil,'unloaded selected style prevents partial save');selector.setup:close()
check(saved.right=='addon.example' and slots.id(p,'right')==nil,'missing addon saved ID preserved but treated as empty')
ProjectYakuza.registerStyle(style('addon.example','Restored style'));check(slots.id(p,'right')=='addon.example','restored addon resolves again')
local vehicles=0;ISVehicleMenu={onKeyStartPressed=function()vehicles=vehicles+1 end}
Events.OnKeyStartPressed.Add(ISVehicleMenu.onKeyStartPressed);selector.vehicleKeyGuard()
ISVehicleMenu.onKeyStartPressed(Keyboard.KEY_Z);check(vehicles==0,'on-foot selector suppresses vanilla Z seat menu')
p.vehicle={};ISVehicleMenu.onKeyStartPressed(Keyboard.KEY_Z);p.vehicle=nil
check(vehicles==1,'Z retains seat menu inside vehicle')
ISVehicleMenu.onKeyStartPressed(99);check(vehicles==2,'other vehicle keys retained')
keys[Keyboard.KEY_Z]=true;selector.open(p)
mx=selector.wheel.x+170;my=selector.wheel.y+290;selector.tick();check(selector.wheel.side=='bottom','mouse picks bottom')
selector.clear();check(selector.wheel==nil and selector.setup==nil and not Events.OnTick.listeners[selector.tick],'save/menu cleanup removes transient UI')
selector.clear()
local toggled={hits=0,aura=0}
ProjectYakuza.HitEffects={toggle=function(player)local d=player:getModData();d.ProjectYakuzaHitEffectsDisabled=not d.ProjectYakuzaHitEffectsDisabled;toggled.hits=toggled.hits+1 end}
ProjectYakuza.HeatAura={toggle=function(player)local d=player:getModData();d.ProjectYakuzaHeatAuraDisabled=not d.ProjectYakuzaHeatAuraDisabled;toggled.aura=toggled.aura+1 end}
ProjectYakuza.diagnosticLine=function()return 'settings diagnostics' end
selector.openSetup(p)
check(#selector.setup.settings==3,'all inventory settings moved into three rows')
check(selector.setup.settings[1].selected==1 and selector.setup.settings[2].selected==1 and selector.setup.settings[3].selected==2,'existing effect defaults and diagnostics state respected')
selector.setup.settings[1].selected=2;selector.setup:close()
check(toggled.hits==0 and not p.data.ProjectYakuzaHitEffectsDisabled,'cancel discards effect preference edits')
selector.openSetup(p);selector.setup.settings[1].selected=2;selector.setup.settings[2].selected=2;selector.setup.settings[3].selected=1
selector.setup:save()
check(toggled.hits==1 and toggled.aura==1 and p.data.ProjectYakuzaDiagnostics==true,'save applies effects through existing cleanup helpers and diagnostics')
selector.openSetup(p)
check(selector.setup.settings[1].selected==2 and selector.setup.settings[2].selected==2 and selector.setup.settings[3].selected==1,'settings restored on reopening')
selector.setup:save();check(toggled.hits==1 and toggled.aura==1,'saving unchanged preferences never retoggles')
local addon=ProjectYakuza.getStyle('addon.example');addon.selectorIcon='media/textures/AddonStyle.png'
check(selector.styleIcon(addon)==getTexture(addon.selectorIcon),'developer-supplied style icon resolved')
check(selector.styleIcon(nil)==nil,'empty style has no invented icon')
selector.openSetup(p);keys[Keyboard.KEY_ESCAPE]=true;selector.setup:update();keys[Keyboard.KEY_ESCAPE]=false
check(selector.setup==nil,'escape closes settings without saving')
local selected=0
ProjectYakuza.StyleEntry={request=function(who,id)check(who==p and id=='dragon_of_dojima','same-slot entry gets selected style');selected=selected+1 end}
p.data.ProjectYakuzaStyle='dragon_of_dojima';p.equipped=true;keys[Keyboard.KEY_Z]=true
selector.open(p);selector.wheel.side='left';keys[Keyboard.KEY_Z]=false;selector.finish()
check(selected==1,'explicit reselect of the current style requests its entry')
return 'PASS '..count..' selector persistence, input, assignment, add-on and original-atlas checks'
