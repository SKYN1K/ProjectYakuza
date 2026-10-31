import java.nio.file.*;import java.util.*;import java.util.regex.*;
public class CombatSoundProbe {
 public static void main(String[] args)throws Exception{
  String text=Files.readString(Path.of(args[0]));var soundType=Class.forName("zombie.scripting.objects.GameSoundScript");int sounds=0,clips=0;
  var match=Pattern.compile("sound\\s+(\\w+)\\s*\\{").matcher(text);
  while(match.find()){
   int start=text.indexOf('{',match.start()),end=start+1,depth=1;while(depth>0){char c=text.charAt(end++);if(c=='{')depth++;if(c=='}')depth--;}
   String block=text.substring(match.start(),end);Object script=soundType.getConstructor().newInstance();soundType.getMethod("Load",String.class,String.class).invoke(script,match.group(1),block);
   var field=soundType.getField("gameSound");Object sound=field.get(script);var definitions=(List)sound.getClass().getField("clips").get(sound);if(definitions.isEmpty())throw new AssertionError("empty sound");sounds++;clips+=definitions.size();
   var files=Pattern.compile("file\\s*=\\s*([^,]+),").matcher(block);while(files.find()){if(!Files.isRegularFile(Path.of(args[1]).resolve(files.group(1).trim())))throw new AssertionError("missing audio "+files.group(1));}
  }
  if(sounds<2)throw new AssertionError("definitions missing");System.out.println("PASS "+sounds+" native combat sound definitions / "+clips+" source clip references parse and resolve; no audio generated");
 }
}
