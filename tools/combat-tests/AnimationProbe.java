import jassimp.*;
import java.util.*;
public class AnimationProbe {
 public static void main(String[] args) throws Exception {
  Jassimp.setLibraryLoader(new JassimpLibraryLoader(){ public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}});
  for(String path:args){
   System.out.println("FILE "+path);
   AiScene scene=Jassimp.importFile(path,EnumSet.of(AiPostProcessSteps.MAKE_LEFT_HANDED,AiPostProcessSteps.REMOVE_REDUNDANT_MATERIALS));
   System.out.println("meshes="+scene.getNumMeshes()+" materials="+scene.getNumMaterials()+" animations="+scene.getNumAnimations());
   System.out.println("meshHasBones="+scene.getMeshes().get(0).hasBones());
   Class<?> paramsType=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiSceneParams");
   Object params=paramsType.getMethod("create").invoke(null);
   paramsType.getField("scene").set(params,scene);
   Class modeType=Class.forName("zombie.core.skinnedmodel.model.jassimp.JAssImpImporter$LoadMode");
   paramsType.getField("mode").set(params,Enum.valueOf(modeType,"AnimationOnly"));
   Class<?> processedType=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiScene");
   Object processed=processedType.getMethod("process",paramsType).invoke(null,params);
   java.lang.reflect.Field sf=processedType.getDeclaredField("skeleton");sf.setAccessible(true);
   Object skeleton=sf.get(processed);if(skeleton==null)throw new RuntimeException("No processed skeleton");
   java.lang.reflect.Field cf=skeleton.getClass().getDeclaredField("clips");cf.setAccessible(true);
   System.out.println("PROCESSED_CLIPS="+((Map)cf.get(skeleton)).keySet());
   for(AiAnimation a:scene.getAnimations()){
    System.out.println("clip="+a.getName()+" seconds="+a.getDuration()/a.getTicksPerSecond()+" channels="+a.getNumChannels());
    for(AiNodeAnim n:a.getChannels())if(n.getNodeName().equals("Bip01_R_Hand"))System.out.println("rightHandKeys="+n.getNumRotKeys());
   }
  }
 }
}
