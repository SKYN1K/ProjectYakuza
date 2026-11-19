from pathlib import Path
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[2];MOD=ROOT/'phone-dev/ProjectYakuzaPhoneDev';GAME=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid')
records=[]
for name in ['sdfRegular.fnt','sdfBold.fnt']:
 p=GAME/'media/fonts'/name;records.append({'font':name,'header':p.read_text(encoding='utf-8').splitlines()[0],'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
source=MOD/'42/media/lua/client/ProjectYakuzaPhoneDev/PhoneFont.lua';text=source.read_text()
assert 'getTextManager():DrawString('in text and 'getTextManager()'in text and ':MeasureStringX('in text
assert 'drawTexture'not in text
record={'renderer':'Native PZ TextManager scaled DrawString, MeasureStringX and getFontHeight','body':'UIFont.SdfRegular / Open Sans','heading':'UIFont.SdfBold / Open Sans Bold','sourceFonts':records,'runtimeSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'operation':'Native text and native shaping/metrics. No custom glyph images, glyph slicing or font replacement in other menus. The original Y6 install supplies bitmap game font data rather than a compatible TTF/OTF; native proportional Open Sans is used as a supported approximation.'}
p=MOD/'docs/font-source.json'
if '--validate'in sys.argv:assert json.loads(p.read_text())==record
else:p.write_text(json.dumps(record,indent=2)+'\n',newline='\n')
print('PASS native proportional Open Sans text, native measurements and source font hashes; no custom glyph images')
