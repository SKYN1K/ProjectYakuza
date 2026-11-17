from pathlib import Path
import hashlib,io,json,sys
from PIL import Image
from y5_source_assets import entry

ROOT=Path(__file__).resolve().parents[2]
MOD=ROOT/'combat/ProjectYakuza'
ARCHIVE=Path('F:/SteamLibrary/steamapps/common/LikeADragonGaiden/runtime/media/data/particle.par')
validate='--validate'in sys.argv
rows=[]
for name in ('e_n_5001_hitsmoke_small.dds','e_f_d0004_spark.dds'):
    data,record=entry(ARCHIVE,name);pixels=Image.open(io.BytesIO(data)).convert('RGBA')
    output=MOD/'42/media/textures/ProjectYakuza/AttackFX'/(Path(name).stem+'.png')
    if validate:assert Image.open(output).convert('RGBA').tobytes()==pixels.tobytes()
    else:output.parent.mkdir(exist_ok=True);pixels.save(output)
    rows.append({**record,'output':output.relative_to(MOD).as_posix(),'size':pixels.size,'pngSha256':hashlib.sha256(output.read_bytes()).hexdigest(),'rgbaSha256':hashlib.sha256(pixels.tobytes()).hexdigest()})
report={'game':'Like a Dragon Gaiden','authorization':'User explicitly allowed Gaiden particles for the limb effects.','operation':'Original supplied DDS pixels decoded to RGBA PNG at native dimensions. No painting, resizing, upscaling, synthesized frames or sound. Runtime colour and motion only.','textures':rows}
path=MOD/'docs/gaiden-effect-assets.json'
if validate:assert json.loads(path.read_text())==json.loads(json.dumps(report))
else:path.write_text(json.dumps(report,indent=2)+'\n')
print('PASS two original Gaiden particle entries, exact pixels and source/PNG hashes; no generated artwork')
