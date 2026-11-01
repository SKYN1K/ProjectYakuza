require "ProjectYakuza/Registry"
require "ProjectYakuza/HeatRushPaths"
local R={duration=130/30,targetRange=2}
ProjectYakuza.HeatRushRules=R
function R.sample(path,time)
    local f=math.max(0,math.min(#path-1,time*30));local i=math.floor(f)+1;local a=path[i];local b=path[math.min(i+1,#path)];local t=f-math.floor(f)
    return a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t
end
function R.point(job,path,time)
    local forward,right=R.sample(path,time)
    return job.x+job.fx*forward+job.fy*right,job.y+job.fy*forward-job.fx*right
end
function R.validTarget(p,z,range)
    if not z or not instanceof(z,"IsoZombie")or z:isDead()or z:isOnFloor()or z:isKnockedDown()or z:isUseless()or z:isAttacking()or math.abs(z:getZ()-p:getZ())>.25 then return false end
    local dx,dy=z:getX()-p:getX(),z:getY()-p:getY();local n=math.sqrt(dx*dx+dy*dy);local f=p:getForwardDirection()
    return n>.01 and n<=(range or R.targetRange)and (dx*f:getX()+dy*f:getY())/n>=.5
end
function R.space(p,job)
    local P=ProjectYakuza.NetworkProtocol;local paths=ProjectYakuza.HeatRushPaths
    for _,path in ipairs({paths.actor,paths.victim})do
        for i=1,#path,8 do local x,y=R.point(job,path,(i-1)/30);if not P.path(p,x,y)then return false end end
        local x,y=R.point(job,path,R.duration);if not P.path(p,x,y)then return false end
    end
    return true
end
function R.amount(action,index)
    local prompt=action.qte and action.qte.prompts[index];if not prompt then return end
    if not R.base then R.base=instanceItem(ProjectYakuza.TOKEN)end
    if not R.base then return end
    return math.max(0,math.min(2,(R.base:getMinDamage()+R.base:getMaxDamage())*.5))*(prompt.damageMultiplier or 1)*1.5
end
