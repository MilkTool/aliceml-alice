signature DISASSEMBLE =
sig
    val disassemble : Code.program * int * int -> unit
end

structure Disassemble : DISASSEMBLE =
struct
    fun showreg r = "R" ^ toString r
    fun show oper = case oper of
        Move {dst, src, cond} => "MOVE\t" ^ showreg dst ^ "<-" ^ showreg src ^ "|" ^ showreg cond ^ " != 0"
      | Get {dst, arr, idx} => "GET\t" ^ showreg dst ^ " := " ^ showreg arr ^ "[" ^ showreg idx ^ "]"
      | Set {arr, idx, src} => "SET\t" ^ showreg arr ^ "[" ^ showreg idx ^ "] := " ^ showreg src
      | Add {dst, x, y} => "ADD\t" ^ showreg dst ^ " := " ^ showreg x ^ " + " ^ showreg y
      | Mul {dst, x, y} => "MUL\t" ^ showreg dst ^ " := " ^ showreg x ^ " - " ^ showreg y
      | Div {dst, x, y} => "DIV\t" ^ showreg dst ^ " := " ^ showreg x ^ " / " ^ showreg y
      | Nand {dst, x, y} => "NAND\t" ^ showreg dst ^ " := " ^ showreg x ^ " nand " ^ showreg y
      | Halt => "HALT"
      | Alloc {dst, size} => "ALLOC\t" ^ showreg dst ^ " (" ^ showreg size ^ ")"
      | Free {src} => "FREE\t" ^ showreg src
      | Out {src} => "OUT\t" ^ showreg src
      | In {dst} => "IN\t" ^ showreg dst
      | Load {arr, off} => "LOAD\t" ^ showreg arr ^ " :" ^ showreg off
      | Imm {dst, i} => "LOAD\t" ^ showreg dst ^ " := " ^ toString i
    fun disassemble (p, fromm, to) = let
        fun f (i, oper) = if fromm <= i andalso i <= to then print (show oper) else ()
        in appi f p end
end
