from pathlib import Path
import hashlib,json
from PIL import Image
root=Path(__file__).resolve().parents[2]
mod=root/'combat/ProjectYakuza'
d=json.loads((mod/'docs/blood-effects-assets.json').read_text(encoding='utf-8'))
source=Path(d['source'])
assert hashlib.sha256(source.read_bytes()).hexdigest()==d['sourceSha256']
im=Image.open(source).convert('RGBA')
assert im.size==(512,512) and len(d['frames'])==16
for i,r in enumerate(d['frames']):
 p=mod/r['output'];frame=Image.open(p)
 assert r['frame']==i and p.name=='Blood_splash_'+str(i)+'.png'
 assert frame.mode=='RGBA' and frame.size==(128,128)
 assert r['crop']==[(i%4)*128,(i//4)*128,(i%4+1)*128,(i//4+1)*128]
 assert frame.tobytes()==im.crop(r['crop']).tobytes()
 assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256']
 assert hashlib.sha256(frame.tobytes()).hexdigest()==r['rgbaSha256']
 alpha=frame.getchannel('A');assert alpha.getextrema()[0]==0 and alpha.getbbox()
 assert alpha.getextrema()[1]>0
 assert any(a>32 and red>green and red>blue for red,green,blue,a in frame.getdata())
assert len(list((mod/'42/media/textures/ProjectYakuza').glob('Blood_splash_*.png')))==16
print('PASS 16 original Yakuza 6 128x128 RGBA blood cells, exact source pixels/alpha/order, native loader filenames and provenance hashes')
