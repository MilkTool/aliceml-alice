<?php include("macros.php3"); ?>

<?php heading("SML Incompatibilities",
		"incompatibilities\nwith\nSML") ?>



<?php section("overview", "overview") ?>

<P>Most Alice extensions to SML'97 are conservative. There are some
incompatibilies with SML'97 however. Most of them are quite pathological,
caught at compile time, and can easily be fixed in an SML compatible way. This
page describes known deviations and possible (backward-compatible)
workarounds.</P>

<P>Also be aware of some <A href="limitations.php3">limitations</A> of the
current version of Alice, which might produce additional incompatibilities.</P>


<?php section("keywords", "reserved words") ?>

<P>The following are reserved words in Alice and may not be used as
identifiers:</P>

<PRE class=code>
any    constructor   exttype    fct      from       import     non
lazy   pack          spawn      unpack   withfun    withval</PRE>

<?php subsection("keywords-fix", "Workaround") ?>

<UL>
  <LI>Avoid these as identifiers.</LI>
</UL>


<?php section("openinfix", "open and infix") ?>

<P>Open pulls in <A href="modules.php3#fixity">infix status</A>. Opening a
structure that</P>

<OL>
  <LI> contains infix declarations, and </LI>
  <LI> has not been constrained by a signature </LI>
</OL>

<P>will change the infix environment, while in SML it would not.</P>

<?php subsection("openinfix-example", "Example") ?>

<PRE class=code>
structure S =
struct
    infix ++
    fun l1++l2 = l1 @ l2
end

open S

val l = ++([1],[2])		(* error: misplaced infix *)</PRE>


<?php subsection("openinfix-fix", "Workaround") ?>

<UL>
  <LI>Use appropriate signature constraints (always a good idea anyway):

   <PRE class=code>
signature SIG =
sig
    val ++ : 'a list * 'a list -> 'a list
end

structure S : SIG =
struct
    infix ++
    fun l1++l2 = l1 @ l2
end

open S

val l = ++([1],[2])</PRE>
  </LI>

  <LI>Or insert <TT>op</TT> on every use of such identifiers:

    <PRE class=code>
val l = op++([1],[2])</PRE>
  </LI>
</UL>


<?php section("valrec", "val rec") ?>

<P>Recursive value bindings do not remove constructor status on the identifiers
bound. You cannot bind functions to an identifier that was a constructor
previously.</P>

<?php subsection("valrec-example", "Example") ?>

<PRE class=code>
val rec NONE = fn x => x
fun NONE x = x</PRE>

<P>Both these declarations are legal in SML'97 due to an artefact of the
formal language specification and would introduce a function named
<TT>NONE</TT>, hiding the constructor status of <TT>NONE</TT>. In Alice, they
produces a type clash because they are interpreted as trying to match
<TT>NONE</TT> with a lambda expression.</P>

<P class=note><EM>Note:</EM> This behaviour is consistent with SML'90 as well
as several other SML implementations, and probably what the user would
expect.</P>


<?php subsection("valrec-fix", "Workaround") ?>

<UL>
  <LI> Rename your function, this is perverse anyway. </LI>
</UL>


<?php section("datatypes", "datatypes") ?>

<P>Alice' <A href="types.php3#structural">structural datatypes</A> come with
some restrictions that are not present in SML. In particular, Alice demands
that, whenever a datatype constructor is used in an expression or pattern, the
corresponding type is visible.</P>


<?php subsection("datatypes-example", "Examples") ?>

<P>The following program will not type-check: </P>

<PRE class=code>
datatype t = C
type t = int
val c = C</PRE>

<P>Though one does not usually write such code, the same situation can appear
implicitly through liberal use of open.</P>

<?php subsection("datatypes-fix", "Workaround") ?>

<UL>
  <LI> Do not shadow datatypes you intend to use. </LI>
</UL>


<?php section("conarity", "constructor arity") ?>

<P>For <A href="interop.php3">interoperability</A> reasons, Alice currently has
the concept of syntactic arity for constructors. For example, in </P>

<PRE class=code>
type     t = int * real
datatype t = A of int * real | B of {a : bool, b : string} | C of t</PRE>

<P>constructor <TT>A</TT> and <TT>B</TT> both have arity 2, while <TT>C</TT>
has arity 1. Usually, syntactic arity can be ignored. However, signature
matching is restricted to disallow changing the syntactic arity of
constructors.</P>

<P class=note><EM>Note:</EM>The same restriction is imposed by Moscow ML.</P>

<P>Note that syntactic arity is calculated after elimination of derived
forms. Therefore <TT>C</TT> has arity 3 in the following example:</P>

<PRE class=code>
datatype t = C of u
withtype u = int * int * string</PRE>


<?php subsection("conarity-example", "Examples") ?>

<P>The following program will not elaborate in the current version of Alice:</P>

<PRE class=code>
signature S1 =
sig
    datatype t = C of int * real
end

structure M1 :> S1 =	(* error: mismatch *)
sig
    type     u = int * real
    datatype t = C of u
end</PRE>

<P>Neither will:</P>

<PRE class=code>
type u = int * real

signature S2 =
sig
    datatype t = C of u
end

structure M2 :> S2 =	(* error: mismatch *)
sig
    datatype t = C of int * real
end</PRE>

<?php subsection("conarity-fix", "Workaround") ?>

<UL>
  <LI>
    <P>In most cases, modules can be rewritten by either expanding type
    synonyms or by introducing auxiliary type synonyms:</P>

    <PRE class=code>
structure M1 :> S1 =
sig
    type     u = int * real
    datatype t = C of int * real
end

structure M2 :> S2 =
sig
    type     u = int * real
    datatype t = C of u
end</PRE>

    <P>Transformations can get tedious in the case of higher-order functors,
    however.</P>
  </LI>
</UL>



<?php section("funid", "namespaces") ?>

<P>Alice provides <A href="modules.php3#higher">higher-order functors</A>. To
integrate them smoothly into the language it was necessary to give up the
separation between namespaces for structures and those for functors - both are
modules. This may break programs that declare structures and functors with
identical names.</P>

<?php subsection("funid-example", "Example") ?>

<PRE>
functor Table() = struct (* ... *) end

structure Table  = Table()
structure Table' = Table()	(* error: Table is not a functor *)</PRE>

<?php subsection("funid-fix", "Workaround") ?>

<UL>
  <LI>
    <P>
      Rename your functors or structures appropriately. It is a good idea to
      stick to naming conventions that denote functors with names like
      <TT>MkTable</TT>.
    </P>
  </LI>
</UL>


<!--
<?php section("include", "include") ?>

<P>Because of syntactic ambiguity with uses of <A
href="modules.php3#paramsig">parameterized signatures</A>, Alice does not
support the multiple include derived form.</P>


<?php subsection("include-example", "Example") ?>

<PRE class=code>
signature S =
sig
    include A B		(* error: A is not parameterized *)
end</PRE>

<?php subsection("include-workaround", "Workaround") ?>

<UL>
  <LI>
    <P>
      Split it into several include specifications:
    </P>

    <PRE class=code>
signature S =
sig
    include A
    include B
end</PRE>
  </LI>
</UL>

-->


<?php section("sharing", "sharing") ?>

<P>In Alice, datatypes are not generative, but are just structural types
similar to records. This has an impact on the use of sharing constraints,
which require <I>flexible</I> (i.e. abstract) type constructors.</P>

<P>Alice relaxes the rules for sharing constraints and allows sharing of
type constructors as long as one of the following conditions holds:</P>

<OL>
  <LI> both are identical type synonyms, or </LI>
  <LI> the type constructor introduced later (lexically) is abstract. </LI>
</OL>

<P>This makes sharing between datatypes possible in most cases. There are
exceptions, however.</P>

<?php subsection("sharing-example", "Example") ?>

<PRE class=code>
signature A =
sig
    type t
end

signature B =
sig
    datatype t = C
end

signature S =
sig
    structure A : A
    structure B : B
    sharing type A.t = B.t	(* error: types incompatible *)
end</PRE>

<P>Signature <TT>S</TT> will not elaborate because type <TT>B.t</TT> is
specified after <TT>A.t</TT> and is neither abstract nor identical to
<TT>A.t</TT> (which is abstract).</P>

<?php subsection("sharing-fix", "Workaround") ?>

<UL>
  <LI>
    <P>Signature <TT>S</TT> can be made valid by reordering structure
    specifications:</P>

    <PRE class=code>
signature S =
sig
    structure B : B
    structure A : A
    sharing type A.t = B.t
end</PRE>

    <P>Suitable reordering is not always possible, however.</P>
  </LI>

  <LI>
    <P>In general, we consider sharing constraints an obsolete feature of SML.
    Use <TT>where</TT> constraints instead<!-- (Alice as well as SML/NJ
    support <TT>where</TT> constraints for whole structures)-->.</P>
  </LI>
</UL>


<?php section("library", "extended library") ?>

<P>Alice extends many of the structures and signatures defined by the <A
href="http://SML.sourceforge.net/Basis/">Standard ML Basis Library</A>. This may
change the meaning of programs that open library structures, or use library
signatures.</P>

<?php subsection("library-example", "Example") ?>

<PRE class=code>
signature A =
sig
    type t
end

signature B =
sig
    datatype t = C
end

signature S =
sig
    structure A : A
    structure B : B
    sharing type A.t = B.t	(* error: types incompatible *)
end</PRE>

<?php subsection("library-fix", "Workaround") ?>

<UL>
  <LI> Avoid opening library structures that might shadow entities from the
     local environment. Prefer qualified access.</LI>
  <LI> Avoid using library signatures in conjunction with non-library structures
  or functors. If in doubt, redefine them.</LI>
</UL>


<?php footing() ?>
