structure Hose :> HOSE =
    struct

	val inFile = ref ""
	val outFile = ref ""


	fun printEx s = (TextIO.output (TextIO.stdErr, s);
			 TextIO.flushOut TextIO.stdErr;
			 OS.Process.exit OS.Process.failure)


	fun hose () =
	    let 
		    
		val lexList =
		    let
			val inputStream = TextIO.openIn (!inFile)
			val input = TextIO.inputAll inputStream
			val _ = TextIO.closeIn inputStream
		    in
			Collect.collect (Parse.parse input, !inFile)
		    end

		val lexMap  = Extract.extract (lexList, !inFile)

		val autoMap = Table.makeAuto lexMap

		val out = TextIO.openOut (!outFile)

	    in	    
		Output.printLexList(out, lexList, autoMap);
		TextIO.closeOut out
	    end


	fun usage() = printEx "Usage: hose infile [-o outfile]\n"

	    
	fun start process = (process(); OS.Process.success)


	fun setFiles infile outfile = (inFile := infile; outFile := outfile)


	fun main' [infile, "-o", outfile] = (setFiles infile outfile;
					     start hose) 
	  | main' ["-o", outfile, infile] = (setFiles infile outfile;
					     start hose) 
	  | main' [infile]                = (setFiles infile (infile ^ ".sml");
					     start hose)
	  | main' _                       = usage () 


	fun main() =
	    let
		(* ugly hack to circumvent the problem that "hose-image"
		 * is sometimes an element of the CommandLine.arguments()
		 * (Windows)
		 *)
		val args = case CommandLine.arguments() of
		    ("hose-image"::xs) => xs
		  | xs                 => xs
	    in
		OS.Process.exit(main' args)
	    end
	handle (IO.Io {name,function="openIn",cause}) =>
	    printEx "input file does not exist\n"
	     | (IO.Io {name,function="openOut",cause}) =>
	    printEx "invalid output file\n"
	     | (IO.Io {name,function="inputAll",cause}) =>
	    printEx "input file seems to be a directory\n"
	     | exn => printEx ("Hose: unhandled internal exception: "
			       ^ General.exnName exn ^ "\n")
       
    end
