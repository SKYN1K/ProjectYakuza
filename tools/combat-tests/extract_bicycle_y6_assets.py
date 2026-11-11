from pathlib import Path
import json
from y5_source_assets import unpack
root=Path(__file__).resolve().parents[2];out=root/'extracted/bicycle-held-0100/h23740_buki_g';index=unpack('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/hact/h23740_buki_g.par',out);(out/'index.json').write_text(json.dumps(index,indent=2)+'\n');print('PASS original Y6 held heavy-weapon scene extracted for the bicycle')
