from pathlib import Path
import ast,struct,json,hashlib,io,sys
from PIL import Image
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/ui.par');entry='/e/texture/qloc/keyboard/pc_all_84.dds';validate='--validate'in sys.argv
with archive.open('rb')as stream:
    header=stream.read(32);endian='>'if header[5]else'<';folders,folderOffset,files,fileOffset=struct.unpack_from(endian+'4I',header,16);stream.seek(32);names=[stream.read(64).split(b'\0')[0].decode('shift_jis',errors='replace')for _ in range(folders+files)];stream.seek(folderOffset);directories=[struct.unpack(endian+'8I',stream.read(32))for _ in range(folders)];stream.seek(fileOffset);entries=[struct.unpack(endian+'6IQ',stream.read(32))for _ in range(files)];found=[]
    def visit(index,prefix=''):
        name=names[index];prefix+=('/'+name if name not in['.','pxdArchiver']else'');children,start,count,first,*_=directories[index]
        for j in range(first,first+count):
            if prefix+'/'+names[folders+j]==entry:found.append(entries[j])
        for j in range(start,start+children):visit(j,prefix)
    visit(0);assert len(found)==1;meta=found[0];compressed,size,stored,offset,attributes,extended,stamp=meta;stream.seek(offset+(extended<<32));data=stream.read(stored if compressed else size)
function=next(n for n in ast.parse((root/'tools/combat-tests/validate_rush_qte_assets.py').read_text()).body if isinstance(n,ast.FunctionDef)and n.name=='sllz');namespace={'struct':struct};exec(compile(ast.Module(body=[function],type_ignores=[]),'source_texture_decoder','exec'),namespace)
dds=namespace['sllz'](data)if compressed else data;assert len(dds)==size;source=Image.open(io.BytesIO(dds)).convert('RGBA');assert source.size==(2048,2048)
sha=lambda data:hashlib.sha256(data).hexdigest();records=[]
for name,region in [('InputKeycap',(0,0,84,84)),('InputMouseLeft',(340,1020,84,84)),('InputMouseMiddle',(425,1020,84,84)),('InputMouseRight',(510,1020,84,84))]:
    x,y,w,h=region;image=source.crop((x,y,x+w,y+h));output=mod/'42/media/textures/ProjectYakuza'/(name+'.png')
    if validate:assert output.exists()and Image.open(output).convert('RGBA').tobytes()==image.tobytes(),'source icon pixels differ: '+name
    else:image.save(output)
    records.append({'name':name,'region':region,'output':output.relative_to(mod).as_posix(),'sha256':sha(output.read_bytes()),'rgbaSha256':sha(image.tobytes()),'size':image.size})
report={'authorization':'User approved original Yakuza 6 PC input atlas extraction/decoding on 2026-11-03.','archive':str(archive),'entry':entry,'archiveMeta':meta,'ddsSha256':sha(dds),'sourceSize':source.size,'operation':'Four original 84x84 regions copied pixel-for-pixel from the supplied PC input atlas. No repainting, recoloring, AI, resizing or upscaling. The keyboard renderer samples the original key border and blank interior patch, omits its baked legend and draws the current binding name at runtime. Mouse icons retain the original left/right/wheel highlights.','textures':records}
path=mod/'docs/input-prompt-assets.json'
if validate:assert json.loads(path.read_text())==json.loads(json.dumps(report)),'input icon provenance differs'
else:path.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('PASS four original Y6 input icon crops and RGBA pixels; no generated artwork or resizing'if validate else'EXTRACTED four native-size Y6 input icons')
