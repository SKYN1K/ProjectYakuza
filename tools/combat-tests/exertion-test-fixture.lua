CharacterStat={ENDURANCE='endurance'}
local endurance,removed,fitness,trait=1,0,1,1
local remote,dead,unlimited,floor=false,false,false,false
function p:isLocalPlayer()return not remote end;function p:isDead()return dead end
function p:isUnlimitedEndurance()return unlimited end
function p:getFatigueMod()return fitness end
function p:getCharacterTraits()return {getTraitEnduranceLossModifier=function()return trait end}end
function p:getStats()return {get=function()return endurance end,remove=function(_,stat,amount)check(stat==CharacterStat.ENDURANCE,'only physical endurance is drained');endurance=math.max(0,endurance-amount);removed=removed+amount end}end
function p:isAimAtFloor()return floor end;function p:isPerformingStompAnimation()return floor end
token.min=.35;token.max=.65;token.data={}
function token:getMinDamage()return self.min end;function token:getMaxDamage()return self.max end
function token:setMinDamage(v)self.min=v end;function token:setMaxDamage(v)self.max=v end
function token:getModData()return self.data end
do local _="ProjectYakuzaFixture:EXERTION" end
local E=PY.Exertion;local style=PY.getStyle('dragon_of_dojima');local s=PY.stateFor(p)
local function near(a,b)return math.abs(a-b)<.000001 end
local cases={{'light',{}},{'directional',{directional=true}},{'quickstepAttack',{quickstepAttack=true}},{'ground',{groundAttack=true}},{'running',{runningAttack=true,variant='left'}},{'dropkick',{runningAttack=true,variant='dropkick'}},{'heavy',{neutralHeavy=true}},{'finisher',{afterLight=1}},{'double',{double=true,afterLight=1}},{'charged',{chargedHeavy=true}},{'counter',{},'parry'},{'heatAction',{},'heatAction'}}
check(E.defaults.light<E.defaults.heavy and E.defaults.heavy<E.defaults.finisher and E.defaults.finisher<E.defaults.charged,'light/heavy/finisher/charge cost ordering')
for _,entry in ipairs(cases)do
 local key,move,kind=entry[1],entry[2],entry[3];local stamp={};local before=removed
 local ok,cost=E.commit(p,style,move,stamp,kind)
 check(ok and near(cost,E.defaults[key])and near(removed-before,cost),'one graded drain for '..key)
 check(not E.commit(p,style,move,stamp,kind)and near(removed-before,cost),'same '..key..' contact/target cannot charge twice')
end
local before=removed;fitness=.75;trait=1.3;local ok,cost=E.commit(p,style,{},{});check(ok and near(cost,.003*.75*1.3),'native fitness and endurance-loss trait modifiers apply once');fitness=1;trait=1
before=removed;remote=true;check(not E.commit(p,style,{},{}),'remote MP observer cannot drain endurance');remote=false;dead=true;check(not E.commit(p,style,{},{}),'dead actor cannot drain endurance');dead=false;unlimited=true;check(not E.commit(p,style,{},{}),'unlimited-endurance cheat respected');unlimited=false
check(near(removed,before),'ineligible events leave stats unchanged')
local other={id='other'};check(not E.commit(p,other,{},{}),'other styles require explicit exertion opt-in')
local overrides={id='addon',exertion={light=.005}};ok,cost=E.commit(p,overrides,{},{});check(ok and near(cost,.005),'style cost override')
ok,cost=E.commit(p,overrides,{enduranceCost=.007},{});check(ok and near(cost,.007),'per-move cost override')
check(not E.commit(p,overrides,{enduranceCost=0},{}),'move override can disable additional drain')
check(not E.commit(p,overrides,{enduranceCost=-1},{})and not E.commit(p,overrides,{enduranceCost=0/0},{}),'invalid custom costs rejected')
fitness=0/0;check(not E.commit(p,style,{},{}),'nonfinite native multiplier rejected');fitness=1
endurance=.001;local lastSpent;PY.on('attackEnduranceSpent',function(_,_,_,_,amount)lastSpent=amount end);E.commit(p,style,{afterLight=1},{});check(endurance==0 and near(lastSpent,.001),'reported drain is bounded by available endurance');local saved=removed;check(not E.commit(p,style,{},{} )and removed==saved,'empty endurance cannot become negative or emit a new spent event');endurance=1
local function reset()p.attacking=false;p.reject=false;p.held=nil;floor=false;PY.resetPlayer(p,'test');PY.Heat.stop(p,'test');PY.Weapons.sync(p);removed=0;endurance=1;clock=clock+100 end
reset();p:AttemptAttack();check(near(removed,.003),'actual Runtime committed light drains once before a hit is required')
PY.emit('combatHit',p,{},token,.3,1);PY.emit('combatHit',p,{},token,.3,1);check(near(removed,.003),'miss/hit/multihit feedback does not add repeated drains')
reset();p.reject=true;p:AttemptAttack();check(removed==0,'rejected native attempt costs nothing')
reset();p:AttemptAttack();p.attacking=false;fire('OnPlayerAttackFinished',p,token);removed=0;check(PY.queueFinisher(p),'first finisher queued')
check(removed==0,'queueing a finisher alone costs nothing');fire('OnPlayerUpdate',p)
check(near(removed,.015)and s.finisherMove.afterLight==1,'actual native first finisher drains once on start')
reset();floor=true;p:AttemptAttack();check(near(removed,.008),'automatic native floor swing pays ground cost instead of light plus ground')
PY.syncGroundAttack(p,PY.getPlayerStyle(p),s);check(near(removed,.008),'ground route does not charge the same native swing again')
reset();p.held=weapon('Base.BaseballBat');PY.Weapons.sync(p);p:AttemptAttack()
check(near(removed,.003),'supported weapon gets one additional light cost without replaying native endurance logic')
check(PY.Weapons.views.dragon_of_dojima.bat.exertion==style.exertion,'weapon view inherits configured style exertion')
local valid=PY.validateStyle({id='bad_exertion',name='bad',lightAttacks={{animation='clip'}},exertion={light=-1}});check(not valid,'style registration rejects negative endurance costs')
valid=PY.validateStyle({id='bad_move_cost',name='bad',lightAttacks={{animation='clip',enduranceCost=.2}}});check(not valid,'move registration rejects out-of-bounds endurance override')
E.clear();local any=false;for _ in pairs(E.paid)do any=true end;check(not any,'world cleanup releases stamp tracking')
return true,'PASS '..checks..' graded exhaustion, native modifiers, committed native attacks, ground deduplication, real weapons, custom profiles, MP owner isolation and invalid-attempt checks'
