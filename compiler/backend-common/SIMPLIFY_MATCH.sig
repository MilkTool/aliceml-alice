(*
 * Author:
 *   Leif Kornstaedt <kornstae@ps.uni-sb.de>
 *
 * Copyright:
 *   Leif Kornstaedt, 1999
 *
 * Last change:
 *   $Date$ by $Author$
 *   $Revision$
 *)

signature SIMPLIFY_MATCH =
    sig
	structure I: INTERMEDIATE_GRAMMAR = IntermediateGrammar
	structure O: IMPERATIVE_GRAMMAR = ImperativeGrammar

	type pos = Label.t list
	type typ = Type.t

	datatype test =
	    LitTest of I.lit
	  | ConTest of I.longid * typ option * O.conArity
	  | RefTest of typ
	  | TupTest of typ list
	  | RecTest of (Label.t * typ) list
	    (* sorted, all labels distinct, no tuple *)
	  | LabTest of Label.t * typ
	  | VecTest of typ list
	  | GuardTest of mapping * I.exp
	  | DecTest of mapping * I.dec list
	withtype mapping = (pos * I.id) list

	val longidToLabel: I.longid -> Label.t

	datatype testGraph =
	    Node of pos * test * testGraph ref * testGraph ref * nodeStatus ref
	  | Leaf of O.body * O.body option ref
	  | Default
	and nodeStatus =
	    Initial
	  | Raw of testGraph list * testGraph list
	  | Cooked of (pos * test) list * (pos * test) list
	  | Optimized of (pos * test) list * (pos * test) list
	  | Translated of O.body

	type consequent = (Source.region * O.body option ref)

	val buildGraph: (Source.region * I.pat * O.body) list * O.body ->
	    testGraph * consequent list

	val buildFunArgs: (Source.region * I.pat * O.body) list * O.body ->
	    O.id O.args * testGraph * mapping * consequent list
    end
