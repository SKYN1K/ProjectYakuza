import java.nio.file.*;
import java.util.*;
import java.io.*;
public class StyleFXProbe {
 public static void main(String[]args)throws Exception{
  var root=Path.of(args[0]);var image=Class.forName("zombie.core.textures.ImageData");int count=0;
  for(String name:new String[]{"EntryWispA","EntryWispB","TauntSpiral","TauntStreak"}){
   Object decoded;try(var input=Files.newInputStream(root.resolve("42/media/textures/ProjectYakuza/StyleFX/"+name+".png"))){decoded=image.getConstructor(InputStream.class,boolean.class).newInstance(input,false);}
   int width=(Integer)image.getMethod("getWidth").invoke(decoded),height=(Integer)image.getMethod("getHeight").invoke(decoded);int expectedWidth=name.equals("TauntSpiral")?128:name.equals("TauntStreak")?32:64,expectedHeight=name.equals("TauntStreak")?64:128;
   if(width!=expectedWidth||height!=expectedHeight||image.getMethod("getData").invoke(decoded)==null)throw new AssertionError(name);image.getMethod("dispose").invoke(decoded);count++;
  }
  var node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");int clips=0;
  try(var files=Files.walk(root.resolve("42/media/AnimSets/player"))){for(var p:files.filter(v->v.getFileName().toString().contains("StyleEntry")&&v.toString().endsWith(".xml")).toList()){
   var parsed=node.getMethod("Parse",String.class).invoke(null,p.toString());if(!node.getField("earlyTransitionOut").getBoolean(parsed)||Math.abs(((Number)node.getField("blendOutTime").get(parsed)).doubleValue()-.24)>.000001)throw new AssertionError(p);clips++;
  }}
  if(clips!=3)throw new AssertionError(clips);System.out.println("PASS "+count+" original-size Kiwami 2 textures through native ImageData and "+clips+" owner/observer early-blend definitions; no game launch");
 }
}

