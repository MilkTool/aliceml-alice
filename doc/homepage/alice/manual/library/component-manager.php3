<?php include("macros.php3"); ?>
<?php heading("The COMPONENT_MANAGER signature",
	      "The <TT>COMPONENT_MANAGER</TT> signature") ?>

<?php section("synopsis", "synopsis") ?>

  <PRE>
    signature COMPONENT_MANAGER</PRE>

  <P>
    A <EM>component manager</EM> is responsible for loading and linking
    components.  To this aim, every component manager maintains its
    <EM>component table</EM>, which is a mapping from URLs to components.
    All loading, linking, evaluating, and signature matching is performed
    lazily.  For this reason components are initially returned as by-need
    futures, which can either be bound (on success) or failed.  See the
    description of exception <TT><A href="component.php3#Failure"
    >Component.Failure</A></TT> to see how these "asynchronous"
    exceptions are handled.
  </P>

  <P>
    See also:
    <A href="component.php3"><TT>Component</TT></A>
  </P>

<?php section("import", "import") ?>

  <PRE>
    import signature COMPONENT_MANAGER from "x-alice:/lib/system/COMPONENT_MANAGER-sig"</PRE>

<?php section("interface", "interface") ?>

  <PRE>
    signature COMPONENT_MANAGER =
    sig
	exception <A href="#Conflict">Conflict</A>

	type <A href="#component">component</A>

	functor <A href="#Eval-fn">Eval</A>(val component : component
		     val url : <A href="url.php3#t">Url.t</A>
		     signature S) : S

	functor <A href="#Link-fn">Link</A>(val url : <A href="url.php3#t">Url.t</A>
		     signature S) : S

	functor <A href="#Enter-fn">Enter</A>(val url: <A href="url.php3#t">Url.t</A>
		      signature S
		      structure X : S) : any

	val <A href="#link">link</A> : <A href="url.php3#t">Url.t</A> -> component
	val <A href="#enter">enter</A> : <A href="url.php3#t">Url.t</A> * component -> unit
	val <A href="#lookup">lookup</A> : <A href="url.php3#t">Url.t</A> -> component option

	val <A href="#start">start</A> : <A href="url.php3#t">Url.t</A> -> unit
    end</PRE>

<?php section("description", "description") ?>

  <DL>
    <DT>
      <TT>exception <A name="Conflict">Conflict</A></TT>
    </DT>
    <DD>
      <P>indicates an attempt to enter a component in the component table
	while some component was already registered under that name.</P>
    </DD>

    <DT>
      <TT>type <A name="component">component</A></TT>
    </DT>
    <DD>
      <P>The type of components this component manager operates on.
	Usually equivalent to <TT><A href="component.php3#component"
	>Component.component</A></TT>.</P>
    </DD>

    <DT>
      <TT><A name="Eval-fn">Eval</A>(val component = <I>comp</I> val url = <I>url</I> signature S = <I>S</I>)</TT>
    </DT>
    <DD>
      <P>evaluates <I>comp</I>, rooted at <I>url</I>, in the context of
	the component table managed by this component manager, and returns
	the computed structure.  Raises <TT><A href="component.php3#Mismatch"
	>Component.Mismatch</A></TT> if the computed structure does not
	match&nbsp;<I>S</I>, <EM>after</EM> evaluating the declarations
	contained in <I>comp</I>.  Note that no entry for <I>url</I> is
	created in the component table, but entries may be created for
	components imported (directly or indirectly) by <I>comp</I>.
	Relative import URLs in <I>comp</I> are resolved using <I>url</I>
	as a base url, which should be absolute.</P>
    </DD>

    <DT>
      <TT><A name="Link-fn">Link</A>(val url = <I>url</I> signature S = <I>S</I>)</TT>
    </DT>
    <DD>
      <P>returns a new by-need future that, when triggered, causes the
	component from <I>url</I> to be linked and evaluated and its signature
	to be matched against&nbsp;<I>S</I>.  The future is then bound to
	the structure computed by the component.  If the component table has
	no entry for <I>url</I> yet, a new entry is created immediately.</P>
    </DD>

    <DT>
      <PRE><A name="Enter-fn">Enter</A>(val url = <I>url</I>
      signature S = <I>S</I>
      structure X = <I>X</I>)</PRE>
    </DT>
    <DD>
      <P>enters an evaluated component with export structure&nbsp;<I>X</I>
	of signature&nbsp;<I>S</I> into the component table, under name
	<I>url</I>.  Raises <TT><A href="#Conflict">Conflict</A></TT> if
	the component table already had an entry for <I>url</I>.</P>
    </DD>

    <DT>
      <TT><A name="link">link</A> <I>url</I></TT>
    </DT>
    <DD>
      <P>returns a new by-need future that, when triggered, causes the
	component from <I>url</I> to be linked and evaluated.  The future
	is then bound to the component.  If the component table has no entry
	for <I>url</I> yet, a new entry is created immediately.</P>
    </DD>

    <DT>
      <TT><A name="enter">enter</A> (<I>url</I>, <I>comp</I>)</TT>
    </DT>
    <DD>
      <P>enters <I>comp</I> into the component table, under name <I>url</I>.
	Raises <TT><A href="#Conflict">Conflict</A></TT> if the component
	table already had an entry for <I>url</I>.</P>
    </DD>

    <DT>
      <TT><A name="lookup">lookup</A> <I>url</I></TT>
    </DT>
    <DD>
      <P>returns <TT>SOME <I>comp</I></TT>, if the component table has
	an entry mapping <I>url</I> to <I>comp</I>, or <TT>NONE</TT>
	otherwise.</P>
    </DD>

    <DT>
      <TT><A name="start">start</A> <I>url</I></TT>
    </DT>
    <DD>
      <P>links and evaluates the component at <I>url</I> eagerly.
	Raises <TT><A href="component.php3#Failure">Component.Failure</A></TT>
	if this fails.</P>
    </DD>
  </DL>

<?php footing() ?>
