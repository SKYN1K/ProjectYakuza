require "ProjectYakuzaPhoneDev/PhoneItems"
local PY=ProjectYakuza
local D=PY.PhoneDev
local M=D.Math
local Styles=ISPanel:derive("ProjectYakuzaPhoneDevStyles")
D.Styles=Styles
Styles.actions={"Equip style","Assign first slot","Assign second slot","Unequip style"}
function Styles:label(text,x,y,size,r,g,b,align,width)
    D.Font.flat(self,text,x,y,r or .94,g or .92,b or .90,self.alpha,size or 21,align,width)
end
local function wrap(text,size,width)
    local lines={};local line=""
    for word in tostring(text):gmatch("%S+")do
        local candidate=line==""and word or line.." "..word
        if line~=""and(#candidate>60 or D.Font.layout(candidate,size,10000).width>width)then lines[#lines+1]=line;line=word else line=candidate end
    end
    if line~=""then lines[#lines+1]=line end
    return lines
end
function Styles:select(index)
    self.selected=M.clamp(index,1,math.max(1,#self.styles));self.message=nil
    local style=self.styles[self.selected]
    self.description=wrap(style and style.description or"No styles are available.",23,self.width*.61-52)
    self.preview=style and style.preview
    local rows=math.max(1,math.floor((self.height-115)/64))
    if self.selected<=self.offset then self.offset=self.selected-1 end
    if self.selected>self.offset+rows then self.offset=self.selected-rows end
end
function Styles:activate()
    if self.closing or self.alpha<.99 then return end
    local style=self.styles[self.selected];if not style then return end
    local p=self.host.player
    if self.action==2 or self.action==3 then
        local ok,reason=PY.StyleSlots.assign(p,self.action==2 and"left"or"right",style.id)
        self.message=ok and"Style slot updated."or tostring(reason or"Cannot assign this style.");PY.UIAudio.play(p,ok and"confirm"or"cancel");return
    end
    if PY.isBusy(p)then self.message="Finish your current action first.";return end
    local unequip=self.action==4
    self.host:close(false,function()if unequip then PY.unequipStyle(p)elseif PY.getStyle(style.id)then PY.equipStyle(p,style.id)end end)
end
function Styles:close()
    if self.closing then return end
    self.closing=true;self.fromAlpha=self.alpha;self.at=getTimestampMs();PY.UIAudio.play(self.host.player,"cancel")
end
function Styles:onKeyPress(key)
    if key==Keyboard.KEY_ESCAPE then self:close();return end
    if self.closing then return end
    if key==Keyboard.KEY_UP then self:select(self.selected-1)
    elseif key==Keyboard.KEY_DOWN then self:select(self.selected+1)
    elseif key==Keyboard.KEY_LEFT then self.action=(self.action-2)%#Styles.actions+1
    elseif key==Keyboard.KEY_RIGHT or key==Keyboard.KEY_TAB then self.action=self.action%#Styles.actions+1
    elseif key==Keyboard.KEY_RETURN or key==Keyboard.KEY_NUMPADENTER then self:activate();return
    else return end
    PY.UIAudio.play(self.host.player,"cursor")
end
function Styles:onMouseDown(x,y)
    if self.closing then return true end
    if x<self.width*.34 and y>=50 and y<self.height-65 then
        local index=math.floor((y-50)/64)+1+self.offset
        if index<=#self.styles then self:select(index);PY.UIAudio.play(self.host.player,"cursor")end
    elseif y>=self.height-102 and y<self.height-59 and x>=self.width*.37 then
        self.action=M.clamp(math.floor((x-self.width*.37)/((self.width*.63-25)/#Styles.actions))+1,1,#Styles.actions);self:activate()
    end
    return true
end
function Styles:onMouseDoubleClick(x,y)
    self:onMouseDown(x,y)
    if x<self.width*.34 and y>=50 and y<self.height-65 and math.floor((y-50)/64)+1+self.offset<=#self.styles then self.action=1;self:activate()end
    return true
end
function Styles:onMouseWheel(delta)
    local rows=math.max(1,math.floor((self.height-115)/64));self.offset=M.clamp(self.offset+delta*3,0,math.max(0,#self.styles-rows));return true
end
function Styles:onMouseMove()return true end
function Styles:onMouseUp()return true end
function Styles:onRightMouseDown()self:close();return true end
function Styles:onRightMouseUp()return true end
function Styles:prerender()
    local t=M.clamp((getTimestampMs()-self.at)/1000/D.Items.transitionSeconds,0,1)
    self.alpha=self.closing and self.fromAlpha*(1-t)or t
    if self.host.closing then self.alpha=self.alpha*self.host.open end
    if self.closing and t>=1 then self.host.activeStyles=nil;self.host:removeChild(self);return end
    local a=self.alpha;local listW=self.width*.34;local x=self.width*.37;local rightW=self.width-x-25
    self:drawRect(0,0,self.width,self.height,a*.98,.025,.022,.027)
    self:drawRect(0,0,self.width,30,a,.88,.87,.85);self:label("Fighting styles",self.width/2,3,23,.05,.05,.05,"center")
    self:setStencilRect(15,49,listW-24,self.height-113)
    local last=math.min(#self.styles,self.offset+math.max(1,math.floor((self.height-115)/64)))
    local current=PY.isEquipped(self.host.player)and PY.getPlayerStyle(self.host.player)
    for i=self.offset+1,last do local style=self.styles[i];local y=50+(i-self.offset-1)*64
        if i==self.selected then self:drawRect(15,y,listW-24,60,a*.65,.79,.29,.05)end
        self:label(style.name,27,y+10,24,nil,nil,nil,nil,listW-49)
        if current and current.id==style.id then self:label("Equipped",27,y+38,17,.60,.84,.65)end
        self:drawRect(15,y+62,listW-24,1,a*.2,.60,.57,.55)
    end
    self:clearStencilRect();self:drawRect(listW,49,1,self.height-110,a*.3,.61,.58,.56)
    local style=self.styles[self.selected]
    if style then
        self:label(style.name,x,49,29,nil,nil,nil,nil,rightW)
        local available=math.max(42,self.height-237-math.min(4,#self.description)*28)
        local w=math.min(rightW,available*16/9);local h=w*9/16;local px=x+(rightW-w)/2
        self:drawRect(px-2,91,w+4,h+4,a*.65,.41,.38,.35)
        if self.preview and self.preview:isReady()then self:drawTextureScaled(self.preview,px,93,w,h,a,1,1,1)
        else self:label("No preview supplied",px+w/2,104,22,.61,.61,.61,"center",w)end
        for i=1,math.min(4,#self.description)do self:label(self.description[i],x,108+h+(i-1)*28,23,nil,nil,nil,nil,rightW)end
    end
    local buttonW=rightW/#Styles.actions
    for i,name in ipairs(Styles.actions)do local bx=x+(i-1)*buttonW
        self:drawRect(bx,self.height-102,buttonW-4,39,a*(i==self.action and .85 or .25),.79,.29,.05)
        self:label(name,bx+(buttonW-4)/2,self.height-91,18,nil,nil,nil,"center",buttonW-12)
    end
    self:drawRect(18,self.height-55,self.width-36,1,a*.3,.61,.58,.56)
    self:label(self.message or"Up/down: style    Left/right: action    Enter: select    Esc: back",23,self.height-40,19)
end
function Styles.open(host)
    if host:submenu()or host.closing then return end
    local panel=Styles:new(host.width*.06,host.height*.09,host.width*.88,host.height*.82)
    panel.host=host;panel.alpha=0;panel.at=getTimestampMs();panel.selected=1;panel.offset=0;panel.action=1;panel.background=false;panel.styles={}
    for _,style in ipairs(PY.listStyles())do
        local path=style.id=="dragon_of_dojima"and"media/textures/ProjectYakuzaPhoneDev/DragonOfDojima.png"or style.previewImage
        panel.styles[#panel.styles+1]={id=style.id,name=style.name,description=style.description or"Additional fighting style.",preview=type(path)=="string"and getTexture(path)or nil}
    end
    panel:initialise();panel:select(1);host.activeStyles=panel;host:addChild(panel);PY.UIAudio.play(host.player,"confirm")
end
