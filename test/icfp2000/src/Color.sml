signature COLOR =
    sig
	type color = {red: real, green: real, blue: real}

	val black: color
	val color: real * real * real -> color
	val scale: real * color -> color
	val add: color * color -> color
	val prod: color * color -> color
    end


structure Color :> COLOR =
    struct
	type color = {red: real, green: real, blue: real}

	fun color (r,g,b) = {red = r, green = g, blue = b}

	val black = {red = 0.0, green = 0.0, blue = 0.0}

	fun scale (k, {red, green, blue}): color =
	    {red = k * red, green = k * green, blue = k * blue}

	fun add ({red = r1, green = g1, blue = b1},
		 {red = r2, green = g2, blue = b2}): color =
	    {red = r1 + r2, green = g1 + g2, blue = b1 + b2}

	fun prod ({red = r1, green = g1, blue = b1},
		  {red = r2, green = g2, blue = b2}): color =
	    {red = r1 * r2, green = g1 * g2, blue = b1 * b2}
    end
