import java.lang.reflect.*;
public class ParticleScaleProbe {
 static Class<?> type(String name)throws Exception{return Class.forName(name);}
 static Object field(Object object,String name)throws Exception{return object.getClass().getField(name).get(object);}
 static float scale(Object instance,String axis)throws Exception{return (Float)instance.getClass().getMethod("getScale"+axis).invoke(instance);}
 public static void main(String[]args)throws Exception{
  var texture=type("zombie.core.textures.Texture");var sprite=type("zombie.iso.sprite.IsoSprite");var instance=type("zombie.iso.sprite.IsoSpriteInstance");var directions=type("zombie.iso.IsoDirections");
  var image=texture.getConstructor().newInstance();texture.getMethod("setWidth",int.class).invoke(image,64);texture.getMethod("setHeight",int.class).invoke(image,128);
  texture.getField("xEnd").setFloat(image,1);texture.getField("yEnd").setFloat(image,1);
  var parent=sprite.getMethod("CreateSprite",type("zombie.iso.sprite.IsoSpriteManager")).invoke(null,new Object[]{null});sprite.getField("texture").set(parent,image);
  var particle=instance.getMethod("get",sprite).invoke(null,parent);instance.getMethod("setScale",float.class,float.class).invoke(particle,.13f,.13f);
  var render=sprite.getDeclaredMethod("performRenderFrame",instance,type("zombie.iso.IsoObject"),directions,int.class,float.class,float.class,float.class,java.util.function.Consumer.class);render.setAccessible(true);
  var north=directions.getField("N").get(null);
  try{render.invoke(parent,particle,null,north,0,0f,0f,0f,null);}catch(InvocationTargetException e){}
  if(scale(particle,"X")!=2||scale(particle,"Y")!=2)throw new AssertionError("native 64x128 automatic scaling not reproduced");
  var pt=type("se.krka.kahlua.j2se.J2SEPlatform");var platform=pt.getMethod("getInstance").invoke(null);var table=type("se.krka.kahlua.vm.KahluaTable");var env=pt.getMethod("newEnvironment").invoke(platform);var cm=type("se.krka.kahlua.converter.KahluaConverterManager");var ex=type("zombie.Lua.LuaManager$Exposer");var converters=cm.getConstructor().newInstance();type("zombie.Lua.KahluaNumberConverter").getMethod("install",cm).invoke(null,converters);var exposer=ex.getConstructor(cm,type("se.krka.kahlua.vm.Platform"),table).newInstance(converters,platform,env);type("zombie.Lua.LuaManager").getField("env").set(null,env);
  try{ex.getMethod("exposeAll").invoke(exposer);}catch(InvocationTargetException e){}
  for(var c:new Class<?>[]{texture,sprite,instance}){
   if(!(Boolean)ex.getMethod("shouldExpose",Class.class).invoke(exposer,c))throw new AssertionError("not available to normal Lua "+c);
   ex.getMethod("exposeLikeJava",Class.class,table).invoke(exposer,c,env);
  }
  for(var pair:new Object[][]{{"particleSprite",parent},{"particleInstance",particle},{"north",north}})table.getMethod("rawset",Object.class,Object.class).invoke(env,pair[0],pair[1]);
  var tt=type("se.krka.kahlua.vm.KahluaThread");var thread=tt.getConstructor(type("se.krka.kahlua.vm.Platform"),table).newInstance(platform,env);tt.getField("debugOwnerThread").set(thread,Thread.currentThread());
  var closure=type("se.krka.kahlua.luaj.compiler.LuaCompiler").getMethod("loadstring",String.class,String.class,table).invoke(null,"local t=particleSprite:getTextureForFrame(0,north);t:setWidth(65);particleInstance:setScale(.13*64/65,.13);return t:getWidthOrig(),t:getHeightOrig()","particle scale",env);
  var result=(Object[])tt.getMethod("pcall",Object.class,Object[].class).invoke(thread,closure,new Object[0]);
  if(!Boolean.TRUE.equals(result[0])||((Number)result[1]).intValue()!=65||((Number)result[2]).intValue()!=128)throw new AssertionError(java.util.Arrays.toString(result));
  try{render.invoke(parent,particle,null,north,0,0f,0f,0f,null);}catch(InvocationTargetException e){}
  float sx=scale(particle,"X"),sy=scale(particle,"Y");
  if(Math.abs(sx-.13f*64/65)>.000001||Math.abs(sy-.13f)>.000001)throw new AssertionError("renderer overrode compact scale");
  if(Math.abs(65*sx-64*.13f)>.000001||Math.abs(128*sy-128*.13f)>.000001)throw new AssertionError("rendered size or centred anchor changed");
  if(texture.getField("xEnd").getFloat(image)!=1||texture.getField("yEnd").getFloat(image)!=1)throw new AssertionError("original image sampling changed");
  System.out.println("PASS native renderer reproduced forced 2x scaling; normal Lua metadata/axis compensation preserves requested dimensions, centred anchor and full original UVs without Java bridge or GPU");
 }
}


