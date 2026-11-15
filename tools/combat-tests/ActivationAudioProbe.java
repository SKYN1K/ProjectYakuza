import java.nio.file.*;
import java.util.*;
import java.util.regex.*;
import javax.sound.sampled.*;
public class ActivationAudioProbe {
 public static void main(String[]args)throws Exception{
  String text=Files.readString(Path.of(args[0]));Class type=Class.forName("zombie.scripting.objects.GameSoundScript");var matches=Pattern.compile("sound\\s+(\\w+)\\s*\\{").matcher(text);int count=0;
  while(matches.find()){
   int start=text.indexOf('{',matches.start()),end=start+1,depth=1;while(depth>0){char c=text.charAt(end++);if(c=='{')depth++;if(c=='}')depth--;}
   String block=text.substring(matches.start(),end);Object script=type.getConstructor().newInstance();type.getMethod("Load",String.class,String.class).invoke(script,matches.group(1),block);Object sound=type.getField("gameSound").get(script);Class st=sound.getClass();
   if(!st.getField("is3d").getBoolean(sound)||st.getField("loop").getBoolean(sound))throw new AssertionError("positional one-shot activation audio");var clips=(List<?>)st.getField("clips").get(sound);if(clips.size()!=1)throw new AssertionError("one original waveform per cue");
   Object clip=clips.get(0);Class ct=clip.getClass();if(ct.getField("distanceMin").getFloat(clip)!=1||ct.getField("distanceMax").getFloat(clip)!=16||Math.abs(ct.getField("volume").getFloat(clip)-.70f)>.0001f)throw new AssertionError("native sound gain or range");
   var files=Pattern.compile("file\\s*=\\s*([^,]+),").matcher(block);if(!files.find())throw new AssertionError("missing PCM path");Path file=Path.of(args[1]).resolve(files.group(1).trim());
   try(var audio=AudioSystem.getAudioInputStream(file.toFile())){AudioFormat format=audio.getFormat();if(!format.getEncoding().equals(AudioFormat.Encoding.PCM_SIGNED)||format.getSampleSizeInBits()!=16||audio.getFrameLength()<=0)throw new AssertionError("original PCM format");}
   count++;
  }
  if(count!=3)throw new AssertionError("activation cue count "+count);
  System.out.println("PASS three native positional one-shot activation definitions, bounded range/gain and readable original PCM files; no game/audio device started");
 }
}
