(*
 * A source file.
 *)


signature SOURCE =
  sig

    type source
    type t	= source

    type pos	= int * int
    type region	= pos * pos

    type desc

    val fromString:		string -> source
    val toString:		source -> string

    val nowhere:		region
    val over:			region * region -> region
    val between:		region * region -> region

    val regionToString:		region -> string

    val stringDesc:		desc
    val urlDesc:		Url.t -> desc

    val url:			desc -> Url.t option

  end
