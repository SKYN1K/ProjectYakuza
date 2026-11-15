from pathlib import Path
import json,uuid,hashlib
from y5_source_assets import unpack
from read_heat_scene import read_scene
from extract_majima_bat_emote import resource

root=Path(__file__).resolve().parents[2];archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 5/main/data/hact/H11240_tomoenage.par');folder=root/'extracted/grab-y5-0116'
def extract():
 index=unpack(archive,folder);(folder/'source-index.json').write_text(json.dumps(index,indent=2)+'\n');scene=read_scene(folder/'cmn.par/cmn.bin');characters=[n for n in scene['nodes']if n['category']==5];assert scene['version']==10 and len(characters)==2 and scene['end']==200
 selection=[]
 for character in characters:
  motion=next(n for n in scene['nodes']if n['category']==6 and n['parent']==character['offset']);stem=resource(folder/'000.par/res.bin',uuid.UUID(motion['guid']).bytes_le.hex());path=folder/'000.par'/(stem+'.gmt');assert path.is_file();selection.append({'character':character['guid'],'motion':motion['guid'],'resource':stem,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
 assert[n['element']['start']for n in scene['nodes']if'damage'in n and n['role']=='victim']==[78]
 (folder/'selection.json').write_text(json.dumps(selection,indent=2)+'\n');print('PASS original Yakuza 5 front-grab sacrifice throw bindings and frame-78 CMN contact')
if __name__=='__main__':extract()
