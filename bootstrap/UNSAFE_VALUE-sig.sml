(* Dummy replacement for bootstrapping *)

signature UNSAFE_VALUE =
    sig
	(* Label vectors must always be sorted *)

	val cast: 'a_value -> 'a
	val same: 'a * 'a -> bool
	val awaitRequest : 'a -> 'a

	(* Projections *)

	val proj: 'prod_value * Label.t vector * int -> 'value
	val projTuple: 'tuple_value * int * int -> 'value

	val tag: 'sum_value * Label.t vector -> int
	val projTagged: 'sum_value * Label.t vector * int -> 'value
	val projTaggedTuple: 'sum_value * int * int -> 'value

	val con: 'ext_value -> 'con_value
	val projConstructed: 'ext_value * Label.t vector * int -> 'value
	val projConstructedTuple: 'ext_value * int * int -> 'value

	val projPoly: 'prod_value * Label.t -> 'value

	(* Construction *)

	val prod: (Label.t * 'value) vector -> 'prod_value
	val tuple: 'value vector -> 'tuple_value

	val tagged: Label.t vector * int *
		    (Label.t * 'value) vector -> 'sum_value
	val taggedTuple: Label.t vector * int *
			 'value vector -> 'sum_value

	val closure: 'code * 'value vector -> 'closure_value

	val prim: string -> 'value

	(* Inspection *)

	val conName: 'con_value -> Name.t

	(* These return one of:
	 *   -2      could not be determined
	 *   -1      single-argument
	 *   n >= 0  tuple/record with n fields
	 *)
	val inArity: 'function_value -> int
	val outArity: 'function_value -> int
    end
