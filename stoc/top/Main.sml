structure Main :> MAIN =
  struct

    fun failure(Crash.Crash s)        = TextIO.print(s ^ "\n")
      | failure(Error.Error((l,r),s)) =
	TextIO.print(Int.toString l ^ "-" ^ Int.toString r ^ ": " ^ s ^ "\n")
      | failure _ = ()

    fun processString process source =
	process (source ^ ";") handle x => ( failure x; raise x )

    fun processFile process name =
	let
	    val file   = TextIO.openIn name
	    val source = TextIO.inputAll file
	    val _      = TextIO.closeIn file
	in
	    processString process source
	end

    val parse      = ParsingPhase.parse
    val abstract   = AbstractionPhase.translate BindEnv0.E0 o parse
    val translate  = TranslationPhase.translate o abstract
    val simplify   = MatchCompilationPhase.simplify o translate

    fun ozify outstream s =
	let
	    val prog = simplify s
	in
	    OzifySimplifiedGrammar.outputProgram(outstream, prog) ;
	    TextIO.output1(outstream, #"\n")
	end

    fun ozifyToFile name s =
	let
	    val file = TextIO.openOut name
	in
	    ozify file s handle x => ( TextIO.closeOut file ; raise x ) ;
	    TextIO.closeOut file
	end

    val parseString		= processString parse
    val parseFile		= processFile parse

    val abstractString		= processString abstract
    val abstractFile		= processFile abstract

    val translateString		= processString translate
    val translateFile		= processFile translate

    val simplifyString		= processString simplify
    val simplifyFile		= processFile simplify

    fun ozifyString(s,os)	= processString (ozify os) s
    fun ozifyFile(n,os)		= processFile (ozify os) n

    val ozifyStringToStdOut	= processString(ozify TextIO.stdOut)
    val ozifyFileToStdOut	= processFile(ozify TextIO.stdOut)

    fun ozifyStringToFile(s,n)	= processString (ozifyToFile n) s
    fun ozifyFileToFile(n1,n2)	= processFile (ozifyToFile n2) n1

  end
