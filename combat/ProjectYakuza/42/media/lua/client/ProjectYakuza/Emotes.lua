require "ProjectYakuza/Registry"
require "ProjectYakuza/EmoteSpears"
require "ISUI/ISEmoteRadialMenu"
local PY=ProjectYakuza
local E={id="ProjectYakuza_MajimaBatPoint",spearId="ProjectYakuza_LauSpearGround",kiryuId="ProjectYakuza_KiryuBadLuck",category="ProjectYakuza_Emotes"}
PY.Emotes=E
local bats={['Base.BaseballBat']=true,['Base.BaseballBat_Crafted']=true,['Base.BaseballBat_Metal']=true,['Base.BaseballBat_Nails']=true,['Base.ShortBat']=true,['Base.ShortBat_Nails']=true}
local definitions={[E.id]={label="IGUI_ProjectYakuza_Emote_MajimaBatPoint",items=bats,icon="comefront"},[E.spearId]={label="IGUI_ProjectYakuza_Emote_LauSpearGround",items=PY.EmoteSpears,icon="stop"},[E.kiryuId]={label="IGUI_ProjectYakuza_Emote_KiryuBadLuck",unarmed=true,icon="shrug"}}
function E.canPlay(p,id)
    local definition=definitions[id or E.id];if not definition then return false end
    if not p or not p:isLocalPlayer()or isGamePaused()or p:isDead()or p:isAsleep()or p:getVehicle()or p:isSitOnGround()or p:isPlayerMoving()or p:isAiming()or p:isCurrentlyBusy()or p:getVariableBoolean("EmotePlaying")then return false end
    if PY.activeActions and PY.activeActions[p]then return false end
    local queue=ISTimedActionQueue.queues[p];if queue and #queue.queue>0 then return false end
    local item=p:getPrimaryHandItem();local secondary=p:getSecondaryHandItem()
    if definition.unarmed then return item==nil and secondary==nil end
    return item~=nil and instanceof(item,"HandWeapon")and definition.items[item:getFullType()]==true and item:getCondition()>0 and(secondary==nil or secondary==item)and not p:isHideWeaponModel()and not p:isHideEquippedHandR()
end
function E.play(p,id)
    id=id or E.id;if not E.canPlay(p,id)then return false end
    p:playEmote(id);return true
end
local originalInit=ISEmoteRadialMenu.init
function ISEmoteRadialMenu:init(...)
    originalInit(self,...)
    local category={name=getText("IGUI_ProjectYakuza_Emotes"),subMenu={}}
    for id,definition in pairs(definitions)do category.subMenu[id]=getText(definition.label);ISEmoteRadialMenu.icons[id]=ISEmoteRadialMenu.icons[definition.icon]end
    ISEmoteRadialMenu.defaultMenu[E.category]=category;ISEmoteRadialMenu.menu[E.category]=category
    ISEmoteRadialMenu.icons[E.category]=ISEmoteRadialMenu.icons.comefront
end
local originalEmote=ISEmoteRadialMenu.emote
function ISEmoteRadialMenu:emote(id,...)
    if not definitions[id]then return originalEmote(self,id,...)end
    local accepted=E.play(self.character,id);self.character:setJoypadIgnoreAimUntilCentered(true);return accepted
end
