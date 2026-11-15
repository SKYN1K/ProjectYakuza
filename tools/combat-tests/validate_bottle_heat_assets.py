from pathlib import Path
import sys,json,hashlib,math,subprocess
root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout)
    if r.returncode or 'PASS bottle source'not in r.stdout:raise SystemExit(r.stderr or 'source checks failed')
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';cp='.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*'
    report=json.loads((mod/'docs/bottle-heat-assets.json').read_text(encoding='utf-8'))
    for args in [['AnimationProbe',*[str(mod/c['output'])for c in report['clips']]],['PropAttachmentProbe',str(w/'bottle-heat-prop-contract.tsv')],['BottleHeatProbe',str(mod/'42/media/AnimSets')]]:subprocess.run([java,'-cp',cp,*args],cwd=w,check=True)
    raise SystemExit(0)
sys.path.insert(0,str(w));from locomotion_math import read,locals_at,world as matrices_at
from native_body_geometry import load_body,skin_part
from mathutils import Vector
body=load_body("F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x")
report=json.loads((mod/'docs/bottle-heat-assets.json').read_text(encoding='utf-8'))
assert len(report['clips'])==2 and sha(report['archive'])==report['archiveSha256']and sha(report['scene'])==report['sceneSha256']
assert report['contactFrames']==[22,73,92]
contracts=[];samples=0
for record in report['clips']:
    output=mod/record['output'];raw=root/'tools/bottle-heat-build/ProjectYakuza/42/media/anims_X/Bob'/output.name
    assert sha(output)==record['sha256']and sha(record['source'])==record['sourceSha256']and sha(raw)==record['retargetSha256']
    _,bones,anim,_=read(output);_,original,curves,_=read(raw);frames=record['frames'];assert frames==151
    for bone,channels in anim.items():
        for kind,keys in channels.items():assert len(keys)==frames and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
    for i in range(frames):
        actual=locals_at(bones,anim,i*160);expected=locals_at(original,curves,i*160)
        for bone in actual:
            if bone in ['Bip01_Prop1','Bip01_Prop2']:continue
            assert max(abs(actual[bone][a][b]-expected[bone][a][b])for a in range(4)for b in range(4))<.00001,(output,bone,i);samples+=1
    grip=report['nativeGrip'];offsets=[','.join(str(v)for row in grip['nativeOffsets'][prop]for v in row)for prop in ['Bip01_Prop1','Bip01_Prop2']]
    if output.stem=='ProjectYakuza_DD_BottleHeat':
        samplesRight=[]
        for frame in range(frames):
            pose=matrices_at(bones,locals_at(bones,anim,frame*160));palm=skin_part(body,pose,['Bip01_R_Hand']);assert(pose['Bip01_Prop1'].translation-sum(palm,Vector())/len(palm)).length<.00002;relative=pose['Bip01_R_Hand'].inverted()@pose['Bip01_Prop1'];samplesRight.append(','.join(str(v)for row in relative for v in row))
        offsets[0]=';'.join(samplesRight)
    contracts.append('\t'.join([str(output),*offsets,str(frames)]))
(w/'bottle-heat-prop-contract.tsv').write_text('\n'.join(contracts),encoding='utf-8')
assert all(len(path)==151 and all(math.isfinite(v)for row in path for v in row)for path in report['paths'])
from types import ModuleType
package=ModuleType('yk');package.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=package
from yk.gmt_lib import read_gmt
from mathutils import Vector,Quaternion
animations=[read_gmt(c['source']).animation for c in report['clips']]
for a in animations:
    for curve in a.bones['vector_c_n'].curves:
        if int(curve.type)==1:curve.fill_channels()
anchor=Vector(animations[0].bones['vector_c_n'].location.keyframes[0].value);rotation=Quaternion(report['sceneRotation'])
for a,path in zip(animations,report['rawPaths']):
    keys=a.bones['vector_c_n'].location.keyframes
    def sample(f):
        if f<=keys[0].frame:return Vector(keys[0].value)
        for left,right in zip(keys,keys[1:]):
            if f<=right.frame:return Vector(left.value).lerp(Vector(right.value),(f-left.frame)/(right.frame-left.frame))
        return Vector(keys[-1].value)
    for i,row in enumerate(path):
        v=rotation@(sample(i)-anchor);assert abs(row[0]-v.z*report['pathScale'])<1e-8 and abs(row[1]-v.x*report['pathScale'])<1e-8
from paired_paths import bridge_scene_cuts
expected,cuts=bridge_scene_cuts(report['rawPaths']);assert expected==report['paths']and cuts==report['sceneCuts']
assert max(__import__('math').dist(a,b)for path in report['paths']for a,b in zip(path,path[1:]))<.06
_,bones,curves,_=read(mod/report['clips'][1]['output']);local=locals_at(bones,curves,0);world={}
for bone,frame in bones.items():world[bone]=world[frame['parent']]@local[bone]if frame['parent']else local[bone]
assert world['Bip01'].translation.y>.4,'victim must start at native standing pelvis height'
print('PASS bottle source archive/GMT/scene hashes, 151 retained frames,',samples,'unchanged retarget body samples and normalized, continuous paired paths with native standing victim height')
