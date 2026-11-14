from pathlib import Path
import json
from y5_source_assets import unpack
root=Path(__file__).resolve().parents[2];out=root/'extracted/bicycle-momentum-0109/h24110_c_german';index=unpack('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/hact/h24110_c_german.par',out);(out/'index.json').write_text(json.dumps(index,indent=2)+'\n');print('PASS original Y6 held-object hit and jump-crush scene extracted for the bicycle')
