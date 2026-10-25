import java.nio.file.*;
import java.util.Arrays;

/** Runs an offline fixture in the installed game's own Kahlua VM. */
public class LuaRunner {
    public static void main(String[] args) throws Exception {
        Class<?> platformClass = Class.forName("se.krka.kahlua.j2se.J2SEPlatform");
        Object platform = platformClass.getMethod("getInstance").invoke(null);
        Class<?> table = Class.forName("se.krka.kahlua.vm.KahluaTable");
        Class<?> threadClass = Class.forName("se.krka.kahlua.vm.KahluaThread");
        for (String file : args) {
            Object env = platformClass.getMethod("newEnvironment").invoke(platform);
            Object thread = threadClass.getConstructor(Class.forName("se.krka.kahlua.vm.Platform"), table).newInstance(platform, env);
            threadClass.getField("debugOwnerThread").set(thread, Thread.currentThread());
            Object closure = Class.forName("se.krka.kahlua.luaj.compiler.LuaCompiler")
                .getMethod("loadstring", String.class, String.class, table)
                .invoke(null, Files.readString(Path.of(file)), file, env);
            Object[] result = (Object[])threadClass.getMethod("pcall", Object.class, Object[].class)
                .invoke(thread, closure, new Object[0]);
            System.out.println(file + " => " + Arrays.toString(result));
            if (!Boolean.TRUE.equals(result[0])) throw new RuntimeException("Lua test failure");
        }
    }
}
