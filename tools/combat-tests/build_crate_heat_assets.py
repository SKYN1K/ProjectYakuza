from pathlib import Path
import sys,json,hashlib,runpy,xml.etree.ElementTree as E
from mathutils import Matrix,Vector,Quaternion
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from native_body_geometry import load_body,skin_part,validate_bind
from locomotion_math import read,locals_at,world,blocks,write
ns=runpy.run_path(str(root/'tools/combat-tests/retarget_crate_heat.py'))
mod=root/'combat/ProjectYakuza';media=mod/'42/media';meta=json.loads((root/'tools/crate-original-retarget-0114.json').read_text());scale=meta['scale'];anchor=Vector(meta['roles'][0]['vectors'][0]);factor=scale/1.5
mapping=list(range(635));ending=list(range(454,635));records=[];C=Matrix.Diagonal((1,1,-1,1))
objSource=root/'extracted/crate-beercase-0114/000.par/h3000_000_7.gmt';obj=ns['read_gmt'](str(objSource)).animation.bones['beercase']
for curve in obj.curves:
 if int(curve.type)in(0,1):curve.fill_channels()
sample=ns['ns']['sample']
def objectPose(f):
 v=sample(obj.location,f,Vector((0,0,0)));v.x-=anchor.x;v.z-=anchor.z;v*=factor
 q=sample(obj.rotation,f,Quaternion((1,0,0,0)),True);m=C@q.to_matrix().to_4x4()@C;m.translation=Vector((v.x,v.y,-v.z));return m
actorRaw=Path(meta['roles'][0]['file']);_,ab,ac,_=read(actorRaw);a0=world(ab,locals_at(ab,ac,0));offset=objectPose(0).inverted()@a0['Bip01_Prop1']
paths=[[],[]];shift=[0.,0.]
rawPaths=[[[float((Vector(v)-anchor).z*scale),float((Vector(v)-anchor).x*scale)]for v in role['vectors']]for role in meta['roles']]
sourcePaths=json.loads(json.dumps(rawPaths))
for frame in range(len(mapping)):
 delta=Vector(rawPaths[0][frame])-Vector(rawPaths[1][frame])
 if delta.length>1.8:rawPaths[0][frame]=list(Vector(rawPaths[1][frame])+delta.normalized()*1.8)
 for role in range(2):
  if frame:
   delta=Vector(rawPaths[role][frame])-Vector(rawPaths[role][frame-1])
   if delta.length>.2:rawPaths[role][frame]=list(Vector(rawPaths[role][frame-1])+delta.normalized()*.2)
origin=Vector(rawPaths[0][0])
for role in range(2):rawPaths[role]=[list(Vector(v)-origin)for v in rawPaths[role]]
for i,f in enumerate(mapping):
 if i and f!=mapping[i-1]+1:
  for axis in range(2):shift[axis]+=rawPaths[0][mapping[i-1]][axis]-rawPaths[0][f][axis]
 for role in range(2):paths[role].append([rawPaths[role][f][a]+shift[a]for a in range(2)])
cuts=[]
for i in range(1,len(mapping)):
 if mapping[i]!=mapping[i-1]+1:
  delta=[paths[1][i-1][a]-paths[1][i][a]for a in range(2)];cuts.append({'frame':i,'correction':delta})
  for age in range(6):
   t=age/6;fade=1-t*t*(3-2*t)
   for a in range(2):paths[1][i+age][a]+=delta[a]*fade
endPaths=[[[rawPaths[r][f][a]-rawPaths[0][454][a]for a in range(2)]for f in ending]for r in range(2)]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');validate_bind(body)
model=json.loads((mod/'docs/beer-crate-assets.json').read_text());vertices=[Vector(v)*.5 for v in model['vertices']]
centre=Vector(tuple((min(v[i]for v in vertices)+max(v[i]for v in vertices))/2 for i in range(3)));roof=min(v.y for v in vertices)+.006
calibration=objectPose(60).to_3x3().inverted()@Matrix.Rotation(3.141592653589793,3,'X')
_,vb,vc,_=read(Path(meta['roles'][1]['file']))
for role,record in enumerate(meta['roles']):
 raw=Path(record['file']);text,b,c,spans=read(raw)
 for fail,frames in [(False,mapping),(True,ending)]:
  name='ProjectYakuza_DD_CrateHeat'+('Fail'if fail else'')+('Victim'if role else'');values=[locals_at(b,c,f*160)for f in frames]
  if not role:
   for f,v in zip(frames,values):
    w=world(b,v);prop=objectPose(f);prop=prop.to_3x3()@calibration;rotation=prop.copy();prop=prop.to_4x4();rootPath=rawPaths[0][f];prop.translation=objectPose(f).translation-Vector((rootPath[1]/1.5,0,-rootPath[0]/1.5))
    victim=world(vb,locals_at(vb,vc,f*160));ap,vp=rawPaths[0][f],rawPaths[1][f];shift=Vector(((vp[1]-ap[1])/1.5,0,-(vp[0]-ap[0])/1.5));head=[p+shift for p in skin_part(body,victim,['Bip01_Head'])];localHead=[rotation.inverted()@point for point in head];target=Vector(((min(p.x for p in localHead)+max(p.x for p in localHead))/2,min(p.y for p in localHead),(min(p.z for p in localHead)+max(p.z for p in localHead))/2));seated=rotation@(target-Vector((centre.x,roof,centre.z)));weight=max(0,min(1,f/50,(500-f)/46));weight=weight*weight*(3-2*weight);prop.translation=prop.translation.lerp(seated,weight);v['Bip01_Prop1']=w[b['Bip01_Prop1']['parent']].inverted()@prop
  out=media/'anims_X/Bob'/(name+'.x');write(out,text,spans,blocks(b,values,[i*160 for i in range(len(frames))],None),name)
  source=root/'extracted/crate-beercase-0114/000.par'/('h3000_000_3.gmt'if role else'h3000_000_1.gmt')
  records.append({'role':role,'ending':fail,'source':str(source),'sourceSha256':sha(source),'retarget':str(raw),'retargetSha256':sha(raw),'output':out.relative_to(mod).as_posix(),'sha256':sha(out),'frames':len(frames),'sourceFrames':frames,'fps':30})
  groups=['zombie/hitreaction','zombie/hitreaction-hit','zombie/idle','player/actions','player/hitreactionpvp']if role else['player/actions']
  for group in groups:
   stem='ProjectYakuza_PVP_BottleHeatVictim'if role and group.startswith('player')else'ProjectYakuza_DD_BottleHeat'+('Victim'if role else'');src=media/'AnimSets'/group/(stem+'.xml');n=E.parse(src).getroot();destStem=stem.replace('BottleHeat','CrateHeat'+('Fail'if fail else''));n.find('m_Name').text=destStem;n.find('m_AnimName').text=name
   for cond in n.findall('m_Conditions'):
    key=cond.findtext('m_Name')
    if key in ['PerformingAction','ProjectYakuzaPairedVictimClip']:cond.find('m_Value').text=name
    elif key=='ProjectYakuzaWeaponProfile':cond.find('m_Value').text='crate'
   E.ElementTree(n).write(src.with_name(destStem+'.xml'),encoding='utf-8',xml_declaration=True)
def lua(v):
 if isinstance(v,str):return json.dumps(v)
 if isinstance(v,bool):return str(v).lower()
 if isinstance(v,(int,float)):return format(v,'.9g')
 if isinstance(v,list):return '{'+','.join(lua(x)for x in v)+'}'
 return '{'+','.join(k+'='+lua(x)for k,x in v.items())+'}'
facing={'forward':float((ns['ns']['sample'](ns['ns']['a'].bones['center_n'].rotation,634,Quaternion((1,0,0,0)),True)@Vector((0,0,1))).z),'right':float((ns['ns']['sample'](ns['ns']['a'].bones['center_n'].rotation,634,Quaternion((1,0,0,0)),True)@Vector((0,0,1))).x)}
def motion(p,d,target):return {'fps':30,'duration':d,'actor':p[0],'victim':p[1],'targetAnimation':target,'victimFacing':facing}
action={'enabled':True,'weaponHeat':True,'weaponItems':['ProjectYakuza.BeerCrate'],'motionId':'dod_crate','useExtremeFuel':True,'heatStocks':1,'noCombo':True,'animation':'ProjectYakuza_DD_CrateHeat','targetAnimation':'ProjectYakuza_DD_CrateHeatVictim','nodeValue':'dd_crate_heat','requiresTarget':True,'duration':(len(mapping)-1)/30,'speed':1,'hitResponse':False,'noKnockback':True,'qteStages':True,'qteFailure':{'animation':'ProjectYakuza_DD_CrateHeatFail','targetAnimation':'ProjectYakuza_DD_CrateHeatFailVictim','nodeValue':'dd_crate_heat_fail','duration':180/30,'paired':True,'motionId':'dod_crate_ending','contactMs':101/30*1000},'qte':{'failureLimit':1,'failureMode':'consecutive','feedback':{'gain':.3},'prompts':[{'atMs':f/30*1000,'windowMs':76/30*1000,'binding':'heatAction','presses':10,'minPressIntervalMs':120,'damageMultiplier':2.25}for f in [183]]},'contacts':[{'atMs':f/30*1000,'damageMultiplier':0,'cue':'heavyImpact'if i==0 else'punchImpact','strong':i==0,'voice':'CombatHeavyAttack'if i==0 else'CombatLightAttack'}for i,f in enumerate([51,134,231,307,404])]+[{'atMs':555/30*1000,'sumQTE':True,'baseDamageMultiplier':1.5,'cue':'heavyImpact','strong':True,'charged':True,'voice':'CombatHeavyAttack'}]}
code='require "ProjectYakuza/Registry"\nProjectYakuza.PairedMotions=ProjectYakuza.PairedMotions or {}\nProjectYakuza.PairedMotions.dod_crate='+lua(motion(paths,(len(mapping)-1)/30,action['targetAnimation']))+'\nProjectYakuza.PairedMotions.dod_crate_ending='+lua(motion(endPaths,180/30,'ProjectYakuza_DD_CrateHeatFailVictim'))+'\nProjectYakuza.CrateHeatMove='+lua(action)+'\n'
(media/'lua/shared/ProjectYakuza/CrateHeatMove.lua').write_text(code)
style=media/'lua/shared/ProjectYakuza/Styles/DragonOfDojima.lua';s=style.read_text();s=s.replace('require "ProjectYakuza/RushMove"','require "ProjectYakuza/RushMove"\nrequire "ProjectYakuza/CrateHeatMove"');needle='            finisher={enabled=true,variants={default={animation="ProjectYakuza_DD_CrateHeavy"';s=s.replace(needle,'            heatAction=ProjectYakuza.CrateHeatMove,\n'+needle);style.write_text(s.replace('require "ProjectYakuza/CrateHeatMove"\nrequire "ProjectYakuza/CrateHeatMove"','require "ProjectYakuza/CrateHeatMove"').replace('            heatAction=ProjectYakuza.CrateHeatMove,\n            heatAction=ProjectYakuza.CrateHeatMove,','            heatAction=ProjectYakuza.CrateHeatMove,'))
report={'authorization':'User requested original Yakuza 5 h3000_beercase scene on 2026-11-15.','operation':'All 635 original body frames at 30 fps and the beercase-specific prop track. Original CMN mash window 107..183 requires ten fresh presses; failure uses the original branch target 454 and closing frames. Source camera-cut travel is bounded in combat space; body and finger poses are retained. The unchanged Y6 crate is fitted opening-down over the native victim head through the spin section. No invented body poses, artwork or audio.','archive':str(Path('F:/SteamLibrary/steamapps/common/Yakuza 5/main/data/hact/h3000_beercase.par')),'clips':records,'paths':paths,'endingPaths':endPaths,'rawPaths':rawPaths,'cuts':cuts,'objectSource':str(objSource),'objectSha256':sha(objSource),'objectAnchorOffset':[list(row)for row in offset],'pathScale':scale,'contactFrames':[51,134,231,307,404,555],'qteFrames':[183],'roles':'res.bin assigns h3000_000_1 to Kiryu, h3000_000_3 to the enemy and h3000_000_7 to the weapon object. Correct original c_cm_bone.gmd skeleton is used, retaining center_n root height.'}
report.update(sourcePaths=sourcePaths,modelScale=.5,modelSha256=model['sha256'],nativeBody=body['path'],nativeBodySha256=sha(body['path']),headSeat={'first':50,'last':454,'centre':list(centre),'roof':roof},objectCalibration=[list(r)for r in calibration])
report['archiveSha256']=sha(report['archive']);(mod/'docs/crate-heat-assets.json').write_text(json.dumps(report,indent=2)+'\n');print('PASS original crate Heat Action:',len(records),'clips, original beercase scene and authored mash window')
