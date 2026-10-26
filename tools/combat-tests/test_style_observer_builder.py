"""Exercise the shipped addon starter/builder without starting the game."""
from pathlib import Path
import sys
sys.dont_write_bytecode=True
import importlib.util
import shutil
import tempfile
import xml.etree.ElementTree as E
import subprocess

here=Path(__file__).resolve().parent
mod=here.parents[1]/'combat/ProjectYakuza'
spec=importlib.util.spec_from_file_location('builder',mod/'tools/build_style_observers.py')
builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
with tempfile.TemporaryDirectory(dir=here) as tmp:
    addon=Path(tmp)/'ExampleAddon'
    shutil.copytree(mod/'templates/StyleSubmod',addon)
    for path in list(addon.rglob('*.example')):
        if path.name.endswith(('.lua.example','.xml.example','mod.info.example')):
            path.rename(path.with_suffix(''))
    before={p.relative_to(addon):p.read_bytes() for p in addon.rglob('*') if p.is_file()}
    records,outputs=builder.build(addon,'example_mod.my_style','ExampleStyle_',True)
    assert len(records)==2 and len(outputs)==7
    assert before=={p.relative_to(addon):p.read_bytes() for p in addon.rglob('*') if p.is_file()}
    builder.build(addon,'example_mod.my_style','ExampleStyle_')
    assert len(builder.build(addon,'example_mod.my_style','ExampleStyle_',True)[0])==2
    for rel,data in before.items():assert (addon/rel).read_bytes()==data
    for path,data in outputs.items():
        assert path.read_bytes()==data
        if path.suffix=='.xml':
            node=E.parse(path).getroot()
            assert not node.findall('m_Events')
            c={x.findtext('m_Name'):x.findtext('m_Value') for x in node.findall('m_Conditions')}
            assert c['ProjectYakuzaRemoteObserver']=='true' and c['ProjectYakuzaRemoteCycle'] in ('0','1')
    game=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid')
    if game.exists():
        native=subprocess.run([str(game/'jre64/bin/java.exe'),'-cp',str(here)+';'+str(game/'projectzomboid.jar'),
                              'MPObserverProbe',str(addon/'42/media/AnimSets/player'),'ExampleStyle_Observer_','6'],cwd=here,check=True,capture_output=True,text=True)
        print(native.stdout.strip())
        compiled=subprocess.run([str(game/'jre64/bin/java.exe'),'-cp',str(here)+';'+str(game/'projectzomboid.jar'),
                                 'CompileCombatLua',str(addon/'42/media/lua')],cwd=here,check=True,capture_output=True,text=True)
        print(compiled.stdout.strip())
    # Never overwrite an author's file, even when other destinations are valid.
    target=next(p for p in outputs if p.suffix=='.xml');target.write_text('<animNode/>')
    snapshots={p:p.read_bytes() for p in outputs}
    try:builder.build(addon,'example_mod.my_style','ExampleStyle_')
    except AssertionError:pass
    else:raise AssertionError('Author-maintained output was overwritten')
    assert snapshots=={p:p.read_bytes() for p in outputs}
    # Reject unsupported native condition operators instead of flattening them.
    owner=addon/'42/media/AnimSets/player/melee/ExampleStyle_Light01.xml'
    tree=E.parse(owner);E.SubElement(tree.getroot().find('m_Conditions'),'m_CompareTo').text='other'
    tree.write(owner)
    try:builder.build(addon,'example_mod.my_style','ExampleStyle_',True)
    except AssertionError:pass
    else:raise AssertionError('Complex condition silently accepted')
print('PASS activated starter, dry-run, deterministic observer generation, native parsing, Lua compilation and overwrite/complex-condition safety')
