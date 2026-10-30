require "ProjectYakuza/Registry"
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISInventoryTransferAction"
local PY=ProjectYakuza
local T=PY.StyleItem
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
