package zombie.core.skinnedmodel.model.jassimp;

import jassimp.*;
import java.nio.file.*;
import java.util.*;
import org.lwjgl.util.vector.Matrix4f;
import zombie.core.skinnedmodel.HelperFunctions;
import zombie.core.skinnedmodel.animation.*;
import zombie.core.skinnedmodel.model.SkinningData;

/** Use the game's actual loader flags, shared Human skin rig and PRS matrices. */
public class MadDogRigProbe {
    static AiScene load(Path p)throws Exception {
        return Jassimp.importFile(p.toAbsolutePath().toString(),EnumSet.of(
            AiPostProcessSteps.MAKE_LEFT_HANDED,AiPostProcessSteps.REMOVE_REDUNDANT_MATERIALS));
    }
    static ImportedSkeleton process(AiScene scene,SkinningData rig) {
        var p=ProcessedAiSceneParams.create();p.scene=scene;p.skinnedTo=rig;
        p.mode=JAssImpImporter.LoadMode.AnimationOnly;
        return ImportedSkeleton.process(ImportedSkeletonParams.create(p,scene.getMeshes().get(0)));
    }
    static String matrix(Matrix4f m) {
        return String.format(Locale.ROOT,"[%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f]",
            m.m00,m.m01,m.m02,m.m03,m.m10,m.m11,m.m12,m.m13,
            m.m20,m.m21,m.m22,m.m23,m.m30,m.m31,m.m32,m.m33);
    }
    public static void main(String[] args)throws Exception {
        JAssImpImporter.Init();
        Jassimp.setLibraryLoader(new JassimpLibraryLoader(){public void loadLibrary(){System.load(Path.of(args[0]).toAbsolutePath().toString());}});
        Path bodyPath=Path.of(args[1]),clips=Path.of(args[2]),output=Path.of(args[3]);Files.createDirectories(output);
        var body=process(load(bodyPath),null);
        var rig=new SkinningData(body.clips,body.bindPose,body.invBindPose,body.skinOffsetMatrices,body.skeletonHierarchy,body.boneIndices);
        String[] names=new String[body.boneIndices.size()];for(var e:body.boneIndices.entrySet())names[e.getValue()]=e.getKey();
        int count=0,poses=0;
        for(Path path:Files.list(clips).filter(p->p.toString().endsWith(".x")).sorted().toList()) {
            var imported=process(load(path),rig);
            if(!imported.boneIndices.equals(body.boneIndices)||!imported.skeletonHierarchy.equals(body.skeletonHierarchy))
                throw new AssertionError("Clip changes actual Human hierarchy: "+path);
            var clip=imported.clips.values().iterator().next();
            int end=Math.round(clip.getDuration()*30);
            StringBuilder json=new StringBuilder("{\"bones\":[");
            for(int i=0;i<names.length;i++){if(i>0)json.append(',');json.append('"').append(names[i]).append('"');}
            json.append("],\"parents\":").append(body.skeletonHierarchy).append(",\"samples\":[");
            // Every source frame, rather than exporter-created reference poses.
            for(int frame=0;frame<=end;frame++) {
                float time=frame/30f;if(frame>0)json.append(',');
                json.append("{\"frame\":").append(frame).append(",\"matrices\":[");
                Matrix4f[] world=new Matrix4f[names.length];
                for(int i=0;i<names.length;i++) {
                    Keyframe selected=null;var keys=clip.getBoneFramesAt(i);
                    if(keys!=null)for(var key:keys)if(key.time<=time+.00001f)selected=key;
                    if(selected==null)throw new AssertionError("Missing Human bone "+names[i]+" in "+path);
                    var local=HelperFunctions.CreateFromQuaternionPositionScale(selected.position,selected.rotation,selected.scale,new Matrix4f());
                    int parent=body.skeletonHierarchy.get(i);
                    world[i]=parent>=0?Matrix4f.mul(local,world[parent],new Matrix4f()):local;
                    if(!Float.isFinite(world[i].determinant())||Math.abs(world[i].determinant()-1)>.001)throw new AssertionError("Invalid rigid transform");
                    if(i>0)json.append(',');json.append(matrix(world[i]));
                }
                json.append("]}");poses++;
            }
            json.append("]}");Files.writeString(output.resolve(path.getFileName().toString().replace(".x",".json")),json.toString());count++;
        }
        System.out.println("PASS: "+bodyPath.getFileName()+" — "+count+" clips / "+poses+" native Human poses with unchanged hierarchy and finite rigid transforms");
    }
}
