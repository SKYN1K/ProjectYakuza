import java.nio.file.*;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
public class WeaponMotionProbe {
 public static void main(String[]args)throws Exception{
  var node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");var state=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState");var variables=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource");var source=Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource");var set=variables.getMethod("setVariable",String.class,String.class);var select=state.getMethod("getAnimNodes",source,List.class);int checks=0;
  try(var files=Files.walk(Path.of(args[0]).resolve("AnimSets/player"))){for(var path:files.filter(p->p.getFileName().toString().matches("ProjectYakuza_DD_(Locomotion.*|Bottle.*|Crate.*|BatIdle|BladeIdle)\\.xml")).toList()){
   var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile());var parsed=node.getMethod("Parse",String.class).invoke(null,path.toString());if(parsed==null)throw new AssertionError("parse "+path);Object st=state.getConstructor().newInstance(),vars=variables.getConstructor().newInstance();state.getMethod("addNode",node).invoke(st,parsed);var conditions=new ArrayList<Element>();var children=doc.getDocumentElement().getChildNodes();for(int i=0;i<children.getLength();i++)if(children.item(i) instanceof Element e&&e.getTagName().equals("m_Conditions"))conditions.add(e);
   for(int i=0;i<conditions.size();i++){var c=conditions.get(i);set.invoke(vars,c.getElementsByTagName("m_Name").item(0).getTextContent(),c.getElementsByTagName("m_Value").item(0).getTextContent());}
   if(((List<?>)select.invoke(st,vars,new ArrayList<>())).size()!=1)throw new AssertionError("selection "+path);checks++;
   for(String[] reject:new String[][]{{"ProjectYakuzaStyle","other.style"},{"ProjectYakuzaWeaponProfile","unsupported"}}){
    String old="";for(int i=0;i<conditions.size();i++){var c=conditions.get(i);if(c.getElementsByTagName("m_Name").item(0).getTextContent().equals(reject[0]))old=c.getElementsByTagName("m_Value").item(0).getTextContent();}set.invoke(vars,reject[0],reject[1]);if(!((List<?>)select.invoke(st,vars,new ArrayList<>())).isEmpty())throw new AssertionError("scope "+path);set.invoke(vars,reject[0],old);checks++;
   }
   if(path.getParent().getFileName().toString().equals("movement")){float blend=Float.parseFloat(doc.getElementsByTagName("m_BlendTime").item(0).getTextContent());if(blend<.25f)throw new AssertionError("walking blend "+path);}
  }}
  if(checks<130)throw new AssertionError("missing selectors "+checks);System.out.println("PASS "+checks+" native weapon/locomotion selector, style/profile isolation and walking blend checks; no game/GPU startup");
 }
}
