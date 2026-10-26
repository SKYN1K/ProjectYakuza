"""Run in Blender 3.6: --background --python convert_motions.py -- [arguments].

Requires local original Y0 Majima GMD/GMT files and the pinned third-party
importers documented in README.md. No original archives or tool installs are
copied into the addon. Retargets existing motion; does not synthesize animation.
"""
import argparse
import hashlib
import importlib.util
import json
import math
import re
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

MAP = {'Bip01':'ketu_c_n', 'Bip01_Pelvis':'ketu_c_n',
       'Bip01_Spine':'kosi_c_n', 'Bip01_Spine1':'mune_c_n',
       'Bip01_Neck':'kubi_c_n', 'Bip01_Head':'face_c_n'}
for side in ('L','R'):
    for target, source in [('Clavicle','kata'),('UpperArm','ude1'),
                           ('Forearm','ude2'),('Hand','ude3'),('Thigh','asi1'),
                           ('Calf','asi2'),('Foot','asi3'),('Toe0','asi4')]:
        MAP[f'Bip01_{side}_{target}'] = f'{source}_{side.lower()}_n'

# Contact frames are approximations selected from source pose samples. The
# original MEP combat/physics implementation is not transplanted into Zomboid.
AIM = {'Bip01_Spine':('Bip01_Spine1','mune_c_n'),
       'Bip01_Spine1':('Bip01_Neck','kubi_c_n'),
       'Bip01_Neck':('Bip01_Head','face_c_n')}
for side in ('L','R'):
    for parent,child,source_child in [('Clavicle','UpperArm','ude1'),
            ('UpperArm','Forearm','ude2'),('Forearm','Hand','ude3'),
            ('Hand','Finger1','naka1'),('Thigh','Calf','asi2'),
            ('Calf','Foot','asi3'),('Foot','Toe0','asi4')]:
        AIM[f'Bip01_{side}_{parent}']=(f'Bip01_{side}_{child}',f'{source_child}_{side.lower()}_n')

CLIPS = []
def clip(name, source, kind, impact=None, **extra):
    CLIPS.append(dict(name='ProjectYakuza_MD_'+name, source=source+'.gmt',
                      kind=kind, impact_frame=impact, **extra))
for i, impact in enumerate([9,12,12,12],1):
    clip(f'Light{i:02}',f'P_MJK_CMB_{i:02}','light',impact,index=i)
for i, impact in enumerate([20,21,24,18],1):
    clip(f'Finisher{i:02}',f'P_MJK_CMB_{i:02}_fin','finisher',impact,index=i)
for i, direction in enumerate(['f','b','l','r'],1):
    clip(f'Quickstep{i:02}',f'P_MJK_sway_{direction}','quickstep',index=i)
    clip(f'QuickstepAttack{i:02}',f'P_MJK_ATK_sway_{direction}', 'quickstepAttack',
         [13,14,16,16][i-1],index=i)
clip('GroundSlash','P_MJK_ATK_down_slash','ground',17)
clip('RunningSlash','P_MJK_ATK_run_slash','runningAttack',16)
clip('CombatIdle','P_MJK_stand_btl_lp','idle')
clip('GuardEnter','P_MJK_guard_st','guard',phase='enter')
clip('GuardLoop','P_MJK_guard_lp','guard',phase='hold')
clip('GuardHit','P_MJK_guard','guard',phase='hit')
clip('GuardExit','P_MJK_guard_en','guard',phase='exit')
clip('Taunt','P_MJK_stlyeact','taunt')
clip('HeatActivate','P_MJK_stlye_st','heatActivation')


def read_frames(text):
    """Read the named Frame hierarchy from a text DirectX file (row matrices)."""
    text=text[re.search(r'^Frame\s+\w+\s*\{', text, re.M).start():]
    text=text.split('\nAnimationSet ')[0]
    tokens = re.findall(r'[A-Za-z_][\w.]*|[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?|[{};,]',text)
    frames, stack = {}, []
    i=0
    while i<len(tokens):
        if tokens[i]=='Frame' and i+2<len(tokens) and tokens[i+2]=='{':
            name=tokens[i+1]
            frames[name]={'parent':stack[-1] if stack else None}
            stack.append(name); i+=3
        elif tokens[i]=='FrameTransformMatrix' and stack:
            j=tokens.index('}',i); values=[float(v) for v in tokens[i+2:j] if v not in (';',',')]
            assert len(values)==16
            frames[stack[-1]]['local']=Matrix([values[n:n+4] for n in range(0,16,4)]).transposed()
            i=j+1
        elif tokens[i]=='}' and stack:
            stack.pop(); i+=1
        else: i+=1
    for name,b in frames.items():
        b['world']=(frames[b['parent']]['world'] if b['parent'] else Matrix.Identity(4)) @ b['local']
    return frames


def basis(left, right, head, hip):
    x=(left-right).normalized(); z=(head-hip).normalized()
    z=(z-x*z.dot(x)).normalized(); y=z.cross(x).normalized()
    return Matrix([x,y,z]).transposed()


def fmt(values):return ','.join(f'{v:.9f}' for v in values)


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--source',type=Path,required=True)
    p.add_argument('--gmd',type=Path,required=True)
    p.add_argument('--gmd-importer',type=Path,required=True)
    p.add_argument('--gmt-importer',type=Path,required=True)
    p.add_argument('--native-knife',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--samples',type=Path,required=True)
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:])
    root=Path(__file__).resolve().parents[2]
    template=(root/'combat/ProjectYakuza/42/media/anims_X/Bob/ProjectYakuza_DD_Light01.x').read_text()
    prefix=(template.split('\nAnimationSet ')[0]+'\n').replace('Y6_Default','MadDog_Default').replace('Y6_ImportSupport','MadDog_ImportSupport')
    bones=read_frames(template)
    sys.path.insert(0,str(args.gmd_importer))
    import yk_gmd_blender
    yk_gmd_blender.register()
    spec=importlib.util.spec_from_file_location('yakuza_gmt',args.gmt_importer/'__init__.py',submodule_search_locations=[str(args.gmt_importer)])
    module=importlib.util.module_from_spec(spec); sys.modules[spec.name]=module; spec.loader.exec_module(module)
    from yakuza_gmt.blender.importer import GMTImporter
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gmd_skinned(filepath=str(args.gmd),strict=False,logging_categories='')
    rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
    bpy.context.view_layer.objects.active=rig;rig.select_set(True)
    rest={n:b.matrix_local.copy() for n,b in rig.data.bones.items()}
    def s(n):return rest[n].translation
    def t(n):return bones[n]['world'].translation
    sb=basis(s('asi1_l_n'),s('asi1_r_n'),s('face_c_n'),s('ketu_c_n'))
    tb=basis(t('Bip01_L_Thigh'),t('Bip01_R_Thigh'),t('Bip01_Head'),t('Bip01'))
    conversion=tb @ sb.transposed()
    # Leg length preserves PZ proportions, with in-place hips and original height motion.
    scale=(t('Bip01_L_Thigh')-t('Bip01_L_Foot')).length/(s('asi1_l_n')-s('asi3_l_n')).length
    # Reuse the original PZ knife's prop-to-hand grip, never a generated model.
    native=args.native_knife.read_text()
    native_frames=read_frames(native)
    def native_pose_zero():
        result={};channels={}
        for match in re.finditer(r'Animation\s*(?:\w+)?\s*\{\s*\{\s*(\w+)\s*\}(.*?)(?=\n\s*Animation\s|\Z)',native,re.S):
            name,body=match.groups(); channels[name]={}
            for key in re.finditer(r'AnimationKey\s*(?:\w+)?\s*\{\s*(\d+)\s*;\s*\d+\s*;\s*\d+\s*;\s*\d+\s*;([^;]+)',body,re.S):
                kind,nums=key.groups();channels[name][int(kind)]=[float(x.strip()) for x in nums.split(',') if x.strip()]
        for name,b in native_frames.items():
            c=channels.get(name,{})
            q=Quaternion([-c[0][0],*c[0][1:]]) if 0 in c else b['local'].to_quaternion()
            pos=Vector(c[2]) if 2 in c else b['local'].translation
            local=q.to_matrix().to_4x4();local.translation=pos
            result[name]=(result[b['parent']] if b['parent'] else Matrix.Identity(4)) @ local
        return result
    zero=native_pose_zero()
    grip=zero['Bip01_R_Hand'].inverted() @ zero['Bip01_Prop1']
    fingers={name:zero[native_frames[name]['parent']].inverted() @ zero[name]
             for name in ('Bip01_R_Finger0','Bip01_R_Finger1')}
    args.output.mkdir(parents=True,exist_ok=True)
    args.samples.mkdir(parents=True,exist_ok=True)
    report=[]
    for entry in CLIPS:
        source=args.source/entry['source']
        GMTImporter(bpy.context,str(source),{'merge_vector_curves':True,'is_auth':False,'import_as_path':False}).read()
        end=bpy.context.scene.frame_end; fps=bpy.context.scene.render.fps
        transforms={name:[] for name in bones}; sample_frames=[]
        for f in range(end+1):
            bpy.context.scene.frame_set(f)
            world={};source_hip=rig.pose.bones['ketu_c_n'].matrix.translation
            for name,b in bones.items():
                parent=b['parent'];parent_pose=world[parent] if parent else Matrix.Identity(4)
                source_name=MAP.get(name)
                if source_name:
                    delta=rig.pose.bones[source_name].matrix.to_3x3() @ rest[source_name].to_3x3().inverted()
                    rotation=conversion @ delta @ conversion.transposed() @ b['world'].to_3x3()
                    if name in AIM:
                        child,source_child=AIM[name]
                        bind_vector=bones[child]['world'].translation-b['world'].translation
                        predicted=rotation @ b['world'].to_3x3().inverted() @ bind_vector
                        desired=conversion @ (rig.pose.bones[source_child].matrix.translation-rig.pose.bones[source_name].matrix.translation)
                        if predicted.length>.00001 and desired.length>.00001:
                            rotation=predicted.rotation_difference(desired).to_matrix() @ rotation
                    local_rotation=parent_pose.to_3x3().inverted() @ rotation
                    local=local_rotation.to_quaternion().normalized().to_matrix().to_4x4()
                    local.translation=b['local'].translation
                    if name=='Bip01':
                        height=conversion @ ((source_hip-s('ketu_c_n'))*scale)
                        position=b['world'].translation.copy();position.y+=height.y
                        local.translation=parent_pose.inverted() @ position
                else:local=fingers.get(name,b['local']).copy()
                world[name]=parent_pose @ local
                if name=='Bip01_Prop1':
                    world[name]=world['Bip01_R_Hand'] @ grip
                    local=parent_pose.inverted() @ world[name]
                transforms[name].append(local)
            sample_frames.append({n:list(w.translation) for n,w in world.items()})
        chunks=[prefix,f'AnimationSet {entry["name"]} {{\n']
        for name,matrices in transforms.items():
            chunks.append(f' Animation {{ {{ {name} }}\n')
            rotations=[];last=None
            for mat in matrices:
                q=mat.to_quaternion().normalized()
                if last is not None and q.dot(last)<0:q.negate()
                last=q.copy();rotations.append([-q.w,q.x,q.y,q.z])
            for label,kind,values in [('R',0,rotations),('S',1,[(1,1,1)]*(end+1)),('T',2,[m.translation for m in matrices])]:
                chunks.append(f'  AnimationKey {label} {{ {kind}; {end+1};\n')
                for f,value in enumerate(values):
                    assert all(math.isfinite(v) for v in value)
                    ending=';;;' if f==end else ';;,'
                    chunks.append(f'{round(f*4800/fps)};{len(value)};{fmt(value)}{ending}\n')
                chunks.append(' }\n')
            chunks.append(' }\n')
        chunks.append('}\n')
        output=args.output/(entry['name']+'.x');output.write_text(''.join(chunks))
        record=dict(entry,frames=end,fps=fps,duration=end/fps,
                    source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                    output_sha256=hashlib.sha256(output.read_bytes()).hexdigest(),
                    channels=len(bones))
        report.append(record)
        (args.samples/(entry['name']+'.json')).write_text(json.dumps(sample_frames))
        print('EXPORTED',entry['name'],end,'frames',flush=True)
    manifest={'source_game':'Yakuza 0 (local PC installation)',
              'archive':'media/data/motion_w64/BattlePlayerMajimaL.par',
              'source_model':args.gmd.name,
              'source_model_sha256':hashlib.sha256(args.gmd.read_bytes()).hexdigest(),
              'retarget':'Global bind-relative rotations with source segment-direction correction for T/A-pose differences; native PZ bone lengths; horizontal root motion removed; vertical hip motion retained; native knife prop/finger grip.',
              'scale':scale,'bone_map':MAP,'clips':report}
    (args.output.parents[3]/'docs/motion-provenance.json').write_text(json.dumps(manifest,indent=2)+'\n')

if __name__=='__main__':main()
