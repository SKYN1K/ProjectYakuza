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

# Exercise the new upstream entry handler with Mad Dog's own original clip.
entry=(root/'tools/combat-tests/style-entry-test-fixture.lua').read_text()
entry=entry.replace("'dragon_of_dojima'", "'project_yakuza.mad_dog_of_shimano'")
entry=entry.replace("c.action.duration==50/30", "c.action.duration==30/30")
style_code='do\n'+modules['ProjectYakuza/Styles/DragonOfDojima']+'\nend\n'
style_code+='local madDogMotions=(function()\n'+modules['ProjectYakuzaMadDog/Motions']+'\nend)()\n'
style_code+='require=function(name) if name=="ProjectYakuzaMadDog/Motions" then return madDogMotions end end\n'
style_code+='ProjectYakuza.NetworkCatalog={}\n'
style_code+='do\n'+modules['ProjectYakuzaMadDog/NetworkCatalog']+'\nend\n'
style_code+='do\n'+modules['ProjectYakuzaMadDog/Style']+'\nend\n'
for marker,module in [('BINDINGS','shared/ProjectYakuza/Bindings.lua'),('REGISTRY','shared/ProjectYakuza/Registry.lua'),('ENTRY','client/ProjectYakuza/StyleEntry.lua')]:
    entry=entry.replace('-- '+marker+'\n','do\n'+(base/module).read_text()+'\nend\n')
entry=entry.replace('-- STYLE\n',style_code)
args.output.with_name('mad-dog-entry-tests.lua').write_text(entry)
