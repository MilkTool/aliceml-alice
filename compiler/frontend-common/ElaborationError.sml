structure ElaborationError :> ELABORATION_ERROR =
  struct

  (* Pretty printer *)

    open PrettyPrint
    open PPMisc

    infixr ^^ ^/^

  (* Types *)

    type lab       = Label.t
    type typ       = Type.t
    type var       = Type.var
    type kind      = Type.kind
    type inf	   = Inf.t
    type fix       = Fixity.t
    type valid     = AbstractGrammar.valid
    type modlongid = AbstractGrammar.modlongid

    type unify_error  = typ * typ * typ * typ
    type inf_mismatch = Inf.mismatch

    datatype error =
	(* Expressions *)
	  VecExpUnify		of unify_error
	| AppExpFunUnify	of unify_error
	| AppExpArgUnify	of unify_error
	| CompExpNoRow		of typ
	| CompExpUnify		of unify_error
	| AndExpUnify		of unify_error
	| OrExpUnify		of unify_error
	| IfExpCondUnify	of unify_error
	| IfExpBranchUnify	of unify_error
	| WhileExpCondUnify	of unify_error
	| RaiseExpUnify		of unify_error
	| HandleExpUnify	of unify_error
	| AnnExpUnify		of unify_error
	| MatchPatUnify		of unify_error
	| MatchExpUnify		of unify_error
	(* Patterns *)
	| VecPatUnify		of unify_error
	| AppPatArrTyp		of typ
	| AppPatFunUnify	of unify_error
	| AppPatUnify		of unify_error
	| AsPatUnify		of unify_error
	| AltPatUnify		of unify_error
	| GuardPatUnify		of unify_error
	| AnnPatUnify		of unify_error
	(* Types *)
	| StarTypKind		of kind
	| AppTypFunKind		of kind
	| AppTypArgKind		of kind * kind
	| RefTypKind		of kind
	| PervasiveTypUnknown	of string
	(* Declarations *)
	| ValDecUnify		of unify_error
	| ValDecLift		of valid * var
	(* Long ids *)
	| ModlongidInf		of modlongid * inf
	(* Modules *)
	| StrModUnclosed	of lab * int * typ
	| SelModInf		of inf
	| AppModFunMismatch	of inf
	| AppModArgMismatch	of inf_mismatch
	| AnnModMismatch	of inf_mismatch
	(* Interfaces *)
	| GroundInfKind		of Inf.kind
	| CompInfMismatch	of inf_mismatch
	| SingInfPath
	| PervasiveInfUnknown	of string
	(* Imports *)
	| ValImpUnbound		of lab
	| ConImpUnbound		of lab
	| TypImpUnbound		of lab
	| ModImpUnbound		of lab
	| InfImpUnbound		of lab
	| FixImpUnbound		of lab
	| ValImpMismatch	of lab * typ * typ
	| ConImpMismatch	of lab * typ * typ
	| TypImpMismatch	of lab * kind * kind
	| ModImpMismatch	of lab * inf_mismatch
	| InfImpMismatch	of lab * inf_mismatch
	| FixImpMismatch	of lab * fix * fix
	(* Components *)
	| CompUnclosed		of lab * int * typ

    datatype warning =
	  NotGeneralized	of valid * typ


  (* Pretty printing *)

    fun ppQuoted s	= "`" ^ s ^ "'"

    fun ppLab'(AbstractGrammar.Lab(_,a)) = Label.toString a

    fun ppId'(AbstractGrammar.Id(_,_,n)) = Name.toString n
    fun ppId x = ppQuoted(ppId' x)

    fun ppLongid'(AbstractGrammar.ShortId(_,x))  = ppId' x
      | ppLongid'(AbstractGrammar.LongId(_,y,a)) = ppLongid' y ^ "." ^ ppLab' a
    fun ppLongid y = ppQuoted(ppLongid' y)

    fun ppLab a = Label.toString a

    val ppPath = PPPath.ppPath
    val ppTyp  = PPType.ppTyp
    val ppInf  = PPInf.ppInf


    fun ppUnify2(d1, d2, (t1,t2,t3,t4)) =
	vbox(
	    d1 ^^ indent(PPType.ppTyp t1) ^^
	    d2 ^^ indent(PPType.ppTyp t2)
	)

    fun ppUnify4(d1, d2, (t1,t2,t3,t4)) =
	let
	    val td1 = PPType.ppTyp t1
	    val td2 = PPType.ppTyp t2
	    val td3 = PPType.ppTyp t3
	    val td4 = PPType.ppTyp t4
	in
	    if td3 = td1 andalso td4 = td2 then
		vbox(
		    d1 ^^ indent td1 ^^
		    d2 ^^ indent td2
		)
	    else
		vbox(
		    d1 ^^ indent td1 ^^
		    d2 ^^ indent td2 ^^
		    textpar["because","type"] ^^ indent td3 ^^
		    textpar["does","not","unify","with"] ^^ indent td4
		)
	end

    fun ppMismatch(d, im) =
        vbox(
	    d ^^
	    ppMismatch' im
	)

    and ppMismatch'(Inf.MissingVal a) =
	    indent(textpar["val",ppLab a]) ^^
	    textpar["is","missing"]
      | ppMismatch'(Inf.MissingTyp  a) =
	    indent(textpar["type",ppLab a]) ^^
	    textpar["is","missing"]
      | ppMismatch'(Inf.MissingMod  a) =
	    indent(textpar["structure",ppLab a]) ^^
	    textpar["is","missing"]
      | ppMismatch'(Inf.MissingInf  a) =
	    indent(textpar["signature",ppLab a]) ^^
	    textpar["is","missing"]
      | ppMismatch'(Inf.MissingFix  a) =
	    textpar["fixity","of",ppQuoted(ppLab a),"is","unspecified"]
      | ppMismatch'(Inf.ManifestVal(a,po,p)) =
	    indent(par([text"val",text(ppLab a)] @
		(case po of NONE => [] | SOME p' => [text"=",ppPath p']))) ^^
	    textpar["does","not","match","manifest","specification"] ^^
	    indent(par[text"val",text(ppLab a),text"=",ppPath p])
      | ppMismatch'(Inf.ManifestTyp(a,to,t)) =
	    indent(
		case to of NONE => textpar["type",ppLab a]
		| SOME t' => par[text"type",text(ppLab a),text"=",ppTyp t']) ^^
	    textpar["does","not","match","manifest","specification"] ^^
	    indent(par[text"type",text(ppLab a),text"=",ppTyp t])
      | ppMismatch'(Inf.ManifestMod(a,po,p)) =
	    indent(par([text"structure",text(ppLab a)] @
		(case po of NONE => [] | SOME p' => [text"=",ppPath p']))) ^^
	    textpar["does","not","match","manifest","specification"] ^^
	    indent(par[text"structure",text(ppLab a),text"=",ppPath p])
      | ppMismatch'(Inf.ManifestInf(a,NONE)) =
	    indent(textpar["signature",ppLab a]) ^^
	    textpar["does","not","match","manifest","specification"]
      | ppMismatch'(Inf.ManifestInf(a,SOME im)) =
	    indent(textpar["signature",ppLab a]) ^^
	    textpar["does","not","match","manifest","specification,",
		"because"] ^^
	    ppMismatch' im
      | ppMismatch'(Inf.MismatchVal(a,t1,t2)) =
	    indent(par([text"val",text(ppLab a),text":",ppTyp t1])) ^^
	    textpar["does","not","match"] ^^
	    indent(par([text"val",text(ppLab a),text":",ppTyp t2]))
      | ppMismatch'(Inf.MismatchTyp(a,k1,k2)) =
	    indent(textpar["type",ppLab a]) ^^
	    textpar["has","incompatible","arity"]
      | ppMismatch'(Inf.MismatchMod(a, Inf.Incompatible(j1,j2))) =
	    indent(par([text"structure",text(ppLab a),text":",ppInf j1])) ^^
	    textpar["does","not","match"] ^^
	    indent(par([text"structure",text(ppLab a),text":",ppInf j2]))
      | ppMismatch'(Inf.MismatchMod(a, im as Inf.IncompatibleArg(p1,p2))) =
	    indent(textpar["structure",ppLab a]) ^^
	    textpar["has","incompatible","signature,",
		"because","signature","argument"] ^^
	    indent(ppPath p1) ^^
	    textpar["does","not","equal"] ^^
	    indent(ppPath p2)
      | ppMismatch'(Inf.MismatchMod(a,im)) =
	    indent(textpar["structure",ppLab a]) ^^
	    textpar["has","incompatible","signature,","because"] ^^
	    ppMismatch' im
      | ppMismatch'(Inf.MismatchInf(a,im)) =
	    indent(textpar["signature",ppLab a]) ^^
	    textpar["is","incompatible"]
      | ppMismatch'(Inf.MismatchFix(a,q1,q2)) =
	    textpar["fixity","of",ppQuoted(ppLab a),"is","different"]
      | ppMismatch'(Inf.MismatchValSort(a,Inf.CONSTRUCTOR _,
					  Inf.CONSTRUCTOR _)) =
	    indent(textpar["constructor",ppLab a]) ^^
	    textpar["has","incompatible","syntactic","arity"]
      | ppMismatch'(Inf.MismatchValSort(a,w1,w2)) =
	    indent(textpar["val",ppLab a]) ^^
	    textpar["is","not","a","constructor"]
      | ppMismatch'(Inf.MismatchTypSort(a,w1,w2)) =
	    indent(textpar["val",ppLab a]) ^^
	    textpar["is","not","an","open","datatype"]
      | ppMismatch'(Inf.MismatchDom im) =
	    break ^^
	    textpar["functor","argument","signature","is","too","restrictive,",
		"because"] ^^
	    ppMismatch' im
      | ppMismatch'(Inf.MismatchRan im) =
	    break ^^
	    textpar["functor","result","signature","is","too","permissive,",
		"because"] ^^
	    ppMismatch' im
      | ppMismatch'(Inf.Incompatible(j1,j2)) =
	    textpar["signature"] ^^
	    indent(ppInf j1) ^^
	    textpar["is","not","compatible","to"] ^^
	    indent(ppInf j2)
      | ppMismatch'(Inf.IncompatibleArg(p1,p2)) =
	    textpar["applied","signature","argument"] ^^
	    textpar["signature"] ^^
	    indent(ppPath p1) ^^
	    textpar["does","not","equal"] ^^
	    indent(ppPath p2)


    fun ppUnclosed(d, (a,n,t)) =
	vbox(
	    d ^^
	    indent(
		fbox(nest(
		    text(Label.toString a) ^/^
		    text ":" ^/^
		    below(PPType.ppTyp t)
		))
	    ) ^^
	    textpar["contains","free","type","variable",
		    "or","unresolved","record","type"]
	)


    fun ppError(VecExpUnify ue) =
	ppUnify2(
	  textpar["inconsistent","types","in","vector","expression:"],
	  textpar["does","not","agree","with","previous","element","type"], ue)
      | ppError(AppExpFunUnify ue) =
	ppUnify2(
	  textpar["applied","value","is","not","a","function:"],
	  textpar["does","not","match","function","type"], ue)
      | ppError(AppExpArgUnify ue) =
	ppUnify4(
	  textpar["argument","type","mismatch:"],
	  textpar["does","not","match","argument","type"], ue)
      | ppError(CompExpNoRow t) =
	vbox(
	    textpar["specialization","type","is","not","a","record:"] ^^
	    nest(break ^^ PPType.ppTyp t)
	)
      | ppError(CompExpUnify ue) =
	ppUnify4(
	  textpar["mismatch","on","record","update:"],
	  textpar["does","not","match","type"], ue)
      | ppError(AndExpUnify ue) =
	ppUnify2(
	  textpar["operand","of","`andalso'","is","not","a","boolean:"],
	  textpar["does","not","match","type"], ue)
      | ppError(OrExpUnify ue) =
	ppUnify2(
	  textpar["operand","of","`orelse'","is","not","a","boolean:"],
	  textpar["does","not","match","type"], ue)
      | ppError(IfExpCondUnify ue) =
	ppUnify2(
	  textpar["operand","of","`if'","is","not","a","boolean:"],
	  textpar["does","not","match","type"], ue)
      | ppError(IfExpBranchUnify ue) =
	ppUnify4(
	  textpar["inconsistent","types","in","branches","of","`if':"],
	  textpar["does","not","agree","with","type"], ue)
      | ppError(WhileExpCondUnify ue) =
	ppUnify2(
	  textpar["operand","of","`while'","is","not","a","boolean:"],
	  textpar["does","not","match","type"], ue)
      | ppError(RaiseExpUnify ue) =
	ppUnify2(
	  textpar["operand","of","`raise'","is","not","an","exception:"],
	  textpar["does","not","match","type"], ue)
      | ppError(HandleExpUnify ue) =
	ppUnify4(
	  textpar["inconsistent","types","in","branches","of","`handle':"],
	  textpar["does","not","agree","with","type"], ue)
      | ppError(AnnExpUnify ue) =
	ppUnify4(
	  textpar["expression","does","not","match","annotation:"],
	  textpar["does","not","match","type"], ue)
      (* Patterns *)
      | ppError(MatchPatUnify ue) =
	ppUnify4(
	  textpar["inconsistent","types","in","`case'","patterns:"],
	  textpar["does","not","agree","with","previous","type"], ue)
      | ppError(MatchExpUnify ue) =
	ppUnify4(
	  textpar["inconsistent","types","in","branches","of","`case':"],
	  textpar["does","not","agree","with","previous","type"], ue)
      | ppError(VecPatUnify ue) =
	ppUnify2(
	  textpar["inconsistent","types","in","vector","pattern:"],
	  textpar["does","not","agree","with","previous","element","type"], ue)
      | ppError(AppPatArrTyp t) =
	  textpar["missing","argument","to","constructor","in","pattern"]
      | ppError(AppPatFunUnify ue) =
	  textpar["surplus","argument","to","constructor","in","pattern"]
      | ppError(AppPatUnify ue) =
	ppUnify4(
	  textpar["ill-typed","constructor","argument:"],
	  textpar["does","not","match","argument","type"], ue)
      | ppError(AsPatUnify ue) =
	ppUnify4(
	  textpar["inconsistent","types","in","`as'","pattern:"],
	  textpar["does","not","agree","with","type"], ue)
      | ppError(AltPatUnify ue) =
	ppUnify4(
	  textpar["inconsistent","types","in","pattern","alternatives:"],
	  textpar["does","not","agree","with","previous","type"], ue)
      | ppError(GuardPatUnify ue) =
	ppUnify2(
	  textpar["pattern","guard","is","not","a","boolean:"],
	  textpar["does","not","match","type"], ue)
      | ppError(AnnPatUnify ue) =
	ppUnify4(
	  textpar["pattern","does","not","match","annotation:"],
	  textpar["does","not","match","type"], ue)
      (* Types *)
      | ppError(StarTypKind k) =
	  textpar["missing","arguments","in","type","expression"]
      | ppError(AppTypFunKind k) =
	  textpar["type","expression","is","not","a","type","function"]
      | ppError(AppTypArgKind(k1,k2)) =
	  textpar["missing","arguments","in","type","expression"]
      | ppError(RefTypKind k) =
	  textpar["missing","arguments","in","type","expression"]
      | ppError(PervasiveTypUnknown s) =
	  textpar["unknown","pervasive","type","name","\""^s^"\""]
      (* Declarations *)
      | ppError(ValDecUnify ue) =
	ppUnify4(
	  textpar["expression","does","not","match","pattern","type:"],
	  textpar["does","not","match","type"], ue)
      | ppError(ValDecLift(x,a)) =
	  textpar["could not generalize","type","of",ppId x,
	      "due","to","value","restriction",
	      "although","it","contains","explicit","type","variables"]
      (* Modules *)
      | ppError(ModlongidInf(y,j)) =
	  textpar["module",ppLongid y,"is","not","a","structure"]
      | ppError(StrModUnclosed lnt) =
	ppUnclosed(
	  textpar["structure","is","not","closed:"], lnt)
      | ppError(SelModInf j) =
	  textpar["module","expression","is","not","a","structure"]
      | ppError(AppModFunMismatch j) =
	  textpar["applied","module","is","not","a","functor"]
	  (* UNFINISHED: print actual signature j *)
      | ppError(AppModArgMismatch im) =
	ppMismatch(
	  textpar["module","expression","does","not","match",
	      "functor","parameter","signature:"], im)
      | ppError(AnnModMismatch im) =
	ppMismatch(
	  textpar["module","expression","does","not","match","signature:"], im)
      (* Interfaces *)
      | ppError(GroundInfKind k) =
	  textpar["missing","arguments","in","signature","expression"]
      | ppError(CompInfMismatch im) =
	ppMismatch(
	  textpar["inconsistency","at","signature","specialization:"], im)
      | ppError(SingInfPath) =
	  textpar["module","expression","is","not","a","path"]
      | ppError(PervasiveInfUnknown s) =
	  textpar["unknown","pervasive","signature","name","\""^s^"\""]
      (* Imports *)
      | ppError(ValImpUnbound a) =
	  textpar["value",ppLab a,"is","not","exported","by","component"]
      | ppError(ConImpUnbound a) =
	  textpar["constructor",ppLab a,"is","not","exported","by","component"]
      | ppError(TypImpUnbound a) =
	  textpar["type",ppLab a,"is","not","exported","by","component"]
      | ppError(ModImpUnbound a) =
	  textpar["structure","or","functor",ppLab a,"is","not","exported",
		  "by","component"]
      | ppError(InfImpUnbound a) =
	  textpar["signature",ppLab a,"is","not","exported","by","component"]
      | ppError(FixImpUnbound a) =
	  textpar["fixity","status","for",ppLab a,"is","not","exported",
		  "by","component"]
      | ppError(ValImpMismatch(a,t1,t2)) =
	vbox(
	    textpar["type","annotation","of","value",ppLab a] ^^
	    nest(break ^^ below(PPType.ppTyp t1)) ^/^
	    textpar["does","not","match","component","export","type"] ^^
	    nest(break ^^ below(PPType.ppTyp t2))
	)
      | ppError(ConImpMismatch(a,t1,t2)) =
	vbox(
	    textpar["type","of","constructor",ppLab a] ^^
	    nest(break ^^ below(PPType.ppTyp t1)) ^/^
	    textpar["does","not","match","component","export","type"] ^^
	    nest(break ^^ below(PPType.ppTyp t2))
	)
      | ppError(TypImpMismatch(a,k1,k2)) =
	  textpar["type",ppLab a,"exported","by","component",
		  "has","incompatible","arity"]
      | ppError(ModImpMismatch(a,im)) =
	ppMismatch(
	  textpar["module",ppLab a,"exported","by","component","does","not",
		  "match","signature,","because"], im)
      | ppError(InfImpMismatch(a,im)) =
	ppMismatch(
	  textpar["signature",ppLab a,"exported","by","component","is",
		  "incompatible,","because"], im)
      | ppError(FixImpMismatch(a,f1,f2)) =
	  textpar["fixity","status","for",ppLab a,"does","not","match",
		  "export"]
      (* Components *)
      | ppError(CompUnclosed ant) =
	ppUnclosed(
	  textpar["component","is","not","closed:"], ant)

    fun ppWarning(NotGeneralized(x,t)) =
	vbox(
	    textpar["type","of",ppId x,"cannot","be","generalized","due","to",
		"value","restriction:"] ^^
	    nest(break ^^ PPType.ppTyp t)
	)

  (* Export *)

    fun errorToString e   = PrettyPrint.toString(ppError e, 75)
    fun warningToString w = PrettyPrint.toString(ppWarning w, 75)

    fun error(region, e)  = Error.error(region, errorToString e)
    fun warn(region, w)   = Error.warn(region, warningToString w)

  end
