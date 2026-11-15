from pathlib import Path
import hashlib,json,subprocess,sys,tempfile,wave
from y5_source_assets import entry
from cri_cue_table import cue_names

root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';write='--write'in sys.argv
archive=Path('F:/SteamLibrary/steamapps/common/Yakuza Kiwami 2/data/sound.par')
raw,metadata=entry(archive,'act_kiryu.acb');names=cue_names(raw);vgm=str(root/'tools/vgmstream/vgmstream-cli.exe')
selections=[('Windup','charge_st_lexus2',7,'Extreme Heat: charge layer'),('Ignition','charge_en_lexus2_v2',9,'Extreme Heat: ignition'),('Surge','charge_en_lexus2_v3',10,'Extreme Heat: power surge')]
records=[];blocks=[]
with tempfile.TemporaryDirectory(prefix='project-yakuza-activation-')as tmp:
    bank=Path(tmp)/'act_kiryu.acb';bank.write_bytes(raw)
    for key,cue,index,label in selections:
        info=json.loads(subprocess.check_output([vgm,'-I','-m','-s',str(index),str(bank)],text=True));assert cue in info['streamInfo']['name'].split('; ')
        cueId=next(i for i,name in names.items()if name==cue);decoded=Path(tmp)/(key+'.wav')
        subprocess.run([vgm,'-s',str(index),'-i','-o',str(decoded),str(bank)],check=True,capture_output=True)
        sound='ProjectYakuza_ExtremeHeat'+key;out=mod/('42/media/sound/ProjectYakuza/ExtremeHeat'+key+'.wav')
        if write:out.write_bytes(decoded.read_bytes())
        else:assert out.read_bytes()==decoded.read_bytes(),key
        with wave.open(str(out))as audio:assert(audio.getframerate(),audio.getnchannels(),audio.getsampwidth(),audio.getnframes())==(info['sampleRate'],info['channels'],2,info['numberOfSamples'])
        records.append({'sound':sound,'label':label,'bank':metadata,'cue':cue,'cueId':cueId,'streamIndex':index,'samples':info['numberOfSamples'],'sampleRate':info['sampleRate'],'channels':info['channels'],'output':out.relative_to(mod).as_posix(),'sha256':hashlib.sha256(out.read_bytes()).hexdigest()})
        blocks.append('    sound '+sound+'\n    {\n        category = ProjectYakuza_Effects,\n        is3D = true,\n        loop = false,\n        clip\n        {\n            file = media/sound/ProjectYakuza/'+out.name+',\n            distanceMin = 1,\n            distanceMax = 16,\n            volume = 0.70,\n        }\n    }')
script='module ProjectYakuza\n{\n'+'\n'.join(blocks)+'\n}\n';target=mod/'42/media/scripts/ProjectYakuza_ExtremeHeat.txt'
report={'operation':'Three complete original Kiwami 2 act_kiryu non-voice streams decoded directly to PCM without trimming, mixing, resampling or synthesis. Existing Yakuza 6 activation layers remain. Runtime gains and fades are applied by the native emitter.','sounds':records,'script':target.relative_to(mod).as_posix(),'scriptSha256':hashlib.sha256(script.encode()).hexdigest()}
manifest=mod/'docs/extreme-activation-audio.json';labels=mod/'42/media/lua/shared/Translate/EN/GameSound_EN.txt'
if write:
    target.write_bytes(script.encode());manifest.write_text(json.dumps(report,indent=2)+'\n')
    text=labels.read_text();lines=['    GameSound_'+r['sound']+' = '+json.dumps(r['label'])+','for r in records if 'GameSound_'+r['sound']+' ='not in text]
    if lines:labels.write_text(text.rstrip().removesuffix('}')+'\n'.join(lines)+'\n}\n')
else:
    assert target.read_bytes()==script.encode()and json.loads(manifest.read_text())==report
    assert all('GameSound_'+r['sound']+' = '+json.dumps(r['label'])+','in labels.read_text()for r in records)
assert len({r['sha256']for r in records})==3
print('PASS three distinct complete original Kiwami 2 PCM decodes, cue IDs, sample counts, readable labels and provenance')
