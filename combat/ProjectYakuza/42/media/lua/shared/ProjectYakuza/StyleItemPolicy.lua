local PY=ProjectYakuza
local T={prepared=setmetatable({}, {__mode="k"}),pending=setmetatable({}, {__mode="k"}),nextUpdate=setmetatable({}, {__mode="k"}),owners=setmetatable({}, {__mode="k"})}
PY.StyleItem=T
function T.clean(item)
    if not PY.isStyleToken(item) then return false end
    if item.isFavorite and not item:isFavorite() then item:setFavorite(true) end
    if item.getBloodLevel and item:getBloodLevel()>0 then item:setBloodLevel(0) end
    local visual=item.getVisual and item:getVisual()
    if visual then
        visual:removeBlood();visual:removeDirt()
    end
    T.prepared[item]=true
    return true
end
function T.flush()
    local pending=T.pending;T.pending=setmetatable({}, {__mode="k"})
    if T.ticking then Events.OnTick.Remove(T.flush);T.ticking=false end
    for item in pairs(pending) do T.clean(item) end
end
function T.onHit(player,victim,item)
    if not PY.isStyleToken(item) then return end
    T.pending[item]=true
    if not T.ticking then Events.OnTick.Add(T.flush);T.ticking=true end
end
function T.remember(player)
    T.owners[player]={item=player:getPrimaryHandItem(),style=player:getModData().ProjectYakuzaStyle}
end
function T.removeUnused(player,keep)
    if isClient and isClient() then return 0 end
    local inventory=player:getInventory()
    local items=inventory.getAllTypeRecurse and inventory:getAllTypeRecurse(PY.TOKEN) or inventory:getItems()
    local removed=0
    for i=items:size()-1,0,-1 do
        local item=items:get(i)
        if item~=keep and PY.isStyleToken(item) then
            local container=item.getContainer and item:getContainer() or inventory
            if container then
                if isServer and isServer() and sendRemoveItemFromContainer then sendRemoveItemFromContainer(container,item) end
                container:Remove(item);removed=removed+1
            end
        end
    end
    return removed
end
function T.update(player)
    if not player or not player:isLocalPlayer() or player:isDead() then return end
    local item=player:getPrimaryHandItem();local id=player:getModData().ProjectYakuzaStyle
    local old=T.owners[player]
    if old and (old.item~=item or old.style~=id) and player:hasTimedActions() then return end
    if isClient and isClient() and PY.Network and PY.Network.localState(player).equipWanted then return end
    if not old or old.item~=item or old.style~=id then
        T.remember(player)
        if not PY.getStyle(id) then T.removeUnused(player,nil)
        elseif PY.isStyleToken(item) then T.clean(item);T.removeUnused(player,item)
        elseif item and PY.Weapons and PY.Weapons.profile(id,item) then
            if isClient and isClient() and PY.Network then PY.Network.equip(player,id,false) else T.removeUnused(player,nil) end
        elseif old and PY.isStyleToken(old.item) then
            if PY.resetPlayer then PY.resetPlayer(player,"style_item_unequipped") end
            if PY.unequipStyle then PY.unequipStyle(player) end
        elseif not item and not player:hasTimedActions() then
            if PY.equipStyle then PY.equipStyle(player,id,false) end
        elseif PY.unequipStyle then PY.unequipStyle(player) end
    end
    local now=getTimestampMs()
    if now<(T.nextUpdate[player] or 0) then return end
    T.nextUpdate[player]=now+250
    item=player:getPrimaryHandItem()
    if PY.isStyleToken(item) then T.clean(item) end
end

function T.canTransfer(item,player,destination)
    if not PY.isStyleToken(item) then return true end
    return player~=nil and destination~=nil and destination:isInCharacterInventory(player)==true
end
if Events and Events.OnWeaponHitCharacter then Events.OnWeaponHitCharacter.Add(T.onHit) end
if Events and Events.OnPlayerUpdate then Events.OnPlayerUpdate.Add(T.update) end
if Events and Events.OnSave then Events.OnSave.Add(T.flush) end
if Events and Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(T.flush) end
