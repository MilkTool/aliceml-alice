(*
 * A source file
 *)


structure Source :> SOURCE =
  struct

    type source	= string
    type t	= source

    type pos	= int * int
    type region	= pos * pos

    type desc	= Url.t option

    val nowhere = ((0,0),(0,0))

    fun fromString s	= s
    fun toString s	= s

    fun over(reg1: region, reg2: region)	= (#1 reg1, #2 reg2)
    fun between(reg1: region, reg2: region)	= (#2 reg1, #1 reg2)

    fun posToString(lin,col) =
	Int.toString lin ^ "." ^ Int.toString col

    fun regionToString(region as (pos1,pos2)) =
	if region = nowhere then
	    "(unknown position)"
	else
	    posToString pos1 ^ "-" ^ posToString pos2

    val stringDesc = NONE
    val urlDesc    = SOME
    fun url d      = d

  end
