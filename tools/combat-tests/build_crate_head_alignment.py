from pathlib import Path
import sys,json,hashlib,zipfile,math
from mathutils import Matrix,Vector

root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent));mod=root/'combat/ProjectYakuza'
from locomotion_math import read,locals_at,world,blocks,write
from native_body_geometry import load_body,skin_part,validate_bind

def build():
    sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();report=json.loads((mod/'docs/crate-heat-assets.json').read_text());model=json.loads((mod/'docs/beer-crate-assets.json').read_text());vertices=[Vector(v)*.5 for v in model['vertices']];body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');validate_bind(body);baseline=root/'dist/ProjectYakuza-B42-v0.98.0.zip';records=[]
    centre=Vector(tuple((min(v[i]for v in vertices)+max(v[i]for v in vertices))/2 for i in range(3)))
    calibration=Matrix.Translation(centre)@Matrix.Rotation(math.pi,4,'X')@Matrix.Translation(-centre)
    roof=min(v.y for v in vertices)+.006
    with zipfile.ZipFile(baseline)as archive:
        for clip in report['clips']:
            if clip['role']!=0:continue
            source=root/'tools/combat-tests'/('crate-head-baseline-'+('ending'if clip['ending']else'main')+'.x');source.write_bytes(archive.read('ProjectYakuza/'+clip['output']));text,bones,animation,spans=read(source);victim=next(c for c in report['clips']if c['role']==1 and c['ending']==clip['ending']);_,vb,va,_=read(mod/victim['output']);paths=report['endingPaths']if clip['ending']else report['paths'];poses=[];anchors=[]
            for frame,sourceFrame in enumerate(clip['sourceFrames']):
                pose=locals_at(bones,animation,frame*160);native=world(bones,pose);v=world(vb,locals_at(vb,va,frame*160));ap,vp=paths[0][frame],paths[1][frame];shift=Vector(((vp[1]-ap[1])/1.5,0,-(vp[0]-ap[0])/1.5));head=[p+shift for p in skin_part(body,v,['Bip01_Head'])];prop=native['Bip01_Prop1']@calibration;rotation=prop.to_3x3();headLocal=[rotation.inverted()@point for point in head];target=Vector(((min(point.x for point in headLocal)+max(point.x for point in headLocal))/2,min(point.y for point in headLocal),(min(point.z for point in headLocal)+max(point.z for point in headLocal))/2));seat=Vector((centre.x,roof,centre.z));desired=rotation@(target-seat);t=min(1,sourceFrame/13);weight=t*t*(3-2*t);prop.translation=prop.translation.lerp(desired,weight);pose['Bip01_Prop1']=native[bones['Bip01_Prop1']['parent']].inverted()@prop;poses.append(pose);anchors.append({'sourceFrame':sourceFrame,'weight':weight,'target':list(target),'localModelSeat':list(seat),'propWorld':[list(row)for row in prop]})
            output=mod/clip['output'];changes=blocks(bones,poses,[i*160 for i in range(clip['frames'])],None);write(output,text,{'Bip01_Prop1':spans['Bip01_Prop1']},{'Bip01_Prop1':changes['Bip01_Prop1']},output.stem);clip['sha256']=sha(output);records.append({'output':clip['output'],'sha256':sha(output),'baselineSha256':sha(source),'frames':anchors})
    alignment={'calibration':[list(row)for row in calibration],'roofInteriorY':roof,'modelCentre':list(centre),'operation':'The intact Y6 crate opens along positive local Y, opposite the Y5 scene prop convention. A fixed 180-degree local-X calibration around the scaled model centre reverses the opening while preserving the early object centre. From source frame 13 the head is centred in the crate local X/Z footprint and the inner closed-base plane sits just above the head crown, with the opening facing down. Original actor/victim body channels and source object motion remain; only actor right-prop channels change. Main and paired failure recovery share the same calibration.','baseline':str(baseline),'baselineSha256':sha(baseline),'modelScale':.5,'modelSha256':model['sha256'],'nativeBody':body['path'],'nativeBodySha256':sha(body['path']),'clips':records};report['headAlignment']='crate-head-alignment.json';(mod/'docs/crate-heat-assets.json').write_text(json.dumps(report,indent=2)+'\n');(mod/'docs/crate-head-alignment.json').write_text(json.dumps(alignment,indent=2)+'\n');print('PASS reduced crate seated on native head across main/ending clips; source body retained, corrected opening and inner roof placement')

if __name__=='__main__':build()
