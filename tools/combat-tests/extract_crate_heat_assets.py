from pathlib import Path
import ast,struct,json,hashlib
root=Path(__file__).resolve().parents[2];archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 5/main/data/hact/H3270_kaburikasa.par');out=root/'extracted/crate-heat-086';rows=[]
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
print('EXTRACTED original Y5 H3270 attacker/victim source and scene data; no generated motion')

p=Path('F:/SteamLibrary/steamapps/common/Yakuza 5/main/data/chara_common/bone.par');d=p.read_bytes();folders,_,count,offset=struct.unpack_from('>IIII',d,16)
node=next(n for n in ast.parse((root/'tools/combat-tests/validate_rush_qte_assets.py').read_text()).body if isinstance(n,ast.FunctionDef)and n.name=='sllz');ns={'struct':struct};exec(compile(ast.Module(body=[node],type_ignores=[]),'archive_decoder','exec'),ns)
for i in range(count):
 name=d[32+folders*64+i*64:32+folders*64+(i+1)*64].split(b'\0')[0].decode()
 if name in ['c_cm_bone.gmd','c_am_bone.gmd','c_man_bone.gmd']:
  flags,plain,size,start=struct.unpack_from('>IIII',d,offset+i*32);b=d[start:start+size];b=ns['sllz'](b)if flags else b;out=root/'extracted/crate-heat-086'/name;out.write_bytes(b);print('Extracted original skeleton',name,len(b))
