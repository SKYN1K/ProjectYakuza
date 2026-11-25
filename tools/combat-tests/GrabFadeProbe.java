import java.nio.file.*;
public class GrabFadeProbe {
 static void set(Object o,String name,Object v)throws Exception{var f=o.getClass().getDeclaredField(name);f.setAccessible(true);f.set(o,v);}
 public static void main(String[]args)throws Exception{
  var node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");var live=Class.forName("zombie.core.skinnedmodel.advancedanimation.LiveAnimNode");var layer=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimLayer");var track=Class.forName("zombie.core.skinnedmodel.animation.AnimationTrack");int cases=0;
  for(String folder:new String[]{"player/actions","zombie/hitreaction"})for(int index=1;index<=4;index++){
   String victim=folder.startsWith("zombie")?"Victim":"";Path root=Path.of(args[0]);Object outgoing=node.getMethod("Parse",String.class).invoke(null,root.resolve(folder+"/ProjectYakuza_DD_GrabStrike"+victim+String.format("%02d",index)+".xml").toString());Object incoming=node.getMethod("Parse",String.class).invoke(null,root.resolve(folder+"/ProjectYakuza_DD_Grab"+(victim.isEmpty()?"Hold":"VictimHold")+".xml").toString());
   Object old=live.getMethod("alloc",layer,node).invoke(null,null,outgoing),hold=live.getMethod("alloc",layer,node).invoke(null,null,incoming),oldTrack=track.getMethod("alloc").invoke(null),holdTrack=track.getMethod("alloc").invoke(null);live.getMethod("addMainTrack",track).invoke(old,oldTrack);live.getMethod("addMainTrack",track).invoke(hold,holdTrack);live.getMethod("setWeightsToFull").invoke(old);set(old,"wasActive",true);set(hold,"wasActive",true);set(hold,"blendingIn",true);live.getMethod("setActive",boolean.class).invoke(hold,true);
   float previous=1;for(int frame=1;frame<=24;frame++){
    live.getMethod("update",float.class).invoke(old,.01f);live.getMethod("update",float.class).invoke(hold,.01f);float a=(Float)live.getMethod("getWeight").invoke(old),b=(Float)live.getMethod("getWeight").invoke(hold);
    if(!track.getField("isPlaying").getBoolean(oldTrack))throw new AssertionError("outgoing hit track was stopped during the return fade");if(a>previous+.00001||Math.abs(a+b-1)>.00001||frame<24&&(a<=0||b<=0))throw new AssertionError("continuous complementary native fade weights");previous=a;cases++;
   }
   if(previous>.00001)throw new AssertionError("outgoing weight did not reach zero");
  }
  System.out.println("PASS "+cases+" actual LiveAnimNode return-fade updates; outgoing tracks keep playing with continuous complementary weights through the complete fade");
 }
}
