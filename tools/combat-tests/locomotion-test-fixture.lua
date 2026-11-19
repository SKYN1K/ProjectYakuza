require=function()end
local hooks={};Events={OnPlayerUpdate={Add=function(fn)hooks[#hooks+1]=fn end},OnTick={Add=function()end}}
isClient=function()return false end
MoodleType={ENDURANCE=1,TIRED=2}
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
instanceof=function(p,name)return p.player and name=="IsoPlayer"end
ProjectYakuza={getPlayerStyle=function(p)return p.style end,isEquipped=function(p)return p.equipped end}
do local _="ProjectYakuzaFixture:LOCOMOTION" end
local L=ProjectYakuza.Locomotion
for _,localPlayer in ipairs({true,false})do
 local p={player=true,localPlayer=localPlayer,style={id="dragon_of_dojima"},equipped=true,levels={0,0},writes=0}
 function p:isDead()return self.dead end
 function p:isLocalPlayer()return self.localPlayer end
 function p:GetVariable()return self.speed end
 function p:getMoodles()return {getMoodleLevel=function(_,kind)return self.levels[kind]end}end
 function p:setVariable(name,value)check(name=="ProjectYakuzaRestedRun","only the isolated run selector gate is changed");self.value=value;self.writes=self.writes+1 end
 L.update(p);check(p.value==true,"rested owner and observer use the custom stride")
 local writes=p.writes;for n=1,100 do L.update(p)end;check(p.writes==writes,"stable state does not rewrite native animation variables")
 if localPlayer then for kind=1,2 do for level=1,4 do p.levels[kind]=level;L.update(p);check(p.value==false,"each tiredness and exertion level uses native movement blending")end;p.levels[kind]=0;L.update(p);check(p.value==true,"recovering restores source running without touching movement rates")end
 else
  p.speed="0.4";L.update(p);check(p.value==false,"slow replicated movement uses the native observer blend")
  p.speed="0.8";L.update(p);check(p.value==true,"replicated recovery restores observer stride")
  local reads=0;getTimestampMs=function()return 1000 end;isClient=function()return true end
  getOnlinePlayers=function()reads=reads+1;return {size=function()return 1 end,get=function()return p end}end
  L.tick();L.tick();check(reads==1,"remote players poll at most four times per second")
  isClient=function()return false end
 end
 p.style.weaponProfile="bat";L.update(p);check(p.value==false,"armed movement keeps its existing selectors");p.style.weaponProfile=nil
 p.dead=true;L.update(p);check(p.value==false,"death cannot enable the source run");p.dead=false
 p.equipped=false;L.update(p);check(p.value==false,"unequipped styles retain native movement")
end
return "PASS "..checks.." rested/exhausted run gate, recovery, observer and cached write checks"
