from pathlib import Path
import json,struct,subprocess,hashlib,wave
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/sound.par');work=root/'extracted/katana-scene-093';work.mkdir(exist_ok=True)
with archive.open('rb')as f:
 header=f.read(32);dirs,_,count,entries=struct.unpack_from('>4I',header,16);f.seek(32+dirs*64);names=[f.read(64).split(b'\0')[0].decode('cp932','replace')for _ in range(count)];index=names.index('hact_h23720_buki_e.acb');f.seek(entries+index*32);flags,plain,size,offset=struct.unpack('>4I',f.read(16));assert not flags;f.seek(offset);bank=work/names[index];bank.write_bytes(f.read(size));assert bank.stat().st_size==plain
jobs=[(1,'bodyfall','BodyFall',97,'victim'),(2,'katana_swing','Swing',8,'actor'),(3,'punch','Punch',28,'actor'),(4,'slash','Slash',20,'victim'),(5,'tuki','Thrust',54,'victim')];records=[];blocks=[]
for index,original,name,frame,target in jobs:
 meta=subprocess.check_output([str(root/'tools/vgmstream/vgmstream-cli.exe'),'-m','-s',str(index),str(bank)],text=True);assert 'stream name: '+original in meta
 output=mod/f'42/media/sound/ProjectYakuza/KatanaScene{name}.wav';output.parent.mkdir(parents=True,exist_ok=True)
 subprocess.run([str(root/'tools/vgmstream/vgmstream-cli.exe'),'-s',str(index),'-o',str(output),str(bank)],check=True,capture_output=True)
 with wave.open(str(output))as audio:rate,channels,samples,width=audio.getframerate(),audio.getnchannels(),audio.getnframes(),audio.getsampwidth()
 assert rate==44100 and channels==2 and width==2
 sound='ProjectYakuza_KatanaScene'+name
 blocks.append('    sound '+sound+'\n    {\n        category = ProjectYakuza_Effects,\n        is3D = true,\n        loop = false,\n        clip\n        {\n            file = media/sound/ProjectYakuza/KatanaScene'+name+'.wav,\n            distanceMin = 1,\n            distanceMax = 16,\n            volume = 0.65,\n        }\n    }')
 records.append({'cueSheet':3790,'cueId':index,'stream':original,'sound':sound,'sourceFrame':frame,'target':target,'output':output.relative_to(mod).as_posix(),'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'sampleRate':rate,'channels':channels,'samples':samples,'sampleWidth':width})
(mod/'42/media/scripts/ProjectYakuza_KatanaScene.txt').write_text('module Base\n{\n'+'\n'.join(blocks)+'\n}\n')
(mod/'docs/katana-scene-audio.json').write_text(json.dumps({'authorization':'User approved original katana sound extraction and paired motion repair on 2026-11-07.','operation':'Original embedded CRI HCA streams decoded to PCM16 WAV at their native 44100 Hz stereo format; no synthesis, filtering, mixing, upscaling or invented audio. Playback starts follow original CMN SE nodes rather than damage markers.','archive':str(archive),'entry':bank.name,'entryOffset':offset,'entrySha256':hashlib.sha256(bank.read_bytes()).hexdigest(),'sounds':records},indent=2)+'\n')
print('PASS five original katana scene cues decoded at native 44100 Hz stereo; no synthesized audio')
