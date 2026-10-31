from pathlib import Path
import sys,json,hashlib
from mathutils import Matrix
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,pose,locals_at,blocks,write
m=root/'combat/ProjectYakuza';d=json.loads((m/'docs/locomotion-assets.json').read_text());sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob');changes=[]
for tag,filename in [('carryBat','Bob_IdleBat'),('carryKnife','Bob_Idle')]:
 src=native/(filename+'.x');_,f,a,_=read(src);w=pose(f,a);offsets={}
 for hand,prop in [('Bip01_R_Hand','Bip01_Prop1'),('Bip01_L_Hand','Bip01_Prop2')]:offsets[prop]=[list(row)for row in w[hand].inverted()@w[prop]]
 d['nativeGrips'][tag]={'source':str(src),'sha256':sha(src),'frame':0,'authoredOffsets':offsets,'nativeOffsets':offsets}
for r in d['clips']:
 if 'Carry' not in r['name']:continue
 family='Knife' if 'Knife' in r['name'] else 'Blade' if 'Blade' in r['name'] else 'Bat';grip='carryKnife' if family=='Knife' else 'carryBat'
 armSource=root/('tools/locomotion-build/ProjectYakuza/42/media/anims_X/Bob/ProjectYakuza_DD_'+family+'Carry.x');_,af,aa,_=read(armSource);held=locals_at(af,aa,0);upper=set(['Bip01_L_Clavicle','Bip01_R_Clavicle'])
 for n,v in af.items():
  if v['parent'] in upper:upper.add(n)
 suffix='WalkSlow' if r['name'].endswith('Slow') else 'Walk' if r['name'].endswith('Walk') else 'Idle'
 nativeName='Bob_'+suffix+('_Bat' if suffix=='WalkSlow' else 'Bat') if family!='Knife' else 'Bob_'+suffix
 if family!='Knife' and suffix=='WalkSlow':nativeName='Bob_WalkSlow_Bat'
 src=native/(nativeName+'.x');s,f,a,sp=read(src);end=max(t for c in a.values() for keys in c.values() for t,v in keys);times=list(range(0,end+1,160));values=[]
 for t in times:
  local=locals_at(f,a,t)
  for n in upper:local[n]=held[n].copy()
  values.append(local)
 path=m/r['output'];before=sha(path);write(path,s,sp,blocks(f,values,times,d['nativeGrips'][grip]),r['name'])
 keep={'name':r['name'],'output':r['output'],'kind':'stableCarryComposite','native':str(src),'nativeSha256':sha(src),'armSource':str(armSource),'armSourceSha256':sha(armSource),'armFrame':0,'upperBones':sorted(upper),'frames':len(times),'fps':30,'duration':end/4800,'grip':grip,'sha256':sha(path)}
 changes.append({'path':r['output'],'beforeSha256':before,'sha256':keep['sha256']});r.clear();r.update(keep)
d['operation']='Approved supplied motion repair: Kiryu running unchanged. Relaxed holds reuse the existing source frame-zero arm pose, native moving torso/head/legs and native idle hand-to-prop grips. No resampled upper-body loop, invented poses, AI or graphical/audio generation.'
(m/'docs/locomotion-assets.json').write_text(json.dumps(d,indent=2)+'\n',encoding='utf-8');(m/'docs/carry-repair-053.json').write_text(json.dumps({'operation':d['operation'],'changed':changes},indent=2)+'\n',encoding='utf-8');print('REPAIRED',len(changes),'native-head/torso, stable source-arm and native idle-grip carry clips')
