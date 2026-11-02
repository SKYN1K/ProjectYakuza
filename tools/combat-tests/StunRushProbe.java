import java.nio.file.*;
import java.util.*;
public class StunRushProbe {
 public static void main(String[]args)throws Exception {
  var weapon=Class.forName("zombie.inventory.types.HandWeapon");
  for(String n:new String[]{"getPushBackMod","getKnockdownMod","isKnockBackOnNoDeath","isAlwaysKnockdown"})weapon.getMethod(n);
  for(String n:new String[]{"setPushBackMod","setKnockdownMod"})weapon.getMethod(n,float.class);
  for(String n:new String[]{"setKnockBackOnNoDeath","setAlwaysKnockdown"})weapon.getMethod(n,boolean.class);
  var player=Class.forName("zombie.characters.IsoPlayer");var actor=Class.forName("zombie.characters.IsoGameCharacter");
  actor.getMethod("setIgnoreStaggerBack",boolean.class);actor.getMethod("isIgnoreStaggerBack");actor.getMethod("changeState",Class.forName("zombie.ai.State"));
  Class.forName("zombie.iso.IsoMovingObject").getMethod("setOnFloor",boolean.class);
  Class.forName("zombie.ai.states.ZombieIdleState").getMethod("instance");Class.forName("zombie.ai.states.ZombieOnGroundState").getMethod("instance");
  actor.getMethod("Hit",weapon,actor,float.class,boolean.class,float.class);player.getMethod("getSafety");player.getMethod("isFactionPvp");
  for(String n:new String[]{"setAuthorizeMeleeAction","setBlockMovement","setIgnoreMovement","setDeferredMovementEnabled"})player.getMethod(n,boolean.class);
  Class.forName("zombie.iso.areas.NonPvpZone").getMethod("getNonPvpZone",int.class,int.class);
  Class.forName("zombie.characters.Faction").getMethod("getPlayerFaction",player);
  var node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");var state=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState");var variables=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource");var source=Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource");var set=variables.getMethod("setVariable",String.class,String.class);var select=state.getMethod("getAnimNodes",source,List.class);
  for(String folder:new String[]{"actions","hitreactionpvp"}){
   var path=Path.of(args[0],folder,"ProjectYakuza_PVP_HeatRushVictim.xml");var parsed=node.getMethod("Parse",String.class).invoke(null,path.toAbsolutePath().toString());Object st=state.getConstructor().newInstance(),vars=variables.getConstructor().newInstance();state.getMethod("addNode",node).invoke(st,parsed);
   set.invoke(vars,"ProjectYakuzaHeatRushVictim","true");set.invoke(vars,"ProjectYakuzaPairedVictimClip","ProjectYakuza_DD_HeatRushVictim");if(((List<?>)select.invoke(st,vars,new ArrayList<>())).size()!=1)throw new AssertionError("player victim selector "+folder);
   set.invoke(vars,"ProjectYakuzaHeatRushVictim","false");if(!((List<?>)select.invoke(st,vars,new ArrayList<>())).isEmpty())throw new AssertionError("player victim selector leak "+folder);
  }
  System.out.println("PASS native weapon knockback/knockdown controls, native player Hit and PvP permission APIs, two scoped player victim state definitions; no game launch");
 }
}
