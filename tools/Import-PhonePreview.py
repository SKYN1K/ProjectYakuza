from pathlib import Path
import argparse,hashlib,io,json,math,re
from PIL import Image

def plan(width,height,frames,max_edge=512):
    assert 1<=frames<=120 and 0<width<=8192 and 0<height<=8192,'GIF dimensions or frame count exceed the preview limits'
    assert 16<=max_edge<=512
    scale=min(1,max_edge/max(width,height),math.sqrt(8*1024*1024/(width*height*frames)))
    return max(1,int(width*scale)),max(1,int(height*scale))

def save(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    if path.exists():assert path.read_bytes()==data,'Refusing to overwrite a different asset: '+str(path)
    else:path.write_bytes(data)

def convert(source,mod_root,namespace,name,max_edge=512):
    source=Path(source).resolve();root=Path(mod_root).resolve()
    assert re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*',namespace)and re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*',name)
    assert source.is_file()and source.stat().st_size<=20*1024*1024 and source.read_bytes()[:6]in[b'GIF87a',b'GIF89a']
    assert (root/'42/mod.info').is_file(),'Choose an existing Build 42 mod root'
    frames=[];durations=[];records=[]
    with Image.open(source)as gif:
        assert gif.format=='GIF';size=plan(gif.width,gif.height,gif.n_frames,max_edge);loop=gif.info.get('loop');loops=0 if loop==0 else int(loop)+1 if loop is not None else 1
        for index in range(gif.n_frames):
            gif.seek(index);duration=max(10,min(60000,int(gif.info.get('duration',100)or 100)));frame=gif.convert('RGBA')
            if frame.size!=size:frame=frame.resize(size,Image.Resampling.LANCZOS)
            file=root/('42/media/textures/'+namespace+'/PhonePreviews/'+name+'_'+str(index+1).zfill(3)+'.png')
            assert file.resolve().is_relative_to(root)
            stream=io.BytesIO();frame.save(stream,format='PNG',optimize=True);data=stream.getvalue();save(file,data)
            frames.append('media/'+file.relative_to(root/'42/media').as_posix());durations.append(duration);records.append({'file':file.relative_to(root).as_posix(),'sha256':hashlib.sha256(data).hexdigest()})
    descriptor='return {frames={'+','.join(json.dumps(p)for p in frames)+'},durations={'+','.join(map(str,durations))+'},loops='+str(loops)+'}\n'
    lua=root/('42/media/lua/client/'+namespace+'/PhonePreviews/'+name+'.lua');assert lua.resolve().is_relative_to(root);save(lua,descriptor.encode())
    report={'source':source.name,'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'frames':len(frames),'size':size,'durationsMs':durations,'loops':loops,'runtimeDescriptor':lua.relative_to(root).as_posix(),'outputs':records,'operation':'Original GIF logical canvas decoded with Pillow disposal/compositing and original delays. Downsampled only when needed for a 512-pixel edge and 32 MiB decoded preview budget. No synthesis or new artwork.'}
    save(root/('docs/phone-preview-'+name+'.json'),(json.dumps(report,indent=2)+'\n').encode());return report

if __name__=='__main__':
    parser=argparse.ArgumentParser(description='Import an author-supplied GIF as a timed Project Yakuza phone preview.')
    parser.add_argument('--gif',type=Path,required=True);parser.add_argument('--mod-root',type=Path,required=True);parser.add_argument('--namespace',required=True);parser.add_argument('--name',required=True);parser.add_argument('--max-edge',type=int,default=512)
    args=parser.parse_args();print(json.dumps(convert(args.gif,args.mod_root,args.namespace,args.name,args.max_edge),indent=2))
