import java.nio.file.*;
public class LimbRenderProjectionProbe {
 public static void main(String[]args)throws Exception{
  var vector=Class.forName("zombie.iso.Vector3");var model=Class.forName("zombie.core.skinnedmodel.model.Model");var iso=Class.forName("zombie.iso.IsoUtils");
  var set=vector.getMethod("set",float.class,float.class,float.class);var toWorld=model.getMethod("vectorToWorldCoords",float.class,float.class,float.class,float.class,vector);var toX=iso.getMethod("XToScreen",float.class,float.class,float.class,int.class);var toY=iso.getMethod("YToScreen",float.class,float.class,float.class,int.class);
  Object point=vector.getConstructor().newInstance();var fx=vector.getField("x");var fy=vector.getField("y");var fz=vector.getField("z");int count=0;double worst=0;
  for(String line:Files.readAllLines(Path.of(args[0]))){
   String[] fields=line.split("\t");float x=Float.parseFloat(fields[0]),y=Float.parseFloat(fields[1]),z=Float.parseFloat(fields[2]);
   for(int i=0;i<16;i++){
    set.invoke(point,x,y,z);toWorld.invoke(null,0f,0f,0f,(float)(i*Math.PI/8+Math.PI/2),point);
    float wx=fx.getFloat(point),wy=fy.getFloat(point),wz=fz.getFloat(point);double actualX=(Float)toX.invoke(null,wx,wy,wz,0),actualY=(Float)toY.invoke(null,wx,wy,wz,0);
    double angle=i*Math.PI/8+Math.PI/2,c=Math.cos(angle),s=Math.sin(angle),ex=(-x*c-z*s)*1.5,ey=(-x*s+z*c)*1.5,ez=y*.61237234;
    double error=Math.hypot((ex-ey)*64-actualX,(ex+ey)*32-ez*192-actualY);worst=Math.max(worst,error);
    if(error>.0003)throw new AssertionError("bone/world projection mismatch "+fields[3]+" "+error);count++;
   }
  }
  if(count<20000)throw new AssertionError("projection coverage");
  if(args.length>1){
   var json=new StringBuilder("{\"cases\":"+count+",\"maxError\":"+worst+",\"finalRenderedSkeletonVerified\":false,\"reference\":[");
   for(int i=0;i<16;i++){set.invoke(point,.1f,.65f,-.4f);toWorld.invoke(null,0f,0f,0f,(float)(i*Math.PI/8+Math.PI/2),point);float x=fx.getFloat(point),y=fy.getFloat(point),z=fz.getFloat(point);if(i>0)json.append(',');json.append('[').append(toX.invoke(null,x,y,z,0)).append(',').append(toY.invoke(null,x,y,z,0)).append(']');}
   Files.writeString(Path.of(args[1]),json.append("]}").toString());
  }
  System.out.println("PASS "+count+" actual native bone/world projections across 16 facings; max error "+worst+"; no synthetic camera offset; this checks coordinate math, not final rendered skeleton placement");
 }
}
