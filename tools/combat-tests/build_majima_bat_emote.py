from pathlib import Path
import sys,json,hashlib,types,xml.etree.ElementTree as E
from mathutils import Matrix,Vector,Quaternion

root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;sys.path.insert(0,str(w));mod=root/'emotes/ProjectYakuzaEmotes';name='ProjectYakuza_MajimaBatPoint';identifier='ProjectYakuza_MajimaBatPoint'
package=types.ModuleType('yk');package.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=package
from yk.gmt_lib import read_gmt
from yk.read_gmd import read_gmd_bones
from locomotion_math import read,locals_at,world,blocks,write
from weapon_hold_geometry import source_pose,fit_arms
from native_body_geometry import load_body,skin_part
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
selection=json.loads((root/'extracted/majima-bat-emote/selection.json').read_text());source=Path(selection['selection']['actor']['path']);propSource=Path(selection['selection']['bat']['path']);rig=root/'extracted/kiwami-entry-099/c_cm_bone.gmd'

def context_for(prefix=False):
    rigBones=read_gmd_bones(str(rig));rigWorld={}
    for bone in rigBones:
        local=Matrix.Translation(Vector(bone.local_pos[:3]))@Quaternion((bone.local_rot[3],*bone.local_rot[:3])).to_matrix().to_4x4();rigWorld[bone.name]=rigWorld[rigBones[bone.parent_index].name]@local if bone.parent_index>=0 else local
    converter=(w/'retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/majima-emote-build-0104'").replace("r'E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'",repr(str(rig))).replace("scale=bind['Bip01_Pelvis'].translation.y/1.14","scale=bind['Bip01_Pelvis'].translation.y/SOURCE_PELVIS_HEIGHT").replace(' tg={}',' sg={bone:SOURCE_ROTATION.to_matrix().to_4x4()@pose for bone,pose in sg.items()}\n tg={}')
    if prefix:converter=converter.split('poses=[];srcposes=[]')[0]
    context={'FINGER_SOURCE':'Bob_AttackBat01_Hit.x','SOURCE_PELVIS_HEIGHT':rigWorld['ketu_c_n'].translation.y,'SOURCE_ROTATION':rotation()};saved=sys.argv;sys.argv=['convert','--',name,str(source)];exec(compile(converter,'supplied_kiwami_majima_bat_point','exec'),context);sys.argv=saved;return context

def rotation():
    track=read_gmt(str(propSource)).animation.bones['anm_root'];curve=track.rotation;curve.fill_channels();keys=curve.keyframes;frame=selection['pointFrame']
    for left,right in zip(keys,keys[1:]):
        if left.frame<=frame<=right.frame:
            a=Quaternion((left.value[3],*left.value[:3]));b=Quaternion((right.value[3],*right.value[:3]));q=a.slerp(b,(frame-left.frame)/(right.frame-left.frame));break
    else:q=Quaternion((keys[-1].value[3],*keys[-1].value[:3]))
    direction=q@Vector((0,1,0));direction.y=0;return direction.normalized().rotation_difference(Vector((0,0,1)))

def build():
    context=context_for();raw=root/'tools/majima-emote-build-0104/ProjectYakuza/42/media/anims_X/Bob'/(name+'.x');text,bones,animation,spans=read(raw);frames=list(range(selection['firstFrame'],selection['lastFrame']+1));times=[i*160 for i in range(len(frames))];values=[locals_at(bones,animation,f*160)for f in frames];fingers={n:v.copy()for n,v in values[0].items()if '_Finger'in n};grip=json.loads((mod/'docs/native-bat-grip.json').read_text());rightGrip=Matrix(grip['authoredOffsets']['Bip01_Prop1']);mirror=Matrix.Diagonal((1,1,-1,1));prop=read_gmt(str(propSource)).animation.bones['anm_root']
    for curve in prop.curves:
        if int(curve.type)in(0,1):curve.fill_channels()
    native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media');bodyPath=native/'models_X/Skinned/MaleBody.x';body=load_body(bodyPath);reference=native/'anims_X/Bob/Bob_Idle.x';_,rb,ra,_=read(reference);feet=['Bip01_L_Foot','Bip01_R_Foot','Bip01_L_Toe0','Bip01_R_Toe0'];floor=min(p.y for p in skin_part(body,world(rb,locals_at(rb,ra,0)),feet));corrections=[];weapons=[]
    for i,frame in enumerate(frames):
        pose=context['srcposes'][frame];values[i],_=fit_arms(bones,values[i],pose,context['bind'],fingers);nativePose=world(bones,values[i]);chest=(mirror@pose['mune_c_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion();adapt=nativePose['Bip01_Spine1'].to_quaternion()@chest.inverted();q=context['sample'](prop.rotation,frame,Quaternion((1,0,0,0)),True);sourceWeapon=context['SOURCE_ROTATION']@q;weapon=adapt@(mirror@sourceWeapon.to_matrix().to_4x4()@mirror).to_quaternion();hand=weapon@rightGrip.to_quaternion().inverted();parent=bones['Bip01_R_Hand']['parent'];translation=values[i]['Bip01_R_Hand'].translation.copy();values[i]['Bip01_R_Hand']=(nativePose[parent].to_quaternion().inverted()@hand).to_matrix().to_4x4();values[i]['Bip01_R_Hand'].translation=translation
        poseNative=world(bones,values[i]);bottom=min(p.y for p in skin_part(body,poseNative,feet));delta=floor-bottom;parent=bones['Bip01']['parent'];values[i]['Bip01'].translation+=poseNative[parent].inverted().to_3x3()@Vector((0,delta,0))if parent else Vector((0,delta,0));corrections.append(delta);weapons.append(list(weapon))
    output=mod/'42/media/anims_X/Bob'/(name+'.x');write(output,text,spans,blocks(bones,values,times,grip),name)
    node=E.Element('animNode')
    for key,value in [('m_Name',identifier),('m_AnimName',name),('m_Looped','false'),('m_BlendTime','0.25'),('m_BlendOutTime','0.25'),('m_EarlyTransitionOut','false'),('m_SpeedScale','1.0'),('m_SyncTrackingEnabled','false')]:E.SubElement(node,key).text=value
    condition=E.SubElement(node,'m_Conditions')
    for key,value in [('m_Name','emote'),('m_Type','STRING'),('m_Value',identifier)]:E.SubElement(condition,key).text=value
    event=E.SubElement(node,'m_Events')
    for key,value in [('m_EventName','EmoteFinishing'),('m_Time','End'),('m_ParameterValue','')]:E.SubElement(event,key).text=value
    for bone in bones:
        if bone=='Body':continue
        weight=E.SubElement(node,'m_SubStateBoneWeights')
        for key,value in [('boneName',bone),('includeDescendants','false'),('weight','1.0')]:E.SubElement(weight,key).text=value
    selector=mod/'42/media/AnimSets/player/emote'/(name+'.xml');selector.parent.mkdir(parents=True,exist_ok=True);E.indent(node,space='  ');E.ElementTree(node).write(selector,encoding='utf-8',xml_declaration=True)
    references=[mod/'docs/native-bat-grip.json',Path(__file__),w/'extract_majima_bat_emote.py',w/'retarget_locomotion.py',w/'weapon_hold_geometry.py',w/'native_body_geometry.py',Path('C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/bind.json'),bodyPath,reference,Path(grip['source']),native/'models_X/weapons/2handed/Baseballbat.x']
    report={'operation':'Direct contiguous original Kiwami batting-center opening-greeting Majima behind-head/point/lower samples at original 30 fps. Constant yaw normalization faces the gesture forward. Native limb proportions, supplied bat fingers and sole grounding adapt the original poses. Independent cinematic bat rotation directs the native right wrist and prop, calibrated using the original native bat palm/grip. No images, sound, new poses or model assets are generated.','upstreamReference':{'url':'https://github.com/DmitryFisk/custom-voice-framework','commit':'e0f46546cbbddb864671d9a14887987b3900e2a5','basis':'Native emote-state dispatch, end event, full-body bone weights and cancellable menu guards; no framework or voice-pack files changed.'},'selection':selection,'source':str(source),'sourceSha256':sha(source),'propSource':str(propSource),'propSourceSha256':sha(propSource),'rig':str(rig),'rigSha256':sha(rig),'sourceFrames':frames,'frames':len(frames),'fps':30,'duration':(len(frames)-1)/30,'sourceYaw':list(context['SOURCE_ROTATION']),'retarget':str(raw),'retargetSha256':sha(raw),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'selector':selector.relative_to(mod).as_posix(),'selectorSha256':sha(selector),'ground':{'floor':floor,'corrections':corrections,'feet':feet},'nativeGrip':grip,'weaponRotations':weapons,'provenance':[{'path':str(p),'sha256':sha(p)}for p in references]}
    (mod/'docs/majima-bat-emote-assets.json').write_text(json.dumps(report,indent=2)+'\n');print('PASS original Majima bat-point emote:',len(frames),'samples,',(len(frames)-1)/30,'seconds; native bat grip, full-body emote and grounded soles')

if __name__=='__main__':build()
