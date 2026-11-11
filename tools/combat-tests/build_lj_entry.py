from pathlib import Path
import sys,json,hashlib,xml.etree.ElementTree as E,zipfile
from mathutils import Vector

root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,world,blocks,write
from weapon_hold_geometry import fit_arms
from native_body_geometry import load_body,skin_part

mod=root/'combat/ProjectYakuza';source=Path('F:/SteamLibrary/steamapps/common/Lost Judgment/runtime/media/mods/dod/motion/gmt/p_yag_btl_sud_styl_mai_st.gmt');name='ProjectYakuza_DD_StyleEntry'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
feet=['Bip01_L_Foot','Bip01_R_Foot','Bip01_L_Toe0','Bip01_R_Toe0']

def context_for(prefix=False):
    converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/lj-entry-build-0100'").replace('str(f*160)','str(round(f*4800/a.frame_rate))')
    if prefix:converter=converter.split('poses=[];srcposes=[]')[0]
    saved=sys.argv;sys.argv=['convert','--',name,str(source)];context={'FINGER_SOURCE':'Bob_IdleAim1Hand.x'};exec(compile(converter,'supplied_lj_blue_dragon_entry','exec'),context);sys.argv=saved
    return context

def build():
    context=context_for();raw=root/'tools/lj-entry-build-0100/ProjectYakuza/42/media/anims_X/Bob'/(name+'.x');text,bones,animation,spans=read(raw)
    count=context['a'].end_frame+1;fps=context['a'].frame_rate;assert count==151 and fps==60
    times=[round(f*4800/fps)for f in range(count)];values=[locals_at(bones,animation,t)for t in times];fingers={n:v.copy()for n,v in values[0].items()if '_Finger'in n}
    native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media');reference=native/'anims_X/Bob/Bob_Idle.x';bodyPath=native/'models_X/Skinned/MaleBody.x';body=load_body(bodyPath)
    _,referenceBones,referenceAnimation,_=read(reference);floor=min(p.y for p in skin_part(body,world(referenceBones,locals_at(referenceBones,referenceAnimation,0)),feet));corrections=[];before=[]
    for frame in range(count):
        values[frame],_=fit_arms(bones,values[frame],context['srcposes'][frame],context['bind'],fingers)
        pose=world(bones,values[frame]);bottom=min(p.y for p in skin_part(body,pose,feet));delta=floor-bottom;parent=bones['Bip01']['parent']
        values[frame]['Bip01'].translation+=pose[parent].inverted().to_3x3()@Vector((0,delta,0))if parent else Vector((0,delta,0))
        corrections.append(delta);before.append(bottom)
    grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];output=mod/'42/media/anims_X/Bob'/(name+'.x');write(output,text,spans,blocks(bones,values,times,grip),name)
    with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.98.0.zip')as archive:
        for group in ['aim','aim-strafe']:
            path=mod/'42/media/AnimSets/player'/group/'ProjectYakuza_DD_CombatIdle.xml';path.write_bytes(archive.read('ProjectYakuza/'+path.relative_to(mod).as_posix()))
    style=mod/'42/media/lua/shared/ProjectYakuza/Styles/DragonOfDojima.lua';code=style.read_text(encoding='utf-8');old='animation="ProjectYakuza_DD_StyleEntry",duration=45/30';new='animation="ProjectYakuza_DD_StyleEntry",duration=150/60';assert old in code or new in code;style.write_text(code.replace(old,new),encoding='utf-8')
    node=mod/'42/media/AnimSets/player/actions'/(name+'.xml');xml=E.parse(node).getroot();xml.find('m_BlendOutTime').text='0.3';xml.find('m_EarlyTransitionOut').text='false';E.indent(xml,space='  ');E.ElementTree(xml).write(node,encoding='utf-8',xml_declaration=True)
    references=[root/'tools/combat-tests/retarget_locomotion.py',root/'tools/combat-tests/weapon_hold_geometry.py',root/'tools/combat-tests/native_body_geometry.py',Path('E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'),Path('C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/bind.json'),reference,bodyPath,native/'anims_X/Bob/Bob_IdleAim1Hand.x']
    report={'operation':'Original installed Lost Judgment dod mod blue Crane/Dragon Engine style entry, p_yag_btl_sud_styl_mai_st. All 151 samples retained at original 60 fps over 2.5 seconds. DE c_man skeleton reference and native PZ proportions; source limb directions and all body rotations preserved. Only the root vertical offset is grounded against the native skinned foot sole for each source support frame. No synthesized poses, pixels or audio. Relaxed idle remains vanilla; previous unarmed RMB combat idle selectors are restored exactly from v0.98.0.','source':str(source),'sourceSha256':sha(source),'frames':count,'fps':fps,'duration':150/60,'times':times,'retarget':str(raw),'retargetSha256':sha(raw),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'nativeGrip':grip,'selector':node.relative_to(mod).as_posix(),'selectorSha256':sha(node),'blendOut':.3,'ground':{'nativeFloor':floor,'reference':str(reference),'body':str(bodyPath),'bones':feet,'before':before,'corrections':corrections},'retargetProvenance':[{'path':str(p),'sha256':sha(p)}for p in references],'restoredIdle':[{'path':('42/media/AnimSets/player/'+group+'/ProjectYakuza_DD_CombatIdle.xml'),'sha256':sha(mod/'42/media/AnimSets/player'/group/'ProjectYakuza_DD_CombatIdle.xml')}for group in ['aim','aim-strafe']]}
    (mod/'docs/combat-entry-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print('PASS original LJ blue Dragon entry: 151 samples at 60 fps; native sole plane',floor,'root correction range',min(corrections),max(corrections),'previous RMB combat idle restored')

if __name__=='__main__':build()
