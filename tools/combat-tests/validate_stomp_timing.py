from pathlib import Path
import array,hashlib,json,math,subprocess,sys,wave

root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza'
if '--inside-blender'not in sys.argv:
    result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python-exit-code','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True)
    assert result.returncode==0,result.stdout+result.stderr
    assert 'PASS native stomp'in result.stdout,result.stdout
    print(result.stdout.strip());raise SystemExit(0)
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,world
from native_body_geometry import load_body,skin_part
report=json.loads((mod/'docs/ground-heat-assets.json').read_text());align=json.loads((mod/'docs/ground-contact-alignment.json').read_text());actor,victim=[read(mod/c['output'])for c in report['clips']]
for c in report['clips']:assert hashlib.sha256((mod/c['output']).read_bytes()).hexdigest()==c['sha256']
for model in align['sources']:
    body=load_body(model['path']);distances={}
    for frame in range(20,31):
        ap,vp=report['paths'][0][frame],report['paths'][1][frame];shift=Vector(((vp[1]+align['offset'][1]-ap[1])/1.5,0,-(vp[0]+align['offset'][0]-ap[0])/1.5))
        a=world(actor[1],locals_at(actor[1],actor[2],frame*160));v=world(victim[1],locals_at(victim[1],victim[2],frame*160))
        head=[p+shift for p in skin_part(body,v,['Bip01_Head'])];foot=skin_part(body,a,['Bip01_R_Foot','Bip01_R_Toe0']);distances[frame]=min((x-y).length for x in foot for y in head)
    assert next(frame for frame,distance in distances.items()if distance<.02)==30,distances
scene=next(r for r in json.loads((mod/'docs/heat-scenes.json').read_text())['scenes']if r['id']=='ground');definition=scene['definitions'][0];event=definition['audioEvents'][0]
assert event['sourceAtMs']==0 and definition['contacts'][0]['atMs']==1000 and event['atMs']==875
sound=mod/'42/media/sound/ProjectYakuza/HeatScene_ground_0.wav'
with wave.open(str(sound))as w:block=w.getframerate()//200*w.getnchannels();samples=array.array('h',w.readframes(w.getnframes()))
rms=[math.sqrt(sum(v*v for v in samples[i:i+block])/len(samples[i:i+block]))for i in range(0,len(samples),block)];onset=next(i for i,v in enumerate(rms)if v>=max(rms)*.65)*5
assert onset==event['attackLeadMs']==125 and event['atMs']+onset==1000
data=json.loads((mod/'docs/heat-presentation-data.json').read_text());clip=next(c for c in data['clips']if c['animation']==definition['animation'])
assert len(clip['effects'])==1 and clip['effects'][0]['impact']and clip['effects'][0]['atMs']==1000
assert clip['effects'][0]['point']==clip['contacts'][0]['point']and clip['contacts'][0]['bone']=='Bip01_Head'
assert not definition['particles']and not scene['damage']
print('PASS native stomp: male/female first sole/head contact frame 30, unchanged source clips, original PCM onset 125ms + runtime start 875ms = contact 1000ms; one anchored existing impact, no invented CMN blood/damage nodes')
