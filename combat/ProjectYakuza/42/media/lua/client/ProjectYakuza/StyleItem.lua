require "ProjectYakuza/Registry"
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISInventoryTransferAction"
require "ISUI/ISEquippedItem"
local PY=ProjectYakuza
local T=PY.StyleItem
local equippedIcon=ISEquippedItem.drawTextureScaledAspect
ISEquippedItem.drawTextureScaledAspect=function(self,texture,x,y,width,height,...)
    local p=self.chr
    if p then
        for _,slot in ipairs({{item=p:getPrimaryHandItem(),hand=self.mainHand},{item=p:getSecondaryHandItem(),hand=self.offHand}})do
            local item,hand=slot.item,slot.hand
            if hand and PY.isStyleToken(item)and texture==item:getTex()then
                local cx,cy=hand.x+hand.width/2,hand.y+hand.height/2
                if math.abs(x+width/2-cx)<.5 and math.abs(y+height/2-cy)<.5 then
                    local size=math.min(hand.width,hand.height)*128/112*.94
                    return equippedIcon(self,texture,cx-size/2,cy-size/2,size,size,...)
                end
            end
        end
    end
    return equippedIcon(self,texture,x,y,width,height,...)
end
local dropItem=ISInventoryPaneContextMenu.dropItem
ISInventoryPaneContextMenu.dropItem=function(item,player)
    if PY.isStyleToken(item) then T.clean(item);return false end
    return dropItem(item,player)
end
local onFavorite=ISInventoryPaneContextMenu.onFavorite
ISInventoryPaneContextMenu.onFavorite=function(items,item2,favorite)
    local contains=false
    for _,item in ipairs(items) do if PY.isStyleToken(item) then contains=true;break end end
    if not contains then return onFavorite(items,item2,favorite) end
    local regular={}
    for _,item in ipairs(items) do
        if PY.isStyleToken(item) then T.clean(item) else regular[#regular+1]=item end
    end
    if #regular>0 then return onFavorite(regular,item2,favorite) end
end
local isValid=ISInventoryTransferAction.isValid
ISInventoryTransferAction.isValid=function(self)
    if PY.isStyleToken(self.item) then
        T.clean(self.item)
        if not T.canTransfer(self.item,self.character,self.destContainer) then return false end
    end
    return isValid(self)
end
