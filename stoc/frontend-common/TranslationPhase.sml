(* Untyped translation *)

structure TranslationPhase :> TRANSLATION_PHASE =
  struct

    structure I = AbstractGrammar
    structure O = IntermediateGrammar


    (* Create fields for all structures and values in an environment *)

    fun idToField(id' as O.Id(i,_,O.ExId s)) =
	    O.Field(i, O.Lab(i,s), O.VarExp(i, O.ShortId(i, id')))

      | idToField _ = Crash.crash "TranslationPhase.idToField: internal id"


    (* Curry-convert expressions *)

    fun funExp(i,    [],     exp') = exp'
      | funExp(i, id'::ids', exp') = O.FunExp(i, id', funExp(i, ids', exp'))

    fun curryExp(i, (0|1), exp') = exp'
      | curryExp(i,   k,   exp') =
	let
	    val ids'  = List.tabulate(k, fn _ => O.Id(i,Stamp.new(),O.InId))
	    val exps' = List.map (fn id' => O.VarExp(i, O.ShortId(i,id'))) ids'
	in
	    funExp(i, ids', O.AppExp(i, exp', O.TupExp(i, exps')))
	end


    (* Literals *)

    fun trLit(I.WordLit w)		= O.WordLit w
      | trLit(I.IntLit n)		= O.IntLit n
      | trLit(I.CharLit c)		= O.CharLit c
      | trLit(I.StringLit s)		= O.StringLit s
(*      | trLit(I.RealLit x)		= O.RealLit x
UNFINISHED: obsolete after bootstrapping:
*)      | trLit(I.RealLit x)		= O.RealLit(LargeReal.toString x)


    (* Identifiers *)

    fun trLab(I.Lab(i,s))		= O.Lab(i,s)

    fun trId(I.Id(i,z,I.InId))		= O.Id(i, z, O.InId)
      | trId(I.Id(i,z,I.ExId s))	= O.Id(i, z, O.ExId s)

    fun trLongid'(I.ShortId(i,x))	= O.ShortId(i, trId x)
      | trLongid'(I.LongId(i,y,a))	= O.LongId(i, trLongid' y, trLab a)

    fun trLongid(y as I.LongId(i, I.ShortId(_,x), I.Lab(_,a))) =
	if x = Prebound.stamp_Prebound then
	    O.ShortId(i, Prebound.nameToStamp a, O.ExId a)
	else trLongid' y

      | trLongid y = trLongid' y


    (* Extract bound ids from declarations. *)

    fun idsRow    idsZ (I.Row(i,fs,_), xs')  = idsFields idsZ (fs, xs')
    and idsField  idsZ (I.Field(i,a,z), xs') = idsZ(z, xs')
    and idsFields idsZ (fs, xs')	     = List.foldr (idsField idsZ) xs' fs

    fun idsDec(I.ValDec(i,p,e), xs')	= idsPat(p, xs')
      | idsDec(I.ConDec(i,c,t), xs')	= idsCon(c, xs')
      | idsDec(I.TypDec(i,x,t), xs')	= idsTyp(t, xs')
      | idsDec(I.ModDec(i,x,m), xs')	= trId x::xs'
      | idsDec(I.InfDec(i,x,j), xs')	= xs'
      | idsDec(I.RecDec(i,ds), xs')	= idsDecs(ds, xs')
      | idsDec(I.TypvarDec(i,x,ds),xs')	= idsDecs(ds, xs')
      | idsDec(I.LocalDec(i,ds), xs')	= xs'
    and idsDecs(ds, xs')		= List.foldr idsDec xs' ds

    and idsPat(I.JokPat(i), xs')	= xs'
      | idsPat(I.LitPat(i,l), xs')	= xs'
      | idsPat(I.VarPat(i,x), xs')	= trId x::xs'
      | idsPat(I.ConPat(i,y,ps), xs')	= idsPats(ps, xs')
      | idsPat(I.RefPat(i,p), xs')	= idsPat(p, xs')
      | idsPat(I.TupPat(i,ps), xs')	= idsPats(ps, xs')
      | idsPat(I.RowPat(i,r), xs')	= idsRow idsPat (r, xs')
      | idsPat(I.VecPat(i,ps), xs')	= idsPats(ps, xs')
      | idsPat(I.AsPat(i,p1,p2), xs')	= idsPat(p1, idsPat(p2, xs'))
      | idsPat(I.AltPat(i,ps), xs')	= idsPats(ps, xs')
      | idsPat(I.NegPat(i,p), xs')	= idsPat(p, xs')
      | idsPat(I.GuardPat(i,p,e), xs')	= idsPat(p, xs')
      | idsPat(I.AnnPat(i,p,t), xs')	= idsPat(p, xs')
      | idsPat(I.WithPat(i,p,ds), xs')	= idsPat(p, idsDecs(ds, xs'))
    and idsPats(ps, xs')		= List.foldr idsPat xs' ps

    and idsCon(I.Con(i,x,ts), xs')	= trId x::xs'
    and idsCons(cs, xs')		= List.foldr idsCon xs' cs

    and idsTyp(I.AbsTyp(i), xs')	= xs'
      | idsTyp(I.VarTyp(i,x), xs')	= xs'
      | idsTyp(I.ConTyp(i,y), xs')	= xs'
      | idsTyp(I.FunTyp(i,x,t), xs')	= idsTyp(t, xs')
      | idsTyp(I.AppTyp(i,t1,t2), xs')	= idsTyp(t1, idsTyp(t2, xs'))
      | idsTyp(I.RefTyp(i,t), xs')	= idsTyp(t, xs')
      | idsTyp(I.TupTyp(i,ts), xs')	= idsTyps(ts, xs')
      | idsTyp(I.RowTyp(i,r), xs')	= idsRow idsTyp (r, xs')
      | idsTyp(I.ArrTyp(i,t1,t2), xs')	= idsTyp(t1, idsTyp(t2, xs'))
      | idsTyp(I.SumTyp(i,cs), xs')	= idsCons(cs, xs')
      | idsTyp(I.ExtTyp(i), xs')	= xs'
      | idsTyp(I.AllTyp(i,x,t), xs')	= idsTyp(t, xs')
      | idsTyp(I.ExTyp(i,x,t), xs')	= idsTyp(t, xs')
      | idsTyp(I.SingTyp(i,y), xs')	= xs'
    and idsTyps(ts, xs')		= List.foldr idsTyp xs' ts



    (* Expressions *)

    fun trExp(I.LitExp(i,l))		= O.LitExp(i, trLit l)
      | trExp(I.PrimExp(i,s,t))		= O.PrimExp(i, s)
      | trExp(I.VarExp(i,y))		= O.VarExp(i, trLongid y)
      | trExp(I.ConExp(i,k,y))		= let val y' = trLongid y in
					      curryExp(i,k,O.ConExp(i,y',k>0))
					  end
      | trExp(I.RefExp(i))		= O.RefExp(i)
      | trExp(I.TupExp(i,es))		= O.TupExp(i, trExps es)
      | trExp(I.RowExp(i,r))		= O.RowExp(i, trExpRow r)
      | trExp(I.SelExp(i,a))		= O.SelExp(i, trLab a)
      | trExp(I.VecExp(i,es))		= O.VecExp(i, trExps es)
      | trExp(I.FunExp(i,x,e))		= O.FunExp(i, trId x, trExp e)
      | trExp(I.AppExp(i,e1,e2))	= O.AppExp(i, trExp e1, trExp e2)
      | trExp(I.CompExp(i,e1,e2))	= O.AdjExp(i, trExp e2, trExp e2)
      | trExp(I.AndExp(i,e1,e2))	= O.AndExp(i, trExp e1, trExp e2)
      | trExp(I.OrExp(i,e1,e2))		= O.OrExp(i, trExp e1, trExp e2)
      | trExp(I.IfExp(i,e1,e2,e3))	= O.IfExp(i, trExp e1, trExp e2, trExp e3)
      | trExp(I.WhileExp(i,e1,e2))	= O.WhileExp(i, trExp e1, trExp e2)
      | trExp(I.SeqExp(i,es))		= O.SeqExp(i, trExps es)
      | trExp(I.CaseExp(i,e,ms))	= O.CaseExp(i, trExp e, trMatchs ms)
      | trExp(I.RaiseExp(i,e))		= O.RaiseExp(i, trExp e)
      | trExp(I.HandleExp(i,e,ms))	= O.HandleExp(i, trExp e, trMatchs ms)
      | trExp(I.AnnExp(i,e,t))		= trExp e
      | trExp(I.LetExp(i,ds,e))		= O.LetExp(i, trDecs ds, trExp e)

    and trExps es			= List.map trExp es

    and trExpRow(I.Row(i,fs,_))		= trExpFields fs
    and trExpField(I.Field(i,a,e))	= O.Field(i, trLab a, trExp e)
    and trExpFields fs			= List.map trExpField fs


    (* Matches and Patterns *)

    and trMatch(I.Match(i,p,e))		= O.Match(i, trPat p, trExp e)
    and trMatchs ms			= List.map trMatch ms

    and trPat(I.JokPat(i))		= O.WildPat(i)
      | trPat(I.LitPat(i,l))		= O.LitPat(i, trLit l)
      | trPat(I.VarPat(i,x))		= O.VarPat(i, trId x)
      | trPat(I.ConPat(i,y,ps))		= O.ConPat(i, trLongid y, trArgPats ps)
      | trPat(I.RefPat(i,p))		= O.RefPat(i, trPat p)
      | trPat(I.TupPat(i,ps))		= O.TupPat(i, trPats ps)
      | trPat(I.RowPat(i,r))		= let val (fs',b') = trPatRow r in
					      O.RowPat(i, fs', b')
					  end
      | trPat(I.VecPat(i,ps))		= O.VecPat(i, trPats ps)
      | trPat(I.AsPat(i,p1,p2))		= O.AsPat(i, trPat p1, trPat p2)
      | trPat(I.AltPat(i,ps))		= O.AltPat(i, trPats ps)
      | trPat(I.NegPat(i,p))		= O.NegPat(i, trPat p)
      | trPat(I.GuardPat(i,p,e))	= O.GuardPat(i, trPat p, trExp e)
      | trPat(I.AnnPat(i,p,t))		= trPat p
      | trPat(I.WithPat(i,p,ds))	= O.WithPat(i, trPat p, trDecs ds)

    and trPats ps			= List.map trPat ps

    and trArgPats []			= NONE
      | trArgPats[p]			= SOME(trPat p)
      | trArgPats ps			= SOME(O.TupPat(I.infoPat(List.hd ps),
							trPats ps))

    and trPatRow(I.Row(i,fs,b))		= (trPatFields fs, b)
    and trPatField(I.Field(i,a,p))	= O.Field(i, trLab a, trPat p)
    and trPatFields fs			= List.map trPatField fs


    (* Modules *)

    and trMod(I.VarMod(i,x))		= let val x' as O.Id(i',_,_) = trId x in
					      O.VarExp(i, O.ShortId(i', x'))
					  end
      | trMod(I.StrMod(i,ds))		= let val ids' = idsDecs(ds, [])
					      val fs'  = List.map idToField ids'
					      val ds'  = trDecs ds in
					      O.LetExp(i, ds', O.RowExp(i, fs'))
					  end
      | trMod(I.SelMod(i,m,a))		= O.AppExp(i, O.SelExp(i, trLab a),
						      trMod m)
      | trMod(I.FunMod(i,x,j,m))	= O.FunExp(i, trId x, trMod m)
      | trMod(I.AppMod(i,m1,m2))	= O.AppExp(i, trMod m1, trMod m2)
      | trMod(I.AnnMod(i,m,j))		= trMod m
      | trMod(I.LetMod(i,ds,m))		= O.LetExp(i, trDecs ds, trMod m)



    (* Declarations *)

    and trDec(I.ValDec(i,p,e), ds')	= O.ValDec(i, trPat p, trExp e) :: ds'
      | trDec(I.ConDec(i,c,t), ds')	= (case t
					   of I.SingTyp(_,y) => trEqCon(c,y,ds')
					    | _              => trCon(c,ds')
					  )
      | trDec(I.TypDec(i,x,t), ds')	= trTyp(t, ds')
      | trDec(I.ModDec(i,x,m), ds')	= let val x' as O.Id(i',_,_) = trId x in
					      O.ValDec(i, O.VarPat(i',x'),
							  trMod m) :: ds'
					  end
      | trDec(I.InfDec(i,x,j), ds')	= ds'
      | trDec(I.RecDec(i,ds), ds')	= O.RecDec(i, trDecs ds) :: ds'
      | trDec(I.TypvarDec(i,x,ds), ds')	= trDecs'(ds, ds')
      | trDec(I.LocalDec(i,ds), ds')	= trDecs'(ds, ds')

    and trDecs ds			= trDecs'(ds, [])
    and trDecs'(ds, ds')		= List.foldr trDec ds' ds

    and trEqCon(I.Con(i,x,ts), y, ds')	= O.ValDec(i, O.VarPat(i,trId x),
						   O.VarExp(i,trLongid y)):: ds'
    and trCon(I.Con(i,x,ts), ds')	= O.ConDec(i, trId x,
						      List.length ts > 0) :: ds'
    and trCons(cs, ds')			= List.foldr trCon ds' cs

    and trTyp(I.AbsTyp(i), ds')		= ds'
      | trTyp(I.VarTyp(i,x), ds')	= ds'
      | trTyp(I.ConTyp(i,y), ds')	= ds'
      | trTyp(I.FunTyp(i,x,t), ds')	= trTyp(t, ds')
      | trTyp(I.AppTyp(i,t1,t2), ds')	= trTyp(t1, trTyp(t2, ds'))
      | trTyp(I.RefTyp(i,t), ds')	= trTyp(t, ds')
      | trTyp(I.TupTyp(i,ts), ds')	= trTyps(ts, ds')
      | trTyp(I.RowTyp(i,r), ds')	= trTypRow(r, ds')
      | trTyp(I.ArrTyp(i,t1,t2), ds')	= trTyp(t1, trTyp(t2, ds'))
      | trTyp(I.SumTyp(i,cs), ds')	= trCons(cs, ds')
      | trTyp(I.ExtTyp(i), ds')		= ds'
      | trTyp(I.AllTyp(i,x,t), ds')	= trTyp(t, ds')
      | trTyp(I.ExTyp(i,x,t), ds')	= trTyp(t, ds')
      | trTyp(I.SingTyp(i,y), ds')	= ds'

    and trTyps(ts, ds')			= List.foldr trTyp ds' ts

    and trTypRow(I.Row(i,fs,_), ds')	= trTypFields(fs, ds')
    and trTypField(I.Field(i,a,t), ds')	= trTyp(t, ds')
    and trTypFields(fs, ds')		= List.foldr trTypField ds' fs


    (* Programs *)

    fun translate program =
	( trDecs program, idsDecs(program, []) )

  end
