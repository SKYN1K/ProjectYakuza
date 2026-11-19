from pathlib import Path
import argparse,hashlib,importlib.util,json,re,shutil
ROOT=Path(__file__).resolve().parent.parent;MOD=ROOT/'phone-dev/ProjectYakuzaPhoneDev';BASE=ROOT/'combat/ProjectYakuza';MOD_ID='ProjectYakuzaPhoneDev'
spec=importlib.util.spec_from_file_location('project_yakuza_runtime_package',ROOT/'tools/Build-GamePackage.py');package=importlib.util.module_from_spec(spec);spec.loader.exec_module(package)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def version(mod):return re.search(r'^version=(.+)$',(mod/'42/mod.info').read_text(),re.M)[1].strip()
def build(release,install=False):
 assert release==version(MOD)and re.fullmatch(r'\d+\.\d+\.\d+',release)
 assets=(MOD/'42/media/lua/client/ProjectYakuzaPhoneDev/Assets.lua').read_text();assert 'VERSION="'+release+'"'in assets
 required=re.search(r'requiredCombatVersion="([^"]+)"',assets)[1];base_version=version(BASE);assert tuple(map(int,base_version.split('.')))>=tuple(map(int,required.split('.')))
 assert 'require=ProjectYakuza'in(MOD/'42/mod.info').read_text()
 files=package.runtime_files(MOD);assert len(files)==34
 dist=ROOT/'dist';dist.mkdir(exist_ok=True);archive=dist/(MOD_ID+'-B42-v'+release+'.zip');package.write_zip(archive,MOD_ID,files)
 effects={n:sha(BASE/'42/media/lua/client/ProjectYakuza'/n)for n in ['AttackEffects.lua','ParentPosePrediction.lua','ParentPoseTracks.lua']}
 report={'version':release,'modId':MOD_ID,'combatVersion':base_version,'requiredCombatVersion':required,'sharedEffects':effects,'files':len(files),'zip':str(archive),'sha256':sha(archive),'runtimeOnly':True,'privacyScanPassed':True}
 if install:
  mods=Path.home()/'Zomboid/mods';target=(mods/MOD_ID).resolve();assert target.parent==mods.resolve()and target.name==MOD_ID
  base_target=mods/'ProjectYakuza';assert version(base_target)==base_version,'Install the matching combat release before the phone development add-on.'
  for name,digest in effects.items():assert sha(base_target/'42/media/lua/client/ProjectYakuza'/name)==digest,'Installed combat effect bytes do not match the shared build.'
  existing={p.relative_to(target).as_posix()for p in target.rglob('*')if p.is_file()and p.name!='.keep'}if target.exists()else set()
  retired={'42/media/textures/ProjectYakuzaPhoneDev/Yakuza6Gothic.png'}
  assert existing<=files.keys()|retired,'Existing phone dev folder contains unexpected files; automatic cleanup is not permitted.'
  backup=ROOT/'combat/backups'/('phone-dev-before-'+release);written=backed_up=0
  for name in existing&retired:
   destination=target/name;assert destination.resolve().is_relative_to(target)
   saved=backup/name;saved.parent.mkdir(parents=True,exist_ok=True)
   if saved.exists():assert saved.read_bytes()==destination.read_bytes()
   else:shutil.copy2(destination,saved)
   assert saved.read_bytes()==destination.read_bytes();destination.unlink();backed_up+=1
  for name,source in sorted(files.items()):
   destination=target/name;assert destination.resolve().is_relative_to(target)
   if destination.exists()and destination.read_bytes()==source.read_bytes():continue
   if destination.exists():
    saved=backup/name;assert saved.resolve().is_relative_to(backup.resolve());saved.parent.mkdir(parents=True,exist_ok=True)
    if saved.exists():assert saved.read_bytes()==destination.read_bytes()
    else:shutil.copy2(destination,saved)
    backed_up+=1
   destination.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,destination);written+=1
  (target/'common').mkdir(exist_ok=True)
  for name,source in files.items():assert(target/name).read_bytes()==source.read_bytes()
  assert {p.relative_to(target).as_posix()for p in target.rglob('*')if p.is_file()and p.name!='.keep'}==files.keys()
  report.update(installed=str(target),written=written,backedUp=backed_up,verified=True,sharedInstalledEffectsVerified=True)
 (dist/(MOD_ID+'-v'+release+'.json')).write_text(json.dumps(report,indent=2)+'\n')
 print(json.dumps(report))
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--version',required=True);parser.add_argument('--install',action='store_true');args=parser.parse_args();build(args.version,args.install)
