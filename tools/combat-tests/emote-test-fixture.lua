local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
require=function()end
ProjectYakuza=nil
ISTimedActionQueue={queues={}}
local paused=false
isGamePaused=function()return paused end
getText=function(key)return key end
getTexture=function(path)return path end
instanceof=function(value,kind)return value.kind==kind end
ISEmoteRadialMenu={}
local originalCalls=0
function ISEmoteRadialMenu:init()
 ISEmoteRadialMenu.defaultMenu={friendly={subMenu={wavehi='Wave'}},cvf_yakuza0={subMenu={cvf_y0_point='CVF Point'}}};ISEmoteRadialMenu.menu=ISEmoteRadialMenu.defaultMenu;ISEmoteRadialMenu.icons={cvf_y0_point='cvf-icon',comefront='native-point-icon',stop='native-stop-icon',shrug='native-shrug-icon'};ISEmoteRadialMenu.variants={wavehi={'wavehi','wavehi02'}}
end
function ISEmoteRadialMenu:emote(id,argument)originalCalls=originalCalls+1;self.character:playEmote(id);return argument end
local item={kind='HandWeapon',id='Base.BaseballBat',condition=6}
function item:getFullType()return self.id end
function item:getCondition()return self.condition end
function item:getSubCategory()return self.subCategory end
function item:getSwingAnim()return self.swingAnim end
local p={primary=item,calls={}}
function p:isLocalPlayer()return not self.remote end
function p:isDead()return self.dead end
function p:isAsleep()return self.asleep end
function p:getVehicle()return self.vehicle end
function p:isSitOnGround()return self.sitting end
function p:isPlayerMoving()return self.moving end
function p:isAiming()return self.aiming end
function p:isCurrentlyBusy()return self.busy end
function p:getVariableBoolean(key)return key=='EmotePlaying'and self.emoting end
function p:getPrimaryHandItem()return self.primary end
function p:getSecondaryHandItem()return self.secondary end
function p:isHideWeaponModel()return self.hidden end
function p:isHideEquippedHandR()return self.rightHidden end
function p:playEmote(id)self.calls[#self.calls+1]=id;self.emoting=true end
function p:setJoypadIgnoreAimUntilCentered(value)self.joypadCentered=value end
"ProjectYakuzaFixture:EMOTES"
local E=ProjectYakuzaEmotes.Emotes
check(ProjectYakuza==nil and ProjectYakuzaEmotes.VERSION=="ProjectYakuzaFixture:VERSION","standalone module loads without combat globals and shares metadata version")
ProjectYakuza={activeActions={}}
local menu=setmetatable({character=p},{__index=ISEmoteRadialMenu})
for _=1,3 do
 menu:init();check(ISEmoteRadialMenu.menu[E.category].subMenu[E.id]~=nil,'entry survives native menu reconstruction');check(ISEmoteRadialMenu.defaultMenu[E.category]==ISEmoteRadialMenu.menu[E.category],'configuration defaults include category')
 check(ISEmoteRadialMenu.menu.friendly.subMenu.wavehi=='Wave'and ISEmoteRadialMenu.menu.cvf_yakuza0.subMenu.cvf_y0_point=='CVF Point','native and CVF entries preserved');check(ISEmoteRadialMenu.icons.cvf_y0_point=='cvf-icon'and ISEmoteRadialMenu.icons[E.id]=='native-point-icon'and ISEmoteRadialMenu.variants.wavehi[2]=='wavehi02','other icons and native variants preserved')
end
check(not E.play(nil),'missing owner rejected')
paused=true;check(not E.play(p),'pause rejected');paused=false
for _,state in ipairs({'remote','dead','asleep','vehicle','sitting','moving','aiming','busy','emoting','hidden','rightHidden'})do p[state]=true;check(not E.play(p),'unsafe native state rejected '..state);p[state]=nil end
ProjectYakuza.activeActions[p]={};check(not E.play(p),'custom combat action cannot be interrupted by emote');ProjectYakuza.activeActions[p]=nil
ISTimedActionQueue.queues[p]={queue={true}};check(not E.play(p),'queued timed action preserved');ISTimedActionQueue.queues[p]=nil
p.secondary={};check(not E.play(p),'unrelated off-hand item rejected');p.secondary=nil
p.primary=nil;check(not E.play(p),'no imaginary bat is created');p.primary=item
for _,id in ipairs({'Base.Katana','Base.HuntingKnife','ProjectYakuza.Bicycle','Base.Crowbar'})do item.id=id;check(not E.play(p),'unrelated item rejected '..id)end
item.id='Base.BaseballBat';item.condition=0;check(not E.play(p),'broken bat rejected');item.condition=6
item.kind='InventoryItem';check(not E.play(p),'item spoof without native weapon type rejected');item.kind='HandWeapon'
check(#p.calls==0,'rejections never dispatch animation')
for _,id in ipairs({'Base.BaseballBat','Base.BaseballBat_Crafted','Base.BaseballBat_Metal','Base.BaseballBat_Nails','Base.ShortBat','Base.ShortBat_Nails'})do
 item.id=id;p.emoting=false;p.secondary=item;local before=#p.calls;check(menu:emote(E.id),'held bat selection accepted '..id);check(#p.calls==before+1 and p.calls[#p.calls]==E.id and p.primary==item and p.secondary==item,'native state dispatch once and original equipment retained')
 check(not menu:emote(E.id)and #p.calls==before+1,'playing emote cannot restart');check(p.joypadCentered,'controller selection resets aim')
end
p.emoting=false;local before=originalCalls;check(menu:emote('cvf_y0_point','cvf-result')=='cvf-result'and originalCalls==before+1,'CVF selection delegates unchanged');check(menu:emote('wavehi','native-result')=='native-result'and originalCalls==before+2,'vanilla selection delegates unchanged')
check(not ProjectYakuza.activeActions[p]and not ISTimedActionQueue.queues[p],'emote owns no timed-action, combat or Heat state')
p.emoting=false;item.id='Base.SpearCrafted';check(not E.play(p),'spear cannot borrow bat gesture')
item.id='Base.BaseballBat';check(not E.play(p,E.spearId),'bat cannot borrow spear gesture')
check(not E.play(p,'other.emote'),'unknown custom gesture rejected')
for id in pairs(ProjectYakuzaEmotes.EmoteSpears)do
 item.id=id;p.emoting=false;local before=#p.calls;check(menu:emote(E.spearId),'every native spear accepted '..id);check(p.calls[#p.calls]==ProjectYakuzaEmotes.SpearClips[id]and #p.calls==before+1 and p.primary==item,'calibrated source spear gesture dispatches once without replacing equipment');check(not menu:emote(E.spearId)and #p.calls==before+1,'spear gesture cannot restart')
end
item.id='Modded.LongSpear';item.subCategory='Spear';p.emoting=false;check(E.play(p,E.spearId)and p.calls[#p.calls]==E.spearId,'modded spear category uses native fallback without item substitution');item.subCategory=nil;item.swingAnim='Spear';p.emoting=false;check(E.play(p,E.spearId)and p.calls[#p.calls]==E.spearId,'modded spear swing animation uses native fallback');item.swingAnim=nil;p.emoting=false;check(not E.play(p,E.spearId),'unrelated modded weapon cannot borrow spear gesture')
item.id='Base.SpearCrafted';p.emoting=false
for _,state in ipairs({'remote','dead','asleep','vehicle','sitting','moving','aiming','busy','emoting','hidden','rightHidden'})do p[state]=true;check(not E.play(p,E.spearId),'spear shares native safety guard '..state);p[state]=nil end
item.condition=0;check(not E.play(p,E.spearId),'broken spear rejected');item.condition=6
menu:init();check(ISEmoteRadialMenu.menu[E.category].subMenu[E.spearId]and ISEmoteRadialMenu.icons[E.spearId]=='native-stop-icon','spear menu label and existing native icon registered')
p.emoting=false;p.primary=nil;p.secondary=nil
check(not E.play(p)and not E.play(p,E.spearId),'empty hands cannot dispatch held-weapon gestures')
paused=true;check(not E.play(p,E.kiryuId),'Kiryu gesture respects pause');paused=false
for _,state in ipairs({'remote','dead','asleep','vehicle','sitting','moving','aiming','busy','emoting'})do p[state]=true;check(not E.play(p,E.kiryuId),'Kiryu shares native safety guard '..state);p[state]=nil end
ProjectYakuza.activeActions[p]={};check(not E.play(p,E.kiryuId),'Kiryu cannot interrupt combat');ProjectYakuza.activeActions[p]=nil
ISTimedActionQueue.queues[p]={queue={true}};check(not E.play(p,E.kiryuId),'Kiryu cannot interrupt timed action');ISTimedActionQueue.queues[p]=nil
for _,id in ipairs({'Base.BaseballBat','Base.SpearCrafted','Base.Katana','Base.HuntingKnife'})do item.id=id;p.primary=item;check(not E.play(p,E.kiryuId),'held weapon rejected for Kiryu '..id)end
p.primary=nil;p.secondary=item;check(not E.play(p,E.kiryuId),'off-hand item rejected for Kiryu');p.secondary=nil
local before=#p.calls;check(menu:emote(E.kiryuId)and #p.calls==before+1 and p.calls[#p.calls]==E.kiryuId,'Kiryu dispatches native emote once with empty hands');check(not menu:emote(E.kiryuId)and #p.calls==before+1,'Kiryu cannot restart');check(p.primary==nil and p.secondary==nil and not ProjectYakuza.activeActions[p]and not ISTimedActionQueue.queues[p],'Kiryu leaves equipment, combat and timed-action state untouched')
menu:init();check(ISEmoteRadialMenu.menu[E.category].subMenu[E.kiryuId]and ISEmoteRadialMenu.icons[E.kiryuId]=='native-shrug-icon','Kiryu label and original native icon survive menu reconstruction')
p.emoting=false;ProjectYakuza=nil;check(E.canPlay(p,E.kiryuId),"standalone unarmed readiness needs no combat global");check(E.play(p,E.kiryuId),"standalone dispatch needs no combat global")
p.emoting=false;paused=true;check(not E.play(p,E.stepUpId),'Step Up respects pause');paused=false
for _,state in ipairs({'remote','dead','asleep','vehicle','sitting','moving','aiming','busy','emoting'})do p[state]=true;check(not E.play(p,E.stepUpId),'Step Up shares native safety guard '..state);p[state]=nil end
ProjectYakuza={activeActions={[p]={}}};check(not E.play(p,E.stepUpId),'Step Up cannot interrupt optional combat');ProjectYakuza.activeActions[p]=nil
ISTimedActionQueue.queues[p]={queue={true}};check(not E.play(p,E.stepUpId),'Step Up cannot interrupt timed action');ISTimedActionQueue.queues[p]=nil
p.primary=item;check(not E.play(p,E.stepUpId),'Step Up rejects occupied primary hand');p.primary=nil;p.secondary=item;check(not E.play(p,E.stepUpId),'Step Up rejects occupied off-hand');p.secondary=nil
ProjectYakuza=nil;before=#p.calls;check(menu:emote(E.stepUpId)and #p.calls==before+1 and p.calls[#p.calls]==E.stepUpId,'Step Up dispatches once without combat or held items');check(not menu:emote(E.stepUpId)and #p.calls==before+1,'Step Up cannot restart');check(p.primary==nil and p.secondary==nil,'Step Up retains empty hands');menu:init();check(ISEmoteRadialMenu.menu[E.category].subMenu[E.stepUpId]and ISEmoteRadialMenu.icons[E.stepUpId]=='native-point-icon','Step Up label and original native icon registered')
return true,'PASS '..checks..' standalone bat/spear/unarmed emote native/CVF menu coexistence, safety guards, equipment identity, native dispatch and replay checks'
