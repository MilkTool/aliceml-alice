/*
 * Author:
 *      Daniel Simon, <dansim@ps.uni-sb.de>
 *
 * Copyright:
 *      Daniel Simon, 1999
 *
 * Last change:
 *    $Date$ by $Author$
 * $Revision$
 *
 */
package de.uni_sb.ps.dml.runtime;

import java.rmi.RemoteException;

final public class ConVal2 implements DMLConVal {

    public DMLValue fst = null;
    public DMLValue snd = null;

    final public Constructor constructor;

    public ConVal2(Constructor con) {
	constructor = con;
    }

    public ConVal2(Constructor con,
			DMLValue eins,
			DMLValue zwei) {
	constructor=con;
	fst=eins;
	snd=zwei;
    }

    final public DMLValue get0() { return fst; }
    final public DMLValue get1() { return snd; }
    final public DMLValue get2() { throw new ArrayIndexOutOfBoundsException(); }
    final public DMLValue get3() { throw new ArrayIndexOutOfBoundsException(); }

    final public DMLValue getContent() {
	return new Tuple2(fst,snd);
    }

    /** Gleichheit der  und Inhalte */
    final public boolean equals(Object val) {
	try {
	    if (val instanceof ConVal2) {
		ConVal2 v = (ConVal2) val;
		return
		    v.constructor == constructor &&
		    fst.equals(v.fst) &&
		    snd.equals(v.snd);
	    } else if (val instanceof DMLConVal) {
		DMLConVal cv = (DMLConVal) val;
		if (cv.getConstructor() == constructor) {
		    DMLTuple t = (DMLTuple) cv.getContent();
		    if (t.getArity()!=2) {
			return false;
		    } else {
			return
			    t.get0().equals(fst) &&
			    t.get1().equals(snd);
		    }
		} else {
		    return false;
		}
	    } else if (val instanceof DMLTransient) {
		return val.equals(this);
	    } else {
		return false;
	    }
	} catch (RemoteException r) {
	    System.err.println(r);
	    r.printStackTrace();
	    return false;
	}
    }

    final public java.lang.String toString() {
	return constructor+"("+fst+", "+snd+") : constructed value";
    }

    _getConstructor ;
    _apply_fails ;
}
