from pathlib import Path
import json,hashlib,wave,struct,re,sys
from read_katana_scene import read_scene
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';report=json.loads((mod/'docs/katana-scene-audio.json').read_text());motion=json.loads((mod/'docs/katana-heat-assets.json').read_text());scene=read_scene(motion['scene']);nodes=scene['nodes']
damage=sorted((r for r in nodes if 'damage'in r),key=lambda r:r['element']['start'])
assert [(r['element']['start'],r['damage']['damage'],r['damage']['noDead'])for r in damage]==[(24,500,1),(44,500,1),(64,1000,0)]
assert len(report['sounds'])==5
prefix='SE_HACT_H23720_BUKI_E_';names={'bodyfall':'BODYFALL','katana_swing':'KATANA_SW','punch':'PUNCH','slash':'SLASH','tuki':'TUKI'}
for record in report['sounds']:
 node=next(r for r in nodes if r['name']==prefix+names[record['stream']]);assert node['element']['start']==record['sourceFrame']
 output=mod/record['output'];assert hashlib.sha256(output.read_bytes()).hexdigest()==record['sha256']
 with wave.open(str(output))as audio:assert (audio.getframerate(),audio.getnchannels(),audio.getsampwidth(),audio.getnframes())==(44100,2,2,record['samples'])
with Path(report['archive']).open('rb')as source:
 source.seek(report['entryOffset']);size=(root/'extracted/katana-scene-093'/report['entry']).stat().st_size;bank=source.read(size);assert hashlib.sha256(bank).hexdigest()==report['entrySha256']
assert len(motion['effectPoints'])==3
for effect in motion['effectPoints']:
 node=next(r for r in nodes if r['name']==effect['sourceEmitter']and r.get('element',{}).get('start')==effect['sourceFrame'])
 assert node['particle']['matrix'][12:15]==effect['sourceLocalOffset']
voices=sorted((r['element']['start'],r['name'].split(':')[-1])for r in nodes if r['name'].endswith(('GV_FIGHTER_ATTACK_XL','GV_FIGHTER_THROW')))
assert voices==[(6,'GV_FIGHTER_ATTACK_XL'),(46,'GV_FIGHTER_THROW')]
summary={'source':scene['source'],'sha256':scene['sha256'],'formatReference':scene['parserReference'],'format':'Yakuza 6 CMN18, original 30 fps frames','motionNodes':[{k:v for k,v in r.items()if k in ['guid','name','motion']}for r in nodes if 'motion'in r],'damage':[{'frame':r['element']['start'],**r['damage']}for r in damage],'audio':[{'frame':r['sourceFrame'],'cueSheet':r['cueSheet'],'cueId':r['cueId'],'stream':r['stream']}for r in sorted(report['sounds'],key=lambda r:r['sourceFrame'])],'actorVoiceLabels':voices,'effectAttachments':motion['effectPoints']}
path=mod/'docs/katana-scene-timeline.json'
if '--write'in sys.argv:path.write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
else:assert json.loads(path.read_text())==json.loads(json.dumps(summary))
print('PASS original CMN18 damage/voice/particle and five native-format sound-bank cue contracts; source bank/output hashes match')
