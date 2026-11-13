local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
require=function()end
getText=function(key)return key end
getTexture=function(path)return path end
isGamePaused=function()return false end
instanceof=function(value,kind)return value.kind==kind end
ZombRand=function()return 0 end
Events={OnGameStart={Add=function()end}}
ISBaseObject={}
function ISBaseObject:derive()return setmetatable({},{__index=self})end
function ISBaseObject:new()return setmetatable({},{__index=self})end
ProjectYakuza={activeActions={}}
ISTimedActionQueue={queues={}}
CustomVoice={getEmotes=function()return {{id='cvf_y0_point',clip='CVF_Y0_Point',key='Point',icon='comefromfront'}}end,getEmote=function(id)if id=='cvf_y0_point'then return {id=id}end end}
"ProjectYakuzaFixture:NATIVE_MENU"
"ProjectYakuzaFixture:PROVIDERS"
local item={kind='HandWeapon',id='Base.BaseballBat_Metal',getFullType=function(self)return self.id end,getCondition=function()return 10 end}
local p={calls={}}
function p:isLocalPlayer()return true end
function p:isDead()return false end
function p:isAsleep()return false end
function p:getVehicle()return nil end
function p:isSitOnGround()return false end
function p:isPlayerMoving()return false end
function p:isAiming()return false end
function p:isCurrentlyBusy()return false end
function p:getVariableBoolean()return self.emoting end
function p:getPrimaryHandItem()if not self.empty then return item end end
function p:getSecondaryHandItem()if not self.empty then return item end end
function p:isHideWeaponModel()return false end
function p:isHideEquippedHandR()return false end
function p:playEmote(id)self.calls[#self.calls+1]=id;self.emoting=true end
function p:setJoypadIgnoreAimUntilCentered(value)self.centered=value end
function p:Callout()self.shouts=(self.shouts or 0)+1 end
local menu=setmetatable({character=p},{__index=ISEmoteRadialMenu})
for _=1,3 do
 menu:init();check(ISEmoteRadialMenu.menu.ProjectYakuza_Emotes.subMenu.ProjectYakuza_MajimaBatPoint~=nil,'Project Yakuza native category survives rebuild');check(ISEmoteRadialMenu.menu.cvf_yakuza0.subMenu.cvf_y0_point~=nil,'actual CVF category survives rebuild');check(ISEmoteRadialMenu.menu.friendly.subMenu.wavehi~=nil and #ISEmoteRadialMenu.variants.wavehi==3,'actual native categories and random variants survive')
end
check(menu:emote(ProjectYakuza.Emotes.id)and p.calls[1]==ProjectYakuza.Emotes.id,'Majima dispatches through native wheel with both actual providers')
check(not menu:emote(ProjectYakuza.Emotes.id)and #p.calls==1,'Majima cannot restart through either provider order')
p.emoting=false;check(menu:emote('cvf_y0_point')and p.calls[2]=='cvf_y0_point','actual CVF guarded native dispatch remains available')
p.emoting=false;menu:emote('wavehi');check(p.calls[3]=='wavehi','actual vanilla variant selection delegates')
p.emoting=false;menu:emote('shout');check(p.calls[4]=='shout'and p.shouts==1,'actual vanilla shout still dispatches its callout once')
p.emoting=false;item.id='Base.SpearCrafted';check(menu:emote(ProjectYakuza.Emotes.spearId)and p.calls[5]==ProjectYakuza.Emotes.spearId,'Lau spear gesture works with either actual provider order');check(not menu:emote(ProjectYakuza.Emotes.spearId)and #p.calls==5,'Lau gesture cannot restart')
p.emoting=false;check(not menu:emote(ProjectYakuza.Emotes.kiryuId)and #p.calls==5,'Kiryu rejects held weapons in either provider order');p.empty=true;check(menu:emote(ProjectYakuza.Emotes.kiryuId)and p.calls[6]==ProjectYakuza.Emotes.kiryuId,'Kiryu dispatches with empty hands in either provider order');check(not menu:emote(ProjectYakuza.Emotes.kiryuId)and #p.calls==6,'Kiryu cannot restart');menu:init();check(ISEmoteRadialMenu.menu.ProjectYakuza_Emotes.subMenu.ProjectYakuza_KiryuBadLuck and ISEmoteRadialMenu.icons.ProjectYakuza_KiryuBadLuck==ISEmoteRadialMenu.icons.shrug,'Kiryu retains native icon and label after actual menu reconstruction')
return true,'PASS '..checks..' actual installed B42 and pinned CVF emote hooks in Project Yakuza load order ProjectYakuzaFixture:ORDER'
