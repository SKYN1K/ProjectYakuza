from pathlib import Path
import json,hashlib,struct,subprocess
from PIL import Image
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';report=json.loads((mod/'docs/style-transition-effects.json').read_text())
for item in report['assets']:
 source=Path(item['decodedOriginal']);output=mod/item['output'];dds=Path(item['dds']);raw=dds.read_bytes()
 assert hashlib.sha256(raw).hexdigest()==item['ddsSha256']and hashlib.sha256(output.read_bytes()).hexdigest()==item['sha256']and output.read_bytes()==source.read_bytes()
 actual=Image.open(output).convert('RGBA')
 try:expected=Image.open(dds).convert('RGBA')
 except NotImplementedError:
  flags,bits,*masks=struct.unpack_from('<6I',raw,80);assert bits==16 and flags&0x20000;expected=Image.frombytes('LA',actual.size,raw[128:128+actual.width*actual.height*2]).convert('RGBA')
 assert actual.size==tuple(item['size'])and actual.tobytes()==expected.tobytes()
print('PASS four supplied Kiwami 2 effect textures preserve every decoded pixel and native dimensions')
game=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid');subprocess.run([str(game/'jre64/bin/java.exe'),'-cp','.;'+str(game/'*'),'StyleFXProbe',str(mod.resolve())],cwd=Path(__file__).parent,check=True)
