structure JVMInst =
    struct
	type label = string
	type classname = string
	type fieldname = string
	type methodname = string
	type stamp = IntermediateGrammar.stamp
	datatype ARG =
	    Arraysig
	  | Boolsig
	  | Charsig
	  | Classsig of classname
	  | Floatsig
	  | Intsig
	  | Voidsig
	  | Wordsig

	datatype LABEL =
	    StringLabel of string
	  | IntLabel of int

	datatype JVMBASETYPE =
	    JVMInt of LargeInt.int
	  | JVMFloat of real
	  | JVMString of string
	  | JVMWord of LargeWord.word
	  | JVMChar of char;

	datatype
	    INSTRUCTION =
	    Astore of int
	  | Aastore
	  | Aaload
	  | Aconst_null
	  | Aload of int
	  | Anewarray of classname
	  | Areturn
	  | Arraylength
	  | Athrow
	  | Bipush of int
	  | Catch of classname * label * label * label
	  | Checkcast of classname
	  | Comment of string
	  | Dup
	  | Fconst of int
	  | Getfield of fieldname * ARG list (* ARG list specifies the type. May be an Array *)
	  | Getself of string
	  | Getstatic of fieldname * ARG list (* ARG list specifies the type. May be an Array *)
	  | Goto of label
	  | Iadd
	  | Iconst of int
	  | Ifacmpeq of label
	  | Ifacmpne of label
	  | Ifeq  of label
	  | Ificmpeq of label
	  | Ificmplt of label
	  | Ificmpne of label
	  | Ifneq of label
	  | Ifnull of label
	  | Ifstatic of (stamp * INSTRUCTION list * INSTRUCTION list)
	  | Iload of int
	  | Instanceof of classname
	  | Invokeinterface of classname * methodname * (ARG list * ARG list)
	  | Invokespecial of classname * methodname * (ARG list * ARG list)
	  | Invokestatic of classname * methodname * (ARG list * ARG list)
	  | Invokevirtual of classname * methodname * (ARG list * ARG list)
	  | Ireturn
	  | Istore of int
	  | Label of label
	  | Lcmp
	  | Ldc of JVMBASETYPE
	  | New of classname
	  | Pop
	  | Putfield of fieldname * ARG list (* ARG list specifies the type. May be an Array *)
	  | Putstatic of fieldname * ARG list (* ARG list specifies the type. May be an Array *)
	  | Return
	  | Sipush of int
	  | Swap
	  | Tableswitch of int * (label list) * label
	and CLASS =
	    Class of CLASSACCESS list * classname * classname * FIELD list * METHOD list
	(* klasse, oberklasse *)
	and
	    FIELD =
	    (* ARG list specifies the type. May be an Array *)
	    Field of FIELDACCESS list * fieldname * ARG list
	and
	    METHOD =
	    Method of METHODACCESS list * methodname * (ARG list * ARG list) * LIMITS *
	    INSTRUCTION list * INSTRUCTION list * bool
	and
	    CLASSACCESS =
	    CPublic | CFinal | CSuper | CAbstract | CInterface
	and
	    FIELDACCESS =
	    FPublic | FPrivate | FProtected | FStatic | FFinal | FVolatile | FTransient
	and
	    METHODACCESS =
	    MPublic | MPrivate | MProtected | MStatic | MFinal | MSynchronized | MNative | MAbstract
	and
	    LIMITS =
	    Locals of int (* locals, stack *)
    end
