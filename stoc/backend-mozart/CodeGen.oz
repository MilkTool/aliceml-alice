%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1999-2000
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

functor
import
   CompilerSupport(isBuiltin) at 'x-oz://boot/CompilerSupport'
   Word(make toInt) at 'x-oz://boot/Word'
   System(printName)
   Narrator('class')
   ErrorListener('class')
   CodeStore('class')
   Prebound(builtinTable: BuiltinTable
	    raiseAliceException: RaiseAliceException
	    unwrapAliceException: UnwrapAliceException)
   Assembler(assemble)
export
   Translate
define
   fun {TestBuiltin Builtinname Regs ThenVInstr ElseVInstr State}
      Reg VHd VInter
   in
      {State.cs newReg(?Reg)}
      VHd = vCallBuiltin(_ Builtinname {Append Regs [Reg]} unit VInter)
      VInter = vTestBool(_ Reg ThenVInstr ElseVInstr nil unit nil)
      VHd
   end

   proc {MakeReg IdDef State ?Reg}
      case IdDef of idDef(id(_ Stamp _)) then
	 case {Dictionary.condGet State.regDict Stamp unit} of unit then
	    {State.cs newReg(?Reg)}
	    {Dictionary.put State.regDict Stamp Reg}
	 elseof Reg0 then
	    %% This test is needed because of shared statements:
	    %% The same variable may be declared on two different paths.
	    Reg = Reg0
	 end
      [] wildcard then
	 {State.cs newReg(?Reg)}
      end
   end

   fun {GetReg id(_ Stamp _) State}
      {Dictionary.get State.regDict Stamp}
   end

   fun {GetStaticCon Stamp State} Dict in
      Dict = State.shareDict
      if {Dictionary.member Dict Stamp} then
	 {Dictionary.get Dict Stamp}
      else N = {NewName} in
	 {Dictionary.put Dict Stamp N}
	 N
      end
   end

   fun {TranslateRegion (I#J)#(_#_) State}
      pos(State.filename I J)
   end

   proc {NoElse Region ElseVInstr nil State} Coord in
      Coord = {TranslateRegion Region State}
      case Coord of pos(Filename I J) then ExnReg VInter in
	 {State.cs newReg(?ExnReg)}
	 ElseVInstr = vEquateRecord(_ kernel 4 ExnReg
				    [constant(noElse) constant(Filename)
				     constant(I) constant(J)] VInter)
	 VInter = vCallBuiltin(_ 'Exception.raiseError' [ExnReg] Coord nil)
      end
   end

   proc {TranslateStm Stm VHd VTl State ReturnReg}
      case Stm of valDec(_ IdDef Exp) then
	 {TranslateExp Exp {MakeReg IdDef State} VHd VTl State}
      [] refAppDec(Region IdDef Id) then
	 VHd = vCallBuiltin(_ 'Cell.access'
			    [{GetReg Id State} {MakeReg IdDef State}]
			    {TranslateRegion Region State} VTl)
      [] tupDec(Region '#[]' Id) then
	 VHd = vMatch(_ {GetReg Id State} {NoElse Region $ nil State}
		      [onScalar(unit VTl)]
		      {TranslateRegion Region State} nil)
      [] tupDec(Region IdDefs Id) then ThenVInstr in
	 {Record.foldL IdDefs
	  proc {$ VHd IdDef VTl}
	     VHd = vGetVariable(_ {MakeReg IdDef State} VTl)
	  end ThenVInstr VTl}
	 VHd = vMatch(_ {GetReg Id State} {NoElse Region $ nil State}
		      [onRecord('#' {Width IdDefs} ThenVInstr)]
		      {TranslateRegion Region State} nil)
      [] prodDec(Region LabelIdDefVec Id) then Arity ThenVInstr in
	 Arity = {Record.foldR LabelIdDefVec
		  fun {$ Label#_ In} Label|In end nil}
	 {Record.foldL LabelIdDefVec
	  proc {$ VHd _#IdDef VTl}
	     VHd = vGetVariable(_ {MakeReg IdDef State} VTl)
	  end ThenVInstr VTl}
	 VHd = vMatch(_ {GetReg Id State} {NoElse Region $ nil State}
		      [onRecord('#' Arity ThenVInstr)]
		      {TranslateRegion Region State} nil)
      [] tryStm(Region TryBody IdDef HandleBody) then
	 Reg1 Reg2 Coord TryVInstr HandleVInstr HandleVInter
      in
	 {State.cs newReg(?Reg1)}
	 Reg2 = {MakeReg IdDef State}
	 Coord = {TranslateRegion Region State}
	 VHd = vExHandler(_ TryVInstr Reg1 HandleVInstr Coord nil _)
	 {TranslateBody TryBody ?TryVInstr nil State ReturnReg}
	 HandleVInstr = vCallConstant(_ UnwrapAliceException
				      [Reg1 Reg2] Coord HandleVInter)
	 {TranslateBody HandleBody ?HandleVInter nil State ReturnReg}
      [] endTryStm(Region Body) then VInter in
	 VHd = vPopEx(_ {TranslateRegion Region State} VInter)
	 {TranslateBody Body VInter VTl State ReturnReg}
      [] endHandleStm(_ Body) then
	 {TranslateBody Body VHd VTl State ReturnReg}
      [] testStm(Region Id litTests(LitBodyVec='#[]'(wordLit(_)#_ ...))
		 ElseBody)
      then IntReg Coord Matches VInter ElseVInstr in
	 {State.cs newReg(?IntReg)}
	 Coord = {TranslateRegion Region State}
	 VHd = vCallBuiltin(_ 'Word.toInt' [{GetReg Id State} IntReg]
			    Coord VInter)
	 Matches = {Record.foldR LitBodyVec
		    fun {$ wordLit(W)#Body In} ThenVInstr in
		       {TranslateBody Body ?ThenVInstr nil State ReturnReg}
		       onScalar({Word.toInt {Word.make 31 W}} ThenVInstr)|In
		    end nil}
	 VInter = vMatch(_ IntReg ElseVInstr Matches Coord VTl=nil)
	 {TranslateBody ElseBody ?ElseVInstr nil State ReturnReg}
      [] testStm(Region Id litTests(LitBodyVec='#[]'(intLit(_)#_ ...))
		 ElseBody)
      then Matches ElseVInstr in
	 Matches = {Record.foldR LitBodyVec
		    fun {$ intLit(I)#Body In} ThenVInstr in
		       {TranslateBody Body ?ThenVInstr nil State ReturnReg}
		       onScalar(I ThenVInstr)|In
		    end nil}
	 VHd = vMatch(_ {GetReg Id State} ElseVInstr Matches
		      {TranslateRegion Region State} VTl=nil)
	 {TranslateBody ElseBody ?ElseVInstr nil State ReturnReg}
      [] testStm(Region Id litTests(LitBodyVec='#[]'(charLit(_)#_ ...))
		 ElseBody)
      then Matches ElseVInstr in
	 Matches = {Record.foldR LitBodyVec
		    fun {$ charLit(C)#Body In} ThenVInstr in
		       {TranslateBody Body ?ThenVInstr nil State ReturnReg}
		       onScalar(C ThenVInstr)|In
		    end nil}
	 VHd = vMatch(_ {GetReg Id State} ElseVInstr Matches
		      {TranslateRegion Region State} VTl=nil)
	 {TranslateBody ElseBody ?ElseVInstr nil State ReturnReg}
      [] testStm(_ Id litTests(LitBodyVec='#[]'(stringLit(_)#_ ...)) ElseBody)
      then ElseVInstr in
	 {Record.foldL LitBodyVec
	  proc {$ VHd stringLit(S)#Body ElseVInstr} TmpReg VInter ThenVInstr in
	     {State.cs newReg(?TmpReg)}
	     VHd = vEquateConstant(_ {ByteString.make S} TmpReg VInter)
	     VInter = {TestBuiltin 'Value.\'==\'' [{GetReg Id State} TmpReg]
		       ThenVInstr ElseVInstr State}
	     {TranslateBody Body ?ThenVInstr nil State ReturnReg}
	  end VHd ElseVInstr}
	 {TranslateBody ElseBody ElseVInstr VTl=nil State ReturnReg}
      [] testStm(Region Id litTests(LitBodyVec='#[]'(realLit(_)#_ ...))
		 ElseBody)
      then Matches ElseVInstr in
	 Matches = {Record.foldR LitBodyVec
		    fun {$ realLit(F)#Body In} ThenVInstr in
		       {TranslateBody Body ?ThenVInstr nil State ReturnReg}
		       onScalar(F ThenVInstr)|In
		    end nil}
	 VHd = vMatch(_ {GetReg Id State} ElseVInstr Matches
		      {TranslateRegion Region State} VTl=nil)
	 {TranslateBody ElseBody ?ElseVInstr nil State ReturnReg}
      [] testStm(Region Id tagTests(TagBodyVec) ElseBody) then
	 Matches ElseVInstr
      in
	 Matches = {Record.foldR TagBodyVec
		    fun {$ Label#_#ConArgs#Body In} Match ThenVInstr in
		       Match =
		       case ConArgs of none then
			  onScalar(Label ThenVInstr)
		       [] some(oneArg(IdDef)) then ThenVInstr0 in
			  ThenVInstr0 = vGetVariable(_ {MakeReg IdDef State}
						     ThenVInstr)
			  onRecord(Label 1 ThenVInstr0)
		       [] some(tupArgs('#[]')) then
			  onScalar(Label ThenVInstr)
		       [] some(tupArgs(IdDefs)) then ThenVInstr0 in
			  {Record.foldL IdDefs
			   proc {$ VHd IdDef VTl}
			      VHd = vGetVariable(_ {MakeReg IdDef State} VTl)
			   end ThenVInstr0 ThenVInstr}
			  onRecord(Label {Width IdDefs} ThenVInstr0)
		       [] some(prodArgs(LabelIdDefVec)) then ThenVInstr0 in
			  {Record.foldL LabelIdDefVec
			   proc {$ VHd _#IdDef VTl}
			      VHd = vGetVariable(_ {MakeReg IdDef State} VTl)
			   end ThenVInstr0 ThenVInstr}
			  onRecord(Label {Record.foldR LabelIdDefVec
					  fun {$ Label#_ In} Label|In end nil}
				   ThenVInstr0)
		       end
		       {TranslateBody Body ?ThenVInstr nil State ReturnReg}
		       Match|In
		    end nil}
	 VHd = vMatch(_ {GetReg Id State} ElseVInstr Matches
		      {TranslateRegion Region State} VTl=nil)
	 {TranslateBody ElseBody ?ElseVInstr nil State ReturnReg}
      [] testStm(Region Id conTests(ConBodyVec) ElseBody) then ElseVInstr in
	 {Record.foldL ConBodyVec
	  proc {$ VHd Con#ConArgs#Body ElseVInstr} Reg ThenVInstr in
	     Reg = {GetReg Id State}
	     case Con#ConArgs of con(Id)#none then
		VHd = {TestBuiltin 'Value.\'==\'' [Reg {GetReg Id State}]
		       ThenVInstr ElseVInstr State}
	     [] con(Id)#some(tupArgs('#[]')) then
		VHd = {TestBuiltin 'Value.\'==\'' [Reg {GetReg Id State}]
		       ThenVInstr ElseVInstr State}
	     [] con(Id)#some(Args) then ThenVInstr0 Coord in
		VHd = {TestBuiltin 'Record.testLabel' [Reg {GetReg Id State}]
		       ThenVInstr0 ElseVInstr State}
		Coord = {TranslateRegion Region State}
		case Args of oneArg(IdDef) then
		   ThenVInstr0 = vInlineDot(_ Reg 1 {MakeReg IdDef State} true
					    Coord ThenVInstr)
		[] tupArgs(IdDefs) then
		   {Record.foldLInd IdDefs
		    proc {$ I VHd IdDef VTl}
		       VHd = vInlineDot(_ Reg I {MakeReg IdDef State} true
					Coord VTl)
		    end ThenVInstr0 ThenVInstr}
		[] prodArgs(LabelIdDefVec) then
		   {Record.foldL LabelIdDefVec
		    proc {$ VHd Label#IdDef VTl}
		       VHd = vInlineDot(_ Reg Label {MakeReg IdDef State} true
					Coord VTl)
		    end ThenVInstr0 ThenVInstr}
		end
/*--**
	     [] staticCon(Stamp)#none then
		{TranslateMatch tagTest({GetStaticCon Stamp State} unit)
		 Reg ThenVInstr State}
	     [] staticCon(Stamp)#some(tupArgs('#[]')) then
		{TranslateMatch tagTest({GetStaticCon Stamp State} unit)
		 Reg ThenVInstr State}
	     [] staticCon(Stamp)#some(Args) then
		{TranslateMatch
		 tagAppTest({GetStaticCon Stamp State} unit Args)
		 Reg ThenVInstr State}
*/
	     end
	     {TranslateBody Body ?ThenVInstr nil State ReturnReg}
	  end VHd ElseVInstr}
	 {TranslateBody ElseBody ElseVInstr VTl=nil State ReturnReg}
      [] testStm(Region Id vecTests(VecBodyVec) ElseBody) then
	 Matches ElseVInstr
      in
	 Matches = {Record.foldR VecBodyVec
		    fun {$ IdDefs#Body In} ThenVInstr0 ThenVInstr in
		       {Record.foldL IdDefs
			proc {$ VHd IdDef VTl}
			   VHd = vGetVariable(_ {MakeReg IdDef State} VTl)
			end ThenVInstr0 ThenVInstr}
		       {TranslateBody Body ?ThenVInstr nil State ReturnReg}
		       onRecord('#[]' {Width IdDefs} ThenVInstr0)|In
		    end nil}
	 VHd = vMatch(_ {GetReg Id State} ElseVInstr Matches
		      {TranslateRegion Region State} VTl=nil)
	 {TranslateBody ElseBody ?ElseVInstr nil State ReturnReg}
      [] raiseStm(Region Id) then
	 VHd = vCallConstant(_ RaiseAliceException [{GetReg Id State}]
			     {TranslateRegion Region State} VTl=nil)
      [] reraiseStm(Region Id) then
	 VHd = vCallConstant(_ RaiseAliceException [{GetReg Id State}]
			     {TranslateRegion Region State} VTl=nil)
      [] sharedStm(_ Body Stamp) then
	 if {Dictionary.member State.shareDict Stamp} then
	    VHd = {Dictionary.get State.shareDict Stamp}
	 else
	    {Dictionary.put State.shareDict Stamp VHd}
	    case {TranslateBody Body $ nil State ReturnReg} of nil then
	       VHd = nil
	    elseof VBody then
	       VHd = vShared(_ _ {State.cs newLabel($)} VBody)
	    end
	 end
	 VTl = nil
      [] returnStm(_ Exp) then {TranslateExp Exp ReturnReg VHd VTl=nil State}
      [] exportStm(_ Exp) then {TranslateExp Exp ReturnReg VHd VTl=nil State}
      end
   end

   proc {TranslateExp Exp Reg VHd VTl State}
      case Exp of litExp(_ Lit) then Constant in
	 Constant = case Lit of wordLit(W) then {Word.make 31 W}
		    [] intLit(I) then I
		    [] charLit(C) then C
		    [] stringLit(S) then {ByteString.make S}
		    [] realLit(F) then F
		    end
	 VHd = vEquateConstant(_ Constant Reg VTl)
      [] primExp(_ Builtinname) then
	 VHd = vEquateConstant(_ BuiltinTable.Builtinname Reg VTl)
      [] newExp(Region) then
	 VHd = vCallBuiltin(_ 'Name.new' [Reg]
			    {TranslateRegion Region State} VTl)
      [] varExp(_ Id) then
	 VHd = vUnify(_ Reg {GetReg Id State} VTl)
      [] tagExp(_ Label _) then
	 VHd = vEquateConstant(_ Label Reg VTl)
      [] conExp(_ con(Id)) then
	 VHd = vUnify(_ Reg {GetReg Id State} VTl)
      [] conExp(Region staticCon(Stamp)) then
	 {TranslateExp
	  tagExp(Region {GetStaticCon Stamp State} unit)
	  Reg VHd VTl State}
      [] tupExp(_ '#[]') then
	 VHd = vEquateConstant(_ unit Reg VTl)
      [] tupExp(_ Ids) then
	 VHd = vEquateRecord(_ '#' {Width Ids} Reg
			     {Record.foldR Ids
			      fun {$ Id In} value({GetReg Id State})|In end
			      nil} VTl)
      [] prodExp(_ LabelIdVec) then Rec in
	 Rec = {List.toRecord '#'
		{Record.foldR LabelIdVec
		 fun {$ Label#Id In} Label#value({GetReg Id State})|In end
		 nil}}
	 VHd = vEquateRecord(_ '#' {Arity Rec} Reg {Record.toList Rec} VTl)
      [] vecExp(_ '#[]') then
	 VHd = vEquateConstant(_ '#[]' Reg VTl)
      [] vecExp(_ Ids) then
	 VHd = vEquateRecord(_ '#[]' {Width Ids} Reg
			     {Record.foldR Ids
			      fun {$ Id In} value({GetReg Id State})|In end
			      nil} VTl)
      [] funExp(Region _ _ tupArgs(IdDefs) Body) then
	 PredId NLiveRegs ResReg FormalRegs BodyVInstr GRegs Code
      in
	 PredId = pid({VirtualString.toAtom
		       State.filename#':'#Region.1.1#'.'#Region.1.2#'/'#
		       {Width IdDefs}#'-ary'}
		      {Width IdDefs} + 1 {TranslateRegion Region State}
		      nil NLiveRegs)
	 {State.cs startDefinition()}
	 {State.cs newReg(?ResReg)}
	 FormalRegs = {Record.foldR IdDefs
		       fun {$ IdDef Rest} {MakeReg IdDef State}|Rest end
		       [ResReg]}
	 {TranslateBody Body ?BodyVInstr nil State ResReg}
	 {State.cs
	  endDefinition(BodyVInstr FormalRegs nil ?GRegs ?Code ?NLiveRegs)}
	 VHd = vDefinition(_ Reg PredId unit GRegs Code VTl)
      [] funExp(Region _ _ Args Body) then
	 PredId NLiveRegs ResReg FormalRegs ArgReg
	 BodyVInstr ThenVInstr ElseVInstr MatchReg ElseVInter GRegs Code
      in
	 PredId = pid({VirtualString.toAtom
		       State.filename#':'#Region.1.1#'.'#Region.1.2}
		      2 {TranslateRegion Region State} nil NLiveRegs)
	 {State.cs startDefinition()}
	 {State.cs newReg(?ResReg)}
	 FormalRegs = [ArgReg ResReg]
	 case Args of oneArg(IdDef) then
	    ArgReg = {MakeReg IdDef State}
	    BodyVInstr = ThenVInstr
	 [] tupArgs('#[]') then
	    {State.cs newReg(?ArgReg)}
	    BodyVInstr = vTestConstant(_ ArgReg unit
				       ThenVInstr ElseVInstr
				       {TranslateRegion Region State} nil)
	 [] prodArgs(LabelIdDefVec) then Arity ThenVInstr0 in
	    {State.cs newReg(?ArgReg)}
	    Arity = {Record.foldR LabelIdDefVec
		     fun {$ Label#_ In} Label|In end nil}
	    BodyVInstr = vMatch(_ ArgReg ElseVInstr
				[onRecord('#' Arity ThenVInstr0)]
				{TranslateRegion Region State} nil)
	    {Record.foldL LabelIdDefVec
	     proc {$ VHd _#IdDef VTl}
		VHd = vGetVariable(_ {MakeReg IdDef State} VTl)
	     end ThenVInstr0 ThenVInstr}
	 end
	 {TranslateBody Body ?ThenVInstr nil State ResReg}
	 {State.cs newReg(?MatchReg)}
	 ElseVInstr = vEquateConstant(_ BuiltinTable.'General.Match'
				      MatchReg ElseVInter)
	 ElseVInter = vCallBuiltin(_ 'Exception.raiseError' [MatchReg]
				   {TranslateRegion Region State} nil)
	 {State.cs
	  endDefinition(BodyVInstr FormalRegs nil ?GRegs ?Code ?NLiveRegs)}
	 VHd = vDefinition(_ Reg PredId unit GRegs Code VTl)
      [] primAppExp(Region Builtinname '#[]') then ArgReg VInter Value in
	 {State.cs newReg(?ArgReg)}
	 VHd = vEquateConstant(_ unit ArgReg VInter)
	 Value = BuiltinTable.Builtinname
	 if {CompilerSupport.isBuiltin Value} then
	    VInter = vCallBuiltin(_ {System.printName Value} [ArgReg Reg]
				  {TranslateRegion Region State} VTl)
	 else
	    VInter = vCallConstant(_ Value [ArgReg Reg]
				   {TranslateRegion Region State} VTl)
	 end
      [] primAppExp(Region Builtinname Ids) then Value Regs in
	 Value = BuiltinTable.Builtinname
	 Regs = {Record.foldR Ids
		 fun {$ Id Regs} {GetReg Id State}|Regs end [Reg]}
	 if {CompilerSupport.isBuiltin Value} then
	    VHd = vCallBuiltin(_ {System.printName Value} Regs
			       {TranslateRegion Region State} VTl)
	 else
	    VHd = vCallConstant(_ Value Regs
				{TranslateRegion Region State} VTl)
	 end
      [] varAppExp(Region Id tupArgs(Ids)) then
	 VHd = vConsCall(_ {GetReg Id State}
			 {Record.foldR Ids
			  fun {$ Id Rest} {GetReg Id State}|Rest end [Reg]}
			 {TranslateRegion Region State} VTl)
      [] varAppExp(Region Id Args) then ArgReg VInter in
	 case Args of oneArg(Id) then
	    VHd = VInter
	    ArgReg = {GetReg Id State}
	 [] tupArgs('#[]') then
	    {State.cs newReg(?ArgReg)}
	    VHd = vEquateConstant(_ unit ArgReg VInter)
	 [] tupArgs(Ids) then
	    {State.cs newReg(?ArgReg)}
	    VHd = vEquateRecord(_ '#' {Width Ids} ArgReg
				{Record.foldR Ids
				 fun {$ Id In} value({GetReg Id State})|In end
				 nil} VInter)
	 [] prodArgs(LabelIdVec) then
	    {State.cs newReg(?ArgReg)}
	    VHd = vEquateRecord(_ '#'
				{Record.foldR LabelIdVec
				 fun {$ Label#_ In} Label|In end nil}
				ArgReg
				{Record.foldR LabelIdVec
				 fun {$ _#Id In}
				    value({GetReg Id State})|In
				 end nil}
				VInter)
	 end
	 VInter = vDeconsCall(_ {GetReg Id State} ArgReg Reg
			      {TranslateRegion Region State} VTl)
      [] tagAppExp(_ Label _ oneArg(Id)) then
	 VHd = vEquateRecord(_ Label 1 Reg [value({GetReg Id State})] VTl)
      [] tagAppExp(_ Label _ tupArgs('#[]')) then
	 VHd = vEquateConstant(_ Label Reg VTl)
      [] tagAppExp(_ Label _ tupArgs(Ids)) then
	 VHd = vEquateRecord(_ Label {Width Ids} Reg
			     {Record.foldR Ids
			      fun {$ Id In} value({GetReg Id State})|In end
			      nil} VTl)
      [] tagAppExp(_ Label _ prodArgs(LabelIdVec)) then
	 VHd = vEquateRecord(_ Label
			     {Record.foldR LabelIdVec
			      fun {$ Label#_ In} Label|In end nil} Reg
			     {Record.foldR LabelIdVec
			      fun {$ _#Id In}
				 value({GetReg Id State})|In
			      end nil}
			     VTl)
      [] conAppExp(Region con(Id1) oneArg(Id2)) then
	 Coord WidthReg VInter1 VInter2
      in
	 Coord = {TranslateRegion Region State}
	 {State.cs newReg(?WidthReg)}
	 VHd = vEquateConstant(_ 1 WidthReg VInter1)
	 VInter1 = vCallBuiltin(_ 'Tuple.make'
				[{GetReg Id1 State} WidthReg Reg]
				Coord VInter2)
	 VInter2 = vInlineDot(_ Reg 1 {GetReg Id2 State} true Coord VTl)
      [] conAppExp(_ con(Id) tupArgs('#[]')) then
	 VHd = vUnify(_ Reg {GetReg Id State} VTl)
      [] conAppExp(Region con(Id) tupArgs(Ids)) then
	 Coord WidthReg VInter1 VInter2
      in
	 Coord = {TranslateRegion Region State}
	 {State.cs newReg(?WidthReg)}
	 VHd = vEquateConstant(_ {Width Ids} WidthReg VInter1)
	 VInter1 = vCallBuiltin(_ 'Tuple.make'
				[{GetReg Id State} WidthReg Reg] Coord VInter2)
	 {Record.foldLInd Ids
	  proc {$ I VHd Id VTl}
	     VHd = vInlineDot(_ Reg I {GetReg Id State} true Coord VTl)
	  end VInter2 VTl}
      [] conAppExp(Region con(Id) prodArgs(LabelIdVec)) then
	 Coord ArityReg VInter1 VInter2
      in
	 Coord = {TranslateRegion Region State}
	 {State.cs newReg(?ArityReg)}
	 VHd = vEquateConstant(_ {Record.foldR LabelIdVec
				  fun {$ Label#_ In} Label|In end nil}
			       ArityReg VInter1)
	 VInter1 = vCallBuiltin(_ 'Record.make'
				[{GetReg Id State} ArityReg Reg] Coord VInter2)
	 {Record.foldL LabelIdVec
	  proc {$ VHd Label#Id VTl}
	     VHd = vInlineDot(_ Reg Label {GetReg Id State} true Coord VTl)
	  end VInter2 VTl}
      [] conAppExp(Region staticCon(Stamp) Arity) then
	 {TranslateExp
	  tagAppExp(Region {GetStaticCon Stamp State} unit Arity)
	  Reg VHd VTl State}
      [] refAppExp(Region Id) then
	 VHd = vCallBuiltin(_ 'Cell.new' [{GetReg Id State} Reg]
			    {TranslateRegion Region State} VTl)
      [] selAppExp(Region _ Label _ Id) then
	 VHd = vInlineDot(_ {GetReg Id State} Label Reg false
			  {TranslateRegion Region State} VTl)
      [] funAppExp(Region Id _ Args) then
	 {TranslateExp varAppExp(Region Id Args) Reg VHd VTl State}
      end
   end

   proc {TranslateBody Stms VHd VTl State ReturnReg}
      {FoldL Stms
       proc {$ VHd Stm VTl}
	  {TranslateStm Stm VHd VTl State ReturnReg}
       end VHd VTl}
   end

   fun {Translate Filename Import#(Body#Sign)}
      NarratorObject Reporter CS ImportReg ExportReg
      State VInstr VInter Code NLiveRegs
   in
      NarratorObject = {New Narrator.'class' init(?Reporter)}
      _ = {New ErrorListener.'class' init(NarratorObject)}
      CS = {New CodeStore.'class'
	    init(proc {$ getSwitch(_ $)} false end Reporter)}
      {CS startDefinition()}
      {CS newReg(?ImportReg)}
      {CS newReg(?ExportReg)}
      State = state(regDict: {NewDictionary} shareDict: {NewDictionary} cs: CS
		    filename: {VirtualString.toAtom Filename})
      {Record.foldLInd Import
       proc {$ I VHd IdDef#_#_ VTl}
	  VHd = vInlineDot(_ ImportReg I {MakeReg IdDef State} false unit VTl)
       end VInstr VInter}
      {TranslateBody Body ?VInter nil State ExportReg}
      {CS endDefinition(VInstr [ImportReg ExportReg] nil
			nil ?Code ?NLiveRegs)}
      case Code of Code1#Code2 then StartLabel EndLabel Res P VS in
	 StartLabel = {NewName}
	 EndLabel = {NewName}
	 {Assembler.assemble
	  (lbl(StartLabel)|
	   definition(x(0) EndLabel
		      pid({VirtualString.toAtom 'Component '#Filename} 2
			  pos({VirtualString.toAtom Filename} 1 0) nil
			  NLiveRegs)
		      unit nil Code1)|
	   endDefinition(StartLabel)|
	   {Append Code2 [lbl(EndLabel) unify(x(0) g(0)) return]}) [Res]
	  switches ?P ?VS}
	 {P}
	 {Functor.new
	  {List.toRecord 'import'
	   {Record.foldRInd Import
	    fun {$ I _#Sign#URL In}
	       I#info('from': URL 'type': sig(Sign))|In
	    end nil}}
	  sig(Sign) Res}#VS#Sign
      end
   end
end
