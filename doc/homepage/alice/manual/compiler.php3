<?php include("macros.php3"); ?>
<?php heading("Batch compiler", "batch\ncompiler") ?>

<?php section("overview", "overview") ?>

<P>The standalone batch compiler is used to produce <A
href="components.php3">components</A> from source files.</A>


<?php section("synopsis", "synopsis") ?>

<DL>
  <DT><TT>alicec</TT> [<I>&lt;options&gt;</I>] [<TT>-c</TT>]
    <I>&lt;input file&gt;</I> [<TT>-o</TT> <I>&lt;output file&gt;</I>]</DT>
<!--
  <DT><TT>alicec</TT> [<I>&lt;options&gt;</I>] <TT>-x</TT>
    <I>&lt;input file&gt;</I> [<TT>-o</TT> <I>&lt;output file&gt;</I>]</DT>
-->
</DL>


<?php section("description", "description") ?>

<P>The <I>&lt;input file&gt;</I> is compiled as an Alice source program and a
corresponding component is written as output.  If <I>&lt;output file&gt;</I> is
given, it is used as the output file name, else the basename of <I>&lt;input
file&gt;</I> is used with <TT>.ozf</TT> as extension. Compiled components can
be executed by invoking the <A href="machine.php3">virtual machine</A>.</P>

<!--
<P>In the second form, <I>&lt;input file&gt;</I> is compiled as an Alice source
and an executable component is written as output.  If <I>&lt;output
file&gt;</I> is given, it is used as the output file name, else the basename of
<I>&lt;input file&gt;</I> is used, without extension.</P>
-->

<P>To compile a component, the compiler requires access to all imported
component files. If one does not exist, but a source file for it
(i.e., a file with same name but ending in <TT>.aml</TT>, <TT>.sml</TT>,
or <TT>.sig</TT>) can be located, the compiler first invokes itself
recursively to compile the imported component.  If a component <EM>does</EM>
exist, the compiler does <EM>not</EM> perform any check to verify whether it is
up-to-date. External tools like <TT>make</TT> have to be used, in conjunction
with the <A href="depend.php3">dependency analyzer</A>, to ensure proper
recompilation if necessary.</P>

<P>It is possible to import Mozart components (<A
href="http://www.mozart-oz.org/documentation/apptut/node3.html">Mozart
"functors"</A>), as long as they are augmented with an Alice signature file. See
the <A href="interop.php3">interop section</A> for details.</P>


<?php section("options", "options") ?>

<DL>
  <DT><TT>--version</TT></DT>
  <DD><P>Print compiler version.</P></DD>
  <DT><TT>--(no-)dump-phases</TT></DT>
  <DD><P>Trace compilation phases.</P></DD>
  <DT><TT>--(no-)dump-elaboration-sig</TT></DT>
  <DD><P>Output component's export signature.</P></DD>
  <DT><TT>--(no-)warn-shadowing</TT></DT>
  <DD><P>Warn about shadowing of identifiers (off by default,
  gives a lot of spurious warnings).</P></DD>
</DL>


<?php footing() ?>
