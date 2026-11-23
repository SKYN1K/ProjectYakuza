require "ProjectYakuza/Runtime"
require "ProjectYakuza/StyleUI"
require "ProjectYakuza/LowHealthFeedback"
require "ISUI/ISPanel"
local ProjectYakuza=ProjectYakuza
local H=ISPanel:derive("ProjectYakuzaHeatGauge")
ProjectYakuza.HeatUI=H
H.scale=.9
H.originX=110
H.originY=100
H.healthLength=337.5
H.glowColor={0.35,0.75,1}
H.extremeGlowColor={.52,.22,1}
function H.loadAssets()
    if H.assets then return H.assets end
    local base="media/textures/ProjectYakuza/HeatHUD/"
    local a={atlas=getTexture(base.."OriginalDragonAtlas.png"),combat=getTexture(base.."OriginalCombatAtlas.png"),healthFrame=getTexture(base.."BarFrame.png"),healthEmpty=getTexture(base.."BarEmpty.png")}

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
function H:layout(p)
    local index=p:getPlayerNum();local width=getPlayerScreenWidth(index);local height=getPlayerScreenHeight and getPlayerScreenHeight(index)or 720
    local text=getTextManager and getTextManager();local font=text and text.getFontHeight and text:getFontHeight(UIFont.Small)or 16
    local rowHeight=math.max(29,font+12);local margin=12
    local capacity=(ProjectYakuza.Heat.rules and ProjectYakuza.Heat.rules(p)or ProjectYakuza.Heat.config).maxStocks
    local tail=330+77*(math.ceil(capacity/2)-3)
    local desiredWidth=math.max(110+40*.9+H.healthLength,110+tail*.9)+12
    local factor=math.min(1,math.max(1,width-2*margin)/desiredWidth)
    local function geometry()
        H.scale=.9*factor;H.originX=110*factor;H.originY=100*factor
        self.healthBarWidth=H.healthLength*factor
        self.cooldownX=H.originX-64*H.scale
        self.cooldownY=H.originY+98*H.scale+12
        self.cooldownWidth=math.max(H.originX+40*H.scale+self.healthBarWidth,H.originX+tail*H.scale)-self.cooldownX
    end
    geometry()
    local requiredText=text and text.MeasureStringX and text:MeasureStringX(UIFont.Small,"QUICKSTEP  3 / 3")+text:MeasureStringX(UIFont.Small,"15.0s")or font*15
    self.stackedCooldownText=requiredText>self.cooldownWidth-24
    if self.stackedCooldownText then rowHeight=math.max(rowHeight,font*2+12)end
    local availableHeight=math.max(1,height-2*margin-2*(rowHeight+5)-16)
    factor=math.min(factor,availableHeight/(100+98*.9));geometry()
    self.cooldownRowHeight=rowHeight;self.cooldownFontHeight=font
    self.layoutWidth=math.min(width-2*margin,desiredWidth*factor)
    if self.setX then self:setX((getPlayerScreenLeft and getPlayerScreenLeft(index)or 0)+margin)end
    if self.setY then self:setY((getPlayerScreenTop and getPlayerScreenTop(index)or 0)+margin)end
end
function H:drawCooldownRow(title,value,y,fractions,ready,count)
    local x=self.cooldownX;local width=self.cooldownWidth;local height=self.cooldownRowHeight
    local color=ready and {.45,.82,1}or {.52,.60,.72}
    self:drawRect(x,y,width,height,.78,.025,.035,.055)
    self:drawRect(x,y,2,height,.95,color[1],color[2],color[3])
    self:drawText(title,x+9,y+2,color[1],color[2],color[3],1,UIFont.Small)
    if count then
        local text=getTextManager and getTextManager();local titleWidth=text and text.MeasureStringX and text:MeasureStringX(UIFont.Small,title)or #title*self.cooldownFontHeight*.55
        self:drawText(count,x+19+titleWidth,y+2,.9,.95,1,1,UIFont.Small)
    end
    self:drawTextRight(value,x+width-8,y+2+(self.stackedCooldownText and self.cooldownFontHeight or 0),.9,.95,1,1,UIFont.Small)
    local gap=4;local count=#fractions;local segment=(width-18-gap*(count-1))/count
    for i,fraction in ipairs(fractions)do
        local left=x+9+(i-1)*(segment+gap)
        self:drawRect(left,y+height-6,segment,3,.8,.13,.19,.26)
        if fraction>0 then self:drawRect(left,y+height-6,segment*math.min(1,fraction),3,.95,color[1],color[2],color[3])end
    end
    return y+height+5
end
function H:drawCooldowns(p)
    local style=ProjectYakuza.getPlayerStyle(p);local y=self.cooldownY
    local q=ProjectYakuza.Quicksteps;local action=style.actions and style.actions.quickstep
    if q and action and action.enabled then
        local available,remaining,gap=q.recovery(p);local fractions={}
        for i=1,q.limit do fractions[i]=i<=available and 1 or (i==available+1 and 1-remaining/q.windowMs or 0)end
        local value
        if remaining>0 then value=string.format("%.1fs",remaining/1000)
        elseif gap>0 then value=string.format("%.1fs",gap/1000)
        else value="READY"end
        y=self:drawCooldownRow("QUICKSTEP",value,y,fractions,available>0 and gap==0,available.." / "..q.limit)
    end
    if ProjectYakuza.TigerDrop and style.tigerDrop and ProjectYakuza.Sandbox.tigerDrop(style)then
        local remaining=ProjectYakuza.TigerDrop.remaining(p);local total=ProjectYakuza.Sandbox.tigerCooldownMs(style)
        local fraction=total>0 and math.max(0,math.min(1,1-remaining/total))or 1
        y=self:drawCooldownRow("TIGER DROP",remaining>0 and string.format("%.1fs",remaining/1000)or "READY",y,{fraction},remaining==0)
    end
    if self.setHeight then self:setHeight(y+4)end
end
function H:prerender()
    local p=getSpecificPlayer(0)
    if not p or p:isDead() or not ProjectYakuza.isEquipped(p) then ProjectYakuza.StyleUI.releaseAll(self);return end
    if ProjectYakuza.StyleUI.render("heat",p,self) then return end
    if ProjectYakuza.getPlayerStyle(p).heatHud~="yakuza6" or not ProjectYakuza.Heat.enabled(p) then return end
    local assets=H.loadAssets()
    for _,key in ipairs({"atlas","combat","healthFrame","healthEmpty"})do local texture=assets[key];if texture and texture.isReady and not texture:isReady()then return end end

    local renderer=SpriteRenderer.instance;local previous=renderer:getDoAdditive()
    renderer:setDoAdditive(false)
    local ok,err=pcall(self.drawGauge,self,p)
    renderer:setDoAdditive(previous)
    if not ok then error(err) end
end
function H:drawGauge(p)
    self:layout(p)
    local time=getTimestampMs()
    if time>=(self.nextRead or 0) then
        local body=p:getBodyDamage();self.health=math.max(0,math.min(100,body:getOverallBodyHealth()))
        self.heat=math.max(0,math.min(100,ProjectYakuza.Heat.display(p)))
        self.extreme=ProjectYakuza.Heat.isExtreme(p)
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
    local healthWidth=self.healthBarWidth
    local healthX,healthY=H.originX+40*H.scale,H.originY-32*H.scale
    if a.healthEmpty then self:drawTextureScaled(a.healthEmpty,healthX,healthY,healthWidth,18*H.scale,1,1,1,1)end
    local warning=math.sqrt(ProjectYakuza.LowHealthFeedback and ProjectYakuza.LowHealthFeedback.sample(p)or 0)
    local healthAlpha=1-warning*.72
    local fill=(healthWidth-4)*self.health/100
    if fill>0 then
        for row=0,7 do local shine=1-math.abs(row-3.5)/4;self:drawRect(healthX+2,healthY+2+row*(14*H.scale/8),fill,14*H.scale/8+1,healthAlpha,.48+.4*shine,.025+.045*shine,.035+.045*shine)end
    end
    if a.healthFrame then self:drawTextureScaled(a.healthFrame,healthX,healthY,healthWidth,18*H.scale,1,1,1,1)end
    if warning>0 and a.healthFrame then
        self:drawTextureScaled(a.healthFrame,healthX-3,healthY-3,healthWidth+6,18*H.scale+6,warning*.22,1,.08,.06)
        self:drawTextureScaled(a.healthFrame,healthX-1,healthY-1,healthWidth+2,18*H.scale+2,warning*.62,1,.12,.1)
    end
    local capacity=(ProjectYakuza.Heat.rules and ProjectYakuza.Heat.rules(p)or ProjectYakuza.Heat.config).maxStocks
    local pairs=math.ceil(capacity/2)
    if self.setWidth then self:setWidth(self.layoutWidth)end

    self.glowState=self.extreme and "extreme" or (self.heat>=99.999 and "ready" or "none")
    local glowAlpha
    if self.extreme then glowAlpha=.38+.06*math.sin(phase*.4)
    elseif self.heat>=99.999 then glowAlpha=.10+.025*math.sin(phase*.2) end
    if glowAlpha then
        local renderer=SpriteRenderer.instance
        local previous=renderer:getDoAdditive()
        renderer:setDoAdditive(false)
        self:drawOriginal(a.glow,-102,-114,234,212,glowAlpha,nil,self.extreme and H.extremeGlowColor or H.glowColor,true)
        for link=1,math.max(0,pairs-2)do self:drawOriginal(a.glowLink,55+77*link,-45.5,78,137,glowAlpha,nil,self.extreme and H.extremeGlowColor or H.glowColor,true)end
        self:drawOriginal(a.glowTail,56+77*(pairs-1),-46.5,120,137,glowAlpha,nil,self.extreme and H.extremeGlowColor or H.glowColor,true)
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

    for link=1,pairs-1 do self:drawOriginal(self.extreme and a.extremeConnector or a.connector,54.5+77*(link-1),-6,77,62)end
    self:drawOriginal(self.extreme and a.extremeTail or a.tail,208+77*(pairs-3),-6,92,62)

    local centers={56,93,130,169,207,246}
    if capacity~=6 then centers={}for i=1,capacity do centers[i]=56+(i-1)*38.5 end end
    for i=1,capacity do
        local x=centers[i]-18.5;local y=6.5
        self:drawOriginal(self.extreme and a.extremeRing or a.stockRing,x,y,37,37)
        self:drawOriginal(self.extreme and a.extremeGlass or a.stockGlass,x,y,37,37)
        local fraction=math.max(0,math.min(1,self.visualHeat*(ProjectYakuza.Heat.rules and ProjectYakuza.Heat.rules(p)or ProjectYakuza.Heat.config).maxStocks/100-(i-1)))
        if not self.extreme then
            self:drawFill(a.core,centers[i]-14.5,10.5,29,fraction,.9)
            if fraction>0 then self:drawOriginal(a.stockGlass,x,y,37,37,.4) end
        end
    end
    self:drawOriginal(self.extreme and a.extremeBody or a.body,-64,-69,118,138)
    self:drawOriginal(a.kanji,-34,-34,68,68,1,a.combat)

    self:drawOriginal(self.extreme and a.extremeHead or a.head,-27.6,-79.4,103.2,96.8)
    self:drawCooldowns(p)
end
function H:onRightMouseDown()return false end
function H:onRightMouseUp()return false end
function H:onMouseDown()return false end
function H:onMouseUp()return false end
function H:onMouseMove()return false end
function H.create()
    if H.instance then return end
    H.loadAssets()
    local panel=H:new(16,12,348,176)
    ProjectYakuza.StyleUI.renderOnly(panel);panel:initialise();panel:setWantMouseEvents(false);panel:addToUIManager()
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
