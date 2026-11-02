import java.nio.file.*;
import java.io.*;
public class HeatPromptAssetProbe {
 public static void main(String[]args)throws Exception {
  var c=Class.forName("zombie.core.textures.ImageData");Object image;
  try(var input=Files.newInputStream(Path.of(args[0]))){image=c.getConstructor(InputStream.class,boolean.class).newInstance(input,false);}
  if((Integer)c.getMethod("getWidth").invoke(image)!=128||(Integer)c.getMethod("getHeight").invoke(image)!=128||c.getMethod("getData").invoke(image)==null)throw new AssertionError("original supplied prompt dimensions/pixels");
  c.getMethod("dispose").invoke(image);
  if(args.length>1){
   try(var input=Files.newInputStream(Path.of(args[1]))){image=c.getConstructor(InputStream.class,boolean.class).newInstance(input,false);}
   if((Integer)c.getMethod("getWidth").invoke(image)!=256||(Integer)c.getMethod("getHeight").invoke(image)!=256||c.getMethod("getData").invoke(image)==null)throw new AssertionError("original QTE ring dimensions/pixels");
   c.getMethod("dispose").invoke(image);
   var signature=new Class<?>[13];signature[0]=Class.forName("zombie.core.textures.Texture");java.util.Arrays.fill(signature,1,13,float.class);
   Class.forName("zombie.core.SpriteRenderer").getMethod("renderPoly",signature);
   Class.forName("zombie.core.SpriteRenderer").getField("instance");
   Class.forName("zombie.ui.UIElement").getMethod("getAbsoluteX");Class.forName("zombie.ui.UIElement").getMethod("getAbsoluteY");
   System.out.println("PASS native 256x256 QTE ImageData and textured quad renderer/screen coordinate APIs");
  }
  System.out.println("PASS supplied 128x128 Y6 flame atlas decodes through native B42 ImageData without resizing or generated artwork");
 }
}
