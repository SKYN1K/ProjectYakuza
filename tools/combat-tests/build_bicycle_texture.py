from pathlib import Path
import json,hashlib,sys
from PIL import Image

root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';source=root/'extracted/bicycle-heat-097/models/s_bsom_bicycle_blue_d.dds';image=Image.open(source).convert('RGBA');small=image.resize((128,128),Image.Resampling.NEAREST);output=mod/'42/media/textures/ProjectYakuza_Bicycle.png';validate='--validate'in sys.argv
if validate:assert Image.open(output).convert('RGBA').tobytes()==small.tobytes()
else:small.save(output)
report={'source':str(source),'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'originalSize':list(image.size),'output':output.relative_to(mod).as_posix(),'size':list(small.size),'filter':'Pillow NEAREST; original supplied texels only, no synthesized painting or upscaling','rgbaSha256':hashlib.sha256(small.tobytes()).hexdigest(),'sha256':hashlib.sha256(output.read_bytes()).hexdigest()}
path=mod/'docs/bicycle-texture.json'
if validate:assert json.loads(path.read_text())==report
else:path.write_text(json.dumps(report,indent=2)+'\n')
print('PASS original',image.size,'bicycle diffuse reduced to',small.size,'with source texels and alpha preserved')
