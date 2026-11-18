require "ProjectYakuzaPhoneDev/PhoneData"
require "ISUI/ISPanelJoypad"
require "ISUI/ISPanel"
require "Vehicles/ISUI/ISUI3DScene"
local PY=ProjectYakuza
local D=PY.PhoneDev
local M=D.Math
local Phone=ISPanelJoypad:derive("ProjectYakuzaPhoneDevPanel")
local Screen=ISPanel:derive("ProjectYakuzaPhoneDevScreen")
local Rows=ISPanel:derive("ProjectYakuzaPhoneDevRows")
D.PhonePanel=Phone
local function audio(self,cue)PY.UIAudio.play(self.player,cue)end
local function quad(panel,q,texture,x,y,w,h,r,g,b,a)
    local ax,ay=(q[2][1]-q[1][1])/320,(q[2][2]-q[1][2])/320
    local bx,by=(q[4][1]-q[1][1])/568,(q[4][2]-q[1][2])/568
    local x1,y1=q[1][1]+ax*x+bx*y,q[1][2]+ay*x+by*y
    local x2,y2=x1+ax*w,y1+ay*w;local x4,y4=x1+bx*h,y1+by*h
    local x3,y3=x2+bx*h,y2+by*h
    panel:drawTextureAllPoint(texture,x1,y1,x2,y2,x3,y3,x4,y4,r,g,b,a)
end
local function caption(panel,q,text,x,y,a)
    local px,py=M.point(q,x/320,y/568);panel:drawTextCentre(text,px,py,.94,.95,1,a,UIFont.Small)
end
function Screen:prerender()
    local host=self.host
    if host.closed or host.open<=.005 or math.cos(host.pose.rx)*math.cos(host.pose.ry)<.12 then self.quad=nil;return end
    local q=M.project(host.pose,self.width,self.height,self.quad);self.quad=q
    local alpha=host.open;local white=host.textures.Pixel
    for row=0,5 do local t=row/5;quad(self,q,white,0,row*568/6,320,568/6+1,.075+.12*t,.12-.025*t,.17+.055*t,alpha)end
    quad(self,q,white,0,0,320,26,0,0,0,alpha)
    caption(self,q,host.clockLabel,43,4,alpha)
    quad(self,q,host.textures.signal,254,5,22,15,1,1,1,alpha);quad(self,q,host.textures.battery,283,7,25,13,1,1,1,alpha)
    caption(self,q,"PROJECT YAKUZA",160,45,alpha)
    caption(self,q,host.styleLabel,160,73,alpha*.75)
    local heat=host.heatLevel
    caption(self,q,"HEAT",52,112,alpha*.9);quad(self,q,white,85,119,210,4,.05,.08,.12,alpha)
    quad(self,q,white,85,119,210*heat,4,.10,.60,1,alpha)
    for index,page in ipairs(D.pages)do
        local x,y,w,h=M.appRect(index);local selected=host.page==index
        quad(self,q,white,x-4,y-4,w+8,h+8,.03,.04,.06,alpha*.55)
        quad(self,q,white,x,y,w,h,.95,selected and .40 or .95,selected and .10 or .96,alpha*.96)
        local icon=host.icons[index];local ix,iy,iw,ih=icon[1],icon[2],icon[3],icon[4]
        local tint=page.id=="effects"and .20 or 1
        quad(self,q,host.textures[page.id],ix,iy,iw,ih,tint,tint,tint,alpha)
        caption(self,q,page.label,x+w/2,y+h+7,alpha)
    end
    quad(self,q,white,0,540,320,28,0,0,0,alpha*.94)
    caption(self,q,"Enter: select    Esc: close",160,545,alpha*.8)
end
function Screen:onMouseMove(dx,dy)
    if not self.quad or self.host.closing then return true end
    local index=M.hit(self.quad,self:getMouseX(),self:getMouseY())
    if index then self.host.focusRows=false;self.host:selectPage(index)end
    return true
end
function Screen:onMouseDown(x,y)
    if self.host.closing then return true end
    local index=self.quad and M.hit(self.quad,x,y)
    if index then self.host:selectPage(index);self.host.focusRows=true;audio(self.host,"confirm")end
    return true
end
function Screen:onMouseUp()return true end
function Screen:onMouseWheel()return true end
function Rows:maxScroll()return math.max(0,#self.items*self.rowHeight-self.height)end
function Rows:scroll(delta)
    self.offset=M.clamp(self.offset+delta*self.rowHeight,0,self:maxScroll())
end
function Rows:onMouseWheel(delta)self:scroll(delta);return true end
function Rows:onMouseMove()
    if self.host.closing then return true end
    local row=math.floor((self:getMouseY()+self.offset)/self.rowHeight)+1
    if row>=1 and row<=#self.items and row~=self.host.row then self.host.row=row;self.host.focusRows=true;audio(self.host,"cursor")end
    return true
end
function Rows:onMouseDown(x,y)
    local index=math.floor((y+self.offset)/self.rowHeight)+1
    if index<1 or index>#self.items then return true end
    self.host.row=index;self.host.focusRows=true
    local item=self.items[index];local delta
    if item.adjust then delta=x>self.width-64 and 1 or x>self.width-118 and -1 or 1 end
    self.host:activateRow(delta)
    return true
end
function Rows:onMouseUp()return true end
function Rows:prerender()
    local a=self.host.open;local selected=self.host.row
    self:setStencilRect(0,0,self.width,self.height)
    local first=math.max(1,math.floor(self.offset/self.rowHeight)+1);local last=math.min(#self.items,math.ceil((self.offset+self.height)/self.rowHeight))
    for i=first,last do
        local item=self.items[i];local y=(i-1)*self.rowHeight-self.offset;local active=i==selected and self.host.focusRows
        if active then self:drawRect(0,y,self.width,self.rowHeight,a*.25,.90,.35,.05);self:drawRect(0,y,3,self.rowHeight,a,.98,.51,.12)end
        self:drawRect(14,y+self.rowHeight-1,self.width-28,1,a*.16,.65,.69,.75)
        self:drawText(item.label,18,y+8,.95,.96,1,a,UIFont.Small)
        self:drawText(item.detail,18,y+29,.65,.72,.82,a*.9,UIFont.Small)
        if item.adjust then self:drawText("-     +",self.width-100,y+9,.98,.61,.27,a,UIFont.Medium)
        elseif item.action then self:drawText(">",self.width-31,y+16,.98,.61,.27,a,UIFont.Medium)end
    end
    self:clearStencilRect()
    if self:maxScroll()>0 then local h=math.max(28,self.height*self.height/(#self.items*self.rowHeight));local y=(self.height-h)*self.offset/self:maxScroll();self:drawRect(self.width-5,y,3,h,a*.75,.9,.51,.23)end
end
function Phone:initialise()
    ISPanelJoypad.initialise(self)
    self.textures={};for name,asset in pairs(D.assets)do self.textures[name]=getTexture(asset.path)end
    self.icons={};for index,page in ipairs(D.pages)do local x,y,w,h=M.appRect(index);self.icons[index]={M.iconRect(D.assets[page.id],x+w/2,y+h/2,46)}end
    local sw=math.min(self.height*.70,self.width*.48);self.scene=ISUI3DScene:new(0,0,sw,self.height);self.scene.background=false;self.scene:initialise();self:addChild(self.scene)
    local native=self.scene.javaObject
    for _,name in ipairs({"setDrawGrid","setDrawGridAxes","setDrawGridPlane","setDrawAttachments","setDrawGeometry"})do native:fromLua1(name,false)end
    native:fromLua1("setGizmoVisible","none");native:fromLua1("setView","Right");native:fromLua1("setZoom",1)
    native:fromLua2("createModel","xperia","ProjectYakuzaPhoneDev.Xperia")
    native:fromLua2("setModelUseWorldAttachment","xperia",false);native:fromLua2("setModelWeaponRotationHack","xperia",false)
    self.rotation=native:fromLua1("getObjectRotation","xperia");self.translation=native:fromLua1("getObjectTranslation","xperia");self.scale=native:fromLua1("getObjectScale","xperia")
    self.screen=Screen:new(0,0,sw,self.height);self.screen.host=self;self.screen.background=false;self.screen:initialise();self:addChild(self.screen)
    self.panelX=math.max(sw*.95,self.width*.43);self.panelW=self.width-self.panelX-28
    self.rows=Rows:new(self.panelX+8,self.height*.15+93,self.panelW-16,self.height*.70-112);self.rows.host=self;self.rows.items={};self.rows.offset=0;self.rows.rowHeight=59;self.rows.background=false;self.rows:initialise();self:addChild(self.rows)
    self:setWantKeyEvents(true);self:refresh();self:applyPose()
end
function Phone:applyPose()
    local pref=D.preferences(self.player);local tx,ty=0,0
    if not self.gamepad then tx=M.clamp((getMouseX()-self:getAbsoluteX()-self.scene.width/2)/(self.scene.width/2),-1,1);ty=M.clamp((getMouseY()-self:getAbsoluteY()-self.height/2)/(self.height/2),-1,1)end
    local blend=1-math.exp(-self.dt*14);self.pointerX=self.pointerX+(tx-self.pointerX)*blend;self.pointerY=self.pointerY+(ty-self.pointerY)*blend
    local pose=M.pose(self.open,self.pointerX,self.pointerY,pref.reduceMotion==true,pref.tilt~=false)
    local old=self.pose
    if old and math.abs(old.rx-pose.rx)<.000001 and math.abs(old.ry-pose.ry)<.000001 and math.abs(old.rz-pose.rz)<.000001 and math.abs(old.scale-pose.scale)<.000001 and math.abs(old.y-pose.y)<.000001 and math.abs(old.z-pose.z)<.000001 then return end
    self.pose=pose
    self.rotation:set(-math.deg(self.pose.rz),math.deg(self.pose.ry),math.deg(self.pose.rx))
    self.translation:set(self.pose.x,self.pose.y,self.pose.z);self.scale:set(self.pose.scale,self.pose.scale,self.pose.scale)
end
function Phone:refresh()
    self.rows.items=D.rows(self.player,D.pages[self.page].id);self.row=M.clamp(self.row,1,math.max(1,#self.rows.items));self.rows.offset=M.clamp(self.rows.offset,0,self.rows:maxScroll());self.refreshed=getTimestampMs()
    self:refreshHeader()
end
function Phone:refreshHeader()
    local hours=getGameTime():getTimeOfDay();self.clockLabel=string.format("%02d:%02d",math.floor(hours)%24,math.floor(hours%1*60))
    local style=PY.getPlayerStyle(self.player);self.styleLabel=style and style.name or"No style equipped"
    local rules=PY.Heat.rules(self.player);self.heatLevel=M.clamp(PY.Heat.stocks(self.player)/math.max(1,rules.maxStocks),0,1);self.headerAt=getTimestampMs()
end
function Phone:selectPage(index)
    index=M.clamp(index,1,#D.pages);if index==self.page then return end
    self.page=index;self.row=1;self.rows.offset=0;D.preferences(self.player).page=index;self:refresh();audio(self,"cursor")
end
function Phone:activateRow(delta)
    if self.closing then return end
    local item=self.rows.items[self.row];if not item then return end
    local fn=delta and item.adjust or item.action;if not fn then return end
    local ok,result,message=pcall(fn,delta)
    if not ok then print("[ProjectYakuza] Phone action failed: "..tostring(result));self.message="That action is not available right now."
    elseif result==false then self.message=message or"Finish your current action first."
    else self.message=nil;if not self.closing then audio(self,item.adjust and"toggle"or"confirm")end end
    if not self.closed then self:refresh()end
end
function Phone:prerender()
    if self.closed then return end
    self:animate(getTimestampMs())
    local a=self.open
    self:drawRect(0,0,self.width,self.height,a*.48,.015,.018,.026)
    self:drawRect(self.panelX,self.height*.15,self.panelW,self.height*.70,a*.88,.025,.027,.035)
    self:drawRect(self.panelX,self.height*.15,self.panelW,28,a*.94,.83,.84,.85)
    self:drawTextCentre(D.pages[self.page].label,self.panelX+self.panelW/2,self.height*.15+5,.04,.04,.045,a,UIFont.Small)
    self:drawText(D.pages[self.page].description,self.panelX+24,self.height*.15+49,.82,.86,.92,a,UIFont.Small)
    if self.page==1 or self.page==3 or self.page==4 then
        local selector=PY.StyleSelector;local style=PY.getPlayerStyle(self.player);local icon=selector.styleIcon and selector.styleIcon(style)
        if icon and selector.assets and icon==selector.assets.dragon then self:drawSubTexture(icon,8,23,112,82,self.panelX+self.panelW-84,self.height*.15+33,64,47,a*.8,1,1,1)
        elseif icon then self:drawTextureScaled(icon,self.panelX+self.panelW-75,self.height*.15+34,46,46,a*.8,1,1,1)end
    end
    self:drawRect(self.panelX+24,self.height*.15+82,self.panelW-48,1,a*.4,.61,.64,.7)
    self:drawText(self.message or(self.focusRows and"Select a row  |  Left / right adjusts audio"or"Choose an app"),self.panelX+23,self.height*.85+18,.85,.87,.93,a,UIFont.Small)
    self:drawText("Tab: change focus     Enter: select     Esc: close",self.panelX+23,self.height*.85+43,.62,.68,.77,a,UIFont.Small)
end
function Phone:update()
    ISPanelJoypad.update(self)
    if self.closed then return end
    local now=getTimestampMs()
    local index=self.player:getPlayerNum()
    if getPlayerScreenWidth(index)~=self.width or getPlayerScreenHeight(index)~=self.height or getCore():isDoingTextEntry()or self.player:isDead()or self.player:getVehicle()or PY.isBusy(self.player)or(ISWorldMap_instance and ISWorldMap_instance:isVisible())then self:close(true);return end
    if self.closing and self.open<=.001 and now>self.transitionAt then self:finishClose();return end
    if now-self.headerAt>400 then self:refreshHeader()end
    if now-self.refreshed>(self.page==2 and 1500 or 400)then self:refresh()end
end
function Phone:animate(now)
    self.dt=M.clamp((now-self.last)/1000,0,.10);self.last=now
    local target=self.closing and 0 or 1;local duration=self.closing and .28 or .48
    if D.preferences(self.player).reduceMotion then duration=.12 end
    local t=M.clamp((now-self.transitionAt)/1000/duration,0,1);self.open=self.fromOpen+(target-self.fromOpen)*M.ease(t)
    self:applyPose()
end
function Phone:finishClose()
    if self.closed then return end
    self.closed=true;self:setWantKeyEvents(false);self:removeFromUIManager()
    if PY.StyleSelector.setup==self then PY.StyleSelector.setup=nil end
    if D.panel==self then D.panel=nil end
    if self.joypadData and self.joypadData.focus==self then setJoypadFocus(self.player:getPlayerNum(),self.previousJoypad)end
    local action=self.afterClose;self.afterClose=nil
    if action and not self.player:isDead()and not self.player:getVehicle()and not PY.isBusy(self.player)then local ok,message=pcall(action);if not ok then print("[ProjectYakuza] Phone follow-up failed: "..tostring(message))end end
end
function Phone:close(silent,afterClose)
    if self.closed then return end
    if silent==true then self.afterClose=nil;self:finishClose();return end
    if self.closing then return end
    self.afterClose=afterClose;self.closing=true;self.fromOpen=self.open;self.transitionAt=getTimestampMs();audio(self,afterClose and"confirm"or"cancel")
end
function Phone:onMouseDown()return true end
function Phone:onMouseUp()return true end
function Phone:onMouseWheel()return true end
function Phone:onRightMouseDown()self:close();return true end
function Phone:onRightMouseUp()return true end
function Phone:isKeyConsumed(key)
    return key==Keyboard.KEY_ESCAPE or key==Keyboard.KEY_RETURN or key==Keyboard.KEY_NUMPADENTER or key==Keyboard.KEY_TAB or key==Keyboard.KEY_LEFT or key==Keyboard.KEY_RIGHT or key==Keyboard.KEY_UP or key==Keyboard.KEY_DOWN
end
function Phone:onKeyPress(key)
    if key==Keyboard.KEY_ESCAPE then self:close();return end
    if self.closing then return end
    if key==Keyboard.KEY_TAB then self.focusRows=not self.focusRows;audio(self,"cursor");return end
    if key==Keyboard.KEY_RETURN or key==Keyboard.KEY_NUMPADENTER then if self.focusRows then self:activateRow()else self.focusRows=true;audio(self,"confirm")end;return end
    local dx=key==Keyboard.KEY_LEFT and -1 or key==Keyboard.KEY_RIGHT and 1 or 0
    local dy=key==Keyboard.KEY_UP and -1 or key==Keyboard.KEY_DOWN and 1 or 0
    if self.focusRows then
        local item=self.rows.items[self.row];if dx~=0 and item and item.adjust then self:activateRow(dx)end
        if dy~=0 then self.row=M.clamp(self.row+dy,1,math.max(1,#self.rows.items));self.rows.offset=M.clamp((self.row-2)*self.rows.rowHeight,0,self.rows:maxScroll());audio(self,"cursor")end
    elseif dx~=0 or dy~=0 then local column=(self.page-1)%3;local row=math.floor((self.page-1)/3);self:selectPage(((row+dy)%3)*3+(column+dx)%3+1)end
end
function Phone:onGainJoypadFocus(data)self.gamepad=true;self.joypadData=data end
function Phone:onLoseJoypadFocus()self.gamepad=false end
function Phone:onJoypadDown(button)
    if button==Joypad.BButton then self:close()
    elseif button==Joypad.AButton then self:onKeyPress(Keyboard.KEY_RETURN)
    elseif button==Joypad.YButton then self:onKeyPress(Keyboard.KEY_TAB)end
end
function Phone:onJoypadDirLeft()self:onKeyPress(Keyboard.KEY_LEFT)end
function Phone:onJoypadDirRight()self:onKeyPress(Keyboard.KEY_RIGHT)end
function Phone:onJoypadDirUp()self:onKeyPress(Keyboard.KEY_UP)end
function Phone:onJoypadDirDown()self:onKeyPress(Keyboard.KEY_DOWN)end
function Phone:new(p)
    local index=p:getPlayerNum();local o=ISPanelJoypad.new(self,getPlayerScreenLeft(index),getPlayerScreenTop(index),getPlayerScreenWidth(index),getPlayerScreenHeight(index))
    o.player=p;o.background=false;o.open=0;o.fromOpen=0;o.transitionAt=getTimestampMs();o.last=o.transitionAt;o.dt=0;o.pointerX=0;o.pointerY=0;o.row=1;o.page=M.clamp(tonumber(D.preferences(p).page)or 2,1,#D.pages);o.focusRows=false
    return o
end
