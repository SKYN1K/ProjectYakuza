from pathlib import Path
import argparse,hashlib,importlib.util,json,re,shutil

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('game_package',ROOT/'tools/Build-GamePackage.py')
package=importlib.util.module_from_spec(spec);spec.loader.exec_module(package)

def contained(root,path):
    root=Path(root).resolve();path=Path(path)
    assert path.resolve().is_relative_to(root)and path.resolve()!=root,str(path)
    for part in [path,*path.parents]:
        if part==root:break
        assert not part.is_symlink()and not(getattr(part,'is_junction',lambda:False)()),str(part)
    return path

def files_at(folder):
    if not folder.exists():return {}
    result={}
    for path in folder.rglob('*'):
        contained(folder,path)
        if path.is_file():result[path.relative_to(folder).as_posix()]=path
    return result

def matches(folder,files):
    actual=files_at(folder)
    return actual.keys()==files.keys()and all(actual[name].read_bytes()==source.read_bytes()for name,source in files.items())

def install(mod,version,zomboid,backup,stage_source):
    assert re.fullmatch(r'\d+\.\d+\.\d+',version)
    mod=Path(mod).resolve();zomboid=Path(zomboid).resolve();backup=Path(backup).resolve();stage_source=Path(stage_source).resolve()
    assert not backup.is_relative_to(zomboid),'Backups must be outside the game cache and Workshop search path'
    files=package.runtime_files(mod)
    assert 'version='+version in(mod/'42/mod.info').read_text()
    assert matches(stage_source/'Contents/mods/ProjectYakuza',files),'Build the matching Workshop package first'
    assert set(files_at(stage_source))=={'Contents/mods/ProjectYakuza/'+name for name in files}|{'preview.png','workshop.txt'}
    target=contained(zomboid,zomboid/'mods/ProjectYakuza');workshop=contained(zomboid,zomboid/'Workshop');desired=contained(workshop,workshop/('ProjectYakuza-v'+version))
    existing=files_at(target);changed=[name for name in existing if name not in files or existing[name].read_bytes()!=files[name].read_bytes()]
    stages=[];metadata=[]
    if desired.exists():assert (desired/'Contents/mods/ProjectYakuza').exists(),'The destination is already used by a different Workshop stage'
    if workshop.exists():
        for stage in sorted(workshop.iterdir()):
            if not stage.is_dir():continue
            contained(workshop,stage)
            payload=stage/'Contents/mods/ProjectYakuza'
            if not payload.exists():continue
            files_at(stage)
            assert {p.name for p in(stage/'Contents/mods').iterdir()}=={'ProjectYakuza'},'Mixed-mod Workshop stage needs manual separation: '+str(stage)
            text=(payload/'42/mod.info').read_text();assert re.search(r'^id=ProjectYakuza\s*$',text,re.M),str(stage)
            info=stage/'workshop.txt'
            if info.is_file():metadata.append((stage,info.read_bytes()))
            if stage!=desired or not matches(payload,files):stages.append(stage)
    ids={match[1]for _,data in metadata if(match:=re.search(rb'(?m)^id=(\d+)\s*$',data))and int(match[1])>0}
    assert len(ids)<=1,'Conflicting Workshop item IDs; originals were left untouched'
    chosen=next((data for _,data in metadata if re.search(rb'(?m)^id='+next(iter(ids))+rb'\s*$',data)),None)if ids else None
    if chosen is None:chosen=next((data for stage,data in metadata if stage==desired),(stage_source/'workshop.txt').read_bytes())
    for name in changed:
        saved=contained(backup,backup/'replaced'/name)
        if saved.exists():assert saved.read_bytes()==existing[name].read_bytes(),'Backup already contains different bytes: '+name
    destinations=[]
    for stage in stages:
        saved=contained(backup,backup/'workshop'/stage.name);assert not saved.exists(),'Workshop archive already exists: '+str(saved)
        destinations.append((stage,saved))
    for name in changed:
        saved=contained(backup,backup/'replaced'/name);saved.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(existing[name],saved)
        assert saved.read_bytes()==existing[name].read_bytes()
    archived=[]
    for stage,saved in destinations:
        before={name:hashlib.sha256(path.read_bytes()).hexdigest()for name,path in files_at(stage).items()}
        saved.parent.mkdir(parents=True,exist_ok=True);stage.rename(saved)
        assert before=={name:hashlib.sha256(path.read_bytes()).hexdigest()for name,path in files_at(saved).items()}
        archived.append(str(saved))
    written=0
    for name,source in files.items():
        output=contained(target,target/name)
        if output.exists()and output.read_bytes()==source.read_bytes():continue
        output.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,output);written+=1
    for name in existing.keys()-files.keys():contained(target,target/name).unlink()
    (target/'common').mkdir(parents=True,exist_ok=True)
    desired.mkdir(parents=True,exist_ok=True)
    for name,source in files.items():
        output=contained(desired,desired/'Contents/mods/ProjectYakuza'/name);output.parent.mkdir(parents=True,exist_ok=True)
        if not output.exists()or output.read_bytes()!=source.read_bytes():shutil.copyfile(source,output)
    (desired/'Contents/mods/ProjectYakuza/common').mkdir(exist_ok=True)
    shutil.copyfile(stage_source/'preview.png',desired/'preview.png');(desired/'workshop.txt').write_bytes(chosen)
    assert matches(target,files)and matches(desired/'Contents/mods/ProjectYakuza',files)
    loadable=[]
    for stage in workshop.iterdir():
        payload=stage/'Contents/mods/ProjectYakuza'
        if payload.exists():assert stage==desired and matches(payload,files);loadable.append(str(payload))
    return {'version':version,'runtimeFiles':len(files),'written':written,'backedUp':len(changed),'archivedWorkshopStages':archived,'installed':str(target),'workshop':str(desired),'loadableWorkshopCopies':loadable,'verified':True,'workshopItemIdPreserved':bool(ids)}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--version',required=True);parser.add_argument('--zomboid-root',type=Path,default=Path.home()/'Zomboid');args=parser.parse_args()
    report=install(ROOT/'combat/ProjectYakuza',args.version,args.zomboid_root,ROOT/'combat/backups'/('before-'+args.version),ROOT/'dist/Workshop'/('ProjectYakuza-v'+args.version))
    (ROOT/'tools'/('install-combat-'+args.version+'.json')).write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))

if __name__=='__main__':main()
