functor MakeAbstractGrammar(type fix_info
			    type vallab_info
			    type typlab_info
			    type modlab_info
			    type inflab_info
			    type valid_info
			    type typid_info
			    type modid_info
			    type infid_info
			    type vallongid_info
			    type typlongid_info
			    type modlongid_info
			    type inflongid_info
			    type exp_info
			    type pat_info
			    type 'a row_info
			    type 'a field_info
			    type match_info
			    type typ_info
			    type mod_info
			    type inf_info
			    type dec_info
			    type spec_info
			    type imp_info
			    type ann_info
			    type comp_info
			   ) : ABSTRACT_GRAMMAR =
  struct

    (* Generic *)

    type fix_info	= fix_info
    type vallab_info	= vallab_info
    type typlab_info	= typlab_info
    type modlab_info	= modlab_info
    type inflab_info	= inflab_info
    type valid_info	= valid_info
    type typid_info	= typid_info
    type modid_info	= modid_info
    type infid_info	= infid_info
    type vallongid_info	= vallongid_info
    type typlongid_info	= typlongid_info
    type modlongid_info	= modlongid_info
    type inflongid_info	= inflongid_info
    type exp_info	= exp_info
    type pat_info	= pat_info
    type 'a row_info	= 'a row_info
    type 'a field_info	= 'a field_info
    type match_info	= match_info
    type typ_info	= typ_info
    type mod_info	= mod_info
    type inf_info	= inf_info
    type dec_info	= dec_info
    type spec_info	= spec_info
    type imp_info	= imp_info
    type ann_info	= ann_info
    type comp_info	= comp_info

    (* Literals *)

    datatype lit =
	  IntLit    of LargeInt.int		(* integer *)
	| WordLit   of LargeWord.word		(* word *)
	| CharLit   of WideChar.char		(* character *)
	| StringLit of WideString.string	(* string *)
	| RealLit   of LargeReal.real		(* floating point *)

    (* Fixity *)

    datatype fix = Fix of fix_info * Fixity.t

    (* Identifiers *)

    datatype 'a lab		= Lab     of 'a * Label.t
    datatype 'a id		= Id      of 'a * Stamp.t * Name.t
    datatype ('a,'b,'c) longid	= ShortId of 'a * 'b id
				| LongId  of 'a * modlongid * 'c lab
    withtype vallab		= vallab_info lab
    and      typlab		= typlab_info lab
    and      modlab		= modlab_info lab
    and      inflab		= inflab_info lab
    and      valid		= valid_info id
    and      typid		= typid_info id
    and      modid		= modid_info id
    and      infid		= infid_info id
    and      vallongid		= (vallongid_info,valid_info,vallab_info) longid
    and      typlongid		= (typlongid_info,typid_info,typlab_info) longid
    and      modlongid		= (modlongid_info,modid_info,modlab_info) longid
    and      inflongid		= (inflongid_info,infid_info,inflab_info) longid

    (* Expressions *)

    datatype exp =
	  LitExp    of exp_info * lit		(* literal *)
	| VarExp    of exp_info * vallongid	(* variable *)
	| PrimExp   of exp_info * string * typ	(* builtin values *)
	| LabExp    of exp_info * vallab * typ	(* first-class label *)
	| NewExp    of exp_info * typ		(* first-class constructor *)
	| TagExp    of exp_info * vallab * vallongid option * exp (* tagged *)
	| ConExp    of exp_info * vallongid * exp (* constructed value *)
	| RefExp    of exp_info * exp		(* reference *)
	| TupExp    of exp_info * exp vector	(* tuple *)
	| ProdExp   of exp_info * exp row	(* product (record) *)
	| UpdExp    of exp_info * exp * exp row	(* record update *)
	| SelExp    of exp_info * vallab * exp	(* selection *)
	| VecExp    of exp_info * exp vector	(* vector *)
	| FunExp    of exp_info * match vector	(* function *)
	| AppExp    of exp_info * exp * exp	(* application *)
	| AndExp    of exp_info * exp * exp	(* short-circuit conjunction *)
	| OrExp     of exp_info * exp * exp	(* short-circuit disjunction *)
	| IfExp     of exp_info * exp * exp * exp (* conditional *)
	| SeqExp    of exp_info * exp vector	(* sequential expressions *)
	| CaseExp   of exp_info * exp * match vector (* case *)
	| FailExp   of exp_info			(* failure *)
	| RaiseExp  of exp_info * exp		(* exception raising *)
	| HandleExp of exp_info * exp * match vector (* exception handling *)
	| AnnExp    of exp_info * exp * typ	(* type annotation *)
	| LetExp    of exp_info * dec vector * exp (* let *)
	| PackExp   of exp_info * mod		(* package introduction *)

    and 'a row   = Row   of 'a row_info * 'a field vector * bool
    and 'a field = Field of 'a field_info * vallab * 'a

    and match    = Match of match_info * pat * exp

    (* Patterns *)

    and pat =
	  JokPat    of pat_info			(* joker (wildcard) *)
	| LitPat    of pat_info * lit		(* literal *)
	| VarPat    of pat_info * valid		(* variable *)
	| TagPat    of pat_info * vallab * vallongid option * pat (* tagged *)
	| ConPat    of pat_info * vallongid * pat (* constructed value *)
	| RefPat    of pat_info * pat		(* reference *)
	| TupPat    of pat_info * pat vector	(* tuple *)
	| ProdPat   of pat_info * pat row	(* row (record) *)
	| VecPat    of pat_info * pat vector	(* vector *)
	| AsPat     of pat_info * pat * pat	(* as (layered) pattern *)
	| AltPat    of pat_info * pat vector	(* alternative pattern *)
	| NegPat    of pat_info * pat		(* negated pattern *)
	| GuardPat  of pat_info * pat * exp	(* guarded pattern *)
	| AnnPat    of pat_info * pat * typ	(* type annotation *)
	| WithPat   of pat_info * pat * dec vector (* local declarations *)

    (* Types *)

    and typ =
	  VarTyp    of typ_info * typid		(* variable *)
	| ConTyp    of typ_info * typlongid	(* constructor *)
	| FunTyp    of typ_info * typid * typ	(* type function *)
	| AppTyp    of typ_info * typ * typ	(* constructor application *)
	| RefTyp    of typ_info * typ		(* reference type *)
	| TupTyp    of typ_info * typ vector	(* tuple (cartesian) type *)
	| ProdTyp   of typ_info * typ row	(* product (record) type *)
	| SumTyp    of typ_info * typ row	(* sum type (datatype) *)
	| ArrTyp    of typ_info * typ * typ	(* arrow (function) type *)
	| AllTyp    of typ_info * typid * typ	(* universal quantification *)
	| ExTyp     of typ_info * typid * typ	(* existential quantification *)
	| PackTyp   of typ_info * inf		(* package type *)
	| SingTyp   of typ_info * vallongid	(* singleton type *)
	| AbsTyp    of typ_info * string option	(* abstract type *)
	| ExtTyp    of typ_info * string option	(* extensible sum type *)

    (* Modules *)

    and mod =
	  VarMod    of mod_info * modid		(* module id *)
	| PrimMod   of mod_info * string * inf	(* builtin modules *)
	| StrMod    of mod_info * dec vector	(* structure *)
	| SelMod    of mod_info * modlab * mod	(* selection *)
	| FunMod    of mod_info * modid * inf * mod (* functor *)
	| AppMod    of mod_info * mod * mod	(* application *)
	| AnnMod    of mod_info * mod * inf	(* annotation *)
	| UpMod     of mod_info * mod * inf	(* coercion *)
	| LetMod    of mod_info * dec vector * mod (* let *)
	| UnpackMod of mod_info * exp * inf	(* package elimination *)

    (* Interfaces *)

    and inf =
	  TopInf    of inf_info			(* top interface *)
	| ConInf    of inf_info * inflongid	(* interface constructor *)
	| SigInf    of inf_info * spec vector	(* signature *)
	| FunInf    of inf_info * modid * inf * inf (* interface function *)
	| AppInf    of inf_info * inf * mod	(* interface application *)
	| CompInf   of inf_info * inf * inf	(* composition *)
	| ArrInf    of inf_info * modid * inf * inf (* functor interface *)
	| LetInf    of inf_info * dec vector * inf (* let *)
	| SingInf   of inf_info * mod		(* singleton interface *)
	| AbsInf    of inf_info * string option	(* abstract interface *)

    (* Declarations *)

    and dec =
	  ValDec    of dec_info * pat * exp	(* value *)
	| TypDec    of dec_info * typid * typ	(* type *)
	| ModDec    of dec_info * modid * mod	(* module *)
	| InfDec    of dec_info * infid * inf	(* interface *)
	| FixDec    of dec_info * vallab * fix	(* fixity *)
	| VarDec    of dec_info * typid * dec	(* scoped type variable *)
	| RecDec    of dec_info * dec vector	(* recursive declarations *)
	| LocalDec  of dec_info * dec vector	(* local declarations *)

    (* Specifications *)

    and spec =
	  ValSpec   of spec_info * valid * typ	(* value *)
	| TypSpec   of spec_info * typid * typ	(* type *)
	| ModSpec   of spec_info * modid * inf	(* module *)
	| InfSpec   of spec_info * infid * inf	(* interface *)
	| FixSpec   of spec_info * vallab * fix	(* fixity *)
	| RecSpec   of spec_info * spec vector	(* recursive specifications *)
	| ExtSpec   of spec_info * inf		(* extension (include) *)

    (* Import *)

    and imp =
	  ValImp of imp_info * valid * (typ_info,typ) desc	(* value *)
	| TypImp of imp_info * typid * (typ_info,typ) desc	(* type *)
	| ModImp of imp_info * modid * (inf_info,inf) desc	(* module *)
	| InfImp of imp_info * infid * (inf_info,inf) desc	(* interface *)
	| FixImp of imp_info * vallab * (fix_info,fix) desc	(* fixity *)
	| RecImp of imp_info * imp vector			(* recursive *)

    and ('info,'a) desc =
	  NoDesc   of 'info
	| SomeDesc of 'info * 'a

    (* Components *)

    and ann  = ImpAnn of ann_info * imp vector * Url.t

    and comp = Comp of comp_info * ann vector * dec vector

    type t = comp


    (* Projections *)

    fun stamp(Id(_,x,_))	= x
    fun name(Id(_,_,n))		= n
    fun lab(Lab(_,a))		= a

    fun infoLab(Lab(i,_))		= i
    fun infoId(Id(i,_,_))		= i
    fun infoLongid(ShortId(i,_))	= i
      | infoLongid(LongId(i,_,_))	= i

    fun infoExp(LitExp(i,_))		= i
      | infoExp(VarExp(i,_))		= i
      | infoExp(PrimExp(i,_,_))		= i
      | infoExp(LabExp(i,_,_))		= i
      | infoExp(NewExp(i,_))		= i
      | infoExp(TagExp(i,_,_,_))	= i
      | infoExp(ConExp(i,_,_))		= i
      | infoExp(RefExp(i,_))		= i
      | infoExp(TupExp(i,_))		= i
      | infoExp(ProdExp(i,_))		= i
      | infoExp(UpdExp(i,_,_))		= i
      | infoExp(SelExp(i,_,_))		= i
      | infoExp(VecExp(i,_))		= i
      | infoExp(FunExp(i,_))		= i
      | infoExp(AppExp(i,_,_))		= i
      | infoExp(AndExp(i,_,_))		= i
      | infoExp(OrExp(i,_,_))		= i
      | infoExp(IfExp(i,_,_,_))		= i
      | infoExp(SeqExp(i,_))		= i
      | infoExp(CaseExp(i,_,_))		= i
      | infoExp(FailExp(i))		= i
      | infoExp(RaiseExp(i,_))		= i
      | infoExp(HandleExp(i,_,_))	= i
      | infoExp(AnnExp(i,_,_))		= i
      | infoExp(LetExp(i,_,_))		= i
      | infoExp(PackExp(i,_))		= i

    fun infoRow(Row(i,_,_))		= i
    fun infoField(Field(i,_,_))		= i
    fun infoMatch(Match(i,_,_))		= i

    fun infoPat(JokPat(i))		= i
      | infoPat(LitPat(i,_))		= i
      | infoPat(VarPat(i,_))		= i
      | infoPat(TagPat(i,_,_,_))	= i
      | infoPat(ConPat(i,_,_))		= i
      | infoPat(RefPat(i,_))		= i
      | infoPat(TupPat(i,_))		= i
      | infoPat(ProdPat(i,_))		= i
      | infoPat(VecPat(i,_))		= i
      | infoPat(AsPat(i,_,_))		= i
      | infoPat(AltPat(i,_))		= i
      | infoPat(NegPat(i,_))		= i
      | infoPat(GuardPat(i,_,_))	= i
      | infoPat(AnnPat(i,_,_))		= i
      | infoPat(WithPat(i,_,_))		= i

    fun infoTyp(VarTyp(i,_))		= i
      | infoTyp(ConTyp(i,_))		= i
      | infoTyp(FunTyp(i,_,_))		= i
      | infoTyp(AppTyp(i,_,_))		= i
      | infoTyp(RefTyp(i,_))		= i
      | infoTyp(TupTyp(i,_))		= i
      | infoTyp(ProdTyp(i,_))		= i
      | infoTyp(SumTyp(i,_))		= i
      | infoTyp(ArrTyp(i,_,_))		= i
      | infoTyp(AllTyp(i,_,_))		= i
      | infoTyp(ExTyp(i,_,_))		= i
      | infoTyp(PackTyp(i,_))		= i
      | infoTyp(SingTyp(i,_))		= i
      | infoTyp(ExtTyp(i,_))		= i
      | infoTyp(AbsTyp(i,_))		= i

    fun infoMod(VarMod(i,_))		= i
      | infoMod(PrimMod(i,_,_))		= i
      | infoMod(StrMod(i,_))		= i
      | infoMod(SelMod(i,_,_))		= i
      | infoMod(FunMod(i,_,_,_))	= i
      | infoMod(AppMod(i,_,_))		= i
      | infoMod(AnnMod(i,_,_))		= i
      | infoMod(UpMod(i,_,_))		= i
      | infoMod(LetMod(i,_,_))		= i
      | infoMod(UnpackMod(i,_,_))	= i

    fun infoInf(TopInf(i))		= i
      | infoInf(ConInf(i,_))		= i
      | infoInf(SigInf(i,_))		= i
      | infoInf(FunInf(i,_,_,_))	= i
      | infoInf(AppInf(i,_,_))		= i
      | infoInf(CompInf(i,_,_))		= i
      | infoInf(ArrInf(i,_,_,_))	= i
      | infoInf(LetInf(i,_,_))		= i
      | infoInf(SingInf(i,_))		= i
      | infoInf(AbsInf(i,_))		= i

    fun infoDec(ValDec(i,_,_))		= i
      | infoDec(TypDec(i,_,_))		= i
      | infoDec(ModDec(i,_,_))		= i
      | infoDec(InfDec(i,_,_))		= i
      | infoDec(FixDec(i,_,_))		= i
      | infoDec(VarDec(i,_,_))		= i
      | infoDec(RecDec(i,_))		= i
      | infoDec(LocalDec(i,_))		= i

    fun infoSpec(ValSpec(i,_,_))	= i
      | infoSpec(TypSpec(i,_,_))	= i
      | infoSpec(ModSpec(i,_,_))	= i
      | infoSpec(InfSpec(i,_,_))	= i
      | infoSpec(FixSpec(i,_,_))	= i
      | infoSpec(RecSpec(i,_))		= i
      | infoSpec(ExtSpec(i,_))		= i

    fun infoImp(ValImp(i,_,_))		= i
      | infoImp(TypImp(i,_,_))		= i
      | infoImp(ModImp(i,_,_))		= i
      | infoImp(InfImp(i,_,_))		= i
      | infoImp(FixImp(i,_,_))		= i
      | infoImp(RecImp(i,_))		= i

    fun infoAnn(ImpAnn(i,_,_))		= i

    fun infoDesc(NoDesc(i))		= i
      | infoDesc(SomeDesc(i,_))		= i

    fun infoComp(Comp(i,_,_))		= i

  end
