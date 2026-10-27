public class OutlineProbe {
 public static void main(String[] args)throws Exception {
  var c=Class.forName("zombie.iso.IsoObject");var o=c.getConstructor().newInstance();
  c.getMethod("setOutlineHighlightCol",int.class,float.class,float.class,float.class,float.class).invoke(o,0,.2f,.4f,.6f,.8f);
  int packed=(Integer)c.getMethod("getOutlineHighlightCol",int.class).invoke(o,0);
  System.out.println("packed="+Integer.toUnsignedString(packed)+" hex="+Integer.toHexString(packed));
  c.getMethod("setOutlineHighlight",int.class,boolean.class).invoke(o,0,true);
  if(!(Boolean)c.getMethod("isOutlineHighlight",int.class).invoke(o,0))throw new AssertionError("outline flag");
  c.getMethod("setOutlineHighlight",int.class,boolean.class).invoke(o,0,false);
  System.out.println("PASS native B42 outline color/flag API (no game launched)");
 }
}
