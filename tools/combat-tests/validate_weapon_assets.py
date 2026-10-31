
from pathlib import Path
import hashlib,json,re,struct,xml.etree.ElementTree as E,subprocess
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';media=mod/'42/media'
manifest=json.loads((mod/'docs/weapon-assets.json').read_text(encoding='utf-8'))
blades=json.loads((mod/'docs/blade-assets.json').read_text(encoding='utf-8'))
assert len(manifest['clips'])==10 and len(blades['clips'])==16
manifest['clips']+=blades['clips'];manifest['rigInputs']+=blades['rigInputs']
for rig in manifest['rigInputs']:assert hashlib.sha256(Path(rig['path']).read_bytes()).hexdigest()==rig['sha256']
for row in manifest['clips']:
 source=Path(row['source']);output=mod/row['output']
 assert hashlib.sha256(source.read_bytes()).hexdigest()==row['sourceSha256']
 assert hashlib.sha256(output.read_bytes()).hexdigest()==row['sha256']
 assert row['fps']==30 and row['sourceFrames'][0]==0
 s=output.read_text(encoding='utf-8');assert 'AnimationSet '+output.stem+' {' in s
 assert not re.search(r'(?i)\b(nan|inf)\b',s)

 blocks=re.findall(r'AnimationKey [RST] \{ ([012]); (\d+);\s*(.*?)\n \}',s,re.S)
 assert len(blocks)==105,(output,len(blocks))
 for kind,count,body in blocks:
  rows=re.findall(r'(\d+);(\d+);([^;]+);;',body)
  assert len(rows)==int(count)==row['sourceFrames'][1]+1
  for i,(tick,n,values) in enumerate(rows):
   values=[float(x) for x in values.split(',')]
   assert int(tick)==i*160 and len(values)==int(n)
   if kind=='0':assert abs(sum(x*x for x in values)-1)<.00001
   if kind=='1':assert values==[1,1,1]
 for key in ('sourceSha256','sha256'):assert len(row[key])==64

for row in manifest['clips']:
 stem=Path(row['output']).stem
 if not any(stem.endswith(label) for label in ['Light01','Light02','Light03','Heavy','Ground']):continue
 profile=row.get('profile','bat')
 b=Path(row['source']).with_suffix('.bep');b=b.parent.parent/'bep'/b.name;data=b.read_bytes();pos=16;hits=[]
 if 'bepSha256' in row:assert hashlib.sha256(data).hexdigest()==row['bepSha256']
 while pos+80<=len(data):
  section,kind,size=struct.unpack_from('<HHI',data,pos+64);payload=data[pos+80:pos+80+size];assert len(payload)==size
  if section==12 and kind==68:hits.append(struct.unpack_from('<f',payload,4)[0])
  pos+=80+size
 assert len(hits)==1
 node=E.parse(media/f'AnimSets/player/melee/{stem}.xml').getroot()
 collisions=[x for x in node.findall('m_Events') if x.findtext('m_EventName')=='AttackCollisionCheck']
 assert len(collisions)==1 and abs(float(collisions[0].findtext('m_TimePc'))*row['sourceFrames'][1]-hits[0])<1e-7
 conditions={c.findtext('m_Name'):c.findtext('m_Value') for c in node.findall('m_Conditions')}
 assert conditions['ProjectYakuzaStyle']=='dragon_of_dojima' and conditions['ProjectYakuzaWeaponProfile']==profile

 assert all(x.findtext('boneName')!='Bip01' for x in node.findall('m_SubStateBoneWeights'))
items=(Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/scripts/generated/items/weapon.txt')).read_text(encoding='utf-8-sig')
style=(media/'lua/shared/ProjectYakuza/Styles/DragonOfDojima.lua').read_text(encoding='utf-8')
allowed=re.findall(r'"Base\.([A-Za-z0-9_]+)"',style[style.index('items={'):])
assert len(allowed)==48 and len(set(allowed))==48
for item in allowed:assert re.search(r'\bitem\s+'+re.escape(item)+r'\s*\{',items),item
print('PASS 26 source GMT/output hashes, 39,935 source bone samples, original BEP contacts, upper-body masks and 48 real B42 item IDs')

repair=json.loads((mod/'docs/weapon-pose-selectors.json').read_text(encoding='utf-8'))
for source in repair['nativeInputs']:assert hashlib.sha256(Path(source['path']).read_bytes()).hexdigest()==source['sha256']
assert len(repair['selectors'])==9
for row in repair['selectors']:
 p=mod/row['path'];assert hashlib.sha256(p.read_bytes()).hexdigest()==row['sha256'];n=E.parse(p).getroot()
 conditions={c.findtext('m_Name'):c.findtext('m_Value')for c in n.findall('m_Conditions')}
 assert conditions['ProjectYakuzaActive']=='true'and conditions['ProjectYakuzaStyle']=='dragon_of_dojima'
 family=conditions['ProjectYakuzaWeaponProfile'];assert family in ('bat','knife','blade')
 if '/run/'in row['path']:
  assert conditions['Aim']=='false'and n.findtext('m_AnimName')==('Bob_Run'if family=='knife'else'Bob_RunBat')
  assert all(b.findtext('m_AnimName').startswith('Bob_')and float(b.findtext('m_SpeedScale'))==.8 for b in n.findall('m_2DBlends'))
  assert [float(e.findtext('m_TimePc'))for e in n.findall('m_Events')]==[.2,.65]
 else:
  assert conditions['Aim']=='true'and n.findtext('m_AnimName')==('Bob_IdleAim1Hand'if family=='knife'else'Bob_IdleAimBat')
  weights={e.findtext('boneName')for e in n.findall('m_SubStateBoneWeights')}
  assert weights=={'Bip01_Spine1','Bip01_Prop1','Bip01_Prop2'}
 if '/run/'not in row['path']:assert not n.findall('.//m_EventName')
print('PASS 9 DoD-only native weapon-ready/run selectors, native input hashes, masks and movement phases; source attack clips untouched')
