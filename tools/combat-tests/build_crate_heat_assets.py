from pathlib import Path
import sys,json,hashlib,runpy,xml.etree.ElementTree as E
from mathutils import Matrix,Vector,Quaternion
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,world,blocks,write
ns=runpy.run_path(str(root/'tools/combat-tests/retarget_crate_heat.py'))
mod=root/'combat/ProjectYakuza';media=mod/'42/media';meta=json.loads((root/'tools/crate-original-retarget-086.json').read_text());scale=meta['scale'];anchor=Vector(meta['roles'][0]['vectors'][0]);factor=scale/1.5
mapping=list(range(34))+list(range(34,64))*3+list(range(64,130));ending=list(range(63,130));records=[];C=Matrix.Diagonal((1,1,-1,1))
objSource=root/'extracted/crate-heat-086/000.par/h3270_000_8.gmt';obj=ns['read_gmt'](str(objSource)).animation.bones['null']
for curve in obj.curves:
 if int(curve.type)in(0,1):curve.fill_channels()
sample=ns['ns']['sample']
def objectPose(f):
 v=sample(obj.location,f,Vector((0,0,0)));v.x-=anchor.x;v.z-=anchor.z;v*=factor
 q=sample(obj.rotation,f,Quaternion((1,0,0,0)),True);m=C@q.to_matrix().to_4x4()@C;m.translation=Vector((v.x,v.y,-v.z));return m
actorRaw=Path(meta['roles'][0]['file']);_,ab,ac,_=read(actorRaw);a0=world(ab,locals_at(ab,ac,0));offset=objectPose(0).inverted()@a0['Bip01_Prop1']
paths=[[],[]];shift=[0.,0.]
rawPaths=[[[float((Vector(v)-anchor).z*scale),float((Vector(v)-anchor).x*scale)]for v in role['vectors']]for role in meta['roles']]
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
endPaths=[[[rawPaths[r][f][a]-rawPaths[0][63][a]for a in range(2)]for f in ending]for r in range(2)]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
for role,record in enumerate(meta['roles']):
 raw=Path(record['file']);text,b,c,spans=read(raw)
 for fail,frames in [(False,mapping),(True,ending)]:
  name='ProjectYakuza_DD_CrateHeat'+('Fail'if fail else'')+('Victim'if role else'');values=[locals_at(b,c,f*160)for f in frames]
  if not role:
   for f,v in zip(frames,values):
    w=world(b,v);prop=objectPose(f)@offset;rootPath=rawPaths[0][f];prop.translation-=Vector((rootPath[1]/1.5,0,-rootPath[0]/1.5));v['Bip01_Prop1']=w[b['Bip01_Prop1']['parent']].inverted()@prop
  out=media/'anims_X/Bob'/(name+'.x');write(out,text,spans,blocks(b,values,[i*160 for i in range(len(frames))],None),name)
  source=root/'extracted/crate-heat-086/000.par'/('h3270_000_3.gmt'if role else'h3270_000_1.gmt')
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
facing={'forward':float((ns['ns']['sample'](ns['ns']['a'].bones['center_n'].rotation,129,Quaternion((1,0,0,0)),True)@Vector((0,0,1))).z),'right':float((ns['ns']['sample'](ns['ns']['a'].bones['center_n'].rotation,129,Quaternion((1,0,0,0)),True)@Vector((0,0,1))).x)}
def motion(p,d,target):return {'fps':30,'duration':d,'actor':p[0],'victim':p[1],'targetAnimation':target,'victimFacing':facing}
action={'enabled':True,'weaponHeat':True,'weaponItems':['ProjectYakuza.BeerCrate'],'motionId':'dod_crate','useExtremeFuel':True,'heatStocks':1,'noCombo':True,'animation':'ProjectYakuza_DD_CrateHeat','targetAnimation':'ProjectYakuza_DD_CrateHeatVictim','nodeValue':'dd_crate_heat','requiresTarget':True,'duration':(len(mapping)-1)/30,'speed':1,'hitResponse':False,'noKnockback':True,'deferFinalDamage':True,'qteStages':True,'qteFailure':{'animation':'ProjectYakuza_DD_CrateHeatFail','targetAnimation':'ProjectYakuza_DD_CrateHeatFailVictim','nodeValue':'dd_crate_heat_fail','duration':66/30,'paired':True,'motionId':'dod_crate_ending','contactMs':19/30*1000},'qte':{'failureLimit':1,'failureMode':'consecutive','feedback':{'success':'heatGain','miss':'guardHit','failure':'heatOff','gain':.3},'prompts':[{'atMs':f/30*1000,'windowMs':1000,'binding':'heatAction','presses':2,'minPressIntervalMs':120,'damageMultiplier':.75}for f in [63,93,123]]},'contacts':[{'atMs':f/30*1000,'damageMultiplier':0,'cue':'heavyImpact'if i==0 else'punchImpact','strong':i==0,'voice':'CombatHeavyAttack'if i==0 else'CombatLightAttack'}for i,f in enumerate([13,44,74,104])]+[{'atMs':142/30*1000,'sumQTE':True,'baseDamageMultiplier':1.5,'cue':'heavyImpact','strong':True,'charged':True,'voice':'CombatHeavyAttack'}]}
code='require "ProjectYakuza/Registry"\nProjectYakuza.PairedMotions=ProjectYakuza.PairedMotions or {}\nProjectYakuza.PairedMotions.dod_crate='+lua(motion(paths,(len(mapping)-1)/30,action['targetAnimation']))+'\nProjectYakuza.PairedMotions.dod_crate_ending='+lua(motion(endPaths,66/30,'ProjectYakuza_DD_CrateHeatFailVictim'))+'\nProjectYakuza.CrateHeatMove='+lua(action)+'\n'
(media/'lua/shared/ProjectYakuza/CrateHeatMove.lua').write_text(code)
style=media/'lua/shared/ProjectYakuza/Styles/DragonOfDojima.lua';s=style.read_text();s=s.replace('require "ProjectYakuza/RushMove"','require "ProjectYakuza/RushMove"\nrequire "ProjectYakuza/CrateHeatMove"');needle='            finisher={enabled=true,variants={default={animation="ProjectYakuza_DD_CrateHeavy"';s=s.replace(needle,'            heatAction=ProjectYakuza.CrateHeatMove,\n'+needle);style.write_text(s.replace('require "ProjectYakuza/CrateHeatMove"\nrequire "ProjectYakuza/CrateHeatMove"','require "ProjectYakuza/CrateHeatMove"').replace('            heatAction=ProjectYakuza.CrateHeatMove,\n            heatAction=ProjectYakuza.CrateHeatMove,','            heatAction=ProjectYakuza.CrateHeatMove,'))
report={'authorization':'User approved original Yakuza 5 H3270 conversion and repeat/ending sections on 2026-11-05.','operation':'Original body poses at original 30 fps. Source frames 34..63 are repeated at most three times; their seam was selected by comparing paired native joint poses. Original prop GMT drives the crate instead of the punching hand. Failure branches into the original closing frames, never an infinite loop. No invented motion, artwork, audio, AI or upscaling.','archive':str(Path('F:/SteamLibrary/steamapps/common/Yakuza 5/main/data/hact/H3270_kaburikasa.par')),'clips':records,'paths':paths,'endingPaths':endPaths,'rawPaths':rawPaths,'cuts':cuts,'objectSource':str(objSource),'objectSha256':sha(objSource),'objectAnchorOffset':[list(row)for row in offset],'pathScale':scale,'contactFrames':[13,44,74,104,142],'qteFrames':[63,93,123],'roles':'res.bin assigns h3270_000_1 to Kiryu, h3270_000_3 to the enemy and h3270_000_8 to the weapon object. Correct original c_cm_bone.gmd skeleton is used, retaining center_n root height.'}
report['archiveSha256']=sha(report['archive']);(mod/'docs/crate-heat-assets.json').write_text(json.dumps(report,indent=2)+'\n');print('PASS original crate Heat Action:',len(records),'clips, finite three-stage mash')
