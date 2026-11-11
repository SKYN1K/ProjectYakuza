from pathlib import Path
import sys,json,hashlib,uuid,re

root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from mathutils import Matrix,Vector,Quaternion
from y5_retarget import provenance,convert,read_gmt
from locomotion_math import read,locals_at,world,blocks,write
mod=root/'combat/ProjectYakuza';media=mod/'42/media';source=root/'extracted/bicycle-heat-097/h11010_jitensha';records=[];vectors=[];mapping=list(range(125,309));grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];mirror=Matrix.Diagonal((1,1,-1,1))
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
obj=read_gmt(str(source/'000.par/h11010_000_7.gmt')).animation
for bone in obj.bones.values():
    for curve in bone.curves:
        if int(curve.type)in [0,1]:curve.fill_channels()
anchor=Vector(json.loads((mod/'docs/bicycle-model-assets.json').read_text())['sourceAnchor'])
contexts=[];data=[]
for suffix,name in [('1','ProjectYakuza_DD_BicycleHeat'),('3','ProjectYakuza_DD_BicycleHeatVictim')]:
    path=source/'000.par'/('h11010_000_'+suffix+'.gmt');out=media/'anims_X/Bob'/(name+'.x');context,raw=convert(name,path,out);contexts.append(context)
    text,bones,animation,spans=read(out);values=[locals_at(bones,animation,f*160)for f in mapping]
    for value in values:
        native=world(bones,value);value['Bip01_Prop2']=native[bones['Bip01_Prop2']['parent']].inverted()@native['Bip01_L_Hand']@Matrix(grip['authoredOffsets']['Bip01_Prop2'])
    centre=context['a'].bones['center_n'];vectors.append([context['sample'](centre.location,f,Vector((0,0,0)))for f in mapping]);data.append((out,text,bones,animation,spans,values,raw,path))
factor=float(contexts[0]['scale']);grid=factor*1.5;origin=vectors[0][0];paths=[[[float((v-origin).z*grid),float((v-origin).x*grid)]for v in values]for values in vectors]
for role,(out,text,bones,animation,spans,values,raw,path)in enumerate(data):
    if role==0:
        sample=contexts[0]['sample'];track=obj.bones['root'];objectMatrices=[]
        for frame,value in zip(mapping,values):
            position=sample(track.location,frame,Vector((0,0,0)));rotation=sample(track.rotation,frame,Quaternion((1,0,0,0)),True);pose=mirror@rotation.to_matrix().to_4x4()@mirror
            position+=rotation@anchor;pose.translation=Vector(((position.x-origin.x)*factor,position.y*factor,-(position.z-origin.z)*factor));actorPath=paths[0][frame-mapping[0]];pose.translation-=Vector((actorPath[1]/1.5,0,-actorPath[0]/1.5));native=world(bones,value);value['Bip01_Prop1']=native[bones['Bip01_Prop1']['parent']].inverted()@pose;objectMatrices.append([list(row)for row in pose])
        write(out,text,spans,blocks(bones,values,[i*160 for i in range(len(mapping))],None),out.stem)
    else:write(out,text,spans,blocks(bones,values,[i*160 for i in range(len(mapping))],grip),out.stem)
    records.append({'role':role,'source':str(path),'sourceSha256':sha(path),'retarget':str(raw),'retargetSha256':sha(raw),'output':out.relative_to(mod).as_posix(),'sha256':sha(out),'frames':len(mapping),'sourceFrames':mapping,'fps':30})
index=json.loads((source/'index.json').read_text());report={'operation':'Original Y5 bicycle strike and complete recovery section, source frames 125..308 at original 30 fps. Long cinematic approach is excluded for nearby-target gameplay; no poses or trajectories synthesized. Whole-bicycle source root track drives the supplied static low-detail model; individual wheel/pedal rotations and physics fragments are not recreated.','archive':index['archive'],'archiveSha256':index['archiveSha256'],'scene':str(source/'cmn.par/cmn.bin'),'sceneSha256':sha(source/'cmn.par/cmn.bin'),'clips':records,'sourceFrames':mapping,'contactFrames':[6,33],'originalDamageFrames':[131,158],'damageWeights':[100,100],'objectSource':str(source/'000.par/h11010_000_7.gmt'),'objectSha256':sha(source/'000.par/h11010_000_7.gmt'),'objectMatrices':objectMatrices,'paths':paths,'pathScale':grid,'modelScale':factor,'sourceAnchor':list(anchor),'nativeGrip':grip}
report['retargetProvenance']=provenance()
(mod/'docs/bicycle-heat-assets.json').write_text(json.dumps(report,indent=2)+'\n')
def literal(v):return '{'+','.join(literal(x)for x in v)+'}'if isinstance(v,list)else format(v,'.9f')
code='require "ProjectYakuza/Registry"\nProjectYakuza.PairedMotions=ProjectYakuza.PairedMotions or {}\nProjectYakuza.PairedMotions.dod_bicycle={fps=30,duration=183/30,actorAnimation="ProjectYakuza_DD_BicycleHeat",targetAnimation="ProjectYakuza_DD_BicycleHeatVictim",actor='+literal(paths[0])+',victim='+literal(paths[1])+'}\n'
(media/'lua/shared/ProjectYakuza/BicycleHeatPaths.lua').write_text(code)
for group,filename in [('player/actions','ProjectYakuza_DD_BatHeat.xml'),('player/actions','ProjectYakuza_PVP_BatHeatVictim.xml'),('player/hitreactionpvp','ProjectYakuza_PVP_BatHeatVictim.xml'),('zombie/idle','ProjectYakuza_DD_BatHeatVictim.xml'),('zombie/hitreaction','ProjectYakuza_DD_BatHeatVictim.xml'),('zombie/hitreaction-hit','ProjectYakuza_DD_BatHeatVictim.xml')]:
    path=media/'AnimSets'/group/filename;text=path.read_text().replace('BatHeat','BicycleHeat').replace('<m_Value>bat</m_Value>','<m_Value>bicycle</m_Value>');path.with_name(filename.replace('BatHeat','BicycleHeat')).write_text(text)
print('PASS 2 original Y5 bicycle strike/recovery clips,',len(mapping),'source frames each; model scale',factor,'maximum paired separation',max(((a[0]-b[0])**2+(a[1]-b[1])**2)**.5 for a,b in zip(*paths)))
