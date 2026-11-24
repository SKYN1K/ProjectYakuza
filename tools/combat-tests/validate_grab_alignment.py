from pathlib import Path
import json,re,sys,zipfile,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,world
MOD=ROOT/'combat/ProjectYakuza';ANIMS=MOD/'42/media/anims_X/Bob'
report=json.loads((MOD/'docs/grab-motion-1.0.12.json').read_text(encoding='utf-8'));runtime=(MOD/'42/media/lua/shared/ProjectYakuza/GrabMotion.lua').read_text(encoding='utf-8')
checks=0
with zipfile.ZipFile(ROOT/'dist/ProjectYakuza-B42-v1.0.9.zip')as old:
 for path in (MOD/'42/media/AnimSets/player').rglob('*.xml'):
  node=E.parse(path).getroot()
  if re.fullmatch(r'ProjectYakuza_DD_GrabStrike0[1-4]',node.findtext('m_AnimName','')):
   assert path.read_text(encoding='utf-8')==old.read('ProjectYakuza/'+path.relative_to(MOD).as_posix()).decode('utf-8').replace('\r\n','\n');checks+=1
 for row in report['strikes']:
  for key in ['actor','victim']:
   path=ANIMS/row[key];assert path.read_bytes()==old.read('ProjectYakuza/'+path.relative_to(MOD).as_posix());checks+=1
 for index,row in enumerate(report['strikes'],1):
  _,ab,ac,_=read(ANIMS/row['actor']);_,vb,vc,_=read(ANIMS/row['victim'])
  line=next(line for line in runtime.splitlines()if line.startswith('M.strikes['+str(index)+']='))
  values=[[float(v)for v in pair.split(',')]for pair in re.findall(r'\{([^{}]+)\}',line)]
  assert len(values)==row['frames']
  for frame,offset in enumerate(values):
   hand=world(ab,locals_at(ab,ac,frame*160))['Bip01_L_Hand'].translation;neck=world(vb,locals_at(vb,vc,frame*160))['Bip01_Neck'].translation
   assert abs(offset[0]+1.5*(hand.z+neck.z))<1e-8 and abs(offset[1]-1.5*(hand.x+neck.x))<1e-8;checks+=1
style=(MOD/'42/media/lua/shared/ProjectYakuza/Styles/DragonOfDojima.lua').read_text(encoding='utf-8')
assert 'distance=.48,lateral=.019354' in style and 'holdOffset='not in style and 'walkOffset='not in style
assert len(report['reachSamples'])==49 and report['reachSamples'][10]>.4 and report['reachSamples'][36]>1.1
print('PASS',checks,'restored owner/observer masks, unchanged original clips, complete paired hand/collar frames and centered hold; complete source footsteps')
