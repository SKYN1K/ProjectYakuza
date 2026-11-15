from pathlib import Path
import sys,json,hashlib,types,xml.etree.ElementTree as E
from mathutils import Matrix,Vector,Quaternion

root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;sys.path.insert(0,str(w));mod=root/'emotes/ProjectYakuzaEmotes';name='main03_007_12';rig=root/'extracted/kiwami-entry-099/c_cm_bone.gmd';selection=json.loads((root/'extracted/shimano-emote/selection.json').read_text(encoding='utf-8'));source=Path(selection['source']);native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media');sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
package=types.ModuleType('yk');package.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=package
from yk.gmt_lib import read_gmt
from yk.read_gmd import read_gmd_bones
from locomotion_math import read,locals_at,world,blocks,write
from weapon_hold_geometry import source_pose,fit_arms
from native_body_geometry import load_body,skin_part

def context_for(prefix=False):
    rigBones=read_gmd_bones(str(rig));rigWorld={}
    for bone in rigBones:
        local=Matrix.Translation(Vector(bone.local_pos[:3]))@Quaternion((bone.local_rot[3],*bone.local_rot[:3])).to_matrix().to_4x4();rigWorld[bone.name]=rigWorld[rigBones[bone.parent_index].name]@local if bone.parent_index>=0 else local
    converter=(w/'retarget_locomotion.py').read_text(encoding='utf-8').replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/shimano-emote-build'").replace("r'E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'",repr(str(rig))).replace("scale=bind['Bip01_Pelvis'].translation.y/1.14","scale=bind['Bip01_Pelvis'].translation.y/SOURCE_PELVIS_HEIGHT").replace(' tg={}',' sg={bone:SOURCE_ROTATION.to_matrix().to_4x4()@pose for bone,pose in sg.items()}\n tg={}')
    context={'FINGER_SOURCE':'Bob_Idle.x','SOURCE_PELVIS_HEIGHT':rigWorld['ketu_c_n'].translation.y,'SOURCE_ROTATION':Quaternion((1,0,0,0))};saved=sys.argv;sys.argv=['convert','--',name,str(source)];exec(compile(converter.split('poses=[];srcposes=[]')[0],'kiwami_shimano_shut_up_context','exec'),context);pose=source_pose(context,169);forward=pose['vector_c_n'].to_quaternion()@Vector((0,0,1));forward.y=0;context['SOURCE_ROTATION']=forward.normalized().rotation_difference(Vector((0,0,1)))
    if not prefix:exec(compile(converter[converter.index('poses=[];srcposes=[]'):],'kiwami_shimano_shut_up_conversion','exec'),context)
    sys.argv=saved;return context

def build():
    context=context_for();assert context['a'].frame_rate==30 and context['a'].end_frame==169;raw=root/'tools/shimano-emote-build/ProjectYakuza/42/media/anims_X/Bob'/(name+'.x');text,bones,animation,spans=read(raw);frames=list(range(selection['firstFrame'],selection['lastFrame']+1));values=[locals_at(bones,animation,f*160)for f in frames];fingers={n:v.copy()for n,v in values[0].items()if '_Finger'in n};bodyPath=native/'models_X/Skinned/MaleBody.x';body=load_body(bodyPath);reference=native/'anims_X/Bob/Bob_Idle.x';_,rb,ra,_=read(reference);feet=['Bip01_L_Foot','Bip01_R_Foot','Bip01_L_Toe0','Bip01_R_Toe0'];floor=min(p.y for p in skin_part(body,world(rb,locals_at(rb,ra,0)),feet));corrections=[]
    for i,frame in enumerate(frames):
        values[i],_=fit_arms(bones,values[i],context['srcposes'][frame],context['bind'],fingers);pose=world(bones,values[i]);delta=floor-min(p.y for p in skin_part(body,pose,feet));parent=bones['Bip01']['parent'];values[i]['Bip01'].translation+=pose[parent].inverted().to_3x3()@Vector((0,delta,0))if parent else Vector((0,delta,0));corrections.append(delta)
    output=mod/'42/media/anims_X/Bob'/(name+'.x');write(output,text,spans,blocks(bones,values,[i*160 for i in range(len(frames))],None),name)
    node=E.parse(mod/'42/media/AnimSets/player/emote/ProjectYakuza_MajimaBatPoint.xml');element=node.getroot()
    for key in ['m_Name','m_AnimName']:element.find(key).text=name
    element.find('m_Conditions/m_Value').text='ProjectYakuza_ShimanoShutUp';selector=mod/'42/media/AnimSets/player/emote'/(name+'.xml');E.indent(node,space='  ');node.write(selector,encoding='utf-8',xml_declaration=True)
    references=[Path(__file__),w/'extract_shimano_emote.py',w/'retarget_locomotion.py',w/'weapon_hold_geometry.py',w/'native_body_geometry.py',w/'locomotion_math.py',Path('C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/bind.json'),bodyPath,reference,mod/'42/media/AnimSets/player/emote/ProjectYakuza_MajimaBatPoint.xml']
    report={'operation':'Original contiguous Kiwami Shimano Tojo HQ furniture strike and seated-to-standing motion preceding the shouted line. Native source animation identifier retained as the asset name. Original 30 fps and head/neck/body rotations retained; constant yaw faces the gesture forward, native proportions adapt arm directions, supplied native idle fingers and skinned sole grounding fit the Human skeleton. Root XZ stays in place. No new poses, visual/audio assets or items are synthesized.','selection':selection,'source':str(source),'sourceSha256':sha(source),'rig':str(rig),'rigSha256':sha(rig),'sourceFrames':frames,'frames':len(frames),'fps':30,'duration':(len(frames)-1)/30,'sourceYaw':list(context['SOURCE_ROTATION']),'retarget':str(raw),'retargetSha256':sha(raw),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'selector':selector.relative_to(mod).as_posix(),'selectorSha256':sha(selector),'ground':{'floor':floor,'corrections':corrections,'feet':feet},'provenance':[{'path':str(p),'sha256':sha(p)}for p in references]}
    (mod/'docs/shimano-emote-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print('PASS original Shimano Tojo HQ emote:',len(frames),'samples,',report['duration'],'seconds; original neck/head motion and native grounded soles')

if __name__=='__main__':build()
