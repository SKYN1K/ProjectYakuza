from pathlib import Path
import hashlib,json,math,re,subprocess,sys,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[2]
MOD=ROOT/'combat/ProjectYakuza'
LUA=MOD/'42/media/lua'
WORK=Path(__file__).parent
GAME=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid')
JAVA=str(GAME/'jre64/bin/java.exe')
EXPORT="""local rows={}
local function add(profile,kind,m)
 if not m or not m.animation then return end
 if not ({light=true,ground=true,directional=true,finisher=true,chargedHeavy=true,quickstepAttack=true,runningAttack=true,heatAction=true,parry=true})[kind]then return end
 local times={};for _,q in ipairs(m.contacts or m.qte and m.qte.prompts or {})do times[#times+1]=q.atMs/1000 end
 if #times==0 and m.contactMs then times[1]=m.contactMs/1000 end
 rows[#rows+1]=table.concat({profile,kind,m.animation,tostring(m.duration or 0),tostring(m.speed or 1.6),tostring(m.impact or -1),table.concat(times,","),tostring(m.kick or false),m.nodeValue or "",m.animation},"|")
 local f=m.qteFailure
 if f and f.paired then rows[#rows+1]=table.concat({profile,kind,f.animation,tostring(f.duration),"1","-1",tostring(f.contactMs/1000),"false",f.nodeValue or "",m.animation},"|")end
end
local function scan(profile,s)
 for _,m in ipairs(s.lightAttacks or {})do add(profile,"light",m)end
 for _,m in ipairs(s.extremeLightAttacks or {})do add(profile,"light",m)end
 for _,m in ipairs(s.groundAttacks or {})do add(profile,"ground",m)end
 for _,m in ipairs(s.actions.grab and s.actions.grab.strikes or {})do add(profile,"light",m)end
 for _,m in pairs(s.directionalAttacks and s.directionalAttacks.moves or {})do add(profile,"directional",m)end
 for kind,slot in pairs(s.actions)do if slot.enabled then if slot.variants then for _,m in pairs(slot.variants)do if m.enabled~=false then add(profile,kind,m)end end else add(profile,kind,slot)end end end
end
scan("unarmed",ProjectYakuza.getStyle("dragon_of_dojima"))
for profile,s in pairs(ProjectYakuza.Weapons.views.dragon_of_dojima)do scan(profile,s)end
return table.concat(rows,"\\n")"""
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def run(args):
 if args[0]==JAVA:args=[args[0],'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2',*args[1:]]
 r=subprocess.run(args,cwd=WORK,capture_output=True,text=True,encoding='utf-8',errors='replace')
 if r.returncode:raise RuntimeError(r.stdout+r.stderr)
 return r.stdout
from fixture_markers import module_source
parts=['require=function()end']
for name in ('shared/ProjectYakuza/Registry.lua','shared/ProjectYakuza/Weapons.lua','shared/ProjectYakuza/Styles/DragonOfDojima.lua'):parts.append('do\n'+module_source(LUA/name)+'\nend')
export=WORK/'export-effect-moves.lua';export.write_text('\n'.join(parts)+'\n'+EXPORT,encoding='utf-8')
result=run([JAVA,'-cp','.;'+str(GAME/'projectzomboid.jar'),'LuaRunner',export.name])
assert '=> [true, 'in result,result
rows=result.split('=> [true, ',1)[1].rstrip().removesuffix(']').splitlines();moves={}
for line in rows:
 profile,kind,animation,duration,speed,impact,qte,kick,node,family=line.split('|')
 moves.setdefault(animation,{'profile':profile,'kind':kind,'animation':animation,'family':family,'node':node,'impact':float(impact),'kick':kick=='true','qte':[float(v)for v in qte.split(',')if v]})
contacts={}
for p in (MOD/'42/media/AnimSets/player').rglob('*.xml'):
 if not p.name.startswith('ProjectYakuza_DD_'):continue
 n=E.parse(p).getroot();animation=n.findtext('m_AnimName')
 node=next((c.findtext('m_Value')for c in n.findall('m_Conditions')if c.findtext('m_Name')=='ProjectYakuzaMove'),None)
 if animation not in moves and (MOD/f'42/media/anims_X/Bob/{animation}.x').is_file():
  source=next((m for m in moves.values()if m['node']==node and node),None)
  if source:moves[animation]={**source,'animation':animation}
 for event in n.findall('m_Events'):
  if event.findtext('m_EventName')=='AttackCollisionCheck':contacts.setdefault(animation,set()).add(float(event.findtext('m_TimePc')))
folder=WORK/'all-trail-native';folder.mkdir(exist_ok=True)
args=[JAVA,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;'+str(GAME/'*'),'LimbTrailProbe']
for animation in sorted(moves):args.extend([str(MOD/f'42/media/anims_X/Bob/{animation}.x'),str(folder/(animation+'.json'))])
run(args)
names=['leftArm','rightArm','leftLeg','rightLeg'];triplets=[(0,1,2,12),(3,4,5,13),(6,7,8,14),(9,10,11,15)]
verified={'ProjectYakuza_DD_Light01':0,'ProjectYakuza_DD_Finisher02':3}
output=['require "ProjectYakuza/AttackTracks"','local T=ProjectYakuza.AttackTracks','local C={};ProjectYakuza.AttackEffectCatalog={dragon_of_dojima=C}'];records=[]
for animation,move in sorted(moves.items()):
 native=json.loads((folder/(animation+'.json')).read_text());frames=native['frames'];duration=(len(frames)-1)/30
 times=move['qte']or sorted({round(t*duration*30)/30 for t in contacts.get(animation,[])})
 if not times:times=[round((move['impact']*duration if move['impact']>=0 else min(.3,duration*.25))*30)/30]
 windows=[]
 for hit,time in enumerate(times):
  frame=max(1,min(len(frames)-2,round(time*30)));scores=[]
  for limb,(a,b,c,upper)in enumerate(triplets):
   score=0
   for f in range(max(1,frame-2),min(len(frames),frame+3)):
    old,new=frames[f-1],frames[f]
    speed=math.sqrt(sum((new[b][j]-old[b][j])**2 for j in range(3)))
    relative=math.sqrt(sum(((new[b][j]-new[upper][j])-(old[b][j]-old[upper][j]))**2 for j in range(3)))
    score+=.35*speed+.65*relative
   scores.append(score)
  allowed=[0,1]if move['profile']!='unarmed'else [2,3]if move['kick']or move['kind']in ('ground','runningAttack')else list(range(4))
  limb=[1,1,1][hit]if animation=='ProjectYakuza_DD_KatanaHeat'else verified.get(animation,max(allowed,key=lambda i:scores[i]))
  a,b,c,upper=triplets[limb];key='dd_trail_'+animation.removeprefix('ProjectYakuza_DD_').lower()+'_'+str(hit+1)
  output.append('T["'+key+'"]=(function()return {animation="'+animation+'",fps=30,limb="'+names[limb]+'",duration='+str(duration)+',frames={')
  output.extend('    {'+','.join(f'{v:.9f}'for bone in (a,b,c)for v in frame[bone])+'},'for frame in frames)
  output.append('},upperFrames={')
  output.extend('    {'+','.join(f'{v:.9f}'for v in frame[upper])+'},'for frame in frames)
  output.append('}}end)()')
  start=max(0,time-.12);end=min(duration,time+.20)
  if hit:start=max(start,(times[hit-1]+time)/2)
  if hit+1<len(times):end=min(end,(time+times[hit+1])/2)
  windows.append({'track':key,'from':start,'to':end,'contact':time,'limb':names[limb],'scores':scores,'selection':'verified original damage frames 24,44,64: right-arm slash, right-fist punch, right-arm thrust'if animation=='ProjectYakuza_DD_KatanaHeat'else'verified native contact pose'if animation in verified else'contact-local relative motion'})
 output.append('C["'+animation+'"]={animation="'+animation+'",actionAnimation="'+move['family']+'",track="'+windows[0]['track']+'",duration='+str(duration)+',from='+str(windows[0]['from'])+',to='+str(windows[-1]['to'])+',windows={'+','.join('{track="'+r['track']+'",from='+str(r['from'])+',to='+str(r['to'])+'}'for r in windows)+'}}')
 records.append({**move,'clip':f'42/media/anims_X/Bob/{animation}.x','clipSha256':digest(MOD/f'42/media/anims_X/Bob/{animation}.x'),'samples':len(frames),'duration':duration,'windows':windows})
code=('\n'.join(output)+'\n').encode();target=LUA/'client/ProjectYakuza/AttackTrailCatalog.lua'
report={'operation':'Code-side numeric FK only from existing supplied PZ clips, including current paired contacts/endings and linked native finisher variants. Contacts use native collision events, authored Heat Action contacts or the documented parry fallback. Clips use contact-local endpoint/relative motion with verified original left-light and right-high-kick pose overrides, independent of charge-up pose. The high kick has right-foot height 0.721 versus planted left foot 0.093 at source frame 24; recovering arms can be faster than the striking leg. Runtime resolves the actual playing clip within the committed move family. No visual/audio/animation/model assets are generated or modified.','catalog':target.relative_to(MOD).as_posix(),'sha256':hashlib.sha256(code).hexdigest(),'clips':records}
manifest=(json.dumps(report,indent=2)+'\n').encode()
if '--write'in sys.argv:target.write_bytes(code);(MOD/'docs/attack-trail-catalog.json').write_bytes(manifest)
else:assert target.read_bytes()==code and (MOD/'docs/attack-trail-catalog.json').read_bytes()==manifest,'numeric catalogue differs from native source'
print('PASS',len(records),'active attack clips,',sum(len(r['windows'])for r in records),'contact windows, native limb FK and deterministic catalogue; no media generated')
for row in records:print(row['animation'],','.join(w['limb']for w in row['windows']))
