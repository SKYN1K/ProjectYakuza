import java.nio.file.*;
import java.util.*;
import jassimp.*;
public class LimbImpactProbe {
 static Object field(Object value,String name)throws Exception{var f=value.getClass().getDeclaredField(name);f.setAccessible(true);return f.get(value);}
 static float component(Object value,String name)throws Exception{return value.getClass().getField(name).getFloat(value);}
 static Object process(String path,Object rig)throws Exception{
  var scene=Jassimp.importFile(path,EnumSet.of(AiPostProcessSteps.MAKE_LEFT_HANDED,AiPostProcessSteps.REMOVE_REDUNDANT_MATERIALS));var type=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiSceneParams");var params=type.getMethod("create").invoke(null);type.getField("scene").set(params,scene);var mode=(Class)Class.forName("zombie.core.skinnedmodel.model.jassimp.JAssImpImporter$LoadMode");type.getField("mode").set(params,Enum.valueOf(mode,"AnimationOnly"));if(rig!=null)type.getField("skinnedTo").set(params,rig);return field(Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiScene").getMethod("process",type).invoke(null,params),"skeleton");
 }

 public static void main(String[]args)throws Exception{
  Jassimp.setLibraryLoader(new JassimpLibraryLoader(){public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}});
  var body=process("F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x",null);var skin=Class.forName("zombie.core.skinnedmodel.model.SkinningData");Object rig=null;
  for(var c:skin.getConstructors())if(c.getParameterCount()==6)rig=c.newInstance(field(body,"clips"),field(body,"bindPose"),field(body,"invBindPose"),field(body,"skinOffsetMatrices"),field(body,"skeletonHierarchy"),field(body,"boneIndices"));
  var vec=Class.forName("org.lwjgl.util.vector.Vector3f");var quat=Class.forName("org.lwjgl.util.vector.Quaternion");var mat=Class.forName("org.lwjgl.util.vector.Matrix4f");var helper=Class.forName("zombie.core.skinnedmodel.HelperFunctions");var make=helper.getMethod("CreateFromQuaternionPositionScale",vec,quat,vec,mat);var mul=mat.getMethod("mul",mat,mat,mat);var trackType=Class.forName("zombie.core.skinnedmodel.animation.AnimationTrack");var get=trackType.getMethod("get",int.class,vec,quat,vec);var update=trackType.getMethod("UpdateKeyframes",float.class);var current=trackType.getMethod("setCurrentTimeValue",float.class);var previous=trackType.getMethod("setPreviousTimeValue",float.class);
  String[] bones={"Bip01_L_Forearm","Bip01_L_Hand","Bip01_L_Finger1","Bip01_R_Forearm","Bip01_R_Hand","Bip01_R_Finger1","Bip01_L_Calf","Bip01_L_Foot","Bip01_L_Toe0","Bip01_R_Calf","Bip01_R_Foot","Bip01_R_Toe0","Bip01_L_UpperArm","Bip01_R_UpperArm","Bip01_L_Thigh","Bip01_R_Thigh","Bip01_Head","Bip01_Neck","Bip01_Spine1","Bip01_Spine","Bip01_Pelvis"};
  for(int job=0;job<args.length;job+=2){
   Object imported=process(args[job],rig);var indices=(Map<String,Integer>)field(imported,"boneIndices");var hierarchy=(List<Integer>)field(imported,"skeletonHierarchy");var clip=((Map<?,?>)field(imported,"clips")).values().iterator().next();var track=trackType.getMethod("alloc").invoke(null);trackType.getMethod("startClip",clip.getClass(),boolean.class,float.class).invoke(track,clip,false,0f);float duration=((Number)trackType.getMethod("getDuration").invoke(track)).floatValue();int frames=Math.round(duration*120)+1;Object position=vec.getConstructor().newInstance(),rotation=quat.getConstructor().newInstance(),scale=vec.getConstructor().newInstance();Object[] matrices=new Object[hierarchy.size()];for(int i=0;i<matrices.length;i++)matrices[i]=mat.getConstructor().newInstance();
   String hash=java.util.HexFormat.of().formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(Files.readAllBytes(Path.of(args[job]))));var out=new StringBuilder("{\"sourceSha256\":\""+hash+"\",\"fps\":120,\"duration\":"+duration+",\"bones\":[");for(int i=0;i<bones.length;i++){if(i>0)out.append(',');out.append('"').append(bones[i]).append('"');}out.append("],\"frames\":[");
   for(int frame=0;frame<frames;frame++){
    float time=Math.min(duration,frame/120f);current.invoke(track,time);previous.invoke(track,time);update.invoke(track,0f);
    for(int i=0;i<matrices.length;i++){get.invoke(track,i,position,rotation,scale);make.invoke(null,position,rotation,scale,matrices[i]);int parent=hierarchy.get(i);if(parent>=0)mul.invoke(null,matrices[i],matrices[parent],matrices[i]);}
    if(frame>0)out.append(',');out.append('[');for(int b=0;b<bones.length;b++){if(b>0)out.append(',');Object m=matrices[indices.get(bones[b])];out.append('[').append(component(m,"m03")).append(',').append(component(m,"m13")).append(',').append(component(m,"m23")).append(']');}out.append(']');
   }
   out.append("]}");Files.writeString(Path.of(args[job+1]),out);trackType.getMethod("reset").invoke(track);System.out.println("PASS native 120 Hz Human limb poses: "+Path.of(args[job]).getFileName()+" / "+frames+" samples");
  }
 }
}
