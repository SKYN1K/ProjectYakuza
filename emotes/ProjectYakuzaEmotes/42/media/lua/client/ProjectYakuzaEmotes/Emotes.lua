require "ProjectYakuzaEmotes/EmoteSpears"
require "ISUI/ISEmoteRadialMenu"
local PY=ProjectYakuzaEmotes
local E={id="ProjectYakuza_MajimaBatPoint",spearId="ProjectYakuza_LauSpearGround",kiryuId="ProjectYakuza_KiryuBadLuck",stepUpId="ProjectYakuza_KiryuStepUp",shimanoId="ProjectYakuza_ShimanoShutUp",category="ProjectYakuzaEmotes"}
PY.Emotes=E
local bats={['Base.BaseballBat']=true,['Base.BaseballBat_Crafted']=true,['Base.BaseballBat_Metal']=true,['Base.BaseballBat_Nails']=true,['Base.ShortBat']=true,['Base.ShortBat_Nails']=true}
local definitions={[E.id]={label="IGUI_ProjectYakuzaEmotes_Emote_MajimaBatPoint",items=bats,icon="comefront"},[E.spearId]={label="IGUI_ProjectYakuzaEmotes_Emote_LauSpearGround",spear=true,icon="stop"},[E.kiryuId]={label="IGUI_ProjectYakuzaEmotes_Emote_KiryuBadLuck",unarmed=true,icon="shrug"},[E.stepUpId]={label="IGUI_ProjectYakuzaEmotes_Emote_KiryuStepUp",unarmed=true,icon="comefront"},[E.shimanoId]={label="IGUI_ProjectYakuzaEmotes_Emote_ShimanoShutUp",unarmed=true,icon="stop"}}
function E.ready(p)
    if not p or not p:isLocalPlayer()or isGamePaused()or p:isDead()or p:isAsleep()or p:getVehicle()or p:isSitOnGround()or p:isPlayerMoving()or p:isAiming()or p:hasTimedActions()or p:isReading()or p:getVariableBoolean("EmotePlaying")then return false end
    local combat=ProjectYakuza;if combat and combat.activeActions and combat.activeActions[p]then return false end
    local queue=ISTimedActionQueue.queues[p];if queue and #queue.queue>0 then return false end
    return true
end
function E.canPlay(p,id)
    local definition=definitions[id or E.id];if not definition or not E.ready(p)then return false end
    local item=p:getPrimaryHandItem();local secondary=p:getSecondaryHandItem()
    if definition.unarmed then return item==nil and secondary==nil end
    if not item or not instanceof(item,"HandWeapon")or item:getCondition()<=0 or secondary~=nil and secondary~=item or p:isHideWeaponModel()or p:isHideEquippedHandR()then return false end
    if definition.spear then return PY.EmoteSpears[item:getFullType()]==true or item:getSubCategory()=="Spear"or item:getSwingAnim()=="Spear"end
    return definition.items[item:getFullType()]==true
end
function E.bindCVF()
    local cvf=CustomVoice;if type(cvf)~="table"or type(cvf.getEmote)~="function"or type(cvf.canPlayEmote)~="function"or cvf.canPlayEmote==E.cvfGuard then return end
    E.cvfGuard=function(p,id)return cvf.getEmote(id)and E.ready(p)or false end
    cvf.canPlayEmote=E.cvfGuard
end
E.bindCVF()
Events.OnGameStart.Add(E.bindCVF)
function E.play(p,id)
    id=id or E.id;if not E.canPlay(p,id)then return false end
    local clip=id;if id==E.spearId then clip=PY.SpearClips[p:getPrimaryHandItem():getFullType()]or id end
    p:playEmote(clip);return true
end
local originalInit=ISEmoteRadialMenu.init
function ISEmoteRadialMenu:init(...)
    originalInit(self,...)
    local category={name=getText("IGUI_ProjectYakuzaEmotes_Category"),subMenu={}}
    for id,definition in pairs(definitions)do category.subMenu[id]=getText(definition.label);ISEmoteRadialMenu.icons[id]=ISEmoteRadialMenu.icons[definition.icon]end
    ISEmoteRadialMenu.defaultMenu[E.category]=category;ISEmoteRadialMenu.menu[E.category]=category
    ISEmoteRadialMenu.icons[E.category]=ISEmoteRadialMenu.icons.comefront
end
local originalEmote=ISEmoteRadialMenu.emote
function ISEmoteRadialMenu:emote(id,...)
    if not definitions[id]then return originalEmote(self,id,...)end
    local accepted=E.play(self.character,id);self.character:setJoypadIgnoreAimUntilCentered(true);return accepted
end
