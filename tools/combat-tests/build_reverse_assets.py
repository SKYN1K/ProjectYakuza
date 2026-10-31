from pathlib import Path
import sys,json,hashlib,struct,math,re
from mathutils import Matrix,Quaternion
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,pose
mod=root/'combat/ProjectYakuza';sourceRoot=Path('E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack');converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text(encoding='utf-8').replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/charge-build'");grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];offsets={n:Matrix(v) for n,v in grip['authoredOffsets'].items()};records=[]
jobs=[]
for i in range(1,5):
 jobs += [(f'ProjectYakuza_DD_ReverseFinisher0{i}',f'P_KRU_BTL_SUD_ath_0{i}_B_fin_md',f'reverse_after_{i}'),(f'ProjectYakuza_DD_ReverseDoubleFinisher0{i}',f'P_KRU_BTL_SUD_ath_0{i}_B_finW_md',f'reverse_double_after_{i}')]
for name,stem,variant in jobs:
 src=sourceRoot/'gmt'/(stem+'.gmt');sys.argv=['convert','--',name,str(src)];ns={"FINGER_SOURCE":"Bob_AttackPunch01_Hit.x"};exec(compile(converter,'source_motion_conversion','exec'),ns)
 path=root/f'tools/charge-build/ProjectYakuza/42/media/anims_X/Bob/{name}.x';content,frames,anim,spans=read(path);count=ns['a'].end_frame+1
 worlds=[pose(frames,anim,f) for f in range(count)];edits=[]
 for hand,prop in [('Bip01_R_Hand','Bip01_Prop1'),('Bip01_L_Hand','Bip01_Prop2')]:
  values=[world[frames[prop]['parent']].inverted()@world[hand]@offsets[prop] for world in worlds];block='Animation { { '+prop+' }\n'
  for kind,label in [(0,'R'),(1,'S'),(2,'T')]:
   rows=[];previous=None
   for f,m in enumerate(values):
    if kind==0:
     q=m.to_quaternion().normalized()
     if previous and q.dot(previous)<0:q.negate()
     previous=q.copy();v=(-q.w,q.x,q.y,q.z)
    elif kind==1:v=(1,1,1)
    else:v=tuple(m.translation)
    rows.append(str(f*160)+';'+str(len(v))+';'+','.join(f'{x:.9f}' for x in v)+';;')
   block+=' AnimationKey '+label+' { '+str(kind)+'; '+str(count)+';\n'+',\n'.join(rows)+';\n }\n'
  block+=' }';left,right=spans[prop];edits.append((left,right,block))
 for left,right,block in sorted(edits,reverse=True):content=content[:left]+block+content[right:]
 out=mod/f'42/media/anims_X/Bob/{name}.x';out.write_text(content,encoding='utf-8')
 bep=sourceRoot/'bep'/(stem+'.bep');b=bep.read_bytes();pos=16;events=[]
 while pos+80<=len(b):
  section,kind,size=struct.unpack_from('<HHI',b,pos+64);data=b[pos+80:pos+80+size];assert len(data)==size
  if section==12 and kind in [68,75,77,206]:events.append({'kind':kind,'start':struct.unpack_from('<f',data,4)[0],'end':struct.unpack_from('<f',data,8)[0]})
  pos+=80+size
 records.append({'animation':name,'variant':variant,'source':str(src),'sourceSha256':hashlib.sha256(src.read_bytes()).hexdigest(),'bep':str(bep),'bepSha256':hashlib.sha256(b).hexdigest(),'output':out.relative_to(mod).as_posix(),'frames':[0,count-1],'fps':float(ns['a'].frame_rate),'events':events,'propGrip':'bat','retargetPath':str(path),'retargetSha256':hashlib.sha256(path.read_bytes()).hexdigest(),'sha256':hashlib.sha256(out.read_bytes()).hexdigest()})
 print('REVERSE SOURCE',name,count,events,flush=True)
links=[]
for i in range(1,5):
 first=next(r for r in records if r['variant']==f'reverse_after_{i}');second=next(r for r in records if r['variant']==f'reverse_double_after_{i}')
 fs,ff,fa,_=read(mod/first['output']);ss,sf,sa,_=read(mod/second['output']);contact=next(e for e in first['events'] if e['kind']==68);recover=next(e for e in first['events'] if e['kind']==75)['start'];secondHit=next(e for e in second['events'] if e['kind']==68)['start']
 bones=[n for n in fa if not any(k in n for k in ['Dummy','Prop','Finger','Body'])];candidates=[]
 for a in range(int(contact['end'])+1,min(first['frames'][1]-3,int(recover)+8)+1):
  for b in range(0,min(10,int(secondHit)-4)+1):
   angles=[]
   for n in bones:
    q1=Quaternion(fa[n][0][a][1]);q2=Quaternion(sa[n][0][b][1]);angles.append(math.degrees(2*math.acos(min(1,abs(q1.normalized().dot(q2.normalized()))))))
   rms=math.sqrt(sum(x*x for x in angles)/len(angles));candidates.append((rms,a,b))
 rms,exitFrame,entryFrame=min(candidates);first['doubleLinkFrame']=exitFrame;first['doubleLinkEndFrame']=min(exitFrame+3,first['frames'][1]-1)
 if entryFrame:
  def clipKeys(m):
   rows=re.findall(r'(\d+);(\d+);([^;]+);;',m[3]);new=[str(j*160)+';'+n+';'+v+';;' for j,(_,n,v) in enumerate(rows[entryFrame:])]
   return 'AnimationKey '+m[1]+' { '+m[2]+'; '+str(len(new))+';\n'+',\n'.join(new)+';\n }'
  result=re.sub(r'AnimationKey\s+(\w+)\s*\{\s*([012]);\s*\d+;(.*?)\n\s*\}',clipKeys,ss,flags=re.S);(mod/second['output']).write_text(result,encoding='utf-8');second['frames'][0]=entryFrame;second['sha256']=hashlib.sha256((mod/second['output']).read_bytes()).hexdigest()
 links.append({'branch':i,'firstExitFrame':exitFrame,'firstWindowEnd':first['doubleLinkEndFrame'],'secondEntrySourceFrame':entryFrame,'localBoneRmsDegrees':rms,'blendSeconds':.10,'operation':'Select closest existing source poses after contact; optional source-prefix trim only. Native runtime blend, no bridge frames or invented motion.'})
 print('SOURCE LINK',links[-1],flush=True)
report={'authorization':'User approved verified reverse-finisher and paired Heat Rush source retargets on 2026-10-31.','operation':'Original source body motion retained; horizontal trajectory in place and native punch finger grip. Native B42 authored hand-to-prop offset repair. Only documented leading frames of second finishers may be removed. No AI, invented poses, baked blend frames or generated visual/audio artwork.','nativeGrip':grip,'commandSource':str(sourceRoot/'command/fighter_command.cfc'),'commandSha256':hashlib.sha256((sourceRoot/'command/fighter_command.cfc').read_bytes()).hexdigest(),'commandMappings':{'Heavy_Rev':'P_KRU_BTL_SUD_ath_BKL_lf_md',**{f'AttackRevFin{i}':f'P_KRU_BTL_SUD_ath_0{i}_B_fin_md' for i in range(1,5)},**{f'AttackRevFinW{i}':f'P_KRU_BTL_SUD_ath_0{i}_B_finW_md' for i in range(1,5)}},'clips':records,'links':links}
(mod/'docs/reverse-finisher-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
