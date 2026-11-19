require "ProjectYakuzaPhoneDev/PhoneData"
require "ProjectYakuzaPhoneDev/PhoneFont"
require "ProjectYakuzaPhoneDev/PhoneItems"
require "ProjectYakuzaPhoneDev/PhoneStyles"
require "ProjectYakuzaPhoneDev/PhoneMaterial"
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
function Phone:submenu()return self.activeStyles or self.activeItems end
local function audio(self,cue)PY.UIAudio.play(self.player,cue)end
local function quad(panel,q,texture,x,y,w,h,r,g,b,a)
    if not texture or texture.isReady and not texture:isReady()then return end
    local ax,ay=(q[2][1]-q[1][1])/320,(q[2][2]-q[1][2])/320
    local bx,by=(q[4][1]-q[1][1])/568,(q[4][2]-q[1][2])/568
    local x1,y1=q[1][1]+ax*x+bx*y,q[1][2]+ay*x+by*y
    local x2,y2=x1+ax*w,y1+ay*w;local x4,y4=x1+bx*h,y1+by*h
    local x3,y3=x2+bx*h,y2+by*h
    panel:drawTextureAllPoint(texture,x1,y1,x2,y2,x3,y3,x4,y4,r,g,b,a)
end
local appColors={{.80,.20,.24},{.51,.25,.72},{.12,.61,.35},{1,1,1},{.08,.51,.85},{.70,.13,.43},{.82,.62,.14},{.19,.42,.80},{.28,.31,.36}}
D.appColors=appColors
local function caption(panel,q,text,x,y,a,size,width)
    D.Font.projected(panel,q,text,x,y,a,size or 20,width)
end
function Screen:prerender()
    local host=self.host
    if host.closed or host.open<=.005 or math.cos(host.pose.rx)*math.cos(host.pose.ry)<.12 then self.quad=nil;return end
    if host.modelReady==false then self.quad=nil;return end
    local q=M.project(host.pose,self.width,self.height,self.quad);self.quad=q
    local alpha=host.open;local white=host.textures.Pixel
    for row=0,5 do local t=row/5;quad(self,q,white,0,row*568/6,320,568/6+1,.025+.19*t,.14+.035*t,.18+.10*t,alpha)end
    quad(self,q,host.textures.dragon,0,108,320,187,.50,.66,.78,alpha*.48)
    quad(self,q,host.textures.dragon,0,295,320,187,.56,.46,.72,alpha*.48)
    quad(self,q,white,0,0,320,26,0,0,0,alpha)
    caption(self,q,host.clockLabel,43,2,alpha,19)
    quad(self,q,host.textures.signal,223,5,22,15,1,1,1,alpha)
    caption(self,q,host.batteryLabel,267,2,alpha,18,39)
    if host:loadBattery()then
        local bx,by,bw,bh=291,5,25,14
        quad(self,q,white,bx+7/44*bw,by+6/24*bh,31/44*bw*host.batteryLevel,12/24*bh,host.batteryR,host.batteryG,host.batteryB,alpha)
        for _,part in ipairs(host.batteryFrame)do quad(self,q,part.texture,bx+part.x/44*bw,by+part.y/24*bh,part.w/44*bw,part.h/24*bh,host.batteryR,host.batteryG,host.batteryB,alpha)end
    end
    quad(self,q,white,0,28,320,46,.03,.16,.21,alpha*.8)
    caption(self,q,host.styleLabel,160,36,alpha,27,286)
    quad(self,q,white,0,73,320,2,.28,.46,.51,alpha)
    caption(self,q,"PROJECT YAKUZA",160,83,alpha*.65,15,280)
    caption(self,q,"HEAT",38,113,alpha*.9,18)
    if host:loadOrbs()then for index=1,6 do
        quad(self,q,host.orbRing,70+(index-1)*30,116,23,23,1,1,1,alpha*.8)
        if index<=host.heatStocks then quad(self,q,host.orbFill,72.5+(index-1)*30,118.5,18,18,1,1,1,alpha*.9)end
    end end
    caption(self,q,host.heatLabel,280,116,alpha*.8,18,58)
    for index,page in ipairs(D.pages)do
        local x,y,w,h=M.appRect(index);local selected=host.page==index
        quad(self,q,white,x-13,y-6,w+26,h+33,selected and .89 or .59,selected and .34 or .45,selected and .11 or .62,alpha*(selected and .95 or .20))
        quad(self,q,white,x+5,y+4,w-6,h-10,0,0,0,alpha*.35)
        quad(self,q,white,x+3,y+1,w-6,h-10,.92,.91,.93,alpha*.98)
        quad(self,q,white,x+3,y+1,w-6,1.5,1,1,1,alpha*.85)
        quad(self,q,white,x+3,y+h-10,w-6,1.5,.40,.39,.42,alpha*.55)
        local icon=host.icons[index];local ix,iy,iw,ih=icon[1],icon[2],icon[3],icon[4]
        local tint=appColors[index]
        quad(self,q,host.textures[page.id],ix,iy-5,iw,ih,tint[1],tint[2],tint[3],alpha)
        caption(self,q,page.label,x+w/2,y+h+1,alpha,22,94)
    end
    quad(self,q,white,0,540,320,28,0,0,0,alpha*.94)
    caption(self,q,host.gamepad and"A Select     B Close"or"Enter Select     Esc Close",160,541,alpha*.8,18,292)
    quad(self,q,white,0,28,1,512,0,0,0,alpha*.30)
    quad(self,q,white,319,28,1,512,.80,.86,.92,alpha*.13)
    local shine=math.sin(host.pose.ry)*72
    if white and white:isReady()then for band=0,2 do
        local left=175+shine+band*10;local right=left+13
        local x1,y1=M.point(q,left/320,0);local x2,y2=M.point(q,right/320,0)
        local x3,y3=M.point(q,(right-110)/320,1);local x4,y4=M.point(q,(left-110)/320,1)
        self:drawTextureAllPoint(white,x1,y1,x2,y2,x3,y3,x4,y4,.82,.91,1,alpha*(band==1 and .033 or .015))
    end end
end
function Screen:onMouseMove(dx,dy)
    if not self.quad or self.host.closing or self.host:submenu() then return true end
    local index=M.hit(self.quad,self:getMouseX(),self:getMouseY())
    if index then self.host.focusRows=false;self.host:selectPage(index)end
    return true
end
function Screen:onMouseDown(x,y)
    if self.host.closing or self.host:submenu() then return true end
    local index=self.quad and M.hit(self.quad,x,y)
    if index then self.host:selectPage(index);self.host:activatePage()end
    return true
end
function Screen:onMouseUp()return true end
function Screen:onMouseWheel()return true end
function Rows:maxScroll()return math.max(0,#self.items*self.rowHeight-self.height)end
function Rows:scroll(delta)
    self.offset=M.clamp(self.offset+delta*self.rowHeight,0,self:maxScroll())
end
function Rows:onMouseWheel(delta)if not self.host:submenu() then self:scroll(delta)end;return true end
function Rows:onMouseMove()
    if self.host.closing or self.host:submenu() then return true end
    local row=math.floor((self:getMouseY()+self.offset)/self.rowHeight)+1
    if row>=1 and row<=#self.items and row~=self.host.row then self.host.row=row;self.host.focusRows=true;audio(self.host,"cursor")end
    return true
end
function Rows:onMouseDown(x,y)
    if self.host.closing or self.host:submenu() then return true end
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
        if item.level~=nil then
            self:drawText(item.label,18,y+6,.85,.82,.80,a,UIFont.Small);self:drawTextRight(item.detail,self.width-18,y+6,.97,.96,.94,a,UIFont.Small)
            local segment=(self.width-36)/10
            for n=1,10 do
                local fill=n<=item.level and 1 or n==item.level+1 and item.progress or 0
                self:drawRect(18+(n-1)*segment,y+36,segment-2,8,a*.6,.18,.18,.20)
                if fill>0 then self:drawRect(18+(n-1)*segment,y+36,(segment-2)*fill,8,a*.8,.49,.74,.58)end
            end
        else
            local inline=#item.label+#item.detail<math.floor((self.width-70)/7)
            self:drawText(item.label,18,y+(inline and 17 or 8),.78,.75,.73,a,UIFont.Small)
            if inline then self:drawTextRight(item.detail,self.width-43,y+17,.97,.96,.94,a,UIFont.Small)
            else self:drawText(item.detail,18,y+29,.78,.81,.83,a*.85,UIFont.Small)end
        end
        if item.adjust then self:drawText("-     +",self.width-100,y+9,.98,.61,.27,a,UIFont.Medium)
        elseif item.action then self:drawText(">",self.width-31,y+16,.98,.61,.27,a,UIFont.Medium)end
    end
    self:clearStencilRect()
    if self:maxScroll()>0 then local h=math.max(28,self.height*self.height/(#self.items*self.rowHeight));local y=(self.height-h)*self.offset/self:maxScroll();self:drawRect(self.width-5,y,3,h,a*.75,.9,.51,.23)end
end
function Phone:initialise()
    ISPanelJoypad.initialise(self)
    self.textures={};for name,asset in pairs(D.assets)do self.textures[name]=getTexture(asset.path)end
    self:loadOrbs()
    self.icons={};for index,page in ipairs(D.pages)do local x,y,w,h=M.appRect(index);self.icons[index]={M.iconRect(D.assets[page.id],x+w/2,y+h/2,46)}end
    local sw=math.min(self.height*.70,self.width*.48);self.scene=ISUI3DScene:new(0,0,sw,self.height);self.scene.background=false;self.scene:initialise();self:addChild(self.scene)
    local native=self.scene.javaObject
    for _,name in ipairs({"setDrawGrid","setDrawGridAxes","setDrawGridPlane","setDrawAttachments","setDrawGeometry"})do native:fromLua1(name,false)end
    native:fromLua1("setGizmoVisible","none");native:fromLua1("setView","Right");native:fromLua1("setZoom",1)
    native:fromLua2("createModel","xperia","ProjectYakuzaPhoneDev.Xperia")
    native:fromLua2("setModelUseWorldAttachment","xperia",false);native:fromLua2("setModelWeaponRotationHack","xperia",false)
    self.rotation=native:fromLua1("getObjectRotation","xperia");self.translation=native:fromLua1("getObjectTranslation","xperia");self.scale=native:fromLua1("getObjectScale","xperia")
    self.material=D.Material:new(0,0,sw,self.height);self.material.host=self;self.material.background=false;self.material:initialise();self:addChild(self.material)
    self.screen=Screen:new(0,0,sw,self.height);self.screen.host=self;self.screen.background=false;self.screen:initialise();self:addChild(self.screen)
    self.panelX=math.max(sw*.95,self.width*.48);self.panelW=self.width-self.panelX-self.width*.033;self.panelY=self.height*.08;self.panelH=self.height*.81
    self.rows=Rows:new(self.panelX+8,self.panelY+130,self.panelW-16,self.panelH-213);self.rows.host=self;self.rows.items={};self.rows.offset=0;self.rows.rowHeight=59;self.rows.background=false;self.rows:initialise();self:addChild(self.rows)
    self:setWantKeyEvents(true);self:refresh();self:applyPose()
end
function Phone:loadOrbs()
    if self.orbRing then return true end
    local atlas=getTexture("media/textures/ProjectYakuza/HeatHUD/OriginalDragonAtlas.png")
    if not atlas or not atlas:isReady()then return false end
    self.orbRing=atlas:split("ProjectYakuzaPhoneDevOrbRing",0,0,37,37);self.orbFill=atlas:split("ProjectYakuzaPhoneDevOrbFill",266,72,68,68);return true
end
function Phone:loadBattery()
    if self.batteryFrame then return true end
    local atlas=self.textures.battery;if not atlas or not atlas:isReady()then return false end
    self.batteryFrame={}
    for i,rect in ipairs({{0,0,44,6},{0,18,44,6},{0,6,7,12},{38,6,6,12}})do
        self.batteryFrame[i]={texture=atlas:split("ProjectYakuzaPhoneDevBattery"..i,rect[1],rect[2],rect[3],rect[4]),x=rect[1],y=rect[2],w=rect[3],h=rect[4]}
    end
    return true
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
    local rules=PY.Heat.rules(self.player);self.heatStocks=PY.Heat.stocks(self.player);self.heatLabel=self.heatStocks.." / "..rules.maxStocks;self.headerAt=getTimestampMs()
    self.batteryLevel,self.batteryR,self.batteryG,self.batteryB,self.batteryLabel=M.battery(self.player:getBodyDamage():getOverallBodyHealth())
end
function Phone:selectPage(index)
    index=M.clamp(index,1,#D.pages);if index==self.page then return end
    self.page=index;self.row=1;self.rows.offset=0;D.preferences(self.player).page=index;self:refresh();audio(self,"cursor")
end
function Phone:activatePage()
    if self.page==1 then D.Styles.open(self)elseif self.page==2 then D.Items.open(self)else self.focusRows=true;audio(self,"confirm")end
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
    local submenu=self:submenu();local covered=submenu and submenu.alpha>=.999 and not submenu.closing and not self.closing
    self.modelReady=self.textures.Xperia:isReady();self.scene:setVisible(self.modelReady and not covered);self.material:setVisible(not covered);self.screen:setVisible(not covered);self.rows:setVisible(not covered)
    local a=self.open
    self:drawRect(0,0,self.width,self.height,a*.48,.015,.018,.026)
    if covered then return end
    local q=M.project(self.pose,self.scene.width,self.height,self.shadowQuad);self.shadowQuad=q
    for _,corner in ipairs(q)do corner[1]=corner[1]+9;corner[2]=corner[2]+14 end
    for layer=1,3 do quad(self,q,self.textures.Pixel,-19-layer*2,-76-layer*2,358+layer*4,720+layer*4,0,0,0,a*.045)end
    self:drawRect(self.panelX,self.panelY,self.panelW,self.panelH,a*.88,.025,.022,.025)
    self:drawRect(self.panelX,self.panelY,self.panelW,26,a*.96,.88,.88,.86)
    self:drawTextCentre(self.page==2 and"Skills"or D.pages[self.page].label,self.panelX+self.panelW/2,self.panelY+4,.04,.04,.045,a,UIFont.Small)
    self:drawText(self.styleLabel,self.panelX+23,self.panelY+43,.96,.94,.92,a,UIFont.Medium)
    self:drawText("PROJECT YAKUZA",self.panelX+24,self.panelY+73,.66,.64,.63,a*.85,UIFont.Small)
    self:drawRect(self.panelX,self.panelY+101,self.panelW,1,a*.35,.54,.53,.53)
    self:drawText(D.pages[self.page].description,self.panelX+24,self.panelY+111,.63,.80,.67,a,UIFont.Small)
    if self.page==1 or self.page==3 or self.page==4 then
        local selector=PY.StyleSelector;local style=PY.getPlayerStyle(self.player);local icon=selector.styleIcon and selector.styleIcon(style)
        if icon and selector.assets and icon==selector.assets.dragon then self:drawSubTexture(icon,8,23,112,82,self.panelX+self.panelW-84,self.panelY+40,64,47,a*.8,1,1,1)
        elseif icon then self:drawTextureScaled(icon,self.panelX+self.panelW-75,self.panelY+40,46,46,a*.8,1,1,1)end
    end
    self:drawRect(self.panelX,self.panelY+self.panelH-78,self.panelW,1,a*.30,.54,.53,.53)
    self:drawText(self.message or(self.focusRows and"Select a row  |  Left / right adjusts audio"or"Choose an app"),self.panelX+23,self.panelY+self.panelH-62,.80,.77,.75,a,UIFont.Small)
    self:drawText(self.gamepad and"Y: change focus     A: select     B: close"or"Tab: change focus     Enter: select     Esc: close",self.panelX+23,self.panelY+self.panelH-31,.64,.64,.64,a,UIFont.Small)
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
    self.afterClose=afterClose;self.closing=true;self.fromOpen=self.open;self.transitionAt=getTimestampMs();D.phoneSound(self.player,"Close")
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
    local submenu=self:submenu();if submenu then submenu:onKeyPress(key);return end
    if key==Keyboard.KEY_ESCAPE then self:close();return end
    if self.closing then return end
    if key==Keyboard.KEY_TAB then self.focusRows=not self.focusRows;audio(self,"cursor");return end
    if key==Keyboard.KEY_RETURN or key==Keyboard.KEY_NUMPADENTER then if self.focusRows then self:activateRow()else self:activatePage()end;return end
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
    if button==Joypad.BButton then local submenu=self:submenu();if submenu then submenu:close()else self:close()end
    elseif button==Joypad.AButton then self:onKeyPress(Keyboard.KEY_RETURN)
    elseif button==Joypad.YButton then self:onKeyPress(Keyboard.KEY_TAB)end
end
function Phone:onJoypadDirLeft()self:onKeyPress(Keyboard.KEY_LEFT)end
function Phone:onJoypadDirRight()self:onKeyPress(Keyboard.KEY_RIGHT)end
function Phone:onJoypadDirUp()self:onKeyPress(Keyboard.KEY_UP)end
function Phone:onJoypadDirDown()self:onKeyPress(Keyboard.KEY_DOWN)end
local function flatText(self,text,x,y,r,g,b,a,font,align)
    D.Font.flat(self,text,x,y,r,g,b,a,font==UIFont.Medium and 25 or 18,align)
end
function Phone:drawText(text,x,y,r,g,b,a,font)flatText(self,text,x,y,r,g,b,a,font)end
function Phone:drawTextCentre(text,x,y,r,g,b,a,font)flatText(self,text,x,y,r,g,b,a,font,"center")end
function Phone:drawTextRight(text,x,y,r,g,b,a,font)flatText(self,text,x,y,r,g,b,a,font,"right")end
Rows.drawText=Phone.drawText;Rows.drawTextCentre=Phone.drawTextCentre;Rows.drawTextRight=Phone.drawTextRight
function Phone:new(p)
    local index=p:getPlayerNum();local o=ISPanelJoypad.new(self,getPlayerScreenLeft(index),getPlayerScreenTop(index),getPlayerScreenWidth(index),getPlayerScreenHeight(index))
    o.player=p;o.background=false;o.open=0;o.fromOpen=0;o.transitionAt=getTimestampMs();o.last=o.transitionAt;o.dt=0;o.pointerX=0;o.pointerY=0;o.row=1;o.page=M.clamp(tonumber(D.preferences(p).page)or 2,1,#D.pages);o.focusRows=false
    return o
end
