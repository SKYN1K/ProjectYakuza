require "ProjectYakuza/Registry"
local PY=ProjectYakuza
local E={paid=setmetatable({}, {__mode="k"}),defaults={light=.003,directional=.004,quickstepAttack=.006,ground=.008,running=.009,dropkick=.012,heavy=.012,finisher=.015,double=.0175,charged=.02,counter=.02,heatAction=.025}}
PY.Exertion=E
local function finite(v)return type(v)=="number"and v==v and v<math.huge and v>-math.huge end
function E.category(p,move,kind)
    if kind=="parry"then return "counter"end
    if kind=="heatAction"then return "heatAction"end
    if move.chargedHeavy then return "charged"end
    if move.double then return "double"end
    if move.runningAttack then return move.variant=="dropkick"and "dropkick"or "running"end
    if move.quickstepAttack then return "quickstepAttack"end
    if move.groundAttack or p:isAimAtFloor()or p:isPerformingStompAnimation()then return "ground"end
    if move.neutralHeavy then return "heavy"end
    if move.afterLight then return "finisher"end
    if move.directional then return "directional"end
    return "light"
end
function E.cost(p,style,move,kind)
    if not style or type(style.exertion)~="table"or type(move)~="table"then return end
    local category=E.category(p,move,kind)
    local amount=move.enduranceCost
    if amount==nil then amount=style.exertion[category]end
    if amount==nil then amount=E.defaults[category]end
    if not finite(amount)or amount<0 or amount>.1 then return end
    return amount,category
end
function E.commit(p,style,move,stamp,kind)
    if not p or not p:isLocalPlayer()or p:isDead()or p:isUnlimitedEndurance()or type(stamp)~="table"then return false end
    local amount,category=E.cost(p,style,move,kind);if not amount or amount==0 then return false end
    local seen=E.paid[p];if seen and seen[stamp]then return false end
    local fitness=p:getFatigueMod();local traits=p:getCharacterTraits():getTraitEnduranceLossModifier()
    if not finite(fitness)or not finite(traits)or fitness<0 or traits<0 then return false end
    local stats=p:getStats();local available=stats:get(CharacterStat.ENDURANCE)
    if not finite(available)or available<0 then return false end
    local cost=math.min(.5,available,amount*fitness*traits)
    if not seen then seen=setmetatable({}, {__mode="k"});E.paid[p]=seen end
    seen[stamp]=true;if cost<=0 then return false end;stats:remove(CharacterStat.ENDURANCE,cost)
    PY.emit("attackEnduranceSpent",p,style,move,category,cost)
    return true,cost
end
PY.on("attackCommitted",E.commit)
function E.clear()E.paid=setmetatable({}, {__mode="k"})end
Events.OnSave.Add(E.clear)
Events.OnMainMenuEnter.Add(E.clear)
