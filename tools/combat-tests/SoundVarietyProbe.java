import java.nio.file.*;import java.util.*;import java.util.regex.*;import java.lang.reflect.*;
public class SoundVarietyProbe {
 public static void main(String[]args)throws Exception{
  var script=Class.forName("zombie.scripting.objects.GameSoundScript");var owner=Class.forName("zombie.audio.GameSound");var clipType=Class.forName("zombie.audio.GameSoundClip");
  var expected=Map.of("PunchImpact",9,"KickImpact",5,"HeatImpact",4,"PunchSwing",4,"KickSwing",3,"GuardImpact",3,"HeavyFinisher",3);int groups=0,clips=0;Object sample=null;
  String text=Files.readString(Path.of(args[0]));var match=Pattern.compile("sound\\s+(\\w+)\\s*\\{").matcher(text);
  while(match.find()){
   String suffix=match.group(1).replace("ProjectYakuza_Y6_","");if(!expected.containsKey(suffix))continue;
   int start=text.indexOf('{',match.start()),end=start+1,depth=1;while(depth>0){char c=text.charAt(end++);depth+=(c=='{'?1:0)-(c=='}'?1:0);}
   Object parsed=script.getConstructor().newInstance();script.getMethod("Load",String.class,String.class).invoke(parsed,match.group(1),text.substring(match.start(),end));Object sound=script.getField("gameSound").get(parsed);var entries=(List)owner.getField("clips").get(sound);
   if(entries.size()!=expected.get(suffix))throw new AssertionError("pool count "+suffix);owner.getMethod("setUserVolume",float.class).invoke(sound,.37f);
   for(Object clip:entries){if(clipType.getField("gameSound").get(clip)!=sound)throw new AssertionError("detached parent volume");String file=(String)clipType.getMethod("getFile").invoke(clip);if(!Files.isRegularFile(Path.of(args[1]).resolve(file)))throw new AssertionError("missing supplied clip "+file);float volume=(Float)clipType.getMethod("getVolume").invoke(clip);if(!Float.isFinite(volume)||volume<0)throw new AssertionError("gain");clips++;}groups++;sample=sound;
  }
  if(groups!=7||clips!=31)throw new AssertionError("pool coverage");
  var platformType=Class.forName("se.krka.kahlua.j2se.J2SEPlatform");var platform=platformType.getMethod("getInstance").invoke(null);var table=Class.forName("se.krka.kahlua.vm.KahluaTable");var env=platformType.getMethod("newEnvironment").invoke(platform);var manager=Class.forName("se.krka.kahlua.converter.KahluaConverterManager");var exposeType=Class.forName("zombie.Lua.LuaManager$Exposer");
  Object exposer=exposeType.getConstructor(manager,Class.forName("se.krka.kahlua.vm.Platform"),table).newInstance(manager.getConstructor().newInstance(),platform,env);
  for(Class<?> type:new Class<?>[]{owner,clipType,Object.class})exposeType.getMethod("setExposed",Class.class).invoke(exposer,type);
  for(Class<?> type:new Class<?>[]{Object.class,owner,clipType})exposeType.getMethod("exposeLikeJava",Class.class,table).invoke(exposer,type,env);
  table.getMethod("rawset",Object.class,Object.class).invoke(env,"nativeSound",sample);
  var threadType=Class.forName("se.krka.kahlua.vm.KahluaThread");var thread=threadType.getConstructor(Class.forName("se.krka.kahlua.vm.Platform"),table).newInstance(platform,env);threadType.getField("debugOwnerThread").set(thread,Thread.currentThread());
  Class.forName("zombie.ui.UIManager").getField("defaultthread").set(null,thread);
  var random=Class.forName("zombie.core.random.RandStandard");random.getMethod("init").invoke(random.getField("INSTANCE").get(null));
  var closure=Class.forName("se.krka.kahlua.luaj.compiler.LuaCompiler").getMethod("loadstring",String.class,String.class,table).invoke(null,"local clip=nativeSound:getRandomClip(); return clip:getFile()","native sound methods",env);
  Object[] result=(Object[])threadType.getMethod("pcall",Object.class,Object[].class).invoke(thread,closure,new Object[0]);if(!Boolean.TRUE.equals(result[0])||!(result[1] instanceof String))throw new AssertionError(Arrays.toString(result));
  var loader=SoundVarietyProbe.class.getClassLoader();var world=Class.forName("zombie.iso.IsoWorld",false,loader);var emitter=Class.forName("zombie.audio.BaseSoundEmitter",false,loader);var object=Class.forName("zombie.iso.IsoObject",false,loader);
  if(!emitter.isAssignableFrom(world.getMethod("getFreeEmitter",float.class,float.class,float.class).getReturnType()))throw new AssertionError("world emitter");
  emitter.getMethod("playClip",clipType,object);emitter.getMethod("setVolume",long.class,float.class);
  System.out.println("PASS 7 native pools / 31 supplied clips retain original parent volumes; native Kahlua public clip methods work; pooled world-emitter clip API exists; no game/audio playback");
 }
}




