(*
import structure Stamp	from "Stamp"
import structure Name	from "Name"
import structure Label	from "Label"

import structure Url	from "Url"

import signature INTERMEDIATE_GRAMMAR	from "INTERMEDIATE_GRAMMAR"
*)


functor MakeIntermediateGrammar(type lab_info
				type id_info
				type longid_info
				type exp_info
				type pat_info
				type 'a field_info
				type match_info
				type dec_info
				type sign) : INTERMEDIATE_GRAMMAR =
  struct

    (* Generic *)

    type lab_info	= lab_info
    type id_info	= id_info
    type longid_info	= longid_info
    type exp_info	= exp_info
    type pat_info	= pat_info
    type 'a field_info	= 'a field_info
    type match_info	= match_info
    type dec_info	= dec_info

    type sign		= sign

    (* Literals *)

    datatype lit =
	  IntLit    of LargeInt.int		(* integer arithmetic *)
	| WordLit   of LargeWord.word		(* modulo arithmetic *)
	| CharLit   of WideChar.char		(* character *)
	| StringLit of WideString.string	(* character string *)
(*	| RealLit   of LargeReal.real		(* floating point *)
UNFINISHED: obsolete after bootstrapping:
*)	| RealLit   of string			(* floating point *)

    (* Identifiers *)

    datatype lab    = Lab     of lab_info * Label.t
    datatype id     = Id      of id_info * Stamp.t * Name.t
    datatype longid = ShortId of longid_info * id
		    | LongId  of longid_info * longid * lab

    (* Expressions *)

    datatype exp =
	  LitExp    of exp_info * lit			(* literal *)
	| VarExp    of exp_info * longid		(* variable *)
	| PrimExp   of exp_info * string		(* primitive value *)
	| NewExp    of exp_info * bool			(* new constructor *)
				(* bool : is n-ary *)
	| TagExp    of exp_info * lab * exp * bool	(* tagged value *)
				(* bool : is n-ary *)
	| ConExp    of exp_info * longid * exp * bool	(* constructed value *)
				(* bool : is n-ary *)
	| RefExp    of exp_info	* exp			(* reference *)
	| TupExp    of exp_info * exp vector		(* tuple *)
	| ProdExp   of exp_info * exp field vector	(* record / module *)
				(* all labels distinct *)
	| SelExp    of exp_info * lab * exp		(* field selection *)
	| VecExp    of exp_info * exp vector		(* vector *)
	| FunExp    of exp_info * match vector		(* function / functor *)
	| AppExp    of exp_info * exp * exp		(* application *)
	| AndExp    of exp_info * exp * exp		(* conjunction *)
	| OrExp     of exp_info * exp * exp		(* disjunction *)
	| IfExp     of exp_info * exp * exp * exp	(* conditional *)
	| SeqExp    of exp_info * exp vector		(* sequential *)
	| CaseExp   of exp_info * exp * match vector	(* case switch *)
	| RaiseExp  of exp_info * exp			(* exception raise *)
	| HandleExp of exp_info * exp * match vector	(* exception handler *)
	| FailExp   of exp_info				(* lazy failure *)
	| LazyExp   of exp_info * exp			(* by-need suspension *)
	| LetExp    of exp_info * dec vector * exp	(* local binding *)
	| UpExp     of exp_info * exp			(* type abstraction *)

    and 'a field = Field of 'a field_info * lab * 'a

    and match    = Match of match_info * pat * exp

    (* Patterns (always linear) *)

    and pat =
	  JokPat    of pat_info				(* joker (wildcard) *)
	| VarPat    of pat_info * id			(* variable *)
	| LitPat    of pat_info * lit			(* literal *)
	| TagPat    of pat_info * lab * pat * bool	(* tagged value *)
				(* bool : is n-ary *)
	| ConPat    of pat_info * longid * pat * bool	(* constructed *)
				(* bool : is n-ary *)
	| RefPat    of pat_info * pat			(* reference *)
	| TupPat    of pat_info * pat vector		(* tuple *)
	| ProdPat   of pat_info * pat field vector	(* record *)
				(* all labels distinct *)
	| VecPat    of pat_info * pat vector		(* vector *)
	| AsPat     of pat_info * pat * pat		(* conjunction *)
	| AltPat    of pat_info * pat vector		(* disjunction *)
				(* all patterns bind same ids *)
	| NegPat    of pat_info * pat			(* negation *)
	| GuardPat  of pat_info * pat * exp		(* guard *)
	| WithPat   of pat_info * pat * dec vector	(* local bindings *)

    (* Declarations *)

    and dec =
	  ValDec    of dec_info * pat * exp		(* value / module *)
	  		(* if inside RecDec, then
			 * (1) pat may not contain AltPat, NegPat, GuardPat,
			 *     WithPat
			 * (2) exp may only contain LitExp, VarExp, ConExp,
			 *     RefExp, TupExp, RowExp, VecExp, FunExp, AppExp
			 * (3) AppExps may only contain ConExp or RefExp
			 *     as first argument
			 * (4) if an VarPat on the LHS structurally corresponds
			 *     to an VarExp on the RHS then the RHS id may not
			 *     be bound on the LHS *)
	| RecDec    of dec_info * dec vector		(* recursion *)

    (* Components *)

    type comp = (id * sign * Url.t) vector * (exp * sign)
    type t = comp


    (* Projections *)

    fun stamp(Id(_,x,_))		= x
    fun name(Id(_,_,n))			= n
    fun lab(Lab(_,a))			= a

    fun infoLab(Lab(i,_))		= i
    fun infoId(Id(i,_,_))		= i
    fun infoLongid(ShortId(i,_))	= i
      | infoLongid(LongId(i,_,_))	= i

    fun infoExp(LitExp(i,_))		= i
      | infoExp(VarExp(i,_))		= i
      | infoExp(PrimExp(i,_))		= i
      | infoExp(NewExp(i,_))		= i
      | infoExp(TagExp(i,_,_,_))	= i
      | infoExp(ConExp(i,_,_,_))	= i
      | infoExp(RefExp(i,_))		= i
      | infoExp(TupExp(i,_))		= i
      | infoExp(ProdExp(i,_))		= i
      | infoExp(SelExp(i,_,_))		= i
      | infoExp(VecExp(i,_))		= i
      | infoExp(FunExp(i,_))		= i
      | infoExp(AppExp(i,_,_))		= i
      | infoExp(AndExp(i,_,_))		= i
      | infoExp(OrExp(i,_,_))		= i
      | infoExp(IfExp(i,_,_,_))		= i
      | infoExp(SeqExp(i,_))		= i
      | infoExp(CaseExp(i,_,_))		= i
      | infoExp(RaiseExp(i,_))		= i
      | infoExp(HandleExp(i,_,_))	= i
      | infoExp(FailExp(i))		= i
      | infoExp(LazyExp(i,_))		= i
      | infoExp(LetExp(i,_,_))		= i
      | infoExp(UpExp(i,_))		= i

    fun infoField(Field(i,_,_))		= i
    fun infoMatch(Match(i,_,_))		= i

    fun infoPat(JokPat(i))		= i
      | infoPat(VarPat(i,_))		= i
      | infoPat(LitPat(i,_))		= i
      | infoPat(TagPat(i,_,_,_))	= i
      | infoPat(ConPat(i,_,_,_))	= i
      | infoPat(RefPat(i,_))		= i
      | infoPat(TupPat(i,_))		= i
      | infoPat(ProdPat(i,_))		= i
      | infoPat(VecPat(i,_))		= i
      | infoPat(AsPat(i,_,_))		= i
      | infoPat(AltPat(i,_))		= i
      | infoPat(NegPat(i,_))		= i
      | infoPat(GuardPat(i,_,_))	= i
      | infoPat(WithPat(i,_,_))		= i

    fun infoDec(ValDec(i,_,_))		= i
      | infoDec(RecDec(i,_))		= i

  end
