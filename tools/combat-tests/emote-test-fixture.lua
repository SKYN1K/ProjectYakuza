local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
require=function()end
ProjectYakuza={activeActions={}}
ISTimedActionQueue={queues={}}
local paused=false
isGamePaused=function()return paused end
getText=function(key)return key end
getTexture=function(path)return path end
instanceof=function(value,kind)return value.kind==kind end
ISEmoteRadialMenu={}
local originalCalls=0
function ISEmoteRadialMenu:init()
 ISEmoteRadialMenu.defaultMenu={friendly={subMenu={wavehi='Wave'}},cvf_yakuza0={subMenu={cvf_y0_point='CVF Point'}}};ISEmoteRadialMenu.menu=ISEmoteRadialMenu.defaultMenu;ISEmoteRadialMenu.icons={cvf_y0_point='cvf-icon',comefront='native-point-icon'};ISEmoteRadialMenu.variants={wavehi={'wavehi','wavehi02'}}
end
function ISEmoteRadialMenu:emote(id,argument)originalCalls=originalCalls+1;self.character:playEmote(id);return argument end
local item={kind='HandWeapon',id='Base.BaseballBat',condition=6}
function item:getFullType()return self.id end
function item:getCondition()return self.condition end
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
local E=ProjectYakuza.Emotes
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
return true,'PASS '..checks..' Majima bat emote native/CVF menu coexistence, safety guards, held-item identity, native dispatch and replay checks'
