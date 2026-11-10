require "ProjectYakuza/HeatSceneData"
local S={};ProjectYakuza.HeatScenes=S
function S.sounds(sounds)
    for key,value in pairs(ProjectYakuza.HeatSceneData.sounds)do sounds[key]=value end
    return sounds
end
function S.action(id,action)
    local data=assert(ProjectYakuza.HeatSceneData.moves[id],"Heat scene is not registered")
    for _,field in ipairs({"contacts","audioEvents","voiceEvents"})do action[field]=data[field]end
    if data.ending then
        for key,value in pairs(data.ending)do action.qteFailure[key]=value end
    end
    return action
end
