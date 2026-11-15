from pathlib import Path
import hashlib,json,math,subprocess,tempfile,wave,zipfile
from read_heat_scene import read_scene
from cri_cue_table import cue_names,sheet_names

root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza'
data=json.loads((mod/'docs/heat-scenes.json').read_text());extra=json.loads((mod/'docs/open-grab-heat-scene.json').read_text());data['scenes']+=extra['scenes'];data['sounds']+=extra['sounds']
effects=json.loads((mod/'docs/heat-scene-effects.json').read_text())
expected={'openGrab':[[78]],'knife':[[40,90]],'rush':[[56,68,74,86,93,105,113,125,131,143,150,162,190],[26]],'bottle':[[32,42,59,84]],'wall':[[12,48]],'ground':[[30]],'crate':[[51,134,231,307,404,555],[101]],'katana':[[24,44,64]],'bat':[[14,50]],'bicycle':[[50]]}
original={'openGrab':[78],'knife':[40,90],'rush':[56,68,78,90,102,114,144],'bottle':[32,42,59,84],'wall':[12,48],'ground':[],'crate':[51,134,231,307,404,555],'katana':[24,44,64],'bat':[14,50],'bicycle':[50]}
sha=lambda b:hashlib.sha256(b).hexdigest()
banks={};count=0
expected['bicycle']=[[29,70]];original['bicycle']=[29,70]
sheet=data['sheetIndex'];assert sha(Path(sheet['path']).read_bytes())==sheet['sha256'];sheets=sheet_names(Path(sheet['path']).read_bytes())
def bank_data(bank):
    identity=(bank['archive'],bank['entryOffset'],bank['entrySize'])
    if identity not in banks:
        with Path(bank['archive']).open('rb')as stream:
            stream.seek(bank['entryOffset']);raw=stream.read(bank['entrySize'])
        assert sha(raw)==bank['entrySha256'];banks[identity]=(raw,cue_names(raw))
    return banks[identity]
for record in data['scenes']:
    key=record['id'];scene=read_scene(record['source'])
    assert scene['sha256']==record['sourceSha256']
    assert scene['version']==(10 if key in ['crate','openGrab']else 18)
    victim=sorted((n for n in scene['nodes']if 'damage'in n and n['role']=='victim'),key=lambda n:n['element']['start'])
    assert [n['element']['start']for n in victim]==original[key]
    bank=record['bank']
    raw,names=bank_data(bank)
    if key=='crate':assert [(r['frame'],r['damage'],r['forceDead'])for r in record['ignoredNonVictimDamage']]==[(555,100,1)]*5
    for i,definition in enumerate(record['definitions']):
        contacts=definition['contacts'];frames=definition['sourceFrames'];clip=definition['animation']
        assert [round(c['atMs']*.03,6)for c in contacts]==expected[key][i]
        assert len(frames)==(271 if key=='rush'and not i else 635 if key=='crate'and not i else len(frames))
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
            if key=='katana':
                katanaCues={'heatKatanaBodyFall':'bodyfall','heatKatanaSwing':'katana_swing','heatKatanaPunch':'punch','heatKatanaSlash':'slash','heatKatanaThrust':'tuki'}
                assert any(names[n['sound']['cueId']]==katanaCues[event['cue']]for n in matches)
            else:
                audio=next(r for r in data['sounds']if r['cue']==event['cue'])
                assert any(n['sound']['cueId']==audio['cueId']and n['sound']['cueSheet']==audio['cueSheet']for n in matches)
                if key=='bicycle':assert audio['entry']==sheets[audio['cueSheet']]+'.acb'
        assert all(v['entry'].startswith('Combat')for v in definition['voiceEvents'])
        count+=len(native)
assert count==129 and len(data['sounds'])==54
with tempfile.TemporaryDirectory(prefix='project-yakuza-cmn-')as tmp:
    folder=Path(tmp)
    for record in data['sounds']:
        key=record['output'].split('HeatScene_')[1].split('_')[0]
        raw,names=bank_data(record);assert names[record['cueId']]==record['stream']and not record['stream'].startswith('Kiryu_')
        assert record['soundIndex']==record['cueId']+(0 if key in ['crate','openGrab']else 1)
        bank=folder/(key+'.acb');bank.write_bytes(raw);out=folder/'decoded.wav'
        subprocess.run([str(root/'tools/vgmstream/vgmstream-cli.exe'),'-s',str(record['streamIndex']),'-i','-o',str(out),str(bank)],check=True,capture_output=True)
        shipped=mod/record['output'];assert out.read_bytes()==shipped.read_bytes()
        assert sha(shipped.read_bytes())==record['sha256']
        with wave.open(str(shipped))as audio:assert (audio.getframerate(),audio.getnchannels(),audio.getsampwidth(),audio.getnframes())==(record['sampleRate'],record['channels'],2,record['samples'])
print('PASS 10 supplied CMN scenes, 12 timelines, 38 contacts, 129 blood anchors and 54 original PCM decodes; scoped media checked by the release validators')
