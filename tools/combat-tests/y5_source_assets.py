from pathlib import Path
import ast,struct,hashlib

root=Path(__file__).resolve().parents[2]
node=next(n for n in ast.parse((root/'tools/combat-tests/validate_rush_qte_assets.py').read_text()).body if isinstance(n,ast.FunctionDef)and n.name=='sllz')
namespace={'struct':struct};exec(compile(ast.Module(body=[node],type_ignores=[]),'supplied_archive_decoder','exec'),namespace)

def entry(archive,name):
    archive=Path(archive)
    with archive.open('rb')as stream:
        header=stream.read(32);assert header[:4]==b'PARC';dirs,_,count,entries=struct.unpack_from('>4I',header,16);stream.seek(32+dirs*64)
        names=[stream.read(64).split(b'\0')[0].decode('cp932','replace')for _ in range(count)]
        stream.seek(entries+names.index(name)*32);flags,plain,size,offset=struct.unpack('>4I',stream.read(16));stream.seek(offset);packed=stream.read(size)
    data=namespace['sllz'](packed)if flags else packed;assert len(data)==plain
    return data,{'archive':str(archive),'name':name,'offset':offset,'size':size,'plain':plain,'flags':flags,'packedSha256':hashlib.sha256(packed).hexdigest(),'sha256':hashlib.sha256(data).hexdigest()}

def unpack(archive,out):
    archive=Path(archive);out=Path(out);records=[]
    def walk(data,prefix=Path()):
        assert data[:4]==b'PARC';dirs,_,count,entries=struct.unpack_from('>4I',data,16)
        for i in range(count):
            name=data[32+dirs*64+i*64:32+dirs*64+(i+1)*64].split(b'\0')[0].decode();assert '/'not in name and '\\'not in name and name not in ['.','..']
            flags,plain,size,offset=struct.unpack_from('>4I',data,entries+i*32);packed=data[offset:offset+size];content=namespace['sllz'](packed)if flags else packed;assert len(content)==plain
            if content[:4]==b'PARC':walk(content,prefix/name)
            else:
                dest=out/prefix/name;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(content);records.append({'entry':(prefix/name).as_posix(),'sha256':hashlib.sha256(content).hexdigest(),'bytes':len(content)})
    walk(archive.read_bytes())
    return {'archive':str(archive),'archiveSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'entries':records}
