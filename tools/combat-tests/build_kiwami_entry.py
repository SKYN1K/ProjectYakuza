from pathlib import Path
import sys,json,hashlib,types,xml.etree.ElementTree as E
from mathutils import Matrix,Vector,Quaternion

root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent));mod=root/'combat/ProjectYakuza';source=root/'extracted/kiwami-entry-099';name='ProjectYakuza_DD_StyleEntry';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
package=types.ModuleType('yk');package.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=package
from yk.read_gmd import read_gmd_bones
from locomotion_math import read,locals_at,world,blocks,write
from weapon_hold_geometry import fit_arms

def context_for(prefix=False):
    bones=read_gmd_bones(str(source/'c_cm_bone.gmd'));bind={}
    for bone in bones:
        local=Matrix.Translation(Vector(bone.local_pos[:3]))@Quaternion((bone.local_rot[3],*bone.local_rot[:3])).to_matrix().to_4x4();bind[bone.name]=bind[bones[bone.parent_index].name]@local if bone.parent_index>=0 else local
    converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/kiwami-entry-build-099'").replace("r'E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'",repr(str(source/'c_cm_bone.gmd'))).replace("scale=bind['Bip01_Pelvis'].translation.y/1.14","scale=bind['Bip01_Pelvis'].translation.y/SOURCE_PELVIS_HEIGHT")
    if prefix:converter=converter.split('poses=[];srcposes=[]')[0]
    saved=sys.argv;sys.argv=['convert','--',name,str(source/'P_KRL_style_st.gmt')];context={'FINGER_SOURCE':'Bob_IdleAim1Hand.x','SOURCE_PELVIS_HEIGHT':bind['ketu_c_n'].translation.y};exec(compile(converter,'supplied_kiwami1_entry','exec'),context);sys.argv=saved
    return context

def build():
    context=context_for();raw=root/'tools/kiwami-entry-build-099/ProjectYakuza/42/media/anims_X/Bob'/(name+'.x');text,bones,animation,spans=read(raw);count=context['a'].end_frame+1;assert count==46 and context['a'].frame_rate==30;times=[f*160 for f in range(count)];values=[locals_at(bones,animation,t)for t in times];fingers={n:v.copy()for n,v in values[0].items()if '_Finger'in n};grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat']
    for frame in range(count):values[frame],_=fit_arms(bones,values[frame],context['srcposes'][frame],context['bind'],fingers)
    output=mod/'42/media/anims_X/Bob'/(name+'.x');write(output,text,spans,blocks(bones,values,times,grip),name)
    node=mod/'42/media/AnimSets/player/actions'/(name+'.xml');xml=E.parse(node).getroot();xml.find('m_BlendOutTime').text='0.3';xml.find('m_EarlyTransitionOut').text='false';E.indent(xml,space='  ');E.ElementTree(xml).write(node,encoding='utf-8',xml_declaration=True)
    for group in ['aim','aim-strafe']:
        override=mod/'42/media/AnimSets/player'/group/'ProjectYakuza_DD_CombatIdle.xml'
        if override.exists():override.unlink()
    report={'operation':'All 46 original Kiwami 1 Dragon P_KRL_style_st samples at 30 fps. Original full-body directions and native segment lengths; native finger pose and hand/prop offsets. Existing action anchor retains in-place gameplay. No baked idle, invented transition poses, images or sounds. Native action layer releases after full source completion and blends out over 0.3 seconds into the game-selected vanilla idle/aim state; dormant custom weapon poses remain gated off.','archiveEntries':json.loads((source/'source-index.json').read_text()),'source':str(source/'P_KRL_style_st.gmt'),'sourceSha256':sha(source/'P_KRL_style_st.gmt'),'rig':str(source/'c_cm_bone.gmd'),'rigSha256':sha(source/'c_cm_bone.gmd'),'retarget':str(raw),'retargetSha256':sha(raw),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'frames':count,'fps':30,'duration':45/30,'blendOut':.3,'selector':node.relative_to(mod).as_posix(),'selectorSha256':sha(node),'nativeGrip':grip,'retargetProvenance':[{'path':str(p),'sha256':sha(p)}for p in [root/'tools/combat-tests/retarget_locomotion.py',root/'tools/combat-tests/weapon_hold_geometry.py',Path('C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/bind.json'),Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob/Bob_IdleAim1Hand.x')]]}
    (mod/'docs/kiwami-entry-assets.json').write_text(json.dumps(report,indent=2)+'\n');print('PASS original Kiwami 1 Dragon style entry, 46 samples / 1.5 seconds, full-body native retarget and 0.3-second vanilla-state blend-out')

if __name__=='__main__':build()
