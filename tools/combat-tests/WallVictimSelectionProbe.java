import java.nio.file.*;
import java.util.*;
public class WallVictimSelectionProbe {
 public static void main(String[]a)throws Exception{
  var node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");var state=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState");var variables=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource");var source=Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource");var set=variables.getMethod("setVariable",String.class,String.class);var select=state.getMethod("getAnimNodes",source,List.class);int count=0;
  for(String group:new String[]{"idle","hitreaction","hitreaction-hit","staggerback","staggerback-knockeddown","hitreaction-gettingUp"}){
   Path path=Path.of(a[0],"AnimSets/zombie",group,"ProjectYakuza_DD_WallHeatVictim.xml");Object parsed=node.getMethod("Parse",String.class).invoke(null,path.toAbsolutePath().toString());if(parsed==null)throw new AssertionError("native parse "+path);
   Object owner=state.getConstructor().newInstance(),vars=variables.getConstructor().newInstance();state.getMethod("addNode",node).invoke(owner,parsed);set.invoke(vars,"ProjectYakuzaHeatRushVictim","true");set.invoke(vars,"ProjectYakuzaPairedVictimClip","ProjectYakuza_DD_WallHeatVictim");
   var matches=(List<?>)select.invoke(owner,vars,new ArrayList<>());if(matches.size()!=1||matches.get(0)!=parsed)throw new AssertionError("paired wall selection "+group);count++;
   set.invoke(vars,"ProjectYakuzaHeatRushVictim","false");if(!((List<?>)select.invoke(owner,vars,new ArrayList<>())).isEmpty())throw new AssertionError("paired owner leak");count++;
   set.invoke(vars,"ProjectYakuzaHeatRushVictim","true");set.invoke(vars,"ProjectYakuzaPairedVictimClip","ProjectYakuza_DD_HeatRushVictim");if(!((List<?>)select.invoke(owner,vars,new ArrayList<>())).isEmpty())throw new AssertionError("wrong scene leak");count++;
  }
  System.out.println("PASS "+count+" native wall-victim owners across idle, hit, stumble, knocked-down and getting-up states with paired/scene isolation; no game/GPU launch");
 }
}
