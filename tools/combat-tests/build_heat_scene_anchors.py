from pathlib import Path
import json,sys,hashlib,subprocess
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';write='--write'in sys.argv
if '--inside-blender'not in sys.argv:
    command=['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python',str(Path(__file__).resolve()),'--','--inside-blender',*(['--write']if write else[])]
    result=subprocess.run(command,cwd=root,capture_output=True,text=True);print(result.stdout);assert result.returncode==0 and'PASS CMN blood'in result.stdout,result.stderr
    raise SystemExit(0)
sys.path.insert(0,str(Path(__file__).parent))
from mathutils import Matrix,Vector
from locomotion_math import read,locals_at,world
data=json.loads((mod/'docs/heat-scenes.json').read_text());bind={n:Matrix(v['mat'])for n,v in json.loads(Path('C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/bind.json').read_text()).items()};mirror=Matrix.Diagonal((1,1,-1,1))
names={'face_c_n':'Bip01_Head','face':'Bip01_Head','kosi_c_n':'Bip01_Spine','kosi_n':'Bip01_Spine','mune_c_n':'Bip01_Spine1','mune_n':'Bip01_Spine1','ketu_c_n':'Bip01_Pelvis','ketu_n':'Bip01_Pelvis','center_n':'Bip01'}
for side in ['r','l']:
    for source,target in [('ude3','Hand'),('ude2','Forearm'),('asi2','Calf'),('asi3','Foot')]:names[source+'_'+side+'_n']='Bip01_'+side.upper()+'_'+target
definitions={};records=[]
for scene in data['scenes']:
    manifest=json.loads((mod/('docs/'+{'rush':'heat-rush-assets','crate':'crate-heat-assets','katana':'katana-heat-assets','wall':'wall-heat-assets','ground':'ground-heat-assets','bottle':'bottle-heat-assets','bat':'bat-heat-assets','bicycle':'bicycle-heat-assets'}[scene['id']]+'.json')).read_text())
    scale=manifest['pathScale']/1.5
    for definition in scene['definitions']:
        actor=mod/('42/media/anims_X/Bob/'+definition['animation']+'.x');victim=actor.with_name(actor.stem+'Victim.x');_,bones,animation,_=read(victim);events=[]
        for event in definition['particles']:
            bone=names.get(event['bone']);assert bone in bones,(definition['animation'],event['bone'])
            pose=world(bones,locals_at(bones,animation,event['frame']*160));local=bind[bone].to_quaternion().inverted()@(mirror@Vector(event['localPoint'])*scale);point=pose[bone]@local
            index=event['contact']if definition['animation']==scene['animation']else len(scene['definitions'][0]['contacts'])
            events.append({'atMs':event['frame']/30*1000,'index':index,'bone':bone,'point':list(point),'bloodOnly':True,'feedback':'blade'if scene['id']=='katana'and event['contact']!=2 else'blunt'if scene['id']in ['bat','bicycle']else'unarmed'})
        definitions[definition['animation']]=events;records.append({'animation':definition['animation'],'actorSha256':hashlib.sha256(actor.read_bytes()).hexdigest(),'victimSha256':hashlib.sha256(victim.read_bytes()).hexdigest(),'events':events})
report={'operation':'Original CMN blood-emitter starts and bone-local positions transformed through unchanged supplied native victim poses. Existing supplied blood pixels and renderer are reused; no images, motion or audio generated. Engine-specific non-blood particle systems are recorded by the CMN audit rather than invented.','moves':definitions,'clips':records}
p=mod/'docs/heat-scene-effects.json';text=json.dumps(report,indent=2)+'\n'
if write:p.write_bytes(text.encode())
else:assert p.read_bytes()==text.encode()
print('PASS CMN blood',len(records),'scene clips and',sum(len(v)for v in definitions.values()),'source-timed native bone anchors')
