<?php include("macros.php3"); ?>
<?php heading("The BinIO structure", "The <TT>BinIO</TT> structure") ?>

<?php section("synopsis", "synopsis") ?>

  <PRE>
    signature BIN_IO
    structure BinIO : BIN_IO
  </PRE>

  <P>
    The Standard ML Basis'
    <A href="http://SML.sourceforge.net/Basis/bin-io.html"><TT>BinIO</TT></A> structure.
  </P>

  <P>See also:
    <A href="text-io.php3"><TT>TextIO</TT></A>,
    <A href="imperative-io.php3"><TT>IMPERATIVE_IO</TT></A>
  </P>

<?php section("import", "import") ?>

  <P>
    Imported implicitly.
  </P>

<?php section("interface", "interface") ?>

  <PRE>
    signature BIN_IO =
    sig
	structure StreamIO : STREAM_IO where type vector = Word8Vector.vector
				         and type elem   = Word8.word
				         and type pos    = Position.int

	type vector = StreamIO.vector
	type elem   = StreamIO.elem

	type instream
	type outstream

	val openIn :       string -> instream
	val input :        instream -> vector
	val input1 :       instream -> elem option
	val inputN :       instream * int -> vector
	val inputAll :     instream -> vector
	val canInput :     instream * int -> int option
	val lookahead :    instream -> elem option
	val closeIn :      instream -> unit
	val endOfStream :  instream -> bool
	val mkInstream :   StreamIO.instream -> instream
	val getInstream :  instream -> StreamIO.instream
	val setInstream :  instream * StreamIO.instream -> unit

	val openOut :      string -> outstream
	val openAppend :   string -> outstream
	val output :       outstream * vector -> unit
	val output1 :      outstream * elem -> unit
	val flushOut :     outstream -> unit
	val closeOut :     outstream -> unit
	val mkOutstream :  StreamIO.outstream -> outstream
	val getOutstream : outstream -> StreamIO.outstream
	val setOutstream : outstream * StreamIO.outstream -> unit
	val getPosOut :    outstream -> StreamIO.out_pos
	val setPosOut :    outstream * StreamIO.out_pos -> unit
    end
  </PRE>

<?php section("description", "description") ?>

  <P>
    Like the Standard ML Basis'
    <A href="http://SML.sourceforge.net/Basis/bin-io.html"><TT>BinIO</TT></A> structure.
  </P>

<?php footing() ?>
