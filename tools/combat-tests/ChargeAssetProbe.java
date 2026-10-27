import java.nio.file.*;import java.io.*;import javax.xml.parsers.*;import org.w3c.dom.*;
public class ChargeAssetProbe {
 public static void main(String[]args)throws Exception {
  Path media=Path.of(args[0]);Class<?> imageType=Class.forName("zombie.core.textures.ImageData");Object image;
  try(var in=Files.newInputStream(media.resolve("textures/ProjectYakuza/ChargeSpark.png"))){image=imageType.getConstructor(InputStream.class,boolean.class).newInstance(in,false);}
  if((Integer)imageType.getMethod("getWidth").invoke(image)!=16||(Integer)imageType.getMethod("getHeight").invoke(image)!=32)throw new AssertionError("original particle size");
  if(imageType.getMethod("getData").invoke(image)==null)throw new AssertionError("particle decode");imageType.getMethod("dispose").invoke(image);
  Class<?> node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");
  var paths=new java.util.ArrayList<String>();paths.add("actions/ProjectYakuza_DD_ChargeLoop.xml");paths.add("melee/ProjectYakuza_DD_ChargeEnd.xml");
  for(int i=1;i<=4;i++){paths.add("actions/ProjectYakuza_DD_ChargeWindup0"+i+".xml");paths.add("melee/ProjectYakuza_DD_ChargedFinisher0"+i+".xml");}
  for(String path:paths) {
   Path p=media.resolve("AnimSets/player").resolve(path);Document d=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(p.toFile());
   if(node.getMethod("Parse",String.class).invoke(null,p.toAbsolutePath().toString())==null)throw new AssertionError("node parse");
   int collisions=0;var events=d.getElementsByTagName("m_Events");
   for(int i=0;i<events.getLength();i++){var e=(Element)events.item(i);if(e.getElementsByTagName("m_EventName").item(0).getTextContent().equals("AttackCollisionCheck"))collisions++;}
   if(collisions!=(path.startsWith("melee")?1:0))throw new AssertionError("collision count "+path);
  }
  System.out.println("PASS original 16x32 spark native decode; 10 native charge nodes parse, every release has one collision and all holds have zero");
 }
}
