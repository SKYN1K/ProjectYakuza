import java.nio.file.*;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
public class BottleHeatProbe {
 public static void main(String[]args)throws Exception {
  var node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");
  var state=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState");
  var variables=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource");
  var source=Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource");
  var set=variables.getMethod("setVariable",String.class,String.class);var select=state.getMethod("getAnimNodes",source,List.class);int count=0;
  try(var files=Files.walk(Path.of(args[0]))){for(var path:files.filter(p->p.getFileName().toString().contains("BottleHeat")&&p.toString().endsWith(".xml")).toList()){
   var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile());
   var parsed=node.getMethod("Parse",String.class).invoke(null,path.toAbsolutePath().toString());Object st=state.getConstructor().newInstance(),vars=variables.getConstructor().newInstance();state.getMethod("addNode",node).invoke(st,parsed);
   var conditions=doc.getElementsByTagName("m_Conditions");
   for(int i=0;i<conditions.getLength();i++){var c=(Element)conditions.item(i);set.invoke(vars,c.getElementsByTagName("m_Name").item(0).getTextContent(),c.getElementsByTagName("m_Value").item(0).getTextContent());}
   if(((List<?>)select.invoke(st,vars,new ArrayList<>())).size()!=1)throw new AssertionError("selection "+path);
   boolean victim=path.getFileName().toString().contains("Victim");
   boolean observer=path.getFileName().toString().startsWith("ProjectYakuza_MP_");
   set.invoke(vars,victim?"ProjectYakuzaPairedVictimClip":observer?"ProjectYakuzaRemoteClip":"ProjectYakuzaStyle",victim?"ProjectYakuza_DD_HeatRushVictim":observer?"another.clip":"another.style");
   if(!((List<?>)select.invoke(st,vars,new ArrayList<>())).isEmpty())throw new AssertionError("cross-selection "+path);
   var names=doc.getElementsByTagName("m_EventName");for(int i=0;i<names.getLength();i++)if(names.item(i).getTextContent().equals("AttackCollisionCheck"))throw new AssertionError("native collision duplicate "+path);
   count++;
  }}
  if(count!=8)throw new AssertionError("node count "+count);
  var actor=Class.forName("zombie.characters.IsoGameCharacter");actor.getMethod("isInvincible");Class.forName("zombie.characters.IsoPlayer").getMethod("isGhostMode");actor.getMethod("setInvincible",boolean.class);Class.forName("zombie.characters.IsoPlayer").getMethod("setGhostMode",boolean.class);
  System.out.println("PASS 8 native bottle owner/victim/observer nodes, original victim isolation, event-free observer contacts and native protection APIs");
 }
}
