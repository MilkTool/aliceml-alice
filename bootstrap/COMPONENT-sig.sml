(* Dummy replacement for bootstrapping *)

signature COMPONENT =
    sig
	type component
	type t = component

	exception Sited
	exception Corrupt
	exception NotFound

	exception Mismatch of {component : Url.t,
			       request : Url.t option,
			       cause : Inf.mismatch}
	exception Eval of exn
	exception Failure of Url.t * exn

	val load: Url.t -> component
	val save: string * component -> unit
	val inf: component -> Inf.t option

	structure Manager: COMPONENT_MANAGER where type component = component
    end
