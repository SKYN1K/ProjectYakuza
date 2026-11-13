require "ProjectYakuza/Registry"
require "ISUI/ISEmoteRadialMenu"
local PY=ProjectYakuza
local E={id="ProjectYakuza_MajimaBatPoint",category="ProjectYakuza_Emotes"}
PY.Emotes=E
local bats={['Base.BaseballBat']=true,['Base.BaseballBat_Crafted']=true,['Base.BaseballBat_Metal']=true,['Base.BaseballBat_Nails']=true,['Base.ShortBat']=true,['Base.ShortBat_Nails']=true}
function E.canPlay(p)
    if not p or not p:isLocalPlayer()or isGamePaused()or p:isDead()or p:isAsleep()or p:getVehicle()or p:isSitOnGround()or p:isPlayerMoving()or p:isAiming()or p:isCurrentlyBusy()or p:getVariableBoolean("EmotePlaying")then return false end
    if PY.activeActions and PY.activeActions[p]then return false end
    local queue=ISTimedActionQueue.queues[p];if queue and #queue.queue>0 then return false end
    local item=p:getPrimaryHandItem();local secondary=p:getSecondaryHandItem()
    return item~=nil and instanceof(item,"HandWeapon")and bats[item:getFullType()]==true and item:getCondition()>0 and(secondary==nil or secondary==item)and not p:isHideWeaponModel()and not p:isHideEquippedHandR()
end
function E.play(p)
    if not E.canPlay(p)then return false end
    p:playEmote(E.id);return true
end
local originalInit=ISEmoteRadialMenu.init
function ISEmoteRadialMenu:init(...)
    originalInit(self,...)
    local category={name=getText("IGUI_ProjectYakuza_Emotes"),subMenu={[E.id]=getText("IGUI_ProjectYakuza_Emote_MajimaBatPoint")}}
    ISEmoteRadialMenu.defaultMenu[E.category]=category;ISEmoteRadialMenu.menu[E.category]=category
    local icon=ISEmoteRadialMenu.icons.comefront;ISEmoteRadialMenu.icons[E.category]=icon;ISEmoteRadialMenu.icons[E.id]=icon
end
local originalEmote=ISEmoteRadialMenu.emote
function ISEmoteRadialMenu:emote(id,...)
    if id~=E.id then return originalEmote(self,id,...)end
    local accepted=E.play(self.character);self.character:setJoypadIgnoreAimUntilCentered(true);return accepted
end
