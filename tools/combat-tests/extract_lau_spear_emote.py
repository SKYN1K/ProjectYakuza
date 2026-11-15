from pathlib import Path
import hashlib,json,re
from y5_source_assets import unpack
from extract_majima_bat_emote import read_scene,resource

root=Path(__file__).resolve().parents[2];folder=root/'extracted/lau-spear-emote/main12_s04';archive=Path('F:/SteamLibrary/steamapps/common/Yakuza Kiwami/media/data/auth_w64_e/main12_s04.par');native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media');sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()

def script_blocks(path,kind):
    text=Path(path).read_text(encoding='utf-8');result={}
    for match in re.finditer(r'\b'+kind+r'\s+(\w+)\s*\{',text):
        depth=1;end=match.end()
        while depth:depth+=(text[end]=='{')-(text[end]=='}');end+=1
        result[match[1]]=text[match.end():end-1]
    return result

def mesh_vertices(path):
    text=Path(path).read_text();match=re.search(r'\bMesh\s+\w*\s*\{\s*(\d+);',text);assert match
    values=re.findall(r'([-+\d.eE]+);([-+\d.eE]+);([-+\d.eE]+);',text[match.end():]);return [tuple(map(float,p))for p in values[:int(match[1])]]

def native_profiles():
    itemPath=native/'scripts/generated/items/weapon.txt';modelPath=native/'scripts/generated/models_weapons.txt';items=script_blocks(itemPath,'item');models=script_blocks(modelPath,'model');profiles=[]
    for name,body in items.items():
        if not re.search(r'\bSubCategory\s*=\s*Spear\s*,',body)or not re.search(r'\bSwingAnim\s*=\s*Spear\s*,',body):continue
        sprites=re.search(r'\bWeaponSprite\s*=\s*(\w+)\s*,',body)or re.search(r'\bWeaponSpritesByIndex\s*=\s*([^,]+),',body);assert sprites,name;variants=[]
        for sprite in sprites[1].strip().split(';'):
            model=models[sprite];mesh=re.search(r'\bmesh\s*=\s*([^,]+),',model);assert mesh and not re.search(r'\bscale\s*=',model)and 'attachment Bip01_Prop1'not in model
            path=native/'models_X'/(mesh[1].strip()+'.x');vertices=mesh_vertices(path);bounds=[(min(p[i]for p in vertices),max(p[i]for p in vertices))for i in range(3)];variants.append({'sprite':sprite,'mesh':str(path),'meshSha256':sha(path),'bounds':bounds})
        assert all(v['meshSha256']==variants[0]['meshSha256']for v in variants),name
        profiles.append({'item':'Base.'+name,**variants[0],'variants':variants,'clip':'ProjectYakuza_LauSpearGround'+(''if name=='SpearCrafted'else'_'+name)})
    assert len(profiles)==22 and any(p['item']=='Base.SpearCrafted'for p in profiles)
    return {'items':sorted(profiles,key=lambda p:p['item']),'scripts':[{'path':str(p),'sha256':sha(p)}for p in [itemPath,modelPath]],'reference':'Base.SpearCrafted','basis':'All native SubCategory=Spear weapons, including forged, short, fire-hardened, bone, plunger and indexed sprites. Each native mesh gets its own floor/shaft calibration. Unknown modded spear-class weapons use the crafted-spear fallback.'}

def extract():
    index=unpack(archive,folder);(folder/'source-index.json').write_text(json.dumps(index,indent=2)+'\n');rows=read_scene(folder/'cmn.par/cmn.bin');actor=next(r for r in rows if r['type']==5 and r['name'].startswith('c_am_rau_'));spear=next(r for r in rows if r['type']==7 and r['name']=='a12_03a_spear_rhau_1');selection={}
    for key,parent,kind in [('actor',actor,6),('spear',spear,9)]:
        motion=next(r for r in rows if r['parent']==parent['offset']and r['type']==kind);name=resource(folder/'007.par/res.bin',motion['guid']);path=folder/'007.par'/(name+'.gmt');selection[key]={'node':parent,'motion':motion,'resource':name,'path':str(path),'sha256':sha(path)}
    continuation={}
    for key,parent,kind in [('actor',actor,6),('spear',spear,9)]:
        motion=next(r for r in rows if r['parent']==parent['offset']and r['type']==kind);name=resource(folder/'008.par/res.bin',motion['guid']);path=folder/'008.par'/(name+'.gmt');continuation[key]={'node':parent,'motion':motion,'resource':name,'path':str(path),'sha256':sha(path)}
    result={'archive':str(archive),'archiveSha256':sha(archive),'scene':str(folder/'cmn.par/cmn.bin'),'sceneSha256':sha(folder/'cmn.par/cmn.bin'),'contactFrame':121,'fps':30,'segments':[{'cut':'007','resources':str(folder/'007.par/res.bin'),'resourcesSha256':sha(folder/'007.par/res.bin'),'selection':selection,'firstFrame':112,'lastFrame':190},{'cut':'008','resources':str(folder/'008.par/res.bin'),'resourcesSha256':sha(folder/'008.par/res.bin'),'selection':continuation,'firstFrame':1,'lastFrame':225}],'basis':'Original Kiwami Lau Ka Long floor strike and flourish, main12_s04 cuts 007 and 008. The matching boundary pose is included once, followed by 225 original continuation frames, extending playback by exactly 7.5 seconds.','nativeProfiles':native_profiles()}
    (folder.parent/'selection.json').write_text(json.dumps(result,indent=2)+'\n');print('PASS original Lau cutscene/spear bindings, 304 samples over 10.1 seconds and',len(result['nativeProfiles']['items']),'native spear items')

if __name__=='__main__':extract()
