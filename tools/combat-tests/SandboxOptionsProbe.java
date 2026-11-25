import java.nio.file.*;
import java.util.*;
public class SandboxOptionsProbe {
 static void translations(Path root)throws Exception{
  var language=Class.forName("zombie.core.Language");var make=language.getDeclaredConstructor(String.class,String.class,String.class,boolean.class);make.setAccessible(true);Object english=make.newInstance("EN","English",null,false);
  var translator=Class.forName("zombie.core.Translator");var loader=translator.getDeclaredMethod("tryFillMapFromFile",String.class,String.class,Map.class,language,java.util.function.Function.class);loader.setAccessible(true);
  var json=Class.forName("org.json.JSONObject");var getText=translator.getMethod("getText",String.class,Object[].class);int strings=0;
  for(String category:new String[]{"Sandbox","UI","GameSound"}){
   String member=category.equals("Sandbox")?"sandbox":category.equals("UI")?"ui":"gameSound";
   var field=translator.getDeclaredField(member);field.setAccessible(true);Map<?,?> actual=(Map<?,?>)field.get(null);
   loader.invoke(null,root.toString(),category,actual,english,java.util.function.Function.identity());
   Object object=json.getConstructor(String.class).newInstance(Files.readString(root.resolve("media/lua/shared/Translate/EN/"+category+".json")));Map<?,?> expected=(Map<?,?>)json.getMethod("toMap").invoke(object);
   if(category.equals("Sandbox")&&expected.size()!=13)throw new AssertionError("page, six names and six tooltips");
   for(var entry:expected.entrySet()){if(!entry.getValue().equals(getText.invoke(null,entry.getKey(),new Object[0])))throw new AssertionError("native translation: "+entry.getKey());strings++;}
  }
  String[] keys={"DragonTigerDrop","DragonTigerDropWindowMs","DragonTigerDropCooldownSeconds","HeatActions","Grabs","ExtremeHeat"};
  String[] names={"Dragon (DE) - Tiger Drop","Dragon (DE) - Tiger Drop ms window","Dragon (DE) - Tiger Drop cooldown","Heat Actions","Grabs","Extreme Heat"};
  String[] tips={"If on, Dragon (DE) style will be able to do Tiger Drops.","Dragon (DE)'s time window to be able to perform a successful Tiger Drop (in milliseconds).","Dragon (DE)'s Tiger Drop cooldown (in seconds).","If on, the player will be able to perform Heat Actions.","If on, the player will be able to grab.","If on, the player will be able to enter the Extreme Heat mode."};
  if(!"Project Yakuza".equals(getText.invoke(null,"Sandbox_ProjectYakuza",new Object[0])))throw new AssertionError("page text");
  for(int i=0;i<keys.length;i++){String key="Sandbox_ProjectYakuza_"+keys[i];if(!names[i].equals(getText.invoke(null,key,new Object[0]))||!tips[i].equals(getText.invoke(null,key+"_tooltip",new Object[0])))throw new AssertionError("exact sandbox text "+key);}
  System.out.println("PASS "+strings+" native JSON translations through Translator.getText, including exact sandbox page, six labels and six tooltips; no game launch");
 }
 public static void main(String[]args)throws Exception{
  translations(Path.of(args[0]).toAbsolutePath().getParent().getParent());
  var type=Class.forName("zombie.sandbox.CustomSandboxOptions");var constructor=type.getDeclaredConstructor();constructor.setAccessible(true);Object parser=constructor.newInstance();var parse=type.getDeclaredMethod("parse",String.class);parse.setAccessible(true);parse.invoke(parser,Files.readString(Path.of(args[0])));var field=type.getDeclaredField("options");field.setAccessible(true);var options=(List<?>)field.get(parser);if(options.size()!=6)throw new AssertionError("six sandbox controls");Set<String> seen=new HashSet<>();
  for(Object option:options){var t=option.getClass();String id=(String)t.getField("id").get(option);if(!seen.add(id)||!"ProjectYakuza".equals(t.getField("page").get(option))||!id.replace('.','_').equals(t.getField("translation").get(option)))throw new AssertionError("namespaced option metadata");Object value=t.getField("defaultValue").get(option);
   if(id.endsWith("WindowMs")){if(((Number)value).intValue()!=160||t.getField("min").getInt(option)!=10||t.getField("max").getInt(option)!=1000)throw new AssertionError("native integer timing range");}
   else if(id.endsWith("CooldownSeconds")){if(((Number)value).doubleValue()!=20||t.getField("min").getDouble(option)!=0||t.getField("max").getDouble(option)!=600)throw new AssertionError("native double cooldown range");}
   else if(!Boolean.TRUE.equals(value))throw new AssertionError("preserve enabled gameplay defaults");
  }
  if(!seen.equals(Set.of("ProjectYakuza.DragonTigerDrop","ProjectYakuza.DragonTigerDropWindowMs","ProjectYakuza.DragonTigerDropCooldownSeconds","ProjectYakuza.HeatActions","ProjectYakuza.Grabs","ProjectYakuza.ExtremeHeat")))throw new AssertionError("option IDs");System.out.println("PASS six native B42 sandbox controls, page/translation bindings, enabled defaults, millisecond window and fractional/zero-second cooldown; no game launch");
 }
}
