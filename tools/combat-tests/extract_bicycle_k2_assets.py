from pathlib import Path
import json
from y5_source_assets import entry
root=Path(__file__).resolve().parents[2];game=Path('F:/SteamLibrary/steamapps/common/Yakuza Kiwami 2/data');out=root/'extracted/bicycle-k2-0111';out.mkdir(parents=True,exist_ok=True);records=[]
for suffix in ['ath_01_md','ath_02_md','ath_03_md','ath_hvy_md','ath_dwn_md','stdA_lp','stdB_lp']:
    stem='P_KRU_BTL_WPC_'+suffix
    for extension in ['gmt','bep']:
        data,record=entry(game/'motion.par',stem+'.'+extension);path=out/(stem+'.'+extension);path.write_bytes(data);records.append(dict(record,path=str(path)))
for extension in ['gmt','bep']:
    name='P_KRU_MOV_wlk_ftl_wpc.'+extension;data,record=entry(game/'motion.par',name);path=out/name;path.write_bytes(data);records.append(dict(record,path=str(path)))
data,record=entry(game/'chara.par','c_man_bone.gmd');path=out/'c_man_bone.gmd';path.write_bytes(data);records.append(dict(record,path=str(path)))
(out/'index.json').write_text(json.dumps(records,indent=2)+'\n');print('PASS 16 original Kiwami 2 attack/hold/walk GMT and BEP entries plus the original Human rig')
