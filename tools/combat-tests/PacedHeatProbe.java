import java.nio.file.*;
import javax.xml.parsers.*;
public class PacedHeatProbe {
 public static void main(String[]args)throws Exception{
  var node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");int count=0;
  try(var files=Files.walk(Path.of(args[0]))){for(var path:files.filter(p->p.toString().endsWith(".xml")).toList()){
   var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile());var names=doc.getElementsByTagName("m_AnimName");if(names.getLength()==0)continue;var name=names.item(0).getTextContent();if(!name.equals("ProjectYakuza_DD_HeatRush")&&!name.equals("ProjectYakuza_DD_HeatRushVictim"))continue;
   Object parsed=node.getMethod("Parse",String.class).invoke(null,path.toString());if(!"ProjectYakuzaHeatRushSpeed".equals(node.getField("speedScaleVariable").get(parsed)))throw new AssertionError(path);count++;
  }}
  Class.forName("zombie.characters.IsoGameCharacter").getMethod("isFallOnFront");if(count!=10)throw new AssertionError(count);
  System.out.println("PASS "+count+" original actor/victim/observer nodes resolve the paced speed variable; native face-up posture API exists; no game launch");
 }
}
