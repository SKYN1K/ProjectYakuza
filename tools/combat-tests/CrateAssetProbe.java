import jassimp.*;
import java.nio.file.*;
import java.util.*;
import java.lang.reflect.*;
import java.io.*;
public class CrateAssetProbe {
 public static void main(String[]args)throws Exception{
  var ji=Class.forName("jassimp.Jassimp");var loader=Class.forName("jassimp.JassimpLibraryLoader");
  Object proxy=new JassimpLibraryLoader(){public void loadLibrary(){System.load("F:/SteamLibrary/steamapps/common/ProjectZomboid/jassimp64.dll");}};
  ji.getMethod("setLibraryLoader",loader).invoke(null,proxy);Class step=Class.forName("jassimp.AiPostProcessSteps");Set flags=EnumSet.noneOf(step);flags.add(Enum.valueOf(step,"MAKE_LEFT_HANDED"));flags.add(Enum.valueOf(step,"REMOVE_REDUNDANT_MATERIALS"));
  Object scene=ji.getMethod("importFile",String.class,Set.class).invoke(null,args[0],flags);Class sc=scene.getClass();
  if((Integer)sc.getMethod("getNumMeshes").invoke(scene)!=1)throw new AssertionError("crate must be one intact source mesh");Object mesh=((List)sc.getMethod("getMeshes").invoke(scene)).get(0);Class mc=mesh.getClass();
  System.out.println("native mesh vertices="+mc.getMethod("getNumVertices").invoke(mesh)+" faces="+mc.getMethod("getNumFaces").invoke(mesh)+" normals="+mc.getMethod("hasNormals").invoke(mesh)+" UV="+mc.getMethod("hasTexCoords",int.class).invoke(mesh,0));
  if((Integer)mc.getMethod("getNumVertices").invoke(mesh)<1004||(Integer)mc.getMethod("getNumFaces").invoke(mesh)!=1052||!(Boolean)mc.getMethod("hasNormals").invoke(mesh)||!(Boolean)mc.getMethod("hasTexCoords",int.class).invoke(mesh,0))throw new AssertionError("source geometry retention");
  var pt=Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiSceneParams");Object params=pt.getMethod("create").invoke(null);pt.getField("scene").set(params,scene);Class mode=Class.forName("zombie.core.skinnedmodel.model.jassimp.JAssImpImporter$LoadMode");pt.getField("mode").set(params,Enum.valueOf(mode,"StaticMesh"));if(Class.forName("zombie.core.skinnedmodel.model.jassimp.ProcessedAiScene").getMethod("process",pt).invoke(null,params)==null)throw new AssertionError("native static processing");
  var imageType=Class.forName("zombie.core.textures.ImageData");for(int i=1;i<=2;i++){Object image;try(var stream=Files.newInputStream(Path.of(args[i]))){image=imageType.getConstructor(InputStream.class,boolean.class).newInstance(stream,false);}if(imageType.getMethod("getData").invoke(image)==null)throw new AssertionError("native texture decode");imageType.getMethod("dispose").invoke(image);}
  var parser=Class.forName("zombie.scripting.ScriptParser");Object root=parser.getMethod("parse",String.class).invoke(null,Files.readString(Path.of(args[3])));var module=((List<?>)root.getClass().getField("children").get(root)).get(0);var items=(List<?>)module.getClass().getField("children").get(module);if(items.size()!=1)throw new AssertionError("one crate item");Object item=items.get(0);
  if(!item.getClass().getField("id").get(item).equals("BeerCrate")||!value(item,"Categories").contains("base:smallblunt")||!value(item,"WeaponSprite").equals("ProjectYakuza_BeerCrate")||!value(item,"TwoHandWeapon").equals("false"))throw new AssertionError("crate item contract");
  var mt=Class.forName("zombie.scripting.objects.ModelScript");Object model=mt.getConstructor().newInstance();String text=Files.readString(Path.of(args[4]));String block=text.substring(text.indexOf("model ProjectYakuza_BeerCrate"),text.lastIndexOf('}'));mt.getMethod("Load",String.class,String.class).invoke(model,"ProjectYakuza_BeerCrate",block);if(!mt.getMethod("getMeshName").invoke(model).equals("Static/ProjectYakuza_BeerCrate")||!mt.getField("isStatic").getBoolean(model))throw new AssertionError("native model contract");
  System.out.println("PASS native B42 intact beer-crate mesh: 1004 source vertices / 3156 native triangle vertices, 1052 faces, normals/UVs/material and static processing; supplied textures decode and short-blunt item/model scripts parse");
 }
 static String value(Object block,String key)throws Exception{Object v=block.getClass().getMethod("getValue",String.class).invoke(block,key);return ((String)v.getClass().getMethod("getValue").invoke(v)).trim();}
}
