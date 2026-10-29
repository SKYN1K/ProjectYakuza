require "ProjectYakuza/Runtime"
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
local ProjectYakuza = ProjectYakuza
function ProjectYakuza.equipStyle(player, styleId)
    local ok, reason = ProjectYakuza.selectStyle(player, styleId)
    if not ok then player:Say("Cannot switch style: " .. tostring(reason)); return end
    -- B42 hit packets carry an inventory item ID, not a serialized weapon.
    -- A client-only AddItem produces a weapon the server can never resolve.
    if isClient() then ProjectYakuza.Network.equip(player,styleId,true);return end
    local held=player:getPrimaryHandItem()
    if ProjectYakuza.Weapons and ProjectYakuza.Weapons.profile(styleId,held) then
        player:setVariable("ProjectYakuzaActive",true)
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
    ProjectYakuza.StyleEntry.request(player,styleId)
    print("[ProjectYakuza] equipped " .. styleId)
end
local function disable(player)
    if ProjectYakuza.isBusy(player) then player:Say("Finish the current move first."); return end
    local item = player:getPrimaryHandItem()
    ProjectYakuza.selectStyle(player, "none")
    if isClient() then ProjectYakuza.Network.equip(player,"none") end
    if item and ProjectYakuza.isStyleToken(item) then player:setPrimaryHandItem(nil) end
end
local function diagnostics(player)
    player:getModData().ProjectYakuzaDiagnostics = not player:getModData().ProjectYakuzaDiagnostics
    print("[ProjectYakuza] " .. ProjectYakuza.diagnosticLine(player))
end
local function menu(playerIndex, context)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end
    local root = context:addOption("Combat styles")
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)
    for _, id in ipairs(ProjectYakuza.styleOrder) do
        local style = ProjectYakuza.getStyle(id)
        sub:addOption(style.name, player, ProjectYakuza.equipStyle, id)
    end
    sub:addOption("Disable fighting style", player, disable)
    sub:addOption("Assign style slots", player, ProjectYakuza.StyleSelector.openSetup)
    if ProjectYakuza.Taunts.available(player) then sub:addOption("Taunt (aim + "..ProjectYakuza.Bindings.label("taunt")..")",player,ProjectYakuza.Taunts.request) end
    sub:addOption("Toggle combat diagnostics", player, diagnostics)
    sub:addOption("Toggle hit sparks", player, ProjectYakuza.HitEffects.toggle)
    sub:addOption("Toggle heat aura", player, ProjectYakuza.HeatAura.toggle)
end
Events.OnFillInventoryObjectContextMenu.Add(menu)
