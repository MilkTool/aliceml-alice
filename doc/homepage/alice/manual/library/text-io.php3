<?php include("macros.php3"); ?>
<?php heading("The TextIO structure", "The <TT>TextIO</TT> structure") ?>

<?php section("synopsis", "synopsis") ?>

  <PRE>
    signature TEXT_IO
    structure TextIO : TEXT_IO
  </PRE>

  <P>
    The Standard ML Basis'
    <A href="http://SML.sourceforge.net/Basis/text-io.html"><TT>TextIO</TT></A> structure.
  </P>

  <P>See also:
    <A href="bin-io.php3"><TT>BinIO</TT></A>,
    <A href="imperative-io.php3"><TT>IMPERATIVE_IO</TT></A>,
    <A href="text-stream-io.php3"><TT>TEXT_STREAM_IO</TT></A>,
    <A href="text-prim-io.php3"><TT>TextPrimIO</TT></A>
  </P>

<?php section("import", "import") ?>

  <P>
    Imported implicitly.
  </P>

<?php section("interface", "interface") ?>

  <PRE>
    signature TEXT_IO =
    sig
	structure StreamIO : TEXT_STREAM_IO

	type vector = string
	type elem   = char
	type instream
	type outstream

	val stdIn :        instream
	val stdOut :       outstream
	val stdErr :       outstream

	val openIn :       string -> instream
	val input :        instream -> string
	val input1 :       instream -> char option
	val inputN :       instream * int -> string
	val inputLine :    instream -> string
	val inputAll :     instream -> string
	val canInput :     instream * int -> int option
	val lookahead :    instream -> char option
	val closeIn :      instream -> unit
	val endOfStream :  instream -> bool
	val mkInstream :   StreamIO.instream -> instream
	val getInstream :  instream -> StreamIO.instream
	val setInstream :  instream * StreamIO.instream -> unit

	val openOut :      string -> outstream
	val openAppend :   string -> outstream
	val openString :   string -> instream
	val output :       outstream * string -> unit
	val output1 :      outstream * char -> unit
	val outputSubstr : outstream * substring -> unit
	val flushOut :     outstream -> unit
	val closeOut :     outstream -> unit
	val mkOutstream :  StreamIO.outstream -> outstream
	val getOutstream : outstream -> StreamIO.outstream
	val setOutstream : outstream * StreamIO.outstream -> unit
	val getPosOut :    outstream -> StreamIO.out_pos
	val setPosOut :    outstream * StreamIO.out_pos -> unit

	val print :        string -> unit

	val scanStream :   ((char, StreamIO.instream) StringCvt.reader -> ('a, StreamIO.instream) StringCvt.reader) -> instream -> 'a option
    end
  </PRE>

<?php section("description", "description") ?>

  <P>
    Like the Standard ML Basis'
    <A href="http://SML.sourceforge.net/Basis/text-io.html"><TT>TextIO</TT></A> structure.
  </P>

<?php footing() ?>
