from pathlib import Path
import sys,json,hashlib,subprocess,wave,re
from y5_source_assets import entry
from cri_cue_table import cue_names
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';work=root/'extracted/object-sounds-0114';work.mkdir(exist_ok=True);archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/sound.par');vgm=root/'tools/vgmstream/vgmstream-cli.exe';records=[];scripts=[];labels={};banks={};validate='--validate'in sys.argv
def bank(name):
 if name not in banks:
  data,record=entry(archive,name+'.acb');path=work/(name+'.acb');path.write_bytes(data);info=json.loads(subprocess.check_output([str(vgm),'-I','-m',str(path)],text=True));streams=[]
  for index in range(1,info['streamInfo']['total']+1):
   row=json.loads(subprocess.check_output([str(vgm),'-I','-m','-s',str(index),str(path)],text=True));streams.append((index,row))
  banks[name]=(path,record,streams)
 return banks[name]
for family,physical in [('Bicycle','bicycle'),('Bottle','breakbin'),('Crate','pylon')]:
 for kind,cue in [('Hit','hit'),('Floor','objhit_l'),('Break','break'),('Swing','donki_swing_s'if family=='Bottle'else'donki_swing_l')]:
  name='ProjectYakuza_'+family+kind;path,provenance,streams=bank('act_common'if kind=='Swing'else'arm_glass'if family=='Bottle'and kind=='Break'else'arm_'+physical);matches=[(index,info)for index,info in streams if info['streamInfo'].get('name')==cue];assert matches,(family,kind,cue);clips=[]
  for number,(index,info)in enumerate(matches,1):
   output=mod/'42/media/sound/ProjectYakuza'/(family+kind+str(number)+'.wav');dest=work/(output.name if validate else'check-'+output.name);subprocess.run([str(vgm),'-s',str(index),'-i','-o',str(dest if validate else output),str(path)],check=True,capture_output=True)
   if validate:assert output.read_bytes()==dest.read_bytes()
   with wave.open(str(output))as audio:assert(audio.getframerate(),audio.getnchannels(),audio.getsampwidth(),audio.getnframes())==(info['sampleRate'],info['channels'],2,info['numberOfSamples'])
   record={**provenance,'family':family,'kind':kind,'cue':cue,'streamIndex':index,'output':output.relative_to(mod).as_posix(),'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'samples':info['numberOfSamples'],'sampleRate':info['sampleRate'],'channels':info['channels']};records.append(record);clips.append('        clip\n        {\n            file = media/sound/ProjectYakuza/'+output.name+',\n            volume = 0.7,\n            distanceMin = 1,\n            distanceMax = 16,\n        }')
  scripts.append('    sound '+name+'\n    {\n        category = ProjectYakuza_Effects,\n        is3D = true,\n        loop = false,\n'+'\n'.join(clips)+'\n    }');labels[name]=family+' '+{'Hit':'impact','Floor':'ground impact','Break':'breaking','Swing':'swing'}[kind]
text='module Base\n{\n'+'\n'.join(scripts)+'\n}\n';out=mod/'42/media/scripts/ProjectYakuza_ObjectSounds.txt';report={'operation':'Unmixed original Yakuza 6 arm_bicycle, arm_breakbin glass-bottle hits/floor impacts and arm_glass break streams; plastic-object arm_pylon streams for the plastic crate; original act_common blunt swings. No synthesized sounds or voice-pack changes.','sounds':records}
if validate:assert out.read_text()==text and json.loads((mod/'docs/object-weapon-sounds.json').read_text())==report
else:
 out.write_text(text);(mod/'docs/object-weapon-sounds.json').write_text(json.dumps(report,indent=2)+'\n');p=mod/'42/media/lua/shared/Translate/EN/GameSound.json';values=json.loads(p.read_text(encoding='utf-8'));values.update({'GameSound_'+k:v for k,v in labels.items()});p.write_text(json.dumps(values,indent=4)+'\n',encoding='utf-8')
print('PASS',len(records),'original object sound streams; twelve readable native sound events')
