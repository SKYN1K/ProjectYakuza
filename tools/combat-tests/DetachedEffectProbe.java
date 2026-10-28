/** Offline B42 pool/offset contract; does not start the game or touch textures/GPU. */
public class DetachedEffectProbe {
 public static void main(String[] a)throws Exception{
  var sprite=Class.forName("zombie.iso.sprite.IsoSprite");var manager=Class.forName("zombie.iso.sprite.IsoSpriteManager");
  var object=Class.forName("zombie.iso.IsoObject");var inst=Class.forName("zombie.iso.sprite.IsoSpriteInstance");
  var shared=sprite.getMethod("CreateSprite",manager).invoke(null,new Object[]{null});var owner=object.getConstructor().newInstance();
  var attach=object.getMethod("AttachExistingAnim",sprite,int.class,int.class,boolean.class,int.class,boolean.class,float.class);
  attach.invoke(owner,shared,2,100,true,0,false,0f);
  if(sprite.getField("soffY").getShort(shared)!=-100)throw new AssertionError("attachment offset contract");
  attach.invoke(owner,shared,2,80,true,0,false,0f);
  if(sprite.getField("soffY").getShort(shared)!=-80)throw new AssertionError("shared offset overwrite contract");
  var fresh=sprite.getMethod("CreateSprite",manager).invoke(null,new Object[]{null});
  var first=inst.getMethod("get",sprite).invoke(null,fresh);var second=inst.getMethod("get",sprite).invoke(null,fresh);
  inst.getMethod("setScale",float.class,float.class).invoke(first,.2f,.2f);inst.getMethod("setScale",float.class,float.class).invoke(second,.4f,.4f);
  if(sprite.getField("soffX").getShort(fresh)!=0||sprite.getField("soffY").getShort(fresh)!=0)throw new AssertionError("detached offsets mutated");
  if((Float)inst.getMethod("getScaleX").invoke(first)!=.2f||(Float)inst.getMethod("getScaleX").invoke(second)!=.4f)throw new AssertionError("instance scale shared");
  for(var i:new Object[]{first,second}){
   inst.getMethod("SetAlpha",float.class).invoke(i,.4f);inst.getMethod("SetTargetAlpha",float.class).invoke(i,.4f);
   if((Boolean)inst.getMethod("isCopyTargetAlpha").invoke(i))throw new AssertionError("particle alpha not independent");
   inst.getMethod("Dispose").invoke(i);inst.getMethod("add",inst).invoke(null,i);
  }
  System.out.println("PASS native shared sprite-offset overwrite reproduced; detached offsets stay zero, scales/alpha independent, pool cleanup works (no game/GPU)");
 }
}
