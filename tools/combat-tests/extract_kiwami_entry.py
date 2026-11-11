from pathlib import Path
import json
from y5_source_assets import entry

root=Path(__file__).resolve().parents[2];base=Path('F:/SteamLibrary/steamapps/common/Yakuza Kiwami/media/data');out=root/'extracted/kiwami-entry-099';out.mkdir(parents=True,exist_ok=True);records=[]
for archive,name in [(base/'motion/BattlePlayerKiryu.par','P_KRL_style_st.gmt'),(base/'chara_common/bone.par','c_cm_bone.gmd')]:
    data,record=entry(archive,name);(out/name).write_bytes(data);records.append(record)
(out/'source-index.json').write_text(json.dumps(records,indent=2)+'\n')
print('PASS supplied Kiwami 1 Dragon style-start motion and original skeleton extracted')
