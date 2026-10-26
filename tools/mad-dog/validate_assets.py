"""Check exported byte provenance, native clip references and collision/event contracts."""
import hashlib
import json
import re
from pathlib import Path
import xml.etree.ElementTree as E

root=Path(__file__).resolve().parents[2]
addon=root/'styles/ProjectYakuzaMadDog'
manifest=json.loads((addon/'docs/motion-provenance.json').read_text())
clips=manifest['clips'];names={c['name'] for c in clips}
assert len(clips)==len(names)==26
actual={p.stem for p in (addon/'42/media/anims_X/Bob').glob('*.x')}
assert actual==names
for clip in clips:
    path=addon/'42/media/anims_X/Bob'/(clip['name']+'.x')
    assert hashlib.sha256(path.read_bytes()).hexdigest()==clip['output_sha256'],path
    assert clip['frames']>0 and clip['fps']==30 and clip['channels']==35
    if clip['impact_frame'] is not None:assert 0<clip['impact_frame']<clip['frames']
    assert clip['source'].startswith(('P_MJK_','P_btlst_MJA_to_MJK'))
owner=observer=collisions=0
for path in (addon/'42/media/AnimSets/player').rglob('*.xml'):
    node=E.parse(path).getroot()
    assert node.findtext('m_AnimName') in names,path
    events=node.findall('m_Events')
    if '_MP_' in path.name:
        observer+=1;assert not events,path
        assert {c.findtext('m_Name') for c in node.findall('m_Conditions')}=={
            'ProjectYakuzaRemoteObserver','ProjectYakuzaRemoteClip','ProjectYakuzaRemoteCycle'}
        continue
    owner+=1
    conditions={c.findtext('m_Name'):c.findtext('m_Value') for c in node.findall('m_Conditions')}
    assert conditions.get('ProjectYakuzaStyle')=='project_yakuza.mad_dog_of_shimano',path
    assert conditions.get('ProjectYakuzaActive')=='true',path
    hits=[e for e in events if e.findtext('m_EventName')=='AttackCollisionCheck']
    if path.parent.name in ('melee','stomp'):
        assert len(hits)==1,path
        collisions+=1
        assert hits[0].findtext('m_ParameterValue') in ('MeleeSwing','MeleeToFloor','Stomp')
        markers=[e for e in events if (e.findtext('m_ParameterValue') or '').startswith('ProjectYakuzaHitMarker=')]
        assert len(markers)==1 and markers[0].findtext('m_TimePc')==hits[0].findtext('m_TimePc'),path
    else:assert not hits,path
    for e in events:
        if e.find('m_TimePc') is not None:assert 0<=float(e.findtext('m_TimePc'))<=1,path
assert owner==28 and observer==82 and collisions==15,(owner,observer,collisions)
# There are no newly authored textures/audio/models, extracted game archives or credentials.
for path in addon.rglob('*'):
    if path.is_file():
        assert path.suffix.lower() not in ('.par','.gmt','.gmd','.png','.dds','.ogg','.wav','.mp3','.jar','.blend'),path
print(f'PASS: {len(clips)} verified clip hashes, {owner} owner nodes, {observer} event-free observers, {collisions} single-collision nodes; no raw archives/media added')
