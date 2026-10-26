import java.nio.file.*;
import java.util.*;
import java.lang.reflect.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
import jassimp.*;
import zombie.core.skinnedmodel.model.jassimp.*;

/** Offline use of PZ's actual importer and animation selectors; never starts the game. */
public class MadDogProbe {
    static String text(Element n,String tag) {return n.getElementsByTagName(tag).item(0).getTextContent();}
    static Object parsed(Path path,Class<?> node)throws Exception {
        Object n=node.getMethod("Parse",String.class).invoke(null,path.toAbsolutePath().toString());
        if(n==null)throw new AssertionError("Native parser rejected "+path);return n;
    }
    public static void main(String[] args)throws Exception {
        Path addon=Path.of(args[0]),framework=Path.of(args[1]);int clips=0,owners=0,observers=0;
        for(Path path:Files.list(addon.resolve("42/media/anims_X/Bob")).filter(p->p.toString().endsWith(".x")).sorted().toList()) {
            AiScene scene=Jassimp.importFile(path.toAbsolutePath().toString(),EnumSet.of(AiPostProcessSteps.VALIDATE_DATA_STRUCTURE));
            if(scene.getAnimations().size()!=1)throw new AssertionError("Animation count "+path);
            AiAnimation anim=scene.getAnimations().get(0);
            if(anim.getNumChannels()!=36 || anim.getDuration()<=0 || anim.getTicksPerSecond()!=4800)throw new AssertionError("Clip metadata "+path);
            for(AiNodeAnim channel:anim.getChannels()) {
                for(int i=0;i<channel.getNumRotKeys();i++) {
                    double norm=Math.pow(channel.getRotKeyW(i),2)+Math.pow(channel.getRotKeyX(i),2)+Math.pow(channel.getRotKeyY(i),2)+Math.pow(channel.getRotKeyZ(i),2);
                    if(!Double.isFinite(norm)||Math.abs(norm-1)>.001)throw new AssertionError("Quaternion "+path+" "+channel.getNodeName());
                }
                if(channel.getNodeName().equals("Bip01")) {
                    for(int i=1;i<channel.getNumPosKeys();i++)
                        if(Math.abs(channel.getPosKeyX(i)-channel.getPosKeyX(0))>.00001 || Math.abs(channel.getPosKeyY(i)-channel.getPosKeyY(0))>.00001)
                            throw new AssertionError("Horizontal root drift "+path);
                }
            }
            ProcessedAiSceneParams params=ProcessedAiSceneParams.create();params.scene=scene;
            params.mode=JAssImpImporter.LoadMode.AnimationOnly;params.animBonesScaleModifier=1;
            params.animBonesRotateModifier=new org.lwjgl.util.vector.Quaternion(0,0,0,1);
            Object processed=ProcessedAiScene.process(params);
            Field skeletonField=ProcessedAiScene.class.getDeclaredField("skeleton");skeletonField.setAccessible(true);
            Object skeleton=skeletonField.get(processed);
            Field clipField=skeleton.getClass().getDeclaredField("clips");clipField.setAccessible(true);
            if(((Map<?,?>)clipField.get(skeleton)).isEmpty())throw new AssertionError("No engine clip "+path);
            System.out.printf("IMPORT %s %.6fs %d channels; engine processing passed%n",path.getFileName(),anim.getDuration()/anim.getTicksPerSecond(),anim.getNumChannels());clips++;
        }
        Class<?> node=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimNode"),stateType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimState"),varsType=Class.forName("zombie.core.skinnedmodel.advancedanimation.AnimationVariableSource"),source=Class.forName("zombie.core.skinnedmodel.advancedanimation.IAnimationVariableSource");
        Method set=varsType.getMethod("setVariable",String.class,String.class),add=stateType.getMethod("addNode",node),select=stateType.getMethod("getAnimNodes",source,List.class);
        Map<String,Object> states=new HashMap<>();
        for(Path root:List.of(framework.resolve("42/media/AnimSets/player"),addon.resolve("42/media/AnimSets/player")))
            try(var paths=Files.walk(root)) {
                for(Path path:paths.filter(p->p.toString().endsWith(".xml")).toList()) {
                    String group=path.getParent().getFileName().toString();Object state=states.get(group);
                    if(state==null){state=stateType.getConstructor().newInstance();states.put(group,state);}
                    add.invoke(state,parsed(path,node));
                }
            }
        try(var paths=Files.walk(addon.resolve("42/media/AnimSets/player"))) {
            for(Path path:paths.filter(p->p.toString().endsWith(".xml")).sorted().toList()) {
                Element doc=DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(path.toFile()).getDocumentElement();
                boolean observer=path.getFileName().toString().contains("_MP_");
                if(observer && doc.getElementsByTagName("m_Events").getLength()!=0)throw new AssertionError("Observer side effect "+path);
                Object vars=varsType.getConstructor().newInstance();NodeList cs=doc.getElementsByTagName("m_Conditions");
                for(int i=0;i<cs.getLength();i++){Element c=(Element)cs.item(i);set.invoke(vars,text(c,"m_Name"),text(c,"m_Value"));}
                Object state=states.get(path.getParent().getFileName().toString());
                List<?> selected=(List<?>)select.invoke(state,vars,new ArrayList<>());
                if(selected.size()!=1 || !node.getField("name").get(selected.get(0)).equals(text(doc,"m_Name")))
                    throw new AssertionError("Native priority/selection conflict "+path+" count="+selected.size());
                set.invoke(vars,observer?"ProjectYakuzaRemoteObserver":"ProjectYakuzaStyle",observer?"false":"dragon_of_dojima");
                selected=(List<?>)select.invoke(state,vars,new ArrayList<>());
                for(Object n:selected)if(node.getField("name").get(n).equals(text(doc,"m_Name")))throw new AssertionError("Style/observer leakage "+path);
                if(observer)observers++;else owners++;
            }
        }
        if(clips!=26||owners!=28||observers!=82)throw new AssertionError("Unexpected coverage: "+clips+"/"+owners+"/"+observers);
        System.out.printf("PASS: %d native clip imports, %d owner selectors with framework conflict checks, %d event-free observer selectors and style/remote isolation%n",clips,owners,observers);
    }
}
