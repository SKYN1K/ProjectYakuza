import java.nio.file.*;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
public class BicycleK2Probe {
 public static void main(String[]args)throws Exception{
  var type=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");var state=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState");var variables=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource");var source=Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource");var set=variables.getMethod("setVariable",String.class,String.class);int checked=0;
  try(var files=Files.walk(Path.of(args[0]))){for(var path:files.filter(p->p.toString().endsWith(".xml")&&p.getFileName().toString().matches("ProjectYakuza_DD_Bicycle(?:Light0[123]|Heavy|Ground|Idle|RelaxedIdle)\\.xml")).toList()){
   var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile());Object parsed=type.getMethod("Parse",String.class).invoke(null,path.toAbsolutePath().toString());Object st=state.getConstructor().newInstance(),vars=variables.getConstructor().newInstance();state.getMethod("addNode",type).invoke(st,parsed);var conditions=doc.getElementsByTagName("m_Conditions");
   for(int i=0;i<conditions.getLength();i++){var c=(Element)conditions.item(i);set.invoke(vars,c.getElementsByTagName("m_Name").item(0).getTextContent(),c.getElementsByTagName("m_Value").item(0).getTextContent());}
   var select=state.getMethod("getAnimNodes",source,List.class);if(((List<?>)select.invoke(st,vars,new ArrayList<>())).size()!=1)throw new AssertionError("native bicycle selector "+path);set.invoke(vars,"ProjectYakuzaWeaponProfile","crate");if(!((List<?>)select.invoke(st,vars,new ArrayList<>())).isEmpty())throw new AssertionError("bicycle selector leaked into crate "+path);checked++;
  }}
  if(checked!=8)throw new AssertionError("five attack and three hold selectors "+checked);System.out.println("PASS eight native Kiwami 2 bicycle attack/idle selectors and crate-profile isolation; no game launch");
 }
}
