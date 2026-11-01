require "ProjectYakuza/Runtime"
require "ProjectYakuza/StyleUI"
require "ProjectYakuza/StyleSlots"
require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "ISUI/ISButton"
local ProjectYakuza=ProjectYakuza
local S={}
ProjectYakuza.StyleSelector=S
local Wheel=ISPanel:derive("ProjectYakuzaStyleWheel")
local Setup=ISPanel:derive("ProjectYakuzaStyleSetup")
function Wheel:onMouseDown()return false end
function Wheel:onMouseUp()return false end
function Wheel:onMouseMove()return false end
function Wheel:onRightMouseDown()return false end
function Wheel:onRightMouseUp()return false end
local positions={top={170,66},left={66,170},right={274,170},bottom={170,274}}
function S.allowed(p)
    return p and p:isLocalPlayer() and not p:isDead() and not p:getVehicle()
        and not isGamePaused() and not getCore():isDoingTextEntry() and not ProjectYakuza.isBusy(p)
end
function S.loadAssets()
    if S.assets then return end
    local base="media/textures/ProjectYakuza/StyleSelector/"
    S.assets={life=getTexture(base.."KiwamiLife.png"),dragon=getTexture(base.."KiwamiDragon.png")}
end
function Wheel:prerender()
    if ProjectYakuza.StyleUI.render("selector",self.player,self,{side=self.side}) then return end
    local elapsed=math.min(1,(getTimestampMs()-self.opened)/120)
    local a=S.assets
    for _,side in ipairs({"top","left","right","bottom"}) do
        local xy=positions[side];local chosen=self.side==side
        local id=ProjectYakuza.StyleSlots.id(self.player,side);local style=id and ProjectYakuza.getStyle(id)
        local alpha=elapsed*(chosen and 1 or .65)
        local custom=ProjectYakuza.StyleUI.render("selectorSlot",self.player,self,{style=style,side=side,x=xy[1],y=xy[2],alpha=alpha,selected=chosen})
        if not custom then

        if a.life then
            self:drawSubTexture(a.life,122,74,51,51,xy[1]-42,xy[2]-42,84,84,alpha,1,1,1)
            if chosen then self:drawSubTexture(a.life,0,0,43,44,xy[1]-44,xy[2]-44,88,88,elapsed,1,1,1) end
        end
        local icon=style and style.selectorIcon and getTexture(style.selectorIcon)
        if not icon and id=="dragon_of_dojima" then icon=a.dragon end
        if icon==a.dragon then

            self:drawSubTexture(icon,8,23,112,82,xy[1]-56,xy[2]-41,112,82,alpha,1,1,1)
        elseif icon then self:drawTextureScaled(icon,xy[1]-46,xy[2]-46,92,92,alpha,1,1,1)
        elseif side=="top" then self:drawTextCentre("UNEQUIP",xy[1],xy[2]-8,1,1,1,alpha,UIFont.Small)
        elseif side=="bottom" then self:drawTextCentre("SETUP",xy[1],xy[2]-8,1,1,1,alpha,UIFont.Small)
        elseif style then self:drawTextCentre(side=="left" and "1" or "2",xy[1],xy[2]-10,1,1,1,alpha,UIFont.Medium) end
        if side=="left" or side=="right" then self:drawTextCentre(side=="left" and "STYLE 1" or "STYLE 2",xy[1],xy[2]+49,1,1,1,alpha,UIFont.Small) end
        end
    end
    local side=self.side
    local id=ProjectYakuza.StyleSlots.id(self.player,side);local style=id and ProjectYakuza.getStyle(id)
    local label=side=="top" and "Unequip style" or side=="bottom" and "Assign styles" or style and style.name or "Empty"
    self:drawTextCentre(label,170,350,1,1,1,elapsed,UIFont.Medium)
    self:drawTextCentre("Hold "..ProjectYakuza.Bindings.label("styles").." - mouse / arrow keys - release to select",170,380,.85,.85,.85,elapsed,UIFont.Small)
end
function S.cancel()
    local wheel=S.wheel;S.wheel=nil
    if wheel then ProjectYakuza.StyleUI.releaseAll(wheel);wheel:removeFromUIManager() end
    Events.OnTick.Remove(S.tick)
end
function S.finish()
    local w=S.wheel;if not w then return end
    local p,side=w.player,w.side
    S.cancel()
    if not S.allowed(p) then return end
    if side=="bottom" then S.openSetup(p);return end
    if side=="top" then ProjectYakuza.unequipStyle(p);return end
    local id=ProjectYakuza.StyleSlots.id(p,side)
    if id then
        if not ProjectYakuza.isEquipped(p) or ProjectYakuza.getPlayerStyle(p).id~=id then ProjectYakuza.equipStyle(p,id)
        elseif ProjectYakuza.StyleEntry then ProjectYakuza.StyleEntry.request(p,id) end
    end
end
function S.tick()
    local w=S.wheel;if not w then return end
    if not S.allowed(w.player) or isKeyDown(Keyboard.KEY_ESCAPE) then S.cancel();return end
    if not ProjectYakuza.Bindings.down("styles") then S.finish();return end
    if isKeyDown(Keyboard.KEY_LEFT) then w.side="left"
    elseif isKeyDown(Keyboard.KEY_RIGHT) then w.side="right"
    elseif isKeyDown(Keyboard.KEY_UP) then w.side="top"
    elseif isKeyDown(Keyboard.KEY_DOWN) then w.side="bottom"
    else
        local x,y=getMouseX(),getMouseY()
        if math.abs(x-w.mouseX)+math.abs(y-w.mouseY)>3 then
            w.side=ProjectYakuza.StyleSlots.direction(x-w:getX()-170,y-w:getY()-170)
            w.mouseX,w.mouseY=x,y
        end
    end
end
function S.open(p)
    if S.wheel or S.setup or not S.allowed(p) then return false end
    S.loadAssets()
    local x=getPlayerScreenLeft(0)+(getPlayerScreenWidth(0)-340)/2
    local y=getPlayerScreenTop(0)+(getPlayerScreenHeight(0)-400)/2
    local panel=Wheel:new(x,y,340,400)
    panel.player=p;panel.opened=getTimestampMs();panel.mouseX,panel.mouseY=getMouseX(),getMouseY()
    local active=ProjectYakuza.getPlayerStyle(p)
    panel.side=active and active.id==ProjectYakuza.StyleSlots.id(p,"right") and "right" or "left"
    panel:initialise();panel.background=false;panel:setWantMouseEvents(false);panel:addToUIManager()
    S.wheel=panel;Events.OnTick.Add(S.tick)
    return true
end
function Setup:prerender()
    if ProjectYakuza.StyleUI.render("setup",self.player,self,{left=self.left,right=self.right,message=self.message}) then return end
    ISPanel.prerender(self)
    self:drawText("STYLE ASSIGNMENTS",20,16,1,1,1,1,UIFont.Medium)
    self:drawText("Style 1 - left",20,62,1,1,1,1,UIFont.Small)
    self:drawText("Style 2 - right",20,116,1,1,1,1,UIFont.Small)
    self:drawText("Top: empty    Bottom: this menu",20,184,.8,.8,.8,1,UIFont.Small)
    self:drawText(self.message or "Assignments are saved for this character.",20,211,.85,.85,.85,1,UIFont.Small)
end
function Setup:close()
    ProjectYakuza.StyleUI.releaseAll(self)
    self:removeFromUIManager()
    if S.setup==self then S.setup=nil end
end
function Setup:update()
    ISPanel.update(self)
    if self.player:isDead() or self.player:getVehicle() then self:close() end
end
function Setup:save()
    if not S.allowed(self.player) then self.message="Finish your current action first.";return end
    for _,side in ipairs({"left","right"}) do
        local combo=self[side];local id=combo:getOptionData(combo.selected)
        if id~="none" and not ProjectYakuza.getStyle(id) then self.message="A selected style is no longer available.";return end
    end
    for _,side in ipairs({"left","right"}) do
        local combo=self[side];local id=combo:getOptionData(combo.selected)
        local ok=ProjectYakuza.StyleSlots.assign(self.player,side,id~="none" and id or nil)
        if not ok then self.message="A selected style is no longer available.";return end
    end
    self:close()
end
function S.openSetup(p)
    if S.setup or not S.allowed(p) then return false end
    local panel=Setup:new(getPlayerScreenLeft(0)+(getPlayerScreenWidth(0)-460)/2,
        getPlayerScreenTop(0)+(getPlayerScreenHeight(0)-294)/2,460,294)
    panel.player=p;panel:initialise();panel.backgroundColor={r=.04,g=.04,b=.04,a=.97}
    for index,side in ipairs({"left","right"}) do
        local combo=ISComboBox:new(164,53+(index-1)*54,274,28)
        combo:initialise();combo:addOptionWithData("Empty","none")
        local id=ProjectYakuza.StyleSlots.get(p)[side]
        for _,entry in ipairs(ProjectYakuza.listStyles()) do
            combo:addOptionWithData(entry.name,entry.id)
            if entry.id==id then combo.selected=#combo.options end
        end
        panel[side]=combo;panel:addChild(combo)
    end
    local save=ISButton:new(236,248,100,28,"Save",panel,Setup.save);save:initialise();panel:addChild(save)
    local cancel=ISButton:new(346,248,92,28,"Cancel",panel,Setup.close);cancel:initialise();panel:addChild(cancel)
    panel:addToUIManager();S.setup=panel;return true
end
function S.keyStart(key)
    if ProjectYakuza.Bindings.matches("styles",key) then S.open(getSpecificPlayer(0)) end
end
function S.poll(p)
    if not p or not p:isLocalPlayer() then return end
    if ProjectYakuza.Bindings.pressed(p,"styles") and ProjectYakuza.Bindings.mode("styles")~=4 then S.open(p) end
end
Events.OnPlayerUpdate.Add(S.poll)
function S.clear()
    S.cancel();if S.setup then S.setup:close() end
end
function S.vehicleKeyGuard()
    if not ISVehicleMenu or S.vehicleHooked then return end
    local original=ISVehicleMenu.onKeyStartPressed
    if not original then return end
    Events.OnKeyStartPressed.Remove(original)
    ISVehicleMenu.onKeyStartPressed=function(key)
        if ProjectYakuza.Bindings.matches("styles",key) and (S.wheel or (not S.setup and S.allowed(getSpecificPlayer(0)))) then return end
        return original(key)
    end
    Events.OnKeyStartPressed.Add(ISVehicleMenu.onKeyStartPressed);S.vehicleHooked=true
end
Events.OnKeyStartPressed.Add(S.keyStart)
Events.OnGameStart.Add(S.vehicleKeyGuard)
Events.OnSave.Add(S.clear)
Events.OnMainMenuEnter.Add(S.clear)
