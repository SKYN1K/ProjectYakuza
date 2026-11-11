from pathlib import Path
import hashlib,json,math,subprocess,tempfile,wave,zipfile
from read_heat_scene import read_scene
from cri_cue_table import cue_names

root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza'
data=json.loads((mod/'docs/heat-scenes.json').read_text())
effects=json.loads((mod/'docs/heat-scene-effects.json').read_text())
expected={'knife':[[40,90]],'rush':[[56,68,80,92,114,126,146,158,170,182,204,216,246],[26]],'bottle':[[32,42,59,84]],'wall':[[12,48]],'ground':[[30]],'crate':[[14,44,54,74,84,104,114,142],[19]],'katana':[[24,44,64]],'bat':[[14,50]],'bicycle':[[50]]}
original={'knife':[40,90],'rush':[56,68,78,90,102,114,144],'bottle':[32,42,59,84],'wall':[12,48],'ground':[],'crate':[14,44,54,82],'katana':[24,44,64],'bat':[14,50],'bicycle':[50]}
sha=lambda b:hashlib.sha256(b).hexdigest()
banks={};count=0
for record in data['scenes']:
    key=record['id'];scene=read_scene(record['source'])
    assert scene['sha256']==record['sourceSha256']
    assert scene['version']==(10 if key=='crate'else 18)
    victim=sorted((n for n in scene['nodes']if 'damage'in n and n['role']=='victim'),key=lambda n:n['element']['start'])
    assert [n['element']['start']for n in victim]==original[key]
    bank=record['bank']
    with Path(bank['archive']).open('rb')as stream:
        stream.seek(bank['entryOffset']);raw=stream.read(bank['entrySize'])
    assert sha(raw)==bank['entrySha256'];banks[key]=(raw,cue_names(raw))
    if key=='crate':assert [(r['frame'],r['damage'],r['forceDead'])for r in record['ignoredNonVictimDamage']]==[(13,100,1)]
    for i,definition in enumerate(record['definitions']):
        contacts=definition['contacts'];frames=definition['sourceFrames'];clip=definition['animation']
        assert [round(c['atMs']*.03,6)for c in contacts]==expected[key][i]
        assert len(frames)==(327 if key=='rush'and not i else 190 if key=='crate'and not i else len(frames))
        for contact in contacts:assert 0<contact['atMs']<(len(frames)-1)/30*1000
        if not i:
            if key in ['rush','crate']:
                assert all(c['damageMultiplier']==0 for c in contacts)
                assert contacts[-1]['sumQTE']and all(not c.get('sumQTE')for c in contacts[:-1])
                assert contacts[-1].get('baseDamageMultiplier',0)==(1.5 if key=='crate'else 0)
            else:
                total=1.5 if key in ['katana','bottle','bat','bicycle','knife']else 5
                assert math.isclose(sum(c['damageMultiplier']for c in contacts),total)
                if victim:
                    weights=[n['damage']['damage']for n in victim]
                    assert all(math.isclose(c['damageMultiplier']/total,w/sum(weights))for c,w in zip(contacts,weights))
        native=effects['moves'][clip];assert len(native)==len(definition['particles'])
        for particle,event in zip(definition['particles'],native):
            source=next(n for n in scene['nodes']if n['offset']==particle['sourceOffset'])
            assert source['role']=='victim'and source['bone']==particle['bone']
            assert source['particle']['matrix'][12:15]==particle['localPoint']
            assert math.isclose(event['atMs'],particle['frame']/30*1000)
            assert all(math.isfinite(v)and abs(v)<5 for v in event['point'])
        for event in definition['audioEvents']:
            mappedFrame=event['atMs']*.03;index=math.floor(mappedFrame+1e-8);sourceFrame=frames[index]+mappedFrame-index
            matches=[n for n in scene['nodes']if math.isclose(n.get('element',{}).get('start',-1000),sourceFrame,abs_tol=1e-6)and 'sound'in n and not n['sound']['fighter']]
            assert matches,(key,event)
            assert any(banks[key][1][n['sound']['cueId']].startswith('Kiryu_')is False for n in matches)
        assert all(v['entry'].startswith('Combat')for v in definition['voiceEvents'])
        count+=len(native)
assert count==130 and len(data['sounds'])==37
with tempfile.TemporaryDirectory(prefix='project-yakuza-cmn-')as tmp:
    folder=Path(tmp)
    for record in data['sounds']:
        key=record['cue'].removeprefix('heatScene').rstrip('0123456789').lower()
        raw,names=banks[key];assert names[record['cueId']]==record['stream']and not record['stream'].startswith('Kiryu_')
        assert record['soundIndex']==record['cueId']+(0 if key=='crate'else 1)
        bank=folder/(key+'.acb');bank.write_bytes(raw);out=folder/'decoded.wav'
        subprocess.run([str(root/'tools/vgmstream/vgmstream-cli.exe'),'-s',str(record['streamIndex']),'-i','-o',str(out),str(bank)],check=True,capture_output=True)
        shipped=mod/record['output'];assert out.read_bytes()==shipped.read_bytes()
        assert sha(shipped.read_bytes())==record['sha256']
        with wave.open(str(shipped))as audio:assert (audio.getframerate(),audio.getnchannels(),audio.getsampwidth(),audio.getnframes())==(record['sampleRate'],record['channels'],2,record['samples'])
print('PASS 9 supplied CMN scenes, 11 timelines, 38 contacts, 130 blood anchors and 37 original PCM decodes; scoped media checked by the release validators')
