import java.nio.file.*;
public class LimbRenderProjectionProbe {
 public static void main(String[]args)throws Exception{
  var matrix=Class.forName("org.joml.Matrix4f");var vector=Class.forName("org.joml.Vector3f");
  var rotate=matrix.getMethod("rotate",float.class,float.class,float.class,float.class);var scale=matrix.getMethod("scale",float.class,float.class,float.class);var translate=matrix.getMethod("translate",float.class,float.class,float.class);var transform=matrix.getMethod("transformPosition",float.class,float.class,float.class,vector);
  float nativeScale=Class.forName("zombie.core.Core").getField("scale").getFloat(null);Object[] cameras=new Object[16];
  for(int i=0;i<16;i++){
   Object camera=matrix.getConstructor().newInstance();matrix.getMethod("scaling",float.class).invoke(camera,nativeScale);
   rotate.invoke(camera,.5235988f,1f,0f,0f);rotate.invoke(camera,2.3561945f,0f,1f,0f);scale.invoke(camera,-1.5f,1.5f,1.5f);
   rotate.invoke(camera,(float)(i*Math.PI/8+Math.PI/2)+(float)Math.PI,0f,1f,0f);translate.invoke(camera,0f,-.48f,0f);cameras[i]=camera;
  }
  Object output=vector.getConstructor().newInstance();int count=0;double worst=0,oldError=0;
  for(String line:Files.readAllLines(Path.of(args[0]))){
   String[] fields=line.split("\t");float x=Float.parseFloat(fields[0]),y=Float.parseFloat(fields[1]),z=Float.parseFloat(fields[2]);
   for(int i=0;i<16;i++){
    transform.invoke(cameras[i],x,y,z,output);double actualX=vector.getField("x").getFloat(output)*1920,actualY=-vector.getField("y").getFloat(output)*1920;
    double angle=i*Math.PI/8+Math.PI/2,c=Math.cos(angle),s=Math.sin(angle),wx=(-x*c-z*s)*1.5,wy=(-x*s+z*c)*1.5,wz=y*.61237234;
    double expectedX=(wx-wy)*64,oldY=(wx+wy)*32-wz*192,expectedY=oldY+.48*.61237234*192;
    double error=Math.hypot(expectedX-actualX,expectedY-actualY);worst=Math.max(worst,error);oldError=Math.max(oldError,Math.abs(oldY-actualY));
    if(error>.0003)throw new AssertionError("render matrix mismatch "+fields[3]+" angle "+i+" "+error);count++;
   }
  }
  if(count<20000||oldError<56||oldError>57)throw new AssertionError("projection coverage/old offset");
  if(args.length>1){
   var json=new StringBuilder("{\"cases\":"+count+",\"maxError\":"+worst+",\"oldOffset\":"+oldError+",\"reference\":[");
   for(int i=0;i<16;i++){transform.invoke(cameras[i],.1f,.65f,-.4f,output);if(i>0)json.append(',');json.append('[').append(vector.getField("x").getFloat(output)*1920).append(',').append(-vector.getField("y").getFloat(output)*1920).append(']');}
   Files.writeString(Path.of(args[1]),json.append("]}").toString());
  }
  System.out.println("PASS "+count+" native JOML character-camera projections across 16 facings; max corrected error "+worst+" pixels; previous missing camera translation "+oldError+" pixels at B42 tile scale 2; no game/GPU launch");
 }
}
