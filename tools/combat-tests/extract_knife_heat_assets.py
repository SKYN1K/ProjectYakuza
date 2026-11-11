from pathlib import Path
import sys,json
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from y5_source_assets import unpack,entry
archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/hact/h23680_buki_b.par');out=root/'extracted/knife-heat-098/h23680_buki_b';index=unpack(archive,out);(out/'index.json').write_text(json.dumps(index,indent=2)+'\n')
models=[]
for name in ['bs_b000_type_b_knife.gmd','bs_b001_type_b_dosu.gmd']:
 data,record=entry(archive.parent.parent/'asset.par',name);dest=out.parent/name;dest.write_bytes(data);models.append(record)
(out.parent/'weapon-models.json').write_text(json.dumps(models,indent=2)+'\n');print('PASS supplied Y6 knife scene and two original model references extracted')
