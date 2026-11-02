import java.nio.file.*;
import java.io.*;
public class HeatPromptAssetProbe {
 public static void main(String[]args)throws Exception {
  var c=Class.forName("zombie.core.textures.ImageData");Object image;
  try(var input=Files.newInputStream(Path.of(args[0]))){image=c.getConstructor(InputStream.class,boolean.class).newInstance(input,false);}
  if((Integer)c.getMethod("getWidth").invoke(image)!=128||(Integer)c.getMethod("getHeight").invoke(image)!=128||c.getMethod("getData").invoke(image)==null)throw new AssertionError("original supplied prompt dimensions/pixels");
  c.getMethod("dispose").invoke(image);System.out.println("PASS supplied 128x128 Y6 flame atlas decodes through native B42 ImageData without resizing or generated artwork");
 }
}
