/*
 * $Date$
 * $Revision$
 * $Author$
 */

package de.uni_sb.ps.dml.builtin;

import de.uni_sb.ps.dml.runtime.*;

final public class Vector implements DMLValue {

    /** nachschauen wieviel in Java machbar ist*/
    public final static int maxLength = 65535;

    /** das Array mit den Werten */
    protected DMLValue[] vec = null;

    protected Vector(int n) {
	if (n<0 || maxLength<n)
	    General.Size.raise();
	else
	    vec=new DMLValue[n];
    }

    public Vector(DMLValue f, int n)  throws java.rmi.RemoteException {// das ist tabulate
	if (n<0 || maxLength<n) {
	    General.Size.raise();
	} else {
	    vec = new DMLValue[n];
	    for(int i=0; i<n; i++) {
		DMLValue[] arg={new Int(i)};
		vec[i]=f.apply(new Tuple(arg));
	    }
	}
    }

    public Vector(int len, DMLValue init) {
	if (len<0 || maxLength<len) {
	    General.Size.raise();
	} else {
	    vec = new DMLValue[len];
	    for(int i=0; i<len; i++)
		vec[i] = init;
	}
    }

    public Vector(DMLValue[] arr) {
	int size=arr.length;
	vec=new DMLValue[size];
	for(int i=0; i<size; i++)
	    vec[i]=arr[i];
    }

    public Vector(DMLValue[] arr, int from, int to) {
	int size=arr.length;
	if (to<0 || from<0 || to<from || arr.length<to)
	    General.Subscript.raise();
	else {
	    size=to-from;
	    vec = new DMLValue[size];
	    for(int i=0; i<size; i++)
		vec[i]=arr[from+i];
	}
    }

    protected Vector(DMLValue list)  throws java.rmi.RemoteException {
	DMLValue li = list;
	if (list==List.nil)
	    vec = new DMLValue[0];
	else if (list instanceof Cons) {
	    int le = 0;
	    while (li!=List.nil) {
		if (li instanceof Cons) {
		    le++;
		    li = ((Cons) li).cdr;
		} else
		     _error(`"argument not DMLList"',list);
	    }
	    vec = new DMLValue[le];
	    int index = 0;
	    while (list!=List.nil) {
		Cons l = (Cons) list;
		vec[index++]=l.car;
		list = l.cdr;
	    }
	} else
	     _error(`"argument not DMLList"',list);
    }

    final public int length() {
	return vec.length;
    }

    final public DMLValue sub(int index) {
	if (index<0 || vec.length<=index) {
	    return General.Subscript.raise();
	} else {
	    return vec[index];
	}
    }

    final public DMLValue app(DMLValue f)  throws java.rmi.RemoteException {
	int length = vec.length;
	for(int i=0; i<length; i++)
	    f.apply(vec[i]);
	return Constants.dmlunit;
    }

    final public DMLValue appi(int from, int to, DMLValue f) throws java.rmi.RemoteException {
	if (to<0 || from<0 || vec.length<to || to<from)
	    return General.Subscript.raise();
	else {
	    for(int i=from; i<to; i++) {
		f.apply(new Tuple2(new Int(i),vec[i]));
	    }
	    return Constants.dmlunit;
	}
    }

    final public DMLValue foldl(DMLValue f, DMLValue init) throws java.rmi.RemoteException {
	DMLValue[] args = new DMLValue[2];
	int length=vec.length;
	args[1]=init;
	for(int i=0; i<length; i++) {
	    args[0]=vec[i];
	    args[1]=f.apply(new Tuple(args));
	}
	return args[1];
    }

    final public DMLValue foldr(DMLValue f, DMLValue init) throws java.rmi.RemoteException {
	DMLValue[] args = new DMLValue[2];
	args[1]=init;
	for(int i=vec.length-1; i>=0; i--) {
	    args[0]=vec[i];
	    args[1]=f.apply(new Tuple(args));
	}
	return args[1];
    }

    final public DMLValue foldli(DMLValue f, DMLValue init, int from, int to) throws java.rmi.RemoteException {
	int length = vec.length;
	if (to<0 || from<0 || length<to || to<from)
	    return General.Subscript.raise();
	else {
	    DMLValue[] args = new DMLValue[3];
	    args[2]=init;
	    for(int i=from; i<to; i++) {
		args[0]=new Int(i);
		args[1]=vec[i];
		args[2]=f.apply(new Tuple(args));
	    }
	    return args[2];
	}
    }

    final public DMLValue foldri(DMLValue f, DMLValue init, int from, int to) throws java.rmi.RemoteException {
	int length = vec.length;
	if (to<0 || from<0 || length<to || to<from)
	    return General.Subscript.raise();
	else {
	    DMLValue[] args = new DMLValue[3];
	    args[2]=init;
	    for(int i=to-1; i>=from; i--) {
		args[0]=new Int(i);
		args[1]=vec[i];
		args[2]=f.apply(new Tuple(args));
	    }
	    return args[2];
	}
    }

    final public DMLValue tabulate(int n, DMLValue f) throws java.rmi.RemoteException {
	return new Vector(f,n);
    }

    final public DMLValue extract(int from, int to) {
	if (to<0 || from<0 || to<from || vec.length<to)
	    return General.Subscript.raise();
	else {
	    return new Vector(vec,from,to);
	}
    }

    final public DMLValue map(DMLValue f) throws java.rmi.RemoteException {
	int size=vec.length;
	Vector ret=new Vector(size);
	DMLValue[] val = ret.vec;
	for(int i=0; i<size; i++)
	    val[i]=f.apply(vec[i]);
	return ret;
    }

    /** @return Vector ein neuer Vektor */
    final public DMLValue mapi(DMLValue f, int from, int to) throws java.rmi.RemoteException {
	int size=vec.length;
	if (to<0 || from<0 || to<from || vec.length<to)
	    return General.Subscript.raise();
	else {
	    size=to-from;
	    Vector ret=new Vector(size);
	    DMLValue[] val = ret.vec;
	    for(int i=0; i<size; i++)
		val[i]=f.apply(vec[from+i]);
	    return ret;
	}
    }

    final public DMLValue copyVec(int from, int len, Array dest, int dfrom) {
	DMLValue[] destArray = dest.arr;
	int dlength = destArray.length;
	if (from<0 || dfrom<0 ||
	    vec.length<from+len || dlength<dfrom+len)
	    return General.Subscript.raise();
	else {
	    for(int i=0; i<len; i++)
		destArray[dfrom+i]=vec[from+i];
	    return Constants.dmlunit;
	}
    }

    final public static DMLValue concat(DMLValue list) throws java.rmi.RemoteException {
	int total=0;
	if (list==List.nil)
	    return new Vector(0);
	else if (list instanceof Cons) {
	    DMLValue li = list;
	    while (li!=List.nil) {
		if (li instanceof Cons) {
		    Cons lc = (Cons) li;
		    DMLValue car = lc.car;
		    if (!(car instanceof Vector))
			return  _error(`"argument not Vector list"',list);
		    total+=((Vector) car).vec.length;
		    li = lc.cdr;
		} else
		    return  _error(`"argument not DMLList"',list);
	    }
	    // Ab hier ist klar: Typ ok
	    Vector ret = new Vector(total);
	    DMLValue[] retvector = ret.vec;
	    int offset = 0;
	    li = list;
	    while (li!=List.nil) {
		Cons lc = (Cons) li;
		DMLValue[] car = ((Vector) lc.car).vec;
		int length = car.length;
		for(int j=0; j<length; j++)
		    retvector[j+offset]=car[j];
		offset+=length;
		li = lc.cdr;
	    }
	    return ret;
	} else
	    return  _error(`"argument not DMLList"',list);
    }
    _apply_fails ;
    _request_id ;
    _getValue_id ;
    _raise ;

    final public java.lang.String toString() {
	java.lang.String s="["+vec[0];
	int l=vec.length;
	for(int i=1; i<l; i++)
	    s+=", "+vec[i];
	return s+"] : Vector";
    }
//' 
	    /*************************************************************/
	    /* Part 2
	     */

    /** <code>val maxLen : int </code>*/
    final public static Int maxLen = new Int(Vector.maxLength);

    final public static class FromList extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,1,"Vector.fromList");
	    DMLValue arg=args[0].request();
	    return new Vector(arg);
	}
    }
    /** <code>val fromList : 'a list -> 'a vector </code>*/
    final public static FromList fromList = new FromList();

    final public static class Tabulate extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,2,"Vector.tabulate");
	    int ar=0;
	    DMLValue arg=args[0].request();
	    if (arg instanceof Int)
		ar = ((Int) arg).getInt();
	    else
		_error(`"argument #1 not DMLArray"',val);
	    return new Vector(args[1],ar);
	}
    }
    /** <code>val tabulate : (int * (int -> 'a)) -> 'a vector </code>*/
    final public static Tabulate tabulate = new Tabulate();

    final public static class Length extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,1,"Vector.length");
	    DMLValue arg=args[0].request();
	    if (arg instanceof Vector)
		return new Int(((Vector) arg).vec.length);
	    else
		return _error(`"argument #1 not Int"',val);
	}
    }
    /** <code>val length : 'a vector -> int </code>*/
    final public static Length length = new Length();

    final public static class Sub extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,2,"Vector.sub");
	    DMLValue vector = args[0].request();
	    if (vector instanceof Vector) {
		DMLValue idx = args[1].request();
		if (idx instanceof Int)
		    return ((Vector) vector).sub(((Int) idx).getInt());
		else
		    return _error(`"argument #2 not Int"',val);
	    }
	    else
		return _error(`"argument #1 not Vector"',val);
	}
    }
    /** <code>val sub : ('a vector * int) -> 'a </code>*/
    final public static Sub sub = new Sub();

    final public static class Extract extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,3,"Vector.extract");
	    DMLValue vector = args[0].request();
	    if (vector instanceof Vector) {
		DMLValue fr = args[1].request();
		if (fr instanceof Int) {
		    DMLValue to = args[2].request();
		    if (to==Option.NONE) {
			Vector a=(Vector) vector;
			return a.extract(((Int) fr).getInt(),
					 a.vec.length);
		    }
		    if (to instanceof DMLConVal) {
			DMLConVal cv = (DMLConVal) to;
			if (cv.getConstructor()==Option.SOME) {
			    to=cv.getContent();
			    if (to instanceof Int)
				return ((Vector) vector).
				    extract(((Int) fr).getInt(),
					    ((Int) to).getInt());
			}
		    }
		    return _error(`"argument #3 not Int option"',val);
		}
		else
		    return _error(`"argument #2 not Int"',val);
	    }
	    else
		return _error(`"argument #1 not Vector"',val);
	}
    }
    /** <code>val extract : ('a vector * int * int option) -> 'a vector </code>*/
    final public static Extract extract = new Extract();

    final public static class Concat extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,1,"Vector.fromList");
	    DMLValue arg=args[0].request();
	    return Vector.concat(arg);
	}
    }
    /** <code>val concat : 'a vector list -> 'a vector </code>*/
    final public static Concat concat = new Concat();

    final public static class Mapi extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,1,"Vector.mapi");
	    return new Mapi1(args[0].request());
	}
	final public static class Mapi1 extends Builtin {
	    public DMLValue fun = null;
	    public Mapi1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
		_fromTuple(args,val,3,"Vector.mapi1");
		DMLValue vector = args[0].request();
		if (!(vector instanceof Vector))
		    return _error(`"argument #1 not Vector"',val);
		DMLValue from = args[1].request();
		if (!(from instanceof Int))
		    return _error(`"argument #2 not Int"',val);
		DMLValue to = args[2].request();
		int toint = 0;
		if (to==Option.NONE)
		    toint = ((Vector) vector).vec.length;
		else if (to instanceof DMLConVal) {
		    DMLConVal cv = (DMLConVal) to;
		    if (!(cv.getConstructor()==Option.SOME)) {
			DMLValue iv= cv.getContent();
			if (!(iv instanceof Int))
			    return _error(`"argument #3 not Int option"',val);
			toint=((Int) iv).getInt();
		    }
		} else
		    return _error(`"argument #3 not Int option"',val);
		return ((Vector) vector).
		    mapi(fun,
			 ((Int) from).getInt(),
			 toint);
	    }
	}
    }
    /** <code>val mapi : ((int * 'a) -> 'b) -> ('a vector * int * int option) -> 'b vector </code>*/
    final public static Mapi mapi = new Mapi();

    final public static class Map extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,1,"Vector.map");
	    return new Map1(args[0].request());
	}
	final public static class Map1 extends Builtin {
	    DMLValue fun = null;
	    Map1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
		_fromTuple(args,val,1,"Vector.map1");
		DMLValue vector = args[0].request();
		if (!(vector instanceof Vector))
		    return _error(`"argument not Vector"',val);
		return ((Vector) vector).map(fun);
	    }
	}
    }
    /** <code>val map : ('a -> 'b) -> 'a vector -> 'b vector </code>*/
    final public static Map map = new Map();

    final public static class Appi extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,1,"Vector.appi");
	    return new Appi1(args[0].request());
	}
	final public static class Appi1 extends Builtin {
	    public DMLValue fun = null;
	    public Appi1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
		_fromTuple(args,val,3,"Vector.appi1");
		DMLValue vector = args[0].request();
		if (!(vector instanceof Vector))
		    return _error(`"argument #1 not Vector"',val);
		DMLValue from = args[1].request();
		if (!(from instanceof Int))
		    return _error(`"argument #2 not Int"',val);
		DMLValue to = args[2].request();
		int toint = 0;
		if (to==Option.NONE)
		    toint = ((Vector) vector).vec.length;
		else if (to instanceof DMLConVal) {
		    DMLConVal cv = (DMLConVal) to;
		    if (!(cv.getConstructor()==Option.SOME)) {
			DMLValue iv= cv.getContent();
			if (!(iv instanceof Int))
			    return _error(`"argument #3 not Int option"',val);
			toint=((Int) iv).getInt();
		    }
		} else
		    return _error(`"argument #3 not Int option"',val);
		return ((Vector) vector).
		    appi(((Int) from).getInt(),
			 toint,
			 fun);
	    }
	}
    }
    /** <code>val appi : ((int * 'a) -> unit) -> ('a vector * int * int option) -> unit </code>*/
    final public static Appi appi = new Appi();

    final public static class App extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,1,"Vector.app");
	    return new App1(args[0].request());
	}
	final public static class App1 extends Builtin {
	    DMLValue fun = null;
	    App1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
		_fromTuple(args,val,1,"Vector.app1");
		DMLValue vector = args[0].request();
		if (!(vector instanceof Vector))
		    return _error(`"argument not Vector"',val);
		return ((Vector) vector).app(fun);
	    }
	}
    }
    /** <code>val app : ('a -> unit) -> 'a vector -> unit </code>*/
    final public static App app = new App();

    final public static class Foldli extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,1,"Vector.foldli");
	    return new Foldli1(args[0].request());
	}
	final public static class Foldli1 extends Builtin {
	    DMLValue fun = null;
	    Foldli1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
		_fromTuple(args,val,1,"Vector.foldli1");
		return new Foldli2(fun, args[0].request());
	    }
	    final public static class Foldli2 extends Builtin {
		DMLValue init = null; DMLValue fun = null;
		Foldli2(DMLValue f, DMLValue i) { init=i; fun=f;}
		final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
		    _fromTuple(args,val,3,"Vector.foldli2");
		    DMLValue vector = args[0].request();
		    if (!(vector instanceof Vector))
			return _error(`"argument #1 not Vector"',val);
		    DMLValue fr = args[1].request();
		    if (!(fr instanceof Int))
			return _error(`"argument #2 not Int"',val);
		    int from = ((Int) fr).getInt();
		    DMLValue to = args[2].request();
		    int toint = 0;
		    if (to==Option.NONE)
			toint = ((Vector) vector).vec.length - from;
		    else if (to instanceof DMLConVal) {
			DMLConVal cv = (DMLConVal) to;
			if (!(cv.getConstructor()==Option.SOME)) {
			    DMLValue iv= cv.getContent();
			    if (!(iv instanceof Int))
				return _error(`"argument #3 not Int option"',val);
			    toint=((Int) iv).getInt();
			}
		    } else
			return _error(`"argument #3 not Int option"',val);
		    return ((Vector) vector).
			foldli(fun,
			       init,
			       from,
			       toint);
		}
	    }
	}
    }
    /** <code>val foldli : ((int * 'a * 'b) -> 'b) -> 'b -> ('a vector * int * int option) -> 'b </code>*/
    final public static Foldli foldli = new Foldli();

    final public static class Foldri extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,1,"Vector.foldri");
	    return new Foldri1(args[0].request());
	}
	final public static class Foldri1 extends Builtin {
	    DMLValue fun = null;
	    Foldri1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
		_fromTuple(args,val,1,"Vector.foldri1");
		return new Foldri2(fun, args[0].request());
	    }
	    final public static class Foldri2 extends Builtin {
		DMLValue init = null; DMLValue fun = null;
		Foldri2(DMLValue f, DMLValue i) { init=i; fun=f; }
		final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
		    _fromTuple(args,val,3,"Vector.foldri2");
		    DMLValue vector = args[0].request();
		    if (!(vector instanceof Vector))
			return _error(`"argument #1 not Vector"',val);
		    DMLValue fr = args[1].request();
		    if (!(fr instanceof Int))
			return _error(`"argument #2 not Int"',val);
		    int from = ((Int) fr).getInt();
		    DMLValue to = args[2].request();
		    int toint = 0;
		    if (to==Option.NONE)
			toint = ((Vector) vector).vec.length - from;
		    else if (to instanceof DMLConVal) {
			DMLConVal cv = (DMLConVal) to;
			if (!(cv.getConstructor()==Option.SOME)) {
			    DMLValue iv= cv.getContent();
			    if (!(iv instanceof Int))
				return _error(`"argument #3 not Int option"',val);
			    toint=((Int) iv).getInt();
			}
		    } else
			return _error(`"argument #3 not Int option"',val);
		    return ((Vector) vector).
			foldri(fun,
			       init,
			       from,
			       toint);
		}
	    }
	}
    }
    /** <code>val foldri : ((int * 'a * 'b) -> 'b) -> 'b -> ('a vector * int * int option) -> 'b </code>*/
    final public static Foldri foldri = new Foldri();

    final public static class Foldl extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,1,"Vector.foldl");
	    return new Foldl1(args[0].request());
	}
	final public static class Foldl1 extends Builtin {
	    DMLValue fun = null;
	    Foldl1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
		_fromTuple(args,val,1,"Vector.foldl1");
		return new Foldl2(fun, args[0]);
	    }
	    final public static class Foldl2 extends Builtin {
		DMLValue init = null; DMLValue fun = null;
		Foldl2(DMLValue f,DMLValue i) { init=i; fun=f; }
		final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
		    _fromTuple(args,val,1,"Vector.foldl2");
		    DMLValue vector = args[0].request();
		    if (!(vector instanceof Vector))
			return _error(`"argument not Vector"',val);
		    return ((Vector) vector).foldl(fun,init);
		}
	    }
	}
    }
    /** <code>val foldl : (('a * 'b) -> 'b) -> 'b -> 'a vector -> 'b </code>*/
    final public static Foldl foldl = new Foldl();

    final public static class Foldr extends Builtin {
	final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
	    _fromTuple(args,val,1,"Vector.foldr");
	    return new Foldr1(args[0].request());
	}
	final public static class Foldr1 extends Builtin {
	    DMLValue fun = null;
	    Foldr1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
		_fromTuple(args,val,1,"Vector.foldr1");
		return new Foldr2(fun, args[0]);
	    }
	    final public static class Foldr2 extends Builtin {
		DMLValue init = null; DMLValue fun = null;
		Foldr2(DMLValue f, DMLValue i) { init=i; fun=f; }
		final public DMLValue apply(DMLValue val) throws java.rmi.RemoteException{
		    _fromTuple(args,val,1,"Vector.foldr2");
		    DMLValue vector = args[0].request();
		    if (!(vector instanceof Vector))
			return _error(`"argument not Vector"',val);
 		    return ((Vector) vector).foldr(fun,init);
		}
	    }
	}
    }
    /** <code>val foldr : (('a * 'b) -> 'b) -> 'b -> 'a vector -> 'b</code>*/
    final public static Foldr foldr = new Foldr();
}
