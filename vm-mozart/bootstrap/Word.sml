(*
 * Authors:
 *   Andreas Rossberg <rossberg@ps.uni-sb.de>
 *   Leif Kornstaedt <kornstae@ps.uni-sb.de>
 *
 * Copyright:
 *   Andreas Rossberg, 1999
 *   Leif Kornstaedt, 1999
 *
 * Last change:
 *   $Date$ by $Author$
 *   $Revision$
 *)

import

structure BootWord:
    sig
	val fromInt' : int * int -> word
	val toInt : word -> int
	val toLargeInt : word -> LargeInt.int
	val toIntX : word -> int
	val orb : word * word -> word
	val xorb : word * word -> word
	val andb : word * word -> word
	val notb : word * word -> word
	val op<< : word * word -> word
	val op>> : word * word -> word
	val op~>> : word * word -> word
	val toString : word -> string
    end

from "../BootWord.ozf"

structure Word =
    struct
	type word = word

	fun fromInt x = BootWord.fromInt' (31, x)
	fun fromLargeInt x = BootWord.fromInt' (31, x)

	val toInt = BootWord.toInt
	val toLargeInt = BootWord.toInt
	val toIntX = BootWord.toIntX
	val orb = BootWord.orb
	val xorb = BootWord.xorb
	val andb = BootWord.andb
	val notb = BootWord.notb
	val op<< = BootWord.<<
	val op>> = BootWord.>>
	val op~>> = BootWord.~>>
	val toString = BootWord.toString

	val op>= = op>=

	fun fromLargeWord w = w
	fun toLargeWord w = w

	local
	    open StringCvt
	    fun skipWSget getc source = getc (dropl Char.isSpace getc source)

	    (* Below, 48 = Char.ord #"0" and 55 = Char.ord #"A" - 10. *)
	    fun decval c = fromInt (Char.ord c) - fromInt 48;
	    fun hexval c =
		if #"0" <= c andalso c <= #"9" then
		    fromInt (Char.ord c) - fromInt 48
		else
		    (fromInt (Char.ord c) - fromInt 55) mod (fromInt 32);
	in
	    fun scan radix getc source =
		let open StringCvt
		    val source = skipWS getc source
		    val (isDigit, factor) =
			case radix of
			    BIN => (fn c => (#"0" <= c andalso c <= #"1"),  2)
			  | OCT => (fn c => (#"0" <= c andalso c <= #"7"),  8)
			  | DEC => (Char.isDigit,                          10)
			  | HEX => (Char.isHexDigit,                       16)
		    fun dig1 NONE              = NONE
		      | dig1 (SOME (c1, src1)) =
			let fun digr res src =
			    case getc src of
				NONE           => SOME (res, src)
			      | SOME (c, rest) =>
				    if isDigit c then
					digr (fromInt factor * res + hexval c)
					rest
				    else SOME (res, src)
			in
			    if isDigit c1 then digr (hexval c1) src1
			    else NONE
			end
		    fun getdigs after0 src =
			case dig1 (getc src) of
			    NONE => SOME(fromInt 0, after0)
			  | res  => res
		    fun hexprefix after0 src =
			if radix <> HEX then getdigs after0 src
			else
			    case getc src of
				SOME(#"x", rest) => getdigs after0 rest
			      | SOME(#"X", rest) => getdigs after0 rest
			      | SOME _           => getdigs after0 src
			      | NONE => SOME(fromInt 0, after0)
		in
		    case getc source of
			SOME(#"0", after0) =>
			    (case getc after0 of
				 SOME(#"w", src2) => hexprefix after0 src2
			       | SOME _           => hexprefix after0 after0
			       | NONE             => SOME(fromInt 0, after0))
		      | SOME _ => dig1 (getc source)
		      | NONE   => NONE
		end
	end
    end

structure LargeWord = Word
