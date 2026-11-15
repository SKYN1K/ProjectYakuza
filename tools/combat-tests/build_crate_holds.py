from pathlib import Path
import sys,json,hashlib,xml.etree.ElementTree as E
from mathutils import Vector

root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;sys.path.insert(0,str(w))
from y5_retarget import convert
from y5_source_assets import entry
from locomotion_math import read,locals_at,world,blocks,write
from weapon_hold_geometry import fit_arms,source_pose
from native_body_geometry import load_body,skin_part

mod=root/'combat/ProjectYakuza';media=mod/'42/media';native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media');folder=root/'extracted/crate-hold-0116';body=load_body(native/'models_X/Skinned/MaleBody.x');sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();records=[];contexts={}
if not(folder/'index.json').exists():
 folder.mkdir(parents=True,exist_ok=True);entries=[]
 for stem in ['stand_btl_lp','stand','MOV_walk','guard_st','guard_lp','guard','guard_en']:
  name='P_WPC_'+stem+'.gmt';data,record=entry('F:/SteamLibrary/steamapps/common/Yakuza 5/main/data/motion/BattlePlayer.par',name);(folder/name).write_bytes(data);entries.append(record)
 (folder/'index.json').write_text(json.dumps(entries,indent=2)+'\n')
for stem in ['stand_btl_lp','stand','MOV_walk','guard_st','guard_lp','guard','guard_en']:
 path=folder/('P_WPC_'+stem+'.gmt');out=root/'tools/crate-hold-build'/(stem+'.x');context,raw=convert('ProjectYakuza_CrateSource_'+stem,path,out);contexts[stem]=(context,out,raw,path)

def mapped(context,frame):
 pose=source_pose(context,frame)
 for old,new in [('mune_n','mune_c_n'),('ketu_n','ketu_c_n'),('kosi_n','kosi_c_n'),('face','face_c_n')]:pose[new]=pose[old]
 return pose

walks={'Walk':'Bob_WalkBat','WalkSlow':'Bob_WalkSlow_Bat','WalkLightLimpR':'Bob_WalkLightLimpR_Bat','WalkLightLimpL':'Bob_WalkLightLimpL_Bat','WalkHeavyLimpR':'Bob_WalkHeavyLimpR_Bat','WalkHeavyLimpL':'Bob_WalkHeavyLimpL_Bat'}
jobs=[('Ready','stand_btl_lp','Bob_IdleAimBat'),('RelaxedIdle','stand','Bob_IdleBat')]+[(label,'MOV_walk',base)for label,base in walks.items()]
for label,stem,baseName in jobs:
 context,converted,raw,path=contexts[stem];sourceCount=context['a'].end_frame+1;base=(media/'anims_X/Bob'if baseName.startswith('Project')else native/'anims_X/Bob')/(baseName+'.x');text,bones,animation,spans=read(base);end=max(t for channels in animation.values()for keys in channels.values()for t,_ in keys);count=sourceCount if label in ['Ready','RelaxedIdle']else round(end/160)+1;fingers={n:v for n,v in locals_at(*read(converted)[1:3],0).items()if '_Finger'in n};values=[]
 for frame in range(count):
  t=frame*160;local=locals_at(bones,animation,t%end if label in ['Ready','RelaxedIdle']else t);local,_=fit_arms(bones,local,mapped(context,frame*(sourceCount-1)/(count-1)),context['bind'],fingers);pose=world(bones,local);points=skin_part(body,pose,['Bip01_R_Hand']);prop=pose['Bip01_Prop1'].copy();prop.translation=sum(points,Vector())/len(points);local['Bip01_Prop1']=pose[bones['Bip01_Prop1']['parent']].inverted()@prop;values.append(local)
 name='ProjectYakuza_DD_Crate'+label;output=media/'anims_X/Bob'/(name+'.x');changes=blocks(bones,values,[i*160 for i in range(count)],None);selected=spans if label in ['Ready','RelaxedIdle']else{n:span for n,span in spans.items()if any(part in n for part in ['Clavicle','UpperArm','Forearm','Hand','Finger','Prop'])};write(output,text,selected,{n:changes[n]for n in selected},name);records.append({'source':str(path),'sourceSha256':sha(path),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'frames':count,'sourceFrames':sourceCount,'nativeBase':str(base),'nativeBaseSha256':sha(base),'fps':30})
for label,stem in [('GuardEnter','guard_st'),('GuardLoop','guard_lp'),('GuardHit','guard'),('GuardExit','guard_en')]:
 context,converted,raw,path=contexts[stem];output=media/'anims_X/Bob'/('ProjectYakuza_DD_Crate'+label+'.x');text,bones,animation,spans=read(converted);write(output,text,{}, {},output.stem);records.append({'source':str(path),'sourceSha256':sha(path),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'frames':context['a'].end_frame+1,'fps':30})
for group,source,destination in [('aim','BicycleIdle','CrateIdle'),('aim-strafe','BicycleIdle','CrateIdle'),('idle','BicycleRelaxedIdle','CrateRelaxedIdle'),('movement','BicycleWalk','CrateWalk')]:
 src=media/'AnimSets/player'/group/('ProjectYakuza_DD_'+source+'.xml');text=src.read_text().replace('Bicycle','Crate').replace('<m_Value>bicycle</m_Value>','<m_Value>crate</m_Value>');(src.parent/('ProjectYakuza_DD_'+destination+'.xml')).write_text(text)
report={'operation':'Supplied Yakuza 5 WPC ready/relaxed holds, walking arms and guards. Native PZ idle and walking leg/deferred-motion channels remain unchanged; source arms are phase-mapped to each complete native walking cycle. Five existing ordinary Y5 attacks remain unchanged. No new source poses, models, texture pixels or sounds.','archiveEntries':json.loads((folder/'index.json').read_text()),'clips':records,'nativeBodySha256':sha(body['path'])};(mod/'docs/crate-hold-assets.json').write_text(json.dumps(report,indent=2)+'\n');print('PASS Yakuza 5 crate holds, six native walking cycles, retained travel and original guards:',len(records))
