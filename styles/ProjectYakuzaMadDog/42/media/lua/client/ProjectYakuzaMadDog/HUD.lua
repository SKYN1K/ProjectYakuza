require "ProjectYakuza/Runtime"
require "ProjectYakuzaMadDog/Style"
require "ISUI/ISPanel"
local P=ProjectYakuza
local H=ISPanel:derive("ProjectYakuzaMadDogHUD")
P.MadDogHUD=H
H.panels={}
H.styleID="project_yakuza.mad_dog_of_shimano"
function H.enabled(player)
    local style=player and P.getPlayerStyle(player)
    return player and player:isLocalPlayer() and not player:isDead() and P.isEquipped(player)
        and style and style.id==H.styleID and style.heatHud=="mad_dog_y0" and P.Heat.enabled(player)
end
function H.assets()
    if not H.textures then
        local base="media/textures/ProjectYakuzaMadDog/"
        H.textures={icon=getTexture(base.."LegendIcon.png"),title=getTexture(base.."StyleTitle.png")}
    end
    return H.textures
end
function H:prerender()
    local player=getSpecificPlayer(self.playerIndex)
    if not H.enabled(player) then self.wasActive=false;return end
    local assets=H.assets()
    if not assets.icon or not assets.title then return end
    self:setX(getPlayerScreenLeft(self.playerIndex)+16)
    self:setY(getPlayerScreenTop(self.playerIndex)+12)
    local now=getTimestampMs()
    if not self.wasActive then self.nextRead=0;self.visualHeat=nil;self.lastTime=now end
    self.wasActive=true
    if now>=(self.nextRead or 0) then
        self.heat=math.max(0,math.min(100,P.Heat.display(player)))
        self.extreme=P.Heat.isExtreme(player)
        self.stocks=P.Heat.stocks(player)
        self.nextRead=now+100
    end
    local dt=math.max(0,math.min(250,now-(self.lastTime or now)));self.lastTime=now
    if self.visualHeat==nil then self.visualHeat=self.heat end
    if not isGamePaused() then
        local fraction=math.min(1,dt/160)
        self.visualHeat=self.visualHeat+(self.heat-self.visualHeat)*fraction
    end
    self:drawTextureScaled(assets.icon,0,5,100,100,1,1,1,1)
    self:drawTextureScaled(assets.title,108,12,225,28,1,1,1,1)
    self:drawRect(103,43,218,62,.30,.015,.012,.025)
    local red,green,blue=.88,.84,1
    if self.extreme then red,green,blue=1,.94,1 end
    local label=self.extreme and "EXTREME HEAT" or ("HEAT  "..self.stocks.." / "..P.Heat.config.maxStocks)
    self:drawText(label,109,45,red,green,blue,1,UIFont.Small)
    for i=1,P.Heat.config.maxStocks do
        local x=109+(i-1)*34
        local fill=math.max(0,math.min(1,self.visualHeat*P.Heat.config.maxStocks/100-(i-1)))
        self:drawRectBorder(x,69,30,11,.65,.80,.78,.90)
        if fill>0 then self:drawRect(x+1,70,28*fill,9,.95,red,green,blue) end
    end
    if not self.extreme and self.heat>=99.999 then
        self:drawText("READY  ["..P.Bindings.label("extremeHeat").."]",109,86,.92,.86,1,1,UIFont.Small)
    end
end
function H:onMouseDown()return false end
function H:onMouseUp()return false end
function H:onMouseMove()return false end
function H.create(index)
    if H.panels[index] or not getSpecificPlayer(index) then return end
    local panel=H:new(16,12,342,110);panel.playerIndex=index
    panel:initialise();panel:setWantMouseEvents(false);panel:addToUIManager()
    H.panels[index]=panel
end
function H.start()
    for index=0,3 do H.create(index) end
end
function H.clear()
    for index,panel in pairs(H.panels) do panel:removeFromUIManager();H.panels[index]=nil end
end
Events.OnGameStart.Add(H.start)
Events.OnCreatePlayer.Add(function(index)H.create(index)end)
Events.OnMainMenuEnter.Add(H.clear)
