signature TYPE =
  sig

    datatype con_sort = OPEN | CLOSED

    datatype kind = STAR | ARROW of kind * kind		(* [kappa,k] *)

    type lab  = Lab.t					(* [lab,l] *)
    type path = Path.t					(* [pi,p] *)
    type con  = kind * con_sort * path			(* [chi,c] *)

    type typ						(* [tau,t] *)
    type row						(* [rho,r] *)
    type alpha						(* [alpha,a] *)

    type t = typ

    type rea = typ PathMap.t


    (* Injections *)

    val unknown :	unit        -> typ
    val inArrow :	typ * typ   -> typ
    val inTuple :	typ list    -> typ
    val inRow :		row         -> typ
    val inSum :		row         -> typ
    val inVar :		alpha       -> typ
    val inCon :		con         -> typ
    val inAll :		alpha * typ -> typ
    val inExist :	alpha * typ -> typ
    val inLambda :	alpha * typ -> typ
    val inApp :		typ * typ   -> typ
    val inRec :		typ         -> typ

    val var :		kind -> alpha

    (* Projections *)

    exception Type

    val asArrow :	typ -> typ * typ	(* Type *)
    val asTuple :	typ -> typ list		(* Type *)
    val asRow :		typ -> row		(* Type *)
    val asSum :		typ -> row		(* Type *)
    val asVar :		typ -> alpha		(* Type *)
    val asCon :		typ -> con		(* Type *)
    val asAll :		typ -> alpha * typ	(* Type *)
    val asExist :	typ -> alpha * typ	(* Type *)
    val asLambda :	typ -> alpha * typ	(* Type *)
    val asApp :		typ -> typ * typ	(* Type *)
    val asRec :		typ -> typ		(* Type *)

    (* Copying and instantiation *)

    val instance :	typ -> typ
    val skolem :	typ -> typ
    val clone :		typ -> typ
    val realise :	rea -> typ -> typ

    (* Complex extractions *)

    val kind :		typ   -> kind
    val kindVar :	alpha -> kind

    val path :		typ -> path		(* Type *)
    val pathCon :	con -> path

    val paths :		typ -> PathSet.t

    (* Operations on rows *)

    exception Row

    val unknownRow :	unit -> row
    val emptyRow :	unit -> row
    val extendRow :	lab * typ * row -> row	(* Row *)

    (* Unification and closure *)

    exception Unify of typ * typ

    val unify :		typ * typ -> unit	(* Unify *)
    val close :		typ -> unit

    (* Level management *)

    val enterLevel :	unit -> unit
    val exitLevel :	unit -> unit

  end
