require "ProjectYakuza/Registry"
local PY=ProjectYakuza
local F={sounds={prompt="ProjectYakuza_QTEAppear",success="ProjectYakuza_QTEPress",miss="ProjectYakuza_QTEFail",failure="ProjectYakuza_QTEFail"}};PY.QTEFeedback=F
function F.play(context,kind,scale)
    local p=type(context)=="table"and context.player
    local config=type(context)=="table"and context.action and context.action.qte and context.action.qte.feedback
    if not p or not p:isLocalPlayer()or p:isDead()then return end
    if config and config[kind]and PY.Feedback then PY.Feedback.play(p,PY.Feedback.sound(p,config[kind]),(config.gain or .4)*(scale or 1))
    elseif F.sounds[kind]and getSoundManager then getSoundManager():playUISound(F.sounds[kind])end
end
PY.on("qtePrompt",function(context)F.play(context,"prompt")end)
PY.on("qteTap",function(context,index,prompt,count,required)if count<required then F.play(context,"success",.35)end end)
PY.on("qteInput",function(context)F.play(context,"success")end)
PY.on("qteResult",function(context,index,success,prompt,state)
    if success then return end
    local config=state.definition;local count=config.failureMode=="total"and state.failures or state.consecutiveFailures
    if not config.failureLimit or count<config.failureLimit then F.play(context,"miss")end
end)
PY.on("qteFailed",function(context)F.play(context,"failure")end)
