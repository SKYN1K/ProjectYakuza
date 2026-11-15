import jassimp.*;
import java.nio.file.*;
import java.util.*;
import java.io.*;
public class BicycleAssetProbe {
 public static void main(String[]args)throws Exception{
  Path media=Path.of(args[0]);Jassimp.setLibraryLoader(new JassimpLibraryLoader(){public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}});
  var scene=Jassimp.importFile(media.resolve("models_X/Static/ProjectYakuza_Bicycle.x").toString(),EnumSet.of(AiPostProcessSteps.MAKE_LEFT_HANDED,AiPostProcessSteps.REMOVE_REDUNDANT_MATERIALS));
  if(scene.getNumMeshes()!=1)throw new AssertionError("single supplied bicycle mesh");var mesh=scene.getMeshes().get(0);
  if(mesh.getNumFaces()!=496||mesh.getNumVertices()<570||!mesh.hasNormals()||!mesh.hasTexCoords(0))throw new AssertionError("source geometry and UVs");
  var pt=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiSceneParams");Object params=pt.getMethod("create").invoke(null);pt.getField("scene").set(params,scene);Class mode=Class.forName("zombie.core.skinnedmodel.model.jassimp.JAssImpImporter$LoadMode");pt.getField("mode").set(params,Enum.valueOf(mode,"StaticMesh"));if(Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiScene").getMethod("process",pt).invoke(null,params)==null)throw new AssertionError("native static processing");
  var it=Class.forName("zombie.core.textures.ImageData");Object image;try(var stream=Files.newInputStream(media.resolve("textures/ProjectYakuza_Bicycle.png"))){image=it.getConstructor(InputStream.class,boolean.class).newInstance(stream,false);}
  if((Integer)it.getMethod("getWidth").invoke(image)!=128||(Integer)it.getMethod("getHeight").invoke(image)!=128||it.getMethod("getData").invoke(image)==null)throw new AssertionError("native reduced texture");it.getMethod("dispose").invoke(image);
  String text=Files.readString(media.resolve("scripts/ProjectYakuza_Bicycle.txt"));var parser=Class.forName("zombie.scripting.ScriptParser");Object root=parser.getMethod("parse",String.class).invoke(null,text);var modules=(List<?>)root.getClass().getField("children").get(root);var items=(List<?>)modules.get(0).getClass().getField("children").get(modules.get(0));Object item=items.get(0);
  if(items.size()!=1||!item.getClass().getField("id").get(item).equals("Bicycle")||!value(item,"Categories").contains("base:bigblunt")||!value(item,"TwoHandWeapon").equals("true")||!value(item,"Weight").equals("7.0")||!value(item,"WorldStaticModel").equals("ProjectYakuza_Bicycle")||!value(item,"Icon").equals("CarTire"))throw new AssertionError("bicycle item contract");
  var mt=Class.forName("zombie.scripting.objects.ModelScript");Object model=mt.getConstructor().newInstance();String block=text.substring(text.indexOf("model ProjectYakuza_Bicycle"),text.lastIndexOf('}'));mt.getMethod("Load",String.class,String.class).invoke(model,"ProjectYakuza_Bicycle",block);
  if(!mt.getMethod("getMeshName").invoke(model).equals("Static/ProjectYakuza_Bicycle")||!mt.getField("isStatic").getBoolean(model))throw new AssertionError("native model contract");
  if(!Files.readString(media.resolve("scripts/ProjectYakuza_Models.txt")).contains("scale = 0.5,"))throw new AssertionError("crate scale");
  System.out.println("PASS native B42 bicycle: 496 original Y6 LOD2 triangles, normals/UVs, static importer, 128x128 ImageData and two-handed item/model scripts");
 }
 static String value(Object block,String key)throws Exception{Object v=block.getClass().getMethod("getValue",String.class).invoke(block,key);return ((String)v.getClass().getMethod("getValue").invoke(v)).trim();}
}
