from pathlib import Path
import json
from y5_source_assets import entry,unpack

root=Path(__file__).resolve().parents[2];game=Path('F:/SteamLibrary/steamapps/common/Yakuza 5/main/data')
out=root/'extracted/bicycle-heat-097/h11010_jitensha';index=unpack(game/'hact/h11010_jitensha.par',out);(out/'index.json').write_text(json.dumps(index,indent=2)+'\n')
models=root/'extracted/bicycle-heat-097/models';models.mkdir(parents=True,exist_ok=True);records=[]
for name in ['wemap0006_bicycle_blue.gmd','wemap0006_bicycle_low.gmd','s_bsom_bicycle_blue_d.dds']:
    data,record=entry(game/'reactorpar/reactor.par',name);(models/name).write_bytes(data);records.append(record)
(models/'index.json').write_text(json.dumps(records,indent=2)+'\n')
bone=root/'extracted/bicycle-heat-097/c_cm_bone.gmd';data,record=entry(game/'chara_common/bone.par',bone.name);bone.write_bytes(data);(bone.parent/'bone-index.json').write_text(json.dumps(record,indent=2)+'\n')
out=root/'extracted/crate-normal-097';out.mkdir(parents=True,exist_ok=True);records=[]
for name in ['P_WPC_CMB_01.gmt','P_WPC_CMB_02.gmt','P_WPC_CMB_03.gmt','P_WPC_ATK_heavy.gmt','P_WPC_guard_lp.gmt']:
    data,record=entry(game/'motion/BattlePlayerKiryu.par',name);(out/name).write_bytes(data);records.append(record)
(out/'index.json').write_text(json.dumps(records,indent=2)+'\n')
print('PASS supplied Y5 bicycle scene, original low/intact models, diffuse, skeleton and five crate attack/guard clips extracted')
