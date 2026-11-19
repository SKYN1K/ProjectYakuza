from pathlib import Path
import hashlib,json,re,sys,struct,io
from PIL import Image
from phone_source_assets import entry
ROOT=Path(__file__).resolve().parents[2]
GAME=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid')
SOURCE=GAME/'media/fonts/EN/2x/zomboidSmall.fnt'
MOD=ROOT/'phone-dev/ProjectYakuzaPhoneDev'
fallback={}
for line in SOURCE.read_text().splitlines():
 if line.startswith('char id='):
  row={k:int(v)for k,v in re.findall(r'(\w+)=\s*(-?\d+)',line)}
  fallback[row['id']]=[row[k]for k in ['x','y','width','height','xoffset','yoffset','xadvance']]
archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/font.par')
metrics,metricRecord=entry(archive,'e/gothic.bin');dds,textureRecord=entry(archive,'e/gothic.dds')
assert metrics[:4]==b'FONT'and(len(metrics)-48)%32==0
original=Image.open(io.BytesIO(dds));assert original.mode=='L'and original.size==(8192,4096)
coverage=original.crop((0,0,8192,41));rgba=Image.new('RGBA',coverage.size,(255,255,255,255));rgba.putalpha(coverage)
output=MOD/'42/media/textures/ProjectYakuzaPhoneDev/Yakuza6Gothic.png'
if '--validate'in sys.argv:assert Image.open(output).convert('RGBA').tobytes()==rgba.tobytes()
else:rgba.save(output)
atlasSha256=hashlib.sha256(output.read_bytes()).hexdigest()
rows={};sourceRows={}
for off in range(48,len(metrics),32):
 code,face,y0,x0,y1,x1,*bounds=struct.unpack_from('<II4f8B',metrics,off)
 if 32<=code<=126 and face==1:
  cell=(round(x0*original.width),round(y0*original.height),round(x1*original.width),round(y1*original.height));assert 0<=cell[1]<cell[3]<=41
  ink=coverage.crop(cell).getbbox()
  if ink:
   left,top,right,bottom=ink;rows[code]=[cell[0]+left,cell[1]+top,right-left,bottom-top,0,top,right-left+2]
  else:rows[code]=[cell[0],cell[1],1,1,0,0,20]
  sourceRows[code]={'face':face,'uv':[y0,x0,y1,x1],'cell':cell,'bounds':bounds,'metrics':rows[code]}
assert len(rows)==95 and len(fallback)==1136
serialize=lambda mapping:''.join('['+str(k)+']={'+','.join(map(str,v))+'},\n'for k,v in sorted(mapping.items()))
data='local D=ProjectYakuza.PhoneDev\nlocal F={path="media/textures/ProjectYakuzaPhoneDev/Yakuza6Gothic.png",fallbackPath="media/fonts/EN/2x/zomboidSmall_0.png",lineHeight=40,glyphs={},metrics={\n'+serialize(rows)+'},fallback={\n'+serialize(fallback)+'}}\nD.Font=F\n'
body='''function F.layout(text,size,maxWidth)
    text=tostring(text or "");local glyphs={};local width=0
    local i=1
    while i<=#text and #glyphs<64 do
        local code=string.byte(text,i);local count=1
        if code>=240 then code=code-240;count=4 elseif code>=224 then code=code-224;count=3 elseif code>=192 then code=code-192;count=2 end
        for j=1,count-1 do local byte=string.byte(text,i+j);if not byte or byte<128 or byte>191 then code=63;count=1;break end;code=code*64+byte-128 end
        i=i+count
        if not F.metrics[code]and not F.fallback[code]then code=63 end
        local m=F.metrics[code]or F.fallback[code];local unit=F.metrics[code]and 1 or F.lineHeight/26
        glyphs[#glyphs+1]={code=(F.metrics[code]or F.fallback[code])and code or 63,x=width+m[5]*unit,y=m[6]*unit,w=m[3]*unit,h=m[4]*unit};width=width+m[7]*unit
    end
    local scale=math.min(size/F.lineHeight,(maxWidth or 300)/math.max(1,width))
    return {glyphs=glyphs,width=width*scale,scale=scale}
end
function F.texture(code)
    if F.glyphs[code]then local tex=F.glyphs[code];if not tex.isReady or tex:isReady()then return tex end;return end
    local original=F.metrics[code]~=nil;local key=original and "atlas"or"fallbackAtlas"
    F[key]=F[key]or getTexture(original and F.path or F.fallbackPath)
    local atlas=F[key];if not atlas or not atlas:isReady()then return end
    local m=F.metrics[code]or F.fallback[code]
    if not m or m[3]<=0 or m[4]<=0 then return end
    local tex=atlas:split("ProjectYakuzaPhoneDevGlyph"..code,m[1],m[2],m[3],m[4]);F.glyphs[code]=tex;return tex
end
function F.draw(drawQuad,panel,q,layout,cx,y,alpha)
    local scale=layout.scale;local left=cx-layout.width/2
    for _,g in ipairs(layout.glyphs)do
        if g.code~=32 then local tex=F.texture(g.code);if tex then drawQuad(panel,q,tex,left+g.x*scale,y+g.y*scale,g.w*scale,g.h*scale,.96,.96,.96,alpha)end end
    end
end
function F.flat(panel,text,x,y,r,g,b,a,size,align,maxWidth)
    maxWidth=maxWidth or(align=="right"and x-18 or align=="center"and math.min(x-10,panel.width-x-10)*2 or panel.width-x-10)
    panel.fontLayouts=panel.fontLayouts or {};local key=tostring(size)..":"..tostring(maxWidth)..":"..tostring(text)
    local layout=panel.fontLayouts[key]
    if not layout then
        if(panel.fontLayoutCount or 0)>=128 then panel.fontLayouts={};panel.fontLayoutCount=0 end
        layout=F.layout(text,size,math.max(1,maxWidth));panel.fontLayouts[key]=layout;panel.fontLayoutCount=(panel.fontLayoutCount or 0)+1
    end
    local left=align=="right"and x-layout.width or align=="center"and x-layout.width/2 or x
    for _,glyph in ipairs(layout.glyphs)do if glyph.code~=32 then local tex=F.texture(glyph.code);if tex then panel:drawTextureScaled(tex,left+glyph.x*layout.scale,y+glyph.y*layout.scale,glyph.w*layout.scale,glyph.h*layout.scale,a,r,g,b)end end end
end
'''
output=MOD/'42/media/lua/client/ProjectYakuzaPhoneDev/PhoneFont.lua'
if '--validate'in sys.argv:assert output.read_text()==data+body
else:output.write_text(data+body,newline='\n')
record={'source':'Yakuza 6/font.par/e/gothic','glyphs':len(rows),'originalMetrics':metricRecord,'originalTexture':textureRecord,'crop':[0,0,8192,41],'face':1,'atlas':'42/media/textures/ProjectYakuzaPhoneDev/Yakuza6Gothic.png','atlasSha256':atlasSha256,'glyphRecords':sourceRows,'fallbackGlyphs':len(fallback),'operation':'Original English gothic face 1 Latin coverage strip retained at original dimensions; original BC4 luminance is used directly as alpha with white RGB, matching the coverage role in the font renderer. No glyph painting, resampling or upscaling. Crop coordinates come from original swapped-axis FONT UV records; proportional layout removes cell padding using unchanged coverage bounds. Non-Latin glyphs use the existing PZ font atlas.'}
p=MOD/'docs/font-source.json'
if '--validate'in sys.argv:assert json.loads(p.read_text())==json.loads(json.dumps(record))
else:p.write_text(json.dumps(record,indent=2)+'\n')
print('PASS 95 original Yakuza 6 Latin glyphs, exact BC4 coverage and source hashes, plus 1136 native fallback glyphs; no generated artwork')
