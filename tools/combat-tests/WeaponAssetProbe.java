import jassimp.*;
import java.util.*;import java.nio.file.*;import java.lang.reflect.*;import javax.xml.parsers.*;import org.w3c.dom.*;
/** Offline native importer/selector checks. Does not start Project Zomboid or create a GL context. */
public class WeaponAssetProbe {
 static Object field(Object o,String n)throws Exception{var f=o.getClass().getDeclaredField(n);f.setAccessible(true);return f.get(o);}
 public static void main(String[]args)throws Exception{
  Path media=Path.of(args[0]);
  Jassimp.setLibraryLoader(new JassimpLibraryLoader(){public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}});
  Class<?> pt=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiSceneParams"),processed=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiScene");
  Class mode=(Class)Class.forName("zombie.core.skinnedmodel.model.jassimp.JAssImpImporter$LoadMode");
  String[] labels={"Light01","Light02","Light03","Heavy","Ground","Idle","GuardEnter","GuardLoop","GuardHit","GuardExit"};
  int samples=0;
  for(String label:labels){
   String name="ProjectYakuza_DD_Bat"+label;
   AiScene scene=Jassimp.importFile(media.resolve("anims_X/Bob/"+name+".x").toString(),EnumSet.of(AiPostProcessSteps.MAKE_LEFT_HANDED,AiPostProcessSteps.REMOVE_REDUNDANT_MATERIALS));
   Object params=pt.getMethod("create").invoke(null);pt.getField("scene").set(params,scene);pt.getField("mode").set(params,Enum.valueOf(mode,"AnimationOnly"));
   var sk=field(processed.getMethod("process",pt).invoke(null,params),"skeleton");var clips=(Map)field(sk,"clips");
   if(clips.size()!=1||!clips.containsKey(name))throw new AssertionError("clip name "+name);
   var clip=clips.get(name);Class<?> ct=clip.getClass();float duration=(Float)ct.getMethod("getDuration").invoke(clip);
   if(!Float.isFinite(duration)||duration<=0)throw new AssertionError("duration");
   var indices=(Map)field(sk,"boneIndices");if(indices.size()!=35)throw new AssertionError("B42 skeleton");
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
  var set=varsType.getMethod("setVariable",String.class,String.class);int nodes=0;
  try(var files=Files.walk(media.resolve("AnimSets/player"))){for(Path p:files.filter(x->x.getFileName().toString().startsWith("ProjectYakuza_DD_Bat")&&x.toString().endsWith(".xml")).toList()){
   var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(p.toFile());Object parsed=node.getMethod("Parse",String.class).invoke(null,p.toAbsolutePath().toString());
   var state=stateType.getConstructor().newInstance();stateType.getMethod("addNode",node).invoke(state,parsed);var vars=varsType.getConstructor().newInstance();
   var conditions=doc.getElementsByTagName("m_Conditions");for(int i=0;i<conditions.getLength();i++){
    var c=(Element)conditions.item(i);set.invoke(vars,c.getElementsByTagName("m_Name").item(0).getTextContent(),c.getElementsByTagName("m_Value").item(0).getTextContent());
   }
   var method=stateType.getMethod("getAnimNodes",source,List.class);
   if(((List)method.invoke(state,vars,new ArrayList<>())).size()!=1)throw new AssertionError("owner selector "+p);
   set.invoke(vars,"ProjectYakuzaStyle","other.style");if(!((List)method.invoke(state,vars,new ArrayList<>())).isEmpty())throw new AssertionError("style leak");
   set.invoke(vars,"ProjectYakuzaStyle","dragon_of_dojima");set.invoke(vars,"ProjectYakuzaWeaponProfile","");
   if(!((List)method.invoke(state,vars,new ArrayList<>())).isEmpty())throw new AssertionError("unarmed leak");nodes++;
  }}
  if(nodes!=12)throw new AssertionError("owner count "+nodes);
  var hand=Class.forName("zombie.inventory.types.HandWeapon");for(String n:new String[]{"getCondition","isTwoHandWeapon","getMaxRange","getMinDamage","getMaxDamage"})hand.getMethod(n);
  System.out.println("PASS 10 native weapon clips, "+samples+" finite source bone samples, 12 isolated owner selectors and held-weapon Lua API methods (no game/GPU)");
 }
}
