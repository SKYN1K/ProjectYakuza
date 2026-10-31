from pathlib import Path
import sys,json,hashlib,struct
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,locals_at,blocks,write
mod=root/'combat/ProjectYakuza';srcRoot=Path('E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack');converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/boost-build'");grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];records=[]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
jobs=[('ProjectYakuza_DD_BoostLight0'+str(i),'P_KRU_BTL_SUD_bct_ath_0'+str(i))for i in range(1,5)]
for name,stem in jobs:
 src=srcRoot/'gmt'/(stem+'.gmt');sys.argv=['convert','--',name,str(src)];ns={'FINGER_SOURCE':'Bob_AttackPunch01_Hit.x'};exec(compile(converter,'retarget_boost_source','exec'),ns)
 raw=root/('tools/boost-build/ProjectYakuza/42/media/anims_X/Bob/'+name+'.x');text,frames,anim,spans=read(raw);count=ns['a'].end_frame+1;times=[i*160 for i in range(count)];values=[locals_at(frames,anim,t)for t in times];output=mod/('42/media/anims_X/Bob/'+name+'.x');write(output,text,spans,blocks(frames,values,times,grip),name)
 bep=srcRoot/'bep'/(stem+'.bep');data=bep.read_bytes();pos=16;events=[]
 while pos+80<=len(data):
  section,kind,size=struct.unpack_from('<HHI',data,pos+64);value=data[pos+80:pos+80+size];assert len(value)==size
  if section==12 and kind in [68,75,77] and len(value)>=12:events.append({'kind':kind,'start':struct.unpack_from('<f',value,4)[0],'end':struct.unpack_from('<f',value,8)[0]})
  pos+=80+size
 records.append({'animation':name,'source':str(src),'sourceSha256':sha(src),'bep':str(bep),'bepSha256':sha(bep),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'retargetSha256':sha(raw),'frames':count,'fps':30,'events':events,'contacts':[int(e['start'])for e in events if e['kind']==68]})
report={'authorization':'User explicitly approved supplied Kiryu bct_ath boost conversion on 2026-10-31.','operation':'All original source frames retained in place with native punch finger pose and native hand-prop offsets. No AI, invented poses, new textures or audio. Only the four ordinary boost lights are exported.','nativeGrip':grip,'rig':'E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd','rigSha256':sha('E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'),'clips':records}
(mod/'docs/boost-attack-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print('EXPORTED',len(records),'verified boost clips')
