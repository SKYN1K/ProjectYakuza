import java.nio.file.*;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
import jassimp.*;
public class MajimaEmoteProbe {
 static Object field(Object o,String name)throws Exception{var f=o.getClass().getDeclaredField(name);f.setAccessible(true);return f.get(o);}
 static Object process(String path,Object rig)throws Exception{
  var scene=Jassimp.importFile(path,EnumSet.of(AiPostProcessSteps.MAKE_LEFT_HANDED,AiPostProcessSteps.REMOVE_REDUNDANT_MATERIALS));var type=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiSceneParams");var p=type.getMethod("create").invoke(null);type.getField("scene").set(p,scene);var mode=(Class)Class.forName("zombie.core.skinnedmodel.model.jassimp.JAssImpImporter$LoadMode");type.getField("mode").set(p,Enum.valueOf(mode,"AnimationOnly"));if(rig!=null)type.getField("skinnedTo").set(p,rig);
  return field(Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiScene").getMethod("process",type).invoke(null,p),"skeleton");
 }
 public static void main(String[]args)throws Exception{
  int expectedFrames=args.length>3?Integer.parseInt(args[3]):152;String emoteId=args.length>4?args[4]:"ProjectYakuza_MajimaBatPoint";
  Jassimp.setLibraryLoader(new JassimpLibraryLoader(){public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}});
  var body=process(args[0],null);var skin=Class.forName("zombie.core.skinnedmodel.model.SkinningData");Object rig=null;
  for(var constructor:skin.getConstructors())if(constructor.getParameterCount()==6)rig=constructor.newInstance(field(body,"clips"),field(body,"bindPose"),field(body,"invBindPose"),field(body,"skinOffsetMatrices"),field(body,"skeletonHierarchy"),field(body,"boneIndices"));
  if(rig==null)throw new AssertionError("native Human rig construction");var imported=process(args[1],rig);
  if(!field(imported,"boneIndices").equals(field(body,"boneIndices"))||!field(imported,"skeletonHierarchy").equals(field(body,"skeletonHierarchy")))throw new AssertionError("emote changes native Human hierarchy");
  var clip=((Map)field(imported,"clips")).values().iterator().next();var indices=(Map<String,Integer>)field(imported,"boneIndices");var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(args[2]);var weights=new ArrayList<>();var weightType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimBoneWeight");var elements=doc.getElementsByTagName("m_SubStateBoneWeights");
  for(int i=0;i<elements.getLength();i++){var e=(Element)elements.item(i);String bone=e.getElementsByTagName("boneName").item(0).getTextContent();float value=Float.parseFloat(e.getElementsByTagName("weight").item(0).getTextContent());var weight=weightType.getConstructor(String.class,float.class).newInstance(bone,value);weightType.getField("includeDescendants").set(weight,false);weights.add(weight);}
  var trackType=Class.forName("zombie.core.skinnedmodel.animation.AnimationTrack");var track=trackType.getMethod("alloc").invoke(null);trackType.getMethod("startClip",clip.getClass(),boolean.class,float.class).invoke(track,clip,false,0f);trackType.getMethod("setBoneWeights",List.class).invoke(track,weights);trackType.getMethod("initBoneWeights",skin).invoke(track,rig);
  for(String bone:new String[]{"Bip01","Bip01_Pelvis","Bip01_L_Thigh","Bip01_R_Thigh","Bip01_L_Clavicle","Bip01_R_Hand","Bip01_Prop1","Bip01_Prop2"})if(((Number)trackType.getMethod("getBoneWeight",int.class).invoke(track,indices.get(bone))).floatValue()!=1f)throw new AssertionError("native mask omits "+bone);
  int count=0;for(var entry:indices.entrySet()){var frames=(Object[])clip.getClass().getMethod("getBoneFramesAt",int.class).invoke(clip,entry.getValue());if(frames==null||frames.length!=expectedFrames)throw new AssertionError("missing native source keys "+entry.getKey());count++;}
  var nodeType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");var stateType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState");var variables=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource");var vars=variables.getConstructor().newInstance();var state=stateType.getConstructor().newInstance();var node=nodeType.getMethod("Parse",String.class).invoke(null,Path.of(args[2]).toAbsolutePath().toString());stateType.getMethod("addNode",nodeType).invoke(state,node);var set=variables.getMethod("setVariable",String.class,String.class);var select=stateType.getMethod("getAnimNodes",Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource"),List.class);
  set.invoke(vars,"emote",emoteId);if(((List)select.invoke(state,vars,new ArrayList<>())).size()!=1)throw new AssertionError("native emote selection");set.invoke(vars,"emote","cvf_y0_point");if(!((List)select.invoke(state,vars,new ArrayList<>())).isEmpty())throw new AssertionError("cross-emote selection");
  var events=doc.getElementsByTagName("m_EventName");if(events.getLength()!=1||!events.item(0).getTextContent().equals("EmoteFinishing"))throw new AssertionError("emote must finish without collision or sound events");var emote=Class.forName("zombie.ai.states.PlayerEmoteState");Object nativeState=emote.getMethod("instance").invoke(null);if(!Boolean.TRUE.equals(emote.getMethod("isDoingActionThatCanBeCancelled").invoke(nativeState))||emote.getField("EMOTE").get(null)==null||emote.getField("PLAYING").get(null)==null)throw new AssertionError("native cancellation or MP state parameters");
  System.out.println("PASS "+count+" shared Human channels / "+expectedFrames+" native samples, full-body and bat-prop mask, isolated emote selector, end event and native cancellable MP state parameters; no game launch");
 }
}
