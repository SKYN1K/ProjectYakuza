from pathlib import Path
import hashlib,json,re,sys
ROOT=Path(__file__).resolve().parents[2]
GAME=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid')
SOURCE=GAME/'media/fonts/EN/2x/zomboidSmall.fnt'
MOD=ROOT/'phone-dev/ProjectYakuzaPhoneDev'
rows={}
for line in SOURCE.read_text().splitlines():
 if line.startswith('char id='):
  row={k:int(v)for k,v in re.findall(r'(\w+)=\s*(-?\d+)',line)}
  rows[row['id']]=[row[k]for k in ['x','y','width','height','xoffset','yoffset','xadvance']]
assert len(rows)==1136
data='local D=ProjectYakuza.PhoneDev\nlocal F={path="media/fonts/EN/2x/zomboidSmall_0.png",lineHeight=26,glyphs={},metrics={\n'+''.join('['+str(k)+']={'+','.join(map(str,v))+'},\n'for k,v in sorted(rows.items()))+'}}\nD.Font=F\n'
body='''function F.layout(text,size,maxWidth)
    text=tostring(text or "");local glyphs={};local width=0
    for i=1,math.min(#text,64)do
        local code=string.byte(text,i);local m=F.metrics[code]or F.metrics[63]
        glyphs[#glyphs+1]={code=F.metrics[code]and code or 63,x=width+m[5],y=m[6],w=m[3],h=m[4]};width=width+m[7]
    end
    local scale=math.min(size/F.lineHeight,(maxWidth or 300)/math.max(1,width))
    return {glyphs=glyphs,width=width*scale,scale=scale}
end
function F.texture(code)
    if F.glyphs[code]then return F.glyphs[code]end
    F.atlas=F.atlas or getTexture(F.path)
    if not F.atlas or not F.atlas:isReady()then return end
    local m=F.metrics[code]
    if not m or m[3]<=0 or m[4]<=0 then return end
    local tex=F.atlas:split("ProjectYakuzaPhoneDevGlyph"..code,m[1],m[2],m[3],m[4]);F.glyphs[code]=tex;return tex
end
function F.draw(drawQuad,panel,q,layout,cx,y,alpha)
    local scale=layout.scale;local left=cx-layout.width/2
    for _,g in ipairs(layout.glyphs)do
        if g.code~=32 then local tex=F.texture(g.code);if tex then drawQuad(panel,q,tex,left+g.x*scale,y+g.y*scale,g.w*scale,g.h*scale,.96,.96,.96,alpha)end end
    end
end
'''
output=MOD/'42/media/lua/client/ProjectYakuzaPhoneDev/PhoneFont.lua'
if '--validate'in sys.argv:assert output.read_text()==data+body
else:output.write_text(data+body,newline='\n')
record={'source':'Project Zomboid/media/fonts/EN/2x/zomboidSmall.fnt','sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'glyphs':len(rows),'atlas':'media/fonts/EN/2x/zomboidSmall_0.png','atlasSha256':hashlib.sha256((GAME/'media/fonts/EN/2x/zomboidSmall_0.png').read_bytes()).hexdigest(),'operation':'Original installed font metrics embedded as Lua data; original game atlas sampled at runtime. No font image, pixels or artwork created or modified.'}
p=MOD/'docs/font-source.json'
if '--validate'in sys.argv:assert json.loads(p.read_text())==record
else:p.write_text(json.dumps(record,indent=2)+'\n')
print('PASS 1136 original font glyph metrics and unchanged native font atlas; no generated artwork')
