(* Dummy replacement for bootstrapping *)

signature UNSAFE_COMPONENT =
    sig
	val load: Url.t -> 'component
	val replaceSign: 'component * Signature.t -> 'component
	val save: string * 'component -> unit
    end
