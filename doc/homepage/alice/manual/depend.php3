<?php include("macros.php3"); ?>
<?php heading("Dependency analyzer", "dependency\nanalyzer") ?>

<?php section("overview", "overview") ?>

<P>The dependency analizyer generates output suitable for inclusion in a
<TT>Makefile</TT>, in order to control recompilation of a set of source
files.</P>


<?php section("synopsis", "synopsis") ?>

<DL>
  <DT><TT>alicedep</TT> <I>&lt;file&gt;</I> ... <TT>&gt;Makefile.depend</TT></DT>
</DL>


<?php section("description", "description") ?>

<P>The analyzer tool takes a list of source files and writes
<TT>make</TT>-compatible dependency information to standard output.</P>

<P>For each given source file the tool generates one <TT>make</TT>-style rule.
The rule's target is the path of the file relative to the current working
directory, with an appropriate extension. To determine the rule's prerequisites
the tool scans all <A href="components.php3#source">import announcements</A> in
the source file. Imports from URIs that have a scheme different from
<TT>file:</TT> are ignored (note that URIs without a scheme are implicitly
assumed to have file schemes). For each file URI an appropriate prerequisite is
generated. Relative paths are resolved with respect to the location of the
source file.</P>

<?php footing() ?>
