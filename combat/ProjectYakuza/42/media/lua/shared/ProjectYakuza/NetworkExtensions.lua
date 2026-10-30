require "ProjectYakuza/NetworkCatalog"
local PY=ProjectYakuza

function PY.registerNetworkAnimations(styleId,entries)
    assert(type(styleId)=="string" and PY.getStyle(styleId),"register the style before its network animations")
    assert(type(entries)=="table","animation entries must be an array")
    local function text(v)return type(v)=="string" and v~="" end
    local function finite(v)return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
    local result,ids={},{}
    for _,entry in ipairs(PY.NetworkCatalog[styleId] or {}) do result[#result+1]=entry;ids[entry.id]=true end
    local added=0
    for i,entry in ipairs(entries) do
        assert(type(entry)=="table" and text(entry.id) and text(entry.animation),"entry id and animation are required at "..i)
        assert(not ids[entry.id],"duplicate network animation id: "..entry.id)

        for other,catalog in pairs(PY.NetworkCatalog) do
            if other~=styleId then for _,v in ipairs(catalog) do assert(v.id~=entry.id,"network animation id belongs to "..other) end end
        end
        assert(entry.group=="melee" or entry.group=="stomp" or entry.group=="actions","invalid animation group")
        assert(type(entry.loop)=="boolean" and finite(entry.priority),"loop boolean and finite priority required")
        assert(type(entry.conditions)=="table" and #entry.conditions>0,"owner node conditions required")
        local conditions={}
        for _,c in ipairs(entry.conditions) do
            assert(type(c)=="table" and text(c.name) and text(c.value),"condition name/value strings required")
            conditions[#conditions+1]={name=c.name,value=c.value}
        end
        local copy={id=entry.id,animation=entry.animation,group=entry.group,loop=entry.loop,priority=entry.priority,conditions=conditions}
        result[#result+1]=copy;added=added+1;ids[entry.id]=true
    end
    table.sort(result,function(a,b)if a.priority==b.priority then return a.id<b.id end;return a.priority>b.priority end)

    PY.NetworkCatalog[styleId]=result
    return added
end
