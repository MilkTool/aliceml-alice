
structure Util :> UTIL =
    struct
	fun firstLower'(X::Xr) = String.implode ((Char.toLower X)::Xr)
	  | firstLower' nil    = ""
	fun firstLower Xs = firstLower'(String.explode Xs)

	fun firstUpper'(X::Xr) = String.implode ((Char.toUpper X)::Xr)
          | firstUpper' nil    = ""
	fun firstUpper Xs = firstUpper'(String.explode Xs)

	fun replaceChar (c,r) s = 
               String.translate 
                  (fn c' => if c = c' then r else Char.toString c' ) 
                  s
	
	fun strUpper s = 
	       String.translate
                  (fn c => if Char.isUpper c 
			       then "_"^(Char.toString c)
                               else (Char.toString (Char.toUpper c)))
                  (firstLower s)

	fun indent n = if n = 0 then "" else "    " ^ (indent (n - 1))

        fun makeTuple sep e nil     = e
	  | makeTuple sep e [x]     = x
	  | makeTuple sep e (x::xr) = x ^ sep ^
	                              (makeTuple sep e xr)
	
        datatype spaces = GDK | GTK | GTKCANVAS

	fun spaceName GDK       = "Gdk"
	  | spaceName GTK       = "Gtk"
	  | spaceName GTKCANVAS = "GtkCanvas"

	fun spaceFuncPrefix GDK       = "gdk_"
	  | spaceFuncPrefix GTK       = "gtk_"
	  | spaceFuncPrefix GTKCANVAS = "gtk_canvas_"

	fun spaceEnumPrefix space = spaceName space
	   
	fun checkPrefix'(X::Xr, Y::Yr) = X = Y andalso checkPrefix'(Xr, Yr)
	  | checkPrefix'(nil, _)       = true
	  | checkPrefix' _             = false

	fun checkPrefix Xs Ys =
	    checkPrefix'(String.explode Xs, String.explode Ys)

	fun cutPrefix'(X::Xr, Ys as Y::Yr) =
	    if ((Char.toUpper X)  = (Char.toUpper Y)) then cutPrefix'(Xr, Yr)
	                                              else String.implode Ys
	  | cutPrefix'(nil, Ys)    = String.implode Ys
	  | cutPrefix'(X::Xr, nil) = ""

	fun cutPrefix(Xs, Ys) =
	    cutPrefix'(String.explode Xs, String.explode Ys)


	fun sep #"_" = true
	  | sep _    = false
	fun translateName str =
	    firstLower (String.concat (map firstUpper (String.tokens sep str)))

	fun computeWrapperName (space, str) =
	    translateName (cutPrefix(spaceFuncPrefix space, str))

	fun computeEnumName (space, str) =
	let
	    val n = cutPrefix(strUpper(spaceEnumPrefix space)^"_",str)
	in
	    if Char.isDigit(hd(String.explode n)) then str else n
	end

	fun filters fs xs = foldl (fn (f,e) => List.filter f e) xs fs
	fun funNot f x = not (f x)

	type fileInfo = {name: string, intro: string list, outro: string list}
	type fileHandle = fileInfo * TextIO.outstream

	fun outputStrings (h as (_,f)) xs = TextIO.output (f, String.concat xs)

	fun openFile (info : fileInfo) =
	let
	    val f = TextIO.openOut (#name info)
            val h = (info, f) : fileHandle
	    val _ = outputStrings h (#intro info)
	in
            h
	end

	fun closeFile (h as (info, f) : fileHandle) =
	    ( outputStrings h (#outro info) ; TextIO.closeOut f )
	  
(*
	fun includeFile (filename, begincomment, endcomment) =
	let
	    val f = TextIO.openIn filename
	    val s = TextIO.inputAll f
	    val _ = TextIO.closeIn f
	in 
	    String.concat
	        ["\n",
		 begincomment," ** begin of ",filename," ** ",endcomment,"\n",
		 s,
		 begincomment," ** end of ",filename," ** ",endcomment,"\n\n"]
	end
        handle _ => ""
*)

    end
