require "ProjectYakuza/Runtime"
local ProjectYakuza=ProjectYakuza
local M={pending=setmetatable({}, {__mode="k"}),swings=setmetatable({}, {__mode="k"})}
ProjectYakuza.MultiHit=M
local function unhook()
    local pending=false;for _ in pairs(M.pending) do pending=true;break end
    if not pending and M.ticking then Events.OnTick.Remove(M.tick);M.ticking=false end
end
function M.clearPath(p,o,dx,dy)
    if not ProjectYakuza.Quicksteps then return false end
    local length=math.sqrt(dx*dx+dy*dy);local travelled=0
    while travelled<length-.000001 do
        local step=math.min(.08,length-travelled)
        if not ProjectYakuza.Quicksteps.canMove(p,dx/length*step,dy/length*step,o.x+dx/length*travelled,o.y+dy/length*travelled) then return false end
        travelled=travelled+step
    end
    return true
end
function M.targets(p,o,ground,seen,limit)
    local result={};local cell=getCell()
    local x,y,z=math.floor(o.x),math.floor(o.y),math.floor(o.z)
    local visited={}
    for ox=-2,2 do for oy=-2,2 do
        local sq=cell:getGridSquare(x+ox,y+oy,z)
        local objects=sq and sq:getMovingObjects()
        if objects then for i=0,objects:size()-1 do
            local v=objects:get(i)
            if not visited[v] then
                visited[v]=true
                if instanceof(v,"IsoZombie") and not seen[v] and not v:isDead()
                    and math.floor(v:getZ())==z and ((v:isOnFloor() or v:isKnockedDown())==ground) then
                    local dx,dy=v:getX()-o.x,v:getY()-o.y
                    local d=dx*dx+dy*dy
                    if d>.0001 and d<=o.range*o.range and (dx*o.fx+dy*o.fy)/math.sqrt(d)>=.5
                        and p:CanSee(v) and M.clearPath(p,o,dx,dy) then result[#result+1]={victim=v,distance=d} end
                end
            end
        end end
    end end
    table.sort(result,function(a,b)return a.distance<b.distance end)
    while #result>limit do table.remove(result) end
    return result
end
function M.origin(p,range)
    local f=p:getForwardDirection();local x,y=f:getX(),f:getY()
    local n=math.sqrt(x*x+y*y);if n<.001 then return nil end
    return {x=p:getX(),y=p:getY(),z=p:getZ(),fx=x/n,fy=y/n,range=range or 1.25}
end
function M.onHit(p,v,weapon,damage)
    if M.processing or not p or not instanceof(p,"IsoPlayer") or not p:isLocalPlayer() or not ProjectYakuza.isEquipped(p)
        or not v or not instanceof(v,"IsoZombie") or type(damage)~="number" or damage<=0 then return end
    local s=ProjectYakuza.stateFor(p)
    if not s.active or not weapon or (not (ProjectYakuza.isStyleToken(weapon) or (ProjectYakuza.Weapons and ProjectYakuza.Weapons.matches(p,weapon)))
        and not (s.groundMove and weapon:getFullType()=="Base.BareHands")) then return end
    local job=M.swings[p]
    if not job or job.stamp~=(s.multiHitToken or s.startedAt) then
        local origin=M.origin(p,1.25);if not origin then return end
        job={stamp=(s.multiHitToken or s.startedAt),origin=origin,ground=s.groundMove~=nil,weapon=weapon,damage=damage,seen={},count=0}
        M.swings[p]=job
    end
    if job.seen[v] then return end
    job.seen[v]=true;job.count=job.count+1
    M.pending[p]=job
    if not M.ticking then Events.OnTick.Add(M.tick);M.ticking=true end
end
function M.tick()
    if isGamePaused() then return end
    local jobs=M.pending;M.pending=setmetatable({}, {__mode="k"})
    unhook()
    for p,job in pairs(jobs) do
        local s=ProjectYakuza.stateFor(p)
        if not p:isDead() and ProjectYakuza.isEquipped(p) and s.active and (s.multiHitToken or s.startedAt)==job.stamp then
            local count=math.max(0,ProjectYakuza.MAX_HIT_COUNT-job.count)
            if count>0 then
                -- Native collision finishes reporting victims before this supplement runs.
                local targets=M.targets(p,job.origin,job.ground,job.seen,count)
                M.processing=true
                for _,entry in ipairs(targets) do
                    local v=entry.victim
                    if not v:isDead() then
                        job.seen[v]=true;job.count=job.count+1
                        -- Native Hit supplies damage, armor, death and normal hit events.
                        local ok,err
                        if isClient() and ProjectYakuza.Network then ok=ProjectYakuza.Network.extra(p,v)
                        else ok,err=pcall(v.Hit,v,job.weapon,p,job.damage,false,1) end
                        if not ok then print("[ProjectYakuza] multi-hit failed: "..tostring(err)) end
                    end
                end
                M.processing=false
            end
        end
    end
end
function M.clear()
    M.pending=setmetatable({}, {__mode="k"});M.swings=setmetatable({}, {__mode="k"});M.processing=false;unhook()
end
Events.OnWeaponHitCharacter.Add(M.onHit)
Events.OnSave.Add(M.clear)
Events.OnMainMenuEnter.Add(M.clear)
