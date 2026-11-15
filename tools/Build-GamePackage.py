from pathlib import Path
import argparse,hashlib,json,re,shutil,zipfile,struct,zlib

ROOT=Path(__file__).resolve().parents[1]
EXTENSIONS={'.lua','.txt','.xml','.x','.png','.wav','.ogg','.mp3','.info'}
FORBIDDEN={'.git','.codex','.agents','docs','templates','tools','backups','extracted','previews','__pycache__'}
PRIVATE_PATTERNS={
    'personal or development path':rb'(?i)[a-z]:[\\/](?:users|steam|steamlibrary|blender|projects|program files)[\\/]',
    'access token':rb'(?i)(?:ghp_|github_pat_|sk-proj-)[a-z0-9_-]{15,}',
    'private key':rb'-----BEGIN (?:RSA |OPENSSH )?PRIVATE KEY-----',
    'development marker':rb'(?i)(?:agents\.md|\.codex|codex-clipboard|chatgpt)',
    'email address':rb'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
}

def metadata(name,data):
    suffix=Path(name).suffix.lower()
    if suffix=='.ogg':
        offset=data.find(b'\x03vorbis',0,1048576);skip=7
        if offset<0:offset=data.find(b'OpusTags',0,1048576);skip=8
        assert offset>=0,(name,'unsupported Ogg metadata')
        pos=offset+skip;size=struct.unpack_from('<I',data,pos)[0];pos+=4;chunks=[data[pos:pos+size]];pos+=size;count=struct.unpack_from('<I',data,pos)[0];pos+=4;assert count<10000
        for _ in range(count):
            size=struct.unpack_from('<I',data,pos)[0];pos+=4;assert pos+size<=len(data);chunks.append(data[pos:pos+size]);pos+=size
        return b'\n'.join(chunks)
    if suffix=='.wav':
        assert data[:4]==b'RIFF'and data[8:12]==b'WAVE',name
        pos=12;chunks=[]
        while pos+8<=len(data):
            kind=data[pos:pos+4];size=struct.unpack_from('<I',data,pos+4)[0];pos+=8;assert pos+size<=len(data),name
            if kind!=b'data':chunks.append(data[pos:pos+size])
            pos+=size+(size%2)
        return b'\n'.join(chunks)
    if suffix=='.png':
        assert data[:8]==b'\x89PNG\r\n\x1a\n',name
        pos=8;chunks=[]
        while pos+12<=len(data):
            size=struct.unpack_from('>I',data,pos)[0];kind=data[pos+4:pos+8];chunk=data[pos+8:pos+8+size];pos+=12+size
            if kind==b'tEXt':chunks.append(chunk)
            elif kind==b'zTXt':keyword,packed=chunk.split(b'\0',1);assert packed[0]==0;chunks.extend([keyword,zlib.decompress(packed[1:])])
            elif kind==b'iTXt':
                keyword,rest=chunk.split(b'\0',1);compressed,method=rest[:2];language,translated,text=rest[2:].split(b'\0',2);assert method==0;chunks.extend([keyword,language,translated,zlib.decompress(text)if compressed else text])
        return b'\n'.join(chunks)
    if suffix=='.mp3':
        if data[:3]!=b'ID3':return b''
        size=0
        for value in data[6:10]:size=(size<<7)|(value&127)
        return data[:size+10]
    return data

def scan(name,data):
    path=Path(name)
    assert not path.is_absolute()and'..'not in path.parts,name
    assert not any(p.lower()in FORBIDDEN for p in path.parts),name
    assert path.name.lower()not in {'agents.md','skill.md','.env','readme.md'},name
    text=metadata(name,data)
    for label,pattern in PRIVATE_PATTERNS.items():assert not re.search(pattern,text if label=='email address'else data),(name,label)

def runtime_files(mod):
    mod=Path(mod).resolve();result={}
    for folder in ['42','common']:
        for path in(mod/folder).rglob('*'):
            if not path.is_file():continue
            relative=path.relative_to(mod).as_posix();parts=Path(relative).parts
            if path.name=='.keep':continue
            assert path.resolve().is_relative_to(mod),relative
            assert relative=='42/mod.info'or len(parts)>2 and parts[1]=='media',relative
            assert path.suffix.lower()in EXTENSIONS,relative
            data=path.read_bytes();scan(relative,data);result[relative]=path
    assert '42/mod.info'in result and result
    return result

def write_zip(path,mod_id,files):
    temporary=path.with_suffix('.building.zip')
    with zipfile.ZipFile(temporary,'w',zipfile.ZIP_DEFLATED,compresslevel=9)as archive:
        archive.writestr(mod_id+'/common/','')
        for name,source in sorted(files.items()):archive.write(source,mod_id+'/'+name)
    temporary.replace(path)
    with zipfile.ZipFile(path)as archive:
        entries={n.removeprefix(mod_id+'/'):n for n in archive.namelist()if not n.endswith('/')}
        assert entries.keys()==files.keys()
        for name,source in files.items():
            data=archive.read(entries[name]);assert data==source.read_bytes();scan(name,data)

def workshop(mod_id,version,files,dist):
    folder=dist/'Workshop'/(mod_id+'-v'+version);payload=folder/'Contents/mods'/mod_id
    assert folder.resolve().is_relative_to(dist.resolve())
    allowed={('Contents/mods/'+mod_id+'/'+n)for n in files}|{'preview.png','workshop.txt'}
    if folder.exists():assert {p.relative_to(folder).as_posix()for p in folder.rglob('*')if p.is_file()}<=allowed
    for name,source in files.items():
        target=payload/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,target)
    (payload/'common').mkdir(exist_ok=True)
    preview=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/Workshop/ModTemplate/preview.png');assert preview.is_file(),'Supplied game preview is missing';scan('preview.png',preview.read_bytes());shutil.copyfile(preview,folder/'preview.png')
    title='Project Yakuza'if mod_id=='ProjectYakuza'else'Project Yakuza Emotes'
    metadata='version=1\ntitle='+title+'\ndescription='+title+' for Project Zomboid Build 42. Version '+version+'.\ntags=\nvisibility=private\n'
    (folder/'workshop.txt').write_text(metadata,encoding='utf-8')
    assert {p.relative_to(payload).as_posix()for p in payload.rglob('*')if p.is_file()}==files.keys()
    for name,source in files.items():assert(payload/name).read_bytes()==source.read_bytes()
    archive=dist/(mod_id+'-Workshop-v'+version+'.zip')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9)as output:
        output.writestr(folder.name+'/Contents/mods/'+mod_id+'/common/','')
        for path in sorted(folder.rglob('*')):
            if path.is_file():output.write(path,folder.name+'/'+path.relative_to(folder).as_posix())
    return folder,archive

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--project',choices=['combat','emotes'],default='combat');parser.add_argument('--version',required=True);parser.add_argument('--workshop',action='store_true');args=parser.parse_args();assert re.fullmatch(r'\d+\.\d+\.\d+',args.version)
    mod_id='ProjectYakuza'if args.project=='combat'else'ProjectYakuzaEmotes';mod=ROOT/args.project/mod_id;files=runtime_files(mod);assert('version='+args.version)in(mod/'42/mod.info').read_text();dist=ROOT/'dist';dist.mkdir(exist_ok=True);archive=dist/(mod_id+'-B42-v'+args.version+'.zip');write_zip(archive,mod_id,files)
    report={'project':mod_id,'version':args.version,'files':len(files),'zip':str(archive),'size':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'runtimeOnly':True,'privacyScanPassed':True,'excluded':['development notes','provenance reports','templates','tools','backups','AGENTS.md','local paths','credentials']}
    if args.workshop:
        folder,upload=workshop(mod_id,args.version,files,dist);report.update(workshopFolder=str(folder),workshopZip=str(upload),preview='Unchanged supplied PZ template preview',visibility='private')
    (ROOT/'tools'/('package-'+args.project+'-'+args.version+'.json')).write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))

if __name__=='__main__':main()
