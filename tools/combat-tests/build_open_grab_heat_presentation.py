from pathlib import Path
import sys,subprocess,json,hashlib,wave,array,math

root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;mod=root/'combat/ProjectYakuza';clip='ProjectYakuza_DD_OpenGrabHeat';victim=mod/'42/media/anims_X/Bob'/(clip+'Victim.x');posePath=w/'open-grab-victim-native.json';java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*','LimbTrailProbe',str(victim),str(posePath)],cwd=w,check=True)
native=json.loads(posePath.read_text(encoding='utf-8'));scene=json.loads((mod/'docs/open-grab-heat-scene.json').read_text(encoding='utf-8'));definition=scene['scenes'][0]['definitions'][0];assert definition['particles']==[];head=native['bones'].index('Bip01_Head');contacts=[];leads={};audio=[]
for i,contact in enumerate(definition['contacts']):
    frame=round(contact['atMs']*.03);contacts.append({'atMs':contact['atMs'],'index':i+1,'cue':contact['cue'],'point':native['frames'][frame][head],'bone':'Bip01_Head','feedback':'unarmed'})
for sound in scene['sounds']:
    path=mod/sound['output']
    with wave.open(str(path))as stream:
        assert stream.getsampwidth()==2;rate=stream.getframerate();channels=stream.getnchannels();samples=array.array('h',stream.readframes(stream.getnframes()))
    block=max(1,rate//200)*channels;rms=[math.sqrt(sum(v*v for v in samples[i:i+block])/max(1,len(samples[i:i+block])))for i in range(0,len(samples),block)];peak=max(rms);lead=min(120,next(i for i,v in enumerate(rms)if v>=peak*.65)*5);relative=path.relative_to(mod/'42').as_posix();leads[relative]=lead;audio.append({'file':relative,'sha256':sha(path),'attackLeadMs':lead})

def literal(value):
    if isinstance(value,str):return json.dumps(value)
    if isinstance(value,bool):return str(value).lower()
    if isinstance(value,(int,float)):return format(value,'.12g')
    if isinstance(value,list):return '{'+','.join(literal(v)for v in value)+'}'
    return '{'+','.join('['+json.dumps(k)+']='+literal(v)for k,v in sorted(value.items()))+'}'

data={'contacts':contacts,'effects':[{'atMs':c['atMs'],'index':c['index'],'point':c['point'],'bone':c['bone'],'feedback':'unarmed'}for c in contacts]};code='require "ProjectYakuza/HeatPresentationData"\nProjectYakuza.HeatPresentationData.moves['+json.dumps(clip)+']='+literal(data)+'\nfor key,value in pairs('+literal(leads)+')do ProjectYakuza.HeatPresentationData.leads[key]=value end\n';output=mod/'42/media/lua/client/ProjectYakuza/OpenGrabHeatPresentation.lua';output.write_text(code,encoding='utf-8');report={'operation':'Actual native B42 imported victim head anchors at the two original damage frames. Original audio attack leads measured from decoded supplied PCM, without synthesis, mixing or new pixels. No authored blood emitters are present; existing native-contact effect/blood rendering is used.','actorSha256':sha(mod/'42/media/anims_X/Bob'/(clip+'.x')),'victimSha256':sha(victim),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'contacts':contacts,'sounds':audio,'provenance':[{'path':str(p),'sha256':sha(p)}for p in [Path(__file__),w/'LimbTrailProbe.java',mod/'docs/open-grab-heat-scene.json']]};(mod/'docs/open-grab-heat-presentation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print('PASS native victim anchors at frames 117/167 and',len(audio),'original audio attack leads')
