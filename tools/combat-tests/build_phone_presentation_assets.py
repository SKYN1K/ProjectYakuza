from pathlib import Path
import hashlib,io,json,subprocess,sys,tempfile,wave
from PIL import Image
from y5_source_assets import entry
from cri_cue_table import cue_names

ROOT=Path(__file__).resolve().parents[2];MOD=ROOT/'phone-dev/ProjectYakuzaPhoneDev';validate='--validate'in sys.argv
sha=lambda b:hashlib.sha256(b).hexdigest()
source=Path('E:/Blender/Images/Kiryu_Zomboid.jpg');raw=source.read_bytes();image=Image.open(io.BytesIO(raw));assert image.size==(1280,720)
preview=image.convert('RGB').resize((512,288),Image.Resampling.LANCZOS).quantize(colors=128,method=Image.Quantize.MEDIANCUT)
buffer=io.BytesIO();preview.save(buffer,format='PNG',optimize=True);pixels=buffer.getvalue();assert len(pixels)<len(raw)
target=MOD/'42/media/textures/ProjectYakuzaPhoneDev/DragonOfDojima.png'
if validate:assert target.read_bytes()==pixels
else:target.write_bytes(pixels)
records={'preview':{'source':source.name,'sourceSha256':sha(raw),'sourceBytes':len(raw),'sourceSize':list(image.size),'output':target.relative_to(MOD).as_posix(),'sha256':sha(pixels),'bytes':len(pixels),'size':[512,288],'operation':'User-authorized resize of supplied image, full composition retained, Lanczos downsampling and 128-colour PNG compression; no generated artwork or upscaling.'},'sounds':[]}
archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/sound.par');bank,metadata=entry(archive,'console.acb');metadata['archive']=archive.name
folder=ROOT/'extracted/phone-presentation';folder.mkdir(parents=True,exist_ok=True);bankPath=folder/'console.acb';bankPath.write_bytes(bank)
vgm=str(ROOT/'tools/vgmstream/vgmstream-cli.exe');names=cue_names(bank);scripts=[]
for key,cue,index in [('PhoneOpen','phone_open',23),('PhoneClose','phone_cancel01',20)]:
 info=json.loads(subprocess.check_output([vgm,'-I','-m','-s',str(index),str(bankPath)],text=True));assert cue in info['streamInfo']['name'].split('; ')
 with tempfile.TemporaryDirectory(prefix='project-yakuza-phone-')as tmp:
  decoded=Path(tmp)/'source.wav';subprocess.run([vgm,'-s',str(index),'-i','-o',str(decoded),str(bankPath)],capture_output=True,check=True);pcm=decoded.read_bytes()
 output=MOD/('42/media/sound/ProjectYakuzaPhoneDev/'+key+'.wav');output.parent.mkdir(parents=True,exist_ok=True)
 if validate:assert output.read_bytes()==pcm
 else:output.write_bytes(pcm)
 with wave.open(io.BytesIO(pcm))as audio:assert(audio.getframerate(),audio.getnchannels(),audio.getsampwidth(),audio.getnframes())==(info['sampleRate'],info['channels'],2,info['numberOfSamples'])
 records['sounds'].append({'bank':metadata,'cue':cue,'cueId':next(i for i,n in names.items()if n==cue),'streamIndex':index,'output':output.relative_to(MOD).as_posix(),'sha256':sha(pcm),'sampleRate':info['sampleRate'],'channels':info['channels'],'samples':info['numberOfSamples'],'operation':'Untrimmed original HCA waveform decoded to PCM without mixing, pitch changes, synthesis or resampling. Native non-positional UI playback.'})
 scripts.append('    sound ProjectYakuzaPhoneDev_'+key+'\n    {\n        category = ProjectYakuza_Interface,\n        is3D = false,\n        loop = false,\n        clip\n        {\n            file = media/sound/ProjectYakuzaPhoneDev/'+key+'.wav,\n            distanceMin = 0,\n            distanceMax = 0,\n            volume = 0.55,\n        }\n    }')
code='module ProjectYakuzaPhoneDev\n{\n'+'\n'.join(scripts)+'\n}\n';output=MOD/'42/media/scripts/ProjectYakuzaPhoneDev_Audio.txt'
if validate:assert output.read_text()==code
else:output.write_text(code,newline='\n')
record=MOD/'docs/presentation-assets.json'
if validate:assert json.loads(record.read_text())==records
else:record.write_text(json.dumps(records,indent=2)+'\n',newline='\n')
print('PASS supplied Dragon preview 1280x720 -> 512x288,',len(raw),'->',len(pixels),'bytes; exact original Y6 phone_open and phone_cancel01 PCM, native rates/channels/durations')
