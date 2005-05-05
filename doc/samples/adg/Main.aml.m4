(* ADG 1.0 - Alice Dependence Graph
*
*  Author: Sebastian Germesin
*
*  $Revision$
*
*  Last updated: $Date$ by $Author$
* 
*
*)

changequote([[,]])

ifdef([[gdl]],[[import structure Backend from "GDL"]])
ifdef([[dot]],[[import structure Backend from "DOT"]],
[[import structure Backend from "DOT"]])


val head = 
    "// Alice Dependence Graph           //\n" ^ 
    "//                                  //\n" ^ 
    "// Author: Sebastian Germesin       //\n" ^ 
    "//                                  //\n" ^
    "// eMail: germi@ps.uni-sb.de        //\n" ^ 
    "//                                  //\n" ^
    "//////////////////////////////////////\n" ^
    "//\n" ^ 
    "//\n" ^ 
    "// written in " ^ Backend.name ^ "\n" ^
    "// Annotations:\n" ^
    "//\n" ^ 
    "// for looking the graph:\n" ^
    "//     use " ^ Backend.program ^ "\n" ^
    "//\n" ^
    "// red box    with black border = main file\n" ^
    "// green box  with black border = built files\n" ^
    "// blue box   with black border = alice-lib files\n" ^
    "// yellow box with black border = unsafe files\n\n\n" ^
    Backend.header ^ 
    "\n\n\n\n"

val usage = "unrecognized option\n\n" ^ 
	    "Usage: \nalicerun Main <input_filename> " ^ 
	    "[-{no, only} regex] [<output_filename>]\n"

fun start (inFile, switch, regex, outFile) = 
    let
	val outStream = TextIO.openOut (outFile ^ Backend.fileEnding)
    in 
	TextIO.output (TextIO.stdOut, "input  file: " ^ inFile ^ "\n");
	TextIO.output (TextIO.stdOut, "output file: " ^ outFile ^ 
				      Backend.fileEnding ^ "\n");
	if switch 
	then TextIO.output (TextIO.stdOut, "only recognizing files with" ^
					   " regex: " ^ regex ^ "\n")
	else if regex <> ""
	     then TextIO.output (TextIO.stdOut, "ignoring files with " ^
						"regex: " ^ regex ^ "\n")
	     else ();
	TextIO.output (outStream, head);
	Backend.output (inFile, switch, regex, outStream);
	TextIO.output (outStream, "\n}");
	TextIO.closeOut outStream;
	OS.Process.exit OS.Process.success
    end


val _  = case CommandLine.arguments () of
	         []           => (TextIO.output (TextIO.stdErr, usage);
				  OS.Process.exit OS.Process.success)
	       (* TODO: fehlerquellen ausmerzen (s. usage) *)
	       | [a]                => start (a, false, "", "output")
 	       | [a,   d]           => start (a, false, "", d)
	       | [a, "-no", c]      => start (a, true, c, "output")
	       | [a, "-only", c]    => start (a, false, c, "output")
	       | [a, "-no", c, d]   => start (a, true, c, d)
	       | [a, "-only", c, d] => start (a, false, c, d)
	       |   _                => TextIO.output (TextIO.stdErr, usage)

