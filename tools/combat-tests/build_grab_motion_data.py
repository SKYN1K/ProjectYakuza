from pathlib import Path
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,world
MOD=ROOT/'combat/ProjectYakuza';ANIMS=MOD/'42/media/anims_X/Bob'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
rows=[];records=[]
for index in range(1,5):
    actor=ANIMS/f'ProjectYakuza_DD_GrabStrike{index:02}.x';victim=ANIMS/f'ProjectYakuza_DD_GrabStrikeVictim{index:02}.x'
    _,ab,ac,_=read(actor);_,vb,vc,_=read(victim);points=[]
    for frame in range(len(ac['Bip01_L_Hand'][0])):
        hand=world(ab,locals_at(ab,ac,frame*160))['Bip01_L_Hand'].translation
        neck=world(vb,locals_at(vb,vc,frame*160))['Bip01_Neck'].translation
        points.append([-1.5*(hand.z+neck.z),1.5*(hand.x+neck.x)])
    assert all(0<p[0]<1.5 and abs(p[1])<.75 for p in points)
    rows.append('M.strikes['+str(index)+']={fps=30,frames={'+','.join('{'+','.join(format(v,'.9g')for v in p)+'}'for p in points)+'}}')
    records.append({'actor':actor.name,'actorSha256':sha(actor),'victim':victim.name,'victimSha256':sha(victim),'frames':len(points)})
attempt=ANIMS/'ProjectYakuza_DD_GrabAttempt.x';_,bones,curves,_=read(attempt)
feet=[{side:world(bones,locals_at(bones,curves,frame*160))['Bip01_'+side+'_Foot'].translation for side in ['L','R']}for frame in range(49)]
travel=[0.0];plants=[]
for previous,current in zip(feet,feet[1:]):
    side=min(['L','R'],key=lambda s:(previous[s].y+current[s].y)/2)
    travel.append(travel[-1]+max(0,1.5*(current[side].z-previous[side].z)))
    plants.append(side)
assert .5<travel[-1]<2
rows.append('M.reach={fps=30,frames={'+','.join(format(v,'.9g')for v in travel)+'}}')
text='require "ProjectYakuza/Registry"\nlocal M={strikes={}};ProjectYakuza.GrabMotion=M\n'+'\n'.join(rows)+'\n'
out=MOD/'42/media/lua/shared/ProjectYakuza/GrabMotion.lua'
report={'version':'1.0.12','operation':'Numeric placement only. Restored full-body paired strikes track the original left-hand/collar separation at every source frame. In-place grab reach advances by the backward displacement of the lower support foot, preserving its original step timing. No visual, audio or motion assets generated.','strikes':records,'attempt':attempt.name,'attemptSha256':sha(attempt),'supportFeet':plants,'reachTiles':travel[-1],'reachSamples':travel,'outputSha256':hashlib.sha256(text.encode()).hexdigest()}
if '--validate'in sys.argv:
    assert out.read_text(encoding='utf-8')==text
    assert json.loads((MOD/'docs/grab-motion-1.0.12.json').read_text(encoding='utf-8'))==report
else:
    out.write_text(text,encoding='utf-8',newline='\n')
    (MOD/'docs/grab-motion-1.0.12.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('PASS numeric grab placement from original paired clips and footsteps:',travel[-1],'tiles')
