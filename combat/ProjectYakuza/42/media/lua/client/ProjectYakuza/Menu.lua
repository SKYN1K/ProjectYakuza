require "ProjectYakuza/Runtime"
require "ProjectYakuza/StyleItem"
require "ProjectYakuza/HitEffects"
require "ProjectYakuza/AttackEffects"
require "ProjectYakuza/HeatAura"
require "ProjectYakuza/CombatMusic"
require "ProjectYakuza/Defense"
require "ProjectYakuza/HeatActivation"
require "ProjectYakuza/Feedback"
require "ProjectYakuza/SoundSettings"
require "ProjectYakuza/StyleSelector"
require "ProjectYakuza/NetworkClient"
require "ProjectYakuza/CombatVoices"
require "ProjectYakuza/Taunts"
require "ProjectYakuza/StyleEntry"
require "ProjectYakuza/GrabCombat"
require "ProjectYakuza/EncounterIntroY6"
local ProjectYakuza = ProjectYakuza
function ProjectYakuza.equipStyle(player, styleId,playEntry)
    local hadStyle=ProjectYakuza.isEquipped(player)
    local ok, reason = ProjectYakuza.selectStyle(player, styleId,playEntry~=false)
    if not ok then player:Say("Cannot switch style: " .. tostring(reason)); return end

    if isClient() then ProjectYakuza.Network.equip(player,styleId,playEntry~=false,hadStyle);return end
    local held=player:getPrimaryHandItem()
    if ProjectYakuza.Weapons and ProjectYakuza.Weapons.profile(styleId,held) then
        player:setVariable("ProjectYakuzaActive",true)
        if ProjectYakuza.StyleItem then ProjectYakuza.StyleItem.removeUnused(player,nil);ProjectYakuza.StyleItem.remember(player) end
        if playEntry~=false then ProjectYakuza.StyleEntry.request(player,styleId,hadStyle) end
        return
    end
    local items, token = player:getInventory():getItems(), nil
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if ProjectYakuza.isStyleToken(item) then token = item; break end
    end
    if not token then token = player:getInventory():AddItem(ProjectYakuza.TOKEN) end
    if not token then print("[ProjectYakuza] ERROR: style item could not be created"); return end
    ProjectYakuza.prepareToken(token)
    player:setPrimaryHandItem(token)
    player:resetModelNextFrame()
    player:setSecondaryHandItem(nil)
    player:setVariable("ProjectYakuzaActive", true)
    player:setVariable("ProjectYakuzaMove", ProjectYakuza.getPlayerStyle(player).lightAttacks[1].nodeValue)
    if ProjectYakuza.StyleItem then ProjectYakuza.StyleItem.removeUnused(player,token);ProjectYakuza.StyleItem.remember(player) end
    if playEntry~=false then ProjectYakuza.StyleEntry.request(player,styleId,hadStyle) end
    print("[ProjectYakuza] equipped " .. styleId)
end
function ProjectYakuza.unequipStyle(player)
    if ProjectYakuza.isBusy(player) then return false,"busy" end
    local item=player:getPrimaryHandItem()
    local ok,reason=ProjectYakuza.selectStyle(player,"none")
    if not ok then return false,reason end
    if ProjectYakuza.isStyleToken(item) then player:setPrimaryHandItem(nil);player:resetModelNextFrame();player:updateHandEquips() end
    if isClient() then ProjectYakuza.Network.equip(player,"none",false)
    elseif ProjectYakuza.StyleItem then ProjectYakuza.StyleItem.removeUnused(player,nil) end
    if ProjectYakuza.StyleItem then ProjectYakuza.StyleItem.remember(player) end
    return true
end
