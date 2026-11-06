import java.nio.file.*;
import java.util.*;
public class LowHealthProbe {
 public static void main(String[]args)throws Exception{
  var root=Path.of(args[0]);var game=Path.of(args[1]);String text=Files.readString(root.resolve("42/media/scripts/ProjectYakuza_HealthFeedback.txt"));
  String original=Files.readString(game.resolve("media/scripts/generated/sounds/player/sounds_player_foley.txt"));
  if(!original.contains("event = Character/Foley/Heartbeat,"))throw new AssertionError("missing supplied heartbeat event");
  var type=Class.forName("zombie.scripting.objects.GameSoundScript");var script=type.getConstructor().newInstance();type.getMethod("Load",String.class,String.class).invoke(script,"ProjectYakuza_LowHealthHeartbeat",text.substring(text.indexOf("sound ProjectYakuza_LowHealthHeartbeat"),text.lastIndexOf('}')));
  Object sound=type.getField("gameSound").get(script);var clips=(List<?>)sound.getClass().getField("clips").get(sound);if(clips.size()!=1)throw new AssertionError("heartbeat clip count");
  Object clip=clips.get(0);if(!"Character/Foley/Heartbeat".equals(clip.getClass().getField("event").get(clip)))throw new AssertionError("source event mismatch");
  var player=Class.forName("zombie.characters.IsoPlayer");player.getMethod("isAsleep");player.getMethod("isLocalPlayer");player.getMethod("getBodyDamage").getReturnType().getMethod("getOverallBodyHealth");
  var stats=player.getMethod("getStats").getReturnType();for(String name:new String[]{"getNumChasingZombies","getNumVeryCloseZombies","getNumVisibleZombies"})stats.getMethod(name);
  stats.getMethod("get",Class.forName("zombie.characters.CharacterStat"));Class.forName("zombie.characters.CharacterStat").getField("PANIC");Class.forName("zombie.GameSounds").getMethod("getSound",String.class).getReturnType().getMethod("getUserVolume");
  player.getMethod("getEmitter").getReturnType().getMethod("isPlaying",String.class);
  var emitter=Class.forName("fmod.fmod.FMODSoundEmitter");emitter.getMethod("setPlayRemoteEvents",boolean.class);emitter.getMethod("set3D",long.class,boolean.class);emitter.getMethod("stopSoundLocal",long.class);emitter.getMethod("isPlaying",long.class);emitter.getMethod("tick");
  System.out.println("PASS supplied PZ heartbeat event, native sound-script parser, health/threat getters and private emitter APIs; no new audio and no game launch");
 }
}
