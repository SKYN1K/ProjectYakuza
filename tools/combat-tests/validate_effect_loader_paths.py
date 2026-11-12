
from pathlib import Path
import argparse,zipfile,struct
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--game-jar',type=Path,default=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar'))
args=parser.parse_args()
with zipfile.ZipFile(args.game_jar) as z:data=z.read('zombie/iso/sprite/IsoAnim.class')
count=struct.unpack_from('>H',data,8)[0];i=1;pos=10;strings=set()
while i<count:
    tag=data[pos];pos+=1
    if tag==1:
        length=struct.unpack_from('>H',data,pos)[0];pos+=2
        strings.add(data[pos:pos+length].decode('utf-8',errors='replace'));pos+=length
    elif tag in (3,4,9,10,11,12,17,18):pos+=4
    elif tag in (5,6):pos+=8;i+=1
    elif tag in (7,8,16,19,20):pos+=2
    elif tag==15:pos+=3
    else:raise AssertionError(('unknown constant',tag))
    i+=1
assert 'LoadFramesNoDirPageDirect' in strings
assert '_\x01_' in strings and '\x01\x01\x01.png' in strings,'Native filename recipes changed; inspect loader before updating checker'
mod=Path(__file__).resolve().parents[2]/'combat/ProjectYakuza';textures=mod/'42/media/textures/ProjectYakuza'
sequences={'HeatWisp':{'a':32,'b':32,'c':32},'ExtremeHeat':{'flame':64,'smoke':64}}
total=0
for prefix,kinds in sequences.items():
    for kind,frames in kinds.items():
        for frame in range(frames):
            path=textures/f'{prefix}_{kind}_{frame}.png'
            assert path.is_file(),f'Native loader cannot resolve {path.name}'
            assert not (textures/f'{prefix}{kind}_{frame}.png').exists(),'Incorrect legacy filename remains'
            total+=1
print(f'PASS native IsoAnim filename recipes and all {total} aura/burst frame paths; missing-underscore regression prevented')


import hashlib,json
from PIL import Image
baseline=mod.parents[1]/'dist/ProjectYakuza-B42-v0.100.0.zip'
with zipfile.ZipFile(baseline)as archive:
    import io
    count=0
    for path in (mod/'42/media/textures').rglob('*.png'):
        with Image.open(path)as actual,Image.open(io.BytesIO(archive.read('ProjectYakuza/'+path.relative_to(mod).as_posix())))as original:
            assert actual.size==original.size and actual.mode==original.mode and actual.tobytes()==original.tobytes(),path
        count+=1
print('PASS',count,'retained textures preserve every baseline pixel, alpha and dimension; no obsolete taunt copies loaded')
