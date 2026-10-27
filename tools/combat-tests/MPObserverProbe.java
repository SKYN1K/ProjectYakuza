import java.nio.file.*;import java.util.*;import java.lang.reflect.*;import javax.xml.parsers.*;import org.w3c.dom.*;
public class MPObserverProbe {
 public static void main(String[] args)throws Exception {
  Class<?> node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode"),stateType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState"),variables=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource"),source=Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource");
  String prefix=args.length>1?args[1]:"ProjectYakuza_MP_";int expected=args.length>2?Integer.parseInt(args[2]):78;
  Method set=variables.getMethod("setVariable",String.class,String.class);int total=0;
  try(var paths=Files.walk(Path.of(args[0]))) {
   for(Path path:paths.filter(p->p.getFileName().toString().startsWith(prefix)&&p.toString().endsWith(".xml")).toList()) {
    Document doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile());
    if(doc.getElementsByTagName("m_Events").getLength()!=0)throw new AssertionError("Observer has events "+path);
    Object parsed=node.getMethod("Parse",String.class).invoke(null,path.toAbsolutePath().toString());if(parsed==null)throw new AssertionError(path);
    Object state=stateType.getConstructor().newInstance(),vars=variables.getConstructor().newInstance();stateType.getMethod("addNode",node).invoke(state,parsed);
    NodeList conditions=doc.getElementsByTagName("m_Conditions");
    for(int i=0;i<conditions.getLength();i++){Element c=(Element)conditions.item(i);set.invoke(vars,c.getElementsByTagName("m_Name").item(0).getTextContent(),c.getElementsByTagName("m_Value").item(0).getTextContent());}
    List<?> selected=(List<?>)stateType.getMethod("getAnimNodes",source,List.class).invoke(state,vars,new ArrayList<>());
    if(selected.size()!=1)throw new AssertionError("Observer not selected "+path);
    set.invoke(vars,"ProjectYakuzaRemoteClip","");selected=(List<?>)stateType.getMethod("getAnimNodes",source,List.class).invoke(state,vars,new ArrayList<>());
    if(!selected.isEmpty())throw new AssertionError("Observer leaks into native local action "+path);total++;
   }
  }
  if(total!=expected)throw new AssertionError("Unexpected observer node count "+total);
  System.out.println("PASS: "+total+" native observer nodes parse, select only for a matching remote clip and contain zero events");
 }
}
