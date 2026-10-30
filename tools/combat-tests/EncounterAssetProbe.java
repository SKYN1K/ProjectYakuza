import java.nio.file.*;
import java.io.*;
public class EncounterAssetProbe {
 public static void main(String[] args)throws Exception{
  var imageType=Class.forName("zombie.core.textures.ImageData");int count=0;
  for(String name:new String[]{"EncounterEdoSZ.png","EncounterFlare.png"}){
   Object data;try(var input=Files.newInputStream(Path.of(args[0],name))){data=imageType.getConstructor(InputStream.class,boolean.class).newInstance(input,false);}
   int width=(Integer)imageType.getMethod("getWidth").invoke(data),height=(Integer)imageType.getMethod("getHeight").invoke(data);
   if(width!=(name.contains("Edo")?2048:512)||height!=512||imageType.getMethod("getData").invoke(data)==null)throw new AssertionError(name);
   imageType.getMethod("dispose").invoke(data);count++;
  }
  var player=Class.forName("zombie.characters.IsoPlayer");var stats=player.getMethod("getStats").getReturnType();
  for(String method:new String[]{"getNumChasingZombies","getNumVisibleZombies","getNumVeryCloseZombies"})stats.getMethod(method);
  Class.forName("zombie.iso.IsoCell").getMethod("getZombieList");
  System.out.println("PASS 2 native intro image decodes and native threat-count/zombie-list API contracts; no game/GPU startup");
 }
}
