structure Prebound :> PREBOUND =
  struct

    type name   = IntermediateGrammar.stamp

    open IntermediateGrammar

    val dummy = Source.nowhere

    val stamp_false	= Stamp.new()
    val stamp_true	= Stamp.new()
    val stamp_nil	= Stamp.new()
    val stamp_cons	= Stamp.new()
    val stamp_ref	= Stamp.new()
    val stamp_Match	= Stamp.new()
    val stamp_Bind	= Stamp.new()
    val stamp_eq	= Stamp.new()
    val stamp_assign	= Stamp.new()

  end
