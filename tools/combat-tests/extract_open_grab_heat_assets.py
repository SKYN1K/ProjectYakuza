from pathlib import Path
import json,uuid,hashlib
from y5_source_assets import unpack
from read_heat_scene import read_scene
from extract_majima_bat_emote import resource

root=Path(__file__).resolve().parents[2];archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/hact/h23600_seoi_oi.par');folder=root/'extracted/open-grab-heat-0108/shoulder-throw';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()

def extract():
    index=unpack(archive,folder);(folder/'source-index.json').write_text(json.dumps(index,indent=2)+'\n',encoding='utf-8');scene=read_scene(folder/'cmn.par/cmn.bin');characters=[n for n in scene['nodes']if n['category']==5];assert len(characters)==2 and scene['end']==224;selection=[]
    for character in characters:
        motion=next(n for n in scene['nodes']if n['category']==6 and n['parent']==character['offset']);name=resource(folder/'000.par/res.bin',uuid.UUID(motion['guid']).bytes_le.hex());path=folder/'000.par'/(name+'.gmt');selection.append({'character':character,'motion':motion,'resource':name,'path':str(path),'sha256':sha(path)})
    assert [s['resource']for s in selection]==['h23600_000_2','h23600_000_4'];damage=[n for n in scene['nodes']if 'damage'in n];assert len(damage)==2 and all(n['parent']==characters[1]['offset']for n in damage)and [n['element']['start']for n in damage]==[117,167]
    report={'archive':str(archive),'archiveSha256':sha(archive),'scene':str(folder/'cmn.par/cmn.bin'),'sceneSha256':scene['sha256'],'resources':str(folder/'000.par/res.bin'),'resourcesSha256':sha(folder/'000.par/res.bin'),'selection':selection,'frames':225,'fps':30,'duration':224/30,'contactFrames':[117,167],'basis':'Original Yakuza 6 h23600 shoulder throw and follow-up, one player and one held victim. No wall, other opponents or props are required. All original samples and CMN victim contact timing are retained; existing mod damage balance is used instead of the source force-death flag.'}
    (folder/'selection.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print('PASS original one-on-one Y6 shoulder throw and follow-up bindings and original frame-117/167 contacts')

if __name__=='__main__':extract()
