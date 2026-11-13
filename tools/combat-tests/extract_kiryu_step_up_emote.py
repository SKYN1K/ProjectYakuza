from pathlib import Path
import hashlib,json,struct
from y5_source_assets import unpack
from extract_majima_bat_emote import read_scene,resource

root=Path(__file__).resolve().parents[2];archive=Path('F:/SteamLibrary/steamapps/common/Yakuza Kiwami/media/data/auth_w64_e/main16_s02.par');folder=root/'extracted/kiryu-step-up/main16_s02';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()

def subtitles(path,rows):
    data=Path(path).read_bytes();node=next(r for r in rows if r['name']=='\u5b57\u5e55');payload=data[node['offset']+80:node['offset']+80+node['size']];count=struct.unpack_from('>I',payload,36)[0];assert count==25 and len(payload)==56+count*272*2
    result=[]
    for index in range(count,2*count):
        offset=56+index*272;first,last=struct.unpack_from('>2f',payload,offset);text=payload[offset+16:offset+272].split(b'\0')[0].decode('utf-8');result.append({'firstFrame':first,'lastFrame':last,'text':text})
    return result

def extract():
    index=unpack(archive,folder);(folder/'source-index.json').write_text(json.dumps(index,indent=2)+'\n',encoding='utf-8');scene=folder/'cmn.par/cmn.bin';rows=read_scene(scene);actor=next(r for r in rows if r['type']==5 and r['name']=='c_at_kiryu_U1_S185');motion=next(r for r in rows if r['parent']==actor['offset']and r['type']==6);resources=folder/'012.par/res.bin';name=resource(resources,motion['guid']);source=folder/'012.par'/(name+'.gmt');dialogue=subtitles(scene,rows);challenge=next(r for r in dialogue if r['text']=='If you want to die, come at me!');assert name=='main16_012_1'and challenge['firstFrame']==2705 and challenge['lastFrame']==2820
    timeline=[]
    for i in range(13):
        table=folder/(f'{i:03}.par')/'res.bin';clip=folder/(f'{i:03}.par')/(resource(table,motion['guid'])+'.gmt');timeline.append({'cut':i,'path':str(clip),'sha256':sha(clip)})
    result={'archive':str(archive),'archiveSha256':sha(archive),'scene':str(scene),'sceneSha256':sha(scene),'resources':str(resources),'resourcesSha256':sha(resources),'actor':actor,'motion':motion,'resource':name,'source':str(source),'sourceSha256':sha(source),'firstFrame':0,'lastFrame':219,'fps':30,'sceneCutStartFrame':2609,'timeline':timeline,'dialogue':[r for r in dialogue if r['firstFrame']>=2640],'basis':'Original Kiwami final-chapter crowd challenge with Haruka, main16_s02 cut 012. The original CMN subtitles identify both challenge lines and the preceding Haruka exchange. Full original shot, including its lead-in and ending, at source speed.'}
    (folder.parent/'selection.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print('PASS supplied final-chapter Kiryu GUID/resource and challenge subtitle binding; source 0..219')

if __name__=='__main__':extract()
