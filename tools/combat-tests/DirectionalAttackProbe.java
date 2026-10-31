import java.nio.file.*;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
public class DirectionalAttackProbe {
 public static void main(String[] args)throws Exception{
  var node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");
  var stateType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState");
  var variables=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource");
  var source=Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource");
  var set=variables.getMethod("setVariable",String.class,String.class);int count=0;
  try(var files=Files.walk(Path.of(args[0]))){for(var path:files.filter(p->p.getFileName().toString().startsWith("ProjectYakuza_DD_Directional")&&p.toString().endsWith(".xml")).toList()){
   var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile());
   var parsed=node.getMethod("Parse",String.class).invoke(null,path.toAbsolutePath().toString());
   Object state=stateType.getConstructor().newInstance(),vars=variables.getConstructor().newInstance();stateType.getMethod("addNode",node).invoke(state,parsed);
   var conditions=doc.getElementsByTagName("m_Conditions");
   for(int i=0;i<conditions.getLength();i++){var c=(Element)conditions.item(i);set.invoke(vars,c.getElementsByTagName("m_Name").item(0).getTextContent(),c.getElementsByTagName("m_Value").item(0).getTextContent());}
   var select=stateType.getMethod("getAnimNodes",source,List.class);
   if(((List)select.invoke(state,vars,new ArrayList<>())).size()!=1)throw new AssertionError("owner selection "+path);
   set.invoke(vars,"ProjectYakuzaStyle","another.style");if(!((List)select.invoke(state,vars,new ArrayList<>())).isEmpty())throw new AssertionError("style leak "+path);
   set.invoke(vars,"ProjectYakuzaStyle","dragon_of_dojima");set.invoke(vars,"ProjectYakuzaWeaponProfile","bat");
   if(!((List)select.invoke(state,vars,new ArrayList<>())).isEmpty())throw new AssertionError("weapon leak "+path);
   var events=doc.getElementsByTagName("m_EventName");int hits=0;
   for(int i=0;i<events.getLength();i++)if(events.item(i).getTextContent().equals("AttackCollisionCheck"))hits++;
   if(hits!=1)throw new AssertionError("collision count "+path);count++;
  }}
  if(count!=3)throw new AssertionError("owner count "+count);
  var zombie=Class.forName("zombie.characters.IsoZombie");zombie.getMethod("addAggro",Class.forName("zombie.iso.IsoMovingObject"),float.class);zombie.getMethod("setTarget",Class.forName("zombie.iso.IsoMovingObject"));zombie.getMethod("isRemoteZombie");zombie.getMethod("isAttacking");zombie.getMethod("isUseless");
  System.out.println("PASS 3 native directional owners, one collision each, style/weapon isolation and native taunt AI API");
 }
}
