require "ProjectYakuza/Registry"
require "ProjectYakuza/WorldEffects"
local PY=ProjectYakuza
local B={bursts={},sprites={},maxPerPlayer=4,maxTotal=16,frames=16,life=400}
PY.BloodEffects=B
local function release(b)
    if b.instance then b.instance:Dispose();IsoSpriteInstance.add(b.instance);b.instance=nil end
end
local function idle()
    if #B.bursts==0 and B.hooked then
        Events.OnTick.Remove(B.update);Events.OnPostRender.Remove(B.render);B.hooked=false
    end
end
function B.clear(player)
    for i=#B.bursts,1,-1 do
        if not player or B.bursts[i].player==player then release(B.bursts[i]);table.remove(B.bursts,i) end
    end
    idle()
end
local function selectFrame(b,frame)
    if b.frame==frame then return end
    release(b)
    local sprite=B.sprites[frame]
    if not sprite then
        sprite=IsoSprite.CreateSprite(nil)
        sprite:LoadFramesNoDirPageSimple("media/textures/ProjectYakuza/Blood_splash_"..frame..".png")
        B.sprites[frame]=sprite
    end
    b.instance=PY.WorldEffects.detached(sprite,b.scale,0);b.frame=frame
end
function B.spawn(player,victim,strong,charged,feedback,anchor)
    local style=PY.getPlayerStyle(player)
    if not style or style.bloodEffects~="yakuza6" or not victim or player:getModData().ProjectYakuzaHitEffectsDisabled then return end
    local count=0
    for _,b in ipairs(B.bursts) do if b.player==player then count=count+1 end end
    if count>=B.maxPerPlayer or #B.bursts>=B.maxTotal then
        for i,b in ipairs(B.bursts) do
            if count<B.maxPerPlayer or b.player==player then release(b);table.remove(B.bursts,i);break end
        end
    end
    local tile=Core.getTileScale()
    local family=feedback;if family==nil then family=style.impactFeedback end
    local scale=family=="blade"and 1.15 or family=="blunt"and .85 or 1
    local b={player=player,victim=victim,age=0,last=getTimestampMs(),life=family=="blade"and 360 or B.life,scale=.18*tile*(charged and 1.35 or strong and 1.2 or 1)*scale,height=((victim:isOnFloor()or victim.GetVariable and victim:GetVariable("ProjectYakuzaPairedVictimClip")=="ProjectYakuza_DD_GroundHeatVictim")and 5 or 26)*tile}
    if anchor then b.anchor={x=anchor.x,y=anchor.y,z=anchor.z}end
    selectFrame(b,0);B.bursts[#B.bursts+1]=b
    if not B.hooked then Events.OnTick.Add(B.update);Events.OnPostRender.Add(B.render);B.hooked=true end
end
function B.update()
    local now=getTimestampMs();local paused=isGamePaused()
    for i=#B.bursts,1,-1 do
        local b=B.bursts[i];local delta=math.max(0,now-b.last);b.last=now
        if not paused then b.age=b.age+delta end
        local style=PY.getPlayerStyle(b.player)
        if b.age>=b.life or b.player:isDead() or not PY.isEquipped(b.player) or not style or style.bloodEffects~="yakuza6"
            or b.player:getModData().ProjectYakuzaHitEffectsDisabled then
            release(b);table.remove(B.bursts,i)
        else selectFrame(b,math.min(B.frames-1,math.floor(b.age*B.frames/b.life))) end
    end
    idle()
end
function B.draw()
    B.update()
    if not B.color then B.color=ColorInfo.new(1,1,1,1) end
    for _,b in ipairs(B.bursts) do
        local alpha=.85*math.min(1,(b.life-b.age)/100)
        b.instance:SetAlpha(alpha);b.instance:SetTargetAlpha(alpha)
        if b.anchor then b.instance:render(b.victim,b.anchor.x,b.anchor.y,b.anchor.z,IsoDirections.N,0,-128*b.scale/2,B.color)
        else PY.WorldEffects.renderCentered(b.victim,b.instance,128,b.scale,0,-b.height,B.color)end
    end
end
function B.render()
    local renderer=SpriteRenderer.instance;local previous=renderer:getDoAdditive();renderer:setDoAdditive(false)
    local ok,err=pcall(B.draw);renderer:setDoAdditive(previous)
    if not ok then B.clear();error(err) end
end
Events.OnGameStart.Add(function()B.clear()end)
Events.OnMainMenuEnter.Add(function()B.clear()end)
Events.OnSave.Add(function()B.clear()end)
