signature PERVASIVE_TYPE =
  sig

    type lab		= Label.t
    type name		= Name.t
    type path		= Path.t
    type con		= Type.con
    type typ		= Type.typ

    val lab_false :	lab
    val lab_true :	lab
    val lab_nil :	lab
    val lab_cons :	lab

    val name_pervasive:	name
    val name_ref :	name
    val name_match :	name
    val name_bind :	name

    val path_zero :	path
    val path_succ :	path
    val path_int :	path
    val path_word :	path
    val path_real :	path
    val path_char :	path
    val path_string :	path
    val path_vec :	path
    val path_array :	path
    val path_ref :	path
    val path_exn :	path
    val path_conarrow :	path

    val con_zero :	con
    val con_succ :	con
    val con_int :	con
    val con_word :	con
    val con_real :	con
    val con_char :	con
    val con_string :	con
    val con_vec :	con
    val con_array :	con
    val con_ref :	con
    val con_exn :	con
    val con_conarrow :	con

    val typ_zero :	typ
    val typ_succ :	typ
    val typ_unit :	typ
    val typ_bool :	typ
    val typ_int :	typ
    val typ_word :	typ
    val typ_real :	typ
    val typ_char :	typ
    val typ_string :	typ
    val typ_list :	typ
    val typ_vec :	typ
    val typ_array :	typ
    val typ_ref :	typ
    val typ_exn :	typ
    val typ_conarrow :	typ

    exception Lookup
    val lookup :	string -> con	(* [Lookup] *)

  end
