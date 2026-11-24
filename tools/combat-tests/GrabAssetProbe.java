import java.nio.file.*;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
public class GrabAssetProbe {
 public static void main(String[]args)throws Exception{
  var actor=Class.forName("zombie.characters.IsoGameCharacter");actor.getMethod("setStateMachineLocked",boolean.class);actor.getMethod("getCurrentStateName");actor.getMethod("setIsAiming",boolean.class);Class.forName("zombie.characters.IsoPlayer").getMethod("isAimControlActive");var player=Class.forName("zombie.characters.IsoPlayer");for(String name:new String[]{"isForceAim","isAllowRun","isAllowSprint"})player.getMethod(name);for(String name:new String[]{"setForceAim","setAllowRun","setAllowSprint"})player.getMethod(name,boolean.class);
  try(var source=Files.walk(Path.of(args[0]).toAbsolutePath().getParent().resolve("lua"))){for(var file:source.filter(p->p.toString().endsWith(".lua")).toList())if(Files.readString(file).contains(":getStateMachine("))throw new AssertionError("unexposed native state-machine getter "+file);}
  var uv=new Class<?>[21];uv[0]=Class.forName("zombie.core.textures.Texture");Arrays.fill(uv,1,21,float.class);Class.forName("zombie.core.SpriteRenderer").getMethod("renderPoly",uv);Class.forName("zombie.characters.BodyDamage.BodyDamage").getMethod("getOverallBodyHealth");
  var square=Class.forName("zombie.iso.IsoGridSquare");for(String name:new String[]{"isWallTo","isWindowTo","isDoorTo"})square.getMethod(name,square);
  var node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");var state=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState");var variables=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource");var source=Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource");var set=variables.getMethod("setVariable",String.class,String.class);var select=state.getMethod("getAnimNodes",source,List.class);int count=0;
  try(var files=Files.walk(Path.of(args[0]))){for(var path:files.filter(p->(p.getFileName().toString().contains("GrabAttempt")||p.getFileName().toString().contains("GrabHold")||p.getFileName().toString().contains("GrabWalk")||p.getFileName().toString().contains("GrabEscape")||p.getFileName().toString().contains("CrateHeat")||p.getFileName().toString().contains("GrabStrike")||p.getFileName().toString().contains("WallHeat")||p.getFileName().toString().contains("GroundHeat"))&&p.toString().endsWith(".xml")).toList()){
   var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile());Object parsed=node.getMethod("Parse",String.class).invoke(null,path.toString()),st=state.getConstructor().newInstance(),vars=variables.getConstructor().newInstance();state.getMethod("addNode",node).invoke(st,parsed);
   String reject=null;var conditions=doc.getElementsByTagName("m_Conditions");for(int i=0;i<conditions.getLength();i++){
    var c=(Element)conditions.item(i);String key=c.getElementsByTagName("m_Name").item(0).getTextContent(),value=c.getElementsByTagName("m_Value").item(0).getTextContent();set.invoke(vars,key,value);
    if(key.equals("ProjectYakuzaDefensePhase")||key.equals("ProjectYakuzaGrabPhase")||key.equals("ProjectYakuzaPairedVictimClip")||key.equals("ProjectYakuzaRemoteClip")||key.equals("PerformingAction"))reject=key;
   }
   if(((List<?>)select.invoke(st,vars,new ArrayList<>())).size()!=1)throw new AssertionError("native selection "+path);
   if(reject==null)throw new AssertionError("unscoped pair "+path);set.invoke(vars,reject,"unrelated.clip");if(!((List<?>)select.invoke(st,vars,new ArrayList<>())).isEmpty())throw new AssertionError("pair leakage "+path);
   var events=doc.getElementsByTagName("m_EventName");for(int i=0;i<events.getLength();i++)if(events.item(i).getTextContent().equals("AttackCollisionCheck"))throw new AssertionError("duplicate native collision "+path);count++;
  }}
  if(count<30)throw new AssertionError("missing paired selectors "+count);
  System.out.println("PASS "+count+" native grab/wall owner, victim and observer selectors; phase isolation; no duplicate collision events; native AI latch and solid-wall APIs; no game launch");
 }
}

