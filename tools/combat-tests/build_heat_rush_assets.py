from pathlib import Path
import sys,json,hashlib,struct
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,locals_at,blocks,write
mod=root/'combat/ProjectYakuza';srcRoot=Path('E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack');converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/boost-build'");grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];records=[]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
jobs=[('ProjectYakuza_DD_HeatRush','extracted/heat-rush-059/h23590_3combo/000.par/h23590_000_4.gmt'),('ProjectYakuza_DD_HeatRushVictim','extracted/heat-rush-059/h23590_3combo/000.par/h23590_000_2.gmt')]
converter=converter.replace(' tg={}', ' ab=a.bones.get("vector_c_n");vq=sample(ab.rotation if ab else None,f,Quaternion((1,0,0,0)),True)\n sg={n:vq.to_matrix().to_4x4()@mat for n,mat in sg.items()}\n tg={}')
poses=[];vectors=[]
for name,source in jobs:
 src=root/source;sys.argv=['convert','--',name,str(src)];ns={'FINGER_SOURCE':'Bob_AttackPunch01_Hit.x'};exec(compile(converter,'retarget_heat_rush','exec'),ns)
 raw=root/('tools/boost-build/ProjectYakuza/42/media/anims_X/Bob/'+name+'.x');text,frames,anim,spans=read(raw);count=ns['a'].end_frame+1;times=[i*160 for i in range(count)];values=[locals_at(frames,anim,t)for t in times];output=mod/('42/media/anims_X/Bob/'+name+'.x');write(output,text,spans,blocks(frames,values,times,grip),name)
 records.append({'animation':name,'source':str(src),'sourceSha256':sha(src),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'retargetSha256':sha(raw),'frames':count,'fps':30})
 poses.append(ns['srcposes'])
 ab=ns['a'].bones.get('vector_c_n');vs=[ns['sample'](ab.location,f,ns['Vector']((0,0,0)))for f in range(count)];vectors.append(vs)
for limb in ['ude3_r_n','ude3_l_n']:
 ds=[min((poses[0][i][limb].translation+vectors[0][i]-poses[1][i][bone].translation-vectors[1][i]).length for bone in ['face_c_n','kubi_c_n','mune_c_n']if bone in poses[1][i])for i in range(count)]
 print(limb,[(i,round(d,3))for i,d in enumerate(ds)if 0<i<count-1 and d<ds[i-1]and d<ds[i+1]])
anchor=vectors[0][0];factor=float(ns['scale'])*1.5
paths=[[[float((v.z-anchor.z)*factor),float((v.x-anchor.x)*factor)]for v in values]for values in vectors]
report={'paths':paths,'pathScale':factor,'authorization':'User approved verified original reverse-finisher and Extreme Heat Rush paired source conversion on 2026-10-31.','archive':'F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/hact/h23590_3combo.par','archiveSha256':sha('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/hact/h23590_3combo.par'),'actorAssignment':'res.bin m_kiryu with am_kiryu_1_c001 animation actor 4; ccm_com_suit_face_1_c001 victim actor 2.','nativeGrip':grip,'clips':records}
def literal(x):
 if isinstance(x,list):return '{'+','.join(literal(v)for v in x)+'}'
 return format(x,'.7f')
code='require "ProjectYakuza/Registry"\nProjectYakuza.HeatRushPaths={fps=30,actor='+literal(paths[0])+',victim='+literal(paths[1])+'}\n'
(mod/'42/media/lua/shared/ProjectYakuza/HeatRushPaths.lua').write_text(code,encoding='utf-8')
(mod/'docs/heat-rush-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
