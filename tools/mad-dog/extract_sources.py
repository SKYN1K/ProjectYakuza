"""Extract only the manifest's supplied Y0 motions and original Majima skeleton."""
import argparse
import hashlib
import json
from pathlib import Path
import sys

parser=argparse.ArgumentParser()
parser.add_argument('--game',type=Path,required=True,help='Local Yakuza 0 directory containing media/data')
parser.add_argument('--par-tool',type=Path,required=True,help='Yakuza-PAR-py checkout')
parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args()
root=Path(__file__).resolve().parents[2]
assert not args.output.resolve().is_relative_to(root), 'Keep extracted source files outside the repository'
manifest=json.loads((root/'styles/ProjectYakuzaMadDog/docs/motion-provenance.json').read_text())
sys.path.insert(0,str(args.par_tool))
from src import read_par,decompress_file
args.output.mkdir(parents=True,exist_ok=True)
archive=read_par(str(args.game/manifest['archive']))
for clip in manifest['clips']:
    file=archive.get_file(clip['source'])
    assert file is not None,clip['source']
    data=bytes(decompress_file(file))
    assert hashlib.sha256(data).hexdigest()==clip['source_sha256'], 'Source version differs: '+clip['source']
    (args.output/file.name).write_bytes(data)
model=read_par(str(args.game/manifest['source_model_archive']))
file=model.get_file(manifest['source_model'])
assert file is not None,manifest['source_model']
data=bytes(decompress_file(file))
assert hashlib.sha256(data).hexdigest()==manifest['source_model_sha256'], 'Original skeleton source differs'
(args.output/file.name).write_bytes(data)
print(f'PASS: extracted and verified {len(manifest["clips"])} original GMTs and the Majima GMD skeleton')
