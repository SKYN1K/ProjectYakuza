"""Verify event-free observer nodes using PZ's native parser and selector."""
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as E

here = Path(__file__).resolve().parent
root = here.parents[1]
media = root / 'combat/ProjectYakuza/42/media'
game = Path('F:/SteamLibrary/steamapps/common/ProjectZomboid')
nodes = list((media / 'AnimSets/player').rglob('ProjectYakuza_MP_*.xml'))
assert len(nodes) == 150, len(nodes)
for cycle in ('0', '1'):
    directory = here / ('native-observers-cycle' + cycle)
    directory.mkdir(exist_ok=True)
    count = 0
    for path in nodes:
        node = E.parse(path).getroot()
        conditions = {c.findtext('m_Name'): c.findtext('m_Value') for c in node.findall('m_Conditions')}
        assert not node.findall('m_Events')
        assert conditions['ProjectYakuzaRemoteObserver'] == 'true'
        assert conditions['ProjectYakuzaRemoteCycle'] in ('0', '1')
        original = media / 'AnimSets/player' / path.parent.name / (conditions['ProjectYakuzaRemoteClip'] + '.xml')
        if not original.is_file():
            original = next((media / 'AnimSets/player').rglob(conditions['ProjectYakuzaRemoteClip'] + '.xml'))
        source = E.parse(original).getroot()
        for tag in ['m_AnimName', 'm_SpeedScale', 'm_BlendTime', 'm_BlendOutTime', 'm_Looped']:
            assert node.findtext(tag) == source.findtext(tag), (path, tag)
        assert [E.tostring(n) for n in node.findall('m_SubStateBoneWeights')] == [E.tostring(n) for n in source.findall('m_SubStateBoneWeights')]
        if conditions['ProjectYakuzaRemoteCycle'] == cycle:
            # Probe intentionally scans files whose names begin ProjectYakuza_MP_.
            shutil.copyfile(path, directory / ('ProjectYakuza_MP_' + path.parent.name + '_' + path.name))
            count += 1
    assert count == 75
    result = subprocess.run([str(game / 'jre64/bin/java.exe'), '-cp', str(here) + ';' + str(game / 'projectzomboid.jar'),
                             'MPObserverProbe', str(directory)], cwd=here, capture_output=True, text=True)
    print(result.stdout, end='')
    if result.returncode:
        print(result.stderr)
        raise SystemExit(result.returncode)
for path in (media / 'AnimSets/zombie/hitreaction').glob('ProjectYakuza_EnemyHit*.xml'):
    repeat = media / 'AnimSets/zombie/hitreaction-hit' / path.name
    assert E.tostring(E.parse(path).getroot()) == E.tostring(E.parse(repeat).getroot())
print('PASS 150 event-free observer selectors retain their supplied clips/settings; 4 native repeat-hit nodes match originals')
