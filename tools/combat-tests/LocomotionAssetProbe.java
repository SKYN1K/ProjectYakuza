import jassimp.*;
import java.util.*;import java.nio.file.*;import java.lang.reflect.*;import javax.xml.parsers.*;import org.w3c.dom.*;

public class LocomotionAssetProbe {
 static Object field(Object o,String n)throws Exception{var f=o.getClass().getDeclaredField(n);f.setAccessible(true);return f.get(o);}
 public static void main(String[]args)throws Exception{
  Path media=Path.of(args[0]);
  Jassimp.setLibraryLoader(new JassimpLibraryLoader(){public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}});
  Class<?> pt=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiSceneParams"),processed=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiScene");
  Class mode=(Class)Class.forName("zombie.core.skinnedmodel.model.jassimp.JAssImpImporter$LoadMode");
  var names=new ArrayList<String>();
  for(String family:new String[]{"","Bat","Knife","Blade"})names.add("ProjectYakuza_DD_"+family+"Run");
  for(String family:new String[]{"Bat","Knife","Blade"})for(String kind:new String[]{"Carry","CarryWalk","CarrySlow"})names.add("ProjectYakuza_DD_"+family+kind);
  int samples=0;
  for(String name:names){
   AiScene scene=Jassimp.importFile(media.resolve("anims_X/Bob/"+name+".x").toString(),EnumSet.of(AiPostProcessSteps.MAKE_LEFT_HANDED,AiPostProcessSteps.REMOVE_REDUNDANT_MATERIALS));
   Object params=pt.getMethod("create").invoke(null);pt.getField("scene").set(params,scene);pt.getField("mode").set(params,Enum.valueOf(mode,"AnimationOnly"));
   var sk=field(processed.getMethod("process",pt).invoke(null,params),"skeleton");var clips=(Map)field(sk,"clips");
   if(clips.size()!=1||!clips.containsKey(name))throw new AssertionError("clip name "+name);
   var clip=clips.get(name);Class<?> ct=clip.getClass();float duration=(Float)ct.getMethod("getDuration").invoke(clip);
   if(!Float.isFinite(duration)||duration<=0)throw new AssertionError("duration");
   var indices=(Map)field(sk,"boneIndices");if(indices.size()!=(name.endsWith("Carry")?35:45))throw new AssertionError("B42 skeleton "+name+" "+indices.size()+" "+indices.keySet());
   if(name.endsWith("Run")||name.endsWith("CarryWalk")||name.endsWith("CarrySlow")){
    Object[] movement=(Object[])ct.getMethod("getBoneFramesAt",int.class).invoke(clip,indices.get("Translation_Data"));
    var first=movement[0].getClass().getField("position").get(movement[0]);var last=movement[movement.length-1].getClass().getField("position").get(movement[movement.length-1]);float distance=0;
    for(String component:new String[]{"x","y","z"}){float delta=last.getClass().getField(component).getFloat(last)-first.getClass().getField(component).getFloat(first);distance+=delta*delta;}
    if(distance<.01f)throw new AssertionError("missing native deferred movement "+name+" first="+first+" last="+last);
   }
   int expected=Math.round(duration*30)+1;
   for(Object idx:indices.values()){
    Object[] keys=(Object[])ct.getMethod("getBoneFramesAt",int.class).invoke(clip,idx);
    if(keys==null||keys.length!=expected)throw new AssertionError("source frame count "+name);
    for(Object key:keys){
     var kc=key.getClass();float time=kc.getField("time").getFloat(key);if(!Float.isFinite(time))throw new AssertionError("time");
     for(String part:new String[]{"position","rotation","scale"}){
      var value=kc.getField(part).get(key);for(String c:part.equals("rotation")?new String[]{"x","y","z","w"}:new String[]{"x","y","z"}){
       float f=value.getClass().getField(c).getFloat(value);if(!Float.isFinite(f))throw new AssertionError("nonfinite pose");
      }
     }samples++;
    }
   }
  }
  var node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");var stateType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState");
  var varsType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource");var source=Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource");
  var set=varsType.getMethod("setVariable",String.class,String.class);var method=stateType.getMethod("getAnimNodes",source,List.class);int tests=0,nodes=0;
  for(String group:new String[]{"run","idle","movement"}){
   var state=stateType.getConstructor().newInstance();var paths=new ArrayList<Path>();
   try(var stream=Files.list(media.resolve("AnimSets/player/"+group))){paths.addAll(stream.filter(x->x.getFileName().toString().startsWith("ProjectYakuza_DD_Locomotion")).toList());}
   for(Path p:paths){Object parsed=node.getMethod("Parse",String.class).invoke(null,p.toAbsolutePath().toString());if(parsed==null)throw new AssertionError("parse");stateType.getMethod("addNode",node).invoke(state,parsed);nodes++;}
   for(Path p:paths){
    var vars=varsType.getConstructor().newInstance();var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(p.toFile());var conditions=new ArrayList<Element>();var children=doc.getDocumentElement().getChildNodes();for(int ci=0;ci<children.getLength();ci++)if(children.item(ci) instanceof Element e&&e.getTagName().equals("m_Conditions"))conditions.add(e);
    for(int i=0;i<conditions.size();i++){var c=conditions.get(i);set.invoke(vars,c.getElementsByTagName("m_Name").item(0).getTextContent(),c.getElementsByTagName("m_Value").item(0).getTextContent());}
    if(((List)method.invoke(state,vars,new ArrayList<>())).size()!=1)throw new AssertionError("selector "+p);tests++;
    String[][] reject={{"ProjectYakuzaStyle","another.style"},{"ProjectYakuzaActive","false"},{"Aim","true"},{"WalkInjury","0.5"},{"inTrees","true"},{"isTurningAround","true"},{"isOverEncumbered","true"},{"ProjectYakuzaWeaponProfile","unsupported"},{"sneaking","true"}};
    for(String[] r:reject){String original="";for(int i=0;i<conditions.size();i++){var c=conditions.get(i);if(c.getElementsByTagName("m_Name").item(0).getTextContent().equals(r[0]))original=c.getElementsByTagName("m_Value").item(0).getTextContent();}set.invoke(vars,r[0],r[1]);if(!((List)method.invoke(state,vars,new ArrayList<>())).isEmpty())throw new AssertionError("fallback "+p+" "+r[0]);set.invoke(vars,r[0],original);tests++;}
   }
  }
  if(nodes!=10)throw new AssertionError("node count "+nodes);
  System.out.println("PASS 13 native locomotion clips / "+samples+" finite bone samples and "+tests+" native selector/fallback contracts across 10 nodes; no game/GPU startup");
 }
}
