from pathlib import Path
import hashlib,json,sys,subprocess,re,math,zipfile
root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;mod=root/'emotes/ProjectYakuzaEmotes';report=json.loads((mod/'docs/lau-weapon-emote-assets.json').read_text());sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()

if '--inside-blender'not in sys.argv:
    for p in report['provenance']:assert sha(p['path'])==p['sha256'],p['path']
    for key in ['output','selector']:assert sha(mod/report[key])==report[key+'Sha256'if key=='selector'else'sha256']
    spark=report['spark'];assert sha(mod/spark['output'])==spark['sha256']==spark['source']['output_sha256']
    from PIL import Image
    original=Image.open(spark['source']['source']).convert('RGBA');actual=Image.open(mod/spark['output']).convert('RGBA');assert actual.size==original.size==(16,32)and actual.tobytes()==original.tobytes()
    with zipfile.ZipFile(root/'dist/ProjectYakuzaEmotes-B42-v0.2.7.zip')as archive:
        for name in archive.namelist():
            if name.endswith('/')or Path(name).suffix not in ['.x','.xml']:continue
            assert archive.read(name)==(mod/name.removeprefix('ProjectYakuzaEmotes/')).read_bytes(),name
    subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python-exit-code','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,check=True)
    source=json.loads((mod/'docs/lau-spear-emote-assets.json').read_text());movement=root/'tools/lau-weapon-path.csv';movement.write_text('\n'.join(str(x)+','+str(-z)for x,y,z in source['deferredPath'])+'\n');prefix=['F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe','-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*'];clip=str(mod/report['output']);selector=str(mod/report['selector']);body='F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x'
    for args in [['AnimationProbe',clip],['MajimaEmoteProbe',body,clip,selector,'1213',report['clip']],['PropAttachmentProbe',str(w/'lau-weapon-props.tsv')],['StepUpMotionProbe',body,clip,selector,str(movement),report['clip']],['SpearSparkProbe',str(mod/report['spark']['output'])]]:subprocess.run(prefix+args,cwd=w,check=True)
    print('PASS custom Lau spear source provenance, unchanged existing emote media, original spark pixels and native Human/prop/movement/spark checks; no game launch')
    raise SystemExit

sys.path.insert(0,str(w))
from mathutils import Matrix,Vector,Quaternion
from mathutils.bvhtree import BVHTree
from locomotion_math import read,locals_at,world
from native_body_geometry import load_body,skin_part
_,bones,animation,_=read(mod/report['output']);_,bb,ba,_=read(mod/'42/media/anims_X/Bob/ProjectYakuza_LauSpearGround.x');source=json.loads((mod/'docs/lau-spear-emote-assets.json').read_text());bodyPath=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');body=load_body(bodyPath);model=json.loads((root/'combat/ProjectYakuza/docs/lau-spear-weapon-model.json').read_text());points=[Vector(p)for p in model['outputVertices']];grip=Matrix(source['grip']['offsets']['Bip01_Prop1']);changed={'Bip01_R_UpperArm','Bip01_R_Forearm','Bip01_R_Hand','Bip01_Prop1'};text=bodyPath.read_text();match=re.search(r'Mesh Body\s*\{\s*(\d+);',text);tail=text[match.end():];numbers=list(re.finditer(r'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?',tail));tail=tail[numbers[len(body['points'])*3-1].end():];match=re.search(r'(\d+)\s*;\s*\n\s*3;',tail);faces=[tuple(map(int,p))for p in re.findall(r'3;\s*(\d+),\s*(\d+),\s*(\d+);',tail[match.start():])[:int(match[1])]];armBones=['Bip01_'+s+'_'+p for s in ['R','L']for p in ['UpperArm','Forearm']];selected={i for i,weights in enumerate(body['weights'])if sum(weight for bone,weight,offset in weights if bone in armBones)>.6};faces=[face for face in faces if all(i in selected for i in face)];edges={tuple(sorted((a,b)))for face in model['faces']for a,b in zip(face,[*face[1:],face[0]])};encoded=[[],[]];maximumHand=0;minimumFloor=1;maxLimbError=0
assert report['frames']==1213 and report['fps']==120 and report['originalFrames']==304 and report['duration']==10.1 and report['sourceSamples']==source['sourceSamples']
for channels in animation.values():
    for keys in channels.values():assert len(keys)==1213 and all(t==i*40 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
for i,row in enumerate(report['samples']):
    local=locals_at(bones,animation,i*40);pose=world(bones,local);oldLocal=locals_at(bb,ba,i*40);oldPose=world(bb,oldLocal);prop=pose['Bip01_Prop1'];assert row['sourceFrame']==i/4
    for n in local:
        if n not in changed:assert max(abs(local[n][a][b]-oldLocal[n][a][b])for a in range(4)for b in range(4))<.0001,(i,n)
        else:assert(local[n].translation-oldLocal[n].translation).length<.00001 or n=='Bip01_Prop1'
    for a,b in [('Bip01_R_UpperArm','Bip01_R_Forearm'),('Bip01_R_Forearm','Bip01_R_Hand')]:
        error=abs((pose[b].translation-pose[a].translation).length-(oldPose[b].translation-oldPose[a].translation).length);maxLimbError=max(maxLimbError,error);assert error<.0001
    expected=oldPose['Bip01_Prop1'].to_quaternion()@Quaternion(row['wristCorrection']);assert 1-abs(expected.normalized().dot(prop.to_quaternion().normalized()))<.000001
    assert 1-abs((prop.to_quaternion().inverted()@pose['Bip01_R_Hand'].to_quaternion()).normalized().dot(grip.to_quaternion().inverted().normalized()))<.000001
    anchor=pose['Bip01_R_Hand']@grip.translation;assert(anchor-prop@Vector((0,row['gripY'],0))).length<.00005
    hand=skin_part(body,pose,['Bip01_R_Hand','Bip01_R_Finger']);hand=[prop.inverted()@p for p in hand];assert min(p.y for p in hand)>=report['shaftBounds'][0]-.0001 and max(p.y for p in hand)<=report['shaftBounds'][1]-.002
    actualCorrection=pose['Bip01_R_Hand'].translation-oldPose['Bip01_R_Hand'].translation;maximumHand=max(maximumHand,actualCorrection.length);assert actualCorrection.length<.041 and(actualCorrection-Vector(row['handCorrection'])).length<.00005
    bottom=min((prop@p).y for p in points);minimumFloor=min(minimumFloor,bottom);assert bottom>=source['ground']['floor']-.00005
    if i==36:assert abs(bottom-source['ground']['floor'])<.00005
    vertices=[sum(((pose[b]@offset@p)*weight for b,weight,offset in weights),Vector())for p,weights in zip(body['points'],body['weights'])];wrists=[pose['Bip01_'+s+'_Hand'].translation for s in ['R','L']];armFaces=[face for face in faces if all(min((vertices[v]-p).length for p in wrists)>.04 for v in face)];tree=BVHTree.FromPolygons(vertices,armFaces,all_triangles=True);spear=[prop@p for p in points]
    for a,b in edges:
        delta=spear[b]-spear[a]
        if delta.length<1e-6:continue
        hit,normal,index,distance=tree.ray_cast(spear[a],delta.normalized(),delta.length);assert hit is None,('spear intersects native arm',i/4)
    for index,(handName,propName)in enumerate([('Bip01_R_Hand','Bip01_Prop1'),('Bip01_L_Hand','Bip01_Prop2')]):encoded[index].append(','.join(str(v)for row in pose[handName].inverted()@pose[propName]for v in row))
(w/'lau-weapon-props.tsv').write_text('\t'.join([str(mod/report['output']),';'.join(encoded[0]),';'.join(encoded[1]),'1213']))
worst=0
for i in range(4849):
    pose=world(bones,locals_at(bones,animation,i*10));p=pose['Bip01_Prop1'].inverted()@(pose['Bip01_R_Hand']@grip.translation);error=math.hypot(p.x,p.z);worst=max(worst,error);assert error<.002
assert all(len(p)==3 and abs(p[1]-source['ground']['floor'])<.00005 for p in report['spark']['contacts'].values())
print('PASS 1213 native-length source-fit poses, original 10.1-second body/footwork, shaft-only closed-hand grip, floor strike, zero arm-surface intersections and 4849 interpolated grip checks; max wrist reach correction',maximumHand,'limb float roundtrip error',maxLimbError,'interpolated radial error',worst,flush=True)
