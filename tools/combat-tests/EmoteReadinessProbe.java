import java.lang.reflect.*;
import java.util.*;

public class EmoteReadinessProbe {
 static Field field(Class<?> type,String name)throws Exception{
  for(Class<?> current=type;current!=null;current=current.getSuperclass())try{var f=current.getDeclaredField(name);f.setAccessible(true);return f;}catch(NoSuchFieldException ignored){}
  throw new NoSuchFieldException(name);
 }
 public static void main(String[] args)throws Exception{
  var unsafeType=Class.forName("sun.misc.Unsafe");var singleton=unsafeType.getDeclaredField("theUnsafe");singleton.setAccessible(true);Object unsafe=singleton.get(null);var playerType=Class.forName("zombie.characters.IsoPlayer");Object player=unsafeType.getMethod("allocateInstance",Class.class).invoke(unsafe,playerType);var statsType=Class.forName("zombie.characters.Stats");Object stats=statsType.getConstructor().newInstance();field(playerType,"stats").set(player,stats);var actions=new Stack<>();field(playerType,"characterActions").set(player,actions);
  field(playerType,"gameVariables").set(player,Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource").getConstructor().newInstance());var busy=playerType.getMethod("isCurrentlyBusy");var timed=playerType.getMethod("hasTimedActions");var reading=playerType.getMethod("isReading");if(Boolean.TRUE.equals(busy.invoke(player)))throw new AssertionError("empty idle baseline");
  statsType.getMethod("setLastNumberChasingZombies",int.class).invoke(stats,3);if(!Boolean.TRUE.equals(busy.invoke(player))||Boolean.TRUE.equals(timed.invoke(player))||Boolean.TRUE.equals(reading.invoke(player)))throw new AssertionError("native chasing-zombie busy flag is not an action");
  statsType.getMethod("setLastNumberChasingZombies",int.class).invoke(stats,0);statsType.getField("lastVeryCloseZombies").setInt(stats,1);if(!Boolean.TRUE.equals(busy.invoke(player))||Boolean.TRUE.equals(timed.invoke(player)))throw new AssertionError("native close-zombie busy flag is not an action");
  field(playerType,"isReading").setBoolean(player,true);if(!Boolean.TRUE.equals(reading.invoke(player)))throw new AssertionError("native reading guard");field(playerType,"isReading").setBoolean(player,false);actions.push(null);if(!Boolean.TRUE.equals(timed.invoke(player)))throw new AssertionError("native real-action guard");
  System.out.println("PASS actual B42 busy flag includes one close or three chasing zombies without an action; separate native timed-action and reading guards verified; no game launch");
 }
}
