from pathlib import Path
import sys,json,hashlib,math,subprocess
root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout)
    if r.returncode or 'PASS katana source'not in r.stdout:raise SystemExit(r.stderr or 'source checks failed')
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';cp='.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*'
    report=json.loads((mod/'docs/katana-heat-assets.json').read_text(encoding='utf-8'))
    for args in [['AnimationProbe',*[str(mod/c['output'])for c in report['clips']]],['PropAttachmentProbe',str(w/'katana-heat-prop-contract.tsv')],['KatanaHeatProbe',str(mod/'42/media/AnimSets')]]:subprocess.run([java,'-cp',cp,*args],cwd=w,check=True)
    raise SystemExit(0)
sys.path.insert(0,str(w));from locomotion_math import read,locals_at
report=json.loads((mod/'docs/katana-heat-assets.json').read_text(encoding='utf-8'))
assert len(report['clips'])==2 and sha(report['archive'])==report['archiveSha256']and sha(report['scene'])==report['sceneSha256']
assert report['contactFrames']==[20,28,54,97]
contracts=[];samples=0
for record in report['clips']:
    output=mod/record['output'];raw=root/'tools/katana-heat-build/ProjectYakuza/42/media/anims_X/Bob'/output.name
    assert sha(output)==record['sha256']and sha(record['source'])==record['sourceSha256']and sha(raw)==record['retargetSha256']
    _,bones,anim,_=read(output);_,original,curves,_=read(raw);frames=record['frames'];assert frames==141
    for bone,channels in anim.items():
        for kind,keys in channels.items():assert len(keys)==frames and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
    for i in range(frames):
        actual=locals_at(bones,anim,i*160);expected=locals_at(original,curves,i*160)
        for bone in actual:
            if bone in ['Bip01_Prop1','Bip01_Prop2']:continue
            assert max(abs(actual[bone][a][b]-expected[bone][a][b])for a in range(4)for b in range(4))<.00001,(output,bone,i);samples+=1
    grip=report['nativeGrip'];offsets=[','.join(str(v)for row in grip['nativeOffsets'][prop]for v in row)for prop in ['Bip01_Prop1','Bip01_Prop2']];contracts.append('\t'.join([str(output),*offsets,str(frames)]))
(w/'katana-heat-prop-contract.tsv').write_text('\n'.join(contracts),encoding='utf-8')
assert all(len(path)==141 and all(math.isfinite(v)for row in path for v in row)for path in report['paths'])
from types import ModuleType
package=ModuleType('yk');package.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=package
from yk.gmt_lib import read_gmt
from mathutils import Vector
animations=[read_gmt(c['source']).animation for c in report['clips']]
for a in animations:
    for curve in a.bones['vector_c_n'].curves:
        if int(curve.type)==1:curve.fill_channels()
anchor=animations[0].bones['vector_c_n'].location.keyframes[0].value
for a,path in zip(animations,report['paths']):
    keys=a.bones['vector_c_n'].location.keyframes
    def sample(f):
        if f<=keys[0].frame:return Vector(keys[0].value)
        for left,right in zip(keys,keys[1:]):
            if f<=right.frame:return Vector(left.value).lerp(Vector(right.value),(f-left.frame)/(right.frame-left.frame))
        return Vector(keys[-1].value)
    for i,row in enumerate(path):
        v=sample(i);assert abs(row[0]-(v.z-anchor[2])*report['pathScale'])<1e-8 and abs(row[1]-(v.x-anchor[0])*report['pathScale'])<1e-8
print('PASS katana source archive/GMT/scene hashes, 141 retained frames,',samples,'unchanged retarget body samples and original paired vector paths')
