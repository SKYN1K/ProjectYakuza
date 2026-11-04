from pathlib import Path
import ast,struct,json,hashlib
root=Path(__file__).resolve().parents[2];archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/hact/h1500_oi_trample_ao.par');out=root/'extracted/ground-heat-081';rows=[]
node=next(n for n in ast.parse((root/'tools/combat-tests/validate_rush_qte_assets.py').read_text()).body if isinstance(n,ast.FunctionDef)and n.name=='sllz');namespace={'struct':struct};exec(compile(ast.Module(body=[node],type_ignores=[]),'supplied_archive_decoder','exec'),namespace)
def walk(data,prefix=Path()):
    folders,_,count,offset=struct.unpack_from('>IIII',data,16)
    for i in range(count):
        name=data[32+folders*64+i*64:32+folders*64+(i+1)*64].split(b'\0')[0].decode();flags,plain,size,start=struct.unpack_from('>IIII',data,offset+i*32);content=data[start:start+size]
        if flags:content=namespace['sllz'](content)
        assert len(content)==plain
        if content[:4]==b'PARC':walk(content,prefix/name)
        else:
            target=out/prefix/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(content);rows.append({'entry':(prefix/name).as_posix(),'sha256':hashlib.sha256(content).hexdigest(),'bytes':len(content)})
walk(archive.read_bytes());(out/'index.json').write_text(json.dumps({'archive':str(archive),'archiveSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'entries':rows},indent=2),encoding='utf-8')
print('EXTRACTED original h1500 ground attacker/victim source and scene data; no generated motion')
