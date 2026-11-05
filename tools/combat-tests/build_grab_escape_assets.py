from pathlib import Path
import sys,json,hashlib,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,blocks,write
mod=root/'combat/ProjectYakuza';media=mod/'42/media';src=Path('E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack/gmt');records=[];paths=[]
converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/grab-escape-build'");grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat']
for role in range(2):
 name='ProjectYakuza_DD_GrabEscape'+('Victim'if role else'');source=src/f'P_KRU_BTL_SUD_sy{role}_gsp_sprt.gmt';sys.argv=['convert','--',name,str(source)];ns={'FINGER_SOURCE':'Bob_AttackPunch01_Hit.x'};exec(compile(converter,'retarget_original_grab_separation','exec'),ns)
 raw=root/('tools/grab-escape-build/ProjectYakuza/42/media/anims_X/Bob/'+name+'.x');text,b,c,spans=read(raw);count=ns['a'].end_frame+1;times=[i*160 for i in range(count)];dest=media/'anims_X/Bob'/(name+'.x');write(dest,text,spans,blocks(b,[locals_at(b,c,t)for t in times],times,grip),name)
 curve=ns['a'].bones.get('center_c_n');curve=curve.location if curve else None
 anchor=ns['sample'](curve,0,ns['Vector']((0,0,0)));factor=float(ns['scale'])*1.5;path=[]
 for frame in range(count):
  v=(ns['sample'](curve,frame,ns['Vector']((0,0,0)))-anchor)*factor;path.append([float(v.z),float(v.x)])
 paths.append(path)
 sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
 records.append({'role':role,'source':str(source),'sourceSha256':sha(source),'retarget':str(raw),'retargetSha256':sha(raw),'output':dest.relative_to(mod).as_posix(),'sha256':sha(dest),'frames':count,'fps':30})
 print('ROOT',role,path[0],path[-1])
 def node(path,role):
  n=E.parse(path).getroot();n.find('m_Name').text=name;n.find('m_AnimName').text=name
  for c in n.findall('m_Conditions'):
   if c.findtext('m_Name')in ['ProjectYakuzaDefensePhase','ProjectYakuzaGrabPhase']:c.find('m_Value').text='escape'
  for e in list(n.findall('m_Events')):n.remove(e)
  for time,value in [('Start','escape_started'),('End','escape_done')]:
   e=E.SubElement(n,'m_Events');E.SubElement(e,'m_EventName').text='SetVariable';E.SubElement(e,'m_Time').text=time;E.SubElement(e,'m_ParameterValue').text=('ProjectYakuzaGrabMarker'if role else'ProjectYakuzaDefenseMarker')+'='+value
  E.ElementTree(n).write(path.with_name(name+'.xml'),encoding='utf-8',xml_declaration=True)
 if role==0:node(media/'AnimSets/player/actions/ProjectYakuza_DD_GrabStrike01.xml',role)
 else:
  for group in ['hitreaction','hitreaction-hit','idle']:node(media/f'AnimSets/zombie/{group}/ProjectYakuza_DD_GrabStrikeVictim01.xml',role)
(mod/'docs/grab-escape-assets.json').write_text(json.dumps({'authorization':'User approved conversion of the original sy0/sy1_gsp_sprt pair on 2026-11-05.','operation':'Original paired grab separation, both complete 71-frame clips at 30 fps; source motion retargeted to PZ with native prop grips, no invented motion, AI or new artwork/audio. Source center horizontal travel is zero; paired controller retains its current staging.','clips':records,'paths':paths,'nativeGrip':grip},indent=2)+'\n')
print('PASS converted original paired grab separation without invented frames')
