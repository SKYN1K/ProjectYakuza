from pathlib import Path
import json,re,sys,hashlib,zipfile,xml.etree.ElementTree as E
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,world
MOD=ROOT/'combat/ProjectYakuza';ANIMS=MOD/'42/media/anims_X/Bob';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
grip=json.loads((MOD/'docs/grab-grip-1.0.14.json').read_text(encoding='utf-8'));motion=json.loads((MOD/'docs/grab-motion-1.0.14.json').read_text(encoding='utf-8'));runtime=(MOD/'42/media/lua/shared/ProjectYakuza/GrabMotion.lua').read_text(encoding='utf-8');palm=Vector(grip['palmLocalPoint']);collar=Vector(grip['collarLocalPoint']);target=Vector(grip['palmTarget']);checks=0;worst=0
_,nb,nc,_=read('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob/Bob_IdleAim1Hand.x');native=locals_at(nb,nc,0)
with zipfile.ZipFile(ROOT/'dist/ProjectYakuza-B42-v1.0.13.zip')as old:
 for row in grip['clips']:
  path=ANIMS/(row['clip']+'.x');assert sha(path)==row['outputSha256'];assert hashlib.sha256(old.read('ProjectYakuza/42/media/anims_X/Bob/'+path.name)).hexdigest()==row['inputSha256'];_,b,c,_=read(path)
  assert all(len(keys)==row['frames']for channels in c.values()for keys in channels.values())
  first=None
  for frame in range(row['frames']):
   local=locals_at(b,c,frame*160);pose=world(b,local)
   if row['clip']in ['ProjectYakuza_DD_GrabHold','ProjectYakuza_DD_GrabWalk']:
    error=(pose['Bip01_L_Hand']@palm-target).length;worst=max(worst,error);assert error<.00002
    for key in ['Bip01','Bip01_Pelvis','Bip01_Spine']:assert max(abs(local[key][i][j]-native[key][i][j])for i in range(4)for j in range(4))<.00002
   else:
    point=pose['Bip01_Spine1']@collar
    if first is None:first=point
    assert(point-first).length<.00002
   checks+=1
for index,row in enumerate(motion['strikes'],1):
 _,ab,ac,_=read(ANIMS/row['actor']);_,vb,vc,_=read(ANIMS/row['victim']);assert sha(ANIMS/row['actor'])==row['actorSha256']and sha(ANIMS/row['victim'])==row['victimSha256']
 line=next(line for line in runtime.splitlines()if line.startswith('M.strikes['+str(index)+']='));values=[[float(v)for v in pair.split(',')]for pair in re.findall(r'\{([^{}]+)\}',line)]
 for frame,offset in enumerate(values):
  hand=world(ab,locals_at(ab,ac,frame*160))['Bip01_L_Hand']@palm;contact=world(vb,locals_at(vb,vc,frame*160))['Bip01_Spine1']@collar
  assert abs(offset[0]+1.5*(hand.z+contact.z))<.000002 and abs(offset[1]-1.5*(hand.x+contact.x))<.000002;checks+=1
returns=json.loads((MOD/'docs/grab-return-1.1.2.json').read_text(encoding='utf-8'));reference=ROOT/returns['reference'];assert sha(reference)==returns['referenceSha256'];ref=json.loads(reference.read_text(encoding='utf-8'));assert ref['liveTail']and ref['mixedPoses']==4;assert ref['maxHoldError']<.0001 and ref['maxBaseError']<.0001
for row in ref['cases']:
 line=next(line for line in runtime.splitlines()if line.startswith('M.returns['+str(row['index'])+']='));values=[[float(v)for v in pair.split(',')]for pair in re.findall(r'\{([^{}]+)\}',line)];value=values[row['frame']]
 assert abs(value[0]-row['forward'])<.00000001 and abs(value[1]-row['right'])<.00000001;checks+=1
for path in (MOD/'42/media/AnimSets/player').rglob('*.xml'):
 n=E.parse(path).getroot()
 if n.findtext('m_AnimName')in ['ProjectYakuza_DD_GrabHold','ProjectYakuza_DD_GrabWalk']:
  weights={w.findtext('boneName'):w.findtext('includeDescendants','true')for w in n.findall('m_SubStateBoneWeights')}
  assert all(weights[key]=='false'for key in ['Bip01','Bip01_Pelvis','Bip01_Spine'])and weights['Bip01_Spine1']=='true';checks+=1
print('PASS',checks,'source-frame, fitted native palm/collar, stable parents and native recovery placements; max baked palm error',worst)
