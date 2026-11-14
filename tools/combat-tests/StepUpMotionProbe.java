import java.nio.file.*;
import java.util.*;
import jassimp.*;

public class StepUpMotionProbe {
 public static void main(String[] args)throws Exception{
  Jassimp.setLibraryLoader(new JassimpLibraryLoader(){public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}});
  var body=MajimaEmoteProbe.process(args[0],null);var skin=Class.forName("zombie.core.skinnedmodel.model.SkinningData");Object rig=null;
  for(var constructor:skin.getConstructors())if(constructor.getParameterCount()==6)rig=constructor.newInstance(MajimaEmoteProbe.field(body,"clips"),MajimaEmoteProbe.field(body,"bindPose"),MajimaEmoteProbe.field(body,"invBindPose"),MajimaEmoteProbe.field(body,"skinOffsetMatrices"),MajimaEmoteProbe.field(body,"skeletonHierarchy"),MajimaEmoteProbe.field(body,"boneIndices"));
  var imported=MajimaEmoteProbe.process(args[1],rig);var clip=((Map<?,?>)MajimaEmoteProbe.field(imported,"clips")).get("ProjectYakuza_KiryuStepUp");var nodeType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");var node=nodeType.getMethod("Parse",String.class).invoke(null,Path.of(args[2]).toAbsolutePath().toString());
  String bone=(String)nodeType.getMethod("getDeferredBoneName").invoke(node);Object axis=nodeType.getMethod("getDeferredBoneAxis").invoke(node);
  if(!bone.equals("Translation_Data")||!axis.toString().equals("Y")||!nodeType.getField("useDeferredMovement").getBoolean(node)||nodeType.getField("useDeferedRotation").getBoolean(node)||nodeType.getField("deferredRotationScale").getFloat(node)!=0f)throw new AssertionError("native translation-only selector configuration");
  var trackType=Class.forName("zombie.core.skinnedmodel.animation.AnimationTrack");var track=trackType.getMethod("alloc").invoke(null);trackType.getMethod("startClip",clip.getClass(),boolean.class,float.class).invoke(track,clip,false,0f);Object skinBone=skin.getMethod("getBone",String.class).invoke(rig,bone);
  trackType.getMethod("setDeferredBone",skinBone.getClass(),axis.getClass()).invoke(track,skinBone,axis);trackType.getMethod("setUseDeferredMovement",boolean.class).invoke(track,true);trackType.getMethod("setUseDeferredRotation",boolean.class).invoke(track,false);trackType.getMethod("setDeferredRotationScale",float.class).invoke(track,0f);
  trackType.getMethod("setBoneWeights",List.class).invoke(track,nodeType.getField("subStateBoneWeights").get(node));trackType.getMethod("initBoneWeights",skin).invoke(track,rig);if(((Number)trackType.getMethod("getDeferredBoneWeight").invoke(track)).floatValue()!=1f)throw new AssertionError("native root movement mask");
  var vectorType=Class.forName("zombie.iso.Vector2");Object movement=vectorType.getConstructor().newInstance();var lines=Files.readAllLines(Path.of(args[3]));double x=0,y=0,worst=0;
  trackType.getMethod("UpdateKeyframes",float.class).invoke(track,0f);
  for(int i=1;i<lines.size();i++){
   trackType.getMethod("UpdateKeyframes",float.class).invoke(track,1f/30f);trackType.getMethod("getDeferredMovementDiff",vectorType).invoke(track,movement);double dx=vectorType.getField("x").getFloat(movement),dy=vectorType.getField("y").getFloat(movement);x+=dx;y+=dy;String[] expected=lines.get(i).split(",");double error=Math.hypot(x-Double.parseDouble(expected[0]),y-Double.parseDouble(expected[1]));worst=Math.max(worst,error);
   if(error>0.00002||((Number)trackType.getMethod("getDeferredRotationDiff").invoke(track)).floatValue()!=0f)throw new AssertionError("native source movement at sample "+i+" error "+error+" actual "+x+","+y+" expected "+lines.get(i));
   trackType.getField("isPlaying").setBoolean(track,false);trackType.getMethod("UpdateKeyframes",float.class).invoke(track,1f/30f);trackType.getMethod("getDeferredMovementDiff",vectorType).invoke(track,movement);if(Math.hypot(vectorType.getField("x").getFloat(movement),vectorType.getField("y").getFloat(movement))>0.00001)throw new AssertionError("paused track moves");trackType.getField("isPlaying").setBoolean(track,true);
  }
  for(int i=0;i<8;i++){trackType.getMethod("UpdateKeyframes",float.class).invoke(track,1f/30f);trackType.getMethod("getDeferredMovementDiff",vectorType).invoke(track,movement);if(Math.hypot(vectorType.getField("x").getFloat(movement),vectorType.getField("y").getFloat(movement))>0.00001)throw new AssertionError("completed emote continues moving");}
  trackType.getMethod("setCurrentTimeValue",float.class).invoke(track,3f);trackType.getMethod("setPreviousTimeValue",float.class).invoke(track,3f);trackType.getField("isPlaying").setBoolean(track,false);
  for(int i=0;i<8;i++){trackType.getMethod("UpdateKeyframes",float.class).invoke(track,1f/30f);trackType.getMethod("getDeferredMovementDiff",vectorType).invoke(track,movement);if(Math.hypot(vectorType.getField("x").getFloat(movement),vectorType.getField("y").getFloat(movement))>0.00001)throw new AssertionError("stopped emote continues moving");}
  if(Math.hypot(x,y)<0.3)throw new AssertionError("stationary emote");System.out.println("PASS native translation-only source path: "+lines.size()+" samples, endpoint "+x+","+y+", maximum error "+worst+", no rotation, pause, post-end or stopped-track movement; no game launch");
 }
}
