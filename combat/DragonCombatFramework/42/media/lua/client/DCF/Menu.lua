require "DCF/Runtime"
require "DCF/HitEffects"
require "DCF/HeatAura"
require "DCF/CombatMusic"
require "DCF/Defense"
require "DCF/HeatActivation"
require "DCF/Feedback"
require "DCF/SoundSettings"
require "DCF/StyleSelector"
require "DCF/NetworkClient"
require "DCF/CombatVoices"
require "DCF/Taunts"
local DCF = DragonCombat
function DCF.equipStyle(player, styleId)
    local ok, reason = DCF.selectStyle(player, styleId)
    if not ok then player:Say("Cannot switch style: " .. tostring(reason)); return end
    local items, token = player:getInventory():getItems(), nil
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:getFullType() == DCF.TOKEN then token = item; break end
    end
    if not token then token = player:getInventory():AddItem(DCF.TOKEN) end
    if not token then print("[DCF] ERROR: style item could not be created"); return end
    DCF.prepareToken(token)
    player:setPrimaryHandItem(token)
    player:resetModelNextFrame()
    player:setSecondaryHandItem(nil)
    player:setVariable("DCFActive", true)
    player:setVariable("DCFMove", DCF.getPlayerStyle(player).lightAttacks[1].nodeValue)
    print("[DCF] equipped " .. styleId)
end
local function disable(player)
    if DCF.isBusy(player) then player:Say("Finish the current move first."); return end
    local item = player:getPrimaryHandItem()
    DCF.selectStyle(player, "none")
    if item and item:getFullType() == DCF.TOKEN then player:setPrimaryHandItem(nil) end
end
local function diagnostics(player)
    player:getModData().DCFDiagnostics = not player:getModData().DCFDiagnostics
    print("[DCF] " .. DCF.diagnosticLine(player))
end
local function menu(playerIndex, context)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end
    local root = context:addOption("Combat styles")
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)
    for _, id in ipairs(DCF.styleOrder) do
        local style = DCF.getStyle(id)
        sub:addOption(style.name, player, DCF.equipStyle, id)
    end
    sub:addOption("Disable fighting style", player, disable)
    sub:addOption("Assign style slots", player, DCF.StyleSelector.openSetup)
    if DCF.Taunts.available(player) then sub:addOption("Taunt (aim + "..DCF.Bindings.label("taunt")..")",player,DCF.Taunts.request) end
    sub:addOption("Toggle combat diagnostics", player, diagnostics)
    sub:addOption("Toggle hit sparks", player, DCF.HitEffects.toggle)
    sub:addOption("Toggle heat aura", player, DCF.HeatAura.toggle)
end
Events.OnFillInventoryObjectContextMenu.Add(menu)
