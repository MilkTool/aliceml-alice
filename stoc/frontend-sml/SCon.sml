(*
 * Standard ML special constants
 *
 * Definition, section 2.2
 *)


functor SCon() :> SCON =
  struct

    datatype SCon =
	  INTEGER of int
	| WORD    of word
	| STRING  of string
	| CHAR    of char
	| REAL    of real


    val fromInt    = INTEGER
    val fromWord   = WORD
    val fromString = STRING
    val fromChar   = CHAR
    val fromReal   = REAL

    fun toString(INTEGER i) = Int.toString i
      | toString(WORD w)    = "0wx" ^ Word.toString w
      | toString(STRING s)  = "\""  ^ String.toCString s ^ "\""
      | toString(CHAR c)    = "\"#" ^ Char.toCString c   ^ "\""
      | toString(REAL r)    = Real.toString r

  end
