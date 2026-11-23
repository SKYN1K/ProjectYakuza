from pathlib import Path
import sys,re,json,hashlib
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,world
mod=root/'combat/ProjectYakuza';clips=mod/'42/media/anims_X/Bob';style=(mod/'42/media/lua/shared/ProjectYakuza/Styles/DragonOfDojima.lua').read_text(encoding='utf-8');moves=(mod/'42/media/lua/shared/ProjectYakuza/GrabMoves.lua').read_text(encoding='utf-8');records=[]
def bone(name,frame,key):
 p=clips/('ProjectYakuza_DD_'+name+'.x');_,b,c,_=read(p)
 return list(world(b,locals_at(b,c,frame*160))[key].translation),hashlib.sha256(p.read_bytes()).hexdigest()
def verify(actor,victim,frame,actual,clearance=0):
 hand,ah=bone(actor,frame,'Bip01_L_Hand');neck,vh=bone(victim,frame,'Bip01_Neck');expected=[-1.5*(hand[2]+neck[2])+clearance,1.5*(hand[0]+neck[0])]
 assert max(abs(a-b)for a,b in zip(expected,actual))<.000002,(actor,expected,actual)
 records.append({'actor':actor,'victim':victim,'frame':frame,'actorSha256':ah,'victimSha256':vh,'hand':hand,'neck':neck,'expected':expected,'configured':actual,'additionalHoldClearance':clearance})
hold=re.search(r'grab = \{[^\n]*?distance=([\d.]+),lateral=([\d.]+)',style);assert hold;verify('GrabHold','GrabVictimHoldNative',0,[float(v)for v in hold.groups()])
throw=re.search(r'throwOffset=\{forward=([\d.]+),right=([\d.]+)',style);verify('Throw','ThrowVictim',0,[float(v)for v in throw.groups()])
for i,row in enumerate(re.finditer(r'pairOffset=\{forward=([\d.-]+),right=([\d.-]+)\},animation="ProjectYakuza_DD_GrabStrike(\d+)"',moves),1):
 assert int(row[3])==i
 verify('GrabStrike%02d'%i,'GrabStrikeVictim%02d'%i,7 if i==1 else 17,[float(row[1]),float(row[2])])
assert len(records)==6
import xml.etree.ElementTree as E
_,nativeBones,native,_=read(Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob/Bob_IdleAim1Hand.x'))
mixedSamples=0
for clip in ['GrabHold','GrabWalk']:
 node=E.parse(mod/('42/media/AnimSets/player/actions/ProjectYakuza_DD_'+clip+'.xml')).getroot()
 mask=[(row.findtext('boneName'),row.findtext('includeDescendants')=='true')for row in node.findall('m_SubStateBoneWeights')]
 assert ('Bip01',False)in mask and ('Bip01_Pelvis',False)in mask and ('Bip01_Spine',False)in mask and ('Bip01_Spine1',True)in mask
 assert node.findtext('m_maxTorsoTwist')=='0'
 _,bones,curves,_=read(clips/('ProjectYakuza_DD_'+clip+'.x'))
 for frame in [0,5,10,15,20]:
  authored=locals_at(bones,curves,frame*160);mixed=locals_at(nativeBones,native,frame*160)
  selected=set()
  for name in bones:
   for ancestor,descendants in mask:
    current=name
    while current:
     if current==ancestor:
      selected.add(name);break
     if not descendants:break
     current=bones[current]['parent']
  for name in selected:mixed[name]=authored[name]
  actual=world(bones,mixed);expected=world(bones,authored)
  for name in ['Bip01_L_Hand','Bip01_R_Hand']:
   assert max(abs(actual[name][i][j]-expected[name][i][j])for i in range(4)for j in range(4))<.00001,(clip,frame,name)
   mixedSamples+=1
  assert 'Bip01_L_Thigh'not in selected and 'Bip01_R_Thigh'not in selected
report={'operation':'Root staging from converted native hand and victim neck transforms. Upper-body blend owns its root/pelvis/spine parent chain while native lower limbs remain available. No extra hold clearance. Original clip bytes unchanged.','pairs':records,'maskedHandSamples':mixedSamples}
print(json.dumps(report,indent=2))
print('PASS six native-skeleton offsets within 0.000002 tiles and',mixedSamples,'blended hold/walk hand transforms within 0.00001')
