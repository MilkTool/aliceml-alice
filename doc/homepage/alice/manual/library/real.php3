<?php include("macros.php3"); ?>
<?php heading("The REAL signature", "The <TT>REAL</TT> signature") ?>

<?php section("synopsis", "synopsis") ?>

  <PRE>
    signature REAL
    structure Real : REAL where type real = real
    structure LargeReal : REAL = Real
  </PRE>

  <P>
    An extended version of the
    <A href="http://www.dina.kvl.dk/~sestoft/sml/real.html">Standard ML
    Basis' <TT>REAL</TT></A> signature.
  </P>

<?php section("import", "import") ?>

  <P>
    Imported implicitly.
  </P>

<?php section("interface", "interface") ?>

  <PRE>
    signature REAL =
    sig
	eqtype real
	type t = real

	structure Math :   MATH where type real = real

	val posInf :       real
	val negInf :       real

	val ~ :            real -> real
	val op + :         real * real -> real
	val op - :         real * real -> real
	val op * :         real * real -> real
	val op / :         real * real -> real
	val rem :          real * real -> real
	val *+ :           real * real * real -> real
	val *- :           real * real * real -> real

	val abs :          real -> real
	val min :          real * real -> real
	val max :          real * real -> real
	val sign :         real -> int
	val signBit :      real -> bool
	val sameSign :     real * real -> bool
	val copySign :     real * real -> real

	val op < :         real * real -> bool
	val op > :         real * real -> bool
	val op <= :        real * real -> bool
	val op >= :        real * real -> bool
	val equal :        real * real -> bool
	val compare :      real * real -> order
	val compareReal :  real * real -> IEEEReal.real_order

	val == :           real * real -> bool
	val != :           real * real -> bool
	val ?= :           real * real -> bool

	val isFinite :     real -> bool
	val isNan :        real -> bool
	val isNormal :     real -> bool
	val class :        real -> IEEEReal.float_class

	val ceil :         real -> int
	val floor :        real -> int
	val trunc :        real -> int
	val round :        real -> int
	val realFloor :    real -> real
	val realCeil :     real -> real
	val realTrunc :    real -> real
	val realRound :    real -> real

	val toInt :        IEEEReal.rounding_mode -> real -> int
	val toLargeInt :   IEEEReal.rounding_mode -> real -> LargeInt.int
	val fromInt :      int -> real
	val fromLargeInt : LargeInt.int -> real
	val toLarge :      real -> LargeReal.real
	val fromLarge :    IEEEReal.rounding_mode -> LargeReal.real -> real

	val toString :     real -> string
	val fromString :   string -> real option
	val scan :         (char,'a) StringCvt.reader -> (real,'a) StringCvt.reader
    end
  </PRE>

<?php section("description", "description") ?>

  <P>
    Items not described here are as in the 
    <A href="http://www.dina.kvl.dk/~sestoft/sml/real.html">Standard ML
    Basis' <TT>REAL</TT></A> signature.
  </P>

  <P>
    <I>Limitations:</I> The following standard values and functions are
    currently missing:
  </P>

  <UL>
    <LI><TT>radix</TT>, <TT>precision</TT></LI>
    <LI><TT>maxFinite</TT>, <TT>minPos</TT>, <TT>minNormalPos</TT></LI>
    <LI><TT>unordered</TT></LI>
    <LI><TT>nextAfter</TT></LI>
    <LI><TT>checkFloat</TT></LI>
    <LI><TT>toManExp</TT>, <TT>fromManExp</TT></LI>
    <LI><TT>split</TT>, <TT>realMod</TT></LI>
    <LI><TT>toDecimal</TT>, <TT>fromDecimal</TT></LI>
    <LI><TT>fmt</TT></LI>
  </UL>

  <P>Furthermore, the functions <TT>isFinite</TT>, <TT>isNan</TT>,
  <TT>isNormal</TT> and <TT>class</TT> are not implemented accurately.</P>

  <DL>
    <DT>
      <TT>eqtype real</TT> <BR>
      <TT>type t = real</TT>
    </DT>
    <DD>
      <P>A type for representing floating point numbers. Note that, unlike in
      the <A href="http://www.dina.kvl.dk/~sestoft/sml/real.html">Standard
      Basis</A>, <TT>real</TT> is an equality type. However, two reals
      compare as equal only if they have <EM>exactly</EM> the same
      representation. In particular, <TT>0.0 &lt;&gt; ~0.0</TT>. For
      IEEE equality, <TT>Real.==</TT> should be used.</P>
    </DD>

    <DT>
      <TT>equal (<I>x1</I>, <I>x2</I>)</TT>
    </DT>
    <DD>
      <P>An explicit equality function on reals. Equivalent to <TT>op=</TT>.</P>
    </DD>

    <DT>
      <TT>hash <I>x</I></TT>
    </DT>
    <DD>
      <P>A hash function on reals.</P>
    </DD>

    <DT>
      <TT>realRound <I>r</I></TT>
    </DT>
    <DD>
      <P>Truncates reals to integer-valued reals, yielding the integer nearest
      to <TT><I>r</I></TT>. In the case of a tie, rounds to the nearest even
      integer. If <TT><I>r</I></TT> is NaN or an infinity, returns
      <TT><I>r</I></TT>. The lack of this function seems to be an oversight
      in the <A href="http://www.dina.kvl.dk/~sestoft/sml/real.html">Standard
      Basis</A>.</P>
    </DD>
  </DL>

<?php section("also", "see also") ?>

  <DL><DD>
    <A href="ieee-real.php3"><TT>IEEEReal</TT></A>,
    <A href="math.php3"><TT>MATH</TT></A>
  </DD></DL>

<?php footing() ?>
