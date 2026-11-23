import java.lang.reflect.*;
public class StyleItemProbe {
 public static void main(String[]a)throws Exception{
  var item=Class.forName("zombie.inventory.InventoryItem");item.getMethod("getBloodLevel");item.getMethod("setBloodLevel",float.class);item.getMethod("isFavorite");item.getMethod("setFavorite",boolean.class);item.getMethod("getVisual");item.getMethod("getContainer");
  var visual=Class.forName("zombie.core.skinnedmodel.visual.ItemVisual");visual.getMethod("removeBlood");visual.getMethod("removeDirt");
  var container=Class.forName("zombie.inventory.ItemContainer");container.getMethod("getAllTypeRecurse",String.class);container.getMethod("Remove",item);container.getMethod("isInCharacterInventory",Class.forName("zombie.characters.IsoGameCharacter"));
  var globals=Class.forName("zombie.Lua.LuaManager$GlobalObject");if(!item.isAssignableFrom(globals.getMethod("instanceItem",String.class).getReturnType()))throw new AssertionError("B42 global item factory");
  if(a.length>0){
   var parser=Class.forName("zombie.scripting.ScriptParser");var root=parser.getMethod("parse",String.class).invoke(null,java.nio.file.Files.readString(java.nio.file.Path.of(a[0])));var modules=(java.util.List<?>)root.getClass().getField("children").get(root);var module=modules.get(0);var items=(java.util.List<?>)module.getClass().getField("children").get(module);
   if(modules.size()!=1||!module.getClass().getField("id").get(module).equals("ProjectYakuza")||items.size()!=1)throw new AssertionError("single style item namespace");var definition=items.get(0);
   if(!definition.getClass().getField("id").get(definition).equals("Dragon_DE_ProjectYakuza_Style"))throw new AssertionError("new internal style item ID");var value=definition.getClass().getMethod("getValue",String.class).invoke(definition,"DisplayName");if(!value.getClass().getMethod("getValue").invoke(value).toString().trim().equals("Dragon (DE) - Project Yakuza"))throw new AssertionError("style display name");
   System.out.println("PASS native item script parser: exact Dragon display name and internal ID, with no legacy item definition");
  }
  System.out.println("PASS native token blood/dirt/favourite, owner-container/removal methods and B42 global instanceItem(String)");
 }
}
