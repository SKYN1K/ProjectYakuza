require=function()end
local checks=0
local function check(v,message)checks=checks+1;assert(v,message)end
local function rejects(fn,message)local ok=pcall(fn);check(not ok,message)end
local clock,paused=1000,false
getTimestampMs=function()return clock end
isGamePaused=function()return paused end
isClient=function()return false end
instanceof=function()return true end
local function event()return {callbacks={},Add=function()end,Remove=function()end}end
Events={}
for _,name in ipairs({'OnPlayerUpdate','OnSave','OnMainMenuEnter','OnWeaponSwing','OnPlayerAttackFinished','OnWeaponHitCharacter'})do
 local e=event();e.Add=function(fn)e.callbacks[#e.callbacks+1]=fn end;Events[name]=e
end
local function fire(name,...)for _,fn in ipairs(Events[name].callbacks)do fn(...)end end
local mouse,keys={},{}
isMouseButtonDown=function(i)return mouse[i]==true end
isKeyDown=function(i)return keys[i]==true end
getKeyName=function(i)return tostring(i)end
Keyboard={}
getCore=function()return {isDoingTextEntry=function()return false end}end
do local _="ProjectYakuzaFixture:REGISTRY" end
do local _="ProjectYakuzaFixture:COMBO" end
do local _="ProjectYakuzaFixture:BINDINGS" end
ProjectYakuza.NetworkCatalog={}
do local _="ProjectYakuzaFixture:NETWORK_EXTENSIONS" end
local PY=ProjectYakuza
local kind='test.focus'
local d=PY.registerActionKind(kind)
check(d.blocksAttacks and PY.registerActionKind(kind)==d,'custom kinds default to exclusive attack policy and register idempotently')
rejects(function()PY.registerActionKind(kind,{blocksAttacks=false})end,'conflicting kind policy rejected')
rejects(function()PY.registerActionKind('bad kind')end,'invalid kind rejected')
rejects(function()PY.registerActionKind('taunt',{blocksAttacks=false})end,'built-in controller policy cannot be replaced')
rejects(function()PY.registerActionKind('test.bad',{unknown=true})end,'unknown policies rejected')
local style={id='test.style',name='Test',lightAttacks={{animation='NativePunch',nodeValue='test_light',duration=1}},actions={
 [kind]={enabled=true,animation='Test_Focus',duration=1},['test.open']={enabled=false}},heat=false}
PY.registerActionKind('test.open',{blocksAttacks=false})
PY.registerStyle(style)
rejects(function()PY.registerStyleActionHandler(style.id,kind,{start=function()return true end,update=true})end,'malformed update callback rejected')
local bad={id='bad',name='Bad',lightAttacks=style.lightAttacks,actions={taunt={enabled=true,animation='a',heatStocks=-1}}}
check(not PY.validateStyle(bad),'negative action costs rejected')
bad.actions.taunt.heatStocks=1;bad.actions.taunt.afterLight=5
check(not PY.validateStyle(bad),'invalid combo branch rejected')
local p={data={ProjectYakuzaStyle=style.id},vars={},attempts=0,allowed=true,hit=''}
local weapon={getFullType=function()return PY.TOKEN end,getMaxHitCount=function()return 3 end,getWeaponSprite=function()return 'ProjectYakuza_EmptyHand' end}
function p:getModData()return self.data end
function p:isLocalPlayer()return true end
function p:isDead()return false end
function p:isAiming()return true end
function p:getPlayerNum()return 0 end
function p:getPrimaryHandItem()return weapon end
function p:setVariable(k,v)self.vars[k]=v end
function p:GetVariable(k)return self.vars[k]end
function p:getHitReaction()return self.hit end
function p:isAuthorizeMeleeAction()return self.allowed end
function p:setAuthorizeMeleeAction(v)self.allowed=v end
function p:AttemptAttack()self.attempts=self.attempts+1;return true end
PY.Heat={endSwing=function()end}
do local _="ProjectYakuzaFixture:RUNTIME" end
local starts,updates,cancels=0,0,0
local handler={canStart=function()return true end,start=function(c)starts=starts+1;c.flag=true;return true end,
 update=function(c)updates=updates+1 end,cancel=function(c,reason)cancels=cancels+1;c.flag=false;c.reason=reason end}
PY.registerStyleActionHandler(style.id,kind,handler)
local inputCalls=0
PY.registerStyleInputHandler(style.id,function()inputCalls=inputCalls+1;return false end)
check(PY.requestAction(p,kind),'custom action starts through validated style slot')
local context=PY.activeActions[p]
check(PY.isCustomAction(p) and PY.blocksNativeAttacks(p),'active custom ownership is visible to native gate')
check(not p.allowed,'accepted custom action gates native attacks immediately, before the next update')
PY.Bindings.update(p);check(not p.allowed and not PY.attemptAttack(p) and p.attempts==0,'native and framework attack entry both blocked')
mouse[0]=true
fire('OnPlayerUpdate',p)
check(updates==1 and inputCalls==1 and p.attempts==0,'actual Runtime updates custom action and input handler without ordinary attacks')
fire('OnWeaponSwing',p,weapon)
check(PY.stateFor(p).step==0,'custom native swing is not misclassified as a combo light')
check(not PY.requestAction(p,kind),'custom action prevents concurrent action')
check(not PY.completeAction(p,{}),'stale async completion cannot clear current action')
check(not PY.cancelAction(p,'stale',{}),'stale async cancellation cannot clear current action')
p.hit='Bite';fire('OnPlayerUpdate',p);p.hit=''
check(not PY.activeActions[p] and cancels==1 and context.reason=='hit_reaction','real Runtime interrupts custom action on hit reaction')
PY.Bindings.update(p);check(p.allowed,'native permission restored after cancellation')
mouse[0]=false;check(PY.requestAction(p,kind),'custom action can restart')
paused=true;fire('OnPlayerUpdate',p);paused=false
check(updates==1,'paused custom action does not tick')
local old=PY.activeActions[p]
PY.registerStyleActionHandler(style.id,kind,{start=function()return true end,update=function()error('expected test error')end,cancel=function()error('wrong captured handler')end})
check(PY.cancelAction(p,'captured',old) and cancels==2,'cancellation uses captured handler')
PY.registerStyleActionHandler(style.id,kind,{start=function()return true end,update=function()error('expected test error')end,cancel=handler.cancel})
check(PY.requestAction(p,kind),'error-case handler starts');fire('OnPlayerUpdate',p)
check(not PY.activeActions[p] and cancels==3,'update exceptions cancel ownership and call cleanup')
PY.registerStyleActionHandler(style.id,kind,handler)
check(PY.requestAction(p,kind),'world-exit handler starts');fire('OnSave')
check(not PY.activeActions[p] and cancels==4,'world exit cancels custom action')
PY.registerStyleInputHandler(style.id,function(who)
 if not PY.isBusy(who) then PY.requestAction(who,kind) end
 return false
end)
fire('OnPlayerUpdate',p)
check(PY.isCustomAction(p) and p.attempts==0,'new ownership consumes core input even when its input handler returns false')
PY.cancelAction(p,'routing_test_done')
style.actions['test.open']={enabled=true,animation='Test_Open'}
PY.registerStyleActionHandler(style.id,'test.open',handler)
check(PY.requestAction(p,'test.open') and not PY.blocksNativeAttacks(p),'advanced native attack owner can explicitly opt out of gate')
PY.cancelAction(p,'done')
local B=PY.Bindings
local bind=B.register({id='test.extra',name='Test extra',mode=4,code=0})
check(not B.down('test.extra') and B.byId['test.extra']~=nil,'unbound addon binding is inert')
rejects(function()B.register(bind)end,'binding IDs cannot replace another binding')
rejects(function()B.register({id='test.invalid',name='x',mode=5})end,'invalid binding rejected')
local options={added={}}
function options:addTitle()end
function options:addDescription()end
function options:addComboBox(id,name)self.added[id]=name;return {addItem=function()end}end
function options:addKeyBind(id,name,key)self.added[id]=key end
function options:getOption()return nil end
B.configure(options)
check(options.added['input_test.extra']=='Test extra','addon binding uses its own readable label')
B.register({id='test.late',name='Late extra',mode=4,code=123})
check(options.added['key_test.late']==123,'late binding appears in existing settings')
keys[123]=true;check(B.pressed(p,'test.late') and not B.pressed(p,'test.late'),'addon binding rising edges are scoped per player')
local function entry(id,priority)return {id=id,animation='NativePunch',group='actions',priority=priority,loop=false,conditions={{name='PerformingAction',value=id}}}end
local entries={entry('Test_One',100),entry('Test_Two',200)}
check(PY.registerNetworkAnimations(style.id,entries)==2,'network batch registers')
check(PY.NetworkCatalog[style.id][1].id=='Test_Two','catalog priority is sorted')
entries[1].conditions[1].value='mutated'
check(PY.NetworkCatalog[style.id][2].conditions[1].value=='Test_One','caller metadata is copied')
rejects(function()PY.registerNetworkAnimations(style.id,{entry('Test_Three',300),entry('Test_One',100)})end,'duplicate network registration fails')
check(#PY.NetworkCatalog[style.id]==2,'failed network batch publishes nothing')
local invalid=entry('Test_Bad',1);invalid.group='unknown'
rejects(function()PY.registerNetworkAnimations(style.id,{invalid})end,'invalid network group rejected')
local other={id='test.other',name='Other',lightAttacks=style.lightAttacks};PY.registerStyle(other)
rejects(function()PY.registerNetworkAnimations(other.id,{entry('Test_One',1)})end,'clip IDs must be unique across styles')
check(PY.API_VERSION==3,'framework API 3 advertised')
return 'PASS '..checks..' addon API, actual Runtime routing, lifecycle, keybind and network registration checks'
