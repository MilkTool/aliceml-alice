<?php include("macros.php3"); ?>
<?php heading("Static linker", "static\nlinker") ?>

<?php section("overview", "overview") ?>

<P>The static linker allows to bundle a component together with (a subset of)
its direct and indirect imports. It can also be used to inspect import and
export signatures of components.</P>


<?php section("synopsis", "synopsis") ?>

<DL>
  <DT><TT>alicelink</TT> [<I>&lt;options&gt;</I>]
    <I>&lt;root url&gt;</I> [<I>&lt;options&gt;</I>]</DT>
  <DT><TT>alicelink</TT> [<I>&lt;options&gt;</I>] <TT>-d</TT>
    <I>&lt;root url&gt;</I></DT>
</DL>


<?php section("description", "description") ?>

<P>Int the first form, the linker takes the root component from <I>&lt;root
url&gt;</I>, bundles it with the components it depends on, and writes an output
component that has the same export signature as the root component.  Components
can be selected for inclusion depending on the URL they reside on.</P>

<P>When the URL of a component is tested for inclusion, it is tested in order
against the given <TT>--include</TT> and <TT>--exclude</TT> option prefixes
(see <A href="#options">below</A>), where string prefix matching is used.  The
first match decides. If no <TT>--include</TT> or <TT>--exclude</TT> is given,
no component will be included at all.  In particular, one has to make sure that
the root component is included.</P>

<P>Bundles can include Mozart components (<A
href="http://www.mozart-oz.org/documentation/apptut/node3.html">Mozart
"functors"</A>).  Native components (<A
href="http://www.mozart-oz.org/documentation/foreign/">Mozart native
"functors"</A>) cannot be part of a component bundle. They are implicitly
considered excluded.</P>

<P>In the second form, the linker just prints the import and export signatures
of the component at <I>&lt;root url&gt;</I> to standard output.</P>

<?php subsection("description-example", "example") ?>

<P>A typical application of the linker is to link all components imported
using relative imports from the same directory as or a subdirectory
of the root component.  The following command line accomplishes this
for a root component <TT>Foo</TT>:</P>

<PRE class=code>
alicelink -v --include ./ ./Foo -o LinkedFoo.ozf</PRE>


<?php section("options", "options") ?>

<DL>
  <DT><TT>-?</TT>, <TT>-h</TT>, <TT>--help</TT>, <TT>--usage</TT></DT>
  <DD><P>Print usage information.</P></DD>
  <DT><TT>-o</TT> &lt;<I>file</I>&gt;,
    <TT>--output</TT> &lt;<I>file</I>&gt;</DT>
  <DD><P>Specify where to write the output component.
    If omitted, do not produce any output.</P></DD>
  <DT><TT>-v</TT>, <TT>--verbose</TT></DT>
  <DD><P>Print messages on activities performed.</P></DD>
  <DT><TT>-d</TT>, <TT>--dumpsig</TT></DT>
  <DD><P>Dump import/export signatures of resulting component, or
    of root component if no ouput file has been specified.</P></DD>
  <DT><TT>--include</TT> &lt;<I>url</I>&gt;<TT>,</TT>...<TT>,</TT>&lt;<I
    >url</I>&gt;</DT>
  <DD><P>Include components with these URL prefixes.</P></DD>
  <DT><TT>--exclude</TT> &lt;<I>url</I>&gt;<TT>,</TT>...<TT>,</TT>&lt;<I
    >url</I>&gt;</DT>
  <DD><P>Exclude components with these URL prefixes.</P></DD>
  <DT><TT>--rewrite</TT> &lt;<I>rule</I>&gt;<TT>,</TT>...<TT>,</TT>&lt;<I
    >rule</I>&gt;</DT>
  <DD><P>Specifies how to replace import URL prefixes in resulting component,
    where a RULE is of the form &lt;<I>from</I>&gt;<TT>=</TT>&lt;<I
    >to</I>&gt;.</P></DD>
</DL>


<?php footing() ?>
