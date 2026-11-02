require "ProjectYakuza/HeatRush"
require "ProjectYakuza/StyleUI"
require "ISUI/ISPanel"
local PY=ProjectYakuza
local rotations={{1,0},{0,1},{-1,0},{0,-1}}
local U=ISPanel:derive("ProjectYakuzaHeatRushPrompt");PY.HeatRushUI=U
function U:onMouseDown()return false end
function U:onMouseUp()return false end
function U:onMouseMove()return false end
function U:onRightMouseDown()return false end
function U:onRightMouseUp()return false end
function U:renderEligibility(p,active)
    local t=getTimestampMs();local dt=math.max(0,math.min(100,t-(self.promptAt or t)));self.promptAt=t
    local style=p and PY.getPlayerStyle(p);local target,move
    if p and not active then target,move=PY.HeatRush.weaponCandidate(p,PY.stateFor(p),style)end
    local desired=target and 1 or 0;local alpha=self.promptAlpha or 0
    if not isGamePaused()then
        if desired==1 then alpha=math.min(1,alpha+dt/120)else alpha=math.max(0,alpha-dt/80)end
    end
    self.promptAlpha=alpha
    if PY.StyleUI and PY.StyleUI.render("heatAction",p,self,{eligible=target~=nil,target=target,move=move,alpha=alpha,binding=PY.Bindings.label("heatAction")})then return end
    if alpha<=0 then return end
    if U.heatIcon==nil then U.heatIcon=getTexture and getTexture("media/textures/ProjectYakuza/HeatActionIconAtlas.png")or false end
    local x,y=self.width*.5,self.height*.67
    self:drawTextCentre(PY.Bindings.label("heatAction"),x,y-24,1,1,1,alpha,UIFont.Medium or UIFont.Small or UIFont.Large)
    if U.heatIcon then
        self:drawSubTexture(U.heatIcon,0,0,64,80,x-32,y,64,80,alpha*.35,.12,.42,1)
        self:drawSubTexture(U.heatIcon,64,0,64,80,x-32,y,64,80,alpha,1,1,1)
    end
end
function U:drawTimingRing(x,y,size,alpha,r,g,b,angle)
    if U.qteIcon==nil then U.qteIcon=getTexture and getTexture("media/textures/ProjectYakuza/HeatRushQTEAtlas.png")or false end
    if not U.qteIcon or not SpriteRenderer or not SpriteRenderer.instance then return end
    local cx=(self:getAbsoluteX())+x;local cy=(self:getAbsoluteY())+y
    for _,rotation in ipairs(rotations)do
        local a,b=math.cos(angle or 0),math.sin(angle or 0)
        local c,v=rotation[1]*a-rotation[2]*b,rotation[1]*b+rotation[2]*a
        SpriteRenderer.instance:renderPoly(U.qteIcon,cx+(-c+v)*size,cy+(-v-c)*size,cx+v*size,cy-c*size,cx,cy,cx-c*size,cy-v*size,r,g,b,alpha)
    end
end
function U:render()
    local p=getSpecificPlayer(self.playerNum);local action=p and PY.HeatRush.active[p]
    self:renderEligibility(p,action)
    if not action then return end
    if not action.seen or not action.qte or action.qte.closed then return end
    local state=action.qte;local prompt=state.definition.prompts[state.index]
    if not prompt then return end
    local age=action.elapsed*1000;local untilHit=prompt.atMs-age
    if untilHit<0 or untilHit>math.max(prompt.windowMs,600)then return end
    local open=PY.QTE.window(state.definition,state.index,age)
    local alpha=state.accepted[state.index]and .8 or 1
    local x,y=self.width*.5,self.height*.7
    local progress=math.max(0,math.min(1,1-untilHit/math.max(600,prompt.windowMs)))
    local appear=math.min(1,(math.max(prompt.windowMs,600)-untilHit)/90)
    local accepted=state.inputAt[state.index]
    local flash=accepted and math.max(0,1-(age-accepted)/180)or 0
    self:drawTimingRing(x,y,56*(1+.12*flash),alpha*appear,.45+.5*flash,.75+.2*flash,1,age*.0018)
    self:drawTimingRing(x,y,56+38*(1-progress),alpha*.65*appear,.75,.9,1,-age*.0024)
    if U.qteEffects==nil then U.qteEffects=getTexture and getTexture("media/textures/ProjectYakuza/HeatRushQTEEffects.png")or false end
    if U.qteEffects then
        local frame=math.floor(age/60)%3
        local sx,sy=frame==1 and 220 or 0,frame==2 and 220 or 0
        local size=108+24*flash
        self:drawSubTexture(U.qteEffects,sx,sy,220,220,x-size*.5,y-size*.5,size,size,(.55+.4*flash)*appear,.5+.5*flash,.8+.2*flash,1)
    end
    self:drawTextCentre(PY.Bindings.label(prompt.binding),x,y-12,.85,1,1,alpha*appear,UIFont.Large)

end
function U.create()
    U.instances=U.instances or {}
    for i=0,getNumActivePlayers()-1 do
        if not U.instances[i]then
            local panel=U:new(getPlayerScreenLeft(i),getPlayerScreenTop(i),getPlayerScreenWidth(i),getPlayerScreenHeight(i));panel.playerNum=i;panel.background=false;panel:initialise();panel:setWantMouseEvents(false);panel:addToUIManager();U.instances[i]=panel
        end
    end
end
Events.OnGameStart.Add(U.create)
Events.OnCreatePlayer.Add(function()U.create()end)
