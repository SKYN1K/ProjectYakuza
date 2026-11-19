import java.nio.file.*;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
public class RecoverySelectionProbe {
 static Class<?> node,stateType,variables,source;
 static Object state,vars;
 static java.lang.reflect.Method set,select;
 static void value(String name,String value)throws Exception{set.invoke(vars,name,value);}
 static Object add(Path path,boolean populate)throws Exception{
  var parsed=node.getMethod("Parse",String.class).invoke(null,path.toAbsolutePath().toString());if(parsed==null)throw new AssertionError("parse "+path);
  stateType.getMethod("addNode",node).invoke(state,parsed);
  if(populate){var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile());var children=doc.getDocumentElement().getChildNodes();for(int i=0;i<children.getLength();i++)if(children.item(i)instanceof Element e&&e.getTagName().equals("m_Conditions"))value(e.getElementsByTagName("m_Name").item(0).getTextContent(),e.getElementsByTagName("m_Value").item(0).getTextContent());}
  return parsed;
 }
 static List<?> selected()throws Exception{return (List<?>)select.invoke(state,vars,new ArrayList<>());}
 public static void main(String[]a)throws Exception{
  node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");stateType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState");variables=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource");source=Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource");set=variables.getMethod("setVariable",String.class,String.class);select=stateType.getMethod("getAnimNodes",source,List.class);int count=0;
  for(int branch=1;branch<=4;branch++){
   state=stateType.getConstructor().newInstance();vars=variables.getConstructor().newInstance();Object own=add(Path.of(a[0],"AnimSets/player/melee/ProjectYakuza_DD_ReverseDoubleFinisher0"+branch+".xml"),true);
   for(String linked:new String[]{"false","true"}){value("ProjectYakuzaLinkedDouble",linked);var rows=selected();if(rows.size()!=1||rows.get(0)!=own)throw new AssertionError("reverse double owner "+branch+" "+linked);count++;}
   value("ProjectYakuzaStyle","other");if(!selected().isEmpty())throw new AssertionError("style leak");count++;
   value("ProjectYakuzaStyle","dragon_of_dojima");value("ProjectYakuzaWeaponProfile","bat");if(!selected().isEmpty())throw new AssertionError("weapon leak");count++;
  }
  state=stateType.getConstructor().newInstance();vars=variables.getConstructor().newInstance();Object nativeRun=add(Path.of(a[1],"media/AnimSets/player/run/defaultRun.xml"),true);Object own=add(Path.of(a[0],"AnimSets/player/run/ProjectYakuza_DD_LocomotionRun.xml"),true);
  for(String rested:new String[]{"false","true"}){value("ProjectYakuzaRestedRun",rested);var rows=selected();if(rows.size()!=1||rows.get(0)!=(rested.equals("true")?own:nativeRun))throw new AssertionError("exhausted native run selection "+rested+" "+rows.size());count++;}
  System.out.println("PASS "+count+" native reverse-double linked/unlinked owners, isolation and rested/exhausted run selection contracts; no game launch");
 }
}
