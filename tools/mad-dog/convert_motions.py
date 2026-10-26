"""Port original Y0 motion onto PZ's real Human bind rig; run in Blender Python.

No generated poses, IK, floor reconstruction or time reversal. The source is
sampled directly from GMT/GMD keys. Only planar root travel is removed because
framework actions own collision-aware travel. All original frame times remain.
"""
import argparse
import bisect
import hashlib
import json
import math
import re
import sys
import types
from pathlib import Path
from mathutils import Matrix, Quaternion, Vector

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
clip('StyleEntry','P_btlst_MJA_to_MJK','styleEntry')


def matrix(text):
    v=[float(n) for n in text.strip().rstrip(';').split(',')]
    assert len(v)==16
    return Matrix([v[i:i+4] for i in range(0,16,4)]).transposed()


def raw_frames(text):
    start=text.index('Frame Dummy01 {');depth=0
    for i in range(start,len(text)):
        if text[i]=='{':depth+=1
        elif text[i]=='}':
            depth-=1
            if depth==0:end=i+1;break
    frames={};stack=[]
    for match in re.finditer(r'Frame (\w+)\s*\{|FrameTransformMatrix\s*\{([^}]+)\}|(\})',text[start:end]):
        if match[1]:
            frames[match[1]]={'parent':stack[-1] if stack else None};stack.append(match[1])
        elif match[2]:frames[stack[-1]]['local']=matrix(match[2])
        else:stack.pop()
    for name,b in frames.items():
        b['world']=(frames[b['parent']]['world'] if b['parent'] else Matrix.Identity(4)) @ b['local']
    return frames,start


def human_bind(text):
    frames,start=raw_frames(text);skin={}
    for match in re.finditer(r'SkinWeights\s*\{\s*"([^"]+)";\s*(\d+);([^}]+)\}',text):
        count=int(match[2])
        values=[float(v) for v in re.findall(r'-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?',match[3])][2*count:]
        assert len(values)==16
        skin[match[1]]=Matrix([values[i:i+4] for i in range(0,16,4)]).transposed().inverted()
    skin['Dummy01']=frames['Dummy01']['local'].copy()
    skin['Bip01']=skin['Bip01_Pelvis'] @ frames['Bip01_Pelvis']['local'].inverted()
    for name,b in frames.items():
        parent=b['parent']
        b['world']=skin.get(name,(frames[parent]['world'] @ b['local']) if parent else b['local']).copy()
        b['local']=(frames[parent]['world'].inverted() @ b['world']) if parent else b['world'].copy()
    # This is where PZ's ImportedSkeleton attaches the separate translation node.
    match=re.search(r'Frame Translation_Data\s*\{\s*FrameTransformMatrix\s*\{([^}]+)\}',text)
    if match:
        local=matrix(match[1]);frames['Translation_Data']={'parent':'Dummy01','local':local,'world':frames['Dummy01']['world'] @ local}
    return frames,start


def native_knife_grip(text):
    frames,_=raw_frames(text);channels={};world={}
    for match in re.finditer(r'Animation\s*(?:\w+)?\s*\{\s*\{\s*(\w+)\s*\}(.*?)(?=\n\s*Animation\s|\Z)',text,re.S):
        name,body=match.groups();channels[name]={}
        for key in re.finditer(r'AnimationKey\s*(?:\w+)?\s*\{\s*(\d+)\s*;\s*\d+\s*;\s*\d+\s*;\s*\d+\s*;([^;]+)',body,re.S):
            channels[name][int(key[1])]=[float(v) for v in key[2].split(',') if v.strip()]
    for name,b in frames.items():
        keys=channels.get(name,{})
        q=Quaternion([-keys[0][0],*keys[0][1:]]) if 0 in keys else b['local'].to_quaternion()
        loc=Vector(keys[2]) if 2 in keys else b['local'].translation
        local=Matrix.LocRotScale(loc,q,Vector((1,1,1)))
        world[name]=(world[b['parent']] if b['parent'] else Matrix.Identity(4)) @ local
    grip=world['Bip01_R_Hand'].inverted() @ world['Bip01_Prop1']
    fingers={n:world[frames[n]['parent']].inverted() @ world[n] for n in ['Bip01_R_Finger0','Bip01_R_Finger1']}
    return grip,fingers


def frame(primary,secondary):
    x=primary.normalized();y=secondary-x*secondary.dot(x)
    assert y.length>1e-6,'Ambiguous anatomical rest frame'
    y.normalize();return Matrix((x,y,x.cross(y).normalized())).transposed().to_4x4()


def rotation(value):return Quaternion((value[3],value[0],value[1],value[2])).normalized()


def evaluate(curve,time,default,is_rotation=False):
    if curve is None or not curve.keyframes:return default.copy()
    curve.fill_channels();keys=curve.keyframes
    index=max(0,bisect.bisect_right([k.frame for k in keys],time)-1)
    convert=rotation if is_rotation else Vector
    a=convert(keys[index].value)
    if index==len(keys)-1 or time<=keys[index].frame:return a
    b=convert(keys[index+1].value);t=(time-keys[index].frame)/(keys[index+1].frame-keys[index].frame)
    return a.slerp(b,t) if is_rotation else a.lerp(b,t)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for key in ['source','gmd','gmt-importer','pz-media','output','samples']:
        parser.add_argument('--'+key,type=Path,required=True)
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    pkg=types.ModuleType('mad_dog_source');pkg.__path__=[str(args.gmt_importer)];sys.modules[pkg.__name__]=pkg
    from mad_dog_source.read_gmd import read_gmd_bones
    from mad_dog_source.gmt_lib import read_gmt
    bones=read_gmd_bones(str(args.gmd));source_rest={}
    for b in bones:
        local=Matrix.LocRotScale(Vector(b.local_pos[:3]),rotation(b.local_rot),Vector((1,1,1)))
        source_rest[b.name]=(source_rest[bones[b.parent_index].name] if b.parent_index>=0 else Matrix.Identity(4)) @ local
    target_path=args.pz_media/'models_X/Skinned/MaleBody.x';text=target_path.read_text()
    target,start=human_bind(text)
    # Yakuza is +Z-forward; PZ is -Z-forward, with +X still character-left.
    # A 180-degree body turn swaps sides. A handedness conversion does not.
    conversion=Matrix.Diagonal((1,1,-1,1));converted_rest={n:conversion @ m @ conversion for n,m in source_rest.items()}
    def direction(world,a,b):return world[b].translation-world[a].translation
    def td(a,b):return target[b]['world'].translation-target[a]['world'].translation
    source_forward=sum((direction(converted_rest,'asi3_'+s+'_n','asi4_'+s+'_n') for s in ['l','r']),Vector())
    target_forward=sum((td('Bip01_'+s+'_Foot','Bip01_'+s+'_Toe0') for s in ['L','R']),Vector())
    source_forward.y=0;source_forward.normalize();target_forward.y=0;target_forward.normalize()
    source_left=direction(converted_rest,'asi1_r_n','asi1_l_n').normalized()
    target_left=td('Bip01_R_Thigh','Bip01_L_Thigh').normalized()
    assert source_forward.dot(target_forward)>.999 and source_left.dot(target_left)>.99,'Incorrect forward or left/right mapping'
    mapping={'Bip01_Pelvis':('ketu_c_n',None),'Bip01_Spine':('kosi_c_n','mune_c_n'),
             'Bip01_Spine1':('mune_c_n','kubi_c_n'),'Bip01_Neck':('kubi_c_n','face_c_n'),'Bip01_Head':('face_c_n',None)}
    children={'Bip01_Spine':'Bip01_Spine1','Bip01_Spine1':'Bip01_Neck','Bip01_Neck':'Bip01_Head'}
    for side,s in [('L','l'),('R','r')]:
        for name,child,src,src_child in [('Clavicle','UpperArm','kata','ude1'),('UpperArm','Forearm','ude1','ude2'),
                ('Forearm','Hand','ude2','ude3'),('Hand','Finger1','ude3','naka1'),('Thigh','Calf','asi1','asi2'),
                ('Calf','Foot','asi2','asi3'),('Foot','Toe0','asi3','asi4'),('Toe0',None,'asi4',None)]:
            name='Bip01_'+side+'_'+name
            mapping[name]=(src+'_'+s+'_n',src_child+'_'+s+'_n' if src_child else None)
            if child:children[name]='Bip01_'+side+'_'+child
    alignment={}
    for name,(src,child) in mapping.items():
        secondary_source,secondary_target=source_forward,target_forward
        if name=='Bip01_Pelvis':
            a=direction(converted_rest,'kosi_c_n','mune_c_n');b=td(name,'Bip01_Spine')
            secondary_source,secondary_target=source_left,target_left
        elif name.endswith('_Toe0'):a,b=source_forward,target_forward;secondary_source=secondary_target=Vector((0,1,0))
        elif name=='Bip01_Head':a=b=Vector((0,1,0))
        else:a=direction(converted_rest,src,child);b=td(name,children[name])
        if name.endswith('_Hand'):
            side='l' if '_L_' in name else 'r'
            secondary_source=direction(converted_rest,src,'oya1_'+side+'_n')
            secondary_target=td(name,'Bip01_'+side.upper()+'_Finger0')
        alignment[name]=frame(a,secondary_source) @ frame(b,secondary_target).inverted()
    scale=target['Bip01']['world'].translation.y/source_rest['center_c_n'].translation.y
    knife=args.pz_media/'anims_X/Bob/Bob_AttackKnife01_Hit.x'
    grip,fingers=native_knife_grip(knife.read_text())
    def source_pose(animation,time):
        world={}
        for b in bones:
            k=animation.bones.get(b.name)
            q=evaluate(k.rotation if k else None,time,rotation(b.local_rot),True)
            loc=evaluate(k.location if k else None,time,Vector(b.local_pos[:3]))
            local=Matrix.LocRotScale(loc,q,Vector((1,1,1)))
            world[b.name]=(world[bones[b.parent_index].name] if b.parent_index>=0 else Matrix.Identity(4)) @ local
        return world
    def render_frame(name,depth=0):
        indent=' '*depth;v=[v for row in target[name]['local'].transposed() for v in row]
        lines=[indent+'Frame '+name+' {',indent+' FrameTransformMatrix { '+','.join(f'{v:.9f}' for v in v)+';; }']
        for child,b in target.items():
            if b['parent']==name:lines.append(render_frame(child,depth+1))
        return '\n'.join(lines+[indent+'}'])
    skeleton='\n'.join(render_frame(n) for n,b in target.items() if b['parent'] is None)
    header=re.split(r'(?m)^Material \w+\s*\{',text[:start])[0]
    support='''
Mesh MadDog_ImportSupport {
3; 0.0;0.0;0.0;, 0.001;0.0;0.0;, 0.0;0.001;0.0;;
1; 3;0,1,2;;
XSkinMeshHeader { 1;3;1; }
SkinWeights { "Bip01";3;0,1,2;1.0,1.0,1.0;
1.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,1.0;; }
}
AnimTicksPerSecond { 4800; }
'''
    args.output.mkdir(parents=True,exist_ok=True);args.samples.mkdir(parents=True,exist_ok=True)
    records=[]
    for entry in CLIPS:
        source=args.source/entry['source'];animation=read_gmt(str(source)).animation
        end=animation.end_frame;fps=animation.frame_rate
        transforms={n:[] for n in target};samples=[]
        for time in range(end+1):
            src_pose=source_pose(animation,time);world={};local={}
            root_delta=conversion.to_3x3() @ (src_pose['center_c_n'].translation-source_rest['center_c_n'].translation)*scale
            root_delta.x=0;root_delta.z=0
            for name,rest in target.items():
                parent=rest['parent'];parent_world=world[parent] if parent else Matrix.Identity(4)
                mat=rest['local'].copy()
                if name in mapping:
                    src=mapping[name][0];current=conversion @ src_pose[src] @ conversion
                    delta=current.to_quaternion().to_matrix().to_4x4() @ converted_rest[src].to_quaternion().inverted().to_matrix().to_4x4()
                    desired=delta @ alignment[name] @ rest['world'].to_quaternion().to_matrix().to_4x4()
                    mat=Matrix.LocRotScale(mat.translation,parent_world.to_quaternion().inverted() @ desired.to_quaternion(),Vector((1,1,1)))
                elif name in fingers:mat=fingers[name].copy()
                if name=='Bip01':mat.translation=parent_world.inverted() @ (rest['world'].translation+root_delta)
                world[name]=parent_world @ mat
                if name=='Bip01_Prop1':world[name]=world['Bip01_R_Hand'] @ grip;mat=parent_world.inverted() @ world[name]
                local[name]=mat;transforms[name].append(mat)
            if time in {round(end*i/4) for i in range(5)}:
                samples.append({'frame':time,'world':{n:[v for row in m for v in row] for n,m in world.items()}})
        output=[header,skeleton,support,'AnimationSet '+entry['name']+' {']
        for name,keys in transforms.items():
            output.append(' Animation { { '+name+' }')
            for label,kind in [('R',0),('T',2),('S',1)]:
                previous=None;rows=[]
                for time,mat in enumerate(keys):
                    if kind==0:
                        value=mat.to_quaternion().conjugated().normalized()
                        if previous is not None and value.dot(previous)<0:value.negate()
                        previous=value.copy()
                    else:value=mat.translation if kind==2 else Vector((1,1,1))
                    assert all(math.isfinite(v) for v in value)
                    rows.append(f'{round(time*4800/fps)};{len(value)};'+','.join(f'{v:.9f}' for v in value)+';;')
                output.append(f'  AnimationKey {label} {{ {kind}; {len(keys)};\n'+',\n'.join(rows)+';\n }')
            output.append(' }')
        output.append('}')
        path=args.output/(entry['name']+'.x');path.write_text('\n'.join(output)+'\n')
        record=dict(entry,frames=end,fps=fps,duration=end/fps,channels=len(target),
                    source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),output_sha256=hashlib.sha256(path.read_bytes()).hexdigest())
        records.append(record)
        (args.samples/(entry['name']+'.json')).write_text(json.dumps(samples))
        print('EXPORTED',entry['name'],end,'frames;',len(target),'Human channels',flush=True)
    manifest={'source_game':'Yakuza 0 (supplied local PC installation)','archive':'media/data/motion_w64/BattlePlayerMajimaL.par',
              'source_model':args.gmd.name,'source_model_archive':'media/data/chara/w64/adv/c_cm_majima_origin/mesh.par',
              'source_model_sha256':hashlib.sha256(args.gmd.read_bytes()).hexdigest(),
              'target_bind_source':'media/models_X/Skinned/MaleBody.x','target_bind_sha256':hashlib.sha256(target_path.read_bytes()).hexdigest(),
              'native_grip_animation':'media/anims_X/Bob/Bob_AttackKnife01_Hit.x','native_grip_sha256':hashlib.sha256(knife.read_bytes()).hexdigest(),
              'retarget':'Direct GMT/GMD FK, Z handedness conversion preserving left/right, native inverse-skin bind and anatomical roll calibration. Source frame times and scaled vertical root motion; planar root travel removed. No IK, floor reconstruction, generated poses or time reversal.',
              'source_to_target':[list(row) for row in conversion],'scale':scale,'bone_map':mapping,'clips':records}
    (args.output.parents[3]/'docs/motion-provenance.json').write_text(json.dumps(manifest,indent=2)+'\n')

if __name__=='__main__':main()
