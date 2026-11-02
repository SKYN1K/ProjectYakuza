import java.nio.file.*;
import java.util.*;
public class BottleItemProbe {
 static String value(Object block,String key)throws Exception{
  var v=block.getClass().getMethod("getValue",String.class).invoke(block,key);
  if(v==null)throw new AssertionError("missing parameter "+key);
  return ((String)v.getClass().getMethod("getValue").invoke(v)).trim();
 }
 public static void main(String[]args)throws Exception{
  var parser=Class.forName("zombie.scripting.ScriptParser");var root=parser.getMethod("parse",String.class).invoke(null,Files.readString(Path.of(args[0])));
  var modules=(List<?>)root.getClass().getField("children").get(root);if(modules.size()!=1)throw new AssertionError("module count");var module=modules.get(0);
  if(!module.getClass().getField("id").get(module).equals("ProjectYakuza"))throw new AssertionError("namespace");var items=(List<?>)module.getClass().getField("children").get(module);if(items.size()!=3)throw new AssertionError("spawnable item count");
  Set<String> expected=new HashSet<>(List.of("IntactBeerBottle","IntactWineBottle","IntactWhiskeyBottle"));
  for(Object item:items){
   String id=(String)item.getClass().getField("id").get(item);if(!expected.remove(id)||!value(item,"ItemType").equals("base:weapon")||!value(item,"Categories").contains("base:smallblunt")||!value(item,"TwoHandWeapon").equals("false"))throw new AssertionError("weapon family "+id);
   if(Float.parseFloat(value(item,"MinDamage"))!=.6f||Float.parseFloat(value(item,"MaxDamage"))!=1f||Integer.parseInt(value(item,"ConditionMax"))!=4)throw new AssertionError("weapon tuning "+id);
   if(!value(item,"WeaponSprite").equals(value(item,"StaticModel")))throw new AssertionError("held model "+id);
  }
  if(!expected.isEmpty())throw new AssertionError("missing items");
  Class.forName("zombie.inventory.types.HandWeapon").getMethod("getMinDamage");
  System.out.println("PASS native script parser: three unique ProjectYakuza spawnable one-handed Short Blunt weapon definitions, canonical damage/condition and existing model names; no game launch");
 }
}
