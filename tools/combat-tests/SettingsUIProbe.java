import java.nio.file.*;
import java.io.*;
public class SettingsUIProbe {
 public static void main(String[]args)throws Exception{
  var type=Class.forName("zombie.core.textures.ImageData");Object image;
  try(var stream=Files.newInputStream(Path.of(args[0]))){image=type.getConstructor(InputStream.class,boolean.class).newInstance(stream,false);}
  if((Integer)type.getMethod("getWidth").invoke(image)!=1024||(Integer)type.getMethod("getHeight").invoke(image)!=512||type.getMethod("getData").invoke(image)==null)throw new AssertionError("settings background decode");
  type.getMethod("dispose").invoke(image);
  System.out.println("PASS original Kiwami background decoded through B42 ImageData; no game launch");
 }
}
