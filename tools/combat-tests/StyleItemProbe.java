import java.lang.reflect.*;
public class StyleItemProbe {
 public static void main(String[]a)throws Exception{
  var item=Class.forName("zombie.inventory.InventoryItem");item.getMethod("getBloodLevel");item.getMethod("setBloodLevel",float.class);item.getMethod("isFavorite");item.getMethod("setFavorite",boolean.class);item.getMethod("getVisual");item.getMethod("getContainer");
  var visual=Class.forName("zombie.core.skinnedmodel.visual.ItemVisual");visual.getMethod("removeBlood");visual.getMethod("removeDirt");
  var container=Class.forName("zombie.inventory.ItemContainer");container.getMethod("getAllTypeRecurse",String.class);container.getMethod("Remove",item);container.getMethod("isInCharacterInventory",Class.forName("zombie.characters.IsoGameCharacter"));
  var globals=Class.forName("zombie.Lua.LuaManager$GlobalObject");if(!item.isAssignableFrom(globals.getMethod("instanceItem",String.class).getReturnType()))throw new AssertionError("B42 global item factory");
  System.out.println("PASS native token blood/dirt/favourite, owner-container/removal methods and B42 global instanceItem(String)");
 }
}
