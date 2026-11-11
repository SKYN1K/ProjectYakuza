from pathlib import Path
import sys,json,hashlib,re,uuid

root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from mathutils import Quaternion,Vector,Matrix
from locomotion_math import read,locals_at,blocks,write,world
from paired_paths import bridge_scene_cuts
from weapon_hold_geometry import fit_arms

from read_heat_scene import read_scene

mod=root/'combat/ProjectYakuza';source=root/'extracted/bicycle-y6-099/h23701_buki_f'
scene=read_scene(source/'cmn.par/cmn.bin');resources=(source/'000.par/res.bin').read_bytes()
bindings={str(uuid.UUID(bytes_le=resources[m.start()-28:m.start()-12])):m.group().decode()for m in re.finditer(rb'(?:h23701_000_\d|m_kiryu|c_ea_)[ -~]*',resources)}
characters=[n for n in scene['nodes']if n['category']==5];assert bindings[characters[0]['guid']]=='m_kiryu'
jobs=[]
for character,name in zip(characters,['ProjectYakuza_DD_BicycleHeat','ProjectYakuza_DD_BicycleHeatVictim']):
    motions=[n for n in scene['nodes']if n['parent']==character['offset']and n['category']==6]
    selected=motions[-1];resource=bindings[selected['guid']];jobs.append((name,source/'000.par'/(resource+'.gmt')))
assert [p.name for _,p in jobs]==['h23701_000_4.gmt','h23701_000_6.gmt']
converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/bicycle-heat-build'")
converter=converter.replace(' tg={}',' ab=a.bones.get("vector_c_n");vq=SCENE_ROTATION@sample(ab.rotation if ab else None,f,Quaternion((1,0,0,0)),True)\n sg={n:vq.to_matrix().to_4x4()@mat for n,mat in sg.items()}\n tg={}')
converter=converter.replace("world.y=sg['ketu_c_n'].translation.y*scale","world.y=(sg['ketu_c_n'].translation.y+sample(a.bones['vector_c_n'].location,f,Vector((0,0,0))).y)*scale")
grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];records=[];vectors=[];rotation=None;propRecord=None
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
for name,path in jobs:
    sys.argv=['convert','--',name,str(path)]
    if rotation is None:
        package=__import__('types').ModuleType('yk');package.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=package
        from yk.gmt_lib import read_gmt
        first=read_gmt(str(path)).animation.bones['vector_c_n'].rotation;first.fill_channels();v=first.keyframes[0].value;rotation=Quaternion((v[3],*v[:3])).inverted()
    context={'FINGER_SOURCE':'Bob_AttackBat01_Hit.x','SCENE_ROTATION':rotation};exec(compile(converter,'retarget_supplied_bicycle_scene','exec'),context)
    assert context['a'].frame_rate==30 and context['a'].end_frame==144
    raw=root/('tools/bicycle-heat-build/ProjectYakuza/42/media/anims_X/Bob/'+name+'.x');text,bones,animation,spans=read(raw);count=145;times=[i*160 for i in range(count)];values=[locals_at(bones,animation,t)for t in times]
    fingers={n:v.copy()for n,v in values[0].items()if '_Finger'in n}
    for frame in range(count):values[frame],_=fit_arms(bones,values[frame],context['srcposes'][frame],context['bind'],fingers)
    output=mod/('42/media/anims_X/Bob/'+name+'.x');write(output,text,spans,blocks(bones,values,times,grip),name)
    if name=='ProjectYakuza_DD_BicycleHeat':
        current,bones,animation,spans=read(output);objectSource=source/'000.par/h23701_000_7.gmt';objectAnimation=read_gmt(str(objectSource)).animation;track=objectAnimation.bones['null3']
        for curve in track.curves:
            if int(curve.type)in[0,1]:curve.fill_channels()
        sample=context['sample'];origin=sample(context['a'].bones['vector_c_n'].location,0,Vector((0,0,0)));mirror=Matrix.Diagonal((1,1,-1,1))
        def object_pose(frame):
            position=rotation@(sample(track.location,frame,Vector((0,0,0)))-origin);q=rotation@sample(track.rotation,frame,Quaternion((1,0,0,0)),True);pose=mirror@q.to_matrix().to_4x4()@mirror;pose.translation=Vector((position.x,position.y,-position.z))*context['scale'];return pose
        model=json.loads((mod/'docs/bicycle-model-assets.json').read_text());modelScale=.44308598137428024;calibration=Matrix.Translation(Vector(model['sourceAnchor'])*modelScale);initial=object_pose(0);bottom=min((initial@calibration@(Vector(v)*modelScale)).y for v in model['vertices']);calibration.translation+=initial.to_3x3().inverted()@Vector((0,-bottom,0));dynamic=[];objectMatrices=[]
        for frame in range(count):
            value=locals_at(bones,animation,times[frame]);native=world(bones,value);pose=object_pose(frame)@calibration;vector=rotation@(sample(context['a'].bones['vector_c_n'].location,frame,Vector((0,0,0)))-origin);pose.translation-=Vector((vector.x,0,-vector.z))*context['scale'];value['Bip01_Prop1']=native[bones['Bip01_Prop1']['parent']].inverted()@pose;dynamic.append(value);objectMatrices.append([list(row)for row in pose])
        write(output,current,{'Bip01_Prop1':spans['Bip01_Prop1']},{'Bip01_Prop1':blocks(bones,dynamic,times,None)['Bip01_Prop1']},name)
        propRecord={'source':str(objectSource),'sourceSha256':sha(objectSource),'sourceBone':'null3','calibration':[list(row)for row in calibration],'objectMatrices':objectMatrices,'modelScale':modelScale,'modelSha256':model['sha256'],'operation':'Original Y6 world big/heavy-object track. Restore the supplied bicycle original model origin from its right-hand rebase and seat its initial lowest vertex at floor height. Whole-model rotation/translation follows every original object sample; the existing paired controller handles horizontal actor motion.'}
    records.append({'animation':name,'source':str(path),'sourceSha256':sha(path),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'retargetSha256':sha(raw),'frames':count,'fps':30})
    vector=context['a'].bones['vector_c_n'];vectors.append([context['sample'](vector.location,f,Vector((0,0,0)))for f in range(count)])
anchor=vectors[0][0];factor=float(context['scale'])*1.5
rawPaths=[[[float((rotation@(v-anchor)).z*factor),float((rotation@(v-anchor)).x*factor)]for v in values]for values in vectors];paths,cuts=bridge_scene_cuts(rawPaths)
report={'authorization':'User requested a bicycle Heat Action using the supplied installed Yakuza 6 reference. Direct original motion conversion only.','operation':'Retain all 145 source samples at 30 fps. Source vector elevation and rotation retained, source arm directions fitted to native PZ segment lengths, native bicycle fingers retained, original buki1 right-weapon track adapted. No AI, invented poses, images, textures or models.','archive':str(source/'index.json'),'archiveSha256':None,'scene':str(source/'cmn.par/cmn.bin'),'sceneSha256':scene['sha256'],'actorAssignment':{'actor':'h23701_000_4','victim':'h23701_000_6','victimSelection':'CMN player/victim bindings select h23701_000_4 and h23701_000_6; h23701_000_7 is the independent heavy object.','nodes':[{'offset':n['offset'],'guid':n['guid'],'resource':bindings[n['guid']]}for n in scene['nodes']if n['category']in [5,6]],'weaponBone':'null3'},'contactFrames':[58],'damageWeights':[1500],'nativeGrip':grip,'propMotion':propRecord,'pathScale':factor,'paths':paths,'rawPaths':rawPaths,'sceneCuts':cuts,'sceneRotation':list(rotation),'clips':records}
index=json.loads((source/'index.json').read_text());report['archive']=index['archive'];report['archiveSha256']=index['archiveSha256']
report['sourceFrames']=list(range(145));report['objectSource']=str(objectSource);report['objectSha256']=sha(objectSource)
report['retargetProvenance']=[{'path':str(p),'sha256':sha(p)}for p in [Path('E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'),root/'tools/combat-tests/retarget_locomotion.py',root/'tools/combat-tests/weapon_hold_geometry.py']]
report['operation']='Original Yakuza 6 h23701_buki_f big/heavy-object Heat Action, all 145 samples at 30 fps including original independent object track. Supplied Y5 low-detail bicycle model/texture and ordinary attacks are retained. No generated art/audio or invented body poses.'
def literal(v):return '{'+','.join(literal(x)for x in v)+'}'if isinstance(v,list)else format(v,'.9f')
code='require "ProjectYakuza/Registry"\nProjectYakuza.PairedMotions=ProjectYakuza.PairedMotions or {}\nProjectYakuza.PairedMotions.dod_bicycle={fps=30,duration=144/30,actorAnimation="ProjectYakuza_DD_BicycleHeat",targetAnimation="ProjectYakuza_DD_BicycleHeatVictim",actor='+literal(paths[0])+',victim='+literal(paths[1])+'}\n'
(mod/'42/media/lua/shared/ProjectYakuza/BicycleHeatPaths.lua').write_bytes(code.encode())
(mod/'docs/bicycle-heat-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
media=mod/'42/media'
for group,filename in [('player/actions','ProjectYakuza_DD_KatanaHeat.xml'),('player/actions','ProjectYakuza_PVP_KatanaHeatVictim.xml'),('player/hitreactionpvp','ProjectYakuza_PVP_KatanaHeatVictim.xml'),('zombie/idle','ProjectYakuza_DD_KatanaHeatVictim.xml'),('zombie/hitreaction','ProjectYakuza_DD_KatanaHeatVictim.xml'),('zombie/hitreaction-hit','ProjectYakuza_DD_KatanaHeatVictim.xml')]:
    path=media/'AnimSets'/group/filename;text=path.read_text().replace('KatanaHeat','BicycleHeat').replace('<m_Value>blade</m_Value>','<m_Value>bicycle</m_Value>');path.with_name(filename.replace('KatanaHeat','BicycleHeat')).write_text(text,encoding='utf-8')
print('PASS 2 original bicycle scene clips, 145 frames each, source weapon-bone motion and paired paths; cuts',cuts)
