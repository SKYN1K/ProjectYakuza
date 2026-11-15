import java.nio.file.*;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
import jassimp.*;
public class OpenGrabHeatProbe {
 public static void main(String[]args)throws Exception{
  Jassimp.setLibraryLoader(new JassimpLibraryLoader(){public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}});
  var body=MajimaEmoteProbe.process(args[0],null);var skin=Class.forName("zombie.core.skinnedmodel.model.SkinningData");Object rig=null;
  for(var c:skin.getConstructors())if(c.getParameterCount()==6)rig=c.newInstance(MajimaEmoteProbe.field(body,"clips"),MajimaEmoteProbe.field(body,"bindPose"),MajimaEmoteProbe.field(body,"invBindPose"),MajimaEmoteProbe.field(body,"skinOffsetMatrices"),MajimaEmoteProbe.field(body,"skeletonHierarchy"),MajimaEmoteProbe.field(body,"boneIndices"));
  if(rig==null)throw new AssertionError("native shared Human");var clips=new HashMap<String,Object>();
  for(int i=1;i<=2;i++){
   var imported=MajimaEmoteProbe.process(args[i],rig);if(!MajimaEmoteProbe.field(imported,"boneIndices").equals(MajimaEmoteProbe.field(body,"boneIndices"))||!MajimaEmoteProbe.field(imported,"skeletonHierarchy").equals(MajimaEmoteProbe.field(body,"skeletonHierarchy")))throw new AssertionError("Human hierarchy changed");
   var clip=((Map)MajimaEmoteProbe.field(imported,"clips")).values().iterator().next();var indices=(Map<String,Integer>)MajimaEmoteProbe.field(imported,"boneIndices");
   for(var entry:indices.entrySet()){var index=entry.getValue();var frames=(Object[])clip.getClass().getMethod("getBoneFramesAt",int.class).invoke(clip,index);if(frames.length!=201&&!(entry.getKey().endsWith("Nub")&&frames.length==0))throw new AssertionError("201 native source keys "+entry.getKey()+" actual="+frames.length);}
   clips.put(Path.of(args[i]).getFileName().toString().replace(".x",""),clip);
  }
  var nodeType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode");var stateType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState");var variableType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource");var set=variableType.getMethod("setVariable",String.class,String.class);var select=stateType.getMethod("getAnimNodes",Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource"),List.class);int count=0;
  try(var files=Files.walk(Path.of(args[3]))){for(var path:files.filter(p->p.getFileName().toString().contains("OpenGrabHeat")&&p.toString().endsWith(".xml")).toList()){
   var doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile());var node=nodeType.getMethod("Parse",String.class).invoke(null,path.toAbsolutePath().toString());var state=stateType.getConstructor().newInstance();var vars=variableType.getConstructor().newInstance();stateType.getMethod("addNode",nodeType).invoke(state,node);String reject=null;var conditions=doc.getElementsByTagName("m_Conditions");
   for(int i=0;i<conditions.getLength();i++){var e=(Element)conditions.item(i);String key=e.getElementsByTagName("m_Name").item(0).getTextContent();set.invoke(vars,key,e.getElementsByTagName("m_Value").item(0).getTextContent());if(List.of("PerformingAction","ProjectYakuzaPairedVictimClip","ProjectYakuzaRemoteClip").contains(key))reject=key;}
   if(reject==null||((List)select.invoke(state,vars,new ArrayList<>())).size()!=1)throw new AssertionError("native owner/victim/observer selector "+path);set.invoke(vars,reject,"unrelated.clip");if(!((List)select.invoke(state,vars,new ArrayList<>())).isEmpty())throw new AssertionError("cross-action leakage");
   var weights=new ArrayList<>();var type=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimBoneWeight");var elements=doc.getElementsByTagName("m_SubStateBoneWeights");
   for(int i=0;i<elements.getLength();i++){var e=(Element)elements.item(i);var weight=type.getConstructor(String.class,float.class).newInstance(e.getElementsByTagName("boneName").item(0).getTextContent(),Float.parseFloat(e.getElementsByTagName("weight").item(0).getTextContent()));type.getField("includeDescendants").set(weight,Boolean.parseBoolean(e.getElementsByTagName("includeDescendants").item(0).getTextContent()));weights.add(weight);}
   var clip=clips.get(doc.getElementsByTagName("m_AnimName").item(0).getTextContent());var trackType=Class.forName("zombie.core.skinnedmodel.animation.AnimationTrack");var track=trackType.getMethod("alloc").invoke(null);trackType.getMethod("startClip",clip.getClass(),boolean.class,float.class).invoke(track,clip,false,0f);trackType.getMethod("setBoneWeights",List.class).invoke(track,weights);trackType.getMethod("initBoneWeights",skin).invoke(track,rig);var indices=(Map<String,Integer>)MajimaEmoteProbe.field(body,"boneIndices");
   for(String bone:List.of("Bip01_Pelvis","Bip01_Head","Bip01_L_Thigh","Bip01_R_Foot","Bip01_L_Hand","Bip01_R_Hand"))if(((Number)trackType.getMethod("getBoneWeight",int.class).invoke(track,indices.get(bone))).floatValue()!=1f)throw new AssertionError("native full-body mask "+bone);
   var events=doc.getElementsByTagName("m_EventName");for(int i=0;i<events.getLength();i++)if(events.item(i).getTextContent().equals("AttackCollisionCheck"))throw new AssertionError("duplicate native damage event");count++;
  }}
  if(count!=6)throw new AssertionError("six scoped native selectors "+count);System.out.println("PASS two shared-Human clips / 201 keys, six isolated full-body owner/victim/MP selectors and no native collision events; no game launch");
 }
}
