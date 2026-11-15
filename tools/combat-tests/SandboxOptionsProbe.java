import java.nio.file.*;
import java.util.*;
public class SandboxOptionsProbe {
 public static void main(String[]args)throws Exception{
  var type=Class.forName("zombie.sandbox.CustomSandboxOptions");var constructor=type.getDeclaredConstructor();constructor.setAccessible(true);Object parser=constructor.newInstance();var parse=type.getDeclaredMethod("parse",String.class);parse.setAccessible(true);parse.invoke(parser,Files.readString(Path.of(args[0])));var field=type.getDeclaredField("options");field.setAccessible(true);var options=(List<?>)field.get(parser);if(options.size()!=6)throw new AssertionError("six sandbox controls");Set<String> seen=new HashSet<>();
  for(Object option:options){var t=option.getClass();String id=(String)t.getField("id").get(option);if(!seen.add(id)||!"ProjectYakuza".equals(t.getField("page").get(option))||!id.replace('.','_').equals(t.getField("translation").get(option)))throw new AssertionError("namespaced option metadata");Object value=t.getField("defaultValue").get(option);
   if(id.endsWith("WindowMs")){if(((Number)value).intValue()!=160||t.getField("min").getInt(option)!=10||t.getField("max").getInt(option)!=1000)throw new AssertionError("native integer timing range");}
   else if(id.endsWith("CooldownSeconds")){if(((Number)value).doubleValue()!=20||t.getField("min").getDouble(option)!=0||t.getField("max").getDouble(option)!=600)throw new AssertionError("native double cooldown range");}
   else if(!Boolean.TRUE.equals(value))throw new AssertionError("preserve enabled gameplay defaults");
  }
  if(!seen.equals(Set.of("ProjectYakuza.DragonTigerDrop","ProjectYakuza.DragonTigerDropWindowMs","ProjectYakuza.DragonTigerDropCooldownSeconds","ProjectYakuza.HeatActions","ProjectYakuza.Grabs","ProjectYakuza.ExtremeHeat")))throw new AssertionError("option IDs");System.out.println("PASS six native B42 sandbox controls, page/translation bindings, enabled defaults, millisecond window and fractional/zero-second cooldown; no game launch");
 }
}
