import java.nio.file.*;
import java.util.*;
import jassimp.*;
public class MaskedLimbPoseProbe {
 static Class<?> type(String n)throws Exception{return Class.forName(n);}
 static void set(Object o,String n,Object value)throws Exception{var f=o.getClass().getDeclaredField(n);f.setAccessible(true);f.set(o,value);}
 public static void main(String[]args)throws Exception{
  Jassimp.setLibraryLoader(new JassimpLibraryLoader(){public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}});
  Object body=LimbImpactProbe.process("F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x",null),rig=null;var skin=type("zombie.core.skinnedmodel.model.SkinningData");
  for(var c:skin.getConstructors())if(c.getParameterCount()==6)rig=c.newInstance(LimbImpactProbe.field(body,"clips"),LimbImpactProbe.field(body,"bindPose"),LimbImpactProbe.field(body,"invBindPose"),LimbImpactProbe.field(body,"skinOffsetMatrices"),LimbImpactProbe.field(body,"skeletonHierarchy"),LimbImpactProbe.field(body,"boneIndices"));
  var indices=(Map<String,Integer>)LimbImpactProbe.field(body,"boneIndices");int count=((List<?>)LimbImpactProbe.field(body,"skeletonHierarchy")).size();
  var m=type("org.lwjgl.util.vector.Matrix4f");var tt=type("zombie.core.skinnedmodel.animation.AnimationTrack");var bt=type("zombie.core.skinnedmodel.animation.AnimatorsBoneTransform");var ap=type("zombie.core.skinnedmodel.animation.AnimationPlayer");var ctor=ap.getDeclaredConstructor();ctor.setAccessible(true);Object player=ctor.newInstance();set(player,"skinningData",rig);
  var bones=java.lang.reflect.Array.newInstance(bt,count);var matrices=java.lang.reflect.Array.newInstance(m,count);
  for(int i=0;i<count;i++){java.lang.reflect.Array.set(bones,i,bt.getMethod("alloc").invoke(null));java.lang.reflect.Array.set(matrices,i,m.getConstructor().newInstance());}
  set(player,"boneTransforms",bones);set(player,"modelTransforms",matrices);var update=ap.getDeclaredMethod("updateModelTransformsInternal");update.setAccessible(true);var blend=ap.getDeclaredMethod("updateMultiTrackBoneTransformsInternal",float.class);blend.setAccessible(true);var multi=ap.getMethod("getMultiTrack").invoke(player);var live=(List<Object>)multi.getClass().getMethod("getTracks").invoke(multi);
  var out=new StringBuilder("[");int jobs=0;String[] observed={"Bip01_L_UpperArm","Bip01_L_Forearm","Bip01_L_Hand","Bip01_L_Finger1","Bip01_R_UpperArm","Bip01_R_Forearm","Bip01_R_Hand","Bip01_R_Finger1"};
  for(String line:Files.readAllLines(Path.of(args[0]))){
   String[] r=line.split("\t");Object[] tracks=new Object[r.length>3?3:2];String[] names=new String[tracks.length];
   live.clear();set(player,"boneTransformsNeedFirstFrame",true);for(int j=0;j<tracks.length;j++){String source=r[j==2?3:j];Object data=LimbImpactProbe.process(source,rig);Object clip=((Map<?,?>)LimbImpactProbe.field(data,"clips")).values().iterator().next();tracks[j]=tt.getMethod("alloc").invoke(null);tt.getMethod("startClip",clip.getClass(),boolean.class,float.class).invoke(tracks[j],clip,false,0f);names[j]=Path.of(source).getFileName().toString().replace(".x","");tt.getMethod("setBlendWeight",float.class).invoke(tracks[j],1f);tt.getMethod("setBlendFieldWeight",float.class).invoke(tracks[j],tracks.length==3&&j!=1?(j==0?.35f:.65f):1f);tt.getField("priority").setInt(tracks[j],j==1?1000:0);live.add(tracks[j]);}
   var node=type("zombie.core.skinnedmodel.advancedanimation.AnimNode");Object parsed=node.getMethod("Parse",String.class).invoke(null,r[2]);Object weights=node.getField("subStateBoneWeights").get(parsed);tt.getMethod("setBoneWeights",List.class).invoke(tracks[1],weights);tt.getMethod("initBoneWeights",skin).invoke(tracks[1],rig);
   for(int frame=0;frame<7;frame++){
    float baseTime=.04f+frame*.033333333f,time=.1f+frame*.033333333f;
    for(int j=0;j<tracks.length;j++){float t=j==1?time:baseTime;tt.getMethod("setCurrentTimeValue",float.class).invoke(tracks[j],t);tt.getMethod("setPreviousTimeValue",float.class).invoke(tracks[j],t);tt.getMethod("UpdateKeyframes",float.class).invoke(tracks[j],0f);}
    blend.invoke(player,0f);
    update.invoke(player);if(jobs++>0)out.append(',');out.append("{\"base\":\"").append(names[0]).append("\",\"animation\":\"").append(names[1]).append("\",\"baseTime\":").append(baseTime).append(",\"time\":").append(time);if(tracks.length==3)out.append(",\"base2\":\"").append(names[2]).append("\"");out.append(",\"points\":[");
    for(int b=0;b<observed.length;b++){Object matrix=ap.getMethod("getModelTransformAt",int.class).invoke(player,indices.get(observed[b]));if(b>0)out.append(',');out.append('[').append(LimbImpactProbe.component(matrix,"m03")).append(',').append(LimbImpactProbe.component(matrix,"m13")).append(',').append(LimbImpactProbe.component(matrix,"m23")).append(']');}out.append("]}");
   }
   for(Object t:tracks)tt.getMethod("reset").invoke(t);
  }
  Files.writeString(Path.of(args[1]),out.append(']').toString());System.out.println("PASS "+jobs+" actual native AnimationPlayer masked Human poses with original XML bone weights; no game or GPU launch");
 }
}
