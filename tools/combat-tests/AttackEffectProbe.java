import java.nio.file.*;
import java.io.*;
public class AttackEffectProbe {
 public static void main(String[]args)throws Exception{
  var type=Class.forName("zombie.core.textures.ImageData");int total=0;
  for(String name:args){
   var path=Path.of(name);Object image;try(var input=Files.newInputStream(path)){image=type.getConstructor(InputStream.class,boolean.class).newInstance(input,false);}
   int width=(Integer)type.getMethod("getWidth").invoke(image),height=(Integer)type.getMethod("getHeight").invoke(image);var png=javax.imageio.ImageIO.read(path.toFile());
   if(width!=png.getWidth()||height!=png.getHeight())throw new AssertionError("native dimensions "+path);
   Object wrapped=type.getMethod("getData").invoke(image);var pixels=(java.nio.ByteBuffer)wrapped.getClass().getMethod("getBuffer").invoke(wrapped);
   for(int y=0;y<height;y++)for(int x=0;x<width;x++){
    int argb=png.getRGB(x,y),offset=(y*width+x)*4;int[] expected={(argb>>>16)&255,(argb>>>8)&255,argb&255,(argb>>>24)&255};
    for(int c=0;c<4;c++)if(Byte.toUnsignedInt(pixels.get(offset+c))!=expected[c])throw new AssertionError("native orientation/channel "+path+" "+x+","+y);
   }
   total+=width*height;type.getMethod("dispose").invoke(image);
  }
  var player=Class.forName("zombie.characters.IsoPlayer");for(String method:new String[]{"dbgGetAnimTrackTime","dbgGetAnimTrackWeight","dbgGetAnimTrackName"})player.getMethod(method,int.class,int.class);
  player.getMethod("getAnimAngleRadians");
  System.out.println("PASS native ImageData dimensions, orientation and all RGBA channels for "+args.length+" original textures / "+total+" pixels; native clock/facing API available; no game launch");
 }
}
