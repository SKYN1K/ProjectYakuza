from pathlib import Path
import sys,json,hashlib,struct,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,blocks,write
mod=root/'combat/ProjectYakuza';source=Path('E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack/gmt/P_KRU_BTL_SUD_atm_sze_l_md.gmt');bep=source.parent.parent/'bep'/source.with_suffix('.bep').name
name='ProjectYakuza_DD_GrabAttempt';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text(encoding='utf-8').replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/grab-attempt-build'")
sys.argv=['convert','--',name,str(source)];ns={'FINGER_SOURCE':str(mod/'42/media/anims_X/Bob/ProjectYakuza_DD_GrabEnter.x')};exec(compile(converter,'retarget_original_grab_attempt','exec'),ns)
raw=root/'tools/grab-attempt-build/ProjectYakuza/42/media/anims_X/Bob'/ (name+'.x')
text,bones,curves,spans=read(raw);count=ns['a'].end_frame+1;times=[i*160 for i in range(count)];grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text(encoding='utf-8'))['nativeGrips']['bat']
output=mod/'42/media/anims_X/Bob'/(name+'.x');write(output,text,spans,blocks(bones,[locals_at(bones,curves,t)for t in times],times,grip),name)
node=E.parse(mod/'42/media/AnimSets/player/actions/ProjectYakuza_DD_GrabEnter.xml').getroot();node.find('m_Name').text=name;node.find('m_AnimName').text=name
for condition in node.findall('m_Conditions'):
 if condition.findtext('m_Name')=='ProjectYakuzaDefensePhase':condition.find('m_Value').text='attempt'
for event in list(node.findall('m_Events')):node.remove(event)
for time,value in [('Start','attempt_started'),('End','attempt_done')]:
 event=E.SubElement(node,'m_Events');E.SubElement(event,'m_EventName').text='SetVariable';E.SubElement(event,'m_Time').text=time;E.SubElement(event,'m_ParameterValue').text='ProjectYakuzaDefenseMarker='+value
E.ElementTree(node).write(mod/'42/media/AnimSets/player/actions'/(name+'.xml'),encoding='utf-8',xml_declaration=True)
b=bep.read_bytes();pos=16;windows=[]
while pos+80<=len(b):
 section,kind,size=struct.unpack_from('<HHI',b,pos+64);data=b[pos+80:pos+80+size]
 if section==12 and kind in [75,77]:windows.append({'kind':kind,'fromFrame':struct.unpack_from('<f',data,4)[0],'toFrame':struct.unpack_from('<f',data,8)[0]})
 pos+=80+size
assert count==49 and windows==[{'kind':77,'fromFrame':10.0,'toFrame':12.0},{'kind':75,'fromFrame':25.0,'toFrame':48.0}]
report={'authorization':'User approved conversion of the supplied original Yakuza 6 grab-attempt motion for missed grabs.','source':str(source),'sourceSha256':sha(source),'bep':str(bep),'bepSha256':sha(bep),'windows':windows,'retarget':str(raw),'retargetSha256':sha(raw),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'frames':count,'fps':30,'duration':1.6,'operation':'Complete original attack-attempt and failed-reach recovery, original frame order and timing. Existing PZ skeleton retargeting and native prop offsets; existing grab finger pose. No invented body motion, artwork or audio.'}
(mod/'docs/grab-attempt-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('PASS original 49-frame grab attempt and recovery, BEP interaction window frames 10..12; no invented frames')
