(*
 * Authors:
 *   Andreas Rossberg <rossberg@ps.uni-sb.de>
 *   Leif Kornstaedt <kornstae@ps.uni-sb.de>
 *
 * Copyright:
 *   Andreas Rossberg, 2000
 *   Leif Kornstaedt, 2001
 *
 * Last change:
 *   $Date$ by $Author$
 *   $Revision$
 *)

functor MakeContextDumpingPhase(
	structure Phase :    PHASE
	structure Switches : SWITCHES
	val header : string
	val pp :     Phase.C.t -> PrettyPrint.doc
	val switch : bool ref
    ) : PHASE =
struct
    open Phase

    fun translate context desc_rep =
	let
	    val rep' = Phase.translate context desc_rep
	in
	    if not(!switch) then () else
	    (
		TextIO.output(Switches.Debug.logOut, "-- " ^ header ^ ":\n");
		PrettyPrint.output(Switches.Debug.logOut, pp context,
				   !Switches.Debug.logWidth);
		TextIO.output(Switches.Debug.logOut, "\n");
		TextIO.flushOut Switches.Debug.logOut
	    );
	    rep'
	end
end
