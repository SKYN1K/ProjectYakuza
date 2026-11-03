import java.nio.file.*;
import java.io.*;
public class InputPromptAssetProbe {
 public static void main(String[]args)throws Exception{
  var type=Class.forName("zombie.core.textures.ImageData");
  for(String name:new String[]{"InputKeycap","InputMouseLeft","InputMouseRight","InputMouseMiddle"}){
   Object image;try(var stream=Files.newInputStream(Path.of(args[0]).resolve(name+".png"))){image=type.getConstructor(InputStream.class,boolean.class).newInstance(stream,false);}
   if((Integer)type.getMethod("getWidth").invoke(image)!=84||(Integer)type.getMethod("getHeight").invoke(image)!=84||type.getMethod("getData").invoke(image)==null)throw new AssertionError("native source icon "+name);
   type.getMethod("dispose").invoke(image);
  }
  var manager=Class.forName("zombie.ui.TextManager",false,ClassLoader.getSystemClassLoader());var font=Class.forName("zombie.ui.UIFont",false,ClassLoader.getSystemClassLoader());manager.getMethod("MeasureStringX",font,String.class);manager.getMethod("getFontHeight",font);
  System.out.println("PASS four original 84x84 input PNGs decode through native B42 ImageData; keyboard measurement APIs exist; no game/GPU startup");
 }
}
