<?php include("macros.php3"); ?>
<?php heading("The Component structure",
	      "The <TT>Component</TT> structure") ?>

<?php section("synopsis", "synopsis") ?>

  <PRE>
    signature COMPONENT
    structure Component : COMPONENT</PRE>

  <P>
    This structure provides components as first-class entities and
    operations on them.  We speak of unevaluated and evaluated components.
    An <EM>unevaluated</EM> component is a component which has not yet been
    linked and applied, that is, its declarations have not been executed.
    An <EM>evaluated</EM> component is similar to a package: it has empty
    import announcements, cannot be applied to produce side-effects, and
    as such is just a pair of a structure and its (export) signature.
  </P>

  <P>
    The linking and evaluation of components takes place in <EM>component
    managers</EM>.
  </P>

  <P>
    If the environment variable <TT>ALICE_TRACE_COMPONENT</TT> is set,
    then trace messages concerning link failures of native components
    and type-checking and evaluation of components will be printed to
    the standard error output stream <TT>TextIO.stdErr</TT>.
  </P>

  <P>
    See also:
    <A href="component-manager.php3"><TT>COMPONENT_MANAGER</TT></A>,
    <A href="resolver.php3"><TT>Resolver</TT></A>,
    <A href="package.php3"><TT>Package</TT></A>,
    <A href="pickle.php3"><TT>Pickle</TT></A>
  </P>

<?php section("import", "import") ?>

  <PRE>
    import structure Component from "x-alice:/lib/system/Component"
    import signature COMPONENT from "x-alice:/lib/system/COMPONENT-sig"</PRE>

<?php section("interface", "interface") ?>

  <PRE>
    signature COMPONENT =
    sig
	type <A href="#component">component</A>
	type <A href="#t">t</A> = component

	exception <A href="#Sited">Sited</A>
	exception <A href="#Corrupt">Corrupt</A>

	exception <A href="#Mismatch">Mismatch</A> of {component : <A href="url.php3#t">Url.t</A>,
			       request : <A href="url.php3#t">Url.t</A> option,
			       cause : Inf.mismatch}
	exception <A href="#Eval">Eval</A> of exn
	exception <A href="#Failure">Failure</A> of <A href="url.php3#t">Url.t</A> * exn

	val <A href="#extension">extension</A>: string

	functor <A href="#Create">Create</A>(signature S  structure X : S) :
	    sig  val component : component  end

	val <A href="#load">load</A>: <A href="url.php3#t">Url.t</A> -> component
	val <A href="#save">save</A>: string * component -> unit
	val <A href="#inf">inf</A>: component -> Inf.t option

	functor <A href="#MkManager">MkManager</A>() : COMPONENT_MANAGER where type component = component
    end</PRE>

<?php section("description", "description") ?>

  <DL>
    <DT>
      <TT>type <A name="component">component</A></TT><BR>
      <TT>type <A name="t">t</A> = component</TT>
    </DT>
    <DD>
      <P>The type of first-class components.</P>
    </DD>

    <DT>
      <TT>exception <A name="Sited">Sited</A></TT>
    </DT>
    <DD>
      <P>used by the <TT>save</TT> operation to indicate that a first-class
	component contains sited data structures.  This exception is never
	raised directly; it only appears as the <TT>cause</TT> of an
	<TT>IO.Io</TT> exception.</P>
    </DD>

    <DT>
      <TT>exception <A name="Corrupt">Corrupt</A></TT>
    </DT>
    <DD>
      <P>used by the <TT>load</TT> operation to indicate that the contents
	of a file did not represent a well-formed pickled component.
	This exception is never raised directly; it only appears as the
	<TT>cause</TT> of an <TT>IO.Io</TT> exception.</P>
    </DD>

    <DT>
      <TT>exception <A name="Mismatch">Mismatch</A> of
	{component : <A href="url.php3#t">Url.t</A>,
	 request : <A href="url.php3#t">Url.t</A> option,
	 cause : Inf.mismatch}</TT>
    </DT>
    <DD>
      <P>indicates a signature mismatch during dynamic linking.
	<TT>component</TT> is the URL of the component whose export
	signature did not meet the requirements of the requestor
	given by <TT>request</TT>.  A requestor of <TT>NONE</TT>
	indicates an request made programmatically.  The <TT>cause</TT>
	is the mismatch reported by the used signature-checking facility.</P>
    </DD>

    <DT>
      <TT>exception <A name="Eval">Eval</A> of exn</TT>
    </DT>
    <DD>
      <P>indicates that a component raised an exception during
	initialization, that is, while its declarations were being
	evaluated.  This is never raised directly, but packaged in
	a <TT><A href="#Failure">Failure</A></TT> exception instead.</P>
    </DD>

    <DT>
      <TT>exception <A name="Failure">Failure</A> of <A href="url.php3#t">Url.t</A> * exn</TT>
    </DT>
    <DD>
      <P>indicates that the loading, evaluating or signature matching
	of a component failed.  The URL is that of the component.  If
	loading failed, the exception is an <TT>IO.Io</TT> exception.
	If evaluating failed, the exception is an <TT><A href="#Eval">Eval</A
	></TT> exception.  If signature matching failed, the exception is a
	<TT><A href="#Mismatch">Mismatch</A></TT> exception.</P>
    </DD>

    <DT>
      <TT><A name="extension">extension</A></TT>
    </DT>
    <DD>
      <P>is the string used on the current platform as extension part to
	name files containing pickled components.  This does not include
	the period commonly used to separate file names' base and extension
	parts.</P>
    </DD>

    <DT>
      <TT><A name="Create">Create</A>(signature S = <I>S</I>  structure X = <I>X</I>)</TT>
    </DT>
    <DD>
      <P>returns an evaluated component (as <TT>val component</TT> of the
	resulting structure) representing structure&nbsp;<TT><I>X</I></TT>
	with export signature&nbsp;<TT><I>S</I></TT>.</P>
    </DD>

    <DT>
      <TT><A name="load">load</A> <I>url</I></TT>
    </DT>
    <DD>
      <P>localizes <TT><I>url</I></TT> using the <A href="resolver.php3"
	>resolver</A> initialized from the <TT>ALICE_LOAD</TT> environment
	variable and attempts to unpickle a first-class component from the
	file found, which it returns upon success.  Raises <TT>IO.Io</TT>
	if resolving, loading or unpickling fails.  If resolving fails, the
	<TT>cause</TT> is <TT>Option</TT>.</P>
    </DD>

    <DT>
      <TT><A name="save">save</A> (<I>s</I>, <I>comp</I>)</TT>
    </DT>
    <DD>
      <P>pickles <TT><I>comp</I></TT> and saves it to a new file with
	name&nbsp;<TT><I>s</I></TT>.  Raises <TT>IO.Io</TT> if pickling
	or saving fails.</P>
    </DD>

    <DT>
      <TT><A name="inf">inf</A> <I>comp</I></TT>
    </DT>
    <DD>
      <P>retrieves the export signature from <TT><I>comp</I></TT>.  May return
	<TT>NONE</TT> if the component represented by <TT><I>comp</I></TT>
	has no explicit export signature, as may be the case for a native
	or foreign component (that is, a component not implemented in
	Alice).</P>
    </DD>

    <DT>
      <TT><A name="MkManager">MkManager</A>()</TT>
    </DT>
    <DD>
      <P>returns a new component manager with a component table empty but
	for the virtual machine's built-in components and those components
	that had to be loaded to initialize the system's boot component
	manager.  The returned component manager uses <TT><A href="#load"
	>load</A></TT> to load its components, and as such the corresponding
	resolver.</P>
    </DD>
  </DL>

<?php footing() ?>
