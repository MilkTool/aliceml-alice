<?php include("macros.php3"); ?>

<?php heading("Syntactic enhancements", "syntactic\nenhancements") ?>


<?php section("overview", "overview") ?>

<P>The extensions listed here are mostly syntactic sugar that is also
expressible by other, less convenient means:</P>

<UL>
  <LI> <A href="sugar.php3#lexical">Lexical syntax</A> </LI>
  <LI> <A href="sugar.php3#longids">Long identifiers</A> </LI>
  <LI> <A href="sugar.php3#vectors">Vector expressions and patterns</A> </LI>
  <LI> <A href="sugar.php3#records">Records</A> </LI>
  <LI> <A href="sugar.php3#patterns">Pattern language</A> </LI>
  <LI> <A href="sugar.php3#rec">Recursive definitions</A> </LI>
</UL>


<?php section("lexical", "lexical syntax extensions") ?>

<?php subsection("literals", "Literals") ?>

<P>Numeric literals may contain underscores to group digits:</P>

<PRE class=code>
val pi = 3.141_592_653_596
val billion = 1_000_000_000
val nibbles = 0wx_f300_4588</PRE>

<P>Moreover, binary integer and word literals are supported:</P>

<PRE class=code>
val ten  = 0b1010
val bits = 0wb1101_0010_1111_0010</PRE>


<?php subsection("longids", "Long identifiers") ?>

<P>Long identifiers are not part of the lexical syntax, but of the context-free
grammar. Consequently, there may be arbitrary white space separating the dots
from the identifiers:</P>

<PRE class=code>
mod . submod (*Here!*) . subsub
    . f</PRE>



<?php section("vectors", "vectors") ?>

<P>Following SML/NJ, Alice provides vector expressions and patterns:</P>

<PRE class=code>
val v = #[1, 2, 4, 1, 2]

fun f #[]  = 0
  | f #[n] = n
  | f  v   = 1</PRE>


<?php subsection("vectors-syntax", "Vector syntax") ?>

<TABLE class=bnf>
  <TR>
    <TD> <I>atexp</I> </TD>
    <TD align="center">::=</TD>
    <TD> ... </TD>
    <TD> </TD>
  </TR>
  <TR>
    <TD></TD> <TD></TD>
    <TD> <TT>#[</TT> <I>exp</I><SUB>1</SUB> <TT>,</TT> ... <TT>,</TT>
                     <I>exp</I><SUB><I>n</I></SUB> <TT>]</TT> </TD>
    <TD> vector (<I>n</I>&ge;0) </TD>
  </TR>
  <TR></TR>
  <TR>
    <TD> <I>atpat</I> </TD>
    <TD align="center">::=</TD>
    <TD> ... </TD>
    <TD> </TD>
  </TR>
  <TR valign=baseline>
    <TD></TD> <TD></TD>
    <TD> <TT>#[</TT> <I>pat</I><SUB>1</SUB> <TT>,</TT> ... <TT>,</TT>
                     <I>pat</I><SUB><I>n</I></SUB> <TT>]</TT> </TD>
    <TD> vector (<I>n</I>&ge;0) </TD>
  </TR>
</TABLE>
  


<?php section("records", "records") ?>

<?php subsection("records-punning", "Record punning") ?>

<P>While SML allows punning in record patterns (so that the left hand side of
the former example is legal), it does not allow punning in record expressions.
In Alice, the latter is also available as a simple derived form, dualing the
derived form for patterns. For example, the declaration

<PRE class=code>
fun f {a,b,c} = {a,b}</PRE>

<P>is understood as an abbreviation for</P>

<PRE class=code>
fun f {a = a, b = b, c = c} = {a = a, b = b}</PRE>

<P>The labels may have type annotations, i.e. <TT>{a : int, b}</TT> abbreviates
<TT>{a = a : int, b = b}</TT>.</P>


<?php subsection("records-update", "Functional record update") ?>

<P>There also is syntax for functional record update. For example,</P>

<PRE class=code>
let
    val r = {a = 1, b = true, c = "hello"}
in
    {r where a = 3, c = "bye"}
end</PRE>

<P>evaluates to</P>

<PRE class=code>
{a = 3, b = true, c = "bye"}</PRE>


<?php subsection("records-syntax", "Record syntax") ?>

<TABLE class=bnf>
  <TR>
    <TD> <I>atexp</I> </TD>
    <TD align="center">::=</TD>
    <TD> ... </TD>
    <TD> </TD>
  </TR>
  <TR>
    <TD></TD> <TD></TD>
    <TD> <TT>{</TT> <I>atexp</I> <TT>where</TT> <I>exprow</I> <TT>}</TT> </TD>
    <TD> record update </TD>
  </TR>
  <TR></TR>
  <TR>
    <TD> <I>exprow</I> </TD>
    <TD align="center">::=</TD>
    <TD> ... </TD>
    <TD> </TD>
  </TR>
  <TR>
    <TD></TD> <TD></TD>
    <TD> <I>vid</I> &lt;<TT>:</TT> <I>ty</I>&gt;
                    &lt;<TT>,</TT> <I>exprow</I>&gt; </TD>
    <TD> label as expression </TD>
  </TR>
</TABLE>

<P>The expression <I>atexp</I> in a record update must have a record type that
includes all fields contained in <I>exprow</I>. The types of the fields must
match. The result of evaluating a record update is a record of the same type
but with the fields occuring in <I>exprow</I> replacing the corresponding
values of the original record.</P>

<P>Labels as expressions are a derived form:</P>

<TABLE class=bnf>
  <TR>
    <TD> <I>vid</I> &lt;<TT>:</TT> <I>ty</I>&gt; &lt;<TT>,</TT> <I>exprow</I>&gt; </TD>
    <TD> ==> </TD>
    <TD> <I>vid</I> <TT>=</TT> <I>vid</I> &lt;<TT>:</TT> <I>ty</I>&gt; &lt;<TT>,</TT> <I>exprow</I>&gt; </TD>
  </TR>
</TABLE>


<?php section("patterns", "patterns") ?>

<?php subsection("patterns-alt", "Alternative patterns") ?>

<P>Alternative patterns (also called <EM>or patterns</EM>) are present in SML/NJ
as well and allow more compact case analysis:</P>

<PRE class=code>
fun f(1 | 2 | 3) = 0
  | f n          = n</PRE>

<P>The patterns nested inside an alternative pattern may bind variables, but
all patterns must bind exactly the same set of variables with the same
type.</P>


<?php subsection("patterns-layered", "Layered patterns") ?>

<P>Layered patterns (also called <EM>as patterns</EM>) have been generalized to
allow arbitrary patterns on both sides (in contrast to just an identifier on
the left hand side as in SML). This is useful as it allows to put the
identifier on either side:</P>

<PRE class=code>
fun f(xs as x::xr) = bla
fun g(x::xr as xs) = blo</PRE>


<?php subsection("patterns-negated", "Negated patterns") ?>

<P>Negated patterns are a more special feature. A negated pattern matches
exactly when the operand pattern does not match. This sometimes allows
specifying cases in a more natural order, in particular in combination with or
patterns:</P>

<PRE class=code>
fun f(non(1 | 2 | 3)) = 0
  | f n               = n</PRE>

<P>The nested pattern may bind variables, but these are not visible outside.
(They may be useful for a local guard, for example.)</P>


<?php subsection("patterns-guard", "Guard patterns") ?>

<P>The most important extension are pattern guards. These allow decorating
patterns with boolean conditions. A guarded pattern matches, if the pattern
matches and the guard expression evaluates to <TT>true</TT>. The guard
expression can refer to variables bound by the nested pattern:</P>

<PRE class=code>
fun f(x,y) where (x = y) = g x
  | f(x,y)               = h y</PRE>

<P>Guards can be nested into other patterns. Any side effect produced by the
guard expression occurs whenever the pattern is tried to be matched.</P>


<?php subsection("patterns-syntax", "Pattern syntax") ?>

<TABLE class=bnf>
  <TR>
    <TD> <I>atpat</I> </TD>
    <TD align="center">::=</TD>
    <TD> ... </TD>
    <TD> </TD>
  </TR>
  <TR valign=baseline>
    <TD></TD> <TD></TD>
    <TD> <TT>(</TT> <I>pat</I><SUB>1</SUB> <TT>|</TT> ... <TT>|</TT>
                    <I>pat</I><SUB><I>n</I></SUB> <TT>)</TT> </TD>
    <TD> alternative (<I>n</I>&ge;2) </TD>
  </TR>
  <TR></TR>
  <TR>
    <TD> <I>pat</I> </TD>
    <TD align="center">::=</TD>
    <TD> ... </TD>
    <TD> </TD>
  </TR>
  <TR>
    <TD></TD> <TD></TD>
    <TD> <I>pat</I> <TT>as</TT> <I>pat</I> </TD>
    <TD> layered (R) </TD>
  </TR>
  <TR>
    <TD></TD> <TD></TD>
    <TD> <TT>non</TT> <I>pat</I> </TD>
    <TD> negated </TD>
  </TR>
  <TR>
    <TD></TD> <TD></TD>
    <TD> <I>pat</I> <TT>where</TT> <I>atexp</I> </TD>
    <TD> guarded (L) </TD>
  </TR>
</TABLE>


<?php section("rec", "recursive definitions") ?>

<?php subsection("rec-declaration", "Recursive declarations") ?>

<P>SML only allows function expressions on the right hand side of <TT>val</TT>
<TT>rec</TT>. Alice is a bit more permissive. For example, one can construct
cyclic lists:</P>

<PRE class=code>
val xs = 1::2::xs</PRE>

<P>Or regular trees:</P>

<PRE class=code>
datatype tree = LEAF | BRANCH of tree * tree

val tree = BRANCH(BRANCH(tree,LEAF), tree)</PRE>

<P>The right-hand sides of recursive bindings may be any expressions that are
<EM>non-expansive</EM> (i.e. syntactic values) and match the corresponding
left-hand side patterns (statically). Unfounded recursion is legal, but
evaluates to <A href="futures.php3">futures</A> that cannot be eliminated:</P>

<PRE class=code>
val (x,y) = (y,x)</PRE>

<P>Note that the same data structures are constructable by explicit use of <A
href="futures.php3#promises">promises</A>.</P>


<?php subsection("rec-expression", "Recursive expressions") ?>

<P>Recursive values may be constructed directly without resorting to recursive 
declarations:</P>

<PRE class=code>
val l = rec xs => 1::2::xs</PRE>


<?php subsection("rec-syntax", "Recursive expression syntax") ?>

<TABLE class=bnf>
  <TR>
    <TD> <I>exp</I> </TD>
    <TD align="center">::=</TD>
    <TD> ... </TD>
    <TD> </TD>
  </TR>
  <TR>
    <TD></TD> <TD></TD>
    <TD> <TT>rec</TT> <I>pat</I> <TT>=></TT> <I>exp</I> </TD>
    <TD> recursion </TD>
  </TR>
</TABLE>

<P>Such <TT>rec</TT> expressions are expanded as a derived form:</P>

<TABLE class=bnf>
  <TR>
    <TD> <TT>rec</TT> <I>pat</I> <TT>=></TT> <I>exp</I> </TD>
    <TD> ==> </TD>
    <TD> <TT>let</TT> <TT>val</TT> <TT>rec</TT> <I>vid</I> <TT>as</TT> <I>pat</I>
    <TT>=</TT> <I>exp</I> <TT>in</TT> <I>vid</I> <TT>end</TT></TD>
  </TR>
</TABLE>

<P>where <I>vid</I> is a new identifier.</P>

<?php footing() ?>
