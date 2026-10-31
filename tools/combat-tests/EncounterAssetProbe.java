import java.nio.file.*;
import java.io.*;
public class EncounterAssetProbe {
 public static void main(String[] args)throws Exception{
  var imageType=Class.forName("zombie.core.textures.ImageData");int count=0;
  for(String name:new String[]{"EncounterEdoSZ.png","EncounterFlare.png","EncounterExplosion.png","EncounterShock.png"}){
   Object data;try(var input=Files.newInputStream(Path.of(args[0],name))){data=imageType.getConstructor(InputStream.class,boolean.class).newInstance(input,false);}
   int width=(Integer)imageType.getMethod("getWidth").invoke(data),height=(Integer)imageType.getMethod("getHeight").invoke(data);
   int expectedWidth=name.contains("Edo")?2048:name.contains("Explosion")?1024:name.contains("Shock")?256:512;
   int expectedHeight=name.contains("Explosion")?1024:name.contains("Shock")?256:512;
   if(width!=expectedWidth||height!=expectedHeight||imageType.getMethod("getData").invoke(data)==null)throw new AssertionError(name);
   imageType.getMethod("dispose").invoke(data);count++;
  }
  var player=Class.forName("zombie.characters.IsoPlayer");var stats=player.getMethod("getStats").getReturnType();
  for(String method:new String[]{"getNumChasingZombies","getNumVisibleZombies","getNumVeryCloseZombies"})stats.getMethod(method);
  Class.forName("zombie.iso.IsoCell").getMethod("getGridSquare",int.class,int.class,int.class);
  Class.forName("zombie.iso.IsoGridSquare").getMethod("getMovingObjects");
  System.out.println("PASS 4 native intro image decodes and native threat-count/grid-square API contracts; no game/GPU startup");
 }
}
