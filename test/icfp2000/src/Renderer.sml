signature VECTOR =
    sig
	type vector = real * real * real
	type row = real * real * real * real
	type matrix = row * row * row

	val add: vector * vector -> vector
	val sub: vector * vector -> vector
	val scale: real * vector -> vector
	val dotProd: vector * vector -> real
	val transformPoint: matrix * vector -> vector
	val transformVector: matrix * vector -> vector
	val length: vector -> real
	val toUnit: vector -> vector
    end

structure Vector :> VECTOR =
    struct
	type vector = real * real * real
	type row = real * real * real * real
	type matrix = row * row * row

	fun add ((ax, ay, az), (bx, by, bz)): vector =
	    (ax + bx, ay + by, az + bz)

	fun sub ((ax, ay, az), (bx, by, bz)): vector =
	    (ax - bx, ay - by, az - bz)

	fun scale (k, (x, y, z)): vector = (k * x, k * y, k * z)

	fun dotProd ((ax, ay, az), (bx, by, bz)): real =
	    ax * bx + ay * by + az * bz

	fun transformPoint (((a11, a12, a13, a14),
			     (a21, a22, a23, a24),
			     (a31, a32, a33, a34)), (b1, b2, b3)): vector =
	    (a11 * b1 + a12 * b2 + a13 * b3 + a14,
	     a21 * b1 + a22 * b2 + a23 * b3 + a24,
	     a31 * b1 + a32 * b2 + a33 * b3 + a34)

	fun transformVector (((a11, a12, a13, _),
			      (a21, a22, a23, _),
			      (a31, a32, a33, _)), (b1, b2, b3)): vector =
	    (a11 * b1 + a12 * b2 + a13 * b3,
	     a21 * b1 + a22 * b2 + a23 * b3,
	     a31 * b1 + a32 * b2 + a33 * b3)

	fun length (x, y, z): real = Math.sqrt (x * x + y * y + z * z)

	fun toUnit (x, y, z) =
	    let
		val k = Math.sqrt (x * x + y * y + z * z)
	    in
		(k * x, k * y, k * z)
	    end
    end

structure Renderer (*:> RENDERER*) =
    struct
    type angle  = real
    type point  = real * real * real
    type vector = real * real * real
    type row    = real * real * real * real
    type matrix = row * row * row
    type color  = {red : real, green : real, blue : real}

    datatype plane_face    = PlaneSurface
    datatype sphere_face   = SphereSurface
    datatype cube_face     = CubeBottom | CubeTop | CubeFront | CubeBack
			   | CubeLeft | CubeRight
    datatype cylinder_face = CylinderBottom | CylinderTop | CylinderSide
    datatype cone_face     = ConeBase | ConeSide

    type 'face surface =
	    'face -> point ->
	    { color :    color
	    , diffuse :  real
	    , specular : real
	    , phong :    real }

    datatype object =
	      Plane      of matrix * matrix * plane_face surface
	    | Sphere     of matrix * matrix * sphere_face surface
	    | Cube       of matrix * matrix * cube_face surface     (* Tier 2 *)
	    | Cylinder   of matrix * matrix * cylinder_face surface (* Tier 2 *)
	    | Cone       of matrix * matrix * cone_face surface     (* Tier 2 *)
	    | Union      of object * object
	    | Intersect  of object * object                         (* Tier 3 *)
	    | Difference of object * object                         (* Tier 3 *)

    datatype light =
	      Directional of color * vector
	    | Point       of color * point                          (* Tier 2 *)
	    | Spot        of color * point * point * angle * real   (* Tier 3 *)

	exception Crash

	datatype intersection = Entry | Exit
	datatype which = A | B
	datatype wher = Outside | InA | InB | InAB

	fun merge (xs as (x as (l1, _, _))::xr, ys as (y as (l2, _, _))::yr) =
	    (case Real.compare (l1, l2) of
		 LESS => (x, A)::merge (xr, ys)
	       | EQUAL => (x, A)::(y, B)::merge (xr, yr)
	       | GREATER => (y, B)::merge (xs, yr))
	  | merge (nil, ys) = List.map (fn y => (y, B)) ys
	  | merge (xs, nil) = List.map (fn x => (x, A)) xs

	fun union ((x as (_, _, Entry), A)::xr, Outside) = x::union (xr, InA)
	  | union ((x as (_, _, Entry), B)::xr, Outside) = x::union (xr, InB)
	  | union ((x as (_, _, Exit), A)::xr, InA) = x::union (xr, Outside)
	  | union ((x as (_, _, Entry), B)::xr, InA) = union (xr, InAB)
	  | union ((x as (_, _, Entry), A)::xr, InB) = union (xr, InAB)
	  | union ((x as (_, _, Exit), B)::xr, InB) = x::union (xr, Outside)
	  | union ((x as (_, _, Exit), A)::xr, InAB) = union (xr, InB)
	  | union ((x as (_, _, Exit), B)::xr, InAB) = union (xr, InA)
	  | union (nil, _) = nil
	  | union (_, _) = raise Crash

	fun inter ((x as (_, _, Entry), A)::xr, Outside) = inter (xr, InA)
	  | inter ((x as (_, _, Entry), B)::xr, Outside) = inter (xr, InB)
	  | inter ((x as (_, _, Exit), A)::xr, InA) = inter (xr, Outside)
	  | inter ((x as (_, _, Entry), B)::xr, InA) = x::inter (xr, InAB)
	  | inter ((x as (_, _, Entry), A)::xr, InB) = x::inter (xr, InAB)
	  | inter ((x as (_, _, Exit), B)::xr, InB) = inter (xr, Outside)
	  | inter ((x as (_, _, Exit), A)::xr, InAB) = x::inter (xr, InB)
	  | inter ((x as (_, _, Exit), B)::xr, InAB) = x::inter (xr, InA)
	  | inter (nil, _) = nil
	  | inter (_, _) = raise Crash

	fun diff ((x as (_, _, Entry), A)::xr, Outside) = x::diff (xr, InA)
	  | diff ((x as (_, _, Entry), B)::xr, Outside) = diff (xr, InB)
	  | diff ((x as (_, _, Exit), A)::xr, InA) = x::diff (xr, Outside)
	  | diff (((l, s, Entry), B)::xr, InA) = (l, s, Exit)::diff (xr, InAB)
	  | diff ((x as (_, _, Entry), A)::xr, InB) = diff (xr, InAB)
	  | diff ((x as (_, _, Exit), B)::xr, InB) = diff (xr, Outside)
	  | diff ((x as (_, _, Exit), A)::xr, InAB) = diff (xr, InB)
	  | diff (((l, s, Exit), B)::xr, InAB) = (l, s, Entry)::diff (xr, InA)
	  | diff (nil, _) = nil
	  | diff (_, _) = raise Crash

	fun intersect (Plane (o2w, w2o, surface), base, dir) =
	    let
		val (_, dy, _) = Vector.transformVector (w2o, dir)
	    in
		if dy >= 0.0 then nil
		else
		    let
			val (_, y, _) = Vector.transformPoint (w2o, base)
		    in
			[(y / ~dy,
			  (surface PlaneSurface,
			   fn _ =>
			   Vector.transformVector (o2w, (0.0, 1.0, 0.0))),
			  Entry)]
		    end
	    end
	  | intersect (Sphere (o2w, w2o, surface), base, dir) =
	    let
		val base' = Vector.transformPoint (w2o, base)
		val dir' = Vector.transformVector (w2o, dir)
		val mtca = Vector.dotProd (dir', base')
	    in
		if mtca > 0.0 then nil
		else
		    let
			val d2 = Vector.dotProd (base', base') - mtca * mtca
		    in
			if d2 > 1.0 then nil
			else
			    let
				val tca = ~mtca
				val thc = Math.sqrt (1.0 - d2)
				val x = (surface SphereSurface,
					 fn v =>
					 Vector.transformVector
					 (o2w, Vector.sub (v, base')))
				val k = Vector.length dir'
			    in
				[((tca - thc) / k, x, Entry),
				 ((tca + thc) / k, x, Exit)]
			    end
		    end
	    end
	  | intersect (Cube (o2w, w2o, surface), base, dir) =
	    raise Crash   (*UNFINISHED*)
	  | intersect (Cylinder (o2w, w2o, surface), base, dir) =
	    raise Crash   (*UNFINISHED*)
	    (* Possibilities:
	     *    2 intersections with bottom (dy = 0)
	     *    1 intersection with bottom
	     *         1 intersection with top - order!
	     *         1 intersection with side - order!
	     *         0 intersections with top/side (tangential)
	     *    0 intersections with bottom
	     *         2 intersections with top (dy = 0)
	     *         1 intersection with top
             *              1 intersection with side - order!
	     *              0 intersections with top/side
	     *         0 intersection with top
	     *              (runs along side: cannot happen)
	     *              2 intersections with side
	     *              1 intersections with side (tangential)
	     *              0 intersections with side
	     *)
(*
	    let
		val base' as (x, y, z) = Vector.transformPoint (w2o, base)
		val dir' as (dx, dy, dz) = Vector.transformVector (w2o, dir)
	    in
		if Real.= (dy, 0.0) then
		    if y > 0.0 andalso y < 1.0 then
		    else if Real.= (y, 0.0) then
		    else if Real.= (y, 1.0) then
		    else nil
		else
		    let   (* test intersection with bottom *)
			val k = y / dy
			val bot_x = x + k * dx
			val bot_z = z + k * dz
		    in
			if bot_x * bot_x + bot_z * bot_z <= 1.0 then
			    k is intersection; test with top/side
			else   (* test intersection with top *)
			    let
				val k = (1.0 - y) / dy
				val top_x = x + k * dx
				val top_z = z + k * dz
			    in
				if top_x * top_x + top_z * top_z <= 1.0 then
				    k is intersection; test with side
				else   (* test intersection with top *)
			    end
		    end
	    end
*)
	  | intersect (Cone (o2w, w2o, surface), base, dir) =
	    raise Crash   (*UNFINISHED*)
	  | intersect (Union (obj1, obj2), base, dir) =
	    union (merge (intersect (obj1, base, dir),
			  intersect (obj2, base, dir)), Outside)
	  | intersect (Intersect (obj1, obj2), base, dir) =
	    inter (merge (intersect (obj1, base, dir),
			  intersect (obj2, base, dir)), Outside)
	  | intersect (Difference (obj1, obj2), base, dir) =
	    diff (merge (intersect (obj1, base, dir),
			 intersect (obj2, base, dir)), Outside)

	fun isShadowed ((k', _, Entry)::_, k: real) = k < k'
	  | isShadowed ((_, _, Exit)::_, _) = raise Crash
	  | isShadowed (nil, _) = true

	fun intensity (Directional (color, dir), scene, point) =
	    if List.null (intersect (scene, point, dir)) then SOME color
	    else NONE
	  | intensity (Point (color, pos), scene, point) =
	    let
		val dir = Vector.sub (pos, point)
	    in
		if isShadowed (intersect (scene, point, dir), 1.0) then NONE
		else SOME color   (*--** attenuation *)
	    end
	  | intensity (Spot (color, pos, at, cutoff, exp), scene, point) =
	    let
		val dir = Vector.sub (pos, point)
	    in
		(*--** at, cutoff, exp *)
		if isShadowed (intersect (scene, point, dir), 1.0) then NONE
		else SOME color   (*--** attenuation *)
	    end

	fun render {ambient, lights, scene, vision, width, height, depth} =
	    let
		fun trace (base, dir) =
		    case intersect (scene, base, dir) of
			(k, (surface, f), Entry)::_ =>
			    let
				val p =   (* intersection point *)
				    Vector.add (base, Vector.scale (k, dir))
				val n =   (* unit normal vector on surface *)
				    Vector.toUnit (f p)
				val {color = c, diffuse = kd,
				     specular = ks, phong = exp} = surface p
				val intensities =
				    List.mapPartial
				    (fn light => intensity (light, scene, p))
				    lights
			    in
				ambient (*UNF*)
			    end
		      | (_, _, Exit)::_ => raise Crash
		      | nil => ambient

		fun render' (x, y) =
		    {red = 0.0, green = 0.0, blue = 0.0}   (*UNFINISHED*)
	    in
		render'
	    end
    end
