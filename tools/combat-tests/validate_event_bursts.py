from pathlib import Path
import json,hashlib,zipfile,subprocess
from PIL import Image
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';textures=mod/'42/media/textures/ProjectYakuza';sha=lambda b:hashlib.sha256(b).hexdigest()
manifest=json.loads((mod/'docs/extreme-smoke-assets.json').read_text());source=Image.open(manifest['source']).convert('RGBA');assert sha(Path(manifest['source']).read_bytes())==manifest['source_sha256']
for row in manifest['frames']:
 p=mod/row['output'];image=Image.open(p).convert('RGBA');assert sha(p.read_bytes())==row['sha256']and image.tobytes()==source.crop(row['crop']).tobytes()
flames=json.loads((mod/'docs/extreme-heat-assets.json').read_text());frames=[v for v in flames['frames']if 'flame'in v['output']];assert len(frames)==64
for row in frames:assert sha((textures/row['output']).read_bytes())==row['sha256']
for kind,size in [('flame',32),('smoke',64)]:
 for i in range(64):
  image=Image.open(textures/f'ExtremeHeat_{kind}_{i}.png').convert('RGBA');assert image.size==(size,size)
  alpha=image.getchannel('A');assert alpha.getextrema()[0]==0,'source must contain real alpha transparency'
  assert not all(image.getpixel((x,y))[3]==255 for x,y in [(0,0),(size-1,0),(0,size-1),(size-1,size-1)]),'opaque texture rectangle is not suitable for normal-alpha bursts'
with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.85.0.zip')as z:
 count=0
 for p in textures.rglob('*.png'):
  name='ProjectYakuza/'+p.relative_to(mod).as_posix();assert p.read_bytes()==z.read(name),p;count+=1
text=(mod/'42/media/lua/client/ProjectYakuza/HeatAura.lua').read_text();assert 'StyleFX/'not in text and 'point.speed or'in text
print('PASS all',count,'supplied texture files unchanged; 128 original alpha-bearing fire/smoke frames and smoke source pixels verified; no black-backed streak input')
game=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid');subprocess.run([str(game/'jre64/bin/java.exe'),'-cp','.;'+str(game/'*'),'NativeAuraTextureProbe',str(textures.resolve())],cwd=Path(__file__).parent,check=True)
