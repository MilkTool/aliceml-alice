<?php include("macros.php3"); ?>
<?php heading("Interactive Top-level", "interactive\ntop-level") ?>

<?php section("overview", "overview") ?>

<P>The interactive top-level provides an interpreter-style environment that
allows entering and evaluating programs from an interactive prompt.</P>

<P>The interactive top-level is designed to work with standard <A
href="#emacs">Emacs modes</A> for SML.</P>


<?php section("synopsis", "synopsis") ?>

<DL>
  <DT><TT>alice</TT> [<I>&lt;options&gt;</I>]</DT>
</DL>


<?php section("description", "description") ?>

<P>After preloading several components, the system will enter an interactive
input-eval-output session. It allows entering arbitrary Alice components. Input
can stretch several lines, it is terminated by a line containing a semicolon as
its last character. The system will print the results and inferred types
for the given declarations, or an appropriate error message.</P>

<P>Note that the <TT>inspect</TT> function from the <A
href="library/inspector.php3">Inspector</A> is available to browse complex
results conveniently.</P>

<P>Like in other SML systems, there also is the special purpose function</P>

<PRE class=code>
use : string -> unit</PRE>

<P>which, given the name of an Alice source file, will process this file as if
it had been fed as direct input.</P>

<P>An interactive session can be terminated by typing an end-of-file character
(Ctrl-D on Unix systems, Ctrl-Z on Windows systems).</P>


<?php subsection("description-import", "imports") ?>

<P>Each input in the interactive toplevel actually is a <A
href="components.php3">component</A>. This implies that import announcements
can be entered to link in separately compiled components from arbitrary
URIs:</P>

<PRE class=code>
- import structure Foo from "http://www.mydomain.net/Foo";
### loaded signature from http://www.mydomain.net/Foo
structure Foo : FOO = Foo
- </PRE>

<P>For convenience, it is possible to abbreviate import announcements as
follows in the interactive top-level:</P>

<PRE class=code>
- import "http://www.mydomain.net/Foo";
### loaded signature from http://www.mydomain.net/Foo
structure Foo : FOO = Foo
- </PRE>

<P>Such an announcement will import all items exported by the corresponding
component.</P>

<P>All <A href="library/">library</A> components (except the <A
href="library/#gtk">Gtk</A> library) are pre-imported in the interactive
top-level and will get loaded automatically on demand.</A>



<?php section("options", "options") ?>

<P>The same command line options are supported as for the standalone <A
href="compiler.php3">batch compiler</A>.</P>



<?php section("emacs", "emacs") ?>

<P>In order to use the interactive Alice top-level from within Emacs, the
following set-up is necessary.</P>

  <P>First make sure that the environment variables <TT>OZHOME</TT> and <TT>STOCKHOME</TT>
    point to the installation directory of the Mozart system and
    the Alice system, respectively.</P>

  <P>You have to decide to either use SML mode version 3.3 or SML mode
    3.9.5. The 3.3 mode featured below is patched for Alice specific syntax
    extensions.</P>

  <P>To use SML mode version 3.3, install the
    <A HREF="sml-mode-3.3.tgz">patched mode</A>
     either to your global <TT>site-lisp</TT> or to your local <TT>elisp</TT> directory.
     Depending on your selection, add the following
     lines to your <TT>.emacs</TT> file:</P>
<PRE class=code>
;; Necessary only if not already in load-path
(setq load-path (cons "/this/is/the/mode/directory" load-path))
;; Enable sml mode
(require 'sml-site)
;; Enable fontification
(require 'sml-font)</PRE>

  <P>To use SML mode version 3.9.5, extract the
     <A HREF="sml-mode-3.9.5.tgz">mode archive file</A>
     and follow the installation instructions given in
    <TT>INSTALL</TT>. Then invoke <TT>load-library</TT> with argument <TT>sml-proc</TT>.
    Afterwards, invoke <TT>customize-group</TT> with argument <TT>sml</TT> and adjust the
    settings <TT>sml-program-name</TT> to <TT>alice</TT>.</P>


<?php footing() ?>
