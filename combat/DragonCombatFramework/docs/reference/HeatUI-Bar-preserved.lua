require "DCF/Runtime"
require "ISUI/ISPanel"
local DCF=DragonCombat
local H=ISPanel:derive("DCFHeatGauge")
DCF.HeatUI=H
function H.loadAssets()
    if H.assets then return H.assets end
    local base="media/textures/DCF/HeatHUD/"
    local atlas=getTexture(base.."OriginalDragonAtlas.png")
    local a={bar={},atlas=atlas}
    a.body={120,160,120,138}
    a.head={128,39,132,119}
    a.glass={264,0,71,70}
    a.core={264,70,71,71}
    a.glow={0,300,234,212}
    a.frame=getTexture(base.."BarFrame.png")
    a.background=getTexture(base.."BarEmpty.png")
    for i=0,31 do a.bar[i+1]=getTexture(base.."Bar_"..i..".png") end
    H.assets=a
    return a
end
function H:drawOriginal(region,x,y,w,h,alpha)
    self:drawSubTexture(H.assets.atlas,region[1],region[2],region[3],region[4],x+8,y+8,w,h,alpha,1,1,1)
end
function H:prerender()
    local p=getSpecificPlayer(0)
    if not p or p:isDead() or not DCF.isEquipped(p) then return end
    local time=getTimestampMs()
    if time>=(self.nextRead or 0) then
        self.heat=math.max(0,math.min(100,DCF.Heat.display(p)))
        self.extreme=DCF.Heat.isExtreme(p)
        self.label=self.extreme and "EXTREME HEAT  [H: end]" or ("HEAT  "..DCF.Heat.stocks(p).." / "..DCF.Heat.config.maxStocks.."  [H]")
        local width=math.max(150,math.min(540,getCore():getScreenWidth()-145))
        if self.width~=width+116 then self:setWidth(width+116) end
        self.barWidth=width;self.nextRead=time+100
    end
    if not isGamePaused() then self.frame=math.floor(time/50) end
    local phase=self.frame or 0
    local a=H.loadAssets()
    -- Raw atlas regions, drawn only at smaller sizes. No added ring or baked dragon animation.
    self:drawOriginal(a.glass,10,22,50,50,1,1,1,1)
    if self.heat>0 then
        local h=50*self.heat/100
        self:setStencilRect(18,80-h,50,h)
        self:drawOriginal(a.core,10,22,50,50,0.8,1,1,1)
        self:clearStencilRect()
    end
    local glowAlpha=nil
    if self.extreme then glowAlpha=.7+.2*math.sin(phase*.25)
    elseif self.heat>=99.999 then glowAlpha=.24+.1*math.sin(phase*.2) end
    if self.activationMs then
        local elapsed=math.max(0,time-self.activationLast);self.activationLast=time
        if not isGamePaused() then self.activationMs=self.activationMs+math.min(250,elapsed) end
        if self.activationMs<800 then
            self:drawOriginal(a.core,10,22,50,50,(1-self.activationMs/800)*.7,1,1,1)
        else self.activationMs=nil end
    end
    local width=self.barWidth;local x=91
    self:drawTextureScaled(a.background,x+3,53,width-6,12,1,1,1,1)
    if self.heat>0 then
        self:setStencilRect(x+2,53,(width-4)*self.heat/100,11)
        self:drawTextureScaled(a.bar[phase%32+1],x+2,53,width-4,11,1,1,1,1)
        if self.extreme then self:drawTextureScaled(a.bar[(phase+8)%32+1],x+2,53,width-4,11,0.35,0.8,1,1) end
        self:clearStencilRect()
    end
    self:drawSubTexture(a.frame,0,0,3,18,x,50,3,18,1,0.8,0.95,1)
    self:drawSubTexture(a.frame,3,0,249,18,x+3,50,width-6,18,1,0.8,0.95,1)
    self:drawSubTexture(a.frame,252,0,4,18,x+width-3,50,3,18,1,0.8,0.95,1)
    for i=1,DCF.Heat.config.maxStocks-1 do self:drawRect(x+width*i/DCF.Heat.config.maxStocks,52,1,13,0.8,0.8,0.95,1) end
    self.glowState=self.extreme and "extreme" or (self.heat>=99.999 and "ready" or "none")
    if glowAlpha then self:drawOriginal(a.glow,-4,0,96,87,glowAlpha,1,1,1) end
    self:drawOriginal(a.body,0,7,69,79,1,1,1,1)
    self:drawOriginal(a.head,34,-3,59,54,1,1,1,1)
    self:drawText(self.label,94,73,0.64,0.9,1,0.95,UIFont.Small)
end
function H:onMouseDown()return false end
function H:onMouseUp()return false end
function H:onMouseMove()return false end
function H.create()
    if H.instance then return end
    H.loadAssets()
    local panel=H:new(16,12,656,104)
    panel:initialise();panel:setWantMouseEvents(false);panel:addToUIManager()
    H.instance=panel
end
function H.activate(player)
    if player==getSpecificPlayer(0) and H.instance then H.instance.activationMs=0;H.instance.activationLast=getTimestampMs() end
end
function H.endExtreme(player)
    if player==getSpecificPlayer(0) and H.instance then H.instance.activationMs=nil end
end
DCF.on("extremeHeatStarted",H.activate)
DCF.on("extremeHeatEnded",H.endExtreme)
Events.OnGameStart.Add(H.create)
