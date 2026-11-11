from pathlib import Path
import sys,subprocess,json,hashlib,re,array,math
from fixture_markers import module_source
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';lua=mod/'42/media/lua';w=Path(__file__).parent;game=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid');java=str(game/'jre64/bin/java.exe')
export='''local function enc(v)
 if type(v)=="string"then return '"'..v..'"'elseif type(v)=="number"then return tostring(v)elseif type(v)=="boolean"then return tostring(v)end
 local a={};if #v>0 then for _,x in ipairs(v)do a[#a+1]=enc(x)end;return "["..table.concat(a,",").."]"end
 for k,x in pairs(v)do a[#a+1]='"'..k..'":'..enc(x)end;return "{"..table.concat(a,",").."}"
end
local PY=ProjectYakuza;local base=PY.getStyle("dragon_of_dojima");local rows={}
local function add(style,move)
 local motion=PY.HeatRushRules.motion(move)
rows[#rows+1]={animation=move.animation,targetAnimation=move.targetAnimation,contacts=move.contacts,sounds=style.sounds,baseSounds=base.sounds,motion=motion,audioEvents=move.audioEvents}
 if move.qteFailure and move.qteFailure.paired then local f=move.qteFailure;local c={};for k,v in pairs(move.contacts[#move.contacts])do c[k]=v end;c.atMs=f.contactMs;c.index=#move.contacts;rows[#rows+1]={animation=f.animation,targetAnimation=f.targetAnimation,contacts={c},sounds=style.sounds,baseSounds=base.sounds,motion=PY.PairedMotions[f.motionId],audioEvents=f.audioEvents}end
end
add(base,base.actions.heatAction);add(base,base.actions.grabHeat);add(base,base.actions.groundHeat)
for _,profile in ipairs({"blade","bottle","crate","bat","bicycle"})do local s=PY.Weapons.views[base.id][profile];add(s,s.actions.heatAction)end
return enc(rows)'''
parts=['require=function()end']
for name in ['Registry','Weapons','HeatRushPaths','KatanaHeatPaths','BottleHeatPaths'] :parts.append('do\n'+module_source(lua/f'shared/ProjectYakuza/{name}.lua')+'\nend')
parts.append('do\n'+module_source(lua/'shared/ProjectYakuza/Styles/DragonOfDojima.lua')+'\nend');parts.append('do\n'+module_source(lua/'shared/ProjectYakuza/HeatRushRules.lua')+'\nend')
p=w/'export-heat-presentation.lua';p.write_text('\n'.join(parts)+'\n'+export)
r=subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','-cp','.;'+str(game/'projectzomboid.jar'),'LuaRunner',p.name],cwd=w,capture_output=True,text=True);assert r.returncode==0,r.stdout+r.stderr;rows=json.loads(r.stdout.split('=> [true, ',1)[1].strip()[:-1]);folder=w/'heat-presentation-native';folder.mkdir(exist_ok=True)
names=sorted({r[k]for r in rows for k in ['animation','targetAnimation']});args=[java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;'+str(game/'*'),'LimbTrailProbe']
for n in names:args.extend([str(mod/f'42/media/anims_X/Bob/{n}.x'),str(folder/(n+'.json'))])
r=subprocess.run(args,cwd=w,capture_output=True,text=True);assert r.returncode==0,r.stdout+r.stderr
catalog=json.loads((mod/'docs/attack-trail-catalog.json').read_text());tracks={r['animation']:r for r in catalog['clips']};definitions={};records=[];sounds=set();katana=json.loads((mod/'docs/katana-heat-assets.json').read_text());sceneEffects=json.loads((mod/'docs/heat-scene-effects.json').read_text())['moves']
def path(v,f):return v[min(f,len(v)-1)]
for row in rows:
 actor=json.loads((folder/(row['animation']+'.json')).read_text());victim=json.loads((folder/(row['targetAnimation']+'.json')).read_text());contacts=[]
 for i,c in enumerate(row['contacts']):
  f=round(c['atMs']*.03);entry=tracks.get(row['animation']);limb=entry['windows'][i]['limb']if entry else'rightLeg'if 'GroundHeat'in row['animation']else'rightArm';hand={'leftArm':1,'rightArm':4,'leftLeg':7,'rightLeg':10}[limb];a=actor['frames'][f][hand];af,ar=path(row['motion']['actor'],f);vf,vr=path(row['motion']['victim'],f);offset=row['motion'].get('contactOffset',{});vf+=offset.get('forward',0);vr+=offset.get('right',0)
  targets=range(16,21)
  if row['animation'].endswith('KatanaHeat'):targets=[[18],[16],[20]][i]
  if 'GroundHeat'in row['animation']:targets=[16]
  if 'WallHeat'in row['animation']:targets=[16]if i==0 else[18]
  if row['animation'].endswith(('BottleHeat','WallHeat'))and i==len(row['contacts'])-1:targets=[18]
  def distance(n):
   b=victim['frames'][f][n];return math.dist([af-a[2]*1.5,ar+a[0]*1.5,a[1]*1.5],[vf-b[2]*1.5,vr+b[0]*1.5,b[1]*1.5])
  bone=min(targets,key=distance);cue=c.get('cue','heavyImpact');base=False;layers=c.get('layers',[])
  if 'HeatRush'in row['animation']:cue='kickImpact'if limb.endswith('Leg')else'punchImpact';layers=[];base=True
  if row['animation'].endswith(('BottleHeat','WallHeat'))and i==len(row['contacts'])-1:cue='throwImpact';base=True
  if row['animation'].endswith('WallHeat')and i==1:cue='kickImpact';base=True
  if row['animation'].startswith('ProjectYakuza_DD_CrateHeat')and i>0 and i<len(row['contacts'])-1:cue='punchImpact';base=True
  event=(row['baseSounds']if base else row['sounds']).get(cue)or row['sounds'].get('heavyImpact');sounds.add(event)
  feedback='unarmed'if base and cue in ['punchImpact','kickImpact']else'blunt'if cue=='throwImpact'else None
  point=victim['frames'][f][bone];boneName=victim['bones'][bone];extra={}
  if row['animation'].endswith('KatanaHeat'):
   source=katana['effectPoints'][i];point=source['point'];boneName=source['bone'];feedback='unarmed'if i==1 else'blade';extra={'bloodOnly':True}
  contacts.append({'atMs':c['atMs'],'index':c.get('index',i+1),'cue':cue,'base':base,'point':point,'bone':boneName,**extra,'layers':layers,**({'feedback':feedback}if feedback else{})})
 for event in row.get('audioEvents',[]):sounds.add(row['sounds'][event['cue']])
 definitions[row['animation']]={'contacts':contacts,'effects':sceneEffects[row['animation']]};records.append({'animation':row['animation'],'targetAnimation':row['targetAnimation'],'actorSha256':hashlib.sha256((mod/f'42/media/anims_X/Bob/{row["animation"]}.x').read_bytes()).hexdigest(),'victimSha256':hashlib.sha256((mod/f'42/media/anims_X/Bob/{row["targetAnimation"]}.x').read_bytes()).hexdigest(),'contacts':contacts,'effects':sceneEffects[row['animation']]})
scripts='\n'.join(p.read_text()for p in (mod/'42/media/scripts').glob('*.txt'));files=set()
for event in sounds:
 m=re.search(r'\bsound\s+'+re.escape(event)+r'\s*\{',scripts);assert m,event;pos=m.end();depth=1
 while depth:depth+=(scripts[pos]=='{')-(scripts[pos]=='}');pos+=1
 files.update(re.findall(r'\bfile\s*=\s*([^,\r\n]+)',scripts[m.end():pos]))
leads={};audio=[]
for name in sorted(files):
 p=mod/'42'/name.strip();raw=subprocess.check_output(['C:/ProgramData/chocolatey/bin/ffmpeg.exe','-v','error','-i',str(p),'-f','f32le','-ac','1','-ar','48000','pipe:1']);samples=array.array('f',raw);rms=[math.sqrt(sum(v*v for v in samples[i:i+240])/240)for i in range(0,len(samples),240)];peak=max(rms);lead=min(120,next(i for i,v in enumerate(rms)if v>=peak*.65)*5);leads[name.strip()]=lead;audio.append({'file':name.strip(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'attackLeadMs':lead})
def literal(v):
 if isinstance(v,str):return json.dumps(v)
 if isinstance(v,bool):return str(v).lower()
 if isinstance(v,(int,float)):return format(v,'.9g')
 if isinstance(v,list):return '{'+','.join(literal(x)for x in v)+'}'
 return '{'+','.join('['+json.dumps(k)+']='+literal(x)for k,x in sorted(v.items()))+'}'
code='require "ProjectYakuza/Registry"\nProjectYakuza.HeatPresentationData='+literal({'moves':definitions,'leads':leads})+'\n';output=lua/'client/ProjectYakuza/HeatPresentationData.lua';report={'operation':'Numeric source-pose anchors through native B42 FK and in-memory PCM onset analysis of unchanged supplied clips. No assets generated, converted to files, edited or upscaled. All eight built-in scenes use original CMN victim damage and independently timed sound, voice and particle-bone events. Bounded QTE repeats and endings retain their source frame maps. Existing supplied blood pixels are reused. Custom clips retain measured transient leads.','clips':records,'sounds':audio}
if '--write'in sys.argv:output.write_text(code);(mod/'docs/heat-presentation-data.json').write_text(json.dumps(report,indent=2)+'\n')
else:assert output.read_text()==code and json.loads((mod/'docs/heat-presentation-data.json').read_text())==report
print('PASS',len(records),'paired main/ending clips,',sum(len(r['contacts'])for r in records),'native victim contact anchors and',len(audio),'unchanged audio onset measurements')
