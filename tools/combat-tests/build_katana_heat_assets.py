from pathlib import Path
import sys,json,hashlib,struct
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,locals_at,blocks,write
mod=root/'combat/ProjectYakuza';srcRoot=Path('E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack');converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/katana-heat-build'");grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];records=[]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
jobs=[('ProjectYakuza_DD_KatanaHeat','extracted/katana-heat-070/000.par/h23720_000_4.gmt'),('ProjectYakuza_DD_KatanaHeatVictim','extracted/katana-heat-070/000.par/h23720_000_6.gmt')]
converter=converter.replace(' tg={}', ' ab=a.bones.get("vector_c_n");vq=sample(ab.rotation if ab else None,f,Quaternion((1,0,0,0)),True)\n sg={n:vq.to_matrix().to_4x4()@mat for n,mat in sg.items()}\n tg={}')
poses=[];vectors=[]
for name,source in jobs:
 src=root/source;sys.argv=['convert','--',name,str(src)];ns={'FINGER_SOURCE':'Bob_AttackPunch01_Hit.x'};exec(compile(converter,'retarget_heat_rush','exec'),ns)
 raw=root/('tools/katana-heat-build/ProjectYakuza/42/media/anims_X/Bob/'+name+'.x');text,frames,anim,spans=read(raw);count=ns['a'].end_frame+1;times=[i*160 for i in range(count)];values=[locals_at(frames,anim,t)for t in times];output=mod/('42/media/anims_X/Bob/'+name+'.x');write(output,text,spans,blocks(frames,values,times,grip),name)
 records.append({'animation':name,'source':str(src),'sourceSha256':sha(src),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'retargetSha256':sha(raw),'frames':count,'fps':30})
 poses.append(ns['srcposes'])
 ab=ns['a'].bones.get('vector_c_n');vs=[ns['sample'](ab.location,f,ns['Vector']((0,0,0)))for f in range(count)];vectors.append(vs)
anchor=vectors[0][0];factor=float(ns['scale'])*1.5
paths=[[[float((v.z-anchor.z)*factor),float((v.x-anchor.x)*factor)]for v in values]for values in vectors]
archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/hact/h23720_buki_e.par')
scene=root/'extracted/katana-heat-070/cmn.par/cmn.bin';data=scene.read_bytes()
import re
soundFrames={}
for match in re.finditer(rb'SE_HACT_H23720[^\0]+',data):
    start,end=struct.unpack_from('<ff',data,match.start()+36);soundFrames[match.group().decode()]={'startFrame':start,'endFrame':end}
report={'authorization':'User approved conversion of the supplied original katana Heat Action on 2026-11-01.','operation':'Original 141 frames and source vector rotations retained through existing non-AI retargeting. Native PZ hand-to-prop grip preserved. No invented body motion, image, audio or model artwork.','archive':str(archive),'archiveSha256':sha(archive),'scene':str(scene),'sceneSha256':sha(scene),'actorAssignment':'cmn.bin binds res.bin m_kiryu GUID at 0x18d0 to h23720_000_4 GUID at 0x1960; enemy model at 0x1dec binds h23720_000_6 at 0x1e7c. Katana prop h23720_000_7 identifies bs_e000_type_e_tachi_1 and the scene attaches it to buki1_r_n.','soundFrames':soundFrames,'contactFrames':[20,28,54,97],'contactsOperation':'Slash, punch, thrust and body-fall scene sound starts supply presentation timings. Damage is applied at the final fall contact to preserve the full paired victim motion. The last recovery remains original.','nativeGrip':grip,'pathScale':factor,'paths':paths,'clips':records}
def literal(value):
    if isinstance(value,list):return '{'+','.join(literal(v)for v in value)+'}'
    return format(value,'.9f')
code='require "ProjectYakuza/Registry"\nProjectYakuza.PairedMotions=ProjectYakuza.PairedMotions or {}\nProjectYakuza.PairedMotions.dod_katana={fps=30,duration=140/30,actorAnimation="ProjectYakuza_DD_KatanaHeat",targetAnimation="ProjectYakuza_DD_KatanaHeatVictim",actor='+literal(paths[0])+',victim='+literal(paths[1])+'}\n'
(mod/'42/media/lua/shared/ProjectYakuza/KatanaHeatPaths.lua').write_bytes(code.encode())
(mod/'docs/katana-heat-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('KATANA_ASSETS',len(records),'original paired clips,',count,'source frames; maximum separation',max(((a[0]-b[0])**2+(a[1]-b[1])**2)**.5 for a,b in zip(paths[0],paths[1])))
