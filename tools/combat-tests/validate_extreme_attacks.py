from pathlib import Path
import hashlib,json,re,struct,subprocess,sys,math,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza'
if '--inside-blender'not in sys.argv:
 r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout)
 if r.returncode or 'PASS supplied boost source'not in r.stdout:raise SystemExit(r.stderr or 'source validation failed')
 java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';cp='.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*'
 for args in [['PropAttachmentProbe',str(w/'boost-prop-contract.tsv')],['ExtremeAttackProbe',str(mod/'42/media/AnimSets/player')]]:subprocess.run([java,'-cp',cp,*args],cwd=w,check=True)
 d=json.loads((mod/'docs/boost-attack-assets.json').read_text());subprocess.run([java,'-cp',cp,'AnimationProbe',*[str(mod/r['output'])for r in d['clips']]],cwd=w,check=True)
 raise SystemExit(0)
sys.path.insert(0,str(w));from locomotion_math import read,locals_at
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
d=json.loads((mod/'docs/boost-attack-assets.json').read_text());assert len(d['clips'])==4 and sha(d['rig'])==d['rigSha256'];contracts=[];samples=0
assert sha(d['nativeGrip']['source'])==d['nativeGrip']['sha256']
for i,r in enumerate(d['clips']):
 p=mod/r['output'];assert sha(p)==r['sha256']and sha(r['source'])==r['sourceSha256']and sha(r['bep'])==r['bepSha256']
 data=Path(r['bep']).read_bytes();pos=16;contacts=[]
 while pos+80<=len(data):
  section,kind,size=struct.unpack_from('<HHI',data,pos+64);payload=data[pos+80:pos+80+size];assert len(payload)==size
  if section==12 and kind==68:contacts.append(int(struct.unpack_from('<f',payload,4)[0]))
  pos+=80+size
 assert contacts==r['contacts']and len(contacts)==1
 raw=root/f'tools/boost-build/ProjectYakuza/42/media/anims_X/Bob/{r["animation"]}.x';assert sha(raw)==r['retargetSha256']
 _,frames,anim,_=read(p);_,ff,aa,_=read(raw);assert set(frames)==set(ff)
 for bone,curves in anim.items():
  for kind,keys in curves.items():
   assert len(keys)==r['frames']
   for j,(tick,value)in enumerate(keys):assert tick==j*160 and all(math.isfinite(v)for v in value)
 for f in range(r['frames']):
  actual=locals_at(frames,anim,f*160);expected=locals_at(ff,aa,f*160)
  for n in actual:
   if n in ['Bip01_Prop1','Bip01_Prop2']:continue
   error=max(abs(actual[n][a][b]-expected[n][a][b])for a in range(4)for b in range(4));assert error<.00001,(r['animation'],f,n,error);samples+=1
 group='melee'if i<4 else 'actions';node=E.parse(mod/f'42/media/AnimSets/player/{group}/{r["animation"]}.xml').getroot();hits=[e for e in node.findall('m_Events')if e.findtext('m_EventName')=='AttackCollisionCheck'];assert len(hits)==(1 if i<4 else 0)
 if hits:assert abs(float(hits[0].findtext('m_TimePc'))*(r['frames']-1)-contacts[0])<1e-8
 offsets=[','.join(str(v)for row in d['nativeGrip']['nativeOffsets'][prop]for v in row)for prop in ['Bip01_Prop1','Bip01_Prop2']];contracts.append('\t'.join([str(p),*offsets,str(r['frames'])]))
(w/'boost-prop-contract.tsv').write_text('\n'.join(contracts),encoding='utf-8')
assert not list((mod/'42/media/anims_X/Bob').glob('ProjectYakuza_DD_Extreme*.x'))
print('PASS supplied boost source GMT/BEP, all source frames,',samples,'finite source bone samples, four source contacts and removed automatic special clips')
