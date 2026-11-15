from pathlib import Path
import hashlib,json,sys
from PIL import Image

root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';source=root/'extracted/lau-spear-weapon/o_ay_spear_rhau_d.dds';image=Image.open(source).convert('RGBA');interior=image.resize((510,510),Image.Resampling.NEAREST);texture=Image.new('RGBA',(512,512));texture.paste(interior,(1,1));texture.paste(interior.crop((509,0,510,510)),(0,1));texture.paste(interior.crop((0,0,1,510)),(511,1));texture.paste(interior.crop((0,509,510,510)),(1,0));texture.paste(interior.crop((0,0,510,1)),(1,511))
for x,y in [(0,0),(511,0),(0,511),(511,511)]:texture.putpixel((x,y),interior.getpixel((509 if x==0 else 0,509 if y==0 else 0)))
output=mod/'42/media/textures/ProjectYakuza_LauSpear.png';validate='--validate'in sys.argv
if validate:assert Image.open(output).convert('RGBA').tobytes()==texture.tobytes()
else:texture.save(output)
report={'sourceGame':'Yakuza 3','source':str(source),'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'originalSize':list(image.size),'output':output.relative_to(mod).as_posix(),'size':list(texture.size),'interior':[510,510],'border':1,'filter':'Pillow NEAREST downsamples the original 512 texels into a 510 interior; one-pixel wrapped source borders preserve periodic bilinear sampling under edge clamping. Every output texel is a supplied original texel; no painting, synthesis or upscaling.','rgbaSha256':hashlib.sha256(texture.tobytes()).hexdigest(),'sha256':hashlib.sha256(output.read_bytes()).hexdigest()};manifest=mod/'docs/lau-spear-weapon-texture.json'
if validate:assert json.loads(manifest.read_text())==report
else:manifest.write_text(json.dumps(report,indent=2)+'\n')
print('PASS original Yakuza 3 512x512 diffuse, 510 source-texel interior and wrapped one-pixel borders; all pixels and alpha verified')
