functor CountPosLexer(
	structure Lexer: LEXER
	where type UserDeclarations.pos = int
	where type ('a,'b) UserDeclarations.token = ('a,'b) LrParser.Token.token
	structure LexerError: LEXER_ERROR
	where type token =
		(Lexer.UserDeclarations.svalue, int) LrParser.Token.token
	val error : Source.region * LexerError.error -> 'a
) : LEXER =
  struct

    structure UserDeclarations =
      struct
	open Lexer.UserDeclarations
	type pos = Source.pos
      end

    fun makeLexer yyinput =
	let
	    val lin  = ref 1
	    val col  = ref 0
	    val pos  = ref 0
	    val buf  = ref ""	(* current buffer *)
	    val buf' = ref ""	(* next buffer *)
	    val off  = ref 0	(* offset to start of current buffer *)
	    val off' = ref 0	(* offset for next buffer *)

	    fun count(i, i', lin, col) =
		if i = i' then
		    (lin,col)
		else (case String.sub(!buf, i)
		    of #"\n" => count(i+1, i', lin+1, 0)
		     | #"\t" => count(i+1, i', lin, col+8-(col mod 8))
		     |  _    => count(i+1, i', lin, col+1)
		) handle Subscript =>
		let
		    val n = String.size(!buf)
		in
		    buf  := !buf' ;
		    buf' := ""    ;
		    off  := !off' ;
		    count(0, i'-n, lin, col)
		end

	    fun transform(pos1, pos2) =
		let
		    val n0 = !off
		    val pos1' as (l1,c1) = count(!pos-n0, pos1-n0, !lin, !col)
		    val n0 = !off
		    val pos2' as (l2,c2) = count(pos1-n0, pos2-n0, l1, c1)
		in
		    lin := l2 ;
		    col := c2 ;
		    pos := pos2 ;
		    (pos1',pos2')
		end

	    fun yyinput' n =
		let
		    val s = yyinput n
		in
		    buf' := s ;
		    off' := !off + String.size(!buf) ;
		    s
		end

	    val lexer = Lexer.makeLexer yyinput'
	in
	    fn () =>
		let
		    val LrParser.Token.TOKEN(term, (svalue,pos1,pos2)) =
			lexer() handle LexerError.EOF f =>
			let val pos = !off'+String.size(!buf') in f(pos,pos) end
		    val (pos1', pos2') = transform(pos1, pos2)
		in
		    LrParser.Token.TOKEN(term, (svalue, pos1', pos2'))
		end
		handle LexerError.Error(position, e) =>
		    error(transform position, e)
	end

  end
