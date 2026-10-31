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
reset(style.id);style.heatAttackSpeed={max=1.5,useExtremeFuel=true};PY.extremeViews[style]=nil;PY.setHeat(p,100);H.start(p);H.onSwing(p,style.lightAttacks[1])
check(near(H.attackHeatMultiplier(p),1.5)and near(p.vars.ProjectYakuzaCombatSpeed,3.6),'Extreme fuel sampled before its attack cost, multiplying the existing mode boost once')
H.states[p].fuel=25;H.playback(p,true);check(near(p.vars.ProjectYakuzaCombatSpeed,3.6),'fuel drain cannot accelerate/decelerate the current swing')
H.endSwing(p);H.onSwing(p,style.lightAttacks[1]);check(near(H.attackHeatMultiplier(p),1.125),'next Extreme attack samples remaining fuel')
PY.emit('styleChanged',p);check(H.attackHeatMultiplier(p)==1,'style changes clear captured speed')
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
