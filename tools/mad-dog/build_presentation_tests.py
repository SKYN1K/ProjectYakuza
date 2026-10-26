from pathlib import Path
import argparse
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args()
modules={}
for directory in [root/'combat/ProjectYakuza/42/media/lua',root/'styles/ProjectYakuzaMadDog/42/media/lua']:
 for scope in ['shared','client']:
  for path in (directory/scope).rglob('*.lua'):modules[path.relative_to(directory/scope).with_suffix('').as_posix()]=path.read_text()
selected=['ProjectYakuza/Registry','ProjectYakuza/Styles/DragonOfDojima','ProjectYakuza/NetworkCatalog',
 'ProjectYakuza/WorldEffects','ProjectYakuza/HeatUI','ProjectYakuza/HeatAura',
 'ProjectYakuzaMadDog/Motions','ProjectYakuzaMadDog/NetworkCatalog','ProjectYakuzaMadDog/Style',
 'ProjectYakuzaMadDog/HUD','ProjectYakuzaMadDog/Aura']
s='local modules={}\n'
for name in selected:s+='modules["'+name+'"]=function()\n'+modules[name]+'\nend\n'
s+=(Path(__file__).with_name('presentation-fixture.lua')).read_text()
a.output.write_text(s)
