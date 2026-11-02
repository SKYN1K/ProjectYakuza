from pathlib import Path
import sys,json,hashlib,math,subprocess,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout)
    if r.returncode or 'PASS reverse and paired source'not in r.stdout:raise SystemExit(r.stderr or 'source checks failed')
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';cp='.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*'
    records=json.loads((mod/'docs/reverse-finisher-assets.json').read_text(encoding='utf-8'))['clips']+json.loads((mod/'docs/heat-rush-assets.json').read_text(encoding='utf-8'))['clips']
    for args in [['AnimationProbe',*[str(mod/c['output'])for c in records]],['PropAttachmentProbe',str(w/'heat-rush-prop-contract.tsv')],['HeatRushAssetProbe',str(mod/'42/media/AnimSets/player')]]:subprocess.run([java,'-cp',cp,*args],cwd=w,check=True)
    raise SystemExit(0)
sys.path.insert(0,str(w));from locomotion_math import read,locals_at
reverse=json.loads((mod/'docs/reverse-finisher-assets.json').read_text(encoding='utf-8'));rush=json.loads((mod/'docs/heat-rush-assets.json').read_text(encoding='utf-8'))
assert rush['victimFacing']=={'forward':-1,'right':0}
assert rush['contactFrames']==[56,63,77,85,102,110,143]and rush['qteBindings']==['light','finisher','grab']*2
assert len(reverse['clips'])==8 and len(rush['clips'])==2 and sha(rush['archive'])==rush['archiveSha256']
contracts=[];samples=0
for record in reverse['clips']+rush['clips']:
    output=mod/record['output'];assert sha(output)==record['sha256']and sha(record['source'])==record['sourceSha256']
    if 'bep'in record:assert sha(record['bep'])==record['bepSha256']
    if 'retargetPath'in record:raw=Path(record['retargetPath']);first,last=record['frames'];frames=last-first+1
    else:raw=root/'tools/rush-retail-build/ProjectYakuza/42/media/anims_X/Bob'/output.name;first=0;frames=record['frames']
    assert sha(raw)==record['retargetSha256']
    _,bones,anim,_=read(output);_,original,curves,_=read(raw)
    for bone,channels in anim.items():
        for kind,keys in channels.items():assert len(keys)==frames and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
    for i in range(frames):
        actual=locals_at(bones,anim,i*160);expected=locals_at(original,curves,(i+first)*160)
        for bone in actual:
            if bone in ['Bip01_Prop1','Bip01_Prop2']:continue
            assert max(abs(actual[bone][a][b]-expected[bone][a][b])for a in range(4)for b in range(4))<.00001,(output,bone,i);samples+=1
    grip=reverse['nativeGrip']if'retargetPath'in record else rush['nativeGrip'];offsets=[','.join(str(v)for row in grip['nativeOffsets'][prop]for v in row)for prop in ['Bip01_Prop1','Bip01_Prop2']];contracts.append('\t'.join([str(output),*offsets,str(frames)]))
for mapping,stem in reverse['commandMappings'].items():assert (mapping+'\0'+stem+'\0').encode()in Path(reverse['commandSource']).read_bytes()
assert sha(reverse['commandSource'])==reverse['commandSha256']
(w/'heat-rush-prop-contract.tsv').write_text('\n'.join(contracts),encoding='utf-8')
assert not list((mod/'42/media').rglob('*Barrage*'))
assert all(len(path)==225 and all(math.isfinite(v)for row in path for v in row)for path in rush['paths'])
assert len(list((mod/'42/media/AnimSets/player').rglob('ProjectYakuza_MP_*.xml')))==350
assert abs(rush['pathScale']-.664628963721426)<1e-9
for record,path in zip(rush['clips'],rush['rawPaths']):
    from types import ModuleType
    package=ModuleType('yk');package.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=package
    from yk.gmt_lib import read_gmt
    a=read_gmt(record['source']).animation
    for bone in a.bones.values():
        for curve in bone.curves:
            if int(curve.type)in(0,1):curve.fill_channels()
    keys=a.bones['vector_c_n'].location.keyframes
    def sample(f):
        from mathutils import Vector
        if f<=keys[0].frame:return Vector(keys[0].value)
        for left,right in zip(keys,keys[1:]):
            if f<=right.frame:return Vector(left.value).lerp(Vector(right.value),(f-left.frame)/(right.frame-left.frame))
        return Vector(keys[-1].value)
    actor=read_gmt(rush['clips'][0]['source']).animation
    for curve in actor.bones['vector_c_n'].curves:
        if int(curve.type)==1:curve.fill_channels()
    anchor=actor.bones['vector_c_n'].location.keyframes[0].value
    from mathutils import Quaternion,Vector
    rotation=Quaternion(rush['sceneRotation'])
    for i,row in enumerate(path):v=rotation@(sample(i)-Vector(anchor));assert abs(row[0]-v.z*rush['pathScale'])<1e-8 and abs(row[1]-v.x*rush['pathScale'])<1e-8
from mathutils import Quaternion
end_rotations=[]
for record in rush['clips']:
    animation=read_gmt(record['source']).animation;curve=animation.bones['vector_c_n'].rotation;curve.fill_channels()
    key=curve.keyframes[-1].value;end_rotations.append(Quaternion((key[3],*key[:3])))
relative=end_rotations[0].inverted()@end_rotations[1]
forward=relative.to_matrix()@Vector((0,0,1));assert abs(forward.z+1)<1e-6 and abs(forward.x)<1e-6
from paired_paths import bridge_scene_cuts
expected,cuts=bridge_scene_cuts(rush['rawPaths']);assert expected==rush['paths']and cuts==rush['sceneCuts']
assert [c['frame']for c in cuts]==[]
print('PASS reverse and paired source archive/GMT/BEP hashes, all retained frames,',samples,'finite unchanged retarget-body samples, original vector paths, source command mappings and removed automatic clips')
