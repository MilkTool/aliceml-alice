<?php include("macros.php3"); ?>
<?php heading("The Socket structure",
	      "The <TT>Socket</TT> structure") ?>

<?php section("synopsis", "synopsis") ?>

  <PRE>
    signature SOCKET
    structure Socket : SOCKET
  </PRE>

  <P>
    This structure provides a simplified interface for creating INET socket
    based client/server applications.  <B>This interface is expected to change
    in a later release.</B>  Note that this structure is incompatible with
    the <TT>Socket</TT> structure defined by the Standard Basis Library.
  </P>

<?php section("import", "import") ?>

  <PRE>
    import signature SOCKET from "x-alice:/lib/system/SOCKET-sig"
    import structure Socket from "x-alice:/lib/system/Socket"
  </PRE>

<?php section("interface", "interface") ?>

  <PRE>
    signature SOCKET =
    sig
	type <A href="#socket">socket</A>
	type <A href="#t">t</A> = socket
	type <A href="#vector">vector</A> = string
	type <A href="#elem">elem</A> = char

	type <A href="#host">host</A> = string
	type <A href="#port">port</A> = int

	val <A href="#server">server</A> : port option * (socket * host * port -> unit) -> socket * port
	val <A href="#client">client</A> : host * port -> socket

	val <A href="#input1">input1</A> : socket -> char option
	val <A href="#inputN">inputN</A> : socket * int -> vector
	val <A href="#inputLine">inputLine</A> : socket -> vector
	val <A href="#output">output</A> : socket * vector -> unit
	val <A href="#output1">output1</A> : socket * char -> unit

	val <A href="#close">close</A> : socket -> unit
    end
  </PRE>

<?php section("description", "description") ?>

  <DL>
    <DT>
      <TT>type <A name="socket">socket</A></TT><BR>
      <TT>type <A name="t">t</A> = socket</TT>
    </DT>
    <DD>
      <P>The type of sockets.</P>
    </DD>

    <DT>
      <TT>type <A name="vector">vector</A> = string</TT><BR>
      <TT>type <A name="elem">elem</A> = char</TT>
    </DT>
    <DD>
      <P>The types of vectors and elements used for communication
	over sockets.</P>
    </DD>

    <DT>
      <TT>type <A name="host">host</A> = string</TT><BR>
      <TT>type <A name="port">port</A> = int</TT>
    </DT>
    <DD>
      <P>The types of host names and port numbers used for establishing
	socket connections.</P>
    </DD>

    <DT>
      <TT><A name="server">server</A> (<I>portOpt</I>, <I>acceptor</I>)</TT>
    </DT>
    <DD>
      <P>starts a server listening for connections.  If <I>portOpt</I> is
	<TT>SOME <I>port</I></TT>, makes the server listen on <I>port</I>
	if available, if it is <TT>NONE</TT>, selects a free port.
	Returns the socket with which one can close down the server and
	the actual port on which it listens.  Raises <TT>IO.Io</TT> if the
	a port was specified but not available.</P>
      <P>For every client that connects to the server, invokes</P>
      <PRE><I>acceptor</I> (<I>sock</I>, <I>host</I>, <I>port</I></PRE>
      <P>where <I>sock</I>, <I>host</I> and <I>port</I> are the socket
	with which to speak to the client, the client's host name and
	the port number on which the client connected, respectively.</P>
    </DD>

    <DT>
      <TT><A name="client">client</A> (<I>host</I>, <I>port</I>)</TT>
    </DT>
    <DD>
      <P>establishes a connection to a server listening on <I>host</I>
	on <I>port</I>.  Raises <TT>IO.Io</TT> if no connection could
	be established.  Returns the socket with which the client can
	speak to the server.</P>
    </DD>

    <DT>
      <TT><A name="input1">input1</A> <I>sock</I></TT>
    </DT>
    <DD>
      <P>receives a single character from <I>sock</I>.  If the socket was
	closed by the other end, returns <TT>NONE</TT>, else returns <TT>SOME
	<I>c</I></TT> where <I>c</I> is the character received.  Raises
	<TT>IO.Io</TT> if receiving failed.</P>
    </DD>

    <DT>
      <TT><A name="inputN">inputN</A> (<I>sock</I>, <I>n</I>)</TT>
    </DT>
    <DD>
      <P>receives at most <I>n</I> characters from <I>sock</I>.  If the
	returned string is shorter than <I>n</I> characters, then this
	indicates that the socket was closed by the other end.  Raises
	<TT>IO.Io</TT> if receiving failed.</P>
    </DD>

    <DT>
      <TT><A name="inputLine">inputLine</A> <I>sock</I></TT>
    </DT>
    <DD>
      <P>receives characters from <I>sock</I> until the next newline character
	(<TT>#"\n"</TT>) and returns them, including the newline character.
	If the returned string is empty, then this indicates that the socket
	was closed by the other end.  The last line is always terminates
	by a newline character, even if it did not end in one.  Raises
	<TT>IO.Io</TT> if receiving failed.</P>
    </DD>

    <DT>
      <TT><A name="output">output</A> (<I>sock</I>, <I>s</I>)</TT>
    </DT>
    <DD>
      <P>sends <I>s</I> to <I>sock</I>.  Raises <TT>IO.Io</TT> if sending
	failed.</P>
    </DD>

    <DT>
      <TT><A name="output1">output1</A> (<I>sock</I>, <I>c</I>)</TT>
    </DT>
    <DD>
      <P>sends <I>c</I> to <I>sock</I>.  Raises <TT>IO.Io</TT> if sending
	failed.</P>
    </DD>

    <DT>
      <TT><A name="close">close</A> <I>sock</I></TT>
    </DT>
    <DD>
      <P>closes <I>sock</I>.  If <I>sock</I> was returned by <A href="#server"
	><TT>server</TT></A>, shuts down the server, else closes an active
	connection.</P>
    </DD>
  </DL>

<?php footing() ?>
