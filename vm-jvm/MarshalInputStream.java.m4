/*
 * @(#)MarshalInputStream.java  1.19 98/07/15
 *
 * Copyright 1996-1998 by Sun Microsystems, Inc.,
 * 901 San Antonio Road, Palo Alto, California, 94303, U.S.A.
 * All rights reserved.
 *
 * This software is the confidential and proprietary information
 * of Sun Microsystems, Inc. ("Confidential Information").  You
 * shall not disclose such Confidential Information and shall use
 * it only in accordance with the terms of the license agreement
 * you entered into with Sun.
 */

package sun.rmi.server;

import de.uni_sb.ps.dml.runtime.Export;
import de.uni_sb.ps.dml.runtime.PickleClassLoader;
import java.io.*;
import java.lang.reflect.*;
import java.net.*;
import java.rmi.Naming;
import java.rmi.server.RMIClassLoader;
import java.util.*;
import java.rmi.server.RMIClassLoader;
import java.security.AccessControlException;
import java.security.Permission;
import sun.security.action.GetBooleanAction;

/**
 * MarshalInputStream is an extension of ObjectInputStream.  When resolving
 * a class, it reads an object from the stream written by a corresponding
 * MarshalOutputStream.  If the class to be resolved is not available
 * locally, from the first class loader on the execution stack, or from the
 * context class loader of the current thread, it will attempt to load the
 * class from the location annotated by the sending MarshalOutputStream.
 * This location object must be a string representing a path of URLs.
 * <p>
 * A new MarshalInputStream should be created to deserialize remote objects or
 * graphs containing remote objects.  Objects are created from the stream
 * using the ObjectInputStream.readObject method.
 */
public class MarshalInputStream extends ObjectInputStream {

    /** if true, don't try superclass first in resolveClass() */
    private boolean skipDefaultResolveClass = false;

    /**
     * value of "java.rmi.server.useCodebaseOnly" property,
     * as cached at class initialization time.
     */
    private final static boolean useCodebaseOnly =
	((Boolean) java.security.AccessController.doPrivileged(
	    new GetBooleanAction(
		"java.rmi.server.useCodebaseOnly"))).booleanValue();

    /** table to hold sun classes to which access is explicitly permitted */
    protected static Map permittedSunClasses = new HashMap(3);

    /*
     * Fix for 4179055: The remote object services inside the
     * activation daemon use stubs that are in the package
     * sun.rmi.server.  Classes for these stubs should be loaded from
     * the classpath by RMI system code and not by the normal
     * unmarshalling process as applications should not need to have
     * permission to access the sun implementation classes.
     *
     * Note: this fix should be redone when API changes may be
     * integrated
     *
     * During parameter unmarshalling RMI needs to explicitly permit
     * access to three sun.* stub classes
     */
    static {
	try {
	    String monitor = sun.rmi.server.Activation.
		ActivationMonitorImpl.class.getName() + "_Stub";
	    String system = sun.rmi.server.Activation.
		ActivationSystemImpl.class.getName() + "_Stub";
	    String registry = sun.rmi.registry.
		RegistryImpl.class.getName() + "_Stub";

	    permittedSunClasses.put(monitor, Class.forName(monitor));
	    permittedSunClasses.put(system, Class.forName(system));
	    permittedSunClasses.put(registry, Class.forName(registry));

	} catch (ClassNotFoundException e) {
	    throw new NoClassDefFoundError("Missing system class: " +
					   e.getMessage());
	}
    }

    /**
     * Create a new MarshalInputStream object.
     */
    public MarshalInputStream(InputStream in)
	throws IOException, StreamCorruptedException
    {
	super(in);
    }

    /**
     * resolveClass is extended to acquire (if present) the location
     * from which to load the specified class.
     * It will find, load, and return the class.
     */
    protected Class resolveClass(ObjectStreamClass classDesc)
	throws IOException, ClassNotFoundException
    {
	/*
	 * Always read annotation written by MarshalOutputStream
	 * describing where to load class from.
	 */
	Object annotation = readLocation();

	String className = classDesc.getName();
	//System.out.println("Annotation: "+annotation);
	/*
	 * Unless we were told to skip this step, first try resolving the
	 * class using default ObjectInputStream mechanism (using first
	 * non-null class loader on the execution stack) to maximize
	 * likelihood of type compatibility with calling code.  (This step
	 * is skipped during server parameter unmarshalling using the 1.2
	 * stub protocol, because there would never be a non-null class
	 * loader on the stack in that situation anyway.)
	 */
	if (!skipDefaultResolveClass) {
	    try {
		return super.resolveClass(classDesc);

	    } catch (AccessControlException e) {
		return checkSunClass(className, e);

	    } catch (ClassNotFoundException e) {
	    }
	}


	/*
	 * Finally, try loading class from an RMIClassLoader instance.
	 * If either the "java.rmi.server.useCodebaseOnly" property was
	 * set or the annotation is not a String, load from the local
	 * loader using the "java.rmi.server.codebase" URL.  Otherwise,
	 * load from a loader using the codebase URL in the annotation.
	 */
	try {
	    if (!useCodebaseOnly &&
		annotation != null && (annotation instanceof String))
	    {
		String location = (String) annotation;
		// System.out.println("Location: "+location+" ClassName: "+className);
		// hier machen wir eine tolle Analyse des annotation Strings
		// und laden gegebenenfalls die Klasse selbst via unseren PickleClassLoader
		// case location of !IP!className =>
		//   schnapp den byte code von IP mit className;
		//   lade Klasse mit PickleClassLoader.enter und gib sie zur�ck
		if (PickleClassLoader.loader.getBytes(className) != null) {
		    // System.out.println("Class already loaded.");
		    return PickleClassLoader.loader.findClass(className);
		} else {
		    // System.out.println("Fetching class "+className+" from "+location+ ".");
		    if (location.startsWith("!")) {
			int idxofcolon = location.indexOf(':');
			// System.out.println("location is: "+location);
			String ip = location.substring(1,idxofcolon);
			// System.out.println("IP: "+ip);
			String machine = location.substring(idxofcolon+1);
			// System.out.println("Machine: " + machine);
			Export exp = null;
			try {
			    exp = (Export) Naming.lookup("//"+ip+"/exporter"+machine);
			} catch (Exception e) {
			    System.err.println(e);
			    e.printStackTrace();
			    return null;
			}
			byte[] b = exp.getClass(className);
			// System.out.println("Bytes: "+b);
			if (b != null) {
			    PickleClassLoader.loader.enter(className,b);
			}
			// here we define the class;
			Class cl = PickleClassLoader.loader.findClass(className);
			// now read the static fields:
			// System.out.println("Reading static fields ...");
			Field[] fields = cl.getDeclaredFields();
			int fc = fields.length;
			for (int i=0; i<fc; i++) {
			    int modifier = fields[i].getModifiers();
			    if (Modifier.isStatic(modifier)) {
				Object content = exp.getField(className+"field"+i);
				// System.out.println("Field "+i+": "+content);
				try {
				    fields[i].set(null,content);
				} catch (IllegalArgumentException I) {
				    System.err.println(I);
				    I.printStackTrace();
				} catch (IllegalAccessException I) {
				    System.err.println(I);
				    I.printStackTrace();
				}
			    }
			}
			// System.out.println("Done.");
			return cl;
		    } else {
			return LoaderHandler.loadClass(location, className);
		    }
		}
	    } else {
		return LoaderHandler.loadClass(className);
	    }
	} catch (AccessControlException e) {
	    return checkSunClass(className, e);

	} catch (MalformedURLException ex) {
	    /*
	     * REMIND: Do we really want to propagate MalformedURLException
	     * like this?  (And it doesn't need to be wrapped; it is a
	     * subclass of IOException anyway.)
	     */
	    throw new IOException("Malformed URL: " + annotation);
	}
    }

    /**
     * Fix for 4179055: Need to assist resolving sun stubs; resolve
     * class locally if it is a "permitted" sun class
     */
    private Class checkSunClass(String className, AccessControlException e)
	throws AccessControlException
    {
	// ensure that we are giving out a stub for the correct reason
	Permission perm = e.getPermission();
	String name = null;
	if (perm != null) {
	    name = perm.getName();
	}

	Class resolvedClass =
	    (Class) permittedSunClasses.get(className);

	// if class not permitted, throw the SecurityException
	if ((name == null) ||
	    (resolvedClass == null) ||
	    ((!name.equals("accessClassInPackage.sun.rmi.server")) &&
	    (!name.equals("accessClassInPackage.sun.rmi.registry"))))
	{
	    throw e;
	}

	return resolvedClass;
    }

    /**
     * Return the location for the class in the stream.  This method can
     * be overridden by subclasses that store this annotation somewhere
     * else than as the next object in the stream, as is done by this class.
     */
    protected Object readLocation()
	throws IOException, ClassNotFoundException
    {
	return readObject();
    }

    /**
     * Set a flag to indicate that the superclass's default resolveClass()
     * implementation should not be invoked by our resolveClass().
     */
    void skipDefaultResolveClass() {
	skipDefaultResolveClass = true;
    }
}
