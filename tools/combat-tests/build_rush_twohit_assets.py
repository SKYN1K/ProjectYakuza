from pathlib import Path
import sys,json,zipfile,hashlib,copy,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,blocks,write
mod=root/'combat/ProjectYakuza';media=mod/'42/media';work=root/'tools/rush-twohit-source';work.mkdir(exist_ok=True)
old=json.loads((mod/'docs/heat-rush-assets.json').read_text());mapping=list(range(41));pairs=[(41,70),(69,98),(89,118)]*2
for first,last in pairs:mapping.extend(range(first,last+1))
mapping.extend(range(119,225));assert len(mapping)==327
records=[]
with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.83.0.zip')as z:
 for role,stem in [('actor','HeatRush'),('victim','HeatRushVictim')]:
  name='ProjectYakuza_DD_'+stem;rel='42/media/anims_X/Bob/'+name+'.x';raw=work/(name+'.x');raw.write_bytes(z.read('ProjectYakuza/'+rel));text,b,c,spans=read(raw)
  for ending in [False,True]:
   frames=list(range(118,225))if ending else mapping
   destName=('ProjectYakuza_DD_HeatRushFail'+('Victim'if role=='victim'else''))if ending else name;dest=media/'anims_X/Bob'/(destName+'.x');values=[locals_at(b,c,i*160)for i in frames];write(dest,text,spans,blocks(b,values,[i*160 for i in range(len(values))],None),destName)
   records.append({'role':role,'ending':ending,'output':dest.relative_to(mod).as_posix(),'source':str(raw),'sourceSha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'sourceFrames':frames,'frames':len(frames),'fps':30})
paths=[[],[]];anchor=[0.,0.]
for i,frame in enumerate(mapping):
 if i and frame!=mapping[i-1]+1:
  for axis in range(2):anchor[axis]+=old['paths'][0][mapping[i-1]][axis]-old['paths'][0][frame][axis]
 for role in range(2):paths[role].append([old['paths'][role][frame][a]+anchor[a]for a in range(2)])
cuts=[]
for i in range(1,len(mapping)):
 if mapping[i]!=mapping[i-1]+1:
  correction=[paths[1][i-1][a]-paths[1][i][a]for a in range(2)];cuts.append({'frame':i,'victimCorrection':correction,'blendFrames':6})
  for age in range(6):
   t=age/6;fade=1-t*t*(3-2*t)
   for axis in range(2):paths[1][i+age][axis]+=correction[axis]*fade
ending=[]
for role in range(2):ending.append([[old['paths'][role][f][a]-old['paths'][0][118][a]for a in range(2)]for f in range(118,225)])
def lua(v):
 if isinstance(v,str):return json.dumps(v)
 if isinstance(v,bool):return str(v).lower()
 if isinstance(v,(int,float)):return format(v,'.9g')
 if isinstance(v,list):return '{'+','.join(lua(x)for x in v)+'}'
 return '{'+','.join(k+'='+lua(x)for k,x in v.items())+'}'
code='require "ProjectYakuza/Registry"\nProjectYakuza.HeatRushPaths='+lua({'fps':30,'actor':paths[0],'victim':paths[1],'victimFacing':{'forward':-1,'right':0}})+'\n'
(media/'lua/shared/ProjectYakuza/HeatRushPaths.lua').write_text(code)
(media/'lua/shared/ProjectYakuza/RushEndingPaths.lua').write_text('require "ProjectYakuza/Registry"\nProjectYakuza.RushEndingPaths='+lua({'fps':30,'actor':ending[0],'victim':ending[1],'duration':106/30,'targetAnimation':'ProjectYakuza_DD_HeatRushFailVictim','victimFacing':{'forward':-1,'right':0}})+'\nProjectYakuza.PairedMotions=ProjectYakuza.PairedMotions or {}\nProjectYakuza.PairedMotions.dod_rush_ending=ProjectYakuza.RushEndingPaths\n')
contacts=[];prompts=[];bounds=[40,70,100,130,160,190,220]
for index,(first,last)in enumerate(pairs,1):
 sourceHits=[56,63]if first==41 else[77,85]if first==69 else[102,110]
 for j,frame in enumerate(sourceHits):contacts.append({'atMs':(bounds[index-1]+frame-(first-1))/30*1000,'damageMultiplier':0,'cue':'punchImpact'if j==0 else'heatImpact','strong':False,'charged':j==1,**({'voice':'CombatLightAttack'}if j==0 else{})})
 prompts.append({'atMs':bounds[index]/30*1000,'windowMs':1000,'binding':['light','finisher','grab'][(index-1)%3],'damageMultiplier':.625})
contacts.append({'atMs':245/30*1000,'sumQTE':True,'cue':'kickImpact','strong':True,'charged':True,'layers':['heavyImpact','heatImpact'],'voice':'CombatHeavyAttack'})
action={'enabled':True,'animation':'ProjectYakuza_DD_HeatRush','targetAnimation':'ProjectYakuza_DD_HeatRushVictim','nodeValue':'dd_heat_rush','requiresTarget':True,'extremeHeat':True,'heatRush':True,'duration':326/30,'hitResponse':False,'noKnockback':True,'qteStages':True,'qteFailure':{'animation':'ProjectYakuza_DD_HeatRushFail','targetAnimation':'ProjectYakuza_DD_HeatRushFailVictim','nodeValue':'dd_heat_rush_fail','duration':106/30,'paired':True,'motionId':'dod_rush_ending','contactMs':25/30*1000},'qte':{'failureLimit':1,'failureMode':'consecutive','feedback':{'success':'heatGain','miss':'guardHit','failure':'heatOff','gain':.35},'prompts':prompts},'contacts':contacts}
(media/'lua/shared/ProjectYakuza/RushMove.lua').write_text('require "ProjectYakuza/Registry"\nrequire "ProjectYakuza/RushEndingPaths"\nProjectYakuza.RushMove='+lua(action)+'\n')
style=media/'lua/shared/ProjectYakuza/Styles/DragonOfDojima.lua';s=style.read_text();lines=s.splitlines();lines=[('        heatAction=ProjectYakuza.RushMove,'if line.strip().startswith('heatAction={enabled=true,animation="ProjectYakuza_DD_HeatRush"')else line)for line in lines];s='\n'.join(lines)+'\n';s=s.replace('require "ProjectYakuza/GrabMoves"','require "ProjectYakuza/GrabMoves"\nrequire "ProjectYakuza/RushMove"');style.write_text(s)
for group,stem in [('zombie/hitreaction','ProjectYakuza_DD_HeatRushVictim'),('zombie/hitreaction-hit','ProjectYakuza_DD_HeatRushVictim'),('zombie/idle','ProjectYakuza_DD_HeatRushVictim'),('player/actions','ProjectYakuza_PVP_HeatRushVictim'),('player/hitreactionpvp','ProjectYakuza_PVP_HeatRushVictim')]:
 p=media/'AnimSets'/group/(stem+'.xml');n=E.parse(p).getroot();n.find('m_Name').text=stem.replace('HeatRushVictim','HeatRushFailVictim');n.find('m_AnimName').text='ProjectYakuza_DD_HeatRushFailVictim'
 for c in n.findall('m_Conditions'):
  if c.findtext('m_Name')=='ProjectYakuzaPairedVictimClip':c.find('m_Value').text='ProjectYakuza_DD_HeatRushFailVictim'
 E.ElementTree(n).write(p.with_name(stem.replace('HeatRushVictim','HeatRushFailVictim')+'.xml'),encoding='utf-8',xml_declaration=True)
report={'authorization':'User approved splitting and replaying original two-punch sections on 2026-11-05, and declined slowing/retiming original motion.','operation':'Copied original converted source poses at 30 fps. Three original two-hit sections are replayed twice. Every QTE spans one one-second section containing two source contacts. The original final kick is automatic on success or failure. No new poses, artwork, audio, AI or upscaling.','baseline':'ProjectYakuza-B42-v0.83.0.zip','clips':records,'pairs':pairs,'qteFrames':bounds[1:],'contactFrames':[round(c['atMs']*.03)for c in contacts],'paths':paths,'endingPaths':ending,'stagingCuts':cuts,'duration':326/30}
(mod/'docs/rush-twohit-sections.json').write_text(json.dumps(report,indent=2)+'\n')
print('PASS split/replayed original sections:',len(records),'clips,',len(mapping),'frames, 12 punch contacts, 6 one-second QTEs, automatic source kick')
