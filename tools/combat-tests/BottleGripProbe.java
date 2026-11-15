import java.nio.file.*;
import java.util.*;
import java.util.regex.*;
import jassimp.*;
public class BottleGripProbe {
 public static void main(String[]args)throws Exception{
  Jassimp.setLibraryLoader(new JassimpLibraryLoader(){public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}});
  String text=Files.readString(Path.of(args[0]));var type=Class.forName("zombie.scripting.objects.ModelScript");var attachmentType=Class.forName("zombie.scripting.objects.ModelAttachment");var renderer=Class.forName("zombie.core.skinnedmodel.model.ModelInstanceRenderData");var matrixType=Class.forName("org.joml.Matrix4f");var vectorType=Class.forName("org.joml.Vector3f");var make=renderer.getMethod("makeAttachmentTransform",attachmentType,matrixType);boolean inverse=renderer.getField("invertAttachmentSelfTransform").getBoolean(null);float worst=0;
  for(String name:new String[]{"BeerBottle","RedWineBottle","WhiskeyBottle"}){
   String id="ProjectYakuza_"+name;int first=text.indexOf("model "+id),start=text.indexOf('{',first),end=start+1,depth=1;while(depth>0){char c=text.charAt(end++);if(c=='{')depth++;if(c=='}')depth--;}Object model=type.getConstructor().newInstance();type.getMethod("Load",String.class,String.class).invoke(model,id,text.substring(first,end));Object attachment=type.getMethod("getAttachmentById",String.class).invoke(model,"Bip01_Prop1");if(attachment==null)throw new AssertionError(id);
   var scene=Jassimp.importFile(Path.of(args[1],name+".x").toString(),EnumSet.of(AiPostProcessSteps.MAKE_LEFT_HANDED,AiPostProcessSteps.REMOVE_REDUNDANT_MATERIALS));var mesh=scene.getMeshes().get(0);float low=Float.POSITIVE_INFINITY,high=Float.NEGATIVE_INFINITY;for(int i=0;i<mesh.getNumVertices();i++){low=Math.min(low,mesh.getPositionY(i));high=Math.max(high,mesh.getPositionY(i));}float height=low+.82f*(high-low),xmin=high*100,xmax=-xmin,zmin=xmin,zmax=-xmin;for(int i=0;i<mesh.getNumVertices();i++)if(mesh.getPositionY(i)>=height){xmin=Math.min(xmin,mesh.getPositionX(i));xmax=Math.max(xmax,mesh.getPositionX(i));zmin=Math.min(zmin,mesh.getPositionZ(i));zmax=Math.max(zmax,mesh.getPositionZ(i));}var neck=vectorType.getConstructor(float.class,float.class,float.class).newInstance((xmin+xmax)/2,height,(zmin+zmax)/2);var transform=make.invoke(null,attachment,matrixType.getConstructor().newInstance());if(inverse)matrixType.getMethod("invert").invoke(transform);matrixType.getMethod("transformPosition",vectorType).invoke(transform,neck);float error=(Float)vectorType.getMethod("length").invoke(neck);worst=Math.max(worst,error);if(error>.00002f)throw new AssertionError(id+" native rendered neck misses prop pivot by "+error);
  }
  System.out.println("PASS all three native imported bottle necks meet their rendered right-hand pivot; native inverse flag="+inverse+"; maximum error="+worst+"; no game launch");
 }
}
