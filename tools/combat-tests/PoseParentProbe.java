import java.nio.file.*;
import java.util.*;
import jassimp.*;
public class PoseParentProbe {
 static Class<?> type(String name)throws Exception{return Class.forName(name);}
 static float part(Object value,String name)throws Exception{return LimbImpactProbe.component(value,name);}
 public static void main(String[]args)throws Exception{
  Jassimp.setLibraryLoader(new JassimpLibraryLoader(){public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}});
  Object body=LimbImpactProbe.process("F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x",null),rig=null;var skin=type("zombie.core.skinnedmodel.model.SkinningData");
  for(var c:skin.getConstructors())if(c.getParameterCount()==6)rig=c.newInstance(LimbImpactProbe.field(body,"clips"),LimbImpactProbe.field(body,"bindPose"),LimbImpactProbe.field(body,"invBindPose"),LimbImpactProbe.field(body,"skinOffsetMatrices"),LimbImpactProbe.field(body,"skeletonHierarchy"),LimbImpactProbe.field(body,"boneIndices"));
  var trackType=type("zombie.core.skinnedmodel.animation.AnimationTrack");var vec=type("org.lwjgl.util.vector.Vector3f");var quat=type("org.lwjgl.util.vector.Quaternion");var mat=type("org.lwjgl.util.vector.Matrix4f");var helper=type("zombie.core.skinnedmodel.HelperFunctions");
  var get=trackType.getMethod("get",int.class,vec,quat,vec);var current=trackType.getMethod("setCurrentTimeValue",float.class);var previous=trackType.getMethod("setPreviousTimeValue",float.class);var update=trackType.getMethod("UpdateKeyframes",float.class);var make=helper.getMethod("CreateFromQuaternionPositionScale",vec,quat,vec,mat);var mul=mat.getMethod("mul",mat,mat,mat);
  Object pos=vec.getConstructor().newInstance(),rot=quat.getConstructor().newInstance(),scale=vec.getConstructor().newInstance();String[] names={"Dummy01","Bip01","Bip01_Pelvis","Bip01_Spine"};int total=0;
  for(String line:Files.readAllLines(Path.of(args[0]))){
   String[] row=line.split("\t");var file=Path.of(row[0]);Object source=LimbImpactProbe.process(row[0],rig);var indices=(Map<String,Integer>)LimbImpactProbe.field(source,"boneIndices");var hierarchy=(List<Integer>)LimbImpactProbe.field(source,"skeletonHierarchy");Object clip=((Map<?,?>)LimbImpactProbe.field(source,"clips")).values().iterator().next();var track=trackType.getMethod("alloc").invoke(null);trackType.getMethod("startClip",clip.getClass(),boolean.class,float.class).invoke(track,clip,false,0f);
   float duration=(Float)trackType.getMethod("getDuration").invoke(track);var out=new StringBuilder("{\"duration\":"+duration+",\"fps\":30,\"sha256\":\""+HexFormat.of().formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(Files.readAllBytes(file)))+"\",\"frames\":[");var refs=new StringBuilder("[\n");
   for(int frame=0;frame<=Math.round(duration*30);frame++){
    float time=Math.min(duration,frame/30f);current.invoke(track,time);previous.invoke(track,time);update.invoke(track,0f);if(frame>0){out.append(',');refs.append(',');}out.append('[');refs.append('[');Object parent=null;
    for(int b=0;b<4;b++){
     int bone=indices.get(names[b]);if(hierarchy.get(bone)!=(b==0?-1:indices.get(names[b-1])))throw new AssertionError("parent hierarchy "+names[b]+" index="+bone+" parent="+hierarchy.get(bone)+" bones="+indices);
     get.invoke(track,bone,pos,rot,scale);for(String axis:new String[]{"x","y","z"})if(Math.abs(part(scale,axis)-1)>.0001)throw new AssertionError("non-rigid parent "+file);
     if(b>0)out.append(',');out.append('[').append(part(pos,"x")).append(',').append(part(pos,"y")).append(',').append(part(pos,"z")).append(',').append(part(rot,"x")).append(',').append(part(rot,"y")).append(',').append(part(rot,"z")).append(',').append(part(rot,"w")).append(']');
     Object matrix=mat.getConstructor().newInstance();make.invoke(null,pos,rot,scale,matrix);if(parent!=null)mul.invoke(null,matrix,parent,matrix);parent=matrix;
     if(b>0)refs.append(',');refs.append('[');for(int i=0;i<12;i++){if(i>0)refs.append(',');refs.append(part(matrix,"m"+(i/4)+(i%4)));}refs.append(']');
    }
    out.append(']');refs.append(']');
   }
   out.append("],\"reference\":").append(refs).append("]}");Files.writeString(Path.of(row[1]),out);trackType.getMethod("reset").invoke(track);total++;
  }
  System.out.println("PASS "+total+" native Human parent-pose clips sampled with original track clocks; hierarchy and unit scale verified; no media generated");
 }
}

