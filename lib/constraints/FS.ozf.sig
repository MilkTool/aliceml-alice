(*
 * Authors:
 *   Thorsten Brunklaus <brunklaus@ps.uni-sb.de>
 *   Andreas Rossberg <rossberg@ps.uni-sb.de>
 *
 * Copyright:
 *   Thorsten Brunklaus, 2000
 *
 * Last Change:
 *   $Date$ by $Author$
 *   $Revision$
 *
 *)

import structure FD from "x-alice:/lib/constraints/FD.ozf"

local
    open FD
in
    signature FS_COMPONENT =
	sig
	    signature FS =
		sig
		    type fs

		    (* Allocation Function *)
		    val fs : (domain * domain) option -> fs
		    val fsVec : int * domain * domain -> fs vector

		    (* Integer FS *)
		    structure Int :
			sig
			    val min : fs * fd -> unit
			    val max : fs * fd -> unit
			    val convex : fs -> unit
			    val match : fs * fd vector -> unit
			    val minN : fs * fd vector -> unit
			    val maxN : fs * fd vector -> unit
			end

		    (* Standard Propagators *)
		    val compl : fs * fs -> unit
		    val complIn : fs * fs * fs -> unit
		    val incl : fd * fs -> unit
		    val excl : fd * fs -> unit
		    val card : fs * fd -> unit
		    val cardRange : int * int * fs -> unit
		    val isIn : int * fs -> bool
		    val isEmpty : fs -> bool

		    val difference : fs * fs * fs -> unit
		    val intersect : fs * fs * fs -> unit
		    val intersectN : fs vector * fs -> unit
		    val union : fs * fs * fs -> unit
		    val unionN : fs vector * fs -> unit
		    val subset : fs * fs -> unit
		    val disjoint : fs * fs -> unit
		    val disjointN : fs vector -> unit
		    val distinct : fs * fs -> unit
		    val distinctN : fs vector -> unit
		    val partition : fs vector * fs -> unit

		    (* Values *)
		    val value : domain -> fs
		    val emptyValue : unit -> fs
		    val singletonValue : int -> fs
		    val universalValue : unit -> fs
		    val isValue : fs -> bool
		    
		    (* Reified Propagators *)
		    structure Reified :
			sig
			    val isIn : int * fs * bin -> unit
			    val areIn : int list * fs * bin list -> unit
			    val incl : fd * fs * bin -> unit
			    val equal : fs * fs * bin -> unit
			    val partition : fs list * int list * fs * bin list -> unit
			end

		    (* Reflection *)
		    structure Reflect :
			sig
			    val card : fs -> domain
			    val lowerBound : fs -> domain
			    val unknown : fs -> domain
			    val upperBound : fs -> domain

			    val cardOfLowerBound : fs -> int
			    val cardOfUnknown : fs -> int
			    val cardOfUpperBound : fs -> int
			end
		end

	    structure FS : FS
	end
end
