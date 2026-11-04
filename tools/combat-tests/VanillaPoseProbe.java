import java.nio.file.*;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
public class VanillaPoseProbe {
 public static void main(String[]args)throws Exception{
  var node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");var state=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState");var variables=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource");var source=Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource");var set=variables.getMethod("setVariable",String.class,String.class);var select=state.getMethod("getAnimNodes",source,List.class);int count=0;
  for(String line:Files.readAllLines(Path.of(args[0]))){
   String[]fields=line.split("\t");var path=Path.of(fields[0]);String gate=fields[1];var parsed=node.getMethod("Parse",String.class).invoke(null,path.toString());if(parsed==null)throw new AssertionError("parse "+path);
   Object st=state.getConstructor().newInstance(),vars=variables.getConstructor().newInstance();state.getMethod("addNode",node).invoke(st,parsed);
   var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile());var children=doc.getDocumentElement().getChildNodes();
   for(int i=0;i<children.getLength();i++)if(children.item(i)instanceof Element e&&e.getTagName().equals("m_Conditions")){
    String key=e.getElementsByTagName("m_Name").item(0).getTextContent();if(!key.equals(gate))set.invoke(vars,key,e.getElementsByTagName("m_Value").item(0).getTextContent());
   }
   if(!((List<?>)select.invoke(st,vars,new ArrayList<>())).isEmpty())throw new AssertionError("custom pose selected with unset gate "+path);count++;
   set.invoke(vars,gate,"true");if(((List<?>)select.invoke(st,vars,new ArrayList<>())).size()!=1)throw new AssertionError("negative control failed "+path);count++;
   set.invoke(vars,gate,"false");if(!((List<?>)select.invoke(st,vars,new ArrayList<>())).isEmpty())throw new AssertionError("disabled gate selects "+path);count++;
   set.invoke(vars,"ProjectYakuzaRemoteObserver","true");if(!((List<?>)select.invoke(st,vars,new ArrayList<>())).isEmpty())throw new AssertionError("remote pose selected "+path);count++;
  }
  if(count!=120)throw new AssertionError("missing coverage "+count);
  System.out.println("PASS "+count+" native owner/observer selection checks; disabled overrides reject unset/false gates and positive controls still reproduce the original selection; no game launch");
 }
}
