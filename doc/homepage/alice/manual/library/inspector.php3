<?php include("macros.php3"); ?>
<?php heading("The Inspector structure", "The <TT>Inspector</TT> structure"); ?>

<?php section("synopsis", "synopsis") ?>
  <PRE>
    signature INSPECTOR
    structure Inspector : INSPECTOR</PRE>

  <P>
    The <I>Alice Inspector</I> is a tool that allows to interactively
    display and inspect Alice data structures.
  </P>

<?php section("import", "import"); ?>

  <PRE>
    import signature INSPECTOR from "x-alice:/lib/tools/INSECTOR-sig"
    import structure Inspector from "x-alice:/lib/tools/Inspector"</PRE>

  <P>
    In the <A href="http://www.ps.uni-sb.de/alice/usage.php3#interactive">interactive toplevel</A> the
    inspector is readily available without further import announcements.
  </P>

<?php section("interface", "interface"); ?>

  <PRE>
    signature INSPECTOR =
    sig
	type value

	datatype color =
	    KEEP_COLOR
	  | SET_COLOR       of {red: int, green: int, blue: int}
	datatype width =
	    KEEP_WIDTHS
	  | REPLACE_WIDTHS  of int vector
	  | APPEND_WIDTH    of int
	  | REMOVE_WIDTH    of int
	datatype depth =
	    KEEP_DEPTHS
	  | REPLACE_DEPTHS  of int vector
	  | APPEND_DEPTH    of int
	  | REMOVE_DEPTH    of int
	datatype action =
	    KEEP_ACTIONS
	  | REPLACE_ACTIONS of (string * (value -> unit)) vector
	  | APPEND_ACTION   of string * (value -> unit)
	  | REMOVE_ACTION   of string

	datatype option =
	    NUMBER            of color *                 action
	  | FUNCTION          of color *                 action
	  | STRING            of color *                 action
	  | HOLE              of color *                 action
	  | FUTURE            of color *                 action
	  | CONSTRUCTOR       of color *                 action
	  | REFERENCE         of                         action
	  | FD                of                         action
	  | FSET              of                         action
	  | TUPLE             of color * width * depth * action
	  | RECORD            of color * width * depth * action
	  | LIST              of color * width * depth * action
	  | CONSTRUCTED_VALUE of         width * depth * action
	  | VECTOR            of color * width * depth * action
	  | RECORD_LABEL      of color
	  (* relation mode *)
	  | ALIAS_DEFINITION  of color
	  | ALIAS_REFERENCE   of color
	  (* ellipses *)
	  | WIDTH_ARROW       of color
	  | DEPTH_ARROW       of color
	  | PARENTHESES       of color
	  | MISC              of color
	  | TYPEDINDICATOR    of color
	  | PROMISE           of color
	  | PACKAGE           of color

	exception ConfigurationError

	val inspect: 'a -> unit
	val inspectN: int * 'a -> unit
	val configure: option vector -> unit   (* ConfigurationError *)</PRE>

<?php section("description", "description"); ?>

  <DL>
    <DT>
      <TT>type value</TT>
    </DT>
    <DD>
      <P>
        The abstract value type.
      </P>
    </DD>

    <DT>
      <TT>inspect <I>x</I></TT>
    </DT>
    <DD>
      <P>displays an arbitrary Alice value <I>x</I> in the Inspector window.
      </P>
    </DD>

    <DT>
      <TT>inspectN (<I>i</I>, <I>x</I>)</TT>
    </DT>
    <DD>
      <P>displays an arbitrary Alice value <I>x</I> in the
         <I>i</I>-th Inspector window.
      </P>
    </DD>

    <DT>
      <TT>configure <I>v</I></TT>
    </DT>
    <DD>
      <P>configures the options in <I>v</I>. Raises <TT>ConfigurationError</TT>
         in case something goes wrong.
      </P>
    </DD>
  </DL>

<?php footing() ?>
