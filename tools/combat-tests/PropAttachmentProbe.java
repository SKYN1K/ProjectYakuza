import jassimp.*;
import java.util.*;import java.nio.file.*;
public class PropAttachmentProbe {
 static Object field(Object o,String n)throws Exception{var f=o.getClass().getDeclaredField(n);f.setAccessible(true);return f.get(o);}
 public static void main(String[]args)throws Exception{
  Jassimp.setLibraryLoader(new JassimpLibraryLoader(){public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}});
  var pt=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiSceneParams");var mode=(Class)Class.forName("zombie.core.skinnedmodel.model.jassimp.JAssImpImporter$LoadMode");
  var mat=Class.forName("org.lwjgl.util.vector.Matrix4f");var vec=Class.forName("org.lwjgl.util.vector.Vector3f");var quat=Class.forName("org.lwjgl.util.vector.Quaternion");var helper=Class.forName("zombie.core.skinnedmodel.HelperFunctions");var make=helper.getMethod("CreateFromQuaternionPositionScale",vec,quat,vec,mat);var mul=mat.getMethod("mul",mat,mat,mat);var invert=mat.getMethod("invert",mat,mat);
  int clips=0,pairs=0;float worst=0;
  for(String line:Files.readAllLines(Path.of(args[0]))){
   String[] cells=line.split("\t");var scene=Jassimp.importFile(cells[0],EnumSet.of(AiPostProcessSteps.MAKE_LEFT_HANDED,AiPostProcessSteps.REMOVE_REDUNDANT_MATERIALS));var params=pt.getMethod("create").invoke(null);pt.getField("scene").set(params,scene);pt.getField("mode").set(params,Enum.valueOf(mode,"AnimationOnly"));
   var processed=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiScene").getMethod("process",pt).invoke(null,params);var skeleton=field(processed,"skeleton");var indices=(Map<String,Integer>)field(skeleton,"boneIndices");var hierarchy=(List<Integer>)field(skeleton,"skeletonHierarchy");var clip=((Map)field(skeleton,"clips")).values().iterator().next();var ct=clip.getClass();int frames=Integer.parseInt(cells[3]);
   String[][] samples={cells[1].split(";"),cells[2].split(";")};for(var sample:samples)if(sample.length!=1&&sample.length!=frames)throw new AssertionError("prop sample count "+cells[0]);
   Object[][] keys=new Object[hierarchy.size()][];for(int i=0;i<keys.length;i++){keys[i]=(Object[])ct.getMethod("getBoneFramesAt",int.class).invoke(clip,i);if(keys[i].length!=frames)throw new AssertionError("source frames "+cells[0]);}
   for(int f=0;f<frames;f++){
    Object[] world=new Object[hierarchy.size()];for(int i=0;i<world.length;i++){var key=keys[i][f];var kc=key.getClass();var m=mat.getConstructor().newInstance();make.invoke(null,kc.getField("position").get(key),kc.getField("rotation").get(key),kc.getField("scale").get(key),m);int parent=hierarchy.get(i);if(parent>=0)mul.invoke(null,m,world[parent],m);world[i]=m;}
    for(int hand=0;hand<2;hand++){
     String handName=hand==0?"Bip01_R_Hand":"Bip01_L_Hand",propName=hand==0?"Bip01_Prop1":"Bip01_Prop2";Object inv=mat.getConstructor().newInstance(),relative=mat.getConstructor().newInstance();invert.invoke(null,world[indices.get(handName)],inv);mul.invoke(null,world[indices.get(propName)],inv,relative);String[] expected=samples[hand][samples[hand].length==1?0:f].split(",");
     for(int row=0;row<4;row++)for(int col=0;col<4;col++){float actual=mat.getField("m"+row+col).getFloat(relative),target=Float.parseFloat(expected[row*4+col]);float error=Math.abs(actual-target);if(!Float.isFinite(actual)||error>.0001f)throw new AssertionError("prop detached "+cells[0]+" frame="+f+" "+propName+" error="+error);worst=Math.max(worst,error);}pairs++;
    }
   }clips++;
  }
  System.out.println("PASS "+clips+" clips / "+pairs+" native hand-prop pose pairs follow authored static or animated offsets; maximum matrix error "+worst);
 }
}
