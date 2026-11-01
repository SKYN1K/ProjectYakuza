import jassimp.*;
import java.util.*;
import java.lang.reflect.*;
import java.nio.file.*;

public class PunchTrackProbe {
 static Object field(Object o,String n)throws Exception {var f=o.getClass().getDeclaredField(n);f.setAccessible(true);return f.get(o);}
 static Object obj(Class<?> c)throws Exception{return c.getConstructor().newInstance();}
 static float component(Object o,String n)throws Exception{return o.getClass().getField(n).getFloat(o);}
 public static void main(String[] args)throws Exception{
  Locale.setDefault(Locale.ROOT);
  Jassimp.setLibraryLoader(new JassimpLibraryLoader(){public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}});
  AiScene scene=Jassimp.importFile(args[0],EnumSet.of(AiPostProcessSteps.MAKE_LEFT_HANDED,AiPostProcessSteps.REMOVE_REDUNDANT_MATERIALS));
  var pt=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiSceneParams");var params=pt.getMethod("create").invoke(null);
  pt.getField("scene").set(params,scene);var mode=(Class)Class.forName("zombie.core.skinnedmodel.model.jassimp.JAssImpImporter$LoadMode");pt.getField("mode").set(params,Enum.valueOf(mode,"AnimationOnly"));
  var processed=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiScene").getMethod("process",pt).invoke(null,params);
  var sk=field(processed,"skeleton");var indices=(Map<String,Integer>)field(sk,"boneIndices");var hierarchy=(List<Integer>)field(sk,"skeletonHierarchy");
  var clips=(Map)field(sk,"clips");var clip=clips.values().iterator().next();var ct=clip.getClass();float duration=(Float)ct.getMethod("getDuration").invoke(clip);
  var mat=Class.forName("org.lwjgl.util.vector.Matrix4f");var vec=Class.forName("org.lwjgl.util.vector.Vector3f");var quat=Class.forName("org.lwjgl.util.vector.Quaternion");var helper=Class.forName("zombie.core.skinnedmodel.HelperFunctions");
  var make=helper.getMethod("CreateFromQuaternionPositionScale",vec,quat,vec,mat);var mul=mat.getMethod("mul",mat,mat,mat);
  String[] bones={"Bip01_L_Forearm","Bip01_L_Hand","Bip01_L_Finger1","Bip01_R_Forearm","Bip01_R_Hand","Bip01_R_Finger1","Bip01_L_UpperArm","Bip01_R_UpperArm"};
  var out=new StringBuilder("{\"fps\":30,\"duration\":"+duration+",\"bones\":[");
  for(int i=0;i<bones.length;i++){if(i>0)out.append(',');out.append('"').append(bones[i]).append('"');}out.append("],\"frames\":[");
  int frames=Math.round(duration*30)+1;
  for(int frame=0;frame<frames;frame++){
   var matrices=new Object[hierarchy.size()];float time=frame/30f;
   for(int i=0;i<matrices.length;i++){
    var keys=(Object[])ct.getMethod("getBoneFramesAt",int.class).invoke(clip,i);
    if(keys.length==0)throw new AssertionError("Missing bone "+i);
    var key=keys[Math.min(frame,keys.length-1)];if(Math.abs(component(key,"time")-time)>.0001)throw new AssertionError("Key time "+i+" "+frame);
    var kc=key.getClass();var m=obj(mat);make.invoke(null,kc.getField("position").get(key),kc.getField("rotation").get(key),kc.getField("scale").get(key),m);
    int parent=hierarchy.get(i);if(parent>=0)mul.invoke(null,m,matrices[parent],m);matrices[i]=m;
   }
   if(frame>0)out.append(',');out.append('[');
   for(int b=0;b<bones.length;b++){if(b>0)out.append(',');var m=matrices[indices.get(bones[b])];out.append(String.format("[%.9f,%.9f,%.9f]",component(m,"m03"),component(m,"m13"),component(m,"m23")));}out.append(']');
  }
  out.append("],\"projection\":[");
  var world=Class.forName("zombie.iso.Vector3");var model=Class.forName("zombie.core.skinnedmodel.model.Model");var iso=Class.forName("zombie.iso.IsoUtils");
  for(int i=0;i<8;i++){
   float angle=(float)(i*Math.PI/4);var point=world.getConstructor(float.class,float.class,float.class).newInstance(.1f,.65f,-.4f);
   model.getMethod("vectorToWorldCoords",float.class,float.class,float.class,float.class,world).invoke(null,0f,0f,0f,angle+(float)Math.PI/2,point);
   float x=component(point,"x"),y=component(point,"y"),z=component(point,"z");
   float sx=(Float)iso.getMethod("XToScreen",float.class,float.class,float.class,int.class).invoke(null,x,y,z,0);
   float sy=(Float)iso.getMethod("YToScreen",float.class,float.class,float.class,int.class).invoke(null,x,y,z,0);
   if(i>0)out.append(',');out.append(String.format("[%.9f,%.9f,%.9f,%.9f,%.9f]",sx,sy,x,y,z));
  }

  var character=Class.forName("zombie.characters.IsoGameCharacter");
  for(String method:new String[]{"dbgGetAnimTrackName","dbgGetAnimTrackTime","dbgGetAnimTrackWeight"})character.getMethod(method,int.class,int.class);
  character.getMethod("getAnimAngleRadians");character.getMethod("getShoulderTwist");
  out.append("]}");Files.writeString(Path.of(args[1]),out);System.out.println("PASS native original punch import/FK: "+frames+" samples, eight bones, "+hierarchy.size()+" skeleton bones");
 }
}
