from pathlib import Path
import sys,json,hashlib,types,math
from mathutils import Matrix,Vector,Quaternion

root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;sys.path.insert(0,str(w));mod=root/'emotes/ProjectYakuzaEmotes';name='ProjectYakuza_LauSpearGround';native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media');rig=root/'extracted/kiwami-entry-099/c_cm_bone.gmd';selection=json.loads((root/'extracted/lau-spear-emote/selection.json').read_text(encoding='utf-8'));source=Path(selection['segments'][0]['selection']['actor']['path']);sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
package=types.ModuleType('yk');package.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=package
from yk.gmt_lib import read_gmt
from yk.read_gmd import read_gmd_bones
from locomotion_math import read,locals_at,world,blocks,write
from weapon_hold_geometry import source_pose,fit_arms
from native_body_geometry import load_body,skin_part
from extract_lau_spear_emote import mesh_vertices

def yaw():
    track=read_gmt(str(source)).animation.bones['vector_c_n'];track.rotation.fill_channels();value=track.rotation.keyframes[0].value;q=Quaternion((value[3],*value[:3]));direction=q@Vector((0,0,1));direction.y=0;return direction.normalized().rotation_difference(Vector((0,0,1)))

def context_for(prefix=False,segment=0):
    rigBones=read_gmd_bones(str(rig));bind={}
    for bone in rigBones:
        local=Matrix.Translation(Vector(bone.local_pos[:3]))@Quaternion((bone.local_rot[3],*bone.local_rot[:3])).to_matrix().to_4x4();bind[bone.name]=bind[rigBones[bone.parent_index].name]@local if bone.parent_index>=0 else local
    converter=(w/'retarget_locomotion.py').read_text(encoding='utf-8').replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/lau-emote-build-0107'").replace("r'E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'",repr(str(rig))).replace("scale=bind['Bip01_Pelvis'].translation.y/1.14","scale=bind['Bip01_Pelvis'].translation.y/SOURCE_PELVIS_HEIGHT").replace(' tg={}',' sg={bone:SOURCE_ROTATION.to_matrix().to_4x4()@pose for bone,pose in sg.items()}\n tg={}')
    if prefix:converter=converter.split('poses=[];srcposes=[]')[0]
    context={'FINGER_SOURCE':'Bob_IdleAimSpear.x','SOURCE_PELVIS_HEIGHT':bind['ketu_c_n'].translation.y,'SOURCE_ROTATION':yaw()};saved=sys.argv;sys.argv=['convert','--',name+('_Continuation'if segment else''),selection['segments'][segment]['selection']['actor']['path']];exec(compile(converter,'supplied_kiwami_lau_spear_ground','exec'),context);sys.argv=saved;return context

def lift_hand(bones,values,delta):
    pose=world(bones,values);upper='Bip01_R_UpperArm';fore='Bip01_R_Forearm';hand='Bip01_R_Hand';start=pose[upper].translation;elbow=pose[fore].translation;target=pose[hand].translation+Vector((0,delta,0));a=(elbow-start).length;b=(pose[hand].translation-elbow).length;direction=(target-start).normalized();distance=(target-start).length;assert abs(a-b)<distance<a+b
    pole=elbow-start-direction*(elbow-start).dot(direction);assert pole.length>.000001;pole.normalize();along=(a*a-b*b+distance*distance)/(2*distance);middle=start+direction*along+pole*math.sqrt(max(0,a*a-along*along));rotations={upper:(pose[fore].translation-start).rotation_difference(middle-start)@pose[upper].to_quaternion(),fore:(pose[hand].translation-elbow).rotation_difference(target-middle)@pose[fore].to_quaternion(),hand:pose[hand].to_quaternion()};actual={}
    for bone,data in bones.items():
        parent=data['parent']
        if bone in rotations:
            rotation=rotations[bone].to_matrix().to_4x4();local=actual[parent].inverted()@rotation if parent else rotation;local.translation=values[bone].translation;values[bone]=local
        actual[bone]=actual[parent]@values[bone]if parent else values[bone]
    assert (actual[hand].translation-target).length<.00002

def build():
    contexts=[context_for(segment=i)for i in range(2)];raws=[root/'tools/lau-emote-build-0107/ProjectYakuza/42/media/anims_X/Bob'/(name+('_Continuation'if i else'')+'.x')for i in range(2)];parsed=[read(p)for p in raws];text,bones,_,spans=parsed[0];samples=[{'segment':i,'frame':f}for i,segment in enumerate(selection['segments'])for f in range(segment['firstFrame'],segment['lastFrame']+1)];values=[locals_at(bones,parsed[s['segment']][2],s['frame']*160)for s in samples];assert len(values)==154 and all(c['a'].frame_rate==30 for c in contexts);fingers={n:v.copy()for n,v in values[0].items()if '_Finger'in n};reference=native/'anims_X/Bob/Bob_IdleAimSpear.x';_,gb,ga,_=read(reference);g=world(gb,locals_at(gb,ga,0));grips={prop:g[hand].inverted()@g[prop]for hand,prop in [('Bip01_R_Hand','Bip01_Prop1'),('Bip01_L_Hand','Bip01_Prop2')]};mirror=Matrix.Diagonal((1,1,-1,1));palm=grips['Bip01_Prop1'].translation;rightGripQ=grips['Bip01_Prop1'].to_quaternion();props=[read_gmt(segment['selection']['spear']['path']).animation.bones['anm_root']for segment in selection['segments']]
    for prop in props:
        for curve in prop.curves:
            if int(curve.type)in(0,1):curve.fill_channels()
    bodyPath=native/'models_X/Skinned/MaleBody.x';body=load_body(bodyPath);idle=native/'anims_X/Bob/Bob_Idle.x';_,ib,ia,_=read(idle);feet=['Bip01_L_Foot','Bip01_R_Foot','Bip01_L_Toe0','Bip01_R_Toe0'];floor=min(p.y for p in skin_part(body,world(ib,locals_at(ib,ia,0)),feet));corrections=[];weapons=[];sourceGrips=[]
    for i,sample in enumerate(samples):
        frame=sample['frame'];context=contexts[sample['segment']];prop=props[sample['segment']];sourcePose=context['srcposes'][frame];values[i],_=fit_arms(bones,values[i],sourcePose,context['bind'],fingers);pose=world(bones,values[i]);chest=(mirror@sourcePose['mune_c_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion();adapt=pose['Bip01_Spine1'].to_quaternion()@chest.inverted();q=context['sample'](prop.rotation,frame,Quaternion((1,0,0,0)),True);weapon=adapt@(mirror@(context['SOURCE_ROTATION']@q).to_matrix().to_4x4()@mirror).to_quaternion();parent=bones['Bip01_R_Hand']['parent'];translation=values[i]['Bip01_R_Hand'].translation.copy();values[i]['Bip01_R_Hand']=(pose[parent].to_quaternion().inverted()@weapon@rightGripQ.inverted()).to_matrix().to_4x4();values[i]['Bip01_R_Hand'].translation=translation
        pose=world(bones,values[i]);delta=floor-min(p.y for p in skin_part(body,pose,feet));parent=bones['Bip01']['parent'];values[i]['Bip01'].translation+=pose[parent].inverted().to_3x3()@Vector((0,delta,0))if parent else Vector((0,delta,0));corrections.append(delta);weapons.append(weapon)
        rawPose=source_pose(context,frame);center=context['sample'](context['a'].bones['center_c_n'].location,frame,Vector((0,0,0)));propOriginal=Matrix.Translation(context['sample'](prop.location,frame,Vector((0,0,0))))@q.to_matrix().to_4x4();sourceGrips.append(propOriginal.inverted()@(rawPose['ude3_r_n'].translation+center))
    impact=selection['contactFrame']-selection['segments'][0]['firstFrame'];template=mod/'42/media/AnimSets/player/emote/ProjectYakuza_MajimaBatPoint.xml';outputs=[]
    for profile in selection['nativeProfiles']['items']:
        clip=profile['clip'];vertices=[Vector(v)for v in mesh_vertices(profile['mesh'])];pose=world(bones,values[impact]);axis=weapons[impact]@Vector((0,1,0));baseGrip=((pose['Bip01_R_Hand']@palm).y+min((weapons[impact]@p).y for p in vertices)-floor)/axis.y;offsets=[];slides=[];heights=[];adjustments=[];lifts=[];poses=[{n:m.copy()for n,m in v.items()}for v in values];low=profile['bounds'][1][0]+.02;high=profile['bounds'][1][1]-.04
        for i,frame in enumerate(samples):
            pose=world(bones,poses[i]);weapon=weapons[i];axis=weapon@Vector((0,1,0));palmWorld=pose['Bip01_R_Hand']@palm;gripY=baseGrip+(sourceGrips[i].y-sourceGrips[impact].y)*contexts[0]['scale'];gripY=max(low,min(high,gripY));bottom=palmWorld.y+min((weapon@p).y for p in vertices)-axis.y*gripY;correction=0
            if bottom<floor and abs(axis.y)>.25:correction=(bottom-floor)/axis.y;gripY=max(low,min(high,gripY+correction))
            bottom=palmWorld.y+min((weapon@p).y for p in vertices)-axis.y*gripY;lift=max(0,floor-bottom);assert lift<.12
            if lift>.0000001:lift_hand(bones,poses[i],lift);pose=world(bones,poses[i]);palmWorld=pose['Bip01_R_Hand']@palm
            assert low-.0001<=gripY<=high+.0001,(profile['item'],i,gripY,low,high)
            matrix=weapon.to_matrix().to_4x4();matrix.translation=palmWorld-weapon@Vector((0,gripY,0));parent=bones['Bip01_Prop1']['parent'];poses[i]['Bip01_Prop1']=pose[parent].inverted()@matrix;parent=bones['Bip01_Prop2']['parent'];poses[i]['Bip01_Prop2']=pose[parent].inverted()@pose['Bip01_L_Hand']@grips['Bip01_Prop2'];offsets.append(pose['Bip01_R_Hand'].inverted()@matrix);slides.append(gripY);heights.append(min((matrix@p).y for p in vertices));adjustments.append(correction);lifts.append(lift)
        output=mod/'42/media/anims_X/Bob'/(clip+'.x');write(output,text,spans,blocks(bones,poses,[i*160 for i in range(len(samples))],None),clip);selector=template.with_name(clip+'.xml');selector.write_text(template.read_text(encoding='utf-8').replace('ProjectYakuza_MajimaBatPoint',clip),encoding='utf-8');outputs.append({'item':profile['item'],'clip':clip,'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'selector':selector.relative_to(mod).as_posix(),'selectorSha256':sha(selector),'shaftRange':[low,high],'baseShaftY':baseGrip,'shaftY':slides,'floorSlideCorrection':adjustments,'armLift':lifts,'nativeOffsets':[[list(row)for row in m]for m in offsets],'spearMinY':heights});print('CALIBRATED',profile['item'],'floor',heights[impact],'minimum',min(heights),'arm clearance',max(lifts),flush=True)
    items=selection['nativeProfiles']['items'];code='ProjectYakuzaEmotes=ProjectYakuzaEmotes or {}\nProjectYakuzaEmotes.VERSION="0.1.0"\nProjectYakuzaEmotes.EmoteSpears={'+','.join('['+json.dumps(p['item'])+']=true'for p in items)+'}\nProjectYakuzaEmotes.SpearClips={'+','.join('['+json.dumps(p['item'])+']='+json.dumps(p['clip'])for p in items)+'}\n';(mod/'42/media/lua/shared/ProjectYakuzaEmotes/EmoteSpears.lua').write_text(code,encoding='utf-8')
    references=[Path(__file__),w/'extract_lau_spear_emote.py',w/'extract_majima_bat_emote.py',w/'retarget_locomotion.py',w/'weapon_hold_geometry.py',w/'native_body_geometry.py',Path('C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/bind.json'),bodyPath,idle,reference,template]
    report={'operation':'Original cutscene floor strike and complete 2.5-second continuation from the matching next-cut boundary. Original actor and independent prop timing/rotation retained. Native proportions, idle fingers, grounded soles, per-native-mesh shaft/floor calibration and bounded two-bone arm clearance adapt the supplied motion. Modded spear-class weapons use the crafted-spear fallback. No invented motion samples, textures, sound or models.','selection':selection,'sourceSamples':samples,'frames':154,'fps':30,'duration':5.1,'extensionSeconds':2.5,'rig':str(rig),'rigSha256':sha(rig),'retargets':[{'path':str(p),'sha256':sha(p)}for p in raws],'sourceYaw':list(contexts[0]['SOURCE_ROTATION']),'ground':{'floor':floor,'feet':feet,'corrections':corrections},'grip':{'source':str(reference),'offsets':{p:[list(row)for row in m]for p,m in grips.items()},'palm':list(palm),'sourceShaftPoints':[list(v)for v in sourceGrips]},'weaponRotations':[list(q)for q in weapons],'outputs':outputs,'provenance':[{'path':str(p),'sha256':sha(p)}for p in references]}
    (mod/'docs/lau-spear-emote-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print('PASS original Lau continuation: 154 samples, 5.1 seconds, 22 native spear calibrations')

if __name__=='__main__':build()
