from pathlib import Path
import hashlib,json
from PIL import Image,ImageFont,ImageDraw
root=Path(__file__).resolve().parents[2]
mod=root/'combat/ProjectYakuza'
d=json.loads((mod/'docs/encounter-intro-assets.json').read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
f=d['font'];assert sha(Path(f['source']))==f['sourceSha256']
assert sha(mod/f['output'])==f['sha256'] and sha(mod/f['metrics'])==f['metricsSha256']
atlas=Image.open(mod/f['output']);assert atlas.mode=='RGBA' and list(atlas.size)==f['size']
assert hashlib.sha256(atlas.tobytes()).hexdigest()==f['rgbaSha256']
font=ImageFont.truetype(f['source'],f['pixelSize']);ascent,descent=font.getmetrics();assert ascent+descent==f['lineHeight']
expected=Image.new('RGBA',atlas.size,(255,255,255,0));draw=ImageDraw.Draw(expected)
for code in range(32,127):
 g=f['glyphs'][str(code)];left,top,right,bottom=font.getbbox(chr(code),anchor='ls')
 assert g['offsetX']==left and g['offsetY']==top+ascent and g['width']==right-left and g['height']==bottom-top
 assert g['advance']==font.getlength(chr(code))
 assert 0<=g['x']<=g['x']+g['width']<=atlas.width and 0<=g['y']<=g['y']+g['height']<=atlas.height
 draw.text((g['x']-left,g['y']-top),chr(code),font=font,fill=(255,255,255,255),anchor='ls')
assert expected.tobytes()==atlas.tobytes()
for title in ['A bunch of brain eaters','Zombies','The Horde']:assert all(str(ord(c)) in f['glyphs'] for c in title)
r=d['flare'];assert sha(Path(r['source']))==r['sourceSha256'] and sha(mod/r['output'])==r['sha256']
source=Image.open(r['source']).convert('RGBA');copy=Image.open(mod/r['output'])
assert list(copy.size)==r['size']==list(source.size) and copy.tobytes()==source.tobytes()
assert hashlib.sha256(copy.tobytes()).hexdigest()==r['rgbaSha256']
assert source.getchannel('A').getextrema()==(0,255)
print('PASS 95 supplied Edo SZ glyphs/metrics and exact direct font rasterization; original Y6 flare RGBA, alpha, dimensions and provenance hashes')
