from pathlib import Path
import hashlib,json,sys
from PIL import Image

root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';source=root/'extracted/lau-spear-weapon/o_ayam_spr_rhau_d.dds';image=Image.open(source).convert('RGBA');small=image.resize((128,128),Image.Resampling.NEAREST);output=mod/'42/media/textures/ProjectYakuza_LauSpear.png';validate='--validate'in sys.argv
if validate:assert Image.open(output).convert('RGBA').tobytes()==small.tobytes()
else:small.save(output)
report={'source':str(source),'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'originalSize':list(image.size),'output':output.relative_to(mod).as_posix(),'size':list(small.size),'filter':'Pillow NEAREST; supplied source texels and alpha only, no painting, synthesis or upscaling','rgbaSha256':hashlib.sha256(small.tobytes()).hexdigest(),'sha256':hashlib.sha256(output.read_bytes()).hexdigest()};manifest=mod/'docs/lau-spear-weapon-texture.json'
if validate:assert json.loads(manifest.read_text())==report
else:manifest.write_text(json.dumps(report,indent=2)+'\n')
print('PASS supplied 512x512 Lau spear diffuse, direct 128x128 source texels and alpha, output pixels/hash verified')
