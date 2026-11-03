require "ProjectYakuza/Bindings"
local PY=ProjectYakuza
local I={cache={},textures={},paths={key="media/textures/ProjectYakuza/InputKeycap.png",left="media/textures/ProjectYakuza/InputMouseLeft.png",right="media/textures/ProjectYakuza/InputMouseRight.png",middle="media/textures/ProjectYakuza/InputMouseMiddle.png"}}
PY.InputPrompts=I
function I.describe(binding)
    local B=PY.Bindings
    if not B.byId[binding]then return end
    local mode=B.mode(binding);local key=mode==4 and B.key(binding)or 0;local current=I.cache[binding]
    if current and current.mode==mode and current.key==key then return current end
    if type(mode)~="number"or mode<1 or mode>4 then return end
    current={binding=binding,mode=mode,key=key,label=B.label(binding),kind=mode==4 and"key"or({"left","right","middle"})[mode],bound=mode~=4 or key>0};I.cache[binding]=current;return current
end
function I.texture(kind)
    if I.textures[kind]==nil then I.textures[kind]=getTexture and getTexture(I.paths[kind])or false end
    return I.textures[kind]
end
function I.draw(panel,binding,x,y,size,alpha)
    local input=I.describe(binding)
    if not input or alpha<=0 then return input end
    local texture=I.texture(input.kind);alpha=alpha*(input.bound and 1 or .5)
    if input.kind~="key"and texture then panel:drawSubTexture(texture,0,0,84,84,x-size*.5,y-size*.5,size,size,alpha,1,1,1);return input end
    local manager=getTextManager and getTextManager();local font=UIFont.Medium or UIFont.Large or UIFont.Small;local label=input.label or"";local maxWidth=size*2.4
    local textWidth=manager and manager:MeasureStringX(font,label)or #label*8
    if textWidth>maxWidth-16 and UIFont.Small then font=UIFont.Small;textWidth=manager and manager:MeasureStringX(font,label)or #label*6 end
    local width=math.max(size,math.min(maxWidth,textWidth+16));local height=manager and manager:getFontHeight(font)or 20
    if texture then
        local border=size*8/84;local dx={x-width*.5,x-width*.5+border,x+width*.5-border};local dy={y-size*.5,y-size*.5+border,y+size*.5-border};local dw={border,width-2*border,border};local dh={border,size-2*border,border};local sx={0,8,76};local sy={0,8,76};local sw={8,68,8};local sh={8,68,8}
        for row=1,3 do for col=1,3 do
            local a,b,w,h=sx[col],sy[row],sw[col],sh[row]
            if row==2 and col==2 then a,b,w,h=12,12,8,8 end
            panel:drawSubTexture(texture,a,b,w,h,dx[col],dy[row],dw[col],dh[row],alpha,1,1,1)
        end end
    end
    panel:drawTextCentre(label,x,y-height*.5,1,1,1,alpha,font)
    return input
end
function I.clear()I.cache={};I.textures={}end
if Events and Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(I.clear)end
