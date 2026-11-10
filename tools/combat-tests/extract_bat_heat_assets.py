from pathlib import Path
import ast,struct,json,hashlib

root=Path(__file__).resolve().parents[2]
archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/hact/h23710_buki_d.par')
out=root/'extracted/bat-heat-096/h23710_buki_d';rows=[]
node=next(n for n in ast.parse((root/'tools/combat-tests/validate_rush_qte_assets.py').read_text()).body if isinstance(n,ast.FunctionDef)and n.name=='sllz')
namespace={'struct':struct};exec(compile(ast.Module(body=[node],type_ignores=[]),'supplied_archive_decoder','exec'),namespace)

def walk(data,prefix=Path()):
    assert data[:4]==b'PARC'
    folders,_,count,offset=struct.unpack_from('>IIII',data,16)
    for i in range(count):
        name=data[32+folders*64+i*64:32+folders*64+(i+1)*64].split(b'\0')[0].decode()
        assert '/'not in name and '\\'not in name and name not in ['.','..']
        flags,plain,size,start=struct.unpack_from('>IIII',data,offset+i*32);assert start+size<=len(data);content=data[start:start+size]
        if flags:content=namespace['sllz'](content)
        assert len(content)==plain
        if content[:4]==b'PARC':walk(content,prefix/name)
        else:
            target=out/prefix/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(content)
            rows.append({'entry':(prefix/name).as_posix(),'sha256':hashlib.sha256(content).hexdigest(),'bytes':len(content)})

walk(archive.read_bytes())
(out/'index.json').write_text(json.dumps({'archive':str(archive),'archiveSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'entries':rows},indent=2)+'\n',encoding='utf-8')
print('PASS supplied Yakuza 6 h23710 archive extracted:',len(rows),'original entries')
models=[];asset=archive.parent.parent/'asset.par'
with asset.open('rb')as stream:
    header=stream.read(32);dirs,_,count,entries=struct.unpack_from('>4I',header,16);stream.seek(32+dirs*64)
    names=[stream.read(64).split(b'\0')[0].decode('cp932','replace')for _ in range(count)]
    for name in ['bs_d000_type_d_bou.gmd','bs_d001_type_d_bat.gmd']:
        stream.seek(entries+names.index(name)*32);flags,plain,size,offset=struct.unpack('>4I',stream.read(16));stream.seek(offset);data=stream.read(size);packedSha=hashlib.sha256(data).hexdigest()
        if flags:data=namespace['sllz'](data)
        assert len(data)==plain
        path=out.parent/name;path.write_bytes(data)
        models.append({'archive':str(asset),'entry':name,'offset':offset,'size':size,'packedSha256':packedSha,'sha256':hashlib.sha256(data).hexdigest()})
(out.parent/'weapon-models.json').write_text(json.dumps(models,indent=2)+'\n',encoding='utf-8')
print('PASS 2 original weapon mesh references extracted for numeric axis validation; no model conversion')
