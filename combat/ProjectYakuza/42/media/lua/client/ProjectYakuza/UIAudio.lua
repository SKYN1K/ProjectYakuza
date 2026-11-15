require "ProjectYakuza/Registry"
local PY=ProjectYakuza
local A={last=setmetatable({}, {__mode="k"})}
PY.UIAudio=A
A.sounds={open="ProjectYakuza_MenuOpen",cursor="ProjectYakuza_MenuCursor",confirm="ProjectYakuza_MenuConfirm",cancel="ProjectYakuza_MenuCancel",toggle="ProjectYakuza_MenuToggle",style="ProjectYakuza_StyleSwitch"}
function A.play(p,kind)
    local name=A.sounds[kind]
    if not name or not p or not p:isLocalPlayer() or p:isDead() or not getSoundManager then return false end
    local t=getTimestampMs();local last=A.last[p]
    if kind=="cursor" and last and t-last.cursor<65 then return false end
    if not last then last={cursor=-1000};A.last[p]=last end
    if kind=="cursor" then last.cursor=t end
    getSoundManager():playUISound(name)
    return true
end
function A.style(p,id,feedback)
    if feedback==false or id=="none" or not PY.getStyle(id) then return false end
    local last=A.last[p];local t=getTimestampMs()
    if last and last.style==id and t-(last.styleAt or 0)<150 then return false end
    if not A.play(p,"style") then return false end
    last=A.last[p];last.style=id;last.styleAt=t
    return true
end
PY.on("styleChanged",A.style)
local function clear()A.last=setmetatable({}, {__mode="k"})end
Events.OnSave.Add(clear)
Events.OnMainMenuEnter.Add(clear)
