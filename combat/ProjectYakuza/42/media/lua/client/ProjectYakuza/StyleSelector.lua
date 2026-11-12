require "ProjectYakuza/Runtime"
require "ProjectYakuza/StyleUI"
require "ProjectYakuza/StyleSlots"
require "ProjectYakuza/UIAudio"
require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "ISUI/ISButton"
local ProjectYakuza=ProjectYakuza
local S={icons={}}
ProjectYakuza.StyleSelector=S
local Wheel=ISPanel:derive("ProjectYakuzaStyleWheel")
local Setup=ISPanel:derive("ProjectYakuzaStyleSetup")
local Combo=ISComboBox:derive("ProjectYakuzaStyleCombo")
S.Combo=Combo
function Combo:showPopup()
    ProjectYakuza.UIAudio.play(self.audioPlayer,"toggle")
    self.audioHighlight=nil
    self.popup:setFont(self.font,4);self.popup:setComboBox(self);self.popup:addToUIManager()
end
function Combo:hidePopup()
    self.popup:removeFromUIManager()
    if self.editor and self.editor:isVisible() then self.filterText=nil;self.editor:unfocus();self.editor:setVisible(false) end
end
function Combo:pointOnItem(index)
    if self.audioHighlight~=index then
        if self.audioHighlight then ProjectYakuza.UIAudio.play(self.audioPlayer,"cursor") end
        self.audioHighlight=index
    end
end
function S.optionChanged(panel,combo)
    ProjectYakuza.UIAudio.play(panel.player,"confirm")
end
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
    S.assets={life=getTexture(base.."KiwamiLife.png"),dragon=getTexture(base.."KiwamiDragon.png"),background=getTexture(base.."KiwamiSettingsBackground.png")}
end
local sides={"top","left","right","bottom"}
local function ease(value)
    value=math.max(0,math.min(1,value))
    return 1-(1-value)^3
end
local function backdrop(panel,alpha)
    local x,y=-panel:getX()+getPlayerScreenLeft(0),-panel:getY()+getPlayerScreenTop(0)
    local width,height=getPlayerScreenWidth(0),getPlayerScreenHeight(0)
    panel:drawRect(x,y,width,height,.48*alpha,.015,.019,.027)
    for i=0,11 do
        local shade=1-math.abs((i+.5)/6-1)
        panel:drawRect(x,y+height*i/12,width,height/12+1,.14*alpha*shade,0,0,0)
    end
end
local function plate(panel,x,y,width,height,alpha)
    panel:drawRect(x-5,y+5,width+10,height,.18*alpha,0,0,0)
    panel:drawRect(x,y,width,height,.94*alpha,.035,.041,.054)
    panel:drawRect(x,y,width,2,.8*alpha,.65,.72,.82)
    panel:drawRect(x,y+height-1,width,1,.3*alpha,.65,.72,.82)
end
function Wheel:prerender()
    local time=getTimestampMs()
    local elapsed=ease((time-self.opened)/260)
    local dt=math.max(0,math.min(.05,(time-(self.lastDraw or time))/1000))
    self.lastDraw=time
    if ProjectYakuza.StyleUI.render("selector",self.player,self,{side=self.side,alpha=elapsed}) then return end
    self:drawTextCentre("COMBAT STYLES",170,-27+8*(1-elapsed),.9,.93,1,elapsed,UIFont.Medium)
    self:drawRect(80,3,180*elapsed,1,.4*elapsed,.6,.7,.85)
    local a=S.assets
    for index,side in ipairs(sides) do
        local origin=positions[side];local chosen=self.side==side
        local enter=ease((time-self.opened-(index-1)*28)/240)
        local focus=self.focus[side] or 0
        focus=focus+((chosen and 1 or 0)-focus)*math.min(1,dt*16)
        self.focus[side]=focus
        local x=170+(origin[1]-170)*(.72+.28*enter)
        local y=170+(origin[2]-170)*(.72+.28*enter)+12*(1-enter)
        local id=ProjectYakuza.StyleSlots.id(self.player,side);local style=id and ProjectYakuza.getStyle(id)
        local alpha=enter*(.58+.42*focus)
        local custom=ProjectYakuza.StyleUI.render("selectorSlot",self.player,self,{style=style,side=side,x=x,y=y,alpha=alpha,selected=chosen,focus=focus,progress=enter})
        if not custom then
            local radius=40+4*focus
            if a.life then
                self:drawSubTexture(a.life,122,74,51,51,x-radius,y-radius,radius*2,radius*2,alpha,1,1,1)
                if focus>.001 then
                    local glow=radius+5+2*math.sin(time/600)
                    self:drawSubTexture(a.life,0,0,43,44,x-glow,y-glow,glow*2,glow*2,enter*focus*.28,.55,.75,1)
                    self:drawSubTexture(a.life,0,0,43,44,x-radius-2,y-radius-2,radius*2+4,radius*2+4,enter*focus,1,1,1)
                end
            end
            local icon=S.styleIcon(style)
            if icon and icon==a.dragon then
                self:drawSubTexture(icon,8,23,112,82,x-56,y-41,112,82,alpha,1,1,1)
            elseif icon then self:drawTextureScaled(icon,x-46,y-46,92,92,alpha,1,1,1)
            elseif side=="top" then self:drawTextCentre("UNEQUIP",x,y-8,.85,.9,1,alpha,UIFont.Small)
            elseif side=="bottom" then self:drawTextCentre("SETTINGS",x,y-8,.85,.9,1,alpha,UIFont.Small)
            else self:drawTextCentre(style and (side=="left" and "1" or "2") or "EMPTY",x,y-8,.75,.8,.9,alpha,UIFont.Small) end
            if side=="left" or side=="right" then self:drawTextCentre(side=="left" and "STYLE 1" or "STYLE 2",x,y+53,.8,.86,.95,alpha,UIFont.Small) end
        end
    end
    local side=self.side
    local id=ProjectYakuza.StyleSlots.id(self.player,side);local style=id and ProjectYakuza.getStyle(id)
    local label=side=="top" and "Unequip style" or side=="bottom" and "Mod settings" or style and style.name or "Empty slot"
    plate(self,-75,342+10*(1-elapsed),490,75,elapsed)
    self:drawTextCentre(label,170,352+10*(1-elapsed),1,1,1,elapsed,UIFont.Medium)
    self:drawTextCentre("Hold "..ProjectYakuza.Bindings.label("styles").."  /  mouse or arrow keys  /  release to select",170,385+10*(1-elapsed),.65,.72,.83,elapsed,UIFont.Small)
end
function S.cancel(silent)
    local wheel=S.wheel;S.wheel=nil
    if wheel then
        if silent~=true then ProjectYakuza.UIAudio.play(wheel.player,"cancel") end
        ProjectYakuza.StyleUI.releaseAll(wheel);wheel:removeFromUIManager()
    end
    Events.OnTick.Remove(S.tick)
end
function S.finish()
    local w=S.wheel;if not w then return end
    local p,side=w.player,w.side
    S.cancel(true)
    if not S.allowed(p) then return end
    if side=="bottom" then S.openSetup(p);return end
    if side=="top" then ProjectYakuza.unequipStyle(p);ProjectYakuza.UIAudio.play(p,"confirm");return end
    local id=ProjectYakuza.StyleSlots.id(p,side)
    if id then
        if not ProjectYakuza.isEquipped(p) or ProjectYakuza.getPlayerStyle(p).id~=id then ProjectYakuza.equipStyle(p,id)
        elseif ProjectYakuza.StyleEntry then local ok=ProjectYakuza.StyleEntry.request(p,id,true);if ok then ProjectYakuza.UIAudio.style(p,id) end end
    else ProjectYakuza.UIAudio.play(p,"cancel") end
end
function S.tick()
    local w=S.wheel;if not w then return end
    if not S.allowed(w.player) then S.cancel(true);return end
    if isKeyDown(Keyboard.KEY_ESCAPE) then S.cancel();return end
    if not ProjectYakuza.Bindings.down("styles") then S.finish();return end
    local oldSide=w.side
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
    if oldSide~=w.side then ProjectYakuza.UIAudio.play(w.player,"cursor") end
end
function S.open(p)
    if S.wheel or S.setup or not S.allowed(p) then return false end
    S.loadAssets()
    local x=getPlayerScreenLeft(0)+(getPlayerScreenWidth(0)-340)/2
    local y=getPlayerScreenTop(0)+(getPlayerScreenHeight(0)-400)/2
    local panel=Wheel:new(x,y,340,400)
    panel.player=p;panel.opened=getTimestampMs();panel.focus={};panel.mouseX,panel.mouseY=getMouseX(),getMouseY()
    local active=ProjectYakuza.getPlayerStyle(p)
    panel.side=active and active.id==ProjectYakuza.StyleSlots.id(p,"right") and "right" or "left"
    ProjectYakuza.StyleUI.renderOnly(panel);panel:initialise();panel.background=false;panel:setWantMouseEvents(false);panel:addToUIManager()
    S.wheel=panel;Events.OnTick.Add(S.tick);ProjectYakuza.UIAudio.play(p,"open")
    return true
end
local preferences={
    {label="Hit effects",key="ProjectYakuzaHitEffectsDisabled",inverse=true,module="HitEffects"},
    {label="Heat aura",key="ProjectYakuzaHeatAuraDisabled",inverse=true,module="HeatAura"},
    {label="Combat diagnostics",key="ProjectYakuzaDiagnostics"},
}
function S.styleIcon(style)
    if not style then return end
    local path=style.selectorIcon
    if path then
        if S.icons[path]==nil then S.icons[path]=getTexture(path) or false end
        if S.icons[path] then return S.icons[path] end
    end
    if style.id=="dragon_of_dojima" then return S.assets.dragon end
end
function Setup:prerender()
    local alpha=ease((getTimestampMs()-self.opened)/300)
    if ProjectYakuza.StyleUI.render("setup",self.player,self,{left=self.left,right=self.right,message=self.message,alpha=alpha,settings=self.settings}) then return end
    backdrop(self,alpha)
    plate(self,0,0,self.width,self.height,alpha)
    if S.assets.background then
        self:drawSubTexture(S.assets.background,188-12*(1-alpha),0,648,512,0,0,self.width,self.height,.58*alpha,1,1,1)
    end
    self:drawRect(0,0,self.width,68,.7*alpha,.025,.028,.035)
    self:drawRect(0,366,self.width,self.height-366,.65*alpha,.025,.028,.035)
    self:drawText("PROJECT YAKUZA",24,18,.93,.96,1,alpha,UIFont.Medium)
    self:drawText("STYLES & SETTINGS",24,48,.6,.68,.78,alpha,UIFont.Small)
    for index,side in ipairs({"left","right"}) do
        local y=80+(index-1)*66
        self:drawRect(20,y-6,self.width-40,60,.65*alpha,.055,.062,.075)
        local combo=self[side];local id=combo:getOptionData(combo.selected)
        local icon=S.styleIcon(ProjectYakuza.getStyle(id))
        if icon==S.assets.dragon and icon then self:drawSubTexture(icon,8,23,112,82,27,y+5,56,41,alpha,1,1,1)
        elseif icon then self:drawTextureScaled(icon,31,y+2,48,48,alpha,1,1,1) end
        self:drawText(index==1 and "First Style:" or "Second Style:",96,y+15,.88,.91,.97,alpha,UIFont.Small)
    end
    for index,setting in ipairs(preferences) do
        local y=224+(index-1)*48
        self:drawRect(24,y-9,self.width-48,1,.18*alpha,.6,.68,.8)
        self:drawText(setting.label,32,y+5,.82,.87,.94,alpha,UIFont.Small)
    end
    self:drawText(self.message or "Audio volumes and keybindings: Options > Mods > Project Yakuza",24,378,.65,.72,.83,alpha,UIFont.Small)
    self:drawText("Save applies changes. Cancel leaves your settings unchanged.",24,400,.65,.72,.83,alpha,UIFont.Small)
end
function Setup:close(silent)
    if self.closed then return end
    self.closed=true
    if not silent then ProjectYakuza.UIAudio.play(self.player,"cancel") end
    ProjectYakuza.StyleUI.releaseAll(self)
    self:removeFromUIManager()
    if S.setup==self then S.setup=nil end
end
function Setup:update()
    ISPanel.update(self)
    if self.player:isDead() or self.player:getVehicle() then self:close(true)
    elseif isKeyDown(Keyboard.KEY_ESCAPE) then self:close() end
end
function Setup:save(button)
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
    local data=self.player:getModData()
    for index,setting in ipairs(preferences) do
        local enabled=self.settings[index]:getOptionData(self.settings[index].selected)==true
        local stored=enabled
        if setting.inverse then stored=not enabled end
        if (data[setting.key]==true)~=stored then
            if setting.module and ProjectYakuza[setting.module] then ProjectYakuza[setting.module].toggle(self.player)
            else data[setting.key]=stored end
            if setting.key=="ProjectYakuzaDiagnostics" then print("[ProjectYakuza] "..ProjectYakuza.diagnosticLine(self.player)) end
        end
    end
    if not button then ProjectYakuza.UIAudio.play(self.player,"confirm") end
    self:close(true)
end
function S.openSetup(p)
    if S.setup or not S.allowed(p) then return false end
    S.loadAssets()
    local panel=Setup:new(getPlayerScreenLeft(0)+(getPlayerScreenWidth(0)-620)/2,
        getPlayerScreenTop(0)+(getPlayerScreenHeight(0)-490)/2,620,490)
    panel.player=p;panel.opened=getTimestampMs();panel:initialise();panel.background=false;panel.settings={}
    for index,side in ipairs({"left","right"}) do
        local combo=Combo:new(230,88+(index-1)*66,366,28,panel,S.optionChanged);combo.audioPlayer=p
        combo:initialise();combo:addOptionWithData("Empty","none")
        local id=ProjectYakuza.StyleSlots.get(p)[side]
        for _,entry in ipairs(ProjectYakuza.listStyles()) do
            combo:addOptionWithData(entry.name,entry.id)
            if entry.id==id then combo.selected=#combo.options end
        end
        panel[side]=combo;panel:addChild(combo)
    end
    local data=p:getModData()
    for index,setting in ipairs(preferences) do
        local combo=Combo:new(430,224+(index-1)*48,166,28,panel,S.optionChanged);combo.audioPlayer=p
        combo:initialise();combo:addOptionWithData("On",true);combo:addOptionWithData("Off",false)
        local enabled=data[setting.key]==true
        if setting.inverse then enabled=not enabled end
        combo.selected=enabled and 1 or 2
        panel.settings[index]=combo;panel:addChild(combo)
    end
    local save=ISButton:new(380,440,100,28,"Save",panel,Setup.save);save:initialise();save.sounds={activate="ProjectYakuza_MenuConfirm"};panel:addChild(save)
    local cancel=ISButton:new(490,440,106,28,"Cancel",panel,Setup.close);cancel:initialise();cancel.sounds={activate="ProjectYakuza_MenuCancel"};panel:addChild(cancel)
    panel:addToUIManager();S.setup=panel;ProjectYakuza.UIAudio.play(p,"open");return true
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
    S.cancel(true);if S.setup then S.setup:close(true) end
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
