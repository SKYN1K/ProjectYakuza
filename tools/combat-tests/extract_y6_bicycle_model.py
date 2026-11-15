from pathlib import Path
import json
from y5_source_assets import entry
root=Path(__file__).resolve().parents[2];out=root/'extracted/bicycle-model-y6-0112';out.mkdir(parents=True,exist_ok=True);records=[]
for name in ['bik2020_bicycle_b.gmd','r_oj_bicy_b00_tt_d.dds']:
    data,record=entry('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/asset.par',name);(out/name).write_bytes(data);records.append(record)
(out/'index.json').write_text(json.dumps(records,indent=2)+'\n');print('PASS original Y6 bicycle B and its original diffuse extracted from asset.par')
