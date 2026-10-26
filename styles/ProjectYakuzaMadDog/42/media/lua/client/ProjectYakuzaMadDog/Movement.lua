require "ProjectYakuza/Runtime"
require "ProjectYakuzaMadDog/Style"
local P=ProjectYakuza
local ID="project_yakuza.mad_dog_of_shimano"
local M={locks=setmetatable({}, {__mode="k"})}
P.MadDogMovement=M
-- The four original lights include turns and deep crouches. Keep their legs;
-- own this movement lock so interrupted native attacks cannot strand controls.
function M.restore(player)
    local saved=M.locks[player]
    if saved then player:setBlockMovement(saved.block);M.locks[player]=nil end
end
function M.start(player,style)
    if style.id~=ID then return end
    M.restore(player)
    M.locks[player]={block=player:isBlockMovement()}
    player:setBlockMovement(true)
end
function M.changed(player,id)
    M.restore(player)
    if id==ID then P.groundNext[player:getPlayerNum()]=1 end
end
function M.watch(player)
    if not M.locks[player] then return end
    local style=P.getPlayerStyle(player)
    if not style or style.id~=ID or not P.isEquipped(player) or player:isDead()
        or player:isOnFloor() or player:isKnockedDown() or player:getVehicle()
        or (player:getHitReaction() or "")~="" or not P.stateFor(player).active then
        M.restore(player)
    end
end
function M.clear()
    for player in pairs(M.locks) do M.restore(player) end
end
P.on("lightAttackStarted",M.start)
P.on("lightAttackFinished",M.restore)
P.on("comboCancelled",M.restore)
P.on("styleChanged",M.changed)
Events.OnPlayerUpdate.Add(M.watch)
Events.OnMainMenuEnter.Add(M.clear)
Events.OnSave.Add(M.clear)
Events.OnPlayerDeath.Add(M.restore)
Events.OnCreatePlayer.Add(function(_,player)
    local style=player and P.getPlayerStyle(player)
    if style and style.id==ID then M.changed(player,ID) end
end)
