(*
 * Author:
 *   Leif Kornstaedt <kornstae@ps.uni-sb.de>
 *
 * Copyright:
 *   Leif Kornstaedt, 1999-2001
 *
 * Last change:
 *   $Date$ by $Author$
 *   $Revision$
 *)

functor MakeRecursiveCompiler(structure Composer: COMPOSER
				  where type Sig.t = Signature.t
			      structure Compiler: COMPILER
				  where Target.Sig = Signature
			      val extension: string): RECURSIVE_COMPILER =
    struct
	structure Composer = Composer
	structure Switches = Compiler.Switches
	structure Target = Compiler.Target

	type context = Compiler.context
	val empty = Compiler.empty

	val extension = extension

	fun warn message =
	    TextIO.output (TextIO.stdErr, "### warning: " ^ message ^ "\n")

	local
	    val homeref: string option ref = ref NONE
	in
	    fun stockhome () =
		case !homeref of
		    NONE =>
			let
			    val home =
				case OS.Process.getEnv "STOCKHOME" of
				    SOME s => s ^ "/"
				  | NONE => (warn "STOCKHOME not set"; "")
			in
			    homeref := SOME home; home
			end
		  | SOME home => home
	end

	fun resolveWrtCwd url =
	    let
		val base =
		    Url.setScheme (Url.fromString (OS.FileSys.getDir () ^ "/"),
				   SOME "file")
	    in
		Url.resolve base url
	    end

	fun parseUrl url =
	    case (Url.getScheme url, Url.getAuthority url) of
		(NONE, NONE) =>
		    Url.toString url
	      | (SOME "file", NONE) =>
		    Url.toString (Url.setScheme (url, NONE))
	      | (SOME "x-alice", NONE) =>
		    stockhome () ^
		    Url.toString (Url.setScheme (Url.makeRelativePath url,
						 NONE))
	      | _ => raise Crash.Crash "MakeBatchCompiler.parseUrl"

	fun readFile filename =
	    let
		val file   = TextIO.openIn filename
		val source = TextIO.inputAll file
		val _      = TextIO.closeIn file
	    in
		source
	    end

	fun isBaseSig desc =
	    case Source.url desc of
		SOME url =>
		    parseUrl url =
		    parseUrl (Url.fromString (stockhome () ^ "lib/Base." ^
					      extension ^ ".sig"))
	      | NONE => false

	fun processBasic process (desc, s) =
	    process
	    (desc,
	     if !Switches.implicitImport then
		 if isBaseSig desc then s
		 else
		     String.map (fn #"\n" => #" " | c => c)
		     (readFile (stockhome () ^ "Default.import")) ^ "\n" ^ s
	     else s)

	fun processString process source =
	    processBasic process (Source.stringDesc, source)

	fun processFile process filename =
	    let
		val url = resolveWrtCwd (Url.fromString filename)
	    in
		processBasic process (Source.urlDesc url,
				      readFile (parseUrl url))
	    end

	local
	    fun compileSign' (desc, s) =
		let
		    val _ =
			TextIO.print ("### reading signature from " ^
				      Url.toString (valOf (Source.url desc)) ^
				      "\n")
		    val (_, target) =
			Compiler.compile (Compiler.empty, desc,
					  Source.fromString s)
		    val _ = TextIO.print "### done\n"
		in
		    case Inf.items (Target.sign target) of
			[item] =>
			    let
				val inf = valOf (#3 (Inf.asInfItem item))
			    in
				Inf.strengthen (Path.invent(), inf);
				Inf.asSig inf
			    end
		      | _ => raise Crash.Crash "MakeBatchCompiler.compileSign"
		end
	in
	    fun compileSign filename = processFile compileSign' filename
	end

	local
	    fun compile' outFilename (desc, s) =
		let
		    val (_, target) =
			Compiler.compile (empty, desc, Source.fromString s)
		in
		    Target.save (Target.C.new ()) outFilename target;
		    Target.sign target
		end

	    val fileStack: string list ref = ref nil
	in
	    fun compileFileToFile (sourceFilename, targetFilename) =
		(TextIO.print ("### compiling file " ^ sourceFilename ^ "\n");
		 fileStack := sourceFilename::(!fileStack);
		 processFile (compile' targetFilename) sourceFilename
		 before (TextIO.print ("### wrote file " ^
				       targetFilename ^ "\n");
			 case fileStack of
			     ref (_::(rest as resumeFilename::_)) =>
				 (fileStack := rest;
				  TextIO.print
				  ("### resuming compilation of " ^
				   resumeFilename ^ "\n"))
			   | ref [_] => fileStack := nil
			   | ref nil => ()))
	end

	(* Define signature acquisition via recursive compiler invocation *)

	fun existsFile filename =
	    (TextIO.closeIn (TextIO.openIn filename); true)
	    handle IO.Io _ => false

	fun pathCeil filename =
	    let
		val fro = "." ^ extension
		val n = String.size filename
		val m = String.size fro
	    in
		if n > m andalso String.substring (filename, n - m, m) = fro
		then filename
		else filename ^ fro
	    end

	fun pathFloor filename =
	    let
		val fro = "." ^ extension
		val n = String.size filename
		val m = String.size fro
	    in
		if n > m andalso String.substring (filename, n - m, m) = fro
		then String.substring (filename, 0, n - m)
		else filename
	    end

	fun urlCeil url =
	    case List.rev (Url.getPath url) of
		last::rest => Url.setPath (url, List.rev (pathCeil last::rest))
	      | nil => url

	(* Try to find a compiled component or source file - search order:
	 *
	 * A              component known to composer, get signature
	 * ceil(A)        component known to composer, get signature
	 * A              pickled component, read signature from pickle
	 * ceil(A)        pickled component, read signature from pickle
	 * ceil(A).sig    compile as signature for native component
	 * floor(A).aml   compile as new component, write to ceil(A)
	 * floor(A).sml   compile as new component, write to ceil(A)
	 * floor(A).sig   compile as new component, write to ceil(A)
	 *
	 * where ceil(A) = A, if A has the component extension, else A.ozf
	 * where floor(A) = A, if A has not component extension,
	 *                  else A without the component extension
	 *)

	fun acquireSign (desc, url) =
	    let
		val url =
		    case Source.url desc of
			SOME base => Url.resolve base url
		      | NONE => resolveWrtCwd url
	    in
		case Composer.sign url of
		    SOME sign => sign
		  | NONE =>
		case Composer.sign (urlCeil url) of
		    SOME sign => sign
		  | NONE =>
		case Pickle.loadSign url of (* this also looks for url ^ ext *)
		    SOME sign =>
			(TextIO.print ("### loaded signature from " ^
				       Url.toString url ^ "\n");
			 Composer.enterSign (urlCeil url, sign);
			 sign)
		  | NONE => acquireFromSource url
	    end
	and acquireFromSource url =
	    let
		val targetFilename = parseUrl url
		val sigFilename = pathCeil targetFilename ^ ".sig"
	    in
		if existsFile sigFilename then
		    let
			val sign = compileSign sigFilename
		    in
			Composer.enterSign (urlCeil url, sign); sign
		    end
		else
		case acquireFromSource' (url, targetFilename, ".aml") of
		    SOME sign => sign
		  | NONE =>
		case acquireFromSource' (url, targetFilename, ".sml") of
		    SOME sign => sign
		  | NONE =>
		case acquireFromSource' (url, targetFilename, ".sig") of
		    SOME sign => sign
		  | NONE =>
		Error.error (Source.nowhere,
			     "could not locate source for " ^ targetFilename)
	     end
	and acquireFromSource' (url, targetFilename, to) =
	    let
		val sourceFilename = pathFloor targetFilename ^ to
	    in
		if existsFile sourceFilename then
		    let
			val sign =
			    compileFileToFile (sourceFilename,
					       pathCeil targetFilename)
		    in
			Composer.enterSign (urlCeil url, sign); SOME sign
		    end
		else NONE
	    end

	local
	    fun compile' context (desc, s) =
		Compiler.compile (context, desc, Source.fromString s)
	in
	    fun compileFile context sourceFilename =
		processFile (compile' context) sourceFilename

	    fun compileString context sourceText =
		processString (compile' context) sourceText
	end
    end
