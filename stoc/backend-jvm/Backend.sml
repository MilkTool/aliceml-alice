structure Backend=
    struct
	type stamp=IntermediateGrammar.stamp

	(* Hashtabelle f�r Stamps. *)
	structure StampHash = MakeHashImpMap(type t=stamp val hash=Stamp.hash)

	(* Scoped Sets f�r Stamps. Wird zur Berechnung der freien
	 Variablen benutzt. *)
	structure ScopedStampSet = MakeHashScopedImpSet(type t=stamp
							val hash=Stamp.hash)

	(* Hashtabelle f�r Listen von Strings. Wird ben�tigt bei der
	 statischen Berechnung der Recordarit�ten. *)
	structure StringListHash = MakeHashImpMap(StringListHashKey)

	(* Hashtabelle f�r Integers. Wird ben�tigt zum statischen
	 Generieren von Integerkonstanten. *)
	structure IntHash = MakeHashImpMap (type t=int fun hash n=n)

	structure StampSet = MakeHashImpSet(type t=stamp val hash=Stamp.hash)

	val toplevel = Stamp.new()
	val illegalstamp = Stamp.new()

	structure Lambda = MakeLambda(structure StampSet=StampSet
				      structure StampHash=StampHash
				      val toplevel=toplevel)
end
