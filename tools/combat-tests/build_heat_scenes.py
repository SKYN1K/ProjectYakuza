from pathlib import Path
import sys,json,struct,hashlib,subprocess,wave,copy
from read_heat_scene import read_scene
from cri_cue_table import cue_names

root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';work=root/'extracted/all-heat-scene-095';work.mkdir(exist_ok=True);write='--write'in sys.argv
scenes={'knife':('knife-heat-098/h23680_buki_b','hact_h23680_buki_b.acb','ProjectYakuza_DD_KnifeHeat'),'rush':('rush-reference-072','hact_h24010_100punchi.acb','ProjectYakuza_DD_HeatRush'),'bottle':('bottle-heat-071','hact_h23760_buki_n.acb','ProjectYakuza_DD_BottleHeat'),'wall':('grab-wall-080/wall-knock','hact_h2000_knock_wall_l.acb','ProjectYakuza_DD_WallHeat'),'ground':('ground-heat-081','hact_h1500.acb','ProjectYakuza_DD_GroundHeat'),'crate':('crate-heat-086','27d7.acb','ProjectYakuza_DD_CrateHeat'),'katana':('katana-heat-070','hact_h23720_buki_e.acb','ProjectYakuza_DD_KatanaHeat'),'bat':('bat-heat-096/h23710_buki_d','hact_h23710_buki_d.acb','ProjectYakuza_DD_BatHeat'),'bicycle':('bicycle-heat-097/h11010_jitensha','28af.acb','ProjectYakuza_DD_BicycleHeat')}
sha=lambda b:hashlib.sha256(b).hexdigest()
vgm=str(root/'tools/vgmstream/vgmstream-cli.exe');sounds={};audioRecords=[];sourceRecords=[];moves={};scripts=[];archiveCache={}
def extract_bank(game,name):
    archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 5/main/data/soundpar/sound.par')if game=='y5'else Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/sound.par')
    if game not in archiveCache:
        with archive.open('rb')as stream:
            header=stream.read(32);dirs,_,count,entries=struct.unpack_from('>4I',header,16);stream.seek(32+dirs*64);names=[stream.read(64).split(b'\0')[0].decode('cp932','replace')for _ in range(count)]
        archiveCache[game]=(names,entries)
    names,entries=archiveCache[game];index=names.index(name)
    with archive.open('rb')as stream:
        stream.seek(entries+index*32);flags,plain,size,offset=struct.unpack('>4I',stream.read(16));assert flags==0 and plain==size;stream.seek(offset);data=stream.read(size)
    path=work/(game+'-'+name);path.write_bytes(data)
    return path,{'archive':str(archive),'entry':name,'entryOffset':offset,'entrySize':size,'entrySha256':sha(data)}

def mapped_events(events,mapping,segments=None):
    result=[]
    for event in events:
        frame=event['element']['start']
        for index,source in enumerate(mapping):
            if source<=frame<source+1:
                if segments:
                    segment=next((r for r in segments if r['first']<=index<=r['last']),None)
                    if segment and not segment['eventStart']<=frame<=segment['eventEnd']:continue
                result.append((index+frame-source,event))
    return sorted(result,key=lambda r:(r[0],r[1]['offset']))

def literal(value):
    if isinstance(value,str):return json.dumps(value,ensure_ascii=True)
    if isinstance(value,bool):return str(value).lower()
    if isinstance(value,(int,float)):return format(value,'.12g')
    if isinstance(value,list):return '{'+','.join(literal(v)for v in value)+'}'
    return '{'+','.join('['+json.dumps(k)+']='+literal(v)for k,v in sorted(value.items()))+'}'

for key,(folder,bankName,animation)in scenes.items():
    scene=read_scene(root/'extracted'/folder/'cmn.par/cmn.bin');game='y5'if scene['version']==10 else'y6';bank,bankMeta=extract_bank(game,bankName);names=cue_names(bank.read_bytes())
    meta=json.loads(subprocess.check_output([vgm,'-I','-m',str(bank)],text=True));total=meta.get('streamInfo',{}).get('total',1);streams={}
    for index in range(1,total+1):
        info=json.loads(subprocess.check_output([vgm,'-I','-m','-s',str(index),str(bank)],text=True));streams.setdefault(info.get('streamInfo',{}).get('name',''),[]).append((index,info))
    for node in scene['nodes']:
        if 'sound'in node:
            sound=node['sound']
            if not sound['fighter']:
                assert sound['cueId']in names,(key,sound)
                sound['name']=names[sound['cueId']]
                if sound['name'].startswith('Kiryu_'):sound['fighter']=True
    if key=='rush':
        sections=json.loads((mod/'docs/rush-twohit-sections.json').read_text());mapping=sections['clips'][0]['sourceFrames'];segments=[]
        for i,(a,b)in enumerate(sections['pairs']):segments.append({'first':41+i*30,'last':70+i*30,'eventStart':[41,71,95][i%3],'eventEnd':[70,94,118][i%3]})
        ending=next(r['sourceFrames']for r in sections['clips']if r['ending'])
    elif key=='crate':
        sections=json.loads((mod/'docs/crate-heat-assets.json').read_text());mapping=next(r['sourceFrames']for r in sections['clips']if r['role']==0 and not r['ending']);ending=next(r['sourceFrames']for r in sections['clips']if r['role']==0 and r['ending']);segments=None
    elif key=='bicycle':
        mapping=json.loads((mod/'docs/bicycle-heat-assets.json').read_text())['sourceFrames'];ending=None;segments=None
    else:
        length=int(max(n['motion']['end']for n in scene['nodes']if'motion'in n));mapping=list(range(length+1));ending=None;segments=None
    damage=[n for n in scene['nodes']if'damage'in n and n['role']=='victim'];soundNodes=[n for n in scene['nodes']if'sound'in n];particleNodes=[n for n in scene['nodes']if'particle'in n and n['role']=='victim'and n['name'].startswith(('YNb','YAb'))and n.get('bone')]
    effectsPolicy='Original blood particle starts and bone-local attachments; existing supplied blood pixels only. Non-blood engine-specific emitters and cinematic cameras are not substituted.'
    record={'id':key,'source':scene['source'],'sourceSha256':scene['sha256'],'version':scene['version'],'byteOrder':scene['byteOrder'],'animation':animation,'sourceFrames':mapping,'endingFrames':ending,'damage':[{'frame':n['element']['start'],**n['damage'],'offset':n['offset']}for n in damage],'ignoredNonVictimDamage':[{'frame':n['element']['start'],'role':n['role'],**n['damage']}for n in scene['nodes']if'damage'in n and n['role']!='victim'],'bank':bankMeta,'effectsPolicy':effectsPolicy,'segments':segments,'definitions':[]}
    for failure,frames in [(False,mapping),*([(True,ending)]if ending else[])]:
        clip=animation.replace('HeatRush','HeatRushFail').replace('CrateHeat','CrateHeatFail')if failure else animation
        events=mapped_events(damage,frames,None if failure else segments);contacts=[]
        for i,(frame,node)in enumerate(events):
            multiplier=0 if key in['rush','crate']else (1.5 if key in['bottle','katana','bat','bicycle','knife']else 5)*node['damage']['damage']/sum(n['damage']['damage']for n in damage)
            contacts.append({'atMs':frame/30*1000,'damageMultiplier':multiplier,'cue':'punchImpact','strong':i==len(events)-1,'charged':key=='rush'and i==len(events)-1})
        if key=='ground':contacts=[{'atMs':1000,'damageMultiplier':5,'cue':'heavyImpact','strong':True}]
        if key in['rush','crate']:
            assert contacts
            contacts[-1]['cue']='kickImpact'if key=='rush'else'heavyImpact'
            if not failure:contacts[-1].update(sumQTE=True,**({'baseDamageMultiplier':1.5}if key=='crate'else{}))
            else:contacts[-1]['damageMultiplier']=0
        if key=='katana':
            for c,cue in zip(contacts,['heatKatanaSlash','heatKatanaPunch','heatKatanaThrust']):c['cue']=cue
        audio=[];voices=[]
        for frame,node in mapped_events(soundNodes,frames,None if failure else segments):
            sound=node['sound'];at=frame/30*1000
            if sound['fighter']:
                if node['role']=='actor':
                    label=node['name'].upper();entry='CombatSpecialMove'if'THROW'in label else'CombatHeavyAttack'if any(s in label for s in['ATTACK_L','ATTACK_XL'])or sound.get('name')=='Kiryu_Attack07'else'CombatLightAttack'
                    voices.append({'atMs':at,'entry':entry})
                continue
            cueName=sound['name'];assert cueName in streams,(key,cueName)
            index,info=streams[cueName][0];assert len(streams[cueName])==1,(key,cueName)
            cue='heatScene'+key.title()+str(sound['cueId']);soundName='ProjectYakuza_HeatScene_'+key+'_'+str(sound['cueId'])
            if key=='katana':
                cue={'bodyfall':'heatKatanaBodyFall','katana_swing':'heatKatanaSwing','punch':'heatKatanaPunch','slash':'heatKatanaSlash','tuki':'heatKatanaThrust'}[cueName]
            elif cue not in sounds:
                rel='42/media/sound/ProjectYakuza/HeatScene_'+key+'_'+str(sound['cueId'])+'.wav';output=mod/rel
                if write:subprocess.run([vgm,'-s',str(index),'-i','-o',str(output),str(bank)],check=True,capture_output=True)
                assert output.exists(),rel
                with wave.open(str(output))as wav:rate,channels,width,samples=wav.getframerate(),wav.getnchannels(),wav.getsampwidth(),wav.getnframes()
                assert(rate,channels,width,samples)==(info['sampleRate'],info['channels'],2,info['numberOfSamples'])
                sounds[cue]=soundName;audioRecords.append({**bankMeta,'cue':cue,'sound':soundName,'cueId':sound['cueId'],'soundIndex':sound['soundIndex'],'streamIndex':index,'stream':cueName,'output':rel,'sha256':sha(output.read_bytes()),'sampleRate':rate,'channels':channels,'samples':samples})
                scripts.append('    sound '+soundName+'\n    {\n        category = ProjectYakuza_Effects,\n        is3D = true,\n        loop = false,\n        clip\n        {\n            file = media/sound/ProjectYakuza/'+output.name+',\n            distanceMin = 1,\n            distanceMax = 16,\n            volume = 0.65,\n        }\n    }')
            audio.append({'atMs':at,'cue':cue,'target':'victim'if node['role']=='victim'else'actor'})
        particles=[]
        for frame,node in mapped_events(particleNodes,frames,None if failure else segments):
            if frame>=len(frames)-1:continue
            index=min(range(len(contacts)),key=lambda i:abs(contacts[i]['atMs']-frame/30*1000))+1
            particles.append({'frame':frame,'sourceFrame':node['element']['start'],'sourceOffset':node['offset'],'name':node['name'],'id':node['particle']['id'],'bone':node['bone'],'localPoint':node['particle']['matrix'][12:15],'contact':index})
        definition={'animation':clip,'contacts':contacts,'audioEvents':audio,'voiceEvents':voices,'particles':particles,'sourceFrames':frames,'damagePolicy':'New weapon action: 1.5 canonical damage distributed using original victim damage weights.'if key in['bat','bicycle']else'Preserve existing QTE-earned final damage aggregation.'if key in['rush','crate']else'Preserve total damage, distribute using original victim damage weights.'if damage else'No CMN damage nodes: retain verified frame-30 sole/head contact.'}
        record['definitions'].append(definition)
    main=record['definitions'][0];moves[key]={k:main[k]for k in['contacts','audioEvents','voiceEvents']}
    if ending:
        fail=record['definitions'][1];moves[key]['ending']={k:fail[k]for k in['audioEvents','voiceEvents']};moves[key]['ending']['contactMs']=fail['contacts'][-1]['atMs']
    sourceRecords.append(record)
data={'moves':moves,'sounds':sounds};code='require "ProjectYakuza/Registry"\nProjectYakuza.HeatSceneData='+literal(data)+'\n'
report={'operation':'Parsed supplied CMN18 and big-endian CMN10 victim damage, SE cue indices, actor voice labels and source blood attachments. Original 30 FPS frame mappings preserve authored bounded QTE repeats/endings. Original non-voice bank streams decoded without synthesis or mixing; no separate voice pack changed.','formatReferences':['https://github.com/Fronkln/HActLib','https://github.com/vgmstream/vgmstream/blob/master/src/util/cri_utf.c'],'scenes':sourceRecords,'sounds':audioRecords}
outputs={mod/'42/media/lua/shared/ProjectYakuza/HeatSceneData.lua':code,mod/'docs/heat-scenes.json':json.dumps(report,indent=2,ensure_ascii=True)+'\n',mod/'42/media/scripts/ProjectYakuza_HeatScenes.txt':'module Base\n{\n'+'\n'.join(scripts)+'\n}\n'}
for path,text in outputs.items():
    if write:path.write_bytes(text.encode('utf-8'))
    else:assert path.read_bytes()==text.encode('utf-8'),str(path)
print('PASS',len(sourceRecords),'CMN scenes,',sum(len(r['definitions'])for r in sourceRecords),'main/ending timelines and',len(audioRecords),'original non-voice sounds')
