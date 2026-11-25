from pathlib import Path
import hashlib,json,sys
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,world
MOD=ROOT/'combat/ProjectYakuza';ANIMS=MOD/'42/media/anims_X/Bob';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
grip=json.loads((MOD/'docs/grab-grip-1.0.14.json').read_text(encoding='utf-8'));palm=Vector(grip['palmLocalPoint']);collar=Vector(grip['collarLocalPoint'])
_,hb,hc,_=read(ANIMS/'ProjectYakuza_DD_GrabHold.x');_,vb,vc,_=read(ANIMS/'ProjectYakuza_DD_GrabVictimHoldNative.x')
_,nb,nc,_=read('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob/Bob_IdleAim1Hand.x');native=locals_at(nb,nc,0)
def hold(time):
 local=locals_at(hb,hc,time*4800);result={k:v.copy()for k,v in native.items()}
 for key in hb:
  current=key
  if key in ['Bip01','Bip01_Pelvis','Bip01_Spine','Bip01_Prop1','Bip01_Prop2']:result[key]=local[key];continue
  while current:
   if current=='Bip01_Spine1':result[key]=local[key];break
   current=hb[current]['parent']
 return result

def blend(a,b,weight):
 result={}
 for key,left in a.items():
  right=b[key];q=left.to_quaternion().slerp(right.to_quaternion(),weight);value=q.to_matrix().to_4x4();value.translation=left.translation.lerp(right.translation,weight);result[key]=value
 return result

def point(ab,a,vb,v):
 hand=world(ab,a)['Bip01_L_Hand']@palm;contact=world(vb,v)['Bip01_Spine1']@collar
 return [-1.5*(hand.z+contact.z),1.5*(hand.x+contact.x)]

def row(points):
 assert all(0<p[0]<1.5 and abs(p[1])<.75 for p in points)
 return '{'+','.join('{'+','.join(format(v,'.9g')for v in p)+'}'for p in points)+'}'
nativePath=ROOT/'tools/combat-tests/grab-return-native.json';nativeReturns=json.loads(nativePath.read_text(encoding='utf-8'))
for name,digest in nativeReturns['sourceHashes'].items():
 path=ANIMS/name if (ANIMS/name).exists()else Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob')/name
 assert sha(path)==digest,('stale native grip reference',name)
rows=[];records=[]
for index in range(1,5):
 actor=ANIMS/f'ProjectYakuza_DD_GrabStrike{index:02}.x';victim=ANIMS/f'ProjectYakuza_DD_GrabStrikeVictim{index:02}.x';_,ab,ac,_=read(actor);_,vb,vcstrike,_=read(victim);count=len(ac['Bip01_L_Hand'][0]);points=[]
 for frame in range(count):points.append(point(ab,locals_at(ab,ac,frame*160),vb,locals_at(vb,vcstrike,frame*160)))
 rows.append('M.strikes['+str(index)+']={fps=30,frames='+row(points)+'}')
 lastA=locals_at(ab,ac,(count-1)*160);lastV=locals_at(vb,vcstrike,(count-1)*160);returns=[]
 for frame in range(25):
  time=frame/100;weight=frame/24;returns.append(point(ab,blend(lastA,hold(time),weight),vb,blend(lastV,locals_at(vb,vc,time*4800),weight)))
 reference=[[r['forward'],r['right']]for r in nativeReturns['cases']if r['index']==index]
 assert len(reference)==25 and max(sum((a-b)**2 for a,b in zip(p,q))**.5 for p,q in zip(reference,returns))<.002
 returns=reference
 rows.append('M.returns['+str(index)+']={fps=100,frames='+row(returns)+'}')
 assert abs(returns[-1][0]-grip['distance'])<.00002 and abs(returns[-1][1]-grip['lateral'])<.00002,(index,returns[-1],grip['distance'],grip['lateral'])
 records.append({'actor':actor.name,'actorSha256':sha(actor),'victim':victim.name,'victimSha256':sha(victim),'frames':count,'returnFrames':len(returns)})
attempt=ANIMS/'ProjectYakuza_DD_GrabAttempt.x';_,bones,curves,_=read(attempt)
feet=[{side:world(bones,locals_at(bones,curves,frame*160))['Bip01_'+side+'_Foot'].translation for side in ['L','R']}for frame in range(49)]
travel=[0.0];plants=[]
for previous,current in zip(feet,feet[1:]):
 side=min(['L','R'],key=lambda s:(previous[s].y+current[s].y)/2);travel.append(travel[-1]+max(0,1.5*(current[side].z-previous[side].z)));plants.append(side)
rows.append('M.reach={fps=30,frames={'+','.join(format(v,'.9g')for v in travel)+'}}')
text='require "ProjectYakuza/Registry"\nlocal M={strikes={},returns={}};ProjectYakuza.GrabMotion=M\n'+'\n'.join(rows)+'\n';out=MOD/'42/media/lua/shared/ProjectYakuza/GrabMotion.lua'
report={'version':'1.0.14','operation':'Native palm/upper-collar surface placement from original strike clips. Return curves follow the actual full-body to corrected-hold local quaternion blend for 240 ms. Original strike motion, source frames and step timing remain.','strikes':records,'attempt':attempt.name,'attemptSha256':sha(attempt),'supportFeet':plants,'reachTiles':travel[-1],'reachSamples':travel,'outputSha256':hashlib.sha256(text.encode()).hexdigest(),'gripReference':'grab-grip-1.0.14.json','recoveryMs':240,'nativeReturnReferenceSha256':sha(nativePath),'nativeReturnBaseDiscrepancy':nativeReturns['maxBaseError'],'nativeHoldCases':nativeReturns['holdCases'],'nativeHoldMaxErrorTiles':nativeReturns['maxHoldError']}
if '--validate'in sys.argv:
 assert out.read_text(encoding='utf-8')==text and json.loads((MOD/'docs/grab-motion-1.0.14.json').read_text(encoding='utf-8'))==report
else:
 out.write_text(text,encoding='utf-8',newline='\n');(MOD/'docs/grab-motion-1.0.14.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('PASS native palm/collar placement:',sum(r['frames']for r in records),'strike frames, 100 recovery frames and original reach steps')
