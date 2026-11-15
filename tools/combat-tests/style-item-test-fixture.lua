do local _="ProjectYakuzaFixture:POLICY" end
local T=PY.StyleItem
local styleSounds={}
getSoundManager=function()return {playUISound=function(_,name)styleSounds[#styleSounds+1]=name end}end
do local _="ProjectYakuzaFixture:UI_AUDIO" end
local inventory={items={}}
local function list(items)return {size=function()return #items end,get=function(_,i)return items[i+1]end}end
function inventory:getItems()return list(self.items)end
function inventory:getAllTypeRecurse()return list(self.items)end
function inventory:isInCharacterInventory(actor)return actor==p end
function inventory:Remove(item)for i=#self.items,1,-1 do if self.items[i]==item then table.remove(self.items,i);item.removed=true end end end
local function item(id)
 local x=weapon(id);x.blood=3;x.favorite=false;x.visual={blood=2,dirt=2}
 function x.visual:removeBlood()self.blood=0 end
 function x.visual:removeDirt()self.dirt=0 end
 function x:getBloodLevel()return self.blood end
 function x:setBloodLevel(v)self.blood=v end
 function x:isFavorite()return self.favorite end
 function x:setFavorite(v)self.favorite=v end
 function x:getVisual()return self.visual end
 function x:getContainer()return inventory end
 function x:getMaxHitCount()return PY.MAX_HIT_COUNT end
 function x:getWeaponSprite()return 'ProjectYakuza_EmptyHand' end
 inventory.items[#inventory.items+1]=x;return x
end
function inventory:AddItem(id)return item(id)end
function p:getInventory()return inventory end
function p:getPrimaryHandItem()return self.hand end
function p:setPrimaryHandItem(v)self.hand=v end
function p:setSecondaryHandItem(v)self.secondary=v end
function p:resetModelNextFrame()end
function p:updateHandEquips()end
function p:hasTimedActions()return self.timed==true end
function p:Say(v)self.said=v end
PY.StyleEntry={count=0,request=function(_,_,hadStyle)PY.StyleEntry.lastHadStyle=hadStyle;PY.StyleEntry.count=PY.StyleEntry.count+1 end}
local dropped,favorites,transfers=0,0,0
ISInventoryPaneContextMenu={dropItem=function()dropped=dropped+1;return true end,onFavorite=function(items,_,value)favorites=favorites+#items;for _,v in ipairs(items)do v:setFavorite(value)end end}
ISInventoryTransferAction={isValid=function()transfers=transfers+1;return true end}
do local _="ProjectYakuzaFixture:CLIENT_ITEM" end
local regular=item('Base.BaseballBat');local first=item(PY.TOKEN);p.hand=first
T.clean(first)
check(first.favorite and first.blood==0 and first.visual.blood==0 and first.visual.dirt==0,'style item is clean and protected')
check(not T.clean(regular) and regular.blood==3,'real equipment is not cleaned')
check(not ISInventoryPaneContextMenu.dropItem(first,p) and dropped==0,'style item cannot drop')
check(ISInventoryPaneContextMenu.dropItem(regular,p) and dropped==1,'normal drops unchanged')
ISInventoryPaneContextMenu.onFavorite({first,regular},nil,false)
check(first.favorite and not regular.favorite and favorites==1,'mixed favorite action protects token only')
local foreign={isInCharacterInventory=function()return false end}
check(not ISInventoryTransferAction.isValid({item=first,character=p,destContainer=foreign}) and transfers==0,'external transfers rejected')
check(ISInventoryTransferAction.isValid({item=first,character=p,destContainer=inventory}) and transfers==1,'own inventory transfers allowed')
check(ISInventoryTransferAction.isValid({item=regular,character=p,destContainer=foreign}),'regular transfers unaffected')
T.onHit(p,{},first);first.blood=9;first.visual.blood=9;T.flush()
check(first.blood==0 and first.visual.blood==0 and not T.ticking,'native post-hit blood cleared on deferred tick')
T.remember(p);p.hand=nil;T.update(p)
check(p.data.ProjectYakuzaStyle=='none' and first.removed and not p.hand,'manual unequip disables style and deletes token')
PY.equipStyle(p,'dragon_of_dojima')
local second=p.hand
check(PY.StyleEntry.lastHadStyle==false,'initial equip captures no prior style before selecting it')
PY.equipStyle(p,'dragon_of_dojima')
check(PY.StyleEntry.lastHadStyle==true,'already-equipped selection captures fast entry before changing equipment')
check(second~=first and not second.removed and second.favorite,'reselect creates clean replacement token')
local entries=PY.StyleEntry.count
p.hand=nil;p.timed=true;T.update(p)
check(not second.removed and p.data.ProjectYakuzaStyle=='dragon_of_dojima','transient hand during timed equip is deferred')
p.hand=regular;p.timed=false;T.update(p)
check(second.removed and p.hand==regular and PY.isEquipped(p),'supported weapon removes unused token and retains style')
clock=clock+1000;local soundCount=#styleSounds;local lifecycleEvents=0
PY.on('styleChanged',function()lifecycleEvents=lifecycleEvents+1 end)
p.hand=nil;T.update(p)
local third=p.hand
check(PY.isStyleToken(third) and PY.StyleEntry.count==entries,'removing real weapon restores temporary token without stance entry')
check(#styleSounds==soundCount and lifecycleEvents==1,'automatic empty-hand restoration keeps lifecycle cleanup and suppresses style audio')
clock=clock+1000;PY.equipStyle(p,'dragon_of_dojima')
check(#styleSounds==soundCount+1 and styleSounds[#styleSounds]=='ProjectYakuza_StyleSwitch','explicit reselection still plays style audio after a silent weapon handoff')
check(PY.unequipStyle(p) and third.removed and not p.hand,'explicit style removal deletes token')
p.hand=regular;PY.equipStyle(p,'dragon_of_dojima');check(p.hand==regular,'style selection preserves real weapon')
check(PY.unequipStyle(p) and p.hand==regular and not regular.removed,'style removal preserves real weapon')
p.hand=nil;PY.equipStyle(p,'dragon_of_dojima');local fourth=p.hand
local axe=item('Base.WoodAxe');p.hand=axe;T.update(p)
check(p.data.ProjectYakuzaStyle=='none' and fourth.removed and p.hand==axe,'unsupported equipment exits style without deleting real item')
p.hand=nil;PY.equipStyle(p,'dragon_of_dojima');local fifth=p.hand
local requests={}
isClient=function()return true end
PY.Network={localState=function()return {}end,equip=function(_,id,entry)requests[#requests+1]={id=id,entry=entry}end}
p.hand=nil;T.update(p)
check(p.data.ProjectYakuzaStyle=='none' and requests[1].id=='none' and not requests[1].entry,'MP manual removal requests authoritative disable')
check(not fifth.removed,'MP waits for server inventory removal')
isClient=function()return false end
T.removeUnused(p,nil)
check(fifth.removed and not regular.removed and not axe.removed,'cleanup removes only style items')
PY.Network=nil;p.hand=item(PY.TOKEN);p.data.ProjectYakuzaStyle='dragon_of_dojima';p.attacking=false;PY.resetPlayer(p,'test')
local heavyOK,heavyReason=PY.queueFinisher(p);check(heavyOK,'ordinary heavy works without a light attack: '..tostring(heavyReason))
check(PY.stateFor(p).finisherMove.neutralHeavy and p.vars.ProjectYakuzaMove=='dd_heavy','neutral heavy uses supplied Kiryu clip')
check(not PY.queueFinisher(p),'neutral heavy cannot queue a double finisher')
p.attacking=false;fire('OnPlayerAttackFinished',p,p.hand)
check(not PY.stateFor(p).firstFinisher and not PY.stateFor(p).finisherMove,'neutral heavy leaves no follow-up branch')
return true,'PASS '..checks..' actual style-item lifecycle, protection, MP request and neutral-heavy checks'
