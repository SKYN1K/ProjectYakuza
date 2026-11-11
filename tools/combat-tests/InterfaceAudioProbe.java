import java.nio.file.*;
import java.util.*;
import java.util.regex.*;
public class InterfaceAudioProbe {
 public static void main(String[]args)throws Exception{
  Class.forName("zombie.SoundManager").getMethod("playUISound",String.class);
  String text=Files.readString(Path.of(args[0]));Class type=Class.forName("zombie.scripting.objects.GameSoundScript");var matches=Pattern.compile("sound\\s+(\\w+)\\s*\\{").matcher(text);int count=0;
  while(matches.find()){
   int start=text.indexOf('{',matches.start()),end=start+1,depth=1;while(depth>0){char c=text.charAt(end++);if(c=='{')depth++;if(c=='}')depth--;}
   String block=text.substring(matches.start(),end);Object script=type.getConstructor().newInstance();type.getMethod("Load",String.class,String.class).invoke(script,matches.group(1),block);Object sound=type.getField("gameSound").get(script);Class st=sound.getClass();
   if(st.getField("is3d").getBoolean(sound)||st.getField("loop").getBoolean(sound))throw new AssertionError("local one-shot UI audio");var clips=(List<?>)st.getField("clips").get(sound);if(clips.size()!=1)throw new AssertionError("one original waveform per cue");
   var files=Pattern.compile("file\\s*=\\s*([^,]+),").matcher(block);if(!files.find()||!Files.isRegularFile(Path.of(args[1]).resolve(files.group(1).trim())))throw new AssertionError("missing PCM path");count++;
  }
  if(count!=6)throw new AssertionError("interface cue count "+count);
  System.out.println("PASS six native 2D one-shot interface definitions, original PCM paths and B42 playUISound API; no game/audio device started");
 }
}
