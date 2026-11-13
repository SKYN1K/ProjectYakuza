local checks=0
local hasCVF="ProjectYakuzaFixture:HAS_CVF"
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
ProjectYakuza=nil
ISTimedActionQueue={queues={}}
if hasCVF then CustomVoice={getEmotes=function()return {{id='cvf_y0_point',clip='CVF_Y0_Point',key='Point',icon='comefromfront'}}end,getEmote=function(id)if id=='cvf_y0_point'then return {id=id}end end}end
"ProjectYakuzaFixture:NATIVE_MENU"
"ProjectYakuzaFixture:PROVIDERS"
local item={kind='HandWeapon',id='Base.BaseballBat_Metal',getFullType=function(self)return self.id end,getCondition=function()return 10 end}
function item:getSubCategory()return nil end
function item:getSwingAnim()return nil end
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
 menu:init();check(ISEmoteRadialMenu.menu.ProjectYakuzaEmotes.subMenu.ProjectYakuza_MajimaBatPoint~=nil,'standalone native category survives rebuild');check(hasCVF and ISEmoteRadialMenu.menu.cvf_yakuza0.subMenu.cvf_y0_point~=nil or not hasCVF and ISEmoteRadialMenu.menu.cvf_yakuza0==nil,'actual CVF presence remains optional');check(ISEmoteRadialMenu.menu.friendly.subMenu.wavehi~=nil and #ISEmoteRadialMenu.variants.wavehi==3,'actual native categories and random variants survive')
end
check(menu:emote(ProjectYakuzaEmotes.Emotes.id)and p.calls[1]==ProjectYakuzaEmotes.Emotes.id,'Majima dispatches through native wheel with both actual providers')
check(not menu:emote(ProjectYakuzaEmotes.Emotes.id)and #p.calls==1,'Majima cannot restart through either provider order')
p.emoting=false;if hasCVF then check(menu:emote('cvf_y0_point')and p.calls[#p.calls]=='cvf_y0_point','actual CVF guarded native dispatch remains available')else check(ProjectYakuza==nil and CustomVoice==nil,'standalone requires neither optional provider')end
p.emoting=false;local before=#p.calls;menu:emote('wavehi');check(#p.calls==before+1 and p.calls[#p.calls]=='wavehi','actual vanilla variant selection delegates')
p.emoting=false;before=#p.calls;menu:emote('shout');check(#p.calls==before+1 and p.calls[#p.calls]=='shout'and p.shouts==1,'actual vanilla shout still dispatches its callout once')
p.emoting=false;before=#p.calls;item.id='Base.SpearCrafted';check(menu:emote(ProjectYakuzaEmotes.Emotes.spearId)and #p.calls==before+1 and p.calls[#p.calls]==ProjectYakuzaEmotes.Emotes.spearId,'Lau spear gesture works with optional CVF');check(not menu:emote(ProjectYakuzaEmotes.Emotes.spearId)and #p.calls==before+1,'Lau gesture cannot restart')
p.emoting=false;before=#p.calls;check(not menu:emote(ProjectYakuzaEmotes.Emotes.kiryuId)and #p.calls==before,'Kiryu rejects held weapons with optional CVF');p.empty=true;check(menu:emote(ProjectYakuzaEmotes.Emotes.kiryuId)and #p.calls==before+1 and p.calls[#p.calls]==ProjectYakuzaEmotes.Emotes.kiryuId,'Kiryu dispatches with empty hands with optional CVF');check(not menu:emote(ProjectYakuzaEmotes.Emotes.kiryuId)and #p.calls==before+1,'Kiryu cannot restart');menu:init();check(ISEmoteRadialMenu.menu.ProjectYakuzaEmotes.subMenu.ProjectYakuza_KiryuBadLuck and ISEmoteRadialMenu.icons.ProjectYakuza_KiryuBadLuck==ISEmoteRadialMenu.icons.shrug,'Kiryu retains native icon and label after actual menu reconstruction')
return true,'PASS '..checks..' actual installed B42 and pinned CVF emote hooks in Project Yakuza load order ProjectYakuzaFixture:ORDER'
