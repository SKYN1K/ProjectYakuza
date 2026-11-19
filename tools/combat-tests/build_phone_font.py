from pathlib import Path
import hashlib,json,re,sys
ROOT=Path(__file__).resolve().parents[2];MOD=ROOT/'phone-dev/ProjectYakuzaPhoneDev';GAME=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid');validate='--validate'in sys.argv
records=[]
for name in ['sdfRegular.fnt','sdfBold.fnt','EN/2x/zomboidSmall.fnt']:
 p=GAME/'media/fonts'/name;records.append({'font':name,'header':p.read_text(encoding='utf-8').splitlines()[0],'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
source=GAME/'media/fonts/EN/2x/zomboidSmall.fnt';rows=source.read_text(encoding='utf-8').splitlines();glyphs=[];kern=[]
for row in rows:
 fields={k:int(v)for k,v in re.findall(r'(\w+)=(-?\d+)',row)}
 if row.startswith('char '):glyphs.append('['+str(fields['id'])+']={'+','.join(str(fields[k])for k in ['x','y','width','height','xoffset','yoffset','xadvance'])+'}')
 if row.startswith('kerning '):kern.append('['+str(fields['first']*65536+fields['second'])+']='+str(fields['amount']))
code='ProjectYakuza.PhoneDev.Glyphs={height=26,path="media/textures/ProjectYakuzaPhoneDev/PhoneFont.png",chars={'+','.join(glyphs)+'},kern={'+','.join(kern)+'}}\n'
output=MOD/'42/media/lua/client/ProjectYakuzaPhoneDev/PhoneGlyphs.lua';atlas=MOD/'42/media/textures/ProjectYakuzaPhoneDev/PhoneFont.png';raw=(source.parent/'zomboidSmall_0.png').read_bytes()
if validate:assert output.read_text()==code and atlas.read_bytes()==raw
else:output.write_text(code,newline='\n');atlas.write_bytes(raw)
record={'renderer':'Native TextManager Open Sans in flat menus; exact supplied Noto Sans SemiBold BMFont glyph metrics and atlas projected onto handset screen','sourceFonts':records,'glyphs':len(glyphs),'atlasSha256':hashlib.sha256(raw).hexdigest(),'metricsSha256':hashlib.sha256(code.encode()).hexdigest(),'operation':'Unmodified original PZ font atlas and metrics; no rasterized label images, generated glyph artwork or Java helper. Handset layout and subtextures are cached independently of pose.'}
p=MOD/'docs/font-source.json'
if validate:assert json.loads(p.read_text())==record
else:p.write_text(json.dumps(record,indent=2)+'\n',newline='\n')
print('PASS native flat text and',len(glyphs),'original proportional glyph metrics; exact source atlas bytes')
