from pathlib import Path
import sys,json,subprocess,hashlib,wave,tempfile
from y5_source_assets import entry
from cri_cue_table import cue_names

root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';write='--write'in sys.argv;vgm=str(root/'tools/vgmstream/vgmstream-cli.exe');sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();records=[];scripts=[]
selections=[('StyleSwitch','kiwami','466d.acb','dragon_change',.65),('MenuOpen','y6','menu_default.acb','dec02',.45),('MenuCursor','y6','menu_default.acb','cursor01',.5),('MenuConfirm','y6','menu_default.acb','dec01',.6),('MenuCancel','y6','menu_default.acb','cancel01',.6),('MenuToggle','y6','menu_default.acb','tgl_dec',.5)]
banks={}
for key,game,bankName,cue,volume in selections:
    if game not in banks:
        archive=Path('F:/SteamLibrary/steamapps/common/Yakuza Kiwami/media/data/soundpar/sound.par')if game=='kiwami'else Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/sound.par');data,metadata=entry(archive,bankName);folder=root/'extracted/interface-audio-098'/game;folder.mkdir(parents=True,exist_ok=True);path=folder/bankName;path.write_bytes(data);names=cue_names(data);info=json.loads(subprocess.check_output([vgm,'-I','-m',str(path)],text=True));streams=[]
        for index in range(1,info['streamInfo']['total']+1):streams.append((index,json.loads(subprocess.check_output([vgm,'-I','-m','-s',str(index),str(path)],text=True))))
        banks[game]=(path,metadata,names,streams)
    path,metadata,names,streams=banks[game];cueId=next(i for i,n in names.items()if n==cue);matches=[(i,info)for i,info in streams if cue in info['streamInfo']['name'].split('; ')];assert len(matches)==1,(cue,matches);index,info=matches[0];out=mod/('42/media/sound/ProjectYakuza/'+key+'.wav')
    with tempfile.TemporaryDirectory(prefix='project-yakuza-ui-audio-')as tmp:
        decoded=Path(tmp)/'source.wav';subprocess.run([vgm,'-s',str(index),'-i','-o',str(decoded),str(path)],capture_output=True,check=True)
        if write:out.write_bytes(decoded.read_bytes())
        else:assert out.read_bytes()==decoded.read_bytes(),key
    with wave.open(str(out))as audio:assert(audio.getframerate(),audio.getnchannels(),audio.getsampwidth(),audio.getnframes())==(info['sampleRate'],info['channels'],2,info['numberOfSamples'])
    records.append({'key':key,'sound':'ProjectYakuza_'+key,'bank':metadata,'cueId':cueId,'cue':cue,'streamIndex':index,'sourceAliases':info['streamInfo']['name'].split('; '),'sampleRate':info['sampleRate'],'channels':info['channels'],'samples':info['numberOfSamples'],'output':out.relative_to(mod).as_posix(),'sha256':sha(out),'volume':volume})
    scripts.append('    sound ProjectYakuza_'+key+'\n    {\n        category = ProjectYakuza_Interface,\n        is3D = false,\n        loop = false,\n        clip\n        {\n            file = media/sound/ProjectYakuza/'+out.name+',\n            volume = '+str(volume)+',\n        }\n    }')
code='module ProjectYakuza\n{\n'+'\n'.join(scripts)+'\n}\n';script=mod/'42/media/scripts/ProjectYakuza_Interface.txt';report={'operation':'Direct original bank PCM decoding, no trimming, mixing, resampling, synthesis or new voice content. The Kiwami dragon_change cue shares its waveform with the other three original style-change cue aliases. Native 2D UI playback uses the supplied waveform; source engine DSP, pitch/control graphs are not recreated. Y6 menu_default supplies mod-only menu navigation/confirmation/cancel/toggle. No global PZ menu sounds are replaced.','sounds':records,'script':script.relative_to(mod).as_posix(),'scriptSha256':hashlib.sha256(code.encode()).hexdigest()};manifest=mod/'docs/interface-audio.json'
if write:script.write_bytes(code.encode());manifest.write_text(json.dumps(report,indent=2)+'\n')
else:assert script.read_bytes()==code.encode()and json.loads(manifest.read_text())==report
print('PASS 6 direct source PCM decodes, original rates/channels/samples, Kiwami style cue and Y6 mod-menu cues; no generated audio')
