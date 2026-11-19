require "ProjectYakuzaPhoneDev/PhonePanel"
local PY=ProjectYakuza
local D=PY.PhoneDev
function D.phoneSound(p,kind)
    if not p or not p:isLocalPlayer()or p:isDead()or not getSoundManager then return false end
    getSoundManager():playUISound("ProjectYakuzaPhoneDev_Phone"..kind);return true
end
function D.compatible(version)
    local a,b,c=string.match(tostring(version or""),"^(%d+)%.(%d+)%.(%d+)")
    a,b,c=tonumber(a),tonumber(b),tonumber(c)
    return a and(a>0 or b>133 or b==133 and c>=0)or false
end
function D.open(p)
    local selector=PY.StyleSelector
    if D.panel or selector.setup or not selector.allowed(p)then return false end
    if selector.loadAssets then selector.loadAssets()end
    local panel=D.PhonePanel:new(p);D.panel=panel;selector.setup=panel
    local ok,message=pcall(function()panel:initialise();panel:addToUIManager();panel:bringToTop()end)
    if not ok then
        pcall(function()panel:close(true)end);D.panel=nil;selector.setup=nil
        print("[ProjectYakuza] Phone dev could not open: "..tostring(message))
        return D.legacyOpenSetup(p)
    end
    local state=JoypadState and JoypadState.players[p:getPlayerNum()+1]
    if state and p:getJoypadBind()~=-1 then panel.previousJoypad=state.focus;panel.joypadData=state;setJoypadFocus(p:getPlayerNum(),panel)end
    D.phoneSound(p,"Open");return true
end
function D.clear()
    if D.panel then D.panel:close(true)end
end
function D.install()
    if not D.compatible(PY.VERSION)then print("[ProjectYakuza] Phone dev needs Project Yakuza "..D.requiredCombatVersion.." or newer.");return end
    local selector=PY.StyleSelector
    D.preloaded=D.preloaded or {}
    for _,asset in pairs(D.assets)do D.preloaded[asset.path]=getTexture(asset.path)end
    D.preloaded.heart=getTexture("media/textures/ProjectYakuzaPhoneDev/FavoriteHeart.png")
    D.Font.atlas=D.Font.atlas or getTexture(D.Glyphs.path)
    D.preloaded.dragonPreview=getTexture("media/textures/ProjectYakuzaPhoneDev/DragonOfDojima.png")
    if selector.openSetup==D.open then return end
    D.legacyOpenSetup=selector.openSetup;selector.openSetup=D.open
end
Events.OnGameStart.Add(D.install)
Events.OnSave.Add(D.clear)
Events.OnMainMenuEnter.Add(D.clear)
