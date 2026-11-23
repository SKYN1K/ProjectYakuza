import java.nio.file.*;
import javax.xml.parsers.*;
public class NativeRushTimingProbe {
 public static void main(String[]args)throws Exception{
  var node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");int count=0;
  int[] rushFrames={9,13,16,15},rushEnds={30,47,42,47};
  for(int branch=1;branch<=4;branch++){
   var path=Path.of(args[0],"player/melee/ProjectYakuza_DD_Light0"+branch+".xml");
   var parsed=node.getMethod("Parse",String.class).invoke(null,path.toAbsolutePath().toString());if(parsed==null)throw new AssertionError("rush node parse "+branch);
   var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile());var events=doc.getElementsByTagName("m_Events");double collision=-1,chain=-1;int hits=0;
   for(int i=0;i<events.getLength();i++){var e=(org.w3c.dom.Element)events.item(i);var name=e.getElementsByTagName("m_EventName").item(0).getTextContent();var parameter=e.getElementsByTagName("m_ParameterValue").item(0).getTextContent();if(name.equals("AttackCollisionCheck")){collision=Double.parseDouble(e.getElementsByTagName("m_TimePc").item(0).getTextContent());hits++;}if(parameter.equals("ProjectYakuzaChainReady=dd_light_0"+branch))chain=Double.parseDouble(e.getElementsByTagName("m_TimePc").item(0).getTextContent());}
   if(hits!=1||chain<=collision||Math.abs(chain-(double)rushFrames[branch-1]/rushEnds[branch-1])>1e-12||!"ProjectYakuzaCombatSpeed".equals(node.getField("speedScale").get(parsed)))throw new AssertionError("rush recovery contract "+branch);
  }
  var player=Class.forName("zombie.characters.IsoPlayer");player.getMethod("setAuthorizeShoveStomp",boolean.class);player.getMethod("isAuthorizeShoveStomp");
  System.out.println("PASS four native normal rush nodes use per-clip post-collision recovery frames, original playback and one collision; separate native shove permission available");
  try(var files=Files.walk(Path.of(args[0]))){for(var path:files.filter(p->p.toString().endsWith(".xml")).toList()){
   var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile());var names=doc.getElementsByTagName("m_AnimName");if(names.getLength()==0)continue;var name=names.item(0).getTextContent();if(!name.equals("ProjectYakuza_DD_HeatRush")&&!name.equals("ProjectYakuza_DD_HeatRushVictim"))continue;
   Object parsed=node.getMethod("Parse",String.class).invoke(null,path.toString());if(!"1".equals(node.getField("speedScale").get(parsed)))throw new AssertionError(path);count++;
  }}
  int endings=0;
  var stateType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState");var variables=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource");var source=Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource");var set=variables.getMethod("setVariable",String.class,String.class);
  try(var files=Files.walk(Path.of(args[0]))){for(var path:files.filter(p->p.toString().endsWith(".xml")).toList()){
   var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile());var names=doc.getElementsByTagName("m_AnimName");if(names.getLength()==0||!names.item(0).getTextContent().equals("ProjectYakuza_DD_HeatRushFailVictim"))continue;
   Object parsed=node.getMethod("Parse",String.class).invoke(null,path.toString());var state=stateType.getConstructor().newInstance();var vars=variables.getConstructor().newInstance();stateType.getMethod("addNode",node).invoke(state,parsed);
   var conditions=doc.getElementsByTagName("m_Conditions");for(int i=0;i<conditions.getLength();i++){var c=(org.w3c.dom.Element)conditions.item(i);set.invoke(vars,c.getElementsByTagName("m_Name").item(0).getTextContent(),c.getElementsByTagName("m_Value").item(0).getTextContent());}
   var select=stateType.getMethod("getAnimNodes",source,java.util.List.class);if(((java.util.List)select.invoke(state,vars,new java.util.ArrayList<>())).size()!=1)throw new AssertionError(path);
   set.invoke(vars,"ProjectYakuzaPairedVictimClip","unrelated.clip");if(!((java.util.List)select.invoke(state,vars,new java.util.ArrayList<>())).isEmpty())throw new AssertionError(path);endings++;
  }}
  if(endings!=8)throw new AssertionError(endings);
  System.out.println("PASS eight native paired-kick victim selectors require their exact clip in zombie/PvP states");
  Class.forName("zombie.characters.IsoGameCharacter").getMethod("isFallOnFront");if(count!=13)throw new AssertionError(count);
  System.out.println("PASS "+count+" original actor/victim/observer nodes preserve original 1x playback; native face-up posture API exists; no game launch");
 }
}
