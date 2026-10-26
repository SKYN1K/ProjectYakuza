"""Losslessly extract supplied Yakuza 0 UI/aura pixels. No media generation."""
from pathlib import Path
import argparse,hashlib,json,sys,tempfile
from PIL import Image

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--game',type=Path,required=True);p.add_argument('--par-tool',type=Path,required=True)
p.add_argument('--output',type=Path,required=True,help='ProjectYakuzaMadDog mod folder')
a=p.parse_args();sys.path.insert(0,str(a.par_tool))
from src import read_par,decompress_file

def sha(data):return hashlib.sha256(data).hexdigest()
records=[];base=a.output/'42/media/textures/ProjectYakuzaMadDog';base.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='mad-dog-original-assets-') as temporary:
 temp=Path(temporary)
 ui_path='media/data/2dpar/ui_e.par';ui=read_par(str(a.game/ui_path))
 life_blob=bytes(decompress_file(ui.get_file('pjcm_life.par')))
 (temp/'life.par').write_bytes(life_blob);life=read_par(str(temp/'life.par'))
 fx_path='media/data/effect/ptc_arc_w64/cmn.par';fx=read_par(str(a.game/fx_path))
 sources={
  'style':(bytes(decompress_file(life.get_file('2d_yk_btl_style.dds'))),ui_path+'!/surfboard/pjcm_life.par!/2d_yk_btl_style.dds'),
  'title':(bytes(decompress_file(ui.get_file('2d_yk_z_common_majima.dds'))),ui_path+'!/tex_common/common/2d_yk_z_common_majima.dds'),
  'rim':(bytes(decompress_file(fx.get_file('e_j_0073_aura_cA8L8.dds'))),fx_path+'!/e_j_0073_aura_cA8L8.dds'),
  'smoke':(bytes(decompress_file(fx.get_file('e_j_0073_aura_eA8L8.dds'))),fx_path+'!/e_j_0073_aura_eA8L8.dds'),
  'spark':(bytes(decompress_file(fx.get_file('e_j_0076_aura_gA8L8.dds'))),fx_path+'!/e_j_0076_aura_gA8L8.dds'),
 }
 for key,(blob,reference) in sources.items():
  path=temp/(key+'.dds');path.write_bytes(blob)
  source=Image.open(path).convert('RGBA')
  if key=='style':outputs=[('LegendIcon.png',(0,344,160,504))]
  elif key=='title':outputs=[('StyleTitle.png',(0,0,225,28))]
  elif key in ('rim','smoke'):outputs=[('Aura'+key.title()+'_0.png',(0,0,*source.size))]
  else:outputs=[(f'AuraSpark_{i}.png',((i%8)*32,(i//8)*32,(i%8+1)*32,(i//8+1)*32)) for i in range(64)]
  for filename,box in outputs:
   image=source.crop(box);dest=base/filename;image.save(dest)
   assert Image.open(dest).convert('RGBA').tobytes()==image.tobytes()
   records.append({'file':'42/media/textures/ProjectYakuzaMadDog/'+filename,'source':reference,
    'source_sha256':sha(blob),'source_size':list(source.size),'crop':list(box),'size':list(image.size),
    'rgba_sha256':sha(image.tobytes()),'output_sha256':sha(dest.read_bytes())})
 report={'source_game':'Supplied local Yakuza 0 PC installation','operations':'DDS decode and exact native-pixel crop only; no resampling, repainting, AI or generated frames.',
 'aura_rendering':'Original Y0 common aura rim/smoke and all 64 native sprite-sheet frames, adapted to PZ torso sprites with style-local white/violet render tint. Native Yakuza MEP shaders are not executed.',
 'assets':records}
 (a.output/'docs/visual-provenance.json').write_text(json.dumps(report,indent=2)+'\n')
 print('PASS:',len(records),'PNG exports match decoded original DDS crop pixels exactly')
