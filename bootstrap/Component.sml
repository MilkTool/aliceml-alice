(* Dummy replacement for bootstrapping *)

structure Component :> COMPONENT =
    struct
	type component = unit
	type t = component

	exception Sited
	exception Corrupt

	fun inf _ = NONE
	fun load url =
	    raise IO.Io {name = Url.toStringRaw url,
			 function = "load", cause = Corrupt}
	fun save (name, _) =
	    raise IO.Io {name = name, function = "save", cause = Sited}

	structure Manager: COMPONENT_MANAGER =
	    struct
		exception Conflict

		type component = component

		fun link url =
		    raise IO.Io {name = Url.toStringRaw url,
				 function = "link", cause = Corrupt}
		fun lookup _ = NONE
		fun enter (_, _) = raise Conflict
	    end
    end

structure ComponentManager = Component.Manager
