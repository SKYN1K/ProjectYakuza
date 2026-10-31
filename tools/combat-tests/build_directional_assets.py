from pathlib import Path
import sys,json,hashlib,struct
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,locals_at,blocks,write
mod=root/'combat/ProjectYakuza';srcRoot=Path('E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack');converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/directional-build'");grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];records=[]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
jobs=[('Left','P_KRU_BTL_SUD_ath_BBL_lf_md','Bip01_L_Hand'),('Right','P_KRU_BTL_SUD_ath_BBR_lf_md','Bip01_R_Hand'),('Rear','P_KRU_BTL_SUD_ath_BKL_lf_md','Bip01_L_Foot')]
for label,stem,limb in jobs:
 name='ProjectYakuza_DD_Directional'+label;src=srcRoot/'gmt'/(stem+'.gmt');sys.argv=['convert','--',name,str(src)];ns={'FINGER_SOURCE':'Bob_AttackPunch01_Hit.x'};exec(compile(converter,'retarget_directional_source','exec'),ns)
 raw=root/('tools/directional-build/ProjectYakuza/42/media/anims_X/Bob/'+name+'.x');text,frames,anim,spans=read(raw);count=ns['a'].end_frame+1
 bep=srcRoot/'bep'/(stem+'.bep');data=bep.read_bytes();pos=16;events=[]
 while pos+80<=len(data):
  section,kind,size=struct.unpack_from('<HHI',data,pos+64);value=data[pos+80:pos+80+size];assert len(value)==size
  if section==12 and kind in [68,75,77] and len(value)>=12:events.append({'kind':kind,'start':struct.unpack_from('<f',value,4)[0],'end':struct.unpack_from('<f',value,8)[0]})
  pos+=80+size
 contacts=[int(e['start'])for e in events if e['kind']==68];assert len(contacts)==1
 contact=contacts[0];times=[i*160 for i in range(count)];values=[locals_at(frames,anim,t)for t in times]
 output=mod/('42/media/anims_X/Bob/'+name+'.x');write(output,text,spans,blocks(frames,values,times,grip),name)
 record={'animation':name,'direction':label.lower(),'source':str(src),'sourceSha256':sha(src),'bep':str(bep),'bepSha256':sha(bep),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'retargetSha256':sha(raw),'frames':count,'fps':30,'events':events,'contactFrame':contact}
 records.append(record);print(label,'frames',count,'contacts',contacts)
command=srcRoot/'command/fighter_command.cfc';mapping={'AttackRevL':'P_KRU_BTL_SUD_ath_BBL_lf_md','AttackRevR':'P_KRU_BTL_SUD_ath_BBR_lf_md','Heavy_Rev':'P_KRU_BTL_SUD_ath_BKL_lf_md'}
for key,value in mapping.items():assert (key+'\0'+value+'\0').encode()in command.read_bytes()
report={'authorization':'User explicitly approved supplied Kiryu side/rear clip retargets on 2026-10-31.','operation':'All supplied frames retained in place with native punch fingers and native hand-prop offsets. Original source body poses, root rotations and timing are retained by the existing retargeter. No AI, invented motion or image/audio generation.','rig':'E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd','rigSha256':sha('E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'),'nativeGrip':grip,'nativeFingerSource':str(Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob/Bob_AttackPunch01_Hit.x')),'nativeFingerSha256':sha('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob/Bob_AttackPunch01_Hit.x'),'commandSource':str(command),'commandSha256':sha(command),'commandMappings':mapping,'clips':records}
(mod/'docs/directional-attack-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
