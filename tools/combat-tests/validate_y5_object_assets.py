from pathlib import Path
import sys,json,hashlib,subprocess,math,xml.etree.ElementTree as E

root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza';media=mod/'42/media';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
heat=json.loads((mod/'docs/bicycle-heat-assets.json').read_text());attacks=json.loads((mod/'docs/y5-object-attacks.json').read_text())
java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe'
if '--inside-blender'not in sys.argv:
    for script in ['build_bicycle_texture.py','validate_y5_object_assets.py']:
        command=[sys.executable,str(w/script),'--validate']if script=='build_bicycle_texture.py'else ['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python',str(w/script),'--','--inside-blender']
        result=subprocess.run(command,cwd=root,capture_output=True,text=True);print(result.stdout);assert result.returncode==0 and 'PASS'in result.stdout,result.stderr
    for args in [['AnimationProbe',*[str(mod/c['output'])for c in attacks['clips']+heat['clips']]],['PropAttachmentProbe',str(w/'y5-object-prop-contract.tsv')],['BicycleHeatProbe',str(media/'AnimSets')],['BicycleAssetProbe',str(media)]]:
        subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*',*args],cwd=w,check=True)
    raise SystemExit(0)

sys.path.insert(0,str(w))
from mathutils import Matrix,Vector
from locomotion_math import read,locals_at,world
from y5_retarget import source_context,read_gmt
from weapon_hold_geometry import source_pose
from y5_source_assets import entry
saved=sys.argv;sys.argv=['validate','--validate'];exec(compile((w/'build_bicycle_model.py').read_text(),str(w/'build_bicycle_model.py'),'exec'),{'__file__':str(w/'build_bicycle_model.py'),'__name__':'validate_model'});sys.argv=saved
for record in attacks['archiveEntries']+json.loads((root/'extracted/bicycle-heat-097/models/index.json').read_text())+[json.loads((root/'extracted/bicycle-heat-097/bone-index.json').read_text())]:
    data,actual=entry(record['archive'],record['name']);assert actual==record
assert sha(heat['archive'])==heat['archiveSha256']and sha(heat['scene'])==heat['sceneSha256']and sha(heat['objectSource'])==heat['objectSha256']
index=json.loads((Path(heat['scene']).parents[1]/'index.json').read_text())
for record in index['entries']:assert sha(Path(heat['scene']).parents[1]/record['entry'])==record['sha256']
from read_heat_scene import read_scene
scene=read_scene(heat['scene']);damage=[(round(n['element']['start']),n['damage']['damage'])for n in scene['nodes']if 'damage'in n and n['role']=='victim'];assert [f for f,d in damage]==[131,158]and [d for f,d in damage]==heat['damageWeights']
for record in heat['retargetProvenance']+attacks['retargetProvenance']:assert sha(record['path'])==record['sha256']
mirror=Matrix.Diagonal((1,1,-1,1));contracts=[];samples=0;worst=0;vectors=[]
for c in attacks['clips']+heat['clips']:
    assert sha(c['source'])==c['sourceSha256']and sha(c['retarget'])==c['retargetSha256']and sha(mod/c['output'])==c['sha256']
    _,bones,animation,_=read(mod/c['output']);_,original,curves,_=read(c['retarget']);mapping=c.get('sourceFrames',list(range(c['frames'])));context=source_context('validate',c['source'],True)
    assert context['a'].frame_rate==30 and len(mapping)==c['frames']
    for channels in animation.values():
        for keys in channels.values():assert len(keys)==c['frames']and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
    for i,frame in enumerate(mapping):
        actual=locals_at(bones,animation,i*160);expected=locals_at(original,curves,frame*160);native=world(bones,actual);source=source_pose(context,frame)
        chest=(mirror@source['mune_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion();adapt=native['Bip01_Spine1'].to_quaternion()@chest.inverted();modified=set()
        for side in ['L','R']:
            suffix='_'+side.lower()+'_n'
            for bone,child,sb,sc in [('Clavicle','UpperArm','kata','ude1'),('UpperArm','Forearm','ude1','ude2'),('Forearm','Hand','ude2','ude3')]:
                name='Bip01_'+side+'_'+bone;child='Bip01_'+side+'_'+child;direction=(adapt@(mirror@(source[sc+suffix].translation-source[sb+suffix].translation))).normalized();error=math.acos(max(-1,min(1,direction.dot((native[child].translation-native[name].translation).normalized()))));worst=max(worst,error);assert error<.001,(c['output'],frame,name,error);modified.add(name)
                assert(actual[name].translation-expected[name].translation).length<1e-6
            modified.add('Bip01_'+side+'_Hand')
        for name in actual:
            if name in modified or name in ['Bip01_Prop1','Bip01_Prop2']:continue
            target=locals_at(original,curves,0)[name]if '_Finger'in name else expected[name]
            assert max(abs(actual[name][a][b]-target[a][b])for a in range(4)for b in range(4))<1e-5,(c['output'],frame,name);samples+=1
    offsets=[','.join(str(v)for row in heat['nativeGrip']['nativeOffsets'][prop]for v in row)for prop in ['Bip01_Prop1','Bip01_Prop2']]
    if c in heat['clips']:
        assert mapping==list(range(125,309));centre=context['a'].bones['center_n'];vectors.append([context['sample'](centre.location,f,Vector((0,0,0)))for f in mapping])
        if c['role']==0:
            objectMotion=read_gmt(heat['objectSource']).animation
            for curve in objectMotion.bones['root'].curves:
                if int(curve.type)in[0,1]:curve.fill_channels()
            expected=[]
            for i,frame in enumerate(mapping):
                from mathutils import Quaternion
                track=objectMotion.bones['root'];position=context['sample'](track.location,frame,Vector((0,0,0)));rotation=context['sample'](track.rotation,frame,Quaternion((1,0,0,0)),True);position+=rotation@Vector(heat['sourceAnchor']);position-=vectors[0][0];pose=mirror@rotation.to_matrix().to_4x4()@mirror;pose.translation=Vector((position.x*heat['modelScale'],(position.y+vectors[0][0].y)*heat['modelScale'],-position.z*heat['modelScale']));ap=heat['paths'][0][i];pose.translation-=Vector((ap[1]/1.5,0,-ap[0]/1.5));assert max(abs(pose[a][b]-heat['objectMatrices'][i][a][b])for a in range(4)for b in range(4))<1e-6
                native=world(bones,locals_at(bones,animation,i*160));assert max(abs(native['Bip01_Prop1'][a][b]-pose[a][b])for a in range(4)for b in range(4))<1e-5;expected.append(native['Bip01_R_Hand'].inverted()@pose)
            offsets[0]=';'.join(','.join(str(v)for row in matrix for v in row)for matrix in expected)
    else:
        end=c['frames']-1;node=E.parse(media/'AnimSets/player/melee'/Path(c['output']).with_suffix('.xml').name).getroot();events=[e for e in node.findall('m_Events')if e.findtext('m_EventName')=='AttackCollisionCheck'];assert len(events)==1 and abs(float(events[0].findtext('m_TimePc'))*end-c['contactFrame'])<1e-8
    contracts.append('\t'.join([str(mod/c['output']),*offsets,str(c['frames'])]))
paths=[[[float((v-vectors[0][0]).z*heat['pathScale']),float((v-vectors[0][0]).x*heat['pathScale'])]for v in values]for values in vectors];assert paths==heat['paths']
assert max(math.dist(a,b)for path in paths for a,b in zip(path,path[1:]))<.35
assert max(math.dist(a,b)for a,b in zip(*paths))<1.3
assert [c['contactFrame']for c in attacks['clips']]==[15,20,21,19,19]*2
assert [c['frames']for c in attacks['clips']]==[46,51,66,53,53]*2
(w/'y5-object-prop-contract.tsv').write_text('\n'.join(contracts))
print('PASS Y5 archive provenance, 12 native motion assets,',samples,'unchanged body/finger samples, original arm directions within',math.degrees(worst),'degrees, original bicycle object-root motion and two victim-only CMN contacts')
