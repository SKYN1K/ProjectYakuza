from pathlib import Path
import sys,json,hashlib,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,locals_at,blocks,write
mod=root/'combat/ProjectYakuza';path=mod/'docs/locomotion-assets.json';d=json.loads(path.read_text());sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for r in d['clips']:
 if r['kind']!='sourceRunNativeTravel':continue
 p=mod/r['output'];text,frames,anim,spans=read(p);old=r.get('nativeTravelScale',1);times=[i*160 for i in range(r['frames'])];values=[locals_at(frames,anim,t)for t in times]
 for v in values:v['Translation_Data'].translation*=1.28/old
 changes=blocks(frames,values,times,None);write(p,text,{'Translation_Data':spans['Translation_Data']},{'Translation_Data':changes['Translation_Data']},r['name'])
 r['nativeTravelScale']=1.28;r['runSpeedScale']=1;r['sha256']=sha(p)
d['operation']='Supplied Kiryu run motion with native travel. Healthy cadence is 1.0, reduced from 1.28; native Translation_Data distance is multiplied by 1.28 to preserve travel per second. Body poses and timings are unchanged. Carry composites retain native legs and torso. No AI or invented motion.'
path.write_text(json.dumps(d,indent=2)+'\n',encoding='utf-8')
for p in (mod/'42/media/AnimSets/player/run').glob('ProjectYakuza_DD_Locomotion*Run.xml'):
 text=p.read_text();assert '<m_SpeedScale>1.28</m_SpeedScale>'in text or '<m_SpeedScale>1.0</m_SpeedScale>'in text
 p.write_text(text.replace('<m_SpeedScale>1.28</m_SpeedScale>','<m_SpeedScale>1.0</m_SpeedScale>'),encoding='utf-8')
p=mod/'docs/locomotion-nodes.json';d=json.loads(p.read_text());d.update(runHealthySpeedScale=1,nativeTravelScale=1.28,operation='DoD-only non-aimed running uses 21.875% slower stride cadence with compensated native travel. Actual running speed is unchanged. Existing injury/tree/turn fallbacks and native walking legs are retained.');p.write_text(json.dumps(d,indent=2)+'\n',encoding='utf-8')
print('Adjusted four run cadences without changing body poses or travel per second')
