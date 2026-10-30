require "ProjectYakuza/Runtime"
require "ProjectYakuza/StyleUI"
require "ISUI/ISPanel"
local ProjectYakuza=ProjectYakuza
local H=ISPanel:derive("ProjectYakuzaHeatGauge")
ProjectYakuza.HeatUI=H
H.scale=0.75
H.visualOrbs=6
H.originX=78
H.originY=90
H.glowColor={0.35,0.75,1}
H.extremeGlowColor={.52,.22,1}
function H.loadAssets()
    if H.assets then return H.assets end
    local base="media/textures/ProjectYakuza/HeatHUD/"
    local a={atlas=getTexture(base.."OriginalDragonAtlas.png"),combat=getTexture(base.."OriginalCombatAtlas.png")}

    a.body={121,160,118,138};a.head={130,38,129,121}
    a.glass={266,1,68,68};a.core={266,72,68,68}
    a.stockGlass={76,0,37,37};a.stockRing={0,0,37,37}
    a.connector={339,63,77,62};a.tail={416,63,92,62}
    a.glow={0,300,234,212};a.glowLink={314,218,78,137};a.glowTail={393,218,119,137}
    a.kanji={205,36,68,68}

    a.extremeBody={0,160,118,138};a.extremeHead={0,38,129,121}
    a.extremeRing={38,0,37,37};a.extremeGlass={114,0,37,37}
    a.extremeConnector={339,0,77,62};a.extremeTail={416,0,92,62}
    H.assets=a
    return a
end
function H:drawOriginal(region,x,y,w,h,alpha,texture,color,snap)
    local left,top=H.originX+x*H.scale,H.originY+y*H.scale
    local right,bottom=left+w*H.scale,top+h*H.scale
    if snap then left=math.floor(left+.5);top=math.floor(top+.5);right=math.floor(right+.5);bottom=math.floor(bottom+.5) end
    self:drawSubTexture(texture or H.assets.atlas,region[1],region[2],region[3],region[4],
        left,top,right-left,bottom-top,alpha or 1,
        color and color[1] or 1,color and color[2] or 1,color and color[3] or 1)
end

function H:drawFill(region,x,y,size,fraction,alpha)
    local f=math.max(0,math.min(1,fraction))
    if f<=0 then return end
    local skip=1-f
    self:drawSubTexture(H.assets.atlas,region[1],region[2]+region[4]*skip,region[3],region[4]*f,
        H.originX+x*H.scale,H.originY+(y+size*skip)*H.scale,size*H.scale,size*f*H.scale,alpha,1,1,1)
end
function H:prerender()
    local p=getSpecificPlayer(0)
    if not p or p:isDead() or not ProjectYakuza.isEquipped(p) then ProjectYakuza.StyleUI.releaseAll(self);return end
    if ProjectYakuza.StyleUI.render("heat",p,self) then return end
    if ProjectYakuza.getPlayerStyle(p).heatHud~="yakuza6" or not ProjectYakuza.Heat.enabled(p) then return end

    local renderer=SpriteRenderer.instance;local previous=renderer:getDoAdditive()
    renderer:setDoAdditive(false)
    local ok,err=pcall(self.drawGauge,self,p)
    renderer:setDoAdditive(previous)
    if not ok then error(err) end
end
function H:drawGauge(p)
    local time=getTimestampMs()
    if time>=(self.nextRead or 0) then
        self.heat=math.max(0,math.min(100,ProjectYakuza.Heat.display(p)))
        self.extreme=ProjectYakuza.Heat.isExtreme(p)
        self.label=self.extreme and "EXTREME HEAT" or ("HEAT  "..ProjectYakuza.Heat.stocks(p).." / "..ProjectYakuza.Heat.config.maxStocks.."  ["..ProjectYakuza.Bindings.label("extremeHeat").."]")
        self.nextRead=time+100
    end
    local paused=isGamePaused()
    local dt=math.max(0,math.min(250,time-(self.lastFrameTime or time)))
    self.lastFrameTime=time
    if not paused then self.frame=(self.frame or time/50)+dt/50 end
    if self.visualHeat==nil then self.visualHeat=self.heat;self.fillFrom=self.heat;self.fillTarget=self.heat;self.fillMs=160 end
    if self.fillTarget~=self.heat then
        self.fillFrom=self.visualHeat;self.fillTarget=self.heat;self.fillMs=0
    end
    if not paused and self.fillMs<160 then
        self.fillMs=math.min(160,self.fillMs+dt)
        local t=self.fillMs/160
        self.visualHeat=self.fillFrom+(self.fillTarget-self.fillFrom)*t*t*(3-2*t)
    end
    local phase=self.frame or 0;local a=H.loadAssets()

    self.glowState=self.extreme and "extreme" or (self.heat>=99.999 and "ready" or "none")
    local glowAlpha
    if self.extreme then glowAlpha=.38+.06*math.sin(phase*.4)
    elseif self.heat>=99.999 then glowAlpha=.10+.025*math.sin(phase*.2) end
    if glowAlpha then
        local renderer=SpriteRenderer.instance
        local previous=renderer:getDoAdditive()
        renderer:setDoAdditive(false)
        self:drawOriginal(a.glow,-102,-114,234,212,glowAlpha,nil,self.extreme and H.extremeGlowColor or H.glowColor,true)
        self:drawOriginal(a.glowLink,132,-45.5,78,137,glowAlpha,nil,self.extreme and H.extremeGlowColor or H.glowColor,true)
        self:drawOriginal(a.glowTail,210,-46.5,120,137,glowAlpha,nil,self.extreme and H.extremeGlowColor or H.glowColor,true)
        renderer:setDoAdditive(previous)
    end
    self:drawOriginal(a.glass,-34,-34,68,68)
    self:drawFill(a.core,-34,-34,68,self.visualHeat/100,.8)

    self:drawOriginal(a.glass,-34,-34,68,68,.35)
    if self.activationMs then
        local elapsed=math.max(0,time-self.activationLast);self.activationLast=time
        if not isGamePaused() then self.activationMs=self.activationMs+math.min(250,elapsed) end
        if self.activationMs<800 then
            local t=self.activationMs/800
            self:drawOriginal(a.core,-34,-34,68,68,(1-t*t*(3-2*t))*.7)
        else self.activationMs=nil end
    end

    self:drawOriginal(self.extreme and a.extremeConnector or a.connector,54.5,-6,77,62)
    self:drawOriginal(self.extreme and a.extremeConnector or a.connector,131.5,-6,77,62)
    self:drawOriginal(self.extreme and a.extremeTail or a.tail,208,-6,92,62)

    local centers={56,93,130,169,207,246}
    for i=1,H.visualOrbs do
        local x=centers[i]-18.5;local y=6.5
        self:drawOriginal(self.extreme and a.extremeRing or a.stockRing,x,y,37,37)
        self:drawOriginal(self.extreme and a.extremeGlass or a.stockGlass,x,y,37,37)
        local fraction=math.max(0,math.min(1,self.visualHeat*ProjectYakuza.Heat.config.maxStocks/100-(i-1)))
        if not self.extreme then
            self:drawFill(a.core,centers[i]-14.5,10.5,29,fraction,.9)
            if fraction>0 then self:drawOriginal(a.stockGlass,x,y,37,37,.4) end
        end
    end
    self:drawOriginal(self.extreme and a.extremeBody or a.body,-64,-69,118,138)
    self:drawOriginal(a.kanji,-34,-34,68,68,1,a.combat)

    self:drawOriginal(self.extreme and a.extremeHead or a.head,-27.6,-79.4,103.2,96.8)
    if ProjectYakuza.TigerDrop then
        local seconds=math.ceil(ProjectYakuza.TigerDrop.remaining(p)/1000)
        self:drawOriginal(a.stockGlass,-58,63,22,22,.8)
        if seconds==0 then self:drawOriginal(a.core,-55,66,16,16,.8) end
        self:drawText(seconds>0 and ("Tiger Drop: "..seconds.."s") or "Tiger Drop ready",55,139,.8,.9,1,1,UIFont.Small)
    end
    self:drawText(self.label or "",55,157,.8,.9,1,1,UIFont.Small)
end
function H:onMouseDown()return false end
function H:onMouseUp()return false end
function H:onMouseMove()return false end
function H.create()
    if H.instance then return end
    H.loadAssets()
    local panel=H:new(16,12,348,176)
    panel:initialise();panel:setWantMouseEvents(false);panel:addToUIManager()
    H.instance=panel
end
function H.activate(player)
    if player==getSpecificPlayer(0) and H.instance then H.instance.activationMs=0;H.instance.activationLast=getTimestampMs() end
end
function H.endExtreme(player)
    if player==getSpecificPlayer(0) and H.instance then H.instance.activationMs=nil end
end
ProjectYakuza.on("extremeHeatStarted",H.activate)
ProjectYakuza.on("extremeHeatEnded",H.endExtreme)
Events.OnGameStart.Add(H.create)
