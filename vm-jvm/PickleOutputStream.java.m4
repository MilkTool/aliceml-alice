/*
 * $Date$
 * $Revision$
 * $Author$
 */

package de.uni_sb.ps.dml.runtime;

import java.rmi.server.*;

/** This is the OutputStream used to create pickles.
 */
final public class PickleOutputStream extends java.io.ObjectOutputStream {

    static Class fcn = null;
    boolean waitforbind = false;

    public PickleOutputStream() throws java.io.IOException {
	super();
	if (fcn==null)
	    try{
		fcn=Class.forName("de.uni_sb.ps.dml.runtime.Function");
		System.err.println("Class zum Vergleichen: "+fcn);
	    } catch (ClassNotFoundException e) {
		System.err.println("DMLFcnClosure must be accessable by the same ClassLoader as java.lang.ObjectOutputStream.");
		e.printStackTrace();
	    }
	enableReplaceObject(true);
    }

    public PickleOutputStream(java.io.OutputStream out) throws java.io.IOException {
	super(out);
	//	System.out.println("HelloPickle");
	if (fcn==null)
	    try{
		fcn=Class.forName("de.uni_sb.ps.dml.runtime.Function");
		//		System.err.println("Class zum Vergleichen: "+fcn);
	    } catch (ClassNotFoundException e) {
		System.err.println("DMLFcnClosure must be accessable by the same ClassLoader as java.lang.ObjectOutputStream.");
		e.printStackTrace();
	    }
	enableReplaceObject(true);
    }

    final public void waitForBind(boolean b) {
	waitforbind=b;
    }

    final protected void annotateClass(Class cls) throws java.io.IOException {
	// System.out.println("POS: annotateClass "+cls);
	if (fcn.isAssignableFrom(cls.getSuperclass())) {
	    // System.out.println("POS: annotateClass "+cls+" must be annotated");
	    byte[] bytes = null;
	    java.lang.String name = cls.getName();
	    ClassLoader cl = cls.getClassLoader();
	    if (cl==PickleClassLoader.loader) {
		// System.out.println("POS: annotateClass "+cls+" came from a pickle");
		bytes = ((PickleClassLoader) cl).getBytes(name);
	    } else if (cl==ClassLoader.getSystemClassLoader()) {
		// System.out.println("POS: annotateClass "+cls+" came from somewhere else");
		java.io.InputStream in = null;
		java.io.DataInputStream din = null;
		try {
		    in = cl.getResourceAsStream(name+".class");
		    din = new java.io.DataInputStream(in);
		    bytes = new byte[din.available()];
		    din.readFully(bytes);
		}
		catch (Exception e) {
		    System.err.println("This should never happen.");
		    e.printStackTrace();
		}
		finally {
		    try {
			if (in!=null)
			    in.close();
			if (din!=null)
			    din.close();
		    } catch (java.io.IOException e) {
			e.printStackTrace();
		    }
		}
	    } else if (cl instanceof java.net.URLClassLoader) { // Klasse wurde �ber Netz geladen
  		// System.out.println("POS: annotateClass "+cls+" has been loaded via Network");
  		java.net.URL[] urls = ((java.net.URLClassLoader) cl).getURLs();
  		for(int i=0; i<urls.length; i++) {
  		    try {
  			// System.out.println("Trying: "+urls[i]);
  			java.io.DataInputStream in =new java.io.DataInputStream(urls[i].openStream());
  			bytes=new byte[in.available()];
  			in.readFully(bytes);
  			break;  // bei Erfolg for verlassen
  		    } catch (java.io.IOException io) {
  			System.err.println(urls[i]+" IOException");
  			io.printStackTrace();
  		    }
  		}
  	    }
	    writeBoolean(true);
	    writeInt(bytes.length);
	    write(bytes,0,bytes.length);
	    }
	else
	    writeBoolean(false);
    }

    /** LVar/Future werden durch ihren Inhalt ersetzt. Falls @field waitforbind true ist,
     *  wird gewartet, bis die logische Variable gebunden ist. Falls @field waitforbind false ist
     *  und die logische Variable ungebunden, wirft LVar.writeObject eine Exception.
     *  Array und Thread sollen immer Exception werfen, Reference ebenfalls.
    */

    final protected java.lang.Object replaceObject(java.lang.Object obj) {
	// System.out.println("POS: replaceObject "+obj);
	try {
	    if (obj instanceof LVar) {
		if (waitforbind)
		    obj = ((LVar) obj).request();
		else
		    obj = ((LVar) obj).getValue();
		return obj;
	    } else if (obj instanceof Array) {
		_RAISE(runtimeError,new STRING ("cannot pickle DMLArray"));
	    } else if (obj instanceof Thread) {
		_RAISE(runtimeError,new STRING ("cannot pickle Thread"));
	    } else if (obj instanceof Reference) {
		_RAISE(runtimeError,new STRING ("cannot pickle Reference"));
	    } else
		return obj;
	} catch (java.rmi.RemoteException r) {
	    System.err.println(r);
	    r.printStackTrace();
	    return null;
	}
    }
}
