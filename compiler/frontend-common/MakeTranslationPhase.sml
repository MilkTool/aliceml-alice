(*
import structure Source			from "Source"
import structure TypedInfo		from "TypedGrammar"
import structure TypedGrammar		from "TypedGrammar"
import structure IntermediateGrammar	from "IntermediateGrammar"
import structure EmptyContext		from "EmptyContext"
import structure StringMap		from "StringMap"

import structure Stamp			from "Stamp"
import structure Name			from "Name"
import structure Label			from "Label"
import structure Type			from "Type"
import structure Inf			from "Inf"

import structure PerasiveType		from "PervasiveType"
import structure LabelReflection	from "LabelReflection"
import structure PathReflection		from "PathReflection"
import structure TypeReflection		from "TypeReflection"
import structure InfReflection		from "InfReflection"

import signature SWITCHES		from "SWITCHES"
import signature TRANSLATION_PHASE	from "TRANSLATION_PHASE"

import structure Crash			from "Crash"
*)

functor MakeTranslationPhase(Switches: SWITCHES) :> TRANSLATION_PHASE =
struct

    structure C = EmptyContext
    structure I = TypedGrammar
    structure O = IntermediateGrammar

    open TypedInfo


  (* UNFINISHED... *)

    fun unfinished i funname casename =
	Error.error(i, "Translation." ^ funname ^ ": " ^ casename ^
		       " not implementeed yet")

  (* Helpers *)

    fun idToField idToX (x' as O.Id(i,_,n)) =
	let
	    val i' = nonInfo(#region i)
	in
	    O.Field(i', O.Lab(i', Label.fromName n), idToX x')
	end


  (* Recognize sum type constructors (tags) *)

    fun decomposeConarrow t =
	if Type.isAll t then decomposeConarrow(#2(Type.asAll t)) else
	let
	    val (t',tArity)  = Type.asApply t
	    val (t'',tArrow) = Type.asApply t'
	in
(*ASSERT    assert Type.equals(t'', PervasiveType.typ_conarrow) => *)
	    if not(Type.equals(t'', PervasiveType.typ_conarrow))
	    then raise Assert.failure else
	    (tArrow, tArity)
	end

    fun decodeArity t  = decodeArity'(#2(decomposeConarrow t))
    and decodeArity' t = if Type.isApply t
			 then 1 + decodeArity'(#2(Type.asApply t))
			 else 0

  (* Names and labels *)

    fun trName' f (Name.ExId s)	= Name.ExId(f s)
      | trName' f  n		= n

    fun trValName  n		= n
    val trTypName		= trName'(fn s => "$" ^ s)
    val trVarName		= trName'(fn s => "$" ^ s)
    val trModName		= trName'(fn s => s ^ "$")
    val trInfName		= trName'(fn s => "$" ^ s ^ "$")

    fun isTypName' s		= String.sub(s,0) = #"$"

    fun trValLabel a		= Label.fromName(trValName(Label.toName a))
    fun trTypLabel a		= Label.fromName(trTypName(Label.toName a))
    fun trModLabel a		= Label.fromName(trModName(Label.toName a))
    fun trInfLabel a		= Label.fromName(trInfName(Label.toName a))


  (* Auxiliaries for reflection *)

    open PervasiveType
    open InfReflection
    open TypeReflection
    open PervasiveTypeReflection
    open PathReflection
    open LabelReflection
    open FixityReflection

    val typ_icon		= InfReflection.typ_con
    val typ_ikind		= InfReflection.typ_kind
    val lab_ikind		= InfReflection.lab_kind

    val modname_label'		= trModName modname_label
    val modname_path'		= trModName modname_path
    val modname_type'		= trModName modname_type
    val modname_pervType'	= trModName modname_pervasiveType
    val modname_inf'		= trModName modname_inf
    val lab_label'		= Label.fromName modname_label'
    val lab_path'		= Label.fromName modname_path'
    val lab_type'		= Label.fromName modname_type'
    val lab_pervType'		= Label.fromName modname_pervType'
    val lab_inf'		= Label.fromName modname_inf'

    val longidr_pervasive	= ref(NONE : O.longid option)
    fun longid_pervasive()	= case !longidr_pervasive
				    of SOME y => y
				     | NONE => raise Crash.Crash
					"TranslationPhase.longid_pervasive"

    fun info_pervasiveDot a	= let
				      val i = O.infoLongid(longid_pervasive())
				      val r = Type.asProd(#typ i)
				      val t = Type.lookupRow(r,a)
				  in typInfo(#region i, t) end
    fun info_label()		= info_pervasiveDot lab_label'
    fun info_path()		= info_pervasiveDot lab_path'
    fun info_type()		= info_pervasiveDot lab_type'
    fun info_inf()		= info_pervasiveDot lab_inf'
    fun info_pervType()		= info_pervasiveDot lab_pervType'

    val typ_typtyp		= Type.inTuple #[typ_typ, typ_typ]
    val typ_vartyp		= Type.inTuple #[typ_var, typ_typ]
    val typ_typVec		= Type.inApply(typ_vec, typ_typ)
    val typ_kindkind		= Type.inTuple #[typ_kind, typ_kind]
    val typ_kindToVar		= Type.inArrow(typ_kind, typ_var)
    val typ_infinf		= Type.inTuple #[typ_inf, typ_inf]
    val typ_pathinfinf		= Type.inTuple #[typ_path, typ_inf, typ_inf]
    val typ_infpathinf		= Type.inTuple #[typ_inf, typ_path, typ_inf]
    val typ_infunit		= Type.inTuple #[typ_inf, typ_unit]
    val typ_signlab		= Type.inTuple #[typ_sign, typ_lab]
    val typ_intassoc		= Type.inTuple #[typ_int, typ_assoc]
    val typ_labtyprow		= Type.inTuple #[typ_lab, typ_typ, typ_row]

    val typ_top			= typ_zero
    fun typ_infinst t		= Type.inArrow(typ_unit,
					       Type.inTuple #[typ_unit, t])
    (*UNFINISHED: this should go *)
    val lab_none		= Label.fromString "NONE"
    val lab_some		= Label.fromString "SOME"
    val typ_opt			= Type.unknown(Type.ARROW(Type.STAR,Type.STAR))
    val var_opt			= Type.var(Type.STAR)
    val typ_some		= Type.inTuple #[Type.inVar var_opt]
    val row_opt			= Type.extendRow(lab_some, typ_some,
				  Type.extendRow(lab_none, typ_zero,
				  Type.emptyRow()))
    val _			= Type.fill(typ_opt,
					Type.inMu(Type.inLambda(var_opt,
							  Type.inSum row_opt)))
    val typ_pathOpt		= Type.inApply(typ_opt, typ_path)
    val typ_typOpt		= Type.inApply(typ_opt, typ_typ)
    val typ_infOpt		= Type.inApply(typ_opt, typ_inf)
    val typ_extendFix		= Type.inTuple #[typ_sign, typ_path, typ_fix]
    val typ_extendVal		= Type.inTuple
				  #[typ_sign, typ_path, typ_typ, typ_pathOpt]
    val typ_extendTyp		= Type.inTuple
				  #[typ_sign, typ_path, typ_kind, typ_typOpt]
    val typ_extendMod		= Type.inTuple
				  #[typ_sign, typ_path, typ_inf, typ_pathOpt]
    val typ_extendInf		= Type.inTuple
				  #[typ_sign, typ_path, typ_ikind, typ_infOpt]

    fun longid_pervasiveDot i n	= O.LongId(i, longid_pervasive(),
					      O.Lab(nonInfo(Source.nowhere),
						    Label.fromName n))

    fun longid_label()		= longid_pervasiveDot(info_label())
						      modname_label'
    fun longid_path()		= longid_pervasiveDot(info_path()) modname_path'
    fun longid_type()		= longid_pervasiveDot(info_type()) modname_type'
    fun longid_inf()		= longid_pervasiveDot(info_inf())  modname_inf'
    fun longid_pervType()	= longid_pervasiveDot(info_pervType())
						      modname_pervType'
    fun longid_pervInf()	= (*UNFINISHED*)
				  unfinished(Source.nowhere) "longid_pervInf" ""

    fun yVal (mkY,typ) a	= let val r  = Source.nowhere
				      val y' = O.LongId(typInfo(r,typ), mkY(),
							O.Lab(nonInfo r, a))
				  in
				      O.VarExp(typInfo(r,typ), y')
				  end

    fun yOp (mkY,typ) (a,e')	= let val r   = #region(O.infoExp e')
				      val t   = #typ(O.infoExp e')
				      val t1  = Type.inArrow(t, typ)
				      val y'  = O.LongId(typInfo(r,t1), mkY(),
							 O.Lab(nonInfo r, a))
				      val e1' = O.VarExp(typInfo(r,t1), y')
				  in
				      O.AppExp(typInfo(r, typ), e1', e')
				  end

    val labOp			= yOp(longid_label,     typ_lab)
    val pathOp			= yOp(longid_path,      typ_path)
    val typOp			= yOp(longid_type,      typ_typ)
    val kindOp			= yOp(longid_type,      typ_kind)
    val varOp			= yOp(longid_type,      typ_var)
    val rowOp			= yOp(longid_type,      typ_row)
    val unitTypOp		= yOp(longid_type,      typ_unit)
    val boolTypOp		= yOp(longid_type,      typ_bool)
    val pervTypeOp		= yOp(longid_pervType,  typ_con)
    val pervTypeVal		= yVal(longid_pervType, typ_typ)
    val sigOp			= yOp(longid_inf,       typ_sign)
    val infOp			= yOp(longid_inf,       typ_inf)
    val ikindOp			= yOp(longid_inf,       typ_ikind)
    val unitInfOp		= yOp(longid_inf,       typ_unit)
    val pathInfOp		= yOp(longid_inf,       typ_path)
    val typInfOp		= yOp(longid_inf,       typ_typ)
    val pervInfOp		= yOp(longid_pervInf,   typ_icon)


  (* Primitive types and expressions *)

    fun trUnit r	= O.TupExp(typInfo(r,typ_unit), #[])
    fun trInt(r, n)	= O.LitExp(typInfo(r,typ_int),
				   O.IntLit(LargeInt.fromInt n))
    fun trString(r, s)	= O.LitExp(typInfo(r,typ_string),
 				   O.StringLit(String.toWide s))

    fun trTagged(i, a, e, b) =
	    O.TagExp(i, O.Lab(nonInfo(#region i), a), e, b)
    fun trTag(i, a) =
	    O.TagExp(i, O.Lab(nonInfo(#region i), a),
		     O.FailExp(typInfo(#region i, typ_zero)), false)

    fun trKind(r, Type.STAR) = trTag(typInfo(r,typ_kind), lab_star)
      | trKind(r, Type.ARROW(k1,k2)) =
	    trTagged(typInfo(r,typ_kind), lab_arrow,
		     O.TupExp(typInfo(r,typ_kindkind),
			      (*UNFINISHED: this should be a vector constant,
			        but NJ has a bug... *)
			      vector[trKind(r,k1), trKind(r,k2)]), true)

    fun trSort(r, Type.OPEN)        = trTag(typInfo(r,typ_sort), lab_open)
      | trSort(r, Type.CLOSED)      = trTag(typInfo(r,typ_sort), lab_closed)

    fun trAssoc(r, Fixity.LEFT)     = trTag(typInfo(r,typ_assoc), lab_left)
      | trAssoc(r, Fixity.RIGHT)    = trTag(typInfo(r,typ_assoc), lab_right)
      | trAssoc(r, Fixity.NEITHER)  = trTag(typInfo(r,typ_assoc), lab_neither)

    fun trFix(r, Fixity.NONFIX)     = trTag(typInfo(r,typ_fix), lab_nonfix)
      | trFix(r, Fixity.PREFIX n)   = trTagged(typInfo(r,typ_fix), lab_prefix,
					       trInt(r,n), false)
      | trFix(r, Fixity.POSTFIX n)  = trTagged(typInfo(r,typ_fix), lab_postfix,
					       trInt(r,n), false)
      | trFix(r, Fixity.INFIX(n,a)) = trTagged(typInfo(r,typ_fix), lab_infix,
					       O.TupExp(typInfo(r,typ_intassoc),
					       (*UNFINISHED: this should be
					        * a vector constant,
					        * but NJ has a bug... *)
					       vector[trInt(r,n), trAssoc(r,a)]),
					       true)


  (* Transformation of type info *)

    structure InfHash = MakeHashImpMap(open Inf val equals = Inf.same)

    val infHash     = InfHash.new() : Type.t InfHash.map
    val infInstHash = InfHash.new() : Type.t InfHash.map
		(*UNFINISHED: remove this global variables! *)

    fun ikindToKind k =
	if Inf.isGround k then
	    Type.STAR
	else if Inf.isDependent k then
	    let
		val (p,j,k1) = Inf.asDependent k
	    in
		Type.ARROW(Type.STAR, ikindToKind k1)
	    end
	else
	    raise Crash.Crash "TranslationPhase.kindToKind: unknown kind"

    fun infToTyp j =
	case InfHash.lookup(infHash, j) of
	  SOME t => t
	| NONE   =>
	    let
		val t = infToTyp' j
	    in
		InfHash.insertDisjoint(infHash, j, t);
		t
	    end

    and infToTyp' j =
	if Inf.isTop j then
	    typ_top
	else if Inf.isCon j then
	    let
		val (k,p) = Inf.asCon j
	    in
		Type.inCon(ikindToKind k, Type.CLOSED, p)
	    end
	else if Inf.isSig j then
	    let
		val s     = Inf.asSig j
		val items = Inf.items s
	    in
		Type.inProd(List.foldr itemToRow (Type.emptyRow()) items)
	    end
	else if Inf.isArrow j then
	    let
		val (p,j1,j2) = Inf.asArrow j
	    in
		Type.inArrow(infToTyp j1, infToTyp j2)
	    end
	else if Inf.isLambda j then
	    let
		val (p,j1,j2) = Inf.asLambda j
	    in
		Type.inLambda(Type.var(Type.STAR), infToTyp j2)
	    end
	else if Inf.isApply j then
	    let
		val (j1,p,j2) = Inf.asApply j
	    in
		Type.inApply(infToTyp j1, infToTyp j2)
	    end
	else
	    raise Crash.Crash "TranslationPhase.infToTyp: unknown inf"

    and itemToRow(item,r) =
	if Inf.isValItem item then
	    let
		val (a,t,d) = Inf.asValItem item
	    in
		Type.extendRow(trValLabel a, t, r)
	    end
	else if Inf.isTypItem item then
	    let
		val (a,k,d) = Inf.asTypItem item
	    in
		Type.extendRow(trTypLabel a, typ_typ, r)
	    end
	else if Inf.isModItem item then
	    let
		val (a,j,d) = Inf.asModItem item
	    in
		Type.extendRow(trModLabel a, infToTyp j, r)
	    end
	else if Inf.isInfItem item then
	    let
		val (a,k,d) = Inf.asInfItem item
		val  t      = case d of SOME j => infToInstTyp j
				      | NONE =>
					(* new abstract type *)
					Type.inCon(ikindToKind k, Type.CLOSED,
						   Path.fromLab a)
	    in
		Type.extendRow(trInfLabel a, typ_infinst t, r)
	    end
	else (* fixity *)
	    r

    and infToInstTyp j =
	case InfHash.lookup(infInstHash, j) of
	  SOME t => t
	| NONE   =>
	    let
		val t = infToInstTyp' j
	    in
		InfHash.insertDisjoint(infInstHash, j, t);
		t
	    end

    and infToInstTyp' j =
	if Inf.isTop j then
	    typ_top
	else if Inf.isCon j then
	    let
		val (k,p) = Inf.asCon j
	    in
		Type.inCon(Type.STAR, Type.CLOSED, p)
	    end
	else if Inf.isSig j then
	    let
		val s     = Inf.asSig j
		val items = Inf.items s
	    in
		Type.inProd(List.foldr itemToInstRow (Type.emptyRow()) items)
	    end
	else if Inf.isArrow j then
	    let
		val (p,j1,j2) = Inf.asArrow j
	    in
		infToInstTyp j2
	    end
	else if Inf.isLambda j then
	    (*UNFINISHED*)
	    typ_unit
	else if Inf.isApply j then
	    (*UNFINISHED*)
	    typ_unit
	else
	    raise Crash.Crash "TranslationPhase.infToInstTyp: unknown inf"

    and itemToInstRow(item,r) =
	if Inf.isValItem item then
	    (*UNFINISHED: get rid of this, but how?*)
	    let
		val (a,t,d) = Inf.asValItem item
	    in
		Type.extendRow(trValLabel a, t, r)
	    end
	else if Inf.isTypItem item then
	    let
		val (a,k,d) = Inf.asTypItem item
	    in
		Type.extendRow(trTypLabel a, typ_typ, r)
	    end
	else if Inf.isModItem item then
	    let
		val (a,j,d) = Inf.asModItem item
	    in
		Type.extendRow(trModLabel a, infToTyp j, r)
	    end
	else if Inf.isInfItem item then
	    let
		val (a,k,d) = Inf.asInfItem item
		val  t      = case d of SOME j => infToInstTyp j
				      | NONE   => typ_unit
	    in
		Type.extendRow(trInfLabel a, typ_infinst t, r)
	    end
	else (* fixity *)
	    r


  (* Handling builtin primitives *)

    fun updatePervasive(I.Id(i,z,n) : I.modid) =
	if n <> name_pervasive then () else
	let
	    val i' = typInfo(#region i, infToTyp(#inf i))
	in
	    longidr_pervasive := SOME(O.ShortId(i', O.Id(i', z, trModName n)))
	end


  (* Literals *)

    fun trLit(I.IntLit n)		= O.IntLit n
      | trLit(I.WordLit w)		= O.WordLit w
      | trLit(I.CharLit c)		= O.CharLit c
      | trLit(I.StringLit s)		= O.StringLit s
      | trLit(I.RealLit x)		= O.RealLit x


  (* Identifiers *)

    fun trValInfo i			= i
    fun trTypInfo {region,typ}		= {region=region, typ=typ_typ}
    fun trVarInfo {region,var}		= {region=region, typ=typ_var}
    fun trModInfo {region,inf}		= {region=region, typ=infToTyp inf}
    fun trInfInfo {region,inf}		= {region=region,
					   typ=typ_infinst(infToInstTyp inf)}

    fun trVallab(I.Lab(i,a))		= O.Lab(i, trValLabel  a)
    fun trTyplab(I.Lab(i,a))		= O.Lab(i, trTypLabel a)
    fun trModlab(I.Lab(i,a))		= O.Lab(i, trModLabel a)
    fun trInflab(I.Lab(i,a))		= O.Lab(i, trInfLabel a)

    fun trValid(I.Id(i,z,n))		= O.Id(trValInfo i, z, trValName n)
    fun trTypid(I.Id(i,z,n))		= O.Id(trTypInfo i, z, trTypName n)
    fun trVarid(I.Id(i,z,n))		= O.Id(trVarInfo i, z, trVarName n)
    fun trModid(I.Id(i,z,n))		= O.Id(trModInfo i, z, trModName n)
    fun trInfid(I.Id(i,z,n))		= O.Id(trInfInfo i, z, trInfName n)

    fun trModlongid(I.ShortId(i,x))	= O.ShortId(trModInfo i, trModid x)
      | trModlongid(I.LongId(i,y,l))	= O.LongId(trModInfo i,
						   trModlongid y, trModlab l)

    fun trVallongid(I.ShortId(i,x))	= O.ShortId(trValInfo i, trValid x)
      | trVallongid(I.LongId(i,y,l))	= O.LongId(trValInfo i,
						   trModlongid y, trVallab l)

    fun trTyplongid(I.ShortId(i,x))	= O.ShortId(trTypInfo i, trTypid x)
      | trTyplongid(I.LongId(i,y,l))	= O.LongId(trTypInfo i,
						   trModlongid y, trTyplab l)

    fun trInflongid(I.ShortId(i,x))	= O.ShortId(trInfInfo i, trInfid x)
      | trInflongid(I.LongId(i,y,l))	= O.LongId(trInfInfo i,
						   trModlongid y, trInflab l)


  (* Extract bound ids from declarations. *)

    fun idsId'(x as O.Id(_,_,Name.ExId s), xs')	= StringMap.insert(xs',s,x)
      | idsId'(x, xs')				= ()

    fun idsDecs(ds, xs')		= Vector.app (fn d => idsDec(d,xs')) ds
    and idsDec(I.ValDec(_,p,_), xs')	= idsPat(p,xs')
      | idsDec(I.TypDec(_,x,_), xs')	= idsId'(trTypid x, xs')
      | idsDec(I.ModDec(_,x,_), xs')	= idsId'(trModid x, xs')
      | idsDec(I.InfDec(_,x,_), xs')	= idsId'(trInfid x, xs')
      | idsDec(I.VarDec(_,_,d), xs')	= idsDec(d,xs')
      | idsDec(I.RecDec(_,ds), xs')	= idsDecs(ds,xs')
      | idsDec((I.FixDec _
	      | I.LocalDec _), xs')	= ()

    and idsPats(ps, xs')		= Vector.app (fn p => idsPat(p,xs')) ps
    and idsPat((I.JokPat(_)
	      | I.LitPat(_,_)), xs')	= ()
      | idsPat(I.VarPat(_,x), xs')	= idsId'(trValid x, xs')
      | idsPat((I.TagPat(_,_,_,p)
	      | I.ConPat(_,_,p)
	      | I.RefPat(_,p)
	      | I.NegPat(_,p)
	      | I.GuardPat(_,p,_)
	      | I.AnnPat(_,p,_)), xs')	= idsPat(p,xs')
      | idsPat((I.TupPat(_,ps)
	      | I.VecPat(_,ps)
	      | I.AltPat(_,ps)), xs')	= idsPats(ps,xs')
      | idsPat(I.ProdPat(_,r), xs')	= idsRow(r,xs')
      | idsPat(I.AsPat(_,p1,p2), xs')	= ( idsPat(p1,xs') ; idsPat(p2,xs') )
      | idsPat(I.WithPat(_,p,ds), xs')	= ( idsPat(p,xs') ; idsDecs(ds,xs') )

    and idsRow(I.Row(_,fs,_), xs')	= Vector.app(fn f => idsField(f,xs')) fs
    and idsField(I.Field(_,_,p), xs')	= idsPat(p,xs')

    fun ids ds				= let val xs' = StringMap.new() in
					      idsDecs(ds,xs') ;
					      Vector.fromList
					  	  (StringMap.fold op:: [] xs')
					  end

  (* Expressions *)

    fun idToExp x'			= let val i' = O.infoId x'
					  in O.VarExp(i', O.ShortId(i',x')) end

    fun trExps es			= Vector.map trExp es
    and trExp(I.LitExp(i,l))		= O.LitExp(i, trLit l)
      | trExp(I.VarExp(i,y))		= O.VarExp(i, trVallongid y)
      | trExp(I.PrimExp(i,s,t))		= O.PrimExp(i, s)
      | trExp(I.LabExp(i,l,t))		= O.FailExp(i)
      | trExp(I.NewExp(i,t))		= O.NewExp(i, decodeArity(#typ i) > 1)
      | trExp(I.TagExp(i,l,NONE,e))	= O.TagExp(i, trVallab l, trExp e,false)
      | trExp(I.TagExp(i,l,SOME y,e))	= O.TagExp(i, trVallab l, trExp e,
					  decodeArity(#typ(I.infoLongid y)) > 1)
      | trExp(I.ConExp(i,y,e))		= O.ConExp(i, trVallongid y, trExp e,
					  decodeArity(#typ(I.infoLongid y)) > 1)
      | trExp(I.RefExp(i,e))		= O.RefExp(i, trExp e)
      | trExp(I.TupExp(i,es))		= O.TupExp(i, trExps es)
      | trExp(I.ProdExp(i,r))		= O.ProdExp(i, trExpRow r)
      | trExp(I.UpdExp(i,e,r))		= trUpdExp(i, trExp e, trExpRow r)
      | trExp(I.SelExp(i,l,e))		= O.SelExp(i, trVallab l, trExp e)
      | trExp(I.VecExp(i,es))		= O.VecExp(i, trExps es)
      | trExp(I.FunExp(i,ms))		= O.FunExp(i, trMatchs ms)
      | trExp(I.AppExp(i,e1,e2))	= O.AppExp(i, trExp e1, trExp e2)
      | trExp(I.AndExp(i,e1,e2))	= O.AndExp(i, trExp e1, trExp e2)
      | trExp(I.OrExp(i,e1,e2))		= O.OrExp(i, trExp e1, trExp e2)
      | trExp(I.IfExp(i,e1,e2,e3))	= O.IfExp(i, trExp e1, trExp e2,
							       trExp e3)
      | trExp(I.SeqExp(i,es))		= O.SeqExp(i, trExps es)
      | trExp(I.CaseExp(i,e,ms))	= O.CaseExp(i, trExp e, trMatchs ms)
      | trExp(I.FailExp(i))		= O.FailExp(i)
      | trExp(I.RaiseExp(i,e))		= O.RaiseExp(i, trExp e)
      | trExp(I.HandleExp(i,e,ms))	= O.HandleExp(i, trExp e, trMatchs ms)
      | trExp(I.AnnExp(i,e,t))		= trExp e
      | trExp(I.LetExp(i,ds,e))		= O.LetExp(i, trDecs ds, trExp e)
      | trExp(I.PackExp(i,m))		= trMod m

    and trExpRow(I.Row(i,fs,_))		= trExpFields fs
    and trExpFields fs			= Vector.map trExpField fs
    and trExpField(I.Field(i,l,e))	= O.Field(i, trVallab l, trExp e)

    and trUpdExp(i,e',r') =
	(* [{ e where r}] = let val x = [e] in {[e]', [r]} *)
	let
	    val i'  = O.infoExp e'
	    val i'' = nonInfo(#region i')
	    val x'  = O.Id(i', Stamp.new(), Name.InId)
	    val d'  = O.ValDec(i'', O.VarPat(i',x'), e')
	    val r'' = trUpdExp'(Type.asProd'(#typ i'), i'', idToExp x', r',
				Vector.toList r')
	in
	    O.LetExp(i, #[d'], O.ProdExp(i, r''))
	end
	
    and trUpdExp'(tr,i,e',r',fs) =
	if Type.isEmptyRow tr then	(* check for unknown necessary? *)
	    Vector.fromList fs
	else let
	    val (a,t) = Type.headRow tr
	    val  tr'  = Type.tailRow tr
	    val  fs'  = if Vector.exists (fn O.Field(_,O.Lab(_,b),_) => a=b) r'
			then fs else
			let val l' = O.Lab(i,a)
			    val i' = typInfo(#region i, t)
			in O.Field(i, l', O.SelExp(i',l',e')) :: fs end
	in
	    trUpdExp'(tr',i,e',r',fs')
	end


  (* Matches and Patterns *)

    and idToPat x'			= O.VarPat(O.infoId x', x')

    and trMatchs ms			= Vector.map trMatch ms
    and trMatch(I.Match(i,p,e))		= O.Match(i, trPat p, trExp e)

    and trPats ps			= Vector.map trPat ps
    and trPat(I.JokPat(i))		= O.JokPat(i)
      | trPat(I.LitPat(i,l))		= O.LitPat(i, trLit l)
      | trPat(I.VarPat(i,x))		= O.VarPat(i, trValid x)
      | trPat(I.TagPat(i,l,NONE,p))	= O.TagPat(i, trVallab l, trPat p,false)
      | trPat(I.TagPat(i,l,SOME y,p))	= O.TagPat(i, trVallab l, trPat p,
					  decodeArity(#typ(I.infoLongid y)) > 1)
      | trPat(I.ConPat(i,y,p))		= O.ConPat(i, trVallongid y, trPat p,
					  decodeArity(#typ(I.infoLongid y)) > 1)
      | trPat(I.RefPat(i,p))		= O.RefPat(i, trPat p)
      | trPat(I.TupPat(i,ps))		= O.TupPat(i, trPats ps)
      | trPat(I.ProdPat(i,r))		= O.ProdPat(i, trPatRow r)
      | trPat(I.VecPat(i,ps))		= O.VecPat(i, trPats ps)
      | trPat(I.AsPat(i,p1,p2))		= O.AsPat(i, trPat p1, trPat p2)
      | trPat(I.AltPat(i,ps))		= O.AltPat(i, trPats ps)
      | trPat(I.NegPat(i,p))		= O.NegPat(i, trPat p)
      | trPat(I.GuardPat(i,p,e))	= O.GuardPat(i, trPat p, trExp e)
      | trPat(I.AnnPat(i,p,t))		= trPat p
      | trPat(I.WithPat(i,p,ds))	= O.WithPat(i, trPat p, trDecs ds)

    and trPatRow(I.Row(i,fs,b))		= trPatFields fs
    and trPatFields fs			= Vector.map trPatField fs
    and trPatField(I.Field(i,l,p))	= O.Field(i, trVallab l, trPat p)


  (* Modules *)

    and trMod(I.PrimMod(i,s,j))		= trPrimMod(i,s,j)
      | trMod(I.VarMod(i,x))		= idToExp(trModid x)
      | trMod(I.StrMod(i,ds))		= let val i'   = trModInfo i
					      val ds'  = trDecs ds
					      val ids' = ids ds
					      val fs'  = Vector.map
							     (idToField idToExp)
							     ids'
					  in O.LetExp(i',ds',O.ProdExp(i',fs'))
					  end
      | trMod(I.SelMod(i,l,m))		= O.SelExp(trModInfo i, trModlab l,
								trMod m)
      | trMod(I.FunMod(i,x,j,m))	= let val r  = #region(I.infoId x)
					      val e' = trMod m
					      val p' = idToPat(trModid x)
					      val m' = O.Match(nonInfo r,p',e')
					  in O.FunExp(trModInfo i, #[m'])
					  end
      | trMod(I.AppMod(i,m1,m2))	= let val i1  = I.infoMod m1
					      val i2  = I.infoMod m2
					      val j11 = #2(Inf.asArrow(#inf i1))
					  in O.AppExp(trModInfo i, trMod m1,
						      trTransCoerceMod
							(#region i2, m2, j11))
					  end
      | trMod(I.AnnMod(i,m,j))		= trTransCoerceMod(#region i, m, #inf i)
      | trMod(I.UpMod(i,m,j))		= trOpaqCoerceMod(i,m,j)
      | trMod(I.LetMod(i,ds,m))		= O.LetExp(trModInfo i, trDecs ds,
								trMod m)
      | trMod(I.UnpackMod(i,e,j))	= trExp e

    and trTransCoerceMod(r,m,j2) =
	(* [m : j] = let val x1 = [m]
	 *           in [x1 : j1 :> x2 = j2]
	 *)
	let
	    val i   = nonInfo r
	    val e1' = trMod m

	    val j1  = #inf(I.infoMod m)
	    val i1  = O.infoExp e1'
	    val t1  = #typ i1
	    val t2  = infToTyp j2
	    val i2  = typInfo(r,t2)

	    val x1' = O.Id(i1, Stamp.new(), Name.InId)
	    val x1  = O.ShortId(i1, x1')
	    val i3  = typInfo(r, typ_unit)	(* x2 will be unused! *)
	    val x2' = O.Id(i3, Stamp.new(), Name.InId)
	    val x2  = O.ShortId(i3, x2')
	in
	    case upInf(false, false, x1,j1,x2,j2, r,t1,t2)
	      of NONE    => e1'
	       | SOME e' =>
		 let
		     val d' = O.ValDec(i, O.VarPat(i1, x1'), e1')
		 in
		     O.LetExp(i2, #[d'], e')
		 end
	end

    and trOpaqCoerceMod(i,m,j) =
	(* [m :> j] = let val    x1  = [m]
	 *                val (_,x2) = [j]
	 *            in [x1 : j1 :> x2 = j2]
	 *)
	if !Switches.Bootstrap.rttLevel <> Switches.Bootstrap.FULL_RTT then
	    trTransCoerceMod(#region i, m, #inf i)
	else let
	    val r   = #region i
	    val i'  = nonInfo r
	    val j1  = #inf(I.infoMod m)
	    val j2  = #inf i

	    val e1' = trMod m
	    val e2' = trInf j
	    val i1  = O.infoExp e1'
	    val i2  = trModInfo i
	    val t1  = #typ i1
	    val t2  = #typ i2
	    val t3  = Vector.sub(Type.asTuple'(#typ(O.infoExp e2')), 1)

	    val x1' = O.Id(i1, Stamp.new(), Name.InId)
	    val x1  = O.ShortId(i1, x1')
	    val i3  = typInfo(#region(O.infoExp e2'), t3)
	    val x2' = O.Id(i3, Stamp.new(), Name.InId)
	    val x2  = O.ShortId(i3, x2')
	in
	    case upInf(true, false, x1,j1,x2,j2, r,t1,t2)
	      of NONE    => O.UpExp(i2, e1')
	       | SOME e' =>
		 let
		     val p1' = O.VarPat(i1, x1')
		     val d1' = O.ValDec(i', p1', e1')

		     val i4  = typInfo(#region(O.infoExp e2'), typ_inf)
		     val p2' = O.TupPat(O.infoExp e2', #[O.JokPat(i4),
							 O.VarPat(i3,x2')])
		     val d2' = O.ValDec(i', p2', e2')
		 in
		     O.LetExp(i2, #[d1',d2'], e')
		 end
	end

  (* Primitive modules *)

    (*UNFINISHED: quick hack *)

    and trPrimMod(i,"Pack",j) =
	(* fn {[x]=x1,[t]=x2} -> cast (x1,x2) *)
	(let
	    val  i'     = trModInfo i
	    val  r      = #region i'
	    val  i0'    = nonInfo r
	    val  t      = #typ i'
	    val (t1,t2) = Type.asArrow' t
	    val (l1,t11,l2,t12) = findValTyp(Type.asProd t1)
	    val  x1'    = O.Id(typInfo(r,t11), Stamp.new(), Name.InId)
	    val  x2'    = O.Id(typInfo(r,t12), Stamp.new(), Name.InId)
	    val  p'     = O.ProdPat(typInfo(r,t1),
				#[O.Field(i0', O.Lab(i0',l1), idToPat x1'),
				  O.Field(i0', O.Lab(i0',l2), idToPat x2')])
	    val  e'     = O.CastExp(typInfo(r,t2), 
				O.TupExp(typInfo(r,Type.inTuple #[t11,t12]),
					 #[idToExp x1', idToExp x2']))
	in
	    O.FunExp(i', #[O.Match(nonInfo r, p', e')])
	end
	handle Type.Type => raise Crash.Crash "trPrimMod: Pack")

      | trPrimMod(i,"Unpack",j) =
	(* fn {[x]=x1,[t]=x2} -> let (x11,x12) = cast x1 in
	 *                           if Type.equals(x12,x2) then
	 *                               {[x']=x11}
	 *                           else
	 *                               raise prim "General.Bind"
	 *                       end *)
	(let
	    val  i'     = trModInfo i
	    val  r      = #region i'
	    val  i0'    = nonInfo r
	    val  t      = #typ i'
	    val (t1,t2) = Type.asArrow' t
	    val (l1,t11,l2,t12) = findValTyp(Type.asProd' t1)
	    val (l3,t21)        = Type.headRow(Type.asProd' t2)
	    val  x1'    = O.Id(typInfo(r,t11), Stamp.new(), Name.InId)
	    val  x2'    = O.Id(typInfo(r,t12), Stamp.new(), Name.InId)
	    val  p'     = O.ProdPat(typInfo(r,t1),
				#[O.Field(i0', O.Lab(i0',l1), idToPat x1'),
				  O.Field(i0', O.Lab(i0',l2), idToPat x2')])

	    val  x11'   = O.Id(typInfo(r,t21), Stamp.new(), Name.InId)
	    val  x12'   = O.Id(typInfo(r,typ_typ), Stamp.new(), Name.InId)
	    val  i1'    = typInfo(r, Type.inTuple #[t21,typ_typ])
	    val  p1'    = O.TupPat(i1', #[idToPat x11', idToPat x12'])
	    val  e1'    = O.CastExp(i1', idToExp x1')
	    val  d'     = O.ValDec(nonInfo r, p1', e1')

	    val  e1'    = boolTypOp(lab_equals, O.TupExp(typInfo(r,typ_typtyp),
						  #[idToExp x12', idToExp x2']))
	    val  i2'    = typInfo(r,t2)
	    val  e2'    = O.ProdExp(i2',
			    #[O.Field(i0', O.Lab(i0',l3), idToExp x11')])
	    val  e3'    = O.RaiseExp(i2', (*UNFINISHED*)
				O.PrimExp(typInfo(r,typ_exn), "General.Bind"))
	    val  e'     = O.LetExp(i2', #[d'], O.IfExp(i2', e1', e2', e3'))
	in
	    O.FunExp(i', #[O.Match(nonInfo r, p', e')])
	end
	handle Type.Type => raise Crash.Crash "trPrimMod: Unpack")

      | trPrimMod(i,s,j) =
	O.PrimExp(trModInfo i, s)

    and findValTyp r =
	let
	    val (l1,t1) = Type.headRow r
	    val (l2,t2) = Type.headRow(Type.tailRow r)
	in
	    case (isTypName'(Label.toString l1), isTypName'(Label.toString l2))
	      of (false,true) => (l1,t1,l2,t2)
	       | (true,false) => (l2,t2,l1,t1)
	       |  _           => raise Crash.Crash "TranslationPhase.findValTyp"
	end


  (* Signature coercions *)

    (*
     * We use the following transformation rules:
     *
     *	[x1 : sig item1* end :> x2 = sig item2* end] =
     *	   struct [x1 . item1 :> x2 . item2]* end
     *	[x1 : fct(x11:j11)->j12 :> x2 = fct(x21:j21)->j22] =
     *	   fct(y:j21) => let z = x1([y : j21 :> _ = j11])
     *                   in [z : j12 :> x2 = j22] end
     *	[x1 : j1 :> x2 = j2] = x1
     *
     *	[x1 . val y:t1 :> x2 . val y:t2] = val y = lazy x1.y
     *	[x1 . constructor y:t1 :> x2 . val y:t2] = val y = lazy (x1.y)
     *  [x1 . type y:k1 :> x2 . type y:k2 = t2] = type y = lazy (x2.y)
     *	[x1 . structure y:j1 :> x2 . structure y:j2] =
     *	   structure y = lazy [x1.y : j1 :> x2.y = j2]
     *  [x1 . interface y:k1 :> x2 . interface y:k2 = j2] =
     *     interface y = lazy (x2.y)
     *
     * Here in [x1 : j1 :> x2 = j2] the structure is bound to x1 and has
     * signature j1, while the instance structure representing the generative
     * parts of interface j2 is bound to x2.
     *
     * Note that the contravariant coercion of a functor argument is always
     * transparent and so no instance structure is needed. We can thus pass
     * whatever we want for x2, it remains unused.
     *
     * Moreover, we apply the optimization that - if the transformation is the
     * identity function - the coercion is a no-op.
     *)

    and upInf(isOpaque, isntIdentity, x1,j1,x2,j2, r,t1,t2) =
	if Inf.isTop j2 andalso Inf.isTop j1 then
	    NONE
	else if Inf.isSig j2 andalso Inf.isSig j1 then
	    let
		val s1 = Inf.asSig j1
		val s2 = Inf.asSig j2
		val (fields,isntIdentity') =
		    upItems(isOpaque, isntIdentity,
			    x1, s1, x2, Inf.items s2, r, [])
	    in
		if isntIdentity' orelse Inf.size s1 <> Inf.size s2 then
		    SOME(O.ProdExp(typInfo(r,t2), fields))
		else
		    NONE
	    end
	else if Inf.isArrow j2 andalso Inf.isArrow j1 then
	    let
		val (p1,j11,j12) = Inf.asArrow j1
		val (p2,j21,j22) = Inf.asArrow j2
		val    (t11,t12) = Type.asArrow t1
		val    (t21,t22) = Type.asArrow t2

		val i' = nonInfo r
		val i1 = typInfo(r, t21)
		val i2 = typInfo(r, t12)
		val y' = O.Id(i1, Stamp.new(), Name.InId)
		val z' = O.Id(i2, Stamp.new(), Name.InId)
		val y  = O.ShortId(i1, y')
		val z  = O.ShortId(i2, z')
	    in
		case (upInf(false, false, y,j21,y(*unsued*),j11, r,t21,t11),
		      upInf(isOpaque, isntIdentity, z,j12,x2,j22, r,t12,t22))
		  of (SOME exp1, SOME exp2) =>
		     let
			val x1exp  = O.VarExp(typInfo(r,t1), x1)
			val ypat   = O.VarPat(typInfo(r,t21), y')
			val zpat   = O.VarPat(typInfo(r,t12), z')
			val appexp = O.AppExp(typInfo(r,t12), x1exp, exp1)
			val dec    = O.ValDec(i', zpat, appexp)
			val letexp = O.LetExp(typInfo(r,t22), #[dec], exp2)
		     in
			SOME(O.FunExp(typInfo(r,t2),#[O.Match(i',ypat,letexp)]))
		     end
		   | (NONE, SOME exp2) =>
		     let
			val x1exp  = O.VarExp(typInfo(r,t1), x1)
			val yexp   = O.VarExp(typInfo(r,t21), y)
			val ypat   = O.VarPat(typInfo(r,t21), y')
			val zpat   = O.VarPat(typInfo(r,t12), z')
			val appexp = O.AppExp(typInfo(r,t12), x1exp, yexp)
			val dec    = O.ValDec(i', zpat, appexp)
			val letexp = O.LetExp(typInfo(r,t22), #[dec], exp2)
		     in
			SOME(O.FunExp(typInfo(r,t2),#[O.Match(i',ypat,letexp)]))
		     end
		   | (SOME exp1, NONE) =>
		     let
			val x1exp  = O.VarExp(typInfo(r,t1), x1)
			val ypat   = O.VarPat(typInfo(r,t21), y')
			val appexp = O.AppExp(typInfo(r,t12), x1exp, exp1)
		     in
			SOME(O.FunExp(typInfo(r,t2),#[O.Match(i',ypat,appexp)]))
		     end
		   | (NONE, NONE) => NONE
	    end
	else (* j1 is sig or arrow, j2 is top *)
	    SOME(trUnit r)

    and upItems(isOpaque, isntIdentity, x1, s1, x2, [], r, fields) =
	    (Vector.fromList fields, isntIdentity)
      | upItems(isOpaque, isntIdentity, x1, s1, x2, item::items, r, fields) =
	if Inf.isValItem item then
	    let
		val (a,t2,_) = Inf.asValItem item
		val    t1    = Inf.lookupVal(s1,a)
		val    i1    = typInfo(r,t1)
		val    i2    = typInfo(r,t2)
		val    i'    = nonInfo r
		val    l'    = O.Lab(i', trValLabel a)
		val    y1    = O.LongId(i1,x1,l')
		val    exp   = O.LazyExp(i2, O.UpExp(i2, O.VarExp(i1,y1)))
	    in
		upItems(isOpaque, isntIdentity, x1, s1, x2, items, r,
			O.Field(i',l',exp)::fields)
	    end
	else if Inf.isTypItem item then
	    let
		val (a,k,d) = Inf.asTypItem item
		val (x,isntIdentity') =
		    (* Case 0, no module RTT: use structure value
		     * Case 1, w/o abstraction: use structure value
		     * Case 2, abstract: use signature value, is not identity
		     * Case 3, manifest, is identity up to now:
		     *         use either structure or signature value
		     * Case 4, manifest, is not identity:
		     *         use signature value
		     *)
		    if not isOpaque orelse !Switches.Bootstrap.rttLevel <>
					    Switches.Bootstrap.FULL_RTT then
			(x1, isntIdentity)
		    else
			(x2, isntIdentity orelse Option.isNone d)
		val i   = typInfo(r, typ_typ)
		val i'  = nonInfo r
		val l'  = O.Lab(i', trTypLabel a)
		val y   = O.LongId(i, x, l')
		val exp = O.LazyExp(i, O.VarExp(O.infoLongid y, y))
	    in
		upItems(isOpaque, isntIdentity', x1, s1, x2, items, r,
			O.Field(i',l',exp)::fields)
	    end
	else if Inf.isModItem item then
	    let
		val (a,j2,_) = Inf.asModItem item
		val    j1    = Inf.lookupMod(s1,a)
		val    t1    = infToTyp j1
		val    t2    = infToTyp j2
		val    i1    = typInfo(r,t1)
		val    i2    = typInfo(r,t2)
		val    i'    = nonInfo r
		val    a'    = trModLabel a
		val    l'    = O.Lab(i', a')
		val    y1    = O.LongId(i1,x1,l')
		val    y2    = if not isOpaque
			       orelse !Switches.Bootstrap.rttLevel <>
				       Switches.Bootstrap.FULL_RTT
			       then y1 (*unused*)
			       else let
				   val row = Type.asProd'(#typ(O.infoLongid x2))
				   val typ = Type.lookupRow(row, a')
			       in
				   O.LongId(typInfo(r,typ),x2,l')
			       end
		val (exp,isntIdentity') =
		    case upInf(isOpaque, isntIdentity, y1,j1,y2,j2, r,t1,t2)
		      of NONE => (if isOpaque then O.UpExp(i2, O.VarExp(i1,y1))
		 			     else O.VarExp(i1,y1), isntIdentity)
		       | SOME exp => (exp, true)
		val  exp' = O.LazyExp(i2,exp)
	    in
		upItems(isOpaque, isntIdentity', x1, s1, x2, items, r,
			O.Field(i',l',exp')::fields)
	    end
	else if Inf.isInfItem item then
	    let
		val (a,k,d) = Inf.asInfItem item
		val (x,isntIdentity') =
		    (* Case 0, no module RTT: use structure value
		     * Case 1, w/o abstraction: use structure value
		     * Case 2, abstract: use signature value, is not identity
		     * Case 3, manifest, is identity up to now:
		     *         use either structure or signature value
		     * Case 4, manifest, is not identity:
		     *         use signature value
		     *)
		    if not isOpaque orelse !Switches.Bootstrap.rttLevel <>
					    Switches.Bootstrap.FULL_RTT then
			(x1, isntIdentity)
		    else
			(x2, isntIdentity orelse Option.isNone d)
		val t1  = infToInstTyp(Inf.lookupMod(s1,a))
		val t2  = case d of SOME j => infToInstTyp j
				  | NONE =>
					(* new abstract type *)
					Type.inCon(ikindToKind k, Type.CLOSED,
						   Path.fromLab a)
		val i1  = typInfo(r, typ_infinst t1)
		val i2  = typInfo(r, typ_infinst t2)
		val i'  = nonInfo r
		val l'  = O.Lab(i', trInfLabel a)
		val y   = O.LongId(i1, x, l')
		val exp = O.LazyExp(i2, O.UpExp(i2, O.VarExp(i1, y)))
	    in
		upItems(isOpaque, isntIdentity', x1, s1, x2, items, r,
			O.Field(i',l',exp)::fields)
	    end
	else (* fixity *)
	    upItems(isOpaque, isntIdentity, x1, s1, x2, items, r, fields)



  (* Types *)

    (* The code generated to produce runtime types and interfaces very much
     * mirrors what happens in the elaborator.
     *)

    and trTyp t =
	if !Switches.Bootstrap.rttLevel = Switches.Bootstrap.NO_RTT then
	    O.FailExp(typInfo(#region(I.infoTyp t), typ_typ))
	else
	    trTyp' t

    and trTyp'(I.VarTyp(i, I.Id(_,z,n))) =
	(* [a] = Type.inVar{[a]} *)
	let
	    val x' = O.Id(typInfo(#region i, typ_var), z, trTypName n)
	in
	    typOp(lab_inVar, idToExp x')
	end

      | trTyp'(I.PrimTyp(i,s)) =
	(* [prim s] = Type.inCon(PervasiveType.lookup s) *)
	typOp(lab_inCon, pervTypeOp(lab_lookup, trString(#region i, s)))

      | trTyp'(I.ConTyp(i,y)) =
	(* [y] = $y *)
	O.VarExp(typInfo(#region i, typ_typ), trTyplongid y)

      | trTyp'(I.FunTyp(i,x,t)) =
	(* [fn x => t] = let val $x = Type.var <<kind x>>
	 *               in Type.inLambda($x,[t]) end
	 *)
	trBindTyp lab_inLambda (i, x, t, Type.domKind(Type.kind(#typ i)))

      | trTyp'(I.AppTyp(i,t1,t2)) =
	(* [t1 t2] = Type.inApply([t1],[t2]) *)
	let
	    val e1' = trTyp' t1
	    val e2' = trTyp' t2
	in
	    typOp(lab_inApply,
		  O.TupExp(typInfo(#region i, typ_typtyp), #[e1',e2']))
	end

      | trTyp'(I.RefTyp(i,t)) =
	(* [Ref t] = Type.inApply(PervasiveType.typ_ref, [t]) *)
	let
	    val e1' = pervTypeVal lab_typ_ref
	    val e2' = trTyp' t
	in
	    typOp(lab_inApply,
		  O.TupExp(typInfo(#region i, typ_typtyp), #[e1',e2']))
	end

      | trTyp'(I.TupTyp(i,ts)) =
	(* [(t1,...,tn)] = Type.inTuple #[t1,...,tn] *)
	let
	    val es' = Vector.map trTyp' ts
	in
	    typOp(lab_inTuple, O.VecExp(typInfo(#region i, typ_typVec), es'))
	end

      | trTyp'(I.ProdTyp(i,r)) =
	(* [{r}] = Type.inProd[r] *)
	typOp(lab_inProd, trTypRow r)

      | trTyp'(I.SumTyp(i,r)) =
	(* [<r>] = Type.inSum[r] *)
	typOp(lab_inSum, trTypRow r)

      | trTyp'(I.ArrTyp(i,t1,t2)) =
	(* [t1 -> t2] = Type.inArrow([t1],[t2]) *)
	let
	    val e1' = trTyp' t1
	    val e2' = trTyp' t2
	in
	    typOp(lab_inArrow,
		  O.TupExp(typInfo(#region i, typ_typtyp), #[e1',e2']))
	end

      | trTyp'(I.AllTyp(i,x,t)) =
	(* [forall x => t] = let val $x = Type.var <<kind x>>
	 *                   in Type.inAll($x,[t]) end
	 *)
	trBindTyp lab_inAll (i,x,t, Type.kindVar(#1(Type.asAll'(#typ i))))

      | trTyp'(I.ExTyp(i,x,t)) =
	(* [exists x => t] = let val $x = Type.var <<kind x>>
	 *                   in Type.inExists($x,[t]) end
	 *)
	trBindTyp lab_inExist (i,x,t, Type.kindVar(#1(Type.asExist'(#typ i))))

      | trTyp'(I.PackTyp(i,j)) =
	(* [pack j] = Type.inPack[j] *)
	(*UNFINISHED*)
	unfinished (#region i) "trTyp" "runtime package types"

      | trTyp'(I.SingTyp(i,y)) =
	(* [sing y] = Type.inSing[y] *)
	(*UNFINISHED*)
	unfinished (#region i) "trTyp" "runtime singleton types"

      | trTyp'(I.AbsTyp(i, isExtensible)) =
	raise Crash.Crash "TranslationPhase.trTyp: AbsTyp"

    and trTypRep(x, t) =
	if !Switches.Bootstrap.rttLevel = Switches.Bootstrap.NO_RTT then
	    O.FailExp(typInfo(#region(I.infoTyp t), typ_typ))
	else
	    let
		val r  = #region(I.infoId x)
		val p' = pathOp(lab_fromLab,
				labOp(lab_fromString,
				      trString(r, Name.toString(I.name x))))
	    in
		case trTypRep'(p', t)
		  of NONE    => trTyp' t
		   | SOME e' => e'
	    end

    and trTypRep'(p', I.FunTyp(i,x,t)) = trTypRep'(p', t)

      | trTypRep'(p', I.AbsTyp(i, isExtensible)) =
	(* [abstract]_p = Type.inCon(<<kind>>, <<isExtensible>>, p) *)
	let
	    val r   = #region i
	    val e1' = trKind(r, Type.kind(#typ i))
	    val e2' = trSort(r, if isExtensible then Type.OPEN else Type.CLOSED)
	in
	    SOME(typOp(lab_inCon, O.TupExp(typInfo(r,typ_con), #[e1',e2',p'])))
	end

      | trTypRep'(p', t) = NONE

    and trTypRow(I.Row(i,fs,b)) =
	(* [f1,...,fn]     = [f1](...[fn](Type.emptyRow())...)
	 * [f1,...,fn,...] = [f1](...[fn](Type.unknownRow())...) *)
	let
	    val a  = if b then lab_unknownRow else lab_emptyRow
	    val e' = rowOp(a, trUnit(#region i))
	in
	    Vector.foldl trTypField e' fs
	end

    and trTypField(I.Field(i1, I.Lab(i2,a), t), e3') =
	(* [a:t]_e3 = Type.extendRow(Label.fromString "a", [t], e3) *)
	let
	    val r   = #region i1
	    val e1' = labOp(lab_fromString,
			    trString(#region i2, Label.toString a))
	    val e2' = trTyp' t
	in
	    rowOp(lab_extendRow,
		  O.TupExp(typInfo(r,typ_labtyprow), #[e1',e2',e3']))
	end

    and trBindTyp a (i,x,t,k) =
	let
	    val r  = #region i
	    val x' = trVarid x
	    val d' = O.ValDec(nonInfo r, idToPat x',
			      varOp(lab_var, trKind(r, k)))
	    val e' = typOp(a, O.TupExp(typInfo(r,typ_vartyp),
				       #[idToExp x', trTyp' t]))
	in
	    O.LetExp(O.infoExp e', #[d'], e')
	end


  (* Interfaces *)

    and trInf j =
	if !Switches.Bootstrap.rttLevel <> Switches.Bootstrap.FULL_RTT then
	    let
		val i   = I.infoInf j
		val r   = #region i
		val t2  = infToInstTyp(#inf i)
		val e1' = O.FailExp(typInfo(r, typ_inf))
		val e2' = O.FailExp(typInfo(r, t2))
	    in
		O.TupExp(typInfo(r, Type.inTuple #[typ_inf,t2]), #[e1',e2'])
	    end
	else
	    trInf' j

    and trInf'(I.TopInf(i)) =
	(* [any] = (Inf.inTop(), ()) *)
	let
	    val r   = #region i
	    val e2' = trUnit r
	    val e1' = infOp(lab_inTop, e2')
	in
	    O.TupExp(typInfo(r,typ_infunit), #[e1',e2'])
	end

      | trInf'(I.PrimInf(i,s)) =
	(* [prim s] = (Inf.inCon(PervasiveInf.lookup s), ()) *)
	let
	    val r   = #region i
	    val e1' = infOp(lab_inCon,
			    pervInfOp(lab_lookup, trString(#region i, s)))
	    val e2' = trUnit r
	in
	    O.TupExp(typInfo(r,typ_infunit), #[e1',e2'])
	end

      | trInf'(I.ConInf(i,y)) =
	(* [y] = lazy [y]() *)
	let
	    val r   = #region i
	    val t1  = infToInstTyp(#inf i)
	    val e1' = O.VarExp(typInfo(r,t1), trInflongid y)
	    val e2' = trUnit r
	    val i'  = typInfo(r, #2(Type.asArrow' t1))
	in
	    O.LazyExp(i', O.AppExp(i', e1', e2'))
	end

      | trInf'(I.SigInf(i,ss)) =
	(* [sig ss end] = let val s = Inf.empty() [ss]_s
	 *                in (Inf.inSig s, [ss]') end
	 *)
	let
	    val r   = #region i
	    val i'  = typInfo(r,typ_sign)
	    val s'  = O.Id(i', Stamp.new(), Name.InId)
	    val e0' = sigOp(lab_empty, trUnit r)
	    val d'  = O.ValDec(nonInfo r, O.VarPat(i',s'), e0')
	    val ss' = trSpecs(idToExp s', ss)

	    val e1' = infOp(lab_inSig, idToExp s')
	    val fs' = trSpecsInst ss
	    val t2  = infToInstTyp(#inf i)
	    val e2' = O.ProdExp(typInfo(r,t2), fs')
	    val i'  = typInfo(r, Type.inTuple #[typ_inf,t2])
	    val e'  = O.TupExp(i', #[e1',e2'])
	in
	    O.LetExp(i', Vector.append(#[d'], ss'), e')
	end

      | trInf'(I.FunInf(i,x,j1,j2)) =
	(* [fn(x:j1) => j2] = let val  x0     = Path.invent()
	 *                        val (x1,x$) = [j1]
	 *                        val (x2,_)  = [j2]
	 *                    in (Inf.inLambda(x0,x1,x2), ???) end
	 *)
	(*trBindInf lab_inLambda (i,x,j1,j2)*)
	(*UNFINISHED*)
	unfinished (#region i) "trInf" "runtime parameterized interfaces"

      | trInf'(I.AppInf(i,j,m)) =
	(* [j m] = (Inf.inApply([j],[m],???), ???) *)
	(*UNFINISHED*)
	let
	    val r   = #region i
	    val e1' = trInf' j
	    val e2' = trMod m
	    val e3' = infOp(lab_inTop, trUnit r)	(* UNFINISHED! *)
	    val e'  = O.TupExp(typInfo(r, typ_infpathinf), #[e1',e2',e3'])
	in
	    infOp(lab_inApply, e')
	end

      | trInf'(I.CompInf(i,j1,j2)) =
	(* [j1 where j2] = let val x = Inf.intersect(#1[j1], #1[j2])
	 *                 in (x, lazy {....}) end
	 *)
	(*UNFINISHED *)
	let
	    val r   = #region i
	    val x'  = O.Id(typInfo(r,typ_inf), Stamp.new(), Name.InId)
	    val xx' = idToExp x'
	    val l'  = O.Lab(nonInfo r, Label.fromInt 1)
	    val e1' = O.SelExp(typInfo(#region(I.infoInf j1), typ_inf),
			       l', trInf j1)
	    val e2' = O.SelExp(typInfo(#region(I.infoInf j2), typ_inf),
			       l', trInf j2)
	    val e'  = infOp(lab_intersect,
			    O.TupExp(typInfo(r,typ_infinf), #[e1',e2']))
	    val d'  = O.ValDec(nonInfo r, idToPat x', e')

	    val j   = #inf i
	    val t   = infToInstTyp j
	    val s'  = O.LazyExp(typInfo(r,t), rebuildInfInst(r,xx',j))
	    val i'  = typInfo(r, Type.inTuple #[typ_inf,t])
	in
	    O.LetExp(i', #[d'], O.TupExp(i', #[xx',s']))
	end

      | trInf'(I.ArrInf(i,x,j1,j2)) =
	(* [fct(x:j1) -> j2] = let val  x0     = Path.invent()
	 *                         val (x1,x$) = [j1]
	 *                         val (x2,x3) = [j2]
	 *                     in (Inf.inArrow(x0,x1,x2), x3) end
	 *)
	trBindInf lab_inArrow (i,x,j1,j2)

      | trInf'(I.LetInf(i,ds,j)) =
	(* [let ds in j end] = let [ds] in [j] end *)
	O.LetExp(typInfo(#region i, typ_inf), trDecs ds, trInf' j)

      | trInf'(I.SingInf(i,m)) =
	(* [sing m] = (Inf.inSing[m], ???) *)
	(*UNFINISHED*)
	unfinished (#region i) "trInf" "runtime singleton interfaces"

      | trInf'(I.AbsInf(i)) =
	raise Crash.Crash "TranslationPhase.trInf: AbsInf"

    and trInfRep(x, j) =
	if !Switches.Bootstrap.rttLevel <> Switches.Bootstrap.FULL_RTT then
	    let
		val i = I.infoInf j
	    in
		O.FailExp(typInfo(#region i, typ_infinst(infToInstTyp(#inf i))))
	    end
	else
	    (* [j]_p = fn _ => [j]_id,id,p *)
	    let
		val r  = #region(I.infoId x)
		val p' = pathOp(lab_fromLab,
			    labOp(lab_fromString,
				  trString(r, Name.toString(I.name x))))
		val r  = #region(I.infoInf j)
		val e' = case trInfRep'(fn k' => k', fn e' => e', p', j)
			   of NONE    => trInf' j
			    | SOME e' => e'
		val m' = O.Match(nonInfo r, O.JokPat(typInfo(r,typ_unit)), e')
	    in
		O.FunExp(typInfo(r, Type.inArrow(typ_unit, #typ(O.infoExp e'))),
			 #[m'])
	    end

    and trInfRep'(mkKind, mkStr, p', I.FunInf(i,x,j1,j2)) =
	(*UNFINISHED: have to bind structure trModid(x) *)
	(* [fn(x:j1) => j2]_MkKind,MkStr,p =
	 *       [j2](fn k => MkKind
	 *            <let val p = Path.invent()
	 *            val $x = ????
	 *            in Inf.inDependent(p,[j1],<k>) end>,
	 *            fn e => MkStr ?????
	 *            <>)
	 *)
	let
	    fun mkKind' k' =
		let
		    val r   = #region(I.infoId x)
		    val i'  = nonInfo(#region i)
		    val i1' = typInfo(r, typ_path)
		    val p'  = O.Id(i1', Stamp.new(), Name.InId)
		    val e1' = pathOp(lab_invent, trUnit r)
		    val d1' = O.ValDec(i', O.VarPat(i1',p'), e1')
		    val x'  = trModid x
		    (*val i2' = typInfo(r, ???)
		    val d2' = O.ValDec(i', O.VarPat(i2',x'), ??)*)
		    val e'  = ikindOp(lab_inDependent,
				     O.TupExp(typInfo(#region i,typ_pathinfinf),
					      #[idToExp p', trInf' j1, k']))
		in
		    mkKind(O.LetExp(O.infoExp e', #[d1'(*,d2'*)], e'))
		end

	    fun mkStr' e' = (*UNFINISHED*) e'
	in
	    trInfRep'(mkKind', mkStr', p', j2)
	end

      | trInfRep'(mkKind, mkStr, p', I.AbsInf(i)) =
	(* [abstract]_MkKind,MkStr,p = (Inf.inCon(MkKind<Inf.inGround()>, p),
	 *                              MkStr<()>)
	 *)
	let
	    val r   = #region i
	    val e1' = mkKind(ikindOp(lab_inGround, trUnit r))
	    val e3' = typOp(lab_inCon,
			    O.TupExp(typInfo(r, typ_icon), #[e1',p']))
	    val e4' = mkStr(trUnit r)
	    val i'  = typInfo(r, Type.inTuple #[typ_con, #typ(O.infoExp e4')])
	in
	    SOME(O.TupExp(i', #[e3',e4']))
	end

      | trInfRep'(mkKind, mkStr, p', j) = NONE

    and trBindInf a (i,x,j1,j2) =
	(* [fct(x:j1) -> j2] = let val  x0     = Path.invent()
	 *                         val (x1,x$) = [j1]
	 *                         val (x2,x3) = [j2]
	 *                     in (Inf.a(x0,x1,x2), x3) end
	 *)
	let
	    val r   = #region i
	    val i'  = nonInfo r
	    val i0' = typInfo(#region(I.infoId x), typ_path)
	    val x0' = O.Id(i0', Stamp.new(), Name.InId)
	    val e0' = pathOp(lab_invent, trUnit r)
	    val d0' = O.ValDec(i', O.VarPat(i0',x0'), e0')

	    val e1' = trInf' j1
	    val t1  = Vector.sub(Type.asTuple'(#typ(O.infoExp e1')), 1)
	    val ii' = typInfo(#region(I.infoId x), t1)
	    val i1' = typInfo(#region(I.infoInf j1), typ_inf)
	    val x'  = O.Id(ii', I.stamp x, trModName(I.name x))
	    val x1' = O.Id(i1', Stamp.new(), Name.InId)
	    val p1' = O.TupPat(O.infoExp e1', #[O.VarPat(i1',x1'),
						O.VarPat(ii',x')])
	    val d1' = O.ValDec(i', p1', e1')

	    val r2  = #region(I.infoInf j2)
	    val e2' = trInf' j2
	    val t2  = Vector.sub(Type.asTuple'(#typ(O.infoExp e2')), 1)
	    val i2' = typInfo(r2, typ_inf)
	    val i3' = typInfo(r2, t2)
	    val x2' = O.Id(i2', Stamp.new(), Name.InId)
	    val x3' = O.Id(i3', Stamp.new(), Name.InId)
	    val p2' = O.TupPat(O.infoExp e2', #[O.VarPat(i2',x2'),
						O.VarPat(i3',x3')])
	    val d2' = O.ValDec(i', p2', e2')

	    val e1' = infOp(a, O.TupExp(typInfo(r,typ_pathinfinf),
				#[idToExp x0', idToExp x1', idToExp x2']))
	    val e2' = idToExp x3'
	    val e'  = O.TupExp(typInfo(r,Type.inTuple #[typ_inf,t2]),#[e1',e2'])
	in
	    O.LetExp(O.infoExp e', #[d0',d1',d2'], e')
	end


    (* This is needed to deal with CompInf only. Ideally we should not need it.
     * It is inefficient, in particular for nested signatures.
     * Not sure how we should modify CompInf...
     *)

    and rebuildInfInst(r,x',j) =
	if Inf.isSig j then
	    (* [sig items end] --> let val x1 = Inf.asSig x in [items] end *)
	    let
		val s   = Inf.asSig j

		val x1' = O.Id(typInfo(r,typ_sign), Stamp.new(), Name.InId)
		val e'  = sigOp(lab_asSig, x')
		val d'  = O.ValDec(nonInfo r, idToPat x1', e')

		val e'  = O.ProdExp(typInfo(r, infToInstTyp j),
				    rebuildSigInst(r, idToExp x1', s))
	    in
		O.LetExp(O.infoExp e', #[d'], e')
	    end
	else if Inf.isArrow j then
	    (* [fct(x:j1) -> j2] --> let val x2 = #3(Inf.asArrow j)
	     *                       in [j2] end
	     *)
	    let
		val (_,_,j2) = Inf.asArrow j

		val x2' = O.Id(typInfo(r,typ_sign), Stamp.new(), Name.InId)
		val e'  = O.SelExp(typInfo(r,typ_inf),
				   O.Lab(nonInfo r, Label.fromInt 3),
				   sigOp(lab_asArrow, x'))
		val d'  = O.ValDec(nonInfo r, idToPat x2', e')

		val e'  = rebuildInfInst(r, idToExp x2', j2)
	    in
		O.LetExp(O.infoExp e', #[d'], e')
	    end
	else
	    trUnit r

    and rebuildSigInst(r,x',s) =
	Vector.fromList(List.foldl (rebuildItemInst(r,x')) [] (Inf.items s))

    and rebuildItemInst (r,x') (item,fs') =
	if Inf.isValItem item then
	    (*UNFINISHED: this should go, but how?*)
	    (* [val y : t]_x --> y = fail *)
	    let
		val (a,t,_) = Inf.asValItem item
		val  l'     = O.Lab(nonInfo r, trValLabel a)
		val  e'     = O.FailExp(typInfo(r,t))
	    in
		O.Field(nonInfo r, l', e') :: fs'
	    end
	else if Inf.isTypItem item then
	    (* [type y = t]_x --> y = Inf.lookupTyp(x,[y]) *)
	    let
		val (a,_,_) = Inf.asTypItem item
		val  l'  = O.Lab(nonInfo r, trTypLabel a)
		val  e1' = labOp(lab_fromString, trString(r, Label.toString a))
		val  e'  = typInfOp(lab_lookupTyp,
				    O.TupExp(typInfo(r,typ_signlab), #[x',e1']))
	    in
		O.Field(nonInfo r, l', e') :: fs'
	    end
	else if Inf.isModItem item then
	    (* [module y : j]_x --> y = let val x1 = Inf.lookupMod(x,[y])
	     *                          in [j]_x1 end
	     *)
	    let
		val (a,j1,_) = Inf.asModItem item
		val  l'  = O.Lab(nonInfo r, trModLabel a)
		val  t1  = infToInstTyp j1
		val  x1' = O.Id(typInfo(r,t1), Stamp.new(), Name.InId)

		val  e1' = labOp(lab_fromString, trString(r, Label.toString a))
		val  e2' = infOp(lab_lookupMod,
				 O.TupExp(typInfo(r,typ_signlab), #[x',e1']))
		val  d'  = O.ValDec(nonInfo r, idToPat x1', e2')

		val  e3' = rebuildInfInst(r, idToExp x1', j1)
		val  e'  = O.LetExp(O.infoExp e3', #[d'], e3')
	    in
		O.Field(nonInfo r, l', e') :: fs'
	    end
	else if Inf.isInfItem item then
	    (* [interface y = j]_x --> y = fn _ =>
	     *                             let val x1 = Inf.instance
	     *                                          (Inf.lookupInf(x,[y]))
	     *                             in (x1, [j]_x1) end
	     *)
	    let
		val (a,k,d) = Inf.asInfItem item
		val  l'  = O.Lab(nonInfo r, trInfLabel a)
		val  x1' = O.Id(typInfo(r,typ_inf), Stamp.new(), Name.InId)
		val  xx' = idToExp x1'

		val  e1' = labOp(lab_fromString, trString(r, Label.toString a))
		val  e2' = typInfOp(lab_lookupInf,
				    O.TupExp(typInfo(r,typ_signlab), #[x',e1']))
		val  e3' = infOp(lab_instance, e2')
		val  d'  = O.ValDec(nonInfo r, idToPat x1', e3')

		val  e4' = case d
			     of SOME j =>
				O.TupExp(typInfo(r,typ_infinst(infToInstTyp j)),
					 #[xx', rebuildInfInst(r,xx',j)])
			      | NONE =>
				O.TupExp(typInfo(r,typ_infunit),
					 #[xx', trUnit r])
		val  t   = #typ(O.infoExp e4')

		val  m'  = O.Match(nonInfo r,O.JokPat(typInfo(r,typ_unit)), e3')
		val  e'  = O.FunExp(typInfo(r, Type.inArrow(typ_unit,t)), #[m'])
	    in
		O.Field(nonInfo r, l', e') :: fs'
	    end
	else (* fixity *)
	    fs'


  (* Declarations *)

    and trDecs ds        = Vector.rev(Vector.fromList(trDecs'(ds, [])))
    and trDecs'(ds, ds') = Vector.foldl trDec ds' ds

    and trDec(I.ValDec(i,p,e), ds') =
	(* [val p = e] = val [p] = [e] *)
	let
	    val d' = O.ValDec(i, trPat p, trExp e)
	in
	    d' :: ds'
	end

      | trDec(I.TypDec(i,x,t), ds') =
	(* [type x = t] = val $x = [t]_(Path.fromLab(Label.fromString "x")) *)
	let
	    val e' = trTypRep(x, t)
	    val d' = O.ValDec(i, idToPat(trTypid x), e')
	in
	    d' :: ds'
	end

      | trDec(I.ModDec(i,x,m), ds') =
	(* [module x = m] = val x$ = [m] *)
	let
	    val r  = #region(I.infoId x)
	    val e' = trMod m
	    val d' = O.ValDec(i, idToPat(trModid x), e')
	in
	    d' :: ds'
	end
	before updatePervasive x

      | trDec(I.InfDec(i,x,j), ds') =
	(* [interface x = j] = val $x = [j]_(Path.fromLab(Label.fromString "x"))
	 *)
	let
	    val e' = trInfRep(x, j)
	    val d' = O.ValDec(i, idToPat(trInfid x), e')
	in
	    d' :: ds'
	end

      | trDec(I.RecDec(i,ds), ds') =
	O.RecDec(i, trRecDecs ds) :: trRHSRecDecs'(ds, trLHSRecDecs'(ds, ds'))

      | trDec(I.FixDec(i,x,q), ds')	= ds'
      | trDec(I.VarDec(i,x,d), ds')	= trDec(d, ds')
      | trDec(I.LocalDec(i,ds), ds')	= trDecs'(ds, ds')


    and trRecDecs ds        = Vector.rev(Vector.fromList(trRecDecs'(ds, [])))
    and trRecDecs'(ds, ds') = Vector.foldl trRecDec ds' ds

    and trRecDec(I.TypDec(i,x,t), ds')	= ds'
      | trRecDec(d,ds')			= trDec(d,ds')


    and trLHSRecDecs'(ds, ds') = Vector.foldl trLHSRecDec ds' ds
    and trLHSRecDec(I.TypDec(i,x,t), ds') =
	(* [type x = t]' = val $x = Type.unknown(<<kind>>) *)
	let
	    val r  = #region i
	    val e' = if !Switches.Bootstrap.rttLevel = Switches.Bootstrap.NO_RTT
		     then O.FailExp(typInfo(r, typ_typ))
		     else typOp(lab_unknown,
				trKind(r, Type.kind(#typ(I.infoTyp t))))
	    val d' = O.ValDec(nonInfo r, idToPat(trTypid x), e')
	in
	    d' :: ds'
        end

      | trLHSRecDec(d, ds') = ds'

    and trRHSRecDecs'(ds, ds') = Vector.foldl trRHSRecDec ds' ds
    and trRHSRecDec(I.TypDec(i,x,t), ds') =
	(* [type x = t]' = val _ = Type.fill($x,
	 *                              [t]_(Path.fromLab(Label.fromString"x")))
	 *)
	if !Switches.Bootstrap.rttLevel = Switches.Bootstrap.NO_RTT then
	    ds'
	else let
	    val r   = #region i
	    val e1' = idToExp(trTypid x)
	    val e2' = trTypRep(x, t)
	    val e'  = unitTypOp(lab_fill,
				O.TupExp(typInfo(r, typ_typtyp), #[e1',e2']))
	    val d'  = O.ValDec(nonInfo r, O.JokPat(typInfo(r,typ_unit)), e')
	in
	    d' :: ds'
	end

      | trRHSRecDec(d, ds') = ds'



  (* Specifications *)

    and trSpecs(s', ss)       = Vector.rev(Vector.fromList(trSpecs'(s',ss,[])))
    and trSpecs'(s', ss, ds') = Vector.foldl (trSpec s') ds' ss

    and trSpec s' (I.ValSpec(i,x,t), ds') =
	(* [val x : t]_s = val _ = Inf.extendVal(s,
	 *                                  Inf.newVal(s, Label.fromString[x]),
	 *                                  [t], NONE)
	 *)
	let
	    val r  = #region i
 	    val r0 = #region(I.infoId x)
	    val a' = labOp(lab_fromString,
			   trString(r0, Name.toString(I.name x)))
	    val p' = pathInfOp(lab_newVal,
			       O.TupExp(typInfo(r0, typ_signlab), #[s',a']))
	    val t' = trTyp' t	(*UNFINISHED: singletons*)
	    val o' = trTag(typInfo(r, typ_pathOpt), lab_none)
	    val e' = unitInfOp(lab_extendVal,
			O.TupExp(typInfo(r, typ_extendVal), #[s',p',t',o']))
	    val d' = O.ValDec(nonInfo r, O.JokPat(O.infoExp e'), e')
	in
	    d' :: ds'
	end

      | trSpec s' (I.TypSpec(i,x,t), ds') =
	(* [type x = t]_s = val  p = Inf.newTyp(s, Label.fromString "x")
	 *                  val $x = [t]_p
	 *                  val  _ = Inf.extendTyp(s, p, Type.kind $x, SOME $x)
	 *)
	let
	    val r   = #region i
	    val i'  = nonInfo r

 	    val r0  = #region(I.infoId x)
	    val p'  = O.Id(typInfo(r0,typ_path), Stamp.new(), Name.InId)
	    val pp' = idToExp p'
	    val a'  = labOp(lab_fromString,
			    trString(r0, Name.toString(I.name x)))
	    val e0' = pathInfOp(lab_newTyp,
				O.TupExp(typInfo(r0, typ_signlab), #[s',a']))
	    val d0' = O.ValDec(nonInfo r0, idToPat p', e0')

	    val x'  = trTypid x
	    val xx' = idToExp x'
	    val to' = trTypRep'(pp', t)
	    val e1' = case to' of NONE    => trTyp' t
			        | SOME t' => t'
	    val d1' = O.ValDec(i', idToPat x', e1')

	    val k'  = kindOp(lab_kind, xx')
	    val o'  = case to'
			of SOME _ => (* generative *)
			   trTag(typInfo(r, typ_typOpt), lab_none)
			 | NONE =>
			   trTagged(typInfo(r,typ_typOpt), lab_some, xx', false)
	    val e2' = unitInfOp(lab_extendTyp,
			O.TupExp(typInfo(r, typ_extendTyp), #[s',pp',k',o']))
	    val d2' = O.ValDec(nonInfo r, O.JokPat(O.infoExp e2'), e2')
	in
	    d2' :: d1' :: d0' :: ds'
	end

      | trSpec s' (I.ModSpec(i,x,j), ds') =
	(* [module x : j]_s = val (x1,$x) = [j]
	 *                    val _  = Inf.extendMod(s,
	 *                                  Inf.newMod(s, Label.fromString "x"),
	 *                                  x1, NONE)
	 *)
	let
	    val r   = #region i
	    val e1' = trInf' j
	    val t1  = Vector.sub(Type.asTuple'(#typ(O.infoExp e1')), 1)
	    val i'  = typInfo(#region(I.infoId x), t1)
	    val i1' = typInfo(#region(I.infoInf j), typ_inf)
	    val x'  = O.Id(i', I.stamp x, trModName(I.name x))
	    val x1' = O.Id(i1', Stamp.new(), Name.InId)
	    val p1' = O.TupPat(O.infoExp e1', #[O.VarPat(i1',x1'),
						O.VarPat(i', x')])
	    val d1' = O.ValDec(nonInfo r, p1', e1')

 	    val r0  = #region(I.infoId x)
	    val a'  = labOp(lab_fromString,
			    trString(r0, Name.toString(I.name x)))
	    val p'  = pathInfOp(lab_newMod,
				O.TupExp(typInfo(r0, typ_signlab), #[s',a']))
	    val j'  = idToExp x1'
	    val o'  = trTag(typInfo(r, typ_typOpt), lab_none)
	    val e2' = unitInfOp(lab_extendMod,
			O.TupExp(typInfo(r, typ_extendTyp), #[s',p',j',o']))
	    val d2' = O.ValDec(nonInfo r, O.JokPat(O.infoExp e2'), e2')
	in
	    d2' :: d1' :: ds'
	end

      | trSpec s' (I.InfSpec(i,x,j), ds') =
	(* [interface x = j]_s = val p  = Inf.newInf(s, Label.fromString "x")
	 *                       val $x = [j]_p
	 *                       val x2 = lazy #1($x())
	 *                       val _  = Inf.extendInf(s, p,
	 *                                            lazy Inf.kind x2, SOME x2)
	 *)
	let
	    val r   = #region i

 	    val r0  = #region(I.infoId x)
	    val p'  = O.Id(typInfo(r0,typ_path), Stamp.new(), Name.InId)
	    val pp' = idToExp p'
	    val a'  = labOp(lab_fromString,
			    trString(r0, Name.toString(I.name x)))
	    val e0' = pathInfOp(lab_newInf,
				O.TupExp(typInfo(r0, typ_signlab), #[s',a']))
	    val d0' = O.ValDec(nonInfo r0, idToPat p', e0')

	    val x'  = trInfid x
	    val xx' = idToExp x'
	    val jo' = trInfRep'(fn k' => k', fn e' => e', pp', j)
	    val j'  = case jo' of NONE    => trInf' j
			        | SOME j' => j'
	    val i1' = O.infoExp j'
	    val r1  = #region i1'
	    val m'  = O.Match(nonInfo r1, O.JokPat(typInfo(r,typ_unit)), j')
	    val t1  = Type.inArrow(typ_unit, #typ i1')
	    val e1' = O.FunExp(typInfo(r1,t1), #[m'])
	    val d1' = O.ValDec(nonInfo r1, idToPat x', e1')

	    val r2  = r1
	    val i2' = typInfo(r2,typ_inf)
	    val x2' = O.Id(i2', Stamp.new(), Name.InId)
	    val y2' = idToExp x2'
	    val l'  = O.Lab(nonInfo r2, Label.fromInt 1)
	    val e2' = O.AppExp(typInfo(r2, #typ i1'), xx', trUnit r2)
	    val e2' = O.LazyExp(i2', O.SelExp(i2', l', e2'))
	    val d2' = O.ValDec(nonInfo r2, O.VarPat(i2',x2'), e2')

	    val k'  = O.LazyExp(typInfo(r1,typ_ikind), ikindOp(lab_ikind, y2'))
	    val o'  = case jo'
			of SOME _ => (* generative *)
			   trTag(typInfo(r, typ_infOpt), lab_none)
			 | NONE =>
			   trTagged(typInfo(r, typ_infOpt), lab_some, y2',false)
	    val e3' = unitInfOp(lab_extendInf,
			O.TupExp(typInfo(r, typ_extendInf), #[s',pp',k',o']))
	    val d3' = O.ValDec(nonInfo r, O.JokPat(typInfo(r,typ_unit)), e3')
	in
	    d3' :: d2' :: d1' :: d0' :: ds'
	end

      | trSpec s' (I.FixSpec(i, I.Lab(i1,a), I.Fix(i2,q)), ds') =
	(* [fixity x : q]_s = val _ = Inf.extendFix(s,
	 *                                Inf.newFix(s,Label.fromString[{x}]),
	 *                                [q])
	 *)
	let
	    val r  = #region i
	    val r0 = #region i2
	    val a' = labOp(lab_fromString,
			   trString(r0, Label.toString a))
	    val p' = pathInfOp(lab_newFix,
			       O.TupExp(typInfo(r0, typ_signlab), #[s',a']))
	    val q' = trFix(#region i2, q)
	    val e' = unitInfOp(lab_extendFix,
			O.TupExp(typInfo(r, typ_extendFix), #[s',p',q']))
	    val d' = O.ValDec(nonInfo r, O.JokPat(O.infoExp e'), e')
	in
	    d' :: ds'
	end

      | trSpec s' (I.RecSpec(i,ss), ds') =
	trRHSRecSpecs'(s', ss, trLHSRecSpecs'(s', ss, ds'))

      | trSpec s' (I.ExtSpec(i,j), ds') =
	unfinished (#region i) "trSpec" "signature extension"
	    

    and trLHSRecSpecs'(s', ss, ds') = Vector.foldl (trLHSRecSpec s') ds' ss
    and trLHSRecSpec s' (I.TypSpec(i,x,t), ds') =
	(* [type x = t]_s = val $x = Type.unknown(<<kind>>) *)
	let
	    val r  = #region i
	    val x' = trTypid x
	    val e' = typOp(lab_unknown, trKind(r, Type.kind(#typ(I.infoTyp t))))
	    val d' = O.ValDec(nonInfo r, idToPat x', e')
	in
	    d' :: ds'
	end

      | trLHSRecSpec s' (_, ds') =
	raise Crash.Crash "TranslationPhase.trLHSRecSpec: invalid spec"

    and trRHSRecSpecs'(s', ss, ds') = Vector.foldl (trRHSRecSpec s') ds' ss
    and trRHSRecSpec s' (I.TypSpec(i,x,t), ds') =
	(* [type x = t]_s = val p = Inf.newTyp(s, Label.fromString[x])
	 *                  val _ = Type.fill($x, [t]_p)
	 *                  val _ = Inf.extendTyp(s, p, Type.kind $x, SOME $x)
	 *)
	let
	    val r   = #region i
	    val i'  = nonInfo r

 	    val r0  = #region(I.infoId x)
	    val p'  = O.Id(typInfo(r0,typ_path), Stamp.new(), Name.InId)
	    val pp' = idToExp p'
	    val a'  = labOp(lab_fromString,
			    trString(r0, Name.toString(I.name x)))
	    val e0' = pathInfOp(lab_newTyp,
				O.TupExp(typInfo(r0, typ_signlab), #[s',a']))
	    val d0' = O.ValDec(nonInfo r0, idToPat p', e0')

	    val x'  = trTypid x
	    val xx' = idToExp x'
	    val to' = trTypRep'(pp', t)
	    val t'  = case to' of NONE    => trTyp' t
			        | SOME t' => t'
	    val e1' = unitTypOp(lab_fill,
				O.TupExp(typInfo(r,typ_typtyp), #[xx',t']))
	    val d1' = O.ValDec(i', O.JokPat(O.infoId x'), e1')

	    val k'  = kindOp(lab_kind, xx')
	    val o'  = case to'
			of SOME _ => (* generative *)
			   trTag(typInfo(r, typ_typOpt), lab_none)
			 | NONE =>
			   trTagged(typInfo(r,typ_typOpt), lab_some, xx', false)
	    val e2' = unitInfOp(lab_extendTyp,
			O.TupExp(typInfo(r, typ_extendTyp), #[s',pp',k',o']))
	    val d2' = O.ValDec(nonInfo r, O.JokPat(O.infoExp e2'), e2')
	in
	    d2' :: d1' :: d0' :: ds'
	end

      | trRHSRecSpec s' (_, ds') =
	raise Crash.Crash "TranslationPhase.trRHSRecSpec: invalid spec"


  (* Signature instance structures *)

    and trSpecsInst ss = Vector.rev(Vector.fromList(trSpecsInst'(ss,[])))

    and trSpecsInst'(ss, fs') = Vector.foldl trSpecInst fs' ss

    and trSpecInst(I.ValSpec(i,x,t), fs') =
	(*UNFINISHED: get rid of this, but how?*)
	let
	    val i' = nonInfo(#region(I.infoId x))
	    val x' = trValid x
	    val a  = Label.fromName(O.name x')
	in
	    O.Field(i', O.Lab(i',a), O.FailExp(O.infoId x')) :: fs'
	end

      | trSpecInst(I.TypSpec(i,x,t), fs') =
	let
	    val i' = nonInfo(#region(I.infoId x))
	    val x' = trTypid x
	    val a  = Label.fromName(O.name x')
	in
	    O.Field(i', O.Lab(i',a), idToExp x') :: fs'
	end

      | trSpecInst(I.ModSpec(i,x,j), fs') =
	let
	    val i' = nonInfo(#region(I.infoId x))
	    val x' = trModid x
	    val a  = Label.fromName(O.name x')
	in
	    O.Field(i', O.Lab(i',a), idToExp x') :: fs'
	end

      | trSpecInst(I.InfSpec(i,x,j), fs') =
	let
	    val i' = nonInfo(#region(I.infoId x))
	    val x' = trInfid x
	    val a  = Label.fromName(O.name x')
	in
	    O.Field(i', O.Lab(i',a), idToExp x') :: fs'
	end

      | trSpecInst(I.FixSpec(i,l,q), fs') =
	fs'

      | trSpecInst(I.RecSpec(i,ss), fs') =
	trSpecsInst'(ss, fs')

      | trSpecInst(I.ExtSpec(i,j), fs') =
	unfinished (#region i) "trSpecInst" "signature extension"


  (* Imports and annotations *)

    fun idToDec(x' as O.Id(i,_,n), y) =
	let
	    val i' = nonInfo(#region i)
	in
	    O.ValDec(i', idToPat x',
			 O.LazyExp(i, O.SelExp(i, O.Lab(i', Label.fromName n),
						  O.VarExp(O.infoLongid y, y))))
	end

    fun trAnns a_s =
	let
	    val (rxsus',ds') = Vector.foldl trAnn ([],[]) a_s
	    val  xsus'       = Vector.rev(Vector.fromList rxsus')
	    val  ds''        = Vector.rev(Vector.fromList ds')
	in
	    ( xsus', ds'' )
	end

    and trAnn(I.ImpAnn(i,is,u), (xsus',ds')) =
	let
	    val r    = #region i
	    val s    = #sign i
	    val t    = infToTyp(Inf.inSig s)
	    val i'   = typInfo(r,t)
	    val x'   = O.Id(i', Stamp.new(), Name.InId)
	    val ds'' = trImps(is, O.ShortId(i',x'), ds')
	    val _    = Inf.stripSig s
	in
	    ( (x',s,u)::xsus', ds'' )
	end

    and trImps(is, y, ds')		= Vector.foldl (trImp y) ds' is
    and trImp y (I.ValImp(i,x,d),ds')	= idToDec(trValid x, y) :: ds'
      | trImp y (I.TypImp(i,x,d),ds')	= idToDec(trTypid x, y) :: ds'
      | trImp y (I.ModImp(i,x,d),ds')	= idToDec(trModid x, y) :: ds'
					  before updatePervasive x
      | trImp y (I.InfImp(i,x,d),ds')	= idToDec(trInfid x, y) :: ds'
      | trImp y (I.FixImp(i,x,d),ds')	= ds'
      | trImp y (I.RecImp(i,is), ds')	= trImps(is, y, ds')


  (* Components *)

    fun trComp(I.Comp(i,a_s,ds)) =
	let
	    val (xsus',ds1') = trAnns a_s
	    val  ds2'        = trDecs ds
	    val  ds'         = Vector.append(ds1',ds2')
	    val  ids'        = ids ds
	    val  fs'         = Vector.map (idToField (fn x' => x')) ids'
	    val  s           = #sign i
	    val  _           = Inf.stripSig s
	in
	    ( xsus', ds', fs', s )
	end

    fun translate () (desc, component) =
	let
	    val _     = InfHash.deleteAll infHash
	    val comp' = trComp component
	in
	    if not(!Switches.Debug.checkIntermediate) then () else
		CheckIntermediate.check comp';
	    comp'
	end
end
