require=function()end
local checks=0;local function check(value,message)checks=checks+1;assert(value,message)end
local function event()return {Add=function()end,Remove=function()end}end
Events={OnSave=event(),OnMainMenuEnter=event()};ProjectYakuza={}
do local _="ProjectYakuzaFixture:HEAT_ACTIONS" end
local H=ProjectYakuza.HeatActions;local p,item={},{}
local function victim(health,kind)
 local z={health=health,kind=kind,clip='paired',consequences=0}
 function z:isDead()return self.health<=0 end;function z:getHealth()return self.health end
 function z:setHealth(v)self.health=v end;function z:setAttackedBy(v)self.attacker=v end
 function z:isInvulnerable()return self.god==true end
 function z:hitConsequences(weapon,attacker,skip,amount,remote)
  check(weapon==item and attacker==p and skip and amount==0 and remote==false,'native death consequences use supplied weapon without applying damage twice')
  self.consequences=self.consequences+1
 end
 function z:Hit()error('native Hit must never interrupt the paired animation')end
 return z
end
for _,kind in ipairs({'zombie','player'})do
  for _,health in ipairs({.1,.5,.75,1.5,10})do
   local job={};local z=victim(health,kind);local dealt,held=0,0
   for i=1,3 do
    local before=z.health;check(H.strike(job,p,z,item,.5,i),'configured contact accepted '..kind)
    if held>0 or .5>=before then held=held+.5;check(z.health==before,'lethal contact preserves health until completion')
    else dealt=dealt+.5;check(z.health==health-dealt,'nonlethal contact damages immediately')end
    check(not H.strike(job,p,z,item,.5,i),'duplicate contact cannot deal or reserve more damage')
    check(not z:isDead()and z.clip=='paired'and z.consequences==0,'paired clip remains alive and uninterrupted')
   end
   check(math.abs((job.pendingDamage or 0)-held)<.000001,'reserved damage is the sum of withheld contacts')
   H.settle(job,p,z,item,true);check(math.abs(z.health-math.max(0,health-1.5))<.000001,'full completion preserves total configured damage')
   check(z.consequences==(health<=1.5 and 1 or 0),'death finalized only for a lethal completed sequence')
   local after=z.health;H.settle(job,p,z,item,true);check(z.health==after,'completion is idempotent')
   check(not H.strike(job,p,z,item,.5,4),'ended sequence cannot accept another hit')
  end
end
local job={};local z=victim(.75,'zombie');H.strike(job,p,z,item,.5,1);H.strike(job,p,z,item,.5,2);H.settle(job,p,z,item,false)
check(z.health==.25 and z.consequences==0 and not job.pendingDamage,'interruption retains nonlethal damage and discards withheld lethal damage')
job={};z=victim(.1,'player');z.god=true;H.strike(job,p,z,item,5,1);H.settle(job,p,z,item,true);check(z.health==.1,'pre-existing protection is respected')
job={};z=victim(10,'zombie');check(not H.strike(job,p,z,item,0/0,1)and not H.strike(job,p,z,item,-1,1)and not H.strike(job,p,z,item,.5,nil),'invalid contact damage and identity rejected')
check(H.strike(job,p,z,item,0,1)and z.health==10 and not job.pendingDamage,'presentation-only contact never invents damage')
local client,server=false,false
isClient=function()return client end;isServer=function()return server end
check(H.useGhostProtection(),'single player retains native ghost protection')
client=true;check(not H.useGhostProtection(),'multiplayer client never enables ghost visibility hiding')
client=false;server=true;check(not H.useGhostProtection(),'authoritative server never enables ghost visibility hiding')
server=false
return true,'PASS '..checks..' shared Heat Action nonlethal hits, lethal deferral, native terminal consequences, zombie/player, cancellation, protection and replay checks'
