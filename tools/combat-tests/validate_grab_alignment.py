from pathlib import Path
import sys,re,json,zipfile,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,world
mod=root/'combat/ProjectYakuza';clips=mod/'42/media/anims_X/Bob';style=(mod/'42/media/lua/shared/ProjectYakuza/Styles/DragonOfDojima.lua').read_text(encoding='utf-8')
_,nativeBones,native,_=read('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob/Bob_IdleAim1Hand.x')
records=[];rootChecks=0
for name in ['GrabHold','GrabWalk']+['GrabStrike%02d'%i for i in range(1,5)]:
 path=clips/('ProjectYakuza_DD_'+name+'.x');_,bones,curves,_=read(path);node=E.parse(mod/('42/media/AnimSets/player/actions/ProjectYakuza_DD_'+name+'.xml')).getroot()
 masks=[(v.findtext('boneName'),v.findtext('includeDescendants','true')=='true')for v in node.findall('m_SubStateBoneWeights')]
 assert ('Bip01_Spine1',True)in masks and not any(k in ['Bip01','Bip01_Pelvis','Bip01_Spine']for k,_ in masks)
 selected=set()
 for nameBone in bones:
  for ancestor,descendants in masks:
   current=nameBone
   while current:
    if current==ancestor:selected.add(nameBone);break
    if not descendants:break
    current=bones[current]['parent']
 count=len(curves['Bip01_L_Hand'][0])
 for frame in range(count):
  authored=locals_at(bones,curves,frame*160);mixed=locals_at(nativeBones,native,frame*160);expected=world(nativeBones,mixed)
  for key in selected:mixed[key]=authored[key]
  actual=world(bones,mixed)
  for key in ['Bip01','Bip01_Pelvis','Bip01_Spine']:
   assert max(abs(actual[key][i][j]-expected[key][i][j])for i in range(4)for j in range(4))<.00001,(name,frame,key)
   rootChecks+=1
  if frame==0 and name in ['GrabHold','GrabWalk']:
   _,vb,vc,_=read(clips/'ProjectYakuza_DD_GrabVictimHoldNative.x');neck=world(vb,locals_at(vb,vc,0))['Bip01_Neck'].translation;hand=actual['Bip01_L_Hand'].translation
   measured=[-1.5*(hand.z+neck.z),1.5*(hand.x+neck.x)];field='holdOffset'if name=='GrabHold'else'walkOffset';match=re.search(field+r'=\{forward=([\d.]+),right=([\d.]+)',style);configured=[float(v)for v in match.groups()]
   error=sum((a-b)**2 for a,b in zip(measured,configured))**.5;assert error<.016 and sum(v*v for v in configured)**.5>.39
   records.append({'clip':name,'measuredHandNeckOffset':measured,'configured':configured,'planarErrorTiles':error})
 with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v1.0.9.zip')as z:assert z.read('ProjectYakuza/'+path.relative_to(mod).as_posix())==path.read_bytes()
for path in (mod/'42/media/AnimSets/player').rglob('*.xml'):
 node=E.parse(path).getroot()
 if node.findtext('m_AnimName')in ['ProjectYakuza_DD_GrabStrike%02d'%i for i in range(1,5)]:
  assert node.findtext('m_maxTorsoTwist')=='0'
assert 'pairOffset='not in(mod/'42/media/lua/shared/ProjectYakuza/GrabMoves.lua').read_text(encoding='utf-8')
report={'version':'1.0.10','operation':'Original source pose under the actual native parent mask, with bounded stationary collar clearance and a separately calibrated walking grip. Strike masks retain native root, pelvis and lower spine while retaining original upper-body and leg joints. Dragon strikes retain the held victim root offset instead of interpolating between unrelated source-root positions.','nativeParentTransformChecks':rootChecks,'referenceGripOffsets':records,'originalClipBytesUnchanged':True,'originalContactFramesUnchanged':True,'offlineOnly':True}
(mod/'docs/grab-staging-1.0.10.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('PASS',rootChecks,'native parent transforms, calibrated mixed-pose grips, stationary strike roots and unchanged source clips')
