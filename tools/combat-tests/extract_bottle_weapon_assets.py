from pathlib import Path
import json
from y5_source_assets import entry
root=Path(__file__).resolve().parents[2];game=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data');out=root/'extracted/bottle-y6-0114';out.mkdir(exist_ok=True);records=[]
for suffix in ['ath_01_md','ath_02_md','ath_03_md','ath_hvy_md','ath_dwn_md','stdA_lp','stdB_lp']:
 for extension in ['gmt','bep']:
  name='P_KRU_BTL_WPN_'+suffix+'.'+extension;data,row=entry(game/'motion.par',name);dest=out/name;dest.write_bytes(data);records.append(dict(row,path=str(dest.resolve())))
(out/'index.json').write_text(json.dumps(records,indent=2)+'\n');print('PASS fourteen supplied WPN bottle GMT/BEP entries')
