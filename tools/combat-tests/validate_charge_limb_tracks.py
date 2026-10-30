
from pathlib import Path
import json,re,subprocess,hashlib,xml.etree.ElementTree as E
w=Path(__file__).resolve().parent;root=w.parents[1];mod=root/'combat/ProjectYakuza';game=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid')
report=json.loads((mod/'docs/charge-limb-tracks.json').read_text(encoding='utf-8'))
code=(mod/report['output']).read_text(encoding='utf-8');assert hashlib.sha256((mod/report['output']).read_bytes()).hexdigest()==report['sha256']
parts=re.split(r'    \["([^"]+)"\]=',code);blocks={parts[i]:parts[i+1] for i in range(1,len(parts),2)}
out=w/'charge-track-native';out.mkdir(exist_ok=True);samples=0
for record in report['clips']:
 clip=mod/record['clip'];assert hashlib.sha256(clip.read_bytes()).hexdigest()==record['clip_sha256']
 target=out/(record['animation']+'.json')
 result=subprocess.run([str(game/'jre64/bin/java.exe'),'-cp',str(w)+';'+str(game/'*'),'ChargeTrackProbe',str(clip),str(target)],capture_output=True,text=True)
 assert result.returncode==0,result.stderr
 native=json.loads(target.read_text());rows=[[float(x) for x in row.split(',')] for row in re.findall(r'^        \{([^{}]+)\},',blocks[record['animation']],re.M)]
 assert len(rows)==len(native['frames'])==record['sample_count']
 for actual,frame in zip(rows,native['frames']):
  expected=sum([frame[i] for i in record['source_bone_indices']],[])
  assert len(expected)==len(actual) and all(abs(a-b)<1e-8 for a,b in zip(actual,expected));samples+=1
for i,frames in enumerate([6,7,6,5],1):
 n=E.parse(mod/f'42/media/AnimSets/player/actions/ProjectYakuza_DD_ChargeWindup0{i}.xml').getroot()
 handoff=[e for e in n.findall('m_Events') if e.findtext('m_ParameterValue')=='ProjectYakuzaChargeClip=handoff']
 assert len(handoff)==1 and abs(float(handoff[0].findtext('m_TimePc'))-(frames-1)/frames)<1e-8
 assert float(n.findtext('m_BlendTime'))==.14
print(f'PASS {len(report["clips"])} original B42 charge limb paths, {samples} source samples, four native last-frame handoff markers; no motion/texture/audio changed')
