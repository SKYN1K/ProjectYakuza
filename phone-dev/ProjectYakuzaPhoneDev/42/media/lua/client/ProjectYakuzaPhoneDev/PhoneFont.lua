local D=ProjectYakuza.PhoneDev
local F={}
D.Font=F
function F.font(bold)return bold and UIFont.SdfBold or UIFont.SdfRegular end
function F.measure(text,size,bold)
    local manager=getTextManager();local font=F.font(bold);local height=math.max(1,manager:getFontHeight(font))
    return manager:MeasureStringX(font,tostring(text or ""))*size/height
end
function F.layout(text,size,maxWidth,bold)
    text=tostring(text or "");local manager=getTextManager();local font=F.font(bold)
    local width=manager:MeasureStringX(font,text);local scale=size/math.max(1,manager:getFontHeight(font))
    if maxWidth and width*scale>maxWidth then scale=math.max(0,maxWidth)/math.max(1,width)end
    return {text=text,font=font,width=width*scale,scale=scale,height=manager:getFontHeight(font)*scale}
end
function F.flat(panel,text,x,y,r,g,b,a,size,align,maxWidth,bold)
    maxWidth=maxWidth or(align=="right"and x-12 or align=="center"and math.min(x-8,panel.width-x-8)*2 or panel.width-x-8)
    local key=tostring(size)..":"..tostring(maxWidth)..":"..tostring(bold)..":"..tostring(text)
    panel.fontLayouts=panel.fontLayouts or {};local layout=panel.fontLayouts[key]
    if not layout then
        if(panel.fontLayoutCount or 0)>=128 then panel.fontLayouts={};panel.fontLayoutCount=0 end
        layout=F.layout(text,size,math.max(1,maxWidth),bold);panel.fontLayouts[key]=layout;panel.fontLayoutCount=(panel.fontLayoutCount or 0)+1
    end
    local left=align=="right"and x-layout.width or align=="center"and x-layout.width/2 or x
    getTextManager():DrawString(layout.font,panel:getAbsoluteX()+left,panel:getAbsoluteY()+y,layout.scale,layout.text,r,g,b,a)
    return layout.height
end
function F.wrap(text,size,width,bold)
    local lines={};local line=""
    local function push()lines[#lines+1]=line;line=""end
    local function append(word)
        local candidate=line==""and word or line.." "..word
        if line~=""and F.measure(candidate,size,bold)>width then push();candidate=word end
        if F.measure(candidate,size,bold)<=width then line=candidate;return end
        for char in word:gmatch("[%z\1-\127\194-\244][\128-\191]*")do
            if line~=""and F.measure(line..char,size,bold)>width then push()end
            line=line..char
        end
    end
    text=tostring(text or ""):gsub("\r","")
    for paragraph in(text.."\n"):gmatch("(.-)\n")do
        for word in paragraph:gmatch("%S+")do append(word)end
        if line~=""then push()elseif paragraph==""then lines[#lines+1]=""end
    end
    return lines
end
function F.projected(panel,q,text,x,y,a,size,width)
    local px,py=D.Math.point(q,x/320,y/568)
    local scaleX=math.sqrt((q[2][1]-q[1][1])^2+(q[2][2]-q[1][2])^2)/320
    local scaleY=math.sqrt((q[4][1]-q[1][1])^2+(q[4][2]-q[1][2])^2)/568
    F.flat(panel,text,px,py,.96,.96,.96,a,size*math.min(scaleX,scaleY),"center",(width or 96)*scaleX)
end
