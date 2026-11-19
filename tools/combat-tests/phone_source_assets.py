from pathlib import Path
import ast,hashlib,struct
ROOT=Path(__file__).resolve().parents[2]
node=next(n for n in ast.parse((ROOT/'tools/combat-tests/validate_rush_qte_assets.py').read_text()).body if isinstance(n,ast.FunctionDef)and n.name=='sllz')
for n in ast.walk(node):
 if isinstance(n,ast.Constant)and n.value==16000000:n.value=64000000
ns={'struct':struct};exec(compile(ast.fix_missing_locations(ast.Module(body=[node],type_ignores=[])),'supplied_phone_archive_decoder','exec'),ns)
def entry(archive,path):
 archive=Path(archive)
 with archive.open('rb')as f:
  header=f.read(32);assert header[:4]==b'PARC';nd,di,nf,fi=struct.unpack_from('>4I',header,16)
  names=[f.read(64).split(b'\0')[0].decode('cp932','replace')for _ in range(nd+nf)];f.seek(di);dirs=[struct.unpack('>8I',f.read(32))for _ in range(nd)];f.seek(fi);files=[struct.unpack('>8I',f.read(32))for _ in range(nf)]
  matches=[]
  def walk(i,prefix=''):
   folder=prefix+'/'+names[i]if i else '';count,first,total,start,*_=dirs[i]
   for j in range(start,start+total):
    if(folder+'/'+names[nd+j]).strip('/')==path.strip('/'):matches.append(j)
   for j in range(first,first+count):walk(j,folder)
  walk(0);assert len(matches)==1,(path,matches);index=matches[0];flags,plain,size,offset,*_=files[index];f.seek(offset);packed=f.read(size)
 raw=ns['sllz'](packed)if flags else packed;assert len(raw)==plain
 return raw,{'archive':archive.name,'entry':path,'offset':offset,'packedBytes':size,'bytes':plain,'packedSha256':hashlib.sha256(packed).hexdigest(),'sha256':hashlib.sha256(raw).hexdigest()}
