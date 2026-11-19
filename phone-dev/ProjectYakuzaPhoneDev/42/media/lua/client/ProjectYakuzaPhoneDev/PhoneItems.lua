require "ProjectYakuzaPhoneDev/PhoneFont"
require "ISUI/ISPanel"
local PY=ProjectYakuza
local D=PY.PhoneDev
local M=D.Math
local Items=ISPanel:derive("ProjectYakuzaPhoneDevItems")
D.Items=Items
Items.categories={"Weapons","Food","Medical","Clothing","Other"}
Items.transitionSeconds=10/60
local function category(item)
    if instanceof(item,"HandWeapon")then return "Weapons"end
    if instanceof(item,"Food")then return "Food"end
    if instanceof(item,"Clothing")then return "Clothing"end
    if item:getDisplayCategory()=="Medical"then return "Medical"end
    return "Other"
end
function Items:label(text,x,y,size,r,g,b,a,align,maxWidth)
    D.Font.flat(self,text,x,y,r or .95,g or .94,b or .92,a or self.alpha,size or 19,align,maxWidth)
end
function Items:refresh()
    local list=self.host.player:getInventory():getItems();self.items={}
    for i=0,list:size()-1 do local item=list:get(i)
        if not PY.isStyleToken(item)and category(item)==Items.categories[self.tab]then
            self.items[#self.items+1]={item=item,name=item:getDisplayName(),texture=item:getTex(),weight=item:getActualWeight()}
        end
    end
    table.sort(self.items,function(a,b)return a.name<b.name end)
    self.selected=M.clamp(self.selected,1,math.max(1,#self.items));self.offset=M.clamp(self.offset,0,math.max(0,#self.items-self:visibleRows()));self.refreshed=getTimestampMs()
end
function Items:visibleRows()return math.max(1,math.floor((self.height-163)/53))end
function Items:setTab(index)
    self.tab=(index-1)%#Items.categories+1;self.selected=1;self.offset=0;self:refresh();PY.UIAudio.play(self.host.player,"cursor")
end
function Items:move(delta)
    self.selected=M.clamp(self.selected+delta,1,math.max(1,#self.items))
    if self.selected<=self.offset then self.offset=self.selected-1 end
    if self.selected>self.offset+self:visibleRows()then self.offset=self.selected-self:visibleRows()end
    PY.UIAudio.play(self.host.player,"cursor")
end
function Items:activate()
    if self.closing or self.alpha<.99 then return end
    local entry=self.items[self.selected];if not entry then return end
    local p=self.host.player;local item=entry.item
    if not p:getInventory():contains(item)then self.message="That item is no longer in your inventory.";self:refresh();return end
    local mx,my=getMouseX(),getMouseY()
    self.host:close(false,function()
        if not p:getInventory():contains(item)then return end
        if instanceof(item,"HandWeapon")then ISInventoryPaneContextMenu.equipWeapon(item,true,item:isTwoHandWeapon(),p:getPlayerNum())
        else ISInventoryPaneContextMenu.createMenu(p:getPlayerNum(),true,{item},mx,my)end
    end)
end
function Items:close()
    if self.closing then return end
    self.closing=true;self.fromAlpha=self.alpha;self.at=getTimestampMs();PY.UIAudio.play(self.host.player,"cancel")
end
function Items:onKeyPress(key)
    if key==Keyboard.KEY_ESCAPE then self:close()
    elseif not self.closing then
        if key==Keyboard.KEY_LEFT then self:setTab(self.tab-1)
        elseif key==Keyboard.KEY_RIGHT or key==Keyboard.KEY_TAB then self:setTab(self.tab+1)
        elseif key==Keyboard.KEY_UP then self:move(-1)
        elseif key==Keyboard.KEY_DOWN then self:move(1)
        elseif key==Keyboard.KEY_RETURN or key==Keyboard.KEY_NUMPADENTER then self:activate()end
    end
end
function Items:onMouseDown(x,y)
    if self.closing then return true end
    if y>=39 and y<78 then self:setTab(math.floor((x-18)/((self.width-36)/#Items.categories))+1)
    elseif x<self.width*.62 and y>=94 and y<self.height-69 then
        local index=math.floor((y-94)/53)+1+self.offset
        if index<=#self.items then self.selected=index;PY.UIAudio.play(self.host.player,"cursor")end
    elseif x>self.width*.64 and y>self.height-108 then self:activate()end
    return true
end
function Items:onMouseDoubleClick(x,y)
    self:onMouseDown(x,y)
    if x>=18 and x<self.width*.62 and y>=94 and y<self.height-69 and math.floor((y-94)/53)+1+self.offset<=#self.items then self:activate()end
    return true
end
function Items:onMouseWheel(delta)
    self.offset=M.clamp(self.offset+delta*3,0,math.max(0,#self.items-self:visibleRows()));return true
end
function Items:onMouseMove()return true end
function Items:onMouseUp()return true end
function Items:onRightMouseDown()self:close();return true end
function Items:onRightMouseUp()return true end
function Items:prerender()
    local now=getTimestampMs();local t=M.clamp((now-self.at)/1000/Items.transitionSeconds,0,1)
    self.alpha=self.closing and self.fromAlpha*(1-t)or t
    if self.closing and t>=1 then self.host.activeItems=nil;self.host:removeChild(self);return end
    if now-self.refreshed>=1500 then self:refresh()end
    local a=self.alpha;local listW=self.width*.62
    self:drawRect(0,0,self.width,self.height,a*.97,.025,.022,.027)
    self:drawRect(0,0,self.width,29,a,.88,.87,.85);self:label("Items",self.width/2,3,23,.05,.05,.05,a,"center")
    for i,name in ipairs(Items.categories)do local x=18+(i-1)*(self.width-36)/#Items.categories;local w=(self.width-36)/#Items.categories
        if i==self.tab then self:drawRect(x,39,w-3,36,a*.85,.84,.31,.07)end
        self:label(name,x+w/2-2,45,21,nil,nil,nil,a,"center")
    end
    self:setStencilRect(16,92,listW-22,self.height-160)
    for i=self.offset+1,math.min(#self.items,self.offset+self:visibleRows())do
        local entry=self.items[i];local y=94+(i-self.offset-1)*53
        if i==self.selected then self:drawRect(18,y,listW-28,51,a*.45,.79,.29,.05)end
        self:drawRect(18,y+52,listW-28,1,a*.22,.55,.53,.51)
        if entry.texture and entry.texture:isReady()then self:drawTextureScaled(entry.texture,25,y+7,38,38,a,1,1,1)end
        self:label(entry.name,77,y+15,21,nil,nil,nil,a,nil,listW-94)
    end
    self:clearStencilRect()
    self:drawRect(listW,94,1,self.height-164,a*.3,.65,.61,.58)
    local entry=self.items[self.selected];local x=listW+23
    if entry then
        self:label(entry.name,x,103,24,nil,nil,nil,a)
        if entry.texture and entry.texture:isReady()then self:drawTextureScaled(entry.texture,x+16,151,82,82,a,1,1,1)end
        self:label(Items.categories[self.tab],x,256,19,.64,.79,.66,a)
        self:label(string.format("Weight: %.2f",entry.weight),x,287,20,nil,nil,nil,a)
        if instanceof(entry.item,"HandWeapon")then self:label("Condition: "..math.floor(entry.item:getCondition()/math.max(1,entry.item:getConditionMax())*100).."%",x,318,20,nil,nil,nil,a)end
        self:drawRect(x,self.height-111,self.width-x-23,38,a*.7,.77,.27,.05);self:label("Select / actions",x+12,self.height-103,21,nil,nil,nil,a)
    else self:label("No items in this category",x,114,20,nil,nil,nil,a)end
    self:drawRect(18,self.height-57,self.width-36,1,a*.3,.61,.58,.56)
    self:label(self.message or(self.host.gamepad and"Left/right: category   A: actions   B: back"or"Left/right: category   Enter: actions   Esc: back"),23,self.height-40,19,nil,nil,nil,a)
end
function Items.open(host)
    if host.activeItems or host.closing then return end
    local p=Items:new(host.width*.06,host.height*.09,host.width*.88,host.height*.82)
    p.host=host;p.alpha=0;p.at=getTimestampMs();p.tab=1;p.selected=1;p.offset=0;p.background=false;p:initialise();p:refresh();host.activeItems=p;host:addChild(p);PY.UIAudio.play(host.player,"confirm")
end
