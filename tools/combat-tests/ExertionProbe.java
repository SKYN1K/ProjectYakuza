public class ExertionProbe {
 public static void main(String[]args)throws Exception{
  var actor=Class.forName("zombie.characters.IsoGameCharacter");var player=Class.forName("zombie.characters.IsoPlayer");var traits=Class.forName("zombie.characters.traits.CharacterTraits");var stats=Class.forName("zombie.characters.Stats");var stat=Class.forName("zombie.characters.CharacterStat");
  actor.getMethod("getFatigueMod");actor.getMethod("isUnlimitedEndurance");actor.getMethod("getCharacterTraits");player.getMethod("isLocalPlayer");traits.getMethod("getTraitEnduranceLossModifier");stats.getMethod("remove",stat,float.class);stats.getMethod("get",stat);stats.getMethod("set",stat,float.class);
  Object value=stats.getConstructor().newInstance();Object endurance=stat.getField("ENDURANCE").get(null);stats.getMethod("set",stat,float.class).invoke(value,endurance,.01f);stats.getMethod("remove",stat,float.class).invoke(value,endurance,.02f);float result=((Number)stats.getMethod("get",stat).invoke(value,endurance)).floatValue();if(result!=0)throw new AssertionError("native endurance clamp "+result);
  System.out.println("PASS native endurance stat/removal clamp, owner/cheat checks and fitness/trait API; no game launch");
 }
}
