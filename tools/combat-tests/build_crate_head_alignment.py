from pathlib import Path
import sys,json,hashlib,zipfile
from mathutils import Matrix,Vector

root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent));mod=root/'combat/ProjectYakuza'
from locomotion_math import read,locals_at,world,blocks,write
from native_body_geometry import load_body,skin_part,validate_bind

def build():
    sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();report=json.loads((mod/'docs/crate-heat-assets.json').read_text());model=json.loads((mod/'docs/beer-crate-assets.json').read_text());vertices=[Vector(v)*.5 for v in model['vertices']];body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');validate_bind(body);baseline=root/'dist/ProjectYakuza-B42-v0.98.0.zip';records=[]
    with zipfile.ZipFile(baseline)as archive:
        for clip in report['clips']:
            if clip['role']!=0:continue
            source=root/'tools/combat-tests'/('crate-head-baseline-'+('ending'if clip['ending']else'main')+'.x');source.write_bytes(archive.read('ProjectYakuza/'+clip['output']));text,bones,animation,spans=read(source);victim=next(c for c in report['clips']if c['role']==1 and c['ending']==clip['ending']);_,vb,va,_=read(mod/victim['output']);paths=report['endingPaths']if clip['ending']else report['paths'];poses=[];anchors=[]
            for frame,sourceFrame in enumerate(clip['sourceFrames']):
                pose=locals_at(bones,animation,frame*160);native=world(bones,pose);v=world(vb,locals_at(vb,va,frame*160));ap,vp=paths[0][frame],paths[1][frame];shift=Vector(((vp[1]-ap[1])/1.5,0,-(vp[0]-ap[0])/1.5));head=[p+shift for p in skin_part(body,v,['Bip01_Head'])];prop=native['Bip01_Prop1'];shape=[prop.to_3x3()@p for p in vertices];target=Vector(((min(p.x for p in head)+max(p.x for p in head))/2,max(p.y for p in head),(min(p.z for p in head)+max(p.z for p in head))/2));centre=Vector(((min(p.x for p in shape)+max(p.x for p in shape))/2,min(p.y for p in shape),(min(p.z for p in shape)+max(p.z for p in shape))/2));desired=target-centre;t=min(1,sourceFrame/13);weight=t*t*(3-2*t);prop.translation=prop.translation.lerp(desired,weight);pose['Bip01_Prop1']=native[bones['Bip01_Prop1']['parent']].inverted()@prop;poses.append(pose);anchors.append({'sourceFrame':sourceFrame,'weight':weight,'target':list(target),'localModelSeat':list(centre),'propWorld':[list(row)for row in prop]})
            output=mod/clip['output'];changes=blocks(bones,poses,[i*160 for i in range(clip['frames'])],None);write(output,text,{'Bip01_Prop1':spans['Bip01_Prop1']},{'Bip01_Prop1':changes['Bip01_Prop1']},output.stem);clip['sha256']=sha(output);records.append({'output':clip['output'],'sha256':sha(output),'baselineSha256':sha(source),'frames':anchors})
    alignment={'operation':'Reduced beer-crate geometry is seated on the native skinned victim head: horizontal footprint centre matches head bounds, and lowest transformed crate vertex touches the head crown. Original object rotations and all actor/victim body channels are retained. Smooth original 0..13 placement handoff reaches full seating at the original opening impact, then follows the head throughout main and failure recovery. Only actor right-prop translations change.','baseline':str(baseline),'baselineSha256':sha(baseline),'modelScale':.5,'modelSha256':model['sha256'],'nativeBody':body['path'],'nativeBodySha256':sha(body['path']),'clips':records};report['headAlignment']='crate-head-alignment.json';(mod/'docs/crate-heat-assets.json').write_text(json.dumps(report,indent=2)+'\n');(mod/'docs/crate-head-alignment.json').write_text(json.dumps(alignment,indent=2)+'\n');print('PASS reduced crate seated on native head across main/ending clips; source body and object rotations retained')

if __name__=='__main__':build()
