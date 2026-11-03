from fixture_markers import fixture_marker
from pathlib import Path
w=Path(__file__).parent;m=w.parent.parent/'combat/ProjectYakuza/42/media/lua'
modules=['shared/ProjectYakuza/Bindings.lua','shared/ProjectYakuza/Registry.lua','shared/ProjectYakuza/StyleSlots.lua','client/ProjectYakuza/StyleUI.lua','client/ProjectYakuza/StyleSelector.lua']
s=(w/'style-selector-test-fixture.lua').read_text(encoding='utf-8')
s=s.replace(fixture_marker('MODULES'),'\n'.join('do\n'+(m/p).read_text(encoding='utf-8')+'\nend' for p in modules)+'\n')
(w/'style-selector-tests.lua').write_text(s,encoding='utf-8')

assert "OnFillInventoryObjectContextMenu" not in (m/"client/ProjectYakuza/Menu.lua").read_text(), "obsolete inventory settings menu remains"

import ast,struct,io,json,hashlib
from PIL import Image
mod=m.parents[2]
record=json.loads((mod/'docs/style-settings-background.json').read_text())
c,size,stored,offset,attr,ext,stamp=record['meta']
with Path(record['archive']).open('rb')as stream:
    stream.seek(offset+(ext<<32));raw=stream.read(stored if c else size)
node=next(n for n in ast.parse((w/'validate_rush_qte_assets.py').read_text()).body if isinstance(n,ast.FunctionDef)and n.name=='sllz')
namespace={'struct':struct};exec(compile(ast.Module(body=[node],type_ignores=[]),'source_dds_decoder','exec'),namespace)
dds=namespace['sllz'](raw)if raw.startswith(b'SLLZ')else raw
source=Image.open(io.BytesIO(dds)).convert('RGBA');output=mod/record['output'];image=Image.open(output).convert('RGBA')
assert source.size==image.size==(1024,512)and source.tobytes()==image.tobytes(),'settings backdrop source pixels differ'
assert hashlib.sha256(output.read_bytes()).hexdigest()==record['sha256']
assert hashlib.sha256(image.tobytes()).hexdigest()==record['rgbaSha256']
print('PASS Kiwami settings background: all 524288 original pixels and 1024x512 dimensions preserved')
