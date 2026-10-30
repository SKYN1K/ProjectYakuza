import java.nio.file.*;
import java.io.*;
public class BloodAssetProbe {
 public static void main(String[] args)throws Exception{
  var type=Class.forName("zombie.core.textures.ImageData");
  for(int i=0;i<16;i++){
   var path=Path.of(args[0],"Blood_splash_"+i+".png");Object image;
   try(var stream=Files.newInputStream(path)){image=type.getConstructor(InputStream.class,boolean.class).newInstance(stream,false);}
   if((Integer)type.getMethod("getWidth").invoke(image)!=128||(Integer)type.getMethod("getHeight").invoke(image)!=128)throw new AssertionError(path);
   if(type.getMethod("getData").invoke(image)==null)throw new AssertionError("native decode "+path);
   type.getMethod("dispose").invoke(image);
  }
  System.out.println("PASS 16 original-size blood frames decode through native B42 ImageData without game/GPU startup");
 }
}
