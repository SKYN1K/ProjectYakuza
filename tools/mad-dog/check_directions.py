"""Independent original GMT FK versus native Human playback direction regression.

Run in Blender Python. Does not import the exporter or its reference poses.
Measures the true bind skeleton's toe/left axes, then checks every original frame
and limb after PZ's real loader flags and PRS matrix reconstruction on both rigs.
"""
import argparse,bisect,json,math,re,sys,types
from pathlib import Path
from mathutils import Matrix,Quaternion,Vector


def parse():
    p=argparse.ArgumentParser(description=__doc__)
    for name in ['gmt-importer','gmd','sources','runtime','pz-media','report']:
        p.add_argument('--'+name,type=Path,required=True)
    return p.parse_args(sys.argv[sys.argv.index('--')+1:])


def main():
    a=parse();root=Path(__file__).resolve().parents[2]
    manifest=json.loads((root/'styles/ProjectYakuzaMadDog/docs/motion-provenance.json').read_text())
    pkg=types.ModuleType('independent_mad_dog');pkg.__path__=[str(a.gmt_importer)];sys.modules[pkg.__name__]=pkg
    from independent_mad_dog.read_gmd import read_gmd_bones
    from independent_mad_dog.gmt_lib import read_gmt
    bones=read_gmd_bones(str(a.gmd));source_rest={b.name:Vector(b.global_pos[:3]) for b in bones}
    text=(a.pz_media/'models_X/Skinned/MaleBody.x').read_text();target={}
    for match in re.finditer(r'SkinWeights\s*\{\s*"([^"]+)";\s*(\d+);([^}]+)\}',text):
        count=int(match[2]);v=[float(x) for x in re.findall(r'-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?',match[3])][count*2:]
        target[match[1]]=Matrix([v[i:i+4] for i in range(0,16,4)]).transposed().inverted()
    def local(name):
        m=re.search(r'Frame '+name+r'\s*\{\s*FrameTransformMatrix\s*\{([^}]+)\}',text)
        v=[float(x) for x in m[1].strip().rstrip(';').split(',')]
        return Matrix([v[i:i+4] for i in range(0,16,4)]).transposed()
    for s in 'LR':target['Bip01_'+s+'_Toe0']=target['Bip01_'+s+'_Foot'] @ local('Bip01_'+s+'_Toe0')
    target['Bip01']=target['Bip01_Pelvis'] @ local('Bip01_Pelvis').inverted()
    def basis(forward,left):
        forward=Vector((forward.x,0,forward.z)).normalized()
        left=Vector((left.x,0,left.z));left=(left-forward*left.dot(forward)).normalized()
        return Matrix((left,Vector((0,1,0)),forward)).transposed()
    source_basis=basis(sum((source_rest['asi4_'+s+'_n']-source_rest['asi3_'+s+'_n'] for s in 'lr'),Vector()),source_rest['asi1_l_n']-source_rest['asi1_r_n'])
    target_basis=basis(sum((target['Bip01_'+s+'_Toe0'].translation-target['Bip01_'+s+'_Foot'].translation for s in 'LR'),Vector()),target['Bip01_L_Thigh'].translation-target['Bip01_R_Thigh'].translation)
    conversion=target_basis @ source_basis.inverted()
    assert conversion.determinant()<-.999 and source_basis.col[2].z>.99 and target_basis.col[2].z<-.99
    assert source_basis.col[0].x>.99 and target_basis.col[0].x>.99,'Anatomical arm swap'
    def q(v):return Quaternion((v[3],v[0],v[1],v[2])).normalized()
    def sample(curve,time,default,rot=False):
        if curve is None or not curve.keyframes:return default.copy()
        curve.fill_channels();keys=curve.keyframes;i=max(0,bisect.bisect_right([k.frame for k in keys],time)-1)
        convert=q if rot else Vector;x=convert(keys[i].value)
        if i+1==len(keys) or time<=keys[i].frame:return x
        y=convert(keys[i+1].value);t=(time-keys[i].frame)/(keys[i+1].frame-keys[i].frame)
        return x.slerp(y,t) if rot else x.lerp(y,t)
    def original_pose(animation,time):
        result=[]
        for b in bones:
            clip=animation.bones.get(b.name)
            rotation=sample(clip.rotation if clip else None,time,q(b.local_rot),True)
            position=sample(clip.location if clip else None,time,Vector(b.local_pos[:3]))
            mat=Matrix.Translation(position) @ rotation.to_matrix().to_4x4()
            result.append(result[b.parent_index] @ mat if b.parent_index>=0 else mat)
        return {b.name:m.translation for b,m in zip(bones,result)}
    segments=[('Clavicle','UpperArm','kata','ude1'),('UpperArm','Forearm','ude1','ude2'),
              ('Forearm','Hand','ude2','ude3'),('Thigh','Calf','asi1','asi2'),('Calf','Foot','asi2','asi3'),('Foot','Toe0','asi3','asi4')]
    report={'source_front':list(source_basis.col[2]),'target_front':list(target_basis.col[2]),'basis_determinant':conversion.determinant(),'checks':0,'clips':{}}
    failures=[];scale=target['Bip01'].translation.y/source_rest['center_c_n'].y
    for clip in manifest['clips']:
        animation=read_gmt(str(a.sources/clip['source'])).animation
        source=[original_pose(animation,f) for f in range(animation.end_frame+1)]
        for body in ['MaleBody','FemaleBody']:
            runtime=json.loads((a.runtime/body/(clip['name']+'.json')).read_text())
            worst={'dot':1};root_error=0;reference_error=0
            assert len(runtime['samples'])==len(source)
            for pose in runtime['samples']:
                time=pose['frame'];original=source[time]
                current={n:Vector((m[3],m[7],m[11])) for n,m in zip(runtime['bones'],pose['matrices'])}
                for side,s in [('L','l'),('R','r')]:
                    for start,end,src,dst in segments:
                        expected=conversion @ (original[dst+'_'+s+'_n']-original[src+'_'+s+'_n'])
                        actual=current['Bip01_'+side+'_'+end]-current['Bip01_'+side+'_'+start]
                        dot=expected.normalized().dot(actual.normalized());report['checks']+=1
                        if dot<worst['dot']:worst={'dot':dot,'frame':time,'segment':side+'_'+start+'->'+end}
                expected=conversion @ (original['center_c_n']-source_rest['center_c_n'])*scale;expected.x=0;expected.z=0
                actual=current['Bip01']-target['Bip01'].translation
                root_error=max(root_error,(actual-expected).length)
            result={'worst_direction':worst,'max_root_error':root_error}
            report['clips'][body+'/'+clip['name']]=result
            if worst['dot']<.999 or root_error>.00002:failures.append(body+'/'+clip['name']+': '+str(result))
    report['failures']=failures;a.report.parent.mkdir(parents=True,exist_ok=True);a.report.write_text(json.dumps(report,indent=2)+'\n')
    if failures:raise AssertionError('\n'.join(failures))
    print('PASS:',report['checks'],'independent original-source limb-direction checks across both Human rigs; planar root fixed, vertical timing retained')

if __name__=='__main__':main()
