(*
 * Authors:
 *   Robert Grabowski <grabow@ps.uni-sb.de>
 *
 * Copyright:
 *   Robert Grabowski, 2003
 *
 * Last Change:
 *   $Date$ by $Author$
 *   $Revision$
 *
 *)


(* 
 The TypeManager structure provides functions that operate on the TypeTree,
 like converting a TypeTree into alice and C type names,
 defining the names of the unsafe<->safe and word<->C conversion functions,
 determining the name space a TypeTree.decl belongs to,
 handling the in/out arguments of a function,
 and much more.
*)

structure TypeManager :> TYPE_MANAGER =
struct
    exception EStruct
    exception EUnion

    open TypeTree
	
    (* Utility function to remove all TYPEREFs from a type (tree) *)
    fun removeTypeRefs (POINTER (c, t))     = POINTER (c, removeTypeRefs t)
      | removeTypeRefs (ARRAY (x,t))   = ARRAY(x, removeTypeRefs t)
      | removeTypeRefs (LIST  (x,t))   = LIST (x, removeTypeRefs t)
      | removeTypeRefs (TYPEREF (_,t)) = removeTypeRefs t
      | removeTypeRefs t               = t

    fun checkSpace f n space = Util.checkPrefix (f space) n

    (* Checks whether certain references/declarations belong to a namespace *)
    fun isRefOfSpace Util.MISC (ENUMREF n) =
        not (List.exists (checkSpace Util.spaceName n) Util.stdSpaces) 
      | isRefOfSpace Util.MISC (STRUCTREF n) =
        not (List.exists (checkSpace Util.spaceName n) Util.stdSpaces) 
      | isRefOfSpace space (ENUMREF n) =
        Util.checkPrefix (Util.spaceName space) n
      | isRefOfSpace space (STRUCTREF n) =
        Util.checkPrefix (Util.spaceName space) n
      | isRefOfSpace space (TYPEREF (_,t)) = isRefOfSpace space t
      | isRefOfSpace _ _ = false

    fun isItemOfSpace Util.MISC (FUNC (n,_,_)) = 
        not (List.exists (checkSpace Util.spaceFuncPrefix n) Util.stdSpaces)
      | isItemOfSpace Util.MISC (ENUM (n,_)) =
        not (List.exists (checkSpace Util.spaceEnumPrefix n) Util.stdSpaces)
      | isItemOfSpace Util.MISC (STRUCT (n,_)) =
        not (List.exists (checkSpace Util.spaceStructPrefix n) Util.stdSpaces)
      | isItemOfSpace space (FUNC (n,_,_)) = 
        Util.checkPrefix (Util.spaceFuncPrefix(space)) n
      | isItemOfSpace space (ENUM (n,_)) =
        Util.checkPrefix (Util.spaceEnumPrefix(space)) n
      | isItemOfSpace space (STRUCT (n,_)) =
        Util.checkPrefix (Util.spaceStructPrefix(space)) n
      | isItemOfSpace _ _ = false

    (* Functions to build a class dependency list. This list is needed *)
    (* to find out the type information of a struct pointer *)
    (* (for creating objects) *)
    local
	val classes = ref nil
	exception NoUnref
	
	fun buildClassList' (STRUCT (name,(_,t)::_)) =
	    (case removeTypeRefs t of
		 STRUCTREF sup => ( classes := ((sup,name)::(!classes)) )
	       | _             => () 
		     )
	  | buildClassList' _ = ()

	fun getParentClass name nil = raise NoUnref
	  | getParentClass name ((sup, n)::cs) = 
	        if n=name then sup else getParentClass name cs
		
	fun getUnrefFun' "_GObject"   = "TYPE_G_OBJECT"
	  | getUnrefFun' "_GtkObject" = "TYPE_GTK_OBJECT"
	  | getUnrefFun' name        = 
	    getUnrefFun' (getParentClass name (!classes))
    in
	fun buildClassList tree = (classes := nil ; 
				   List.app buildClassList' tree)
	fun getTypeInfo t = 
	    (case removeTypeRefs t of 
		 STRUCTREF name => getUnrefFun' name
	       | _              => raise NoUnref)
	    handle _ => "TYPE_UNKNOWN"
    end

    (* Convert a TypeTree type into its C type name *)
    local
	fun numericToCType sign kind =
	    (if sign then "" else "unsigned ")^
		 (case kind of
		      CHAR => "char" 
		    | SHORT => "short" 
		    | INT => "int" 
		    | LONG => "long" 
		    | LONGLONG => "longlong" 
		    | FLOAT => "float" 
		    | DOUBLE => "double" 
		    | LONGDOUBLE => "long double")
    in
	fun getCType VOID                     = "void"
	  | getCType (ELLIPSES true)          = "..."
	  | getCType (ELLIPSES false)         = "va_list"
	  | getCType BOOL                     = "gboolean"
	  | getCType (NUMERIC (sign,_,kind))  = numericToCType sign kind
      | getCType (POINTER (true, (STRING (false, true))))   
                                          = "const guchar* const *"
      | getCType (POINTER (true, (STRING (true, true))))
                                          = "const gchar* const*"
	  | getCType (POINTER (true, t))      = "const " ^ getCType t ^"*"
      | getCType (POINTER (false, t))     = getCType t ^ "*"
	  | getCType (STRING (false, false))  = "guchar*"
	  | getCType (STRING (true, false))   = "gchar*"
	  | getCType (STRING (false, true))   = "const guchar*"
	  | getCType (STRING (true, true))    = "const gchar*"
      | getCType (ARRAY (SOME i, t))      = 
	        (getCType t)^"["^Int.toString(i)^"]"
	  | getCType (ARRAY (NONE, t))        = (getCType t)^"[]"
	  | getCType (LIST (name,_))          = name^"*"
	  | getCType (FUNCTION (ret,arglist)) = 
 	        getCType(ret)^"(*)("^
		(Util.makeTuple ", " "void" (map getCType arglist)) ^")"
	  | getCType (STRUCTREF name)   = name
	  | getCType (UNIONREF name)    = name
	  | getCType (ENUMREF name)     = name
	  | getCType (TYPEREF (name,_)) = name
    end

    (* Convert a TypeTree type into its alice type name *)
    local
	fun getEnumSpace name = 
	    foldl (fn (s,e) => if isRefOfSpace s (ENUMREF name) then s else e)
	          Util.MISC Util.allSpaces
    in
	fun getAliceType VOID                  = "unit"
	  | getAliceType (ELLIPSES true)       = "Core.arg"
	  | getAliceType (ELLIPSES false)      = "Core.arg list"
	  | getAliceType BOOL                  = "bool"
	  | getAliceType (NUMERIC (_,false,_)) = "int"
	  | getAliceType (NUMERIC (_,true,_))  = "real"
	  | getAliceType (POINTER (_, _))      = "Core.object"
	  | getAliceType (STRING _)            = "string"
	  | getAliceType (ARRAY (_,t))         = (getAliceType t) ^ " vector"
	  | getAliceType (LIST (_,t))          = (getAliceType t) ^ " list"
	  | getAliceType (FUNCTION _)          = "Core.object"
	  | getAliceType (STRUCTREF _)         = raise EStruct
	  | getAliceType (UNIONREF _)          = raise EUnion
	  | getAliceType (ENUMREF name)        = 
	         Util.spaceName(getEnumSpace name)^"Enums."^name
	  | getAliceType (TYPEREF (_,t))       = getAliceType t
	 
	fun getAliceNativeType t =
	    case removeTypeRefs t of 
		(ENUMREF _) => "int" 
	      | _ => getAliceType t
    end
      
    (* Return the conversion functions used before and after calling *)
    (* a native function *)
    fun safeToUnsafe vname (ENUMREF ename)     = ename^"ToInt "^vname
      | safeToUnsafe vname _                   = vname

    fun unsafeToSafe vname (ENUMREF ename)     = "IntTo"^ename^" "^vname
      | unsafeToSafe vname (POINTER _)         = vname (* OBJECT_TO_WORD *)
      | unsafeToSafe vname (LIST(_,POINTER _)) = vname (* OBJECT_TO_WORD *)
      | unsafeToSafe vname _                   = vname

    (* Return the macro name for converting from and to a word; *)
    (* plus extra arguments for that macro *)
    fun fromWord (NUMERIC(_,false,_)) = ("DECLARE_INT", nil)
      | fromWord (NUMERIC(_,true, _)) = ("DECLARE_CDOUBLE", nil)
      | fromWord (ELLIPSES true)      = ("DECLARE_ELLIPSES", nil)
      | fromWord (ELLIPSES false)     = ("DECLARE_VALIST", nil)
      | fromWord BOOL                 = ("DECLARE_BOOL", nil)
      | fromWord (POINTER _)          = ("DECLARE_OBJECT", nil)
      | fromWord (STRING _)           = ("DECLARE_CSTRING", nil)
      | fromWord (ARRAY (_,t))        = ("DECLARE_CARRAY",
					 [getCType t,#1(fromWord t)])
      | fromWord (LIST("GList", t))   = ("DECLARE_GLIST", [#1(fromWord t)])
      | fromWord (LIST("GSList", t))  = ("DECLARE_GSLIST",[#1(fromWord t)])
      | fromWord (FUNCTION _)         = ("DECLARE_OBJECT", nil)
      | fromWord (ENUMREF _)          = ("DECLARE_ENUM", nil)
      | fromWord (TYPEREF (_,t))      = fromWord t
      | fromWord _                    = ("DECLARE_UNKNOWN", nil)

    fun toWord (NUMERIC(_,false,_))      = ("INT_TO_WORD", nil)
      | toWord (NUMERIC(_,true ,_))      = ("REAL_TO_WORD", nil)
      | toWord BOOL                      = ("BOOL_TO_WORD", nil)
      | toWord (POINTER (c, t))          = ("OBJECT_TO_WORD", [getTypeInfo t])
      | toWord (STRING _)                = ("STRING_TO_WORD", nil)
      | toWord (LIST("GList",STRING _))  = ("GLIST_STRING_TO_WORD", nil)
      | toWord (LIST("GSList",STRING _)) = ("GSLIST_STRING_TO_WORD", nil)
      | toWord (LIST("GList",_))         = ("GLIST_OBJECT_TO_WORD", nil)
      | toWord (LIST("GSList",_))        = ("GSLIST_OBJECT_TO_WORD", nil)
      | toWord (FUNCTION _)              = ("FUNCTION_TO_WORD", nil)
      | toWord (TYPEREF(_,t))            = toWord t
      | toWord (ENUMREF _)               = ("ENUM_TO_WORD", nil)
      | toWord _                         = ("",nil)
  
    (* Define how "real" output arguments should be set before the *)
    (* library function call *)
    fun outInit (NUMERIC _)      = "= 4711"
      | outInit BOOL             = "= true"
      | outInit (TYPEREF (_,t))  = outInit t
      | outInit _                = ""
      
    datatype argtype = IN | OUT
    type arginfo = argtype * string * TypeTree.ty
    (* arginfo: IN/OUT argument; name of the C variable; type *)

    local
	fun isOutArg (POINTER (c, NUMERIC _))   = not c
	  | isOutArg (POINTER (c, POINTER _))   = not c
	  | isOutArg (POINTER (c, ENUMREF _))   = not c
	  | isOutArg (POINTER (_, STRING (_, c)))  = not c
	  | isOutArg _                          = false
    in
	(* Splits an list of TypeTree.ty's into inArgs and outArgs      *)
	(* (arginfo lists), where outArgs lose their POINTERs           *)
	(* example: [BOOL, POINTER (NUMERIC ...)] ->                    *)
	(*      ( [(IN, "in0", BOOL)] , [(OUT, "out1", NUMERIC ...)] )  *)
	fun splitArgTypes arglist =
	let
	    val arglist' = List.filter (fn VOID => false | _ => true) arglist
	    fun makeArg (t,num) = 
		let 
		    val at = if isOutArg (removeTypeRefs t) then OUT else IN
		in  
		    if at = IN
			then (at, "in"^num, t)
			else (at, "out"^num, (case t of 
			                        POINTER (_, x) => x 
					      | _         => t) )
		end
	in
	    ListPair.map makeArg (arglist', 
				  List.tabulate(length arglist',Int.toString))
	end

        (* Converts all argumens into inArgs (needed for get/set field funs) *)
	fun splitArgTypesNoOuts arglist =
	    ListPair.map (fn (num,t) => (IN, "in"^num, t))
	            (List.tabulate (length arglist,Int.toString), arglist)
    end

    (* splits an arginfo list into an IN arginfo list and an OUT arginfo list*)
    (* doinout = whether output arguments are also input arguments *)
    fun splitInOuts (l,doinout) =
	(List.filter (fn (IN,_,_) => true | _ => doinout) l,
	 List.filter (fn (IN,_,_) => false | _ => true) l)

    (* returns the number of input/output arguments *)
    fun numIns (l,doinout) = length (#1 (splitInOuts (l,doinout)))
    fun numOuts (l,doinout) = length (#2 (splitInOuts (l,doinout)))

    (* Return the C type name of a function *)
    fun getCFunType (funName, ret, arglist, mask) =
    let
	fun getCType' (IN,_,t) = getCType t
	  | getCType' (OUT,_,t)  = getCType (POINTER (false, t))
	val s = (getCType ret) ^ " " ^ funName ^ "(" ^ 
	        (Util.makeTuple ", " "void" (map getCType' arglist)) ^ ")"
    in
	if mask then (Util.replaceChar (#"*","#") s) else s
    end

    (* Return the Alice type name of a function *)
    fun getAliceFunType (funName, ret, arglist, doinout) convFun =
    let
	val (ins,outs') = splitInOuts (arglist,doinout)
	val outs = if ret=VOID then outs' else (OUT, "", ret)::outs'
	fun getType (_,_,t) = t
    in
	"val "^funName^" : "^
	(Util.makeTuple " * " "unit" (map (convFun o getType) ins)) ^ " -> " ^
	(Util.makeTuple " * " "unit" (map (convFun o getType) outs))
    end

    (* Creates a FUNC declaration for a specific get/set function *)
    fun makeFieldFun space (sname, mname, mtype, get) =
    let
	val sname' = (Util.spaceName space)^
	              Util.cutPrefix ("_"^(Util.spaceEnumPrefix space), sname)
	val stype = POINTER (false, STRUCTREF sname')
    in
	if get 
	    then (sname'^"_get_field_"^mname, mtype, [stype])
  	    else (sname'^"_set_field_"^mname, VOID, [stype, mtype])
    end


    (* checks whether a binding can be generated for a declaration  *)
    fun checkItem (FUNC (n,ret,arglist)) =
	let
	    fun error s = ( print ("function "^n^" ignored: "^s^"\n") ; false )
	in
	    ( map getAliceType (ret::arglist) ; true )
	    handle
  	        EStruct   => error "struct in arglist or retval"
	      | EUnion    => error "union in arglist or retval"
	end		    
(* Hack Alert - the following line prevents cygwin ld crashing *)
(*      | checkItem (STRUCT ("_GtkFileSelection",_)) = true
      | checkItem (s as (STRUCT _)) = not (isItemOfSpace Util.GTK s)*)
      | checkItem _ = true

    (* Removes struct/enum members for which no binding can be generated *)
    fun checkStructMember (_,t) =
	(case removeTypeRefs t of
	     FUNCTION _        => false
	   | ARRAY _           => false
	   | POINTER (_, ARRAY _) => false
           | t'         => ((getAliceType t' ; true) handle _ => false))

    fun checkEnumMember (_,v) = (LargeInt.toInt v ; true) handle _ => false

end
