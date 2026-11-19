require "ProjectYakuzaPhoneDev/PhoneItems"
require "ProjectYakuzaPhoneDev/PhonePreview"
local PY=ProjectYakuza
local D=PY.PhoneDev
local M=D.Math
local Styles=ISPanel:derive("ProjectYakuzaPhoneDevStyles")
D.Styles=Styles
Styles.actions={"Assign to 1st slot","Assign to 2nd slot"}
function Styles:label(text,x,y,size,color,align,width,bold)
    color=color or self.theme.text
    return D.Font.flat(self,text,x,y,color[1],color[2],color[3],self.alpha,size or 22,align,width,bold)
end
function Styles:box(x,y,w,h,alpha,color)
    self:drawRect(x,y,w,h,self.alpha*alpha,color[1],color[2],color[3])
end
function Styles:layout()
    local pad=M.clamp(self.width*.02,12,24);local listW=math.max(132,self.width*.28)
    local x=listW+pad*2;local w=self.width-x-pad;local footerH=58;local buttonH=44
    local result={pad=pad,listW=listW,x=x,w=w,top=48,rowH=74,footerY=self.height-footerH,buttonY=self.height-footerH-buttonH-pad,buttonH=buttonH}
    local style=self.styles[self.selected]
    result.title=D.Font.wrap(style and style.name or"Fighting styles",27,w,true)
    result.titleH=math.min(2,#result.title)*29
    result.tabColumns=math.min(4,math.max(1,style and #style.previews or 0));result.tabRows=style and #style.previews>1 and math.ceil(#style.previews/result.tabColumns)or 0
    result.tabsY=result.top+result.titleH+8;result.tabsH=result.tabRows*35
    result.imageY=result.tabsY+result.tabsH+8
    local available=math.max(60,result.buttonY-pad-result.imageY)
    result.descriptionH=math.min(132,math.max(40,available*.32));result.imageH=math.max(20,available-result.descriptionH-12)
    result.descriptionY=result.imageY+result.imageH+12;result.lineH=24
    result.visibleLines=math.max(1,math.floor(result.descriptionH/result.lineH))
    result.listRows=math.max(1,math.floor((result.footerY-result.top-pad)/result.rowH))
    self.geometry=result
    return result
end
function Styles:selectPreview(index)
    local style=self.styles[self.selected]
    self.previewIndex=M.clamp(index,1,math.max(1,style and #style.previews or 0));self.previewState=D.Preview.start(style and style.previews[self.previewIndex],getTimestampMs())
end
function Styles:select(index)
    self.selected=M.clamp(index,1,math.max(1,#self.styles));self.message=nil;self.descriptionOffset=0
    local style=self.styles[self.selected]
    self.theme=style and style.theme or{accent={.62,.66,.73},background={.025,.025,.032},text={.94,.96,.98}}
    local g=self:layout();for _,entry in ipairs(self.styles)do entry.nameLines=D.Font.wrap(entry.name,22,g.listW-58)end;self.description=D.Font.wrap(style and style.description or"No styles are available.",22,g.w)
    self:selectPreview(1)
    if self.selected<=self.offset then self.offset=self.selected-1 end
    if self.selected>self.offset+g.listRows then self.offset=self.selected-g.listRows end
end
function Styles:toggleFavorite(index)
    local entry=self.styles[index];if not entry then return end
    self.favorites[entry.id]=not self.favorites[entry.id]or nil
    PY.UIAudio.play(self.host.player,"confirm")
end
function Styles:activate()
    if self.closing or self.alpha<.99 then return end
    local style=self.styles[self.selected];if not style then return end
    local ok,reason=PY.StyleSlots.assign(self.host.player,self.action==1 and"left"or"right",style.id)
    self.message=ok and("Assigned to "..(self.action==1 and"1st"or"2nd").." slot.")or tostring(reason or"Cannot assign this style.")
    PY.UIAudio.play(self.host.player,ok and"confirm"or"cancel")
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
    elseif key==Keyboard.KEY_LEFT then self.action=1
    elseif key==Keyboard.KEY_RIGHT then self.action=2
    elseif key==Keyboard.KEY_F then self:toggleFavorite(self.selected)
    elseif key==Keyboard.KEY_TAB then local style=self.styles[self.selected];if style and #style.previews>1 then self:selectPreview(self.previewIndex%#style.previews+1)end
    elseif key==Keyboard.KEY_RETURN or key==Keyboard.KEY_NUMPADENTER then self:activate();return
    else return end
    PY.UIAudio.play(self.host.player,"cursor")
end
function Styles:onMouseDown(x,y)
    if self.closing then return true end
    local g=self.geometry or self:layout();local style=self.styles[self.selected]
    if x<g.listW+g.pad and y>=g.top and y<g.footerY-g.pad then
        local index=math.floor((y-g.top)/g.rowH)+1+self.offset
        if index<=#self.styles then
            if x>=g.pad+g.listW-42 then self:toggleFavorite(index)else self:select(index);PY.UIAudio.play(self.host.player,"cursor")end
        end
    elseif x>=g.x and x<g.x+g.w and y>=g.buttonY and y<g.buttonY+g.buttonH then
        self.action=x<g.x+g.w/2 and 1 or 2;self:activate()
    elseif style and g.tabRows>0 and x>=g.x and x<g.x+g.w and y>=g.tabsY and y<g.tabsY+g.tabsH then
        local index=math.floor((y-g.tabsY)/35)*g.tabColumns+math.floor((x-g.x)/(g.w/g.tabColumns))+1
        if index<=#style.previews then self:selectPreview(index);PY.UIAudio.play(self.host.player,"cursor")end
    end
    return true
end
function Styles:onMouseDoubleClick(x,y)return self:onMouseDown(x,y)end
function Styles:onMouseWheel(delta)
    local g=self.geometry or self:layout()
    if self:getMouseX()>=g.x then self.descriptionOffset=M.clamp(self.descriptionOffset+delta*2,0,math.max(0,#self.description-g.visibleLines))
    else self.offset=M.clamp(self.offset+delta*2,0,math.max(0,#self.styles-g.listRows))end
    return true
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
    local g=self.geometry or self:layout();local theme=self.theme;local accent=theme.accent;local a=self.alpha;local style=self.styles[self.selected]
    self:box(0,0,self.width,self.height,.98,theme.background);self:box(0,0,self.width,36,.18,accent);self:box(0,35,self.width,1,.65,accent)
    self:label("Fighting styles",self.width/2,4,26,theme.text,"center",self.width-g.pad*2,true)
    self:setStencilRect(g.pad,g.top,g.listW,g.footerY-g.top-g.pad)
    for i=self.offset+1,math.min(#self.styles,self.offset+g.listRows)do
        local entry=self.styles[i];local y=g.top+(i-self.offset-1)*g.rowH
        if i==self.selected then self:box(g.pad,y,g.listW,g.rowH-3,.22,accent);self:box(g.pad,y,3,g.rowH-3,.9,accent)end
        local heart=self.heart
        if heart and(not heart.isReady or heart:isReady())then self:drawTextureScaled(heart,g.pad+g.listW-36,y+15,28,28,a*(self.favorites[entry.id]and 1 or .27),1,1,1)end
        local names=entry.nameLines
        for line=1,math.min(2,#names)do self:label(names[line],g.pad+10,y+5+(line-1)*23,22,nil,nil,g.listW-58,i==self.selected)end
        local slots={};for index,side in ipairs({"left","right"})do if PY.StyleSlots.id(self.host.player,side)==entry.id then slots[#slots+1]="Slot "..index end end
        if #slots>0 then self:label(table.concat(slots," / "),g.pad+10,y+51,16,accent,nil,g.listW-58)end
    end
    self:clearStencilRect();self:box(g.x-g.pad,g.top,1,g.footerY-g.top-g.pad,.28,accent)
    if style then
        for i=1,math.min(2,#g.title)do self:label(g.title[i],g.x,g.top+(i-1)*29,27,nil,nil,g.w,true)end
        if g.tabRows>0 then for i,preview in ipairs(style.previews)do
            local bx=g.x+(i-1)%g.tabColumns*g.w/g.tabColumns;local by=g.tabsY+math.floor((i-1)/g.tabColumns)*35;local bw=g.w/g.tabColumns-5
            self:box(bx,by,bw,30,i==self.previewIndex and .32 or .08,accent);self:label(preview.label,bx+bw/2,by+5,19,nil,"center",bw-12)
        end end
        local texture=D.Preview.texture(self.previewState,getTimestampMs());self.preview=texture
        if texture then
            local ratio=texture:getWidth()/math.max(1,texture:getHeight());local w=math.min(g.w,g.imageH*ratio);local h=w/ratio;local x=g.x+(g.w-w)/2;local y=g.imageY+(g.imageH-h)/2
            self:box(x-1,y-1,w+2,h+2,.45,accent);self:drawTextureScaled(texture,x,y,w,h,a,1,1,1)
        else self:label(#style.previews>0 and"Loading preview"or"No preview supplied",g.x+g.w/2,g.imageY+g.imageH/2-11,22,accent,"center",g.w)end
        self:setStencilRect(g.x,g.descriptionY,g.w,g.descriptionH)
        for i=self.descriptionOffset+1,math.min(#self.description,self.descriptionOffset+g.visibleLines)do self:label(self.description[i],g.x,g.descriptionY+(i-self.descriptionOffset-1)*g.lineH,22,nil,nil,g.w)end
        self:clearStencilRect()
        if #self.description>g.visibleLines then self:box(g.x+g.w-2,g.descriptionY,2,g.descriptionH,.2,accent);self:box(g.x+g.w-2,g.descriptionY+self.descriptionOffset/#self.description*g.descriptionH,2,g.visibleLines/#self.description*g.descriptionH,.8,accent)end
    end
    for i,name in ipairs(Styles.actions)do local x=g.x+(i-1)*g.w/2;local w=g.w/2-6
        self:box(x,g.buttonY,w,g.buttonH,self.action==i and .42 or .13,accent);self:box(x,g.buttonY+g.buttonH-2,w,2,self.action==i and 1 or .3,accent)
        self:label(name,x+w/2,g.buttonY+9,23,nil,"center",w-16)
    end
    self:box(g.pad,g.footerY,self.width-g.pad*2,1,.35,accent)
    local help=self.message or("Up/Down: style  |  Left/Right: slot  |  Enter: assign  |  F: favorite  |  Esc: back"..(style and #style.previews>1 and"  |  Tab: preview"or""))
    if self.helpText~=help then self.helpText=help;self.helpLines=D.Font.wrap(help,18,self.width-g.pad*2)end
    local lines=self.helpLines
    for i=1,math.min(2,#lines)do self:label(lines[i],g.pad,g.footerY+7+(i-1)*20,18,nil,nil,self.width-g.pad*2)end
end
function Styles.open(host)
    if host:submenu()or host.closing then return end
    local panel=Styles:new(host.width*.04,host.height*.06,host.width*.92,host.height*.88)
    panel.host=host;panel.alpha=0;panel.at=getTimestampMs();panel.selected=1;panel.offset=0;panel.action=1;panel.background=false;panel.styles={}
    for _,entry in ipairs(PY.listStyles())do panel.styles[#panel.styles+1]=D.Preview.style(entry)end
    table.sort(panel.styles,function(a,b)local an,bn=string.lower(a.name),string.lower(b.name);return an==bn and a.id<b.id or an<bn end)
    local preferences=D.preferences(host.player);if type(preferences.favorites)~="table"then preferences.favorites={}end;panel.favorites=preferences.favorites
    panel.heart=D.preloaded and D.preloaded.heart or getTexture("media/textures/ProjectYakuzaPhoneDev/FavoriteHeart.png")
    panel:initialise();panel:select(1);host.activeStyles=panel;host:addChild(panel);PY.UIAudio.play(host.player,"confirm")
end
