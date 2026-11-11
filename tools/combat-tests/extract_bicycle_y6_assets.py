from pathlib import Path
import json
from y5_source_assets import unpack
root=Path(__file__).resolve().parents[2];out=root/'extracted/bicycle-y6-099/h23701_buki_f';index=unpack('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/hact/h23701_buki_f.par',out);(out/'index.json').write_text(json.dumps(index,indent=2)+'\n');print('PASS original Y6 big/heavy-object scene extracted for the bicycle')
