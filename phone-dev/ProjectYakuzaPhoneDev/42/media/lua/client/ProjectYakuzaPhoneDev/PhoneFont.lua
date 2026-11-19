require "ProjectYakuzaPhoneDev/PhoneGlyphs"
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
function F.codes(text)
    local result={}
    for char in tostring(text or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*")do
        local first=char:byte();local code=first
        if #char>1 then code=first%(2^(7-#char));for i=2,#char do code=code*64+char:byte(i)%64 end end
        result[#result+1]=code
    end
    return result
end
function F.handsetLayout(text,size,width)
    local source=D.Glyphs;local cursor=0;local previous;local glyphs={}
    for _,code in ipairs(F.codes(text))do
        local glyph=source.chars[code]or source.chars[63]
        if glyph then
            if previous then cursor=cursor+(source.kern[previous*65536+code]or 0)end
            glyphs[#glyphs+1]={code=code,glyph=glyph,x=cursor+glyph[5],y=glyph[6]}
            cursor=cursor+glyph[7];previous=code
        end
    end
    local scale=math.min(size/source.height,(width or 96)/math.max(1,cursor))
    return {glyphs=glyphs,scale=scale,width=cursor*scale}
end
function F.glyphTexture(code,glyph)
    F.glyphTextures=F.glyphTextures or {};local texture=F.glyphTextures[code]
    if texture then return texture end
    F.atlas=F.atlas or getTexture(D.Glyphs.path)
    if not F.atlas or F.atlas.isReady and not F.atlas:isReady()then return end
    texture=F.atlas:split("ProjectYakuzaPhoneGlyph"..code,glyph[1],glyph[2],glyph[3],glyph[4]);F.glyphTextures[code]=texture
    return texture
end
function F.projected(panel,q,text,x,y,a,size,width)
    panel.handsetLayouts=panel.handsetLayouts or {};local key=tostring(text)..":"..size..":"..tostring(width)
    local layout=panel.handsetLayouts[key]
    if not layout then
        if(panel.handsetLayoutCount or 0)>=64 then panel.handsetLayouts={};panel.handsetLayoutCount=0 end
        layout=F.handsetLayout(text,size,width);panel.handsetLayouts[key]=layout;panel.handsetLayoutCount=(panel.handsetLayoutCount or 0)+1
    end
    local ax,ay=(q[2][1]-q[1][1])/320,(q[2][2]-q[1][2])/320
    local bx,by=(q[4][1]-q[1][1])/568,(q[4][2]-q[1][2])/568
    for _,row in ipairs(layout.glyphs)do
        local glyph=row.glyph;local texture=F.glyphTexture(row.code,glyph)
        if texture and(not texture.isReady or texture:isReady())then
            local left,top=x-layout.width/2+row.x*layout.scale,y+row.y*layout.scale
            local w,h=glyph[3]*layout.scale,glyph[4]*layout.scale
            local x1,y1=q[1][1]+ax*left+bx*top,q[1][2]+ay*left+by*top
            local x2,y2=x1+ax*w,y1+ay*w;local x4,y4=x1+bx*h,y1+by*h
            panel:drawTextureAllPoint(texture,x1,y1,x2,y2,x2+bx*h,y2+by*h,x4,y4,.96,.96,.96,a)
        end
    end
end
