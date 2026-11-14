from pathlib import Path
import sys,json,hashlib,re,uuid,math,zipfile

root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from mathutils import Quaternion,Vector,Matrix
from locomotion_math import read,locals_at,blocks,write,world
from paired_paths import bridge_scene_cuts
from weapon_hold_geometry import fit_arms
from bat_prop_motion import prop_offsets
from read_heat_scene import read_scene

mod=root/'combat/ProjectYakuza';source=root/'extracted/bicycle-momentum-0109/h24110_c_german'
scene=read_scene(source/'cmn.par/cmn.bin');resources=(source/'000.par/res.bin').read_bytes()
bindings={str(uuid.UUID(bytes_le=resources[m.start()-28:m.start()-12])):m.group().decode()for m in re.finditer(rb'(?:h24110_000_\d|m_kiryu|c_ea_)[ -~]*',resources)}
characters=[n for n in scene['nodes']if n['category']==5];assert bindings[characters[0]['guid']]=='m_kiryu'
jobs=[]
for character,name in zip(characters,['ProjectYakuza_DD_BicycleHeat','ProjectYakuza_DD_BicycleHeatVictim']):
    motions=[n for n in scene['nodes']if n['parent']==character['offset']and n['category']==6]
    selected=motions[-1];resource=bindings[selected['guid']];jobs.append((name,source/'000.par'/(resource+'.gmt')))
assert [p.name for _,p in jobs]==['h24110_000_4.gmt','h24110_000_6.gmt']
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
    context={'FINGER_SOURCE':'Bob_AttackBat01_Hit.x','SCENE_ROTATION':rotation};exec(compile(converter,'retarget_supplied_bat_scene','exec'),context)
    assert context['a'].frame_rate==30 and context['a'].end_frame==150
    raw=root/('tools/bicycle-heat-build/ProjectYakuza/42/media/anims_X/Bob/'+name+'.x');text,bones,animation,spans=read(raw);count=151;times=[i*160 for i in range(count)];values=[locals_at(bones,animation,t)for t in times]
    fingers={n:v.copy()for n,v in values[0].items()if '_Finger'in n}
    for frame in range(count):values[frame],_=fit_arms(bones,values[frame],context['srcposes'][frame],context['bind'],fingers)
    output=mod/('42/media/anims_X/Bob/'+name+'.x');write(output,text,spans,blocks(bones,values,times,grip),name)
    if name=='ProjectYakuza_DD_BicycleHeat':
        current,bones,animation,spans=read(output);offsets,sourceOffsets=prop_offsets(context,bones,animation,count);dynamic=[]
        reference=mod/'42/media/anims_X/Bob/ProjectYakuza_DD_BicycleLight01.x';_,rb,ra,_=read(reference);rp=world(rb,locals_at(rb,ra,0));calibration=offsets[0].inverted()@rp['Bip01_R_Hand'].inverted()@rp['Bip01_Prop1']
        palm=(offsets[0]@calibration).inverted().translation;calibration=calibration@Matrix.Translation(palm)@Matrix.Rotation(math.pi/2,4,'Y')@Matrix.Translation(-palm)
        for frame,offset in enumerate(offsets):
            value=locals_at(bones,animation,times[frame]);pose=world(bones,value);value['Bip01_Prop1']=pose[bones['Bip01_Prop1']['parent']].inverted()@pose['Bip01_R_Hand']@offset@calibration;dynamic.append(value)
        write(output,current,{'Bip01_Prop1':spans['Bip01_Prop1']},{'Bip01_Prop1':blocks(bones,dynamic,times,None)['Bip01_Prop1']},name)
        propRecord={'source':str(path),'sourceSha256':sha(path),'calibration':[list(row)for row in calibration],'modelSha256':json.loads((mod/'docs/bicycle-model-assets.json').read_text())['sha256'],'modelScale':.44308598137428024,'sourceBone':'buki1_r_n','sourceHand':'ude3_r_n','targetProp':'Bip01_Prop1','frames':count,'gripReference':{'path':str(reference),'sha256':sha(reference),'frame':0},'reference':'Original Y6 held-object hit and forward jump-crush weapon bone; supplied bicycle mesh retains its right-grip origin and native scale.','operation':'Original h24110 animated buki1_r_n world rotation and hand-relative position reflected into native coordinates through the source-to-native chest/arm adaptation; the original source weapon rotation and hand-relative translation are retained with a fixed bicycle calibration derived from the supplied Y5 bicycle grip and a quarter-turn about the right palm so its long frame spans the two hands. No nearby world-object track is used.'}
    records.append({'animation':name,'source':str(path),'sourceSha256':sha(path),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'retargetSha256':sha(raw),'frames':count,'fps':30})
    vector=context['a'].bones['vector_c_n'];vectors.append([context['sample'](vector.location,f,Vector((0,0,0)))for f in range(count)])
cutFrame=97;victimOutput=mod/records[1]['output'];_,vb,va,_=read(victimOutput);before=world(vb,locals_at(vb,va,(cutFrame-1)*160))['Bip01'].to_quaternion();after=world(vb,locals_at(vb,va,cutFrame*160))['Bip01'].to_quaternion();delta=(after@before.inverted()).to_matrix();stageYaw=math.atan2(delta[0][2],delta[2][2]);assert 32<math.degrees(stageYaw)<35
for role,record in enumerate(records):
    output=mod/record['output'];text,bones,animation,spans=read(output);values=[]
    for frame in range(count):
        local=locals_at(bones,animation,frame*160)
        if frame>=cutFrame:
            phase=(frame-cutFrame)/(count-1-cutFrame);weight=1-phase*phase*(3-2*phase)if role==0 else 1;pose=world(bones,local);rootPose=pose['Bip01'];corrected=Matrix.Rotation(-stageYaw*weight,4,'Y')@rootPose;corrected.translation=rootPose.translation;parent=bones['Bip01']['parent'];local['Bip01']=pose[parent].inverted()@corrected if parent else corrected
        values.append(local)
    changes=blocks(bones,values,times,None);left,right=spans['Bip01'];originalRoot=text[left:right];pattern=r'(AnimationKey R\s*\{\s*0;\s*\d+;\s*\n)(.*?)(\n\s*\})';originalRotation=re.search(pattern,originalRoot,re.S);correctedRotation=re.search(pattern,changes['Bip01'],re.S);originalRows=originalRotation[2].splitlines();correctedRows=correctedRotation[2].splitlines();assert len(originalRows)==len(correctedRows)==count;rows=originalRows[:cutFrame]+correctedRows[cutFrame:]
    if role==0:rows[-1]=originalRows[-1]
    correctedRoot=originalRoot[:originalRotation.start(2)]+'\n'.join(rows)+originalRoot[originalRotation.end(2):];write(output,text,{'Bip01':spans['Bip01']},{'Bip01':correctedRoot},record['animation']);record['sha256']=sha(output)
anchor=vectors[0][0];factor=float(context['scale'])*1.5
rawPaths=[[[float((rotation@(v-anchor)).z*factor),float((rotation@(v-anchor)).x*factor)]for v in values]for values in vectors];paths,cuts=bridge_scene_cuts(rawPaths)
individualCuts=[]
for role,path in enumerate(paths):
    staged=[list(p)for p in path]
    for frame in range(1,len(path)):
        if math.dist(staged[frame],staged[frame-1])<=.35:continue
        shift=[staged[frame][axis]-staged[frame-1][axis]for axis in range(2)];individualCuts.append({'actor':role,'frame':frame,'translation':shift,'blendFrames':6})
        for age in range(min(6,len(path)-frame)):
            t=age/6;fade=1-t*t*(3-2*t)
            path[frame+age]=[path[frame+age][axis]-shift[axis]*fade for axis in range(2)]
report={'authorization':'User requested the held-weapon heavy-object bicycle Heat Action using the supplied installed Yakuza 6 reference. Direct original motion conversion only.','operation':'Retain all 151 source samples, including the airborne forward dive at frames 60..70, at 30 fps. Source vector elevation and rotation retained, source arm directions fitted to native PZ segment lengths, native heavy-weapon fingers retained, original buki1 right-weapon track adapted. No AI, invented poses, images, textures or models.','archive':str(source/'index.json'),'archiveSha256':None,'scene':str(source/'cmn.par/cmn.bin'),'sceneSha256':scene['sha256'],'actorAssignment':{'actor':'h24110_000_4','victim':'h24110_000_6','victimSelection':'CMN player and victim bindings select h24110_000_4 and h24110_000_6. The held heavy object follows the player buki1_r_n weapon bone, not a separate world-object motion.','nodes':[{'offset':n['offset'],'guid':n['guid'],'resource':bindings[n['guid']]}for n in scene['nodes']if n['category']in [5,6]],'weaponBone':'buki1_r_n'},'contactFrames':[29,70],'damageWeights':[500,1500],'nativeGrip':grip,'propMotion':propRecord,'pathScale':factor,'paths':paths,'rawPaths':rawPaths,'sceneCuts':cuts,'sceneRotation':list(rotation),'clips':records}
index=json.loads((source/'index.json').read_text());report['archive']=index['archive'];report['archiveSha256']=index['archiveSha256']
report['bicycleModel']={'path':'42/media/models_X/Static/ProjectYakuza_Bicycle.x','sha256':sha(mod/'42/media/models_X/Static/ProjectYakuza_Bicycle.x'),'origin':'Existing supplied Y5 low-detail held bicycle, unchanged model and texture.'}
report['sourceFrames']=list(range(151))
report['individualSceneCuts']=individualCuts
report['recoveryStageRotation']={'frame':cutFrame,'radians':stageYaw,'degrees':math.degrees(stageYaw),'referenceAnimation':records[1]['animation'],'referenceFrames':[cutFrame-1,cutFrame],'actorEndFrame':count-1,'operation':'Compensate the shared camera-cut yaw about each native root at frame 97. Keep the grounded victim heading continuous. Smoothly return the attacker correction to zero through the original recovery using a smoothstep weight, retaining the original final facing and idle handoff. Only the root rotation changes; original root translations, child-local body and weapon channels, flight, paired paths and damage timings remain unchanged.'}
retired=[];baseline=root/'dist/ProjectYakuza-B42-v0.108.0.zip'
with zipfile.ZipFile(baseline)as archive:
    for name in ['HeatScene_bicycle_5.wav','HeatScene_bicycle_379_10.wav','HeatScene_bicycle_379_12.wav']:
        relative='42/media/sound/ProjectYakuza/'+name;original=archive.read('ProjectYakuza/'+relative);path=mod/relative
        if path.exists():
            assert path.read_bytes()==original;path.unlink()
        retired.append({'path':relative,'bytes':len(original),'sha256':hashlib.sha256(original).hexdigest()})
report['retiredAudio']={'baseline':str(baseline),'sha256':sha(baseline),'files':retired}
report['retargetProvenance']=[{'path':str(p),'sha256':sha(p)}for p in [Path('E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'),Path('C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/bind.json'),Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x'),root/'tools/combat-tests/retarget_locomotion.py',root/'tools/combat-tests/weapon_hold_geometry.py',root/'tools/combat-tests/bat_prop_motion.py']]
report['retargetProvenance'].extend({'path':str(p),'sha256':sha(p)}for p in [Path(__file__),root/'tools/combat-tests/extract_bicycle_y6_assets.py'])
def literal(v):return '{'+','.join(literal(x)for x in v)+'}'if isinstance(v,list)else format(v,'.9f')
code='require "ProjectYakuza/Registry"\nProjectYakuza.PairedMotions=ProjectYakuza.PairedMotions or {}\nProjectYakuza.PairedMotions.dod_bicycle={fps=30,duration=150/30,actorAnimation="ProjectYakuza_DD_BicycleHeat",targetAnimation="ProjectYakuza_DD_BicycleHeatVictim",actor='+literal(paths[0])+',victim='+literal(paths[1])+'}\n'
(mod/'42/media/lua/shared/ProjectYakuza/BicycleHeatPaths.lua').write_bytes(code.encode())
(mod/'docs/bicycle-heat-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
media=mod/'42/media'
for group,filename in [('player/actions','ProjectYakuza_DD_KatanaHeat.xml'),('player/actions','ProjectYakuza_PVP_KatanaHeatVictim.xml'),('player/hitreactionpvp','ProjectYakuza_PVP_KatanaHeatVictim.xml'),('zombie/idle','ProjectYakuza_DD_KatanaHeatVictim.xml'),('zombie/hitreaction','ProjectYakuza_DD_KatanaHeatVictim.xml'),('zombie/hitreaction-hit','ProjectYakuza_DD_KatanaHeatVictim.xml')]:
    path=media/'AnimSets'/group/filename;text=path.read_text().replace('KatanaHeat','BicycleHeat').replace('<m_Value>blade</m_Value>','<m_Value>bicycle</m_Value>');path.with_name(filename.replace('KatanaHeat','BicycleHeat')).write_text(text,encoding='utf-8')
print('PASS 2 original held bicycle scene clips, 151 frames each, source weapon-bone motion and paired paths; cuts',cuts)
