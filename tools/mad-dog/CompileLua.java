import java.nio.file.*;
import java.util.*;
import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
/** Compile every production file without executing UI/game dependencies. */
public class CompileLua {
    public static void main(String[] args)throws Exception {
        var env=J2SEPlatform.getInstance().newEnvironment();int count=0;
        for(String root:args)try(var paths=Files.walk(Path.of(root))) {
            for(Path path:paths.filter(p->p.toString().endsWith(".lua")).toList()) {
                LuaCompiler.loadstring(Files.readString(path),path.toString(),env);count++;
            }
        }
        System.out.println("PASS: "+count+" production Lua files compile in PZ's Kahlua VM");
    }
}
