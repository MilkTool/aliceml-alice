<?php include("macros.php3"); ?>
<?php heading("The Url structure", "The <TT>Url</TT> structure") ?>

<?php section("synopsis", "synopsis") ?>

  <PRE>
    signature URL
    structure Url : URL
  </PRE>

  <P>
    This structure provides functions for parsing URLs, extracting URL
    constituents, constructing URLs from constituents and resolving
    relative URLs.  Absolute and relative URLs are supported.  URL parsing
    conforms to RFCs 1738 and 1808 with one exception:  We allow URLs
    to contain single-letter <EM>device</EM> constituents, which is a
    mostly-conservative common extension.  Device letters enable the
    representation of Windows-style path and file names as URLs.
  </P>

<?php section("import", "import") ?>

  <PRE>
    import signature URL from "x-alice:/lib/utility/URL-sig"
    import signature Url from "x-alice:/lib/utility/Url"
  </PRE>

<?php section("interface", "interface") ?>

  <PRE>
    signature URL =
    sig
	eqtype <A href="#url">url</A>
	type <A href="#t">t</A> = url

	type <A href="#scheme">scheme</A> = string option
	type <A href="#authority">authority</A> = string option
	type <A href="#device">device</A> = char option
	type <A href="#path">path</A> = string list
	type <A href="#query">query</A> = string option
	type <A href="#fragment">fragment</A> = string option

	exception <A href="#Malformed">Malformed</A>

	val <A href="#empty">empty</A>: url
	val <A href="#fromString">fromString</A>: string -> url
	val <A href="#toString">toString</A>: url -> string
	val <A href="#toStringRaw">toStringRaw</A>: url -> string
	val <A href="#isAbsolute">isAbsolute</A>: url -> bool
	val <A href="#resolve">resolve</A>: url -> url -> url
	val <A href="#equal">equal</A>: url * url -> bool
	val <A href="#compare">compare</A>: url * url -> order
	val <A href="#hash">hash</A>: url -> int

	val <A href="#getScheme">getScheme</A>: url -> scheme
	val <A href="#getAuthority">getAuthority</A>: url -> authority
	val <A href="#getDevice">getDevice</A>: url -> device
	val <A href="#isAbsolutePath">isAbsolutePath</A>: url -> bool
	val <A href="#getPath">getPath</A>: url -> path
	val <A href="#getQuery">getQuery</A>: url -> query
	val <A href="#getFragment">getFragment</A>: url -> fragment

	val <A href="#setScheme">setScheme</A>: url * scheme -> url
	val <A href="#setAuthority">setAuthority</A>: url * authority -> url
	val <A href="#setDevice">setDevice</A>: url * device -> url
	val <A href="#makeAbsolutePath">makeAbsolutePath</A>: url -> url
	val <A href="#makeRelativePath">makeRelativePath</A>: url -> url
	val <A href="#setPath">setPath</A>: url * path -> url
	val <A href="#setQuery">setQuery</A>: url * query -> url
	val <A href="#setFragment">setFragment</A>: url * fragment -> url
    end
  </PRE>

<?php section("description", "description") ?>

  <DL>
    <DT>
      <TT>type <A name="url">url</A></TT><BR>
      <TT>type <A name="t">t</A> = url</TT>
    </DT>
    <DD>
      <P>The type of parsed URLs.  Values of this type represent absolute
	as well as relative URLs.  The equivalence test using <TT>=</TT>
	is reliable for absolute URLs only.  URL values are always
	normalized.</P>
    </DD>

    <DT>
      <TT>type <A name="scheme">scheme</A> = string option</TT><BR>
      <TT>type <A name="authority">authority</A> = string option</TT><BR>
      <TT>type <A name="device">device</A> = char option</TT><BR>
      <TT>type <A name="path">path</A> = string option</TT><BR>
      <TT>type <A name="query">query</A> = string option</TT><BR>
      <TT>type <A name="fragment">fragment</A> = string option</TT><BR>
    </DT>
    <DD>
      <P>The types of the respective URL constituents.  Option types are
	used to indicate the presence or absence of optional indiviual
	constituents.  Device letters are always normalized to their
	lower-case equivalent, that is, are always in the range
	<TT>#"a"</TT> ... <TT>#"z"</TT> if present.  The absent path
	is equivalent to the empty path, represented by <TT>nil</TT>.
	Path constituents can contain empty strings.  The last element
	of a path constituent being the empty string represents the
	absence of a file name constituent (that is, the string
	representation of the path constituent ends in a slash).
	Constituents use no encoding except for the query, which has
	to encode <TT>#"="</TT> and <TT>#"&"</TT>.  The only URL
	constituent for which there is no explicit type defined is
	the flag whether the path constituent is absolute or relative,
	that is, whether its string representation starts with a slash
	or not.</P>
    </DD>

    <DT>
      <TT>exception <A name="Malformed">Malformed</A></TT>
    </DT>
    <DD>
      <P>indicates that a string is not a well-formed URL in string
	representation, or that a URL constituent has no well-formed
	string representation.</P>
    </DD>

    <DT>
      <TT><A name="empty">empty</A></TT>
    </DT>
    <DD>
      <P>represents the empty URL, which has all constituents absent resp.
	empty.  Its string representation is the empty string.</P>
    </DD>

    <DT>
      <TT><A name="fromString">fromString</A> <I>s</I></TT>
    </DT>
    <DD>
      <P>parses <I>s</I> as a URL in string representation, raising
	<TT>Malformed</TT> if it is not well-formed.  The resulting URL
	is normalized and returned.</P>
    </DD>

    <DT>
      <TT><A name="toString">toString</A> <I>url</I></TT>
    </DT>
    <DD>
      <P>converts <I>url</I> into its string representation.  Constituents
	are encoded as necessary.</P>
<!--** when may toString u1 = toString u2 for u1 <> u2? -->
    </DD>

    <DT>
      <TT><A name="toStringRaw">toStringRaw</A> <I>url</I></TT>
    </DT>
    <DD>
      <P>converts <I>url</I> into its string representation, without
	encoding any characters.  Only reliable for URLs that represent
	local files or paths (that is, where scheme, authority, query
	and fragment are all absent).</P>
    </DD>

    <DT>
      <TT><A name="isAbsolute">isAbsolute</A> <I>url</I></TT>
    </DT>
    <DD>
      <P>returns <TT>true</TT> if <I>url</I> represents an absolute URL,
	<TT>false</TT> otherwise.  An URL is absolute if at least one
	of scheme or device is present or if the path constituent is
	an absolute path or starts with <TT>"."</TT>, <TT>".."</TT> or
	the character <TT>#"~"</TT>.</P>
    </DD>

    <DT>
      <TT><A name="resolve">resolve</A> <I>baseUrl</I> <I>relUrl</I></TT>
    </DT>
    <DD>
      <P>resolves <I>relUrl</I> with respect to <I>baseUrl</I> and returns
	the resulting URL.  <I>baseUrl</I> should be an absolute URL,
	although this is not required.</P>
    </DD>

    <DT>
      <TT><A name="equal">equal</A> (<I>url1</I>, <I>url2</I>)</TT>
    </DT>
    <DD>
      <P>returns <TT>true</TT> if <I>url1</I> and <I>url2</I> represent
	the same URL, <TT>false</TT> otherwise.  Is identical to</P>
      <PRE><I>url1</I> = <I>url2</I></PRE>
    </DD>

    <DT>
      <TT><A name="compare">compare</A> (<I>url1</I>, <I>url2</I>)</TT>
    </DT>
    <DD>
      <P>is equivalent to</P>
      <PRE>String.compare (toString <I>url1</I>, toString <I>url2</I>)</PRE>
    </DD>

    <DT>
      <TT><A name="hash">hash</A> <I>url</I></TT>
    </DT>
    <DD>
      <P>returns a hash value for <I>url</I>.</P>
    </DD>

    <DT>
      <TT><A name="getScheme">getScheme</A> <I>url</I></TT><BR>
      <TT><A name="getAuthority">getAuthority</A> <I>url</I></TT><BR>
      <TT><A name="getDevice">getDevice</A> <I>url</I></TT><BR>
      <TT><A name="getPath">getPath</A> <I>url</I></TT><BR>
      <TT><A name="getQuery">getQuery</A> <I>url</I></TT><BR>
      <TT><A name="getFragment">getFragment</A> <I>url</I></TT>
    </DT>
    <DD>
      <P>return the corresponding constituents of <I>url</I>.  For optional
	constituents, return <TT>SOME _</TT> if the constituent is present,
	<TT>NONE</TT> otherwise.</P>
    </DD>

    <DT>
      <TT><A name="isAbsolutePath">isAbsolutePath</A> <I>url</I></TT>
    </DT>
    <DD>
      <P>returns <TT>true</TT> if the path constituent of <I>url</I>
	represents an absolute path, that is, a path whose string
	representation starts with a slash, <TT>false</TT> otherwise.</P>
    </DD>

    <DT>
      <TT><A name="setScheme">setScheme</A> (<I>url</I>, <I>x</I>)</TT><BR>
      <TT><A name="setAuthority">setAuthority</A> (<I>url</I>, <I>x</I>)</TT><BR>
      <TT><A name="setDevice">setDevice</A> (<I>url</I>, <I>x</I>)</TT><BR>
      <TT><A name="setQuery">setQuery</A> (<I>url</I>, <I>x</I>)</TT>
    </DT>
    <DD>
      <P>return a URL with the corresponding constituent replaced.
	If <I>x</I> is <TT>SOME _</TT>, this causes the constituent to
	be present in the result, if it is <TT>NONE</TT>, the constituent
	is absent in the result.  Raise <TT>Malformed</TT> if <I>x</I>
	is not a valid value for the constituent.</P>
    </DD>

    <DT>
      <TT><A name="makeAbsolutePath">makeAbsolutePath</A> <I>url</I></TT><BR>
      <TT><A name="makeRelativePath">makeRelativePath</A> <I>url</I></TT>
    </DT>
    <DD>
      <P>return a URL equivalent to <I>url</I> except that its path
	constituent is absolute resp. relative.</P>
    </DD>

    <DT>
      <TT><A name="setPath">setPath</A> (<I>url</I>, <I>x</I>)</TT><BR>
      <TT><A name="setFragment">setFragment</A> (<I>url</I>, <I>x</I>)</TT>
    </DT>
    <DD>
      <P>return a URL with the corresponding constituent replaced.
	If <I>x</I> is <TT>SOME _</TT>, this causes the constituent to
	be present in the result, if it is <TT>NONE</TT>, the constituent
	is absent in the result.</P>
    </DD>
  </DL>

<?php footing() ?>
