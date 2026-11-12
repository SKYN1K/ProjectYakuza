import java.nio.file.*;
import java.util.*;
import java.util.regex.*;
public class PassiveUIProbe {
 public static void main(String[]args)throws Exception{
  var platformType=Class.forName("se.krka.kahlua.j2se.J2SEPlatform");var platform=platformType.getMethod("getInstance").invoke(null);
  var tableType=Class.forName("se.krka.kahlua.vm.KahluaTable");var env=platformType.getMethod("newEnvironment").invoke(platform);
  var threadType=Class.forName("se.krka.kahlua.vm.KahluaThread");var thread=threadType.getConstructor(Class.forName("se.krka.kahlua.vm.Platform"),tableType).newInstance(platform,env);
  threadType.getField("debugOwnerThread").set(thread,Thread.currentThread());
  Class.forName("zombie.ui.UIManager").getField("defaultthread").set(null,thread);
  var compiler=Class.forName("se.krka.kahlua.luaj.compiler.LuaCompiler").getMethod("loadstring",String.class,String.class,tableType);
  var uiType=Class.forName("zombie.ui.UIElement");var ui=uiType.getConstructor(tableType).newInstance(env);
  uiType.getMethod("setVisible",boolean.class).invoke(ui,true);uiType.getMethod("setConsumeMouseEvents",boolean.class).invoke(ui,false);
  var empty=compiler.invoke(null,"return nil","empty inherited handler",env);
  for(String method:new String[]{"onRightMouseDown","onRightMouseUp"}){
   tableType.getMethod("rawset",Object.class,Object.class).invoke(env,method,empty);
   if(!Boolean.TRUE.equals(uiType.getMethod(method,double.class,double.class).invoke(ui,10d,10d)))throw new AssertionError("nil handler no longer reproduces input interception");
  }
  int checks=2;
  for(String[]entry:new String[][]{{"HeatRushUI.lua","U"},{"EncounterIntro.lua","Panel"},{"HeatUI.lua","H"},{"StyleSelector.lua","Wheel"}}){
   String source=Files.readString(Path.of(args[0]).resolve(entry[0]));
   for(String method:new String[]{"onRightMouseDown","onRightMouseUp"}){
    var match=Pattern.compile("function "+entry[1]+":"+method+"\\(\\)(.*?)end",Pattern.DOTALL).matcher(source);
    if(!match.find())throw new AssertionError("missing passive handler "+entry[0]+" "+method);
    Object closure=compiler.invoke(null,match.group(1),entry[0]+" "+method,env);
    tableType.getMethod("rawset",Object.class,Object.class).invoke(env,method,closure);
    if(!Boolean.FALSE.equals(uiType.getMethod(method,double.class,double.class).invoke(ui,10d,10d)))throw new AssertionError("passive overlay consumed "+method+" "+entry[0]);
    checks++;
   }
  }
  Object lower=uiType.getConstructor(tableType).newInstance(env),upperEnv=platformType.getMethod("newEnvironment").invoke(platform),upper=uiType.getConstructor(tableType).newInstance(upperEnv);
  for(Object element:new Object[]{lower,upper}){
   uiType.getMethod("setVisible",boolean.class).invoke(element,true);uiType.getMethod("setConsumeMouseEvents",boolean.class).invoke(element,false);
   for(String method:new String[]{"setWidth","setHeight"})uiType.getMethod(method,double.class).invoke(element,100d);
  }
  var manager=Class.forName("zombie.ui.UIManager");var list=(List)manager.getMethod("getUI").invoke(null);list.clear();list.add(lower);list.add(upper);
  var point=uiType.getMethod("isPointOver",double.class,double.class);
  if(!Boolean.FALSE.equals(point.invoke(lower,20d,20d)))throw new AssertionError("native full-size passive overlay no longer reproduces inventory hit-test occlusion");
  tableType.getMethod("rawset",Object.class,Object.class).invoke(env,"onMouseWheel",compiler.invoke(null,"return true","inventory accepts wheel",env));
  tableType.getMethod("rawset",Object.class,Object.class).invoke(upperEnv,"onMouseWheel",compiler.invoke(null,"return false","overlay passes wheel",upperEnv));
  if(!Boolean.FALSE.equals(uiType.getMethod("onMouseWheel",double.class).invoke(upper,1d)))throw new AssertionError("passive wheel callback");
  uiType.getMethod("setWidth",double.class).invoke(upper,0d);uiType.getMethod("setHeight",double.class).invoke(upper,0d);
  if(!Boolean.TRUE.equals(point.invoke(lower,20d,20d))||!Boolean.TRUE.equals(uiType.getMethod("onMouseWheel",double.class).invoke(lower,1d)))throw new AssertionError("zero-input-bounds overlay did not restore inventory scrolling");
  tableType.getMethod("rawset",Object.class,Object.class).invoke(upperEnv,"render",compiler.invoke(null,"local self=...;self.rendered=true","zero-bounds still renders",upperEnv));
  uiType.getMethod("render").invoke(upper);
  if(!Boolean.TRUE.equals(tableType.getMethod("rawget",Object.class).invoke(upperEnv,"rendered")))throw new AssertionError("zero input bounds suppressed render callback");
  list.clear();
  System.out.println("PASS "+checks+" native RMB checks and inventory wheel regression: full-size passive root occludes inventory; zero input bounds restore hit testing and retain rendering; no game/UI launch");
 }
}
