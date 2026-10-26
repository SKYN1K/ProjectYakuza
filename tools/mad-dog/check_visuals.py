"""Independently compare every shipped PNG with its original archived DDS crop."""
from pathlib import Path
from io import BytesIO
import argparse, hashlib, json, sys, tempfile
from PIL import Image

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--game',type=Path,required=True)
p.add_argument('--par-tool',type=Path,required=True)
p.add_argument('--addon',type=Path,default=Path('styles/ProjectYakuzaMadDog'))
a=p.parse_args();sys.path.insert(0,str(a.par_tool))
from src import read_par,decompress_file

def sha(data):return hashlib.sha256(data).hexdigest()
records=json.loads((a.addon/'docs/visual-provenance.json').read_text())['assets']
cache={};pixels=0
with tempfile.TemporaryDirectory(prefix='mad-dog-pixel-check-') as temporary:
    for record in records:
        source=record['source']
        if source not in cache:
            parts=source.split('!/')
            archive=read_par(str(a.game/parts[0]))
            for index,member in enumerate(parts[1:]):
                blob=bytes(decompress_file(archive.get_file(Path(member).name)))
                if index<len(parts)-2:
                    path=Path(temporary)/(sha(blob)+'.par');path.write_bytes(blob)
                    archive=read_par(str(path))
            assert sha(blob)==record['source_sha256'],source
            cache[source]=Image.open(BytesIO(blob)).convert('RGBA')
        original=cache[source]
        assert list(original.size)==record['source_size'],source
        expected=original.crop(record['crop'])
        path=a.addon/record['file'];actual=Image.open(path).convert('RGBA')
        assert actual.size==expected.size==tuple(record['size']),path
        assert actual.tobytes()==expected.tobytes(),path
        assert sha(actual.tobytes())==record['rgba_sha256'],path
        assert sha(path.read_bytes())==record['output_sha256'],path
        assert actual.getchannel('A').getextrema()[1]>0,path
        pixels+=actual.width*actual.height
assert len(records)==68 and len(cache)==5
print(f'PASS: {len(records)} original DDS crops, {len(cache)} original sources, {pixels:,} exact RGBA pixels; alpha and source/output hashes verified')
