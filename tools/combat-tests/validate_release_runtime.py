from pathlib import Path
import importlib.util,json,re,subprocess,hashlib,sys,xml.etree.ElementTree as E
sys.stdout.reconfigure(errors="replace")
ROOT=Path(__file__).resolve().parents[2];MOD=ROOT/'combat/ProjectYakuza';WORK=Path(__file__).parent
spec=importlib.util.spec_from_file_location('package',ROOT/'tools/Build-GamePackage.py');package=importlib.util.module_from_spec(spec);spec.loader.exec_module(package)
files=package.runtime_files(MOD,release=True);raw=package.runtime_files(MOD)
subprocess.run(['E:/Java/bin/javac.exe',str(WORK/'RemovedItemLoadProbe.java')],check=True)
for name,path in files.items():
 if path.suffix.lower()in {'.lua','.txt','.xml'}:
  text=path.read_text(encoding='utf-8')
  assert not re.search(r'ProjectYakuza[._/][\w_]*(?:Bottle|Crate|Bicycle|LauSpear)[\w_]*',text),name
  for module in re.findall(r'\brequire\s*[\( ]*"(ProjectYakuza/[^"\n]+)"',text):assert any('42/media/lua/'+side+'/'+module+'.lua'in files for side in ['shared','client','server']),(name,module)
 if path.suffix.lower()=='.xml':
  for node in E.fromstring(path.read_text()).iter('m_AnimName'):
   if node.text and node.text.startswith('ProjectYakuza'):assert '42/media/anims_X/Bob/'+node.text+'.x'in files,(name,node.text)
for token in ['IntactBeerBottle','IntactWineBottle','IntactWhiskeyBottle','BeerCrate','Bicycle','LauSpear']:
 assert all(not re.search(r'\bitem\s+'+token+r'\s*\{',p.read_text(encoding='utf-8'))for n,p in files.items()if '/scripts/'in n),token
items=[item for name,path in files.items()if '/scripts/'in name for item in re.findall(r'\bitem\s+(\w+)\s*\{',path.read_text(encoding='utf-8'))]
assert items==['StyleToken'],items
sources={}
for name,path in files.items():
 if name.endswith('.lua'):
  module=re.sub(r'^42/media/lua/(?:shared|client|server)/','',name)[:-4];sources[module]=path.read_text(encoding='utf-8')
version=re.search(r'^version=(.+)$',(MOD/'42/mod.info').read_text(),re.M)[1]
validation=ROOT/'tools/release-validation'/version/'lua'
for name,text in sources.items():
 path=validation/(name+'.lua');path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf-8',newline='\n')
java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe'
options=[java,'-Xms16m','-Xmx128m','-XX:+UseSerialGC','-XX:ReservedCodeCacheSize=32m','-XX:ActiveProcessorCount=2','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*']
result=subprocess.run([*options,'CompileCombatLua',str(validation)],cwd=WORK,capture_output=True,text=True,encoding='utf-8',errors='replace');print(result.stdout);assert result.returncode==0,result.stderr
loaded=set()
def append(name):
 if name in loaded:return ''
 loaded.add(name)
 text=re.sub(r'(?m)^\s*require\s*[\( ]*"(ProjectYakuza/[^"\n]+)"\s*\)?\s*$',lambda m:append(m[1]),sources[name])
 return 'do\n'+text+'\nend\n'
fixture=''.join(append('ProjectYakuza/'+name)for name in ['Registry','Weapons','Styles/DragonOfDojima','HeatRushRules','AttackTrailCatalog','HeatPresentationData','NetworkCatalog','NetworkProtocol'])
fixture+='''local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local PY=ProjectYakuza;local base=PY.getStyle('dragon_of_dojima');local views=PY.Weapons.views[base.id]
local count=0;for name in pairs(views)do count=count+1;check(name=='bat'or name=='blade'or name=='knife','only vanilla profiles')end
check(count==3,'exactly three retained profiles')
for _,pair in ipairs({{'Base.BaseballBat','bat'},{'Base.Katana','blade'},{'Base.HuntingKnife','knife'},{'Base.KitchenKnife','knife'},{'Base.Machete','blade'}})do
 local id=pair[1];local profile=PY.Weapons.profile(base.id,{getFullType=function()return id end,getCondition=function()return 1 end});check(profile==pair[2],'vanilla weapon retained '..id)
end
for _,name in ipairs({'BeerCrate','Bicycle','IntactBeerBottle','IntactWineBottle','IntactWhiskeyBottle','LauSpear'})do check(PY.Weapons.byItem[base.id]['ProjectYakuza.'..name]==nil,'removed item has no profile or Heat Action')end
for profile,clip in pairs({bat='BatHeat',blade='KatanaHeat',knife='KnifeHeat'})do local move=views[profile].actions.heatAction;check(move.enabled and move.weaponHeat and move.animation=='ProjectYakuza_DD_'..clip,'vanilla Heat Action retained')end
check(base.actions.heatAction.enabled and base.actions.grabHeat.enabled and base.actions.groundHeat.enabled,'unarmed Heat Actions retained')
for _,node in ipairs({'dd_bat_heat','dd_katana_heat','dd_knife_heat'})do check(PY.NetworkProtocol.move(base.id,node)~=nil,'MP can resolve retained weapon Heat Action')end
for _,node in ipairs({'dd_crate_heat','dd_bicycle_heat','dd_bottle_heat'})do check(PY.NetworkProtocol.move(base.id,node)==nil,'removed MP action cannot resolve')end
for _,clip in ipairs({'BottleHeat','CrateHeat','BicycleHeat'})do check(PY.NetworkProtocol.clip(base.id,'ProjectYakuza_DD_'..clip)==nil,'removed observer clip cannot resolve')end

for clip,entry in pairs(PY.AttackEffectCatalog.dragon_of_dojima)do for _,window in ipairs(entry.windows)do check(PY.AttackTracks[window.track].animation==clip,'released limb track resolves')end end
for _,name in ipairs({'bottle','crate','bicycle'})do check(PY.HeatSceneData.moves[name]==nil,'removed scene cannot register')end
return 'PASS '..checks..' player release compilation, vanilla weapon/profile/Heat Action preservation, removed custom actions, limb tracks and require closure'
'''
path=WORK/'release-runtime-tests.lua';path.write_text(fixture,encoding='utf-8',newline='\n');java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe'
result=subprocess.run([java,'-Xms16m','-Xmx128m','-XX:+UseSerialGC','-XX:ReservedCodeCacheSize=32m','-XX:ActiveProcessorCount=2','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*','LuaRunner',path.name],cwd=WORK,capture_output=True,text=True,encoding='utf-8',errors='replace');print(result.stdout);assert result.returncode==0,result.stderr
version=re.search(r'^version=(.+)$',(MOD/'42/mod.info').read_text(),re.M)[1]
report={'version':version,'releaseProfile':'vanilla-weapons','sourceFiles':len(raw),'runtimeFiles':len(files),'excludedCustomFiles':sorted(raw.keys()-files.keys()),'transformedFiles':[n for n,p in files.items()if p!=raw[n]],'retainedProfiles':['bat','blade','knife'],'retainedWeaponHeatActions':['BatHeat','KatanaHeat','KnifeHeat'],'canonicalCustomSourcePreserved':True,'originalMediaBytesUnchanged':all(p.read_bytes()==raw[n].read_bytes()for n,p in files.items()if p.suffix in {'.x','.png','.wav','.ogg','.mp3'}),'offlineOnly':True,'nativeMissingItemSaveRecordChecks':2}
result=subprocess.run([*options,'RemovedItemLoadProbe'],cwd=WORK,capture_output=True,text=True,encoding='utf-8',errors='replace');print(result.stdout);assert result.returncode==0,result.stderr
(MOD/('docs/release-profile-'+version+'.json')).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps({k:v for k,v in report.items()if k not in ['excludedCustomFiles','transformedFiles']}))
