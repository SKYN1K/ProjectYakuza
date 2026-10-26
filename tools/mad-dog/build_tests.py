"""Embed production Lua into an isolated Kahlua fixture. Output stays outside Git."""
from pathlib import Path
import argparse
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('output',type=Path);args=p.parse_args()
base=root/'combat/ProjectYakuza/42/media/lua'
addon=root/'styles/ProjectYakuzaMadDog/42/media/lua'
modules={}
for directory in [base,addon]:
    for scope in ['shared','client']:
        for path in (directory/scope).rglob('*.lua'):
            modules[path.relative_to(directory/scope).with_suffix('').as_posix()]=path.read_text()
selected=['ProjectYakuza/Registry','ProjectYakuza/Combo','ProjectYakuza/Styles/DragonOfDojima',
          'ProjectYakuza/NetworkCatalog','ProjectYakuza/NetworkProtocol','ProjectYakuza/Heat',
          'ProjectYakuza/Runtime','ProjectYakuzaMadDog/Motions','ProjectYakuzaMadDog/NetworkCatalog',
          'ProjectYakuzaMadDog/Style','ProjectYakuzaMadDog/Movement']
lines=['local modules={}']
for name in selected:
    lines.append('modules["'+name+'"]=function()\n'+modules[name]+'\nend')
lines.append((Path(__file__).with_name('fixture.lua')).read_text())
args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text('\n'.join(lines))
print('Embedded',len(selected),'production modules into',args.output)
