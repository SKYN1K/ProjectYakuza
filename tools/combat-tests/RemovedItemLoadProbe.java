import java.nio.*;
public class RemovedItemLoadProbe {
 public static void main(String[]args)throws Exception{
  var dictionary=Class.forName("zombie.world.WorldDictionary");var field=dictionary.getDeclaredField("data");field.setAccessible(true);var constructor=field.getType().getDeclaredConstructor();constructor.setAccessible(true);field.set(null,constructor.newInstance());
  var type=Class.forName("zombie.inventory.InventoryItem");var load=type.getMethod("loadItem",ByteBuffer.class,int.class);
  for(short id:new short[]{-12345,-23456}){
   var buffer=ByteBuffer.allocate(15);buffer.putInt(7).putShort(id).put((byte)0).putInt(123).putInt(0x12345678).flip();Object item=load.invoke(null,buffer,240);
   if(item!=null||buffer.position()!=11||buffer.getInt()!=0x12345678)throw new AssertionError("missing item payload was not skipped safely");
  }
  System.out.println("PASS native inventory loader skips missing item definitions and preserves the following saved record; no save/game launched");
 }
}
