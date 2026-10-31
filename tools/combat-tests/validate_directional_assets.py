from pathlib import Path
import hashlib,json,struct,subprocess,sys,math,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza'
if '--inside-blender'not in sys.argv:
 r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout)
 if r.returncode or 'PASS supplied directional source'not in r.stdout:raise SystemExit(r.stderr or 'source validation failed')
 java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';cp='.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*';d=json.loads((mod/'docs/directional-attack-assets.json').read_text())
 for args in [['PropAttachmentProbe',str(w/'directional-prop-contract.tsv')],['DirectionalAttackProbe',str(mod/'42/media/AnimSets/player')],['AnimationProbe',*[str(mod/r['output'])for r in d['clips']]]]:subprocess.run([java,'-cp',cp,*args],cwd=w,check=True)
 raise SystemExit(0)
sys.path.insert(0,str(w));from locomotion_math import read,locals_at
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
d=json.loads((mod/'docs/directional-attack-assets.json').read_text());assert len(d['clips'])==3 and sha(d['rig'])==d['rigSha256'];assert sha(d['nativeGrip']['source'])==d['nativeGrip']['sha256'];contracts=[];samples=0
assert sha(d['nativeFingerSource'])==d['nativeFingerSha256']
assert sha(d['commandSource'])==d['commandSha256'];command=Path(d['commandSource']).read_bytes()
for key,value in d['commandMappings'].items():assert (key+'\0'+value+'\0').encode()in command
for r in d['clips']:
 p=mod/r['output'];assert sha(p)==r['sha256']and sha(r['source'])==r['sourceSha256']and sha(r['bep'])==r['bepSha256']
 data=Path(r['bep']).read_bytes();pos=16;contacts=[]
 while pos+80<=len(data):
  section,kind,size=struct.unpack_from('<HHI',data,pos+64);payload=data[pos+80:pos+80+size];assert len(payload)==size
  if section==12 and kind==68:contacts.append(int(struct.unpack_from('<f',payload,4)[0]))
  pos+=80+size
 assert contacts==[r['contactFrame']]
 raw=root/f'tools/directional-build/ProjectYakuza/42/media/anims_X/Bob/{r["animation"]}.x';assert sha(raw)==r['retargetSha256'];_,ff,aa,_=read(raw);_,frames,anim,_=read(p);assert set(frames)==set(ff)
 for bone,curves in anim.items():
  for kind,keys in curves.items():
   assert len(keys)==r['frames']
   for j,(tick,value)in enumerate(keys):assert tick==j*160 and all(math.isfinite(v)for v in value)
 for f in range(r['frames']):
  actual=locals_at(frames,anim,f*160);expected=locals_at(ff,aa,f*160)
  for n in actual:
   if n in ['Bip01_Prop1','Bip01_Prop2']:continue
   error=max(abs(actual[n][a][b]-expected[n][a][b])for a in range(4)for b in range(4));assert error<.00001,(r['animation'],f,n,error);samples+=1
 node=E.parse(mod/f'42/media/AnimSets/player/melee/{r["animation"]}.xml').getroot();events=node.findall('m_Events');hits=[e for e in events if e.findtext('m_EventName')=='AttackCollisionCheck'];assert len(hits)==1
 assert abs(float(hits[0].findtext('m_TimePc'))*(r['frames']-1)-r['contactFrame'])<1e-8
 cancel=[e for e in events if (e.findtext('m_ParameterValue')or'').startswith('ProjectYakuzaQuickstepCancelReady=')];assert len(cancel)==1 and abs(float(cancel[0].findtext('m_TimePc'))*(r['frames']-1)-r['contactFrame']-1)<1e-8
 blocks=[e for e in events if e.findtext('m_EventName')=='BlockMovement'];assert {(e.findtext('m_Time'),e.findtext('m_ParameterValue'))for e in blocks}=={('Start','TRUE'),('End','FALSE')}
 assert node.find('m_SubStateBoneWeights/boneName').text=='Bip01'
 assert node.findtext('m_EarlyTransitionOut')=='true'
 offsets=[','.join(str(v)for row in d['nativeGrip']['nativeOffsets'][prop]for v in row)for prop in ['Bip01_Prop1','Bip01_Prop2']];contracts.append('\t'.join([str(p),*offsets,str(r['frames'])]))
(w/'directional-prop-contract.tsv').write_text('\n'.join(contracts),encoding='utf-8')
print('PASS supplied directional source GMT/BEP, exact command mappings, all frames and',samples,'finite retained body samples')
