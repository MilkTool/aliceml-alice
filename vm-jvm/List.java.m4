package de.uni_sb.ps.dml.builtin;

import de.uni_sb.ps.dml.runtime.*;
/** TODO: foldr
 */
final public class List {
    final private static class Nil extends DMLName implements DMLList{
	Nil(java.lang.String n) { super(n); }
    }
    final public static DMLName nil = new Nil("List.nil");
    final public static DMLConstructor cons = new DMLConstructor("List.cons");
    /** <code>exception Empty</code>*/
    final public static DMLName Empty = new DMLName("List.Empty");

    final public static class IsNull extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.null");
	    DMLValue l = args[0].request();
	    if (l instanceof Cons)
		return DMLConstants.dmlfalse;
	    else if (l==nil)
		return DMLConstants.dmltrue;
	    else
		return error("argument not DMLList",val);
	}
    }
    /** <code>val null : 'a list -> bool</code>*/
    final public static IsNull isNull = new IsNull();

    final public static class Length extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.length");
	    DMLValue l = args[0].request();
	    int length = 0;
	    while (l instanceof Cons) {
		length++;
		l = ((Cons) l).cdr.request();
	    }
	    if (l instanceof Nil)
		return new DMLInt(length);
	    else
		return error("argument not DMLList",val);
	}
    }
    /** <code>val length : 'a list -> int </code>*/
    final public static Length length = new Length();

    final public static class Append extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,2,"List.append");
	    DMLValue first = args[0].request();
	    if (first==nil)
		return args[1];
	    else if (first instanceof Cons) {
		Cons newList = new Cons(null,null);
		Cons cons = newList;
		while (first!=nil) {
		    if (first instanceof Cons) {
			Cons fc = (Cons) first;
			cons.cdr = new Cons(fc.car,null);
			cons=(Cons) cons.cdr;
			first = fc.cdr.request();
		    }
		    else
			return error("argument not DMLList",val);
		}
		cons.cdr = args[1];
		return newList.cdr;
	    } else
		return error("argument not DMLList",val);
	}
    }
    /** <code>val @ : ('a list * 'a list) -> 'a list </code>*/
    final public static Append append = new Append();

    final public static class Hd extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.hd");
	    DMLValue first = args[0].request();
	    if (first instanceof Cons)
		return ((Cons) first).car;
	    else if (first==nil)
		return Empty.raise();
	    else
		return error("argument not DMLList",val);
	}
    }
    /** <code>val hd : 'a list -> 'a </code>*/
    final public static Hd hd = new Hd();

    final public static class Tl extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.tl");
	    DMLValue first = args[0].request();
	    if (first instanceof Cons)
		return ((Cons) first).cdr;
	    else if (first==nil)
		return Empty.raise();
	    else
		return error("argument not DMLList",val);
	}
    }
    /** <code>val tl : 'a list -> 'a list</code>*/
    final public static Tl tl = new Tl();

    final public static class Last extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.last");
	    DMLValue first = args[0].request();
	    if (first==nil)
		return Empty.raise();
	    else if (first instanceof Cons) {
		DMLValue next = ((Cons) first).cdr.request();
		while (next!=nil) {
		    if (next instanceof Cons) {
			first = next;
			next = ((Cons) next).cdr.request();
		    }
		    else
			return error("argument not DMLList",val);
		}
		return ((Cons) first).car;
	    } else
		return error("argument not DMLList",val);
	}
    }
    /** <code>val last : 'a list -> 'a </code>*/
    final public static Last last = new Last();

    final public static class GetItem extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.getItem");
	    DMLValue first = args[0].request();
	    if (first==nil)
		return Option.NONE;
	    else if (first instanceof Cons) {
		DMLValue car = ((Cons) first).car;
		DMLValue cdr = ((Cons) first).cdr;
		return Option.SOME.apply(new Tuple2(car,cdr));
	    } else
		return error("argument not DMLList",val);
	}
    }
    /** <code>val getItem : 'a list -> ('a * 'a list) option </code>*/
    final public static GetItem getItem = new GetItem();

    final public static class Nth extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,2,"List.nth");
	    DMLValue n = args[1].request();
	    if (!(n instanceof DMLInt))
		return error("argument #2 not DMLInt",val);
	    int le = ((DMLInt) n).getInt();
	    if (le<0)
		return General.Subscript.raise();
	    DMLValue first = args[0].request();
	    if (first==nil)
		return Empty.raise();
	    else if (first instanceof Cons) {
		int i=0;
		DMLValue next = first;
		while (next!=nil && i<le) {
		    if (next instanceof Cons) {
			i++;
			first = next;
			next = ((Cons) next).cdr.request();
		    }
		    else
			return error("argument #1 not DMLList",val);
		}
		if (i<le)
		    return General.Subscript.raise();
		else
		    return ((Cons) first).car;
	    } else
		return error("argument #1 not DMLList",val);
	}
    }
    /** <code>val nth : ('a list * int) -> 'a</code>*/
    final public static Nth nth = new Nth();

    final public static class Take extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,2,"List.take");
	    DMLValue n = args[1].request();
	    if (!(n instanceof DMLInt))
		return error("argument #2 not DMLInt",val);
	    int le = ((DMLInt) n).getInt();
	    if (le<0)
		return General.Subscript.raise();
	    DMLValue first = args[0].request();
	    if (first==nil)
		return Empty.raise();
	    else if (first instanceof Cons) {
		int i=0;
		Cons newList = new Cons(null,null);
		Cons cons = newList;
		while (first!=nil && i<le) {
		    if (first instanceof Cons) {
			Cons fc = (Cons) first;
			i++;
			cons.cdr = new Cons(fc.car,null);
			cons=(Cons)cons.cdr;
			first = fc.cdr.request();
		    }
		    else
			return error("argument #1 not DMLList",val);
		}
		if (i>le)
		    return General.Subscript.raise();
		else {
		    cons.cdr=nil;
		    return newList.cdr;
		}
	    } else
		return error("argument not DMLList",val);
	}
    }
    /** <code>val take : ('a list * int) -> 'a list </code>*/
    final public static Take take = new Take();

    final public static class Drop extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,2,"List.drop");
	    DMLValue n = args[1].request();
	    if (!(n instanceof DMLInt))
		return error("argument #2 not DMLInt",val);
	    int le = ((DMLInt) n).getInt();
	    if (le<0)
		return General.Subscript.raise();
	    DMLValue first = args[0].request();
	    if (first==nil)
		return Empty.raise();
	    else if (first instanceof Cons) {
		int i=0;
		DMLValue next = ((Cons) first).cdr.request();
		while (next!=nil && i<le) {
		    if (next instanceof Cons) {
			i++;
			first = next;
			next = ((Cons) next).cdr.request();
		    }
		    else
			return error("argument #1 not DMLList",val);
		}
		if (i<le)
		    return General.Subscript.raise();
		else
		    return ((Cons) first).cdr;
	    } else
		return error("argument not DMLList",val);
	}
    }
    /** <code>val drop : ('a list * int) -> 'a list</code>*/
    final public static Drop drop = new Drop();

    final public static class Rev extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.rev");
	    DMLValue first = args[0].request();
	    if (first==nil)
		return Empty.raise();
	    else if (first instanceof Cons) {
 		Cons cons = new Cons(((Cons) first).car,nil);
		first = ((Cons) first).cdr.request();
		while (first!=nil) {
		    if (first instanceof Cons) {
			Cons fc = (Cons) first;
			cons = new Cons(fc.car,cons);
			first = fc.cdr.request();
		    }
		    else
			return error("argument #1 not DMLList",val);
		}
		return cons;
	    } else
		return error("argument not DMLList",val);
	}
    }
    /** <code>val rev : 'a list -> 'a list </code>*/
    final public static Rev rev = new Rev();

    final public static class Concat extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.concat");
	    DMLValue first = args[0].request();
	    if (first==nil)
		return nil;
	    else if (first instanceof Cons) {
		Cons result = new Cons(null,null);
		Cons cons = result;
		while (first!=nil) {
		    DMLValue li = ((Cons) first).car;
		    if (li==nil) {
			first=((Cons) first).cdr.request();
			continue;
		    }
		    else if (li instanceof Cons) {
			while (li!=nil) {
			    if (li instanceof Cons) {
				Cons l = (Cons) li;
				cons.cdr = new Cons(l.car,null);
				cons=(Cons) cons.cdr;
				li = l.cdr.request();
			    } else
				return error("argument not DMLList list",val);
			}
		    } else
			return error("argument not DMLList",val);
		    first=((Cons) first).cdr.request();
		}
		cons.cdr=nil;
		return result.cdr;
	    } else
		return error("argument not DMLList",val);
	}
    }
    /** <code>val concat : 'a list list -> 'a list </code>*/
    final public static Concat concat = new Concat();

    final public static class RevAppend extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,2,"List.revAppend");
	    DMLValue first = args[0].request();
	    if (first==nil)
		return args[1];
	    else if (first instanceof Cons) {
		Cons cons = new Cons(((Cons) first).car,args[1]);
		first = ((Cons) first).cdr.request();
		while (first!=nil) {
		    if (first instanceof Cons) {
			Cons fc = (Cons) first;
			cons = new Cons(fc.car,cons);
			first = fc.cdr.request();
		    }
		    else
			return error("argument not DMLList",val);
		}
		return cons;
	    } else
		return error("argument not DMLList",val);
	}
    }
    /** <code>val revAppend : ('a list * 'a list) -> 'a list </code>*/
    final public static RevAppend revAppend = new RevAppend();

    final public static class App extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.app");
	    return new App1(args[0]);
	}
	final public static class App1 extends DMLBuiltin {
	    DMLValue fun = null;
	    App1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) {
		DMLValue[] args=fromTuple(val,1,"List.app1");
		DMLValue l = args[0].request();
		while (l instanceof Cons) {
		    Cons lc = (Cons) l;
		    fun.apply(lc.car);
		    l = lc.cdr.request();
		}
		if (l instanceof Nil)
		    return DMLConstants.dmlunit;
		else
		    return error("argument not DMLList",val);
	    }
	}
    }
    /** <code>val app : ('a -> unit) -> 'a list -> unit </code>*/
    final public static App app = new App();

    final public static class Map extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.map");
	    return new Map1(args[0]);
	}
	final public static class Map1 extends DMLBuiltin {
	    DMLValue fun = null;
	    Map1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) {
		DMLValue[] args=fromTuple(val,1,"List.map1");
		DMLValue l = args[0].request();
		if (l==nil)
		    return nil;
		Cons first = new Cons(null,null);
		Cons list = first;
		while (l instanceof Cons) {
		    Cons lc = (Cons) l;
		    list.cdr=new Cons(fun.apply(new Tuple1(lc.car)),
				      null);
		    list=(Cons) list.cdr;
		    l = lc.cdr.request();
		}
		if (l==nil) {
		    list.cdr=nil;
		    return first.cdr;
		}
		else
		    return error("argument not DMLList",val);
	    }
	}
    }
    /** <code>val map : ('a -> 'b) -> 'a list -> 'b list </code>*/
    final public static Map map = new Map();

    final public static class MapPartial extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.mapPartial");
	    return new MapPartial1(args[0]);
	}
	final public static class MapPartial1 extends DMLBuiltin {
	    DMLValue fun = null;
	    MapPartial1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) {
		DMLValue[] args=fromTuple(val,1,"List.mapPartial1");
		DMLValue l = args[0].request();
		if (l==nil)
		    return nil;
		Cons first = new Cons(null,null);
		Cons list = first;
		while (l instanceof Cons) {
		    Cons lc = (Cons) l;
		    DMLValue res=fun.apply(new Tuple1(lc.car));
		    if (res!=Option.NONE) {
			list.cdr = new Cons(lc.car,null);
			list=(Cons)list.cdr;
		    }
		    l = lc.cdr.request();
		}
		if (l==nil) {
		    list.cdr=nil;
		    return first.cdr;
		}
		else
		    return error("argument not DMLList",val);
	    }
	}
    }
    /** <code>val mapPartial : ('a -> 'b option) -> 'a list -> 'b list </code>*/
    final public static MapPartial mapPartial = new MapPartial();

    final public static class Find extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.find");
	    return new Find1(args[0]);
	}
	final public static class Find1 extends DMLBuiltin {
	    DMLValue fun = null;
	    Find1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) {
		DMLValue[] args=fromTuple(val,1,"List.find1");
		DMLValue l = args[0].request();
		if (l==nil)
		    return DMLConstants.dmlfalse;
		while (l instanceof Cons) {
		    Cons lc = (Cons) l;
		    DMLValue res=fun.apply(new Tuple1(lc.car));
		    if (res==DMLConstants.dmltrue)
			return Option.SOME.apply(lc.car);
		    l = lc.cdr.request();
		}
		if (l==nil) {
		    return Option.NONE;
		}
		else
		    return error("argument not DMLList",val);
	    }
	}
    }
    /** <code>val find : ('a -> bool) -> 'a list -> 'a option </code>*/
    final public static Find find = new Find();

    final public static class Filter extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.filter");
	    return new Filter1(args[0]);
	}
	final public static class Filter1 extends DMLBuiltin {
	    DMLValue fun = null;
	    Filter1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) {
		DMLValue[] args=fromTuple(val,1,"List.filter1");
		DMLValue l = args[0].request();
		if (l==nil)
		    return nil;
		Cons first = new Cons(null,null);
		Cons list = first;
		while (l instanceof Cons) {
		    Cons lc = (Cons) l;
		    DMLValue res=fun.apply(new Tuple1(lc.car));
		    if (res==DMLConstants.dmltrue) {
			list.cdr = new Cons(lc.car,null);
			list=(Cons)list.cdr;
		    }
		    l = lc.cdr.request();
		}
		if (l==nil) {
		    list.cdr=nil;
		    return first.cdr;
		}
		else
		    return error("argument not DMLList",val);
	    }
	}
    }
    /** <code>val filter : ('a -> bool) -> 'a list -> 'a list </code>*/
    final public static Filter filter = new Filter();

    final public static class Partition extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.partition");
	    return new Partition1(args[0]);
	}
	final public static class Partition1 extends DMLBuiltin {
	    DMLValue fun = null;
	    Partition1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) {
		DMLValue[] args=fromTuple(val,1,"List.partition1");
		DMLValue l = args[0].request();
		if (l==nil)
		    return nil;
		Cons neg = new Cons(null,null);
		Cons nlist = neg;
		Cons pos = new Cons(null,null);
		Cons plist = pos;
		while (l instanceof Cons) {
		    Cons lc = (Cons) l;
		    DMLValue res=fun.apply(new Tuple1(lc.car));
		    if (res==DMLConstants.dmltrue) {
			plist.cdr = new Cons(lc.car,null);
			plist=(Cons) plist.cdr;
		    }
		    else {
			nlist.cdr = new Cons(lc.car,null);
			nlist=(Cons) nlist.cdr;
		    }
		    l = lc.cdr.request();
		}
		if (l==nil) {
		    plist.cdr=nil;
		    nlist.cdr=nil;
		    return new Tuple2(pos.cdr,neg.cdr);
		}
		else
		    return error("argument not DMLList",val);
	    }
	}
    }
    /** <code>val partition : ('a -> bool) -> 'a list -> ('a list * 'a list) </code>*/
    final public static Partition partition = new Partition();

    final public static class Foldl extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.foldl");
	    return new Foldl1(args[0]);
	}
	final public static class Foldl1 extends DMLBuiltin {
	    DMLValue fun = null;
	    Foldl1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) {
		DMLValue[] args=fromTuple(val,1,"List.foldl1");
		return new Foldl2(fun,args[0]);
	    }
	    final public static class Foldl2 extends DMLBuiltin {
		DMLValue fun = null; DMLValue init = null;
		Foldl2(DMLValue f, DMLValue i) {
		    fun=f;
		    init = i;
		}
		final public DMLValue apply(DMLValue val) {
		    DMLValue[] args=fromTuple(val,1,"List.foldl2");
		    DMLValue li = args[0].request();
		    if (li==nil)
			return init;
		    else if (li instanceof Cons) {
			DMLValue result=init;
			while (li instanceof Cons) {
			    Cons lc = (Cons) li;
			    result=fun.apply(new Tuple2(lc.car,result));
			    li = lc.cdr;
			}
			if (li==nil)
			    return result;
			else
			    return error("argument not DMLList",val);
		    } else
			return error("argument not DMLList",val);
		}
	    }
	}
    }
    /** <code>val foldl : (('a * 'b) -> 'b) -> 'b -> 'a list -> 'b </code>*/
    final public static Foldl foldl = new Foldl();

    final public static class Foldr extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.foldr");
	    return new Foldr1(args[0]);
	}
	final public static class Foldr1 extends DMLBuiltin {
	    DMLValue fun = null;
	    Foldr1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) {
		DMLValue[] args=fromTuple(val,1,"List.foldr1");
		return new Foldr2(fun,args[0]);
	    }
	    final public static class Foldr2 extends DMLBuiltin {
		DMLValue fun = null; DMLValue init = null;
		Foldr2(DMLValue f, DMLValue i) {
		    fun=f;
		    init = i;
		}
		final public DMLValue apply(DMLValue val) {
		    DMLValue[] args=fromTuple(val,1,"List.foldr2");
		    DMLValue li = args[0].request();
		    if (li==nil)
			return init;
		    else if (li instanceof Cons) {
			Cons cons = new Cons(((Cons) li).car,nil);
			li = ((Cons) li).cdr.request();
			while (li!=nil) {
			    if (li instanceof Cons) {
				Cons lc = (Cons) li;
				cons = new Cons(lc.car,cons);
				li = lc.cdr.request();
			    }
			    else
				return error("argument #1 not DMLList",val);
			}
			// in cons ist jetzt die umgedrehte Liste
			DMLValue result=init;
			while (cons instanceof Cons) {
			    Cons cc = (Cons) cons;
			    result=fun.apply(new Tuple2(cc.car,result));
			    if (cc.cdr instanceof Cons)
				cons = (Cons) cc.cdr;
			    else
				break;
			}
			return result;
		    } else
			return error("argument not DMLList",val);
		}
	    }
	}
    }
    /** <code>val foldr : (('a * 'b) -> 'b) -> 'b -> 'a list -> 'b </code>*/
    final public static Foldr foldr = new Foldr();

    final public static class Exists extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.exists");
	    return new Exists1(args[0]);
	}
	final public static class Exists1 extends DMLBuiltin {
	    DMLValue fun = null;
	    Exists1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) {
		DMLValue[] args=fromTuple(val,1,"List.exists1");
		DMLValue l = args[0].request();
		if (l==nil)
		    return DMLConstants.dmlfalse;
		while (l instanceof Cons) {
		    Cons lc = (Cons) l;
		    DMLValue res=fun.apply(new Tuple1(lc.car));
		    if (res==DMLConstants.dmltrue)
			return DMLConstants.dmltrue;
		    l = lc.cdr.request();
		}
		if (l==nil) {
		    return DMLConstants.dmlfalse;
		}
		else
		    return error("argument not DMLList",val);
	    }
	}
    }
    /** <code>val exists : ('a -> bool) -> 'a list -> bool </code>*/
    final public static Exists exists = new Exists();

    final public static class All extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,1,"List.all");
	    return new All1(args[0]);
	}
	final public static class All1 extends DMLBuiltin {
	    DMLValue fun = null;
	    All1(DMLValue f) { fun=f; }
	    final public DMLValue apply(DMLValue val) {
		DMLValue[] args=fromTuple(val,1,"List.all1");
		DMLValue l = args[0].request();
		if (l==nil)
		    return DMLConstants.dmltrue;
		while (l instanceof Cons) {
		    Cons lc = (Cons) l;
		    DMLValue res=fun.apply(new Tuple1(lc.car));
		    if (res!=DMLConstants.dmltrue)
			return DMLConstants.dmlfalse;
		    l = lc.cdr.request();
		}
		if (l==nil) {
		    return DMLConstants.dmltrue;
		}
		else
		    return error("argument not DMLList",val);
	    }
	}
    }
    /** <code>val all : ('a -> bool) -> 'a list -> bool </code>*/
    final public static All all = new All();

    final public static class Tabulate extends DMLBuiltin {
	final public DMLValue apply(DMLValue val) {
	    DMLValue[] args=fromTuple(val,2,"List.tabulate");
	    DMLValue n = args[0].request();
	    if (!(n instanceof DMLInt))
		return error("argument #1 not DMLInt",val);
	    int k = ((DMLInt) n).getInt();
	    if (k<0)
		return General.Size.raise();
	    DMLValue fun = args[1];
	    Cons first = new Cons(null,null);
	    Cons cons = first;
	    for(int i=0; i<k; i++) {
		cons.cdr=new Cons(fun.apply(new Tuple1(new DMLInt(i))),null);
		cons=(Cons)cons.cdr;
	    }
	    cons.cdr=nil;
	    return first.cdr;
	}
    }
    /** <code>val tabulate : (int * (int -> 'a)) -> 'a list }</code>*/
    final public static Tabulate tabulate = new Tabulate();

    // Hilfsfunktionen
    final private static DMLValue[] fromTuple
	(DMLValue v, /*value-Tuple*/
	 int ea,     // erwartete Anzahl Argumente
	 java.lang.String errMsg) {
	v=v.request();
	if (v instanceof DMLTuple) {
	    DMLTuple t=(DMLTuple) v;
	    if (t.getArity()==ea) {
		DMLValue[] vals = new DMLValue[ea];
		for(int i=0; i<ea; i++)
		    vals[i]=t.getByIndex(i);
		return vals;
	    }
	    else
		error("wrong number of arguments in "+errMsg, v);
	}
	else
	    error("wrong argument type for "+errMsg,v);
	return null;
    }

    final private static DMLValue error
	(java.lang.String msg, DMLValue v) {
	// sonst: Fehler
	DMLValue[] err = {
	    new DMLString(msg),
	    v};
	return DMLConstants.
	    runtimeError.apply(new Tuple(err)).raise();
    }
}
