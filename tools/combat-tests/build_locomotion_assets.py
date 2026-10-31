from pathlib import Path
import sys,json,hashlib,re,math
from mathutils import Matrix,Vector,Quaternion
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,pose,locals_at,blocks,write
mod=root/'combat/ProjectYakuza';out=mod/'42/media/anims_X/Bob';native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob');source=Path('E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack/gmt')
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text();grips=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips'];records=[]
def convert(name,src,gripTag,finger):
 sys.argv=['convert','--',name,str(source/(src+'.gmt'))];ns={'FINGER_SOURCE':finger};exec(compile(converter,'retarget_locomotion.py','exec'),ns)
 path=root/('tools/locomotion-build/ProjectYakuza/42/media/anims_X/Bob/'+name+'.x');s,frames,anim,spans=read(path);count=ns['a'].end_frame+1;times=[f*160 for f in range(count)];values=[locals_at(frames,anim,t) for t in times];grip=grips[gripTag] if gripTag else None
 output=out/(name+'.x')
 record={'name':name,'output':output.relative_to(mod).as_posix(),'source':str(source/(src+'.gmt')),'sourceSha256':sha(source/(src+'.gmt')),'frames':count,'fps':30,'duration':(count-1)/30,'grip':gripTag,'fingerSource':str(native/finger),'fingerSha256':sha(native/finger),'kind':'source','retargetSha256':sha(path),'sourceSampleReport':str(root/('tools/'+name+'-source.json'))}
 if name.endswith('Run'):
  nativeRun=native/'Bob_Run.x';s,nframes,nanim,spans=read(nativeRun);end=max(t for curves in nanim.values() for keys in curves.values() for t,v in keys);merged=[]
  for i,t in enumerate(times):
   v=locals_at(nframes,nanim,t/times[-1]*end)
   for bone,value in values[i].items():
    if bone not in ['Body','Translation_Data']:v[bone]=value
   merged.append(v)
  frames=nframes;values=merged;record.update({'kind':'sourceRunNativeTravel','native':str(nativeRun),'nativeSha256':sha(nativeRun),'nativeDuration':end/4800})
 write(output,s,spans,blocks(frames,values,times,grip),name);record['sha256']=sha(output)
 _,frames,anim,_=read(output)
 records.append(record);return output,frames,anim,record
baseRun,_,_,_=convert('ProjectYakuza_DD_Run','P_KRU_MOV_run_ftl',None,'Bob_Run.x')
for family,sourceFamily,grip,finger in [('Bat','WPA','bat','Bob_AttackBat01_Hit.x'),('Knife','WPB','knife','Bob_AttackKnife01_Hit.x'),('Blade','WPN','bat','Bob_AttackBat01_Hit.x')]:
 convert('ProjectYakuza_DD_'+family+'Run','P_KRU_MOV_run_ftl',grip,finger)
 carry,cframes,canim,crecord=convert('ProjectYakuza_DD_'+family+'Carry','P_KRU_BTL_'+sourceFamily+'_stdB_lp',grip,finger)
 upper=set(['Bip01_Spine1'])
 for n,d in cframes.items():
  if d['parent'] in upper:upper.add(n)
 upper.update(['Bip01_Prop1','Bip01_Prop2'])
 for suffix,nativeName in [('Walk','Bob_WalkBat'),('Slow','Bob_WalkSlow_Bat')]:
  src=native/(nativeName+'.x');s,frames,anim,spans=read(src);ticks=int(re.search(r'AnimTicksPerSecond\s*{\s*(\d+)',s)[1]);end=max(t for curves in anim.values() for keys in curves.values() for t,v in keys);times=list(range(0,end+1,160));assert times[-1]==end and ticks==4800
  values=[]
  for t in times:
   original=locals_at(frames,anim,t);hold=locals_at(cframes,canim,t/end*(crecord['frames']*160-160))
   for n in upper:original[n]=hold[n]
   values.append(original)
  name='ProjectYakuza_DD_'+family+'Carry'+suffix;output=out/(name+'.x');write(output,s,spans,blocks(frames,values,times,grips[grip]),name)
  records.append({'name':name,'kind':'nativeLegComposite','output':output.relative_to(mod).as_posix(),'sha256':sha(output),'native':str(src),'nativeSha256':sha(src),'carry':crecord['output'],'carrySha256':sha(carry),'upperBones':sorted(upper),'frames':len(times),'fps':30,'duration':end/ticks,'grip':grip})
report={'authorization':'User explicitly approved conversion of supplied Kiryu running and weapon-hold motion on 2026-10-30.','operation':'Original Y6 full run loop and alternate unlocked weapon holds retargeted in place; native finger grips and hand-prop offsets. Running retains the native Translation_Data movement track at matched cadence. Walking variants combine existing native lower-body samples with source upper-body motion, fitting the complete source hold loop to each native walk cycle. No AI, invented motion or new artwork/audio.','clips':records,'nativeGrips':grips,'rig':'E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd','rigSha256':sha('E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd')}
(mod/'docs/locomotion-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print('EXPORTED',len(records),'running/carry/native-leg clips')

exec(compile((root/"tools/combat-tests/repair_carry_053.py").read_text(),"repair_carry_053.py","exec"))
exec(compile((root/"tools/combat-tests/adjust_run_cadence.py").read_text(),"adjust_run_cadence.py","exec"))
