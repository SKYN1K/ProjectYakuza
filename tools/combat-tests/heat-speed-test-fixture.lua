local function near(a,b)return math.abs(a-b)<.000001 end
local S=PY.HeatSpeed;local H=PY.Heat;local baseStyle=PY.getStyle('dragon_of_dojima')
check(baseStyle.heatAttackSpeed==nil,'DoD does not opt into heat speed')
for _,profile in pairs(PY.Weapons.views.dragon_of_dojima)do check(profile.heatAttackSpeed==nil,'current weapon profiles also remain opted out')end
for _,cfg in ipairs({{max=.9},{max=2.1},{max=0/0},{max=1.5,power=0},{max=1.5,power=5},{max=1.5,useExtremeFuel=1},{max=1.5,typo=true}})do check(not S.valid(cfg),'invalid speed curve rejected')end
local style={};for k,v in pairs(baseStyle)do style[k]=v end
style.id='test_heat_speed';style.name='Test heat-speed authoring';style.attackSpeed=2;style.heatAttackSpeed={max=1.5}
check(PY.registerStyle(style)==style,'independent style can register an optional speed curve')
for heat=0,100 do check(near(S.factor(style,heat,0,false),1+.5*heat/100),'linear bounded heat curve '..heat)end
check(S.factor(style,-1,0,false)==1 and S.factor(style,500,0,false)==1.5,'heat endpoints clamp')
check(S.factor(style,0/0,0,false)==1,'nonfinite heat is safe')
check(S.factor(baseStyle,100,100,false)==1 and S.factor(baseStyle,100,100,true)==1,'DoD always retains its previous heat multiplier')
check(S.factor(style,100,75,true)==1,'Extreme Heat fuel opt-in defaults off')
style.heatAttackSpeed={max=1.5,power=2,useExtremeFuel=true}
check(near(S.factor(style,50,0,false),1.125)and near(S.factor(style,0,50,true),1.125),'curve exponent and Extreme fuel supported')
check(not S.allowed(style,1.6,false)and not S.allowed(style,0/0,false)and not S.allowed(baseStyle,1.2,false),'network factors cannot exceed configuration or opt in another style')
style.heatAttackSpeed={max=1.5}
token.min=.35;token.max=.65;token.data={}
function token:getMinDamage()return self.min end;function token:getMaxDamage()return self.max end
function token:setMinDamage(v)self.min=v end;function token:setMaxDamage(v)self.max=v end
function token:getModData()return self.data end
function token:setZombieHitSound(v)self.hitSound=v end
local function finish()p.attacking=false;fire('OnPlayerAttackFinished',p,token);clock=clock+40 end
local function reset(id)p.attacking=false;p.held=nil;PY.resetPlayer(p,'test');H.stop(p,'test');p.data.ProjectYakuzaStyle=id;PY.Weapons.sync(p);clock=clock+100 end
reset('dragon_of_dojima');PY.setHeat(p,100);p:AttemptAttack();check(near(p.vars.ProjectYakuzaCombatSpeed,1.6),'DoD full stored Heat does not change normal speed');finish()
PY.setHeat(p,100);check(H.start(p),'DoD Extreme Heat starts');p:AttemptAttack();check(near(p.vars.ProjectYakuzaCombatSpeed,1.92)and H.attackHeatMultiplier(p)==1,'DoD retains its exact existing Extreme bonus');finish();H.stop(p,'test')
reset(style.id);PY.setHeat(p,50);p:AttemptAttack()
check(near(H.attackHeatMultiplier(p),1.25)and near(p.vars.ProjectYakuzaCombatSpeed,2.5),'new native swing samples Heat and scales combat speed')
check(near(p.vars.ProjectYakuzaChargedHeavySpeed,1.25)and near(p.vars.ProjectYakuzaRunningKneeSpeed,1.5),'charged release and running-knee variables share the captured multiplier')
PY.setHeat(p,100);H.playback(p,false);check(near(p.vars.ProjectYakuzaCombatSpeed,2.5),'mid-swing Heat gains do not change speed')
finish();check(H.attackHeatMultiplier(p)==1,'swing completion releases captured speed')
p:AttemptAttack();check(near(p.vars.ProjectYakuzaCombatSpeed,3),'next swing samples new Heat');finish()
PY.Weapons.register(style.id,{id='fixture_bat',items={'Base.HeatSpeedFixtureBat'},attackSpeed=1.4,lightAttacks=PY.Weapons.views.dragon_of_dojima.bat.lightAttacks,actions=PY.Weapons.views.dragon_of_dojima.bat.actions,heatAttackSpeed=false})
check(PY.Weapons.views[style.id].fixture_bat.heatAttackSpeed==false,'weapon profiles can explicitly opt out without mutating base')
p.held=weapon('Base.HeatSpeedFixtureBat');PY.Weapons.sync(p);PY.setHeat(p,100);H.onSwing(p,PY.Weapons.views[style.id].fixture_bat.lightAttacks[1]);check(near(p.vars.ProjectYakuzaCombatSpeed,1.4),'opted-out weapon retains its authored native speed')
local invalid={};for k,v in pairs(style)do invalid[k]=v end;invalid.heatAttackSpeed={max=3};check(not PY.validateStyle(invalid),'registration validates the optional curve')
do
 reset(baseStyle.id);PY.setHeat(p,0);local combo={active=true};local first,second,third={},{},{}
 H.onHit(p,first,.4,combo);check(near(PY.getHeat(p),.5),'first eligible victim retains full Heat gain')
 H.onHit(p,first,.4,combo);check(near(PY.getHeat(p),.5),'duplicate primary collision grants no additional Heat')
 H.onHit(p,second,.4,combo);H.onHit(p,third,.4,combo);check(near(PY.getHeat(p),.75),'two secondary victims each grant one quarter Heat')
 H.onHit(p,second,2,combo);check(near(PY.getHeat(p),.75),'secondary collision replay cannot gain twice')
 combo={active=true};H.onHit(p,first,.4,combo);check(near(PY.getHeat(p),1.25),'new swing restores full primary gain')
 for _,profile in pairs(PY.Weapons.views[baseStyle.id])do check(PY.HeatRules.forStyle(profile).secondaryTargetGain==.25,'DoD weapon profiles inherit crowd gain reduction')end
 check(not PY.HeatRules.valid({secondaryTargetGain=-.01})and not PY.HeatRules.valid({secondaryTargetGain=1.01})and PY.HeatRules.valid({secondaryTargetGain=0}),'secondary-target factor is bounded and can be explicitly disabled')
end
reset(style.id);style.heatAttackSpeed={max=1.5,useExtremeFuel=true};PY.extremeViews[style]=nil;PY.setHeat(p,100);H.start(p);H.onSwing(p,style.lightAttacks[1])
check(near(H.attackHeatMultiplier(p),1.5)and near(p.vars.ProjectYakuzaCombatSpeed,3.6),'Extreme fuel sampled before its attack cost, multiplying the existing mode boost once')
H.states[p].fuel=25;H.playback(p,true);check(near(p.vars.ProjectYakuzaCombatSpeed,3.6),'fuel drain cannot accelerate/decelerate the current swing')
H.endSwing(p);H.onSwing(p,style.lightAttacks[1]);check(near(H.attackHeatMultiplier(p),1.125),'next Extreme attack samples remaining fuel')
PY.emit('styleChanged',p);check(H.attackHeatMultiplier(p)==1,'style changes clear captured speed')
do
 local C=PY.HeatRules
 check(baseStyle.heatConfig.secondaryTargetGain==.25 and H.rules(p).maxStocks==6,'DoD limits secondary-target Heat while retaining stock capacity')
 for _,bad in ipairs({{maxStocks=0},{maxStocks=33},{maxStocks=1.5},{gainPerDamage=-1},{gainPerDamage=math.huge},{idleGraceMs=-1},{idleLossPerSecond=0/0},{secondsPerStock=0},{attackFuelCost=-1},{retainStocks=1},{typo=1}})do check(not C.valid(bad),'invalid capacity/gain/drain rules rejected')end
 local own={};for k,v in pairs(baseStyle)do own[k]=v end;own.id='test_heat_rules';own.name='Heat rules test'
 own.heatConfig={maxStocks=3,gainPerDamage=10,lossPerDamage=2,idleGraceMs=0,idleLossPerSecond=10,secondsPerStock=5,attackFuelCost=7,retainStocks=false}
 check(PY.registerStyle(own)==own,'future styles can register their own Heat rules')
 reset(own.id);PY.setHeat(p,20)
 check(near(H.stockSize(p),100/3)and H.stocks(p)==0,'custom stock size uses normalized Heat')
 H.onHit(p,{},3,{active=true});check(near(PY.getHeat(p),40)and H.stocks(p)==1,'custom confirmed-hit gain retains damage cap and stock thresholds')
 H.lose(p,10);check(near(PY.getHeat(p),30),'optional continuous drain can consume completed stocks')
 H.onDamage(p,'BITE',2);check(near(PY.getHeat(p),26),'style owns damage-related heat loss')
 H.states[p].lastUpdate=clock;H.states[p].lastAction=clock-1000;clock=clock+100;H.update(p)
 check(near(PY.getHeat(p),25),'style owns idle grace and passive drain')
 PY.setHeat(p,100);check(H.start(p),'custom Heat mode starts with a full gauge')
 H.onSwing(p,own.lightAttacks[1]);check(near(H.states[p].fuel,93),'style owns per-attack Extreme fuel cost')
 H.onHit(p,{},2,{active=true});check(near(H.states[p].fuel,93)and PY.getHeat(p)==0,'custom gain remains disabled during Extreme Heat')
 H.states[p].lastUpdate=clock;clock=clock+100;H.update(p)
 check(near(H.states[p].fuel,93-(100/3)/5*.1),'custom seconds-per-stock sets timed fuel drain')
 H.stop(p,'test');own.heatConfig.retainStocks=true;own.heatConfig.gainPerDamage=12;PY.registerStyle(own)
 PY.setHeat(p,60);H.lose(p,50);check(near(PY.getHeat(p),100/3),'retained-stock mode remains configurable')
 check(H.rules(p).gainPerDamage==12,'official same-table registration refreshes merged rules')
 local view=PY.Weapons.register(own.id,{id='rules_bat',items={'Base.HeatRulesTestBat'},lightAttacks=PY.Weapons.views.dragon_of_dojima.bat.lightAttacks,actions={},heatConfig={maxStocks=8}})
 check(C.forStyle(view).maxStocks==8 and C.forStyle(view).gainPerDamage==12,'weapon Heat overrides inherit the owning style gain')
 check(H.config.maxStocks==6 and H.config.gainPerDamage==1.25 and C.forStyle(baseStyle).secondaryTargetGain==.25 and H.config.secondaryTargetGain==1,'custom rules never mutate DoD/global defaults')
 reset(style.id)
end
reset(style.id);style.heatAttackSpeed={max=1.5};PY.setHeat(p,50);H.onSwing(p,style.lightAttacks[1]);p.combo=nil
local s=PY.stateFor(p);s.active=true;s.multiHitToken={};s.startedAt=clock
Events.OnGameStart=event();p.playSound=function()return 0 end;p.getEmitter=function()return {}end
H.isExtreme=function()return false end
do local _="ProjectYakuzaFixture:FEEDBACK" end
local move={animation='test_clip',duration=2,speed=2,impact=.4};PY.Feedback.swing(p,style,1,move)
check(near(PY.Feedback.pending[p].due-clock,((2/1.25)*.4-.07)*1000),'fallback whoosh scheduling follows the captured attack speed')
p.dbgGetAnimTrackName=function()return 'test_clip'end;PY.AttackEffects={};PY.Feedback.swing(p,style,1,move)
check(near(PY.Feedback.pending[p].sourceTime,.4*4-.07*2*1.25),'native-phase whoosh lead also accounts for the captured curve')
return true,'PASS '..checks..' heat-speed authoring, curve bounds, interpolation, native swing capture, Extreme fuel, fixed DoD behavior, weapon override and feedback timing checks'
