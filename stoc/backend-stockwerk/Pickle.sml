(*
 * Author:
 *   Leif Kornstaedt <kornstae@ps.uni-sb.de>
 *
 * Copyright:
 *   Leif Kornstaedt, 2000
 *
 * Last change:
 *   $Date$ by $Author$
 *   $Revision$
 *)

structure Pickle :> PICKLE =
    struct
	structure C = EmptyContext

	datatype value =
	    Prim of string
	  | Int of LargeInt.int
	  | Word of LargeWord.word
	  | Char of WideChar.char
	  | String of WideString.string
	  | Real of string
	  | Constructor of Stamp.t

	type id = int

	datatype idDef =
	    IdDef of id
	  | Wildcard

	datatype idRef =
	    Local of id
	  | Global of int

	datatype con =
	    Con of idRef
	  | StaticCon of value

	datatype 'a args =
	    OneArg of 'a
	  | TupArgs of 'a vector

	datatype instr =
	    Kill of id vector * instr
	  | PutConst of id * value * instr
	  | PutVar of id * idRef * instr
	  | PutNew of id * instr
	  | PutTag of id * int * idRef vector * instr
	  | PutCon of id * con * idRef vector * instr
	  | PutRef of id * idRef * instr
	  | PutTup of id * idRef vector * instr
	  | PutVec of id * idRef vector * instr
	  | PutFun of id * idRef vector * function * instr
	  | AppPrim of idDef * string * idRef vector * instr option
	  | AppVar of idDef args * idRef * idRef args * instr option
	  | AppConst of idDef args * value * idRef args * instr option
	  | GetRef of id * idRef * instr
	  | GetTup of idDef vector * idRef * instr
	  | Raise of idRef
	  | Try of instr * idDef * instr
	  | EndTry of instr
	  | EndHandle of instr
	  | IntTest of idRef * (int * instr) vector * instr
	  | RealTest of idRef * (real * instr) vector * instr
	  | StringTest of idRef * (string * instr) vector * instr
	  | TagTest of idRef * (int * instr) vector
			     * (int * idDef vector * instr) vector * instr
	  | ConTest of idRef * (con * instr) vector
			     * (con * idDef vector * instr) vector * instr
	  | VecTest of idRef * (idDef vector * instr) vector * instr
	  | Return of idRef args
	and function = Function of int * idDef args * instr

	type t = value
    end
