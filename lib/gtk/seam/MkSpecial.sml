(*
 * Authors:
 *   Robert Grabowski <grabow@ps.uni-sb.de>
 *
 * Copyright:
 *   Robert Grabowski, 2003
 *
 * Last Change:
 *   $Date$ by $Author$
 *   $Revision$
 *
 *)

(*
  This functor defines the items for which a special binding
  (or no binding at all) should be generated.
*)

functor MkSpecial(val space : Util.spaces) :> SPECIAL =
    struct
	open TypeTree

	(* includeFile: file that is included in the generated native code.  *)
        (* The triple means: 1. name of the included file (or "" if none)    *)
        (*                   2. name of a possible init function in the file *)
        (*                   3. number of entries the init function adds to  *)
        (*                      the structure.                               *)
	val includeFile =
	    case space of
		Util.GTK => ("NativeGtkSpecial.hh", "", 0)
	      | Util.GDK => ("NativeGdkSpecial.hh", "", 0)
	      | Util.GNOMECANVAS => ("NativeGnomeCanvasSpecial.hh", "", 0)
	      | _ => ("", "", 0)

        fun testType (t, l) =
            (* If the type looks like _GtkType we also test for
               GtkType
             *)
            Util.contains t l orelse (t <> "" andalso String.sub (t, 0) = #"_" andalso 
                Util.contains (String.extract (t, 1, NONE)) l)

        fun testPositiveTypeList t =
            case space of
                Util.GTK => testType (t, CommonTypeList.common_type_list @
                                         GtkPositiveTypeList.gtk_positive_type_list)
              | Util.GDK => testType (t, CommonTypeList.common_type_list @
                                         GdkPositiveTypeList.gdk_positive_type_list) 
              | Util.GNOMECANVAS => true
              (* FIXME: find a GnomeCanvasPositiveTypeList.gnome_canvas_positive_type_list *)
              | _ => true

              
        (* ignoreItems: do not generate any code for: *)
	val ignoreItems = 
	    case space of
		Util.GTK => ["gtk_init",  
			     "gtk_init_check",
			     "gtk_main",
			     "gtk_true",  
			     "gtk_false", 
			     "gtk_signal_connect",
			     "gtk_signal_disconnect",
			     "gtk_tree_store_new",
			     "gtk_type_init",
			     "gtk_signal_run_type_get_type",
			     "gtk_signal_newv",
			     "gtk_signal_new",
			     "gtk_signal_emit_stop_by_name",
			     "gtk_signal_connect_object_while_alive",
			     "gtk_signal_connect_while_alive",
			     "gtk_signal_connect_full",
			     "gtk_signal_emitv",
			     "gtk_signal_emit",
			     "gtk_signal_emit_by_name",
			     "gtk_signal_emitv_by_name",
			     "gtk_signal_compat_matched",
			     "gtk_radio_button_new",
			     "gtk_radio_button_new_with_label",
			     "gtk_radio_button_new_with_mnemonic",
			     "gtk_radio_button_get_group",
			     "gtk_radio_button_set_group",
			     "gtk_radio_menu_item_get_group",
			     "gtk_radio_menu_item_set_group",
			     "gtk_radio_menu_item_new",
			     "gtk_radio_menu_item_new_with_label",
			     "gtk_radio_menu_item_new_with_mnemonic",
                             "gtk_icon_theme_set_search_path",
                             "gtk_icon_theme_get_search_path",
			     "_GtkSocket",
			     "_GtkPlug"] (* not available for win32 *)
	      | Util.GDK => ["gdk_init",
			     "gdk_init_check",
			     "gdk_pixbuf_new_from_xpm_data",
			     "gdk_pixbuf_composite_color",
                             "gdk_spawn_on_screen",
                             "gdk_spawn_on_screen_with_pipes"
                             ]
	      | Util.GNOMECANVAS => ["gnome_canvas_item_new",
				     "gnome_canvas_join_gdk_to_art",
				     "gnome_canvas_cap_gdk_to_art"]
	      | _ => nil

        (* specialFuns: for these functions, generate a full binding except
	   for the native wrapper code. (This code should then be written
           manually into the includeFile specified above.) *)
	val specialFuns = case space of
	    Util.GTK => 
		[FUNC("gtk_text_iter_new", POINTER (false, STRUCTREF "_GtkTextIter"), 
		      nil),
		 FUNC("gtk_tree_iter_new", POINTER (false, STRUCTREF "_GtkTreeIter"), 
		      nil),
		 FUNC("gtk_tree_store_new", POINTER (false, VOID), nil),
		 FUNC("gtk_tree_view_get_selected_string", 
		      STRING (true, true), [POINTER (false, VOID)]),
		 FUNC("gtk_widget_set_flags", VOID,
		      [POINTER (false, STRUCTREF "_GtkWidget"),
		       NUMERIC(false, false, INT)]),
		 FUNC("gtk_widget_unset_flags", VOID,
		      [POINTER (false, STRUCTREF "_GtkWidget"),
		       NUMERIC(false, false, INT)]),
		 FUNC("gtk_radio_button_new",
		      POINTER (false, STRUCTREF "_GtkRadioButton"),
		      [POINTER (false, VOID)]),
		 FUNC("gtk_radio_button_new_with_label",
		      POINTER (false, STRUCTREF "_GtkRadioButton"),
		      [POINTER (false, VOID), STRING (true, true)]),
		 FUNC("gtk_radio_button_new_with_mnemonic",
		      POINTER (false, STRUCTREF "_GtkRadioButton"),
		      [POINTER (false, VOID), STRING (true, true)]),
		 FUNC("gtk_radio_button_get_group",
		      POINTER (false, VOID),
		      [POINTER (false, STRUCTREF "_GtkRadioButton")]),
		 FUNC("gtk_radio_button_set_group",
		      VOID,
		      [POINTER (false, STRUCTREF "_GtkRadioButton"),
		       POINTER (false, VOID)]),
		 FUNC("gtk_radio_menu_item_get_group",
		      POINTER (false, VOID),
		      [POINTER (false, STRUCTREF "_GtkRadioMenuItem")]),
		 FUNC("gtk_radio_menu_item_set_group",
		      VOID,
		      [POINTER (false, STRUCTREF "_GtkRadioMenuItem"),
		       POINTER (false, VOID)]),
		 FUNC("gtk_radio_menu_item_new",
		      POINTER (false, STRUCTREF "_GtkRadioMenuItem"),
		      [POINTER (false, VOID)]),
		 FUNC("gtk_radio_menu_item_new_with_label",
		      POINTER (false, STRUCTREF "_GtkRadioMenuItem"),
		      [POINTER (false, VOID), STRING (true, true)]),
		 FUNC("gtk_radio_menu_item_new_with_mnemonic",
		      POINTER (false, STRUCTREF "_GtkRadioMenuItem"),
		      [POINTER (false, VOID), STRING (true, true)])]

	 | Util.GDK =>
	       [FUNC("gdk_pixbuf_new_from_xpm_data", POINTER (false, VOID),
		     [ARRAY (NONE, STRING (true, true))]),
		FUNC("gdk_color_new", POINTER (false, STRUCTREF "_GdkColor"), 
		     [NUMERIC (false,false,INT),
		      NUMERIC (false,false,INT), NUMERIC (false,false,INT)]),
		FUNC("gdk_point_new", POINTER (false, STRUCTREF "_GdkPoint"),
		     [NUMERIC (true,false,INT), NUMERIC (true,false,INT)]),
		FUNC("gdk_rectangle_new", POINTER (false, STRUCTREF "_GdkRectangle"),
		     [NUMERIC (true,false,INT), NUMERIC (true,false,INT),
		      NUMERIC (true,false,INT), NUMERIC (true,false,INT)])]
	  | Util.GNOMECANVAS =>
	       [FUNC("gnome_canvas_points_set_coords", VOID,
		     [POINTER (false, VOID), NUMERIC (true,false,INT), 
		      NUMERIC (true,false,INT)]),
		FUNC("gnome_canvas_item_new", POINTER (false, VOID),
		     [POINTER (false, VOID), NUMERIC (true,false,INT)]),
		FUNC("gnome_canvas_set_background_color", VOID,
		     [POINTER (false, VOID), POINTER (false, STRUCTREF "_GdkColor")])]
	  | _ => nil

       (* changedFuns: assume different type information for: *)
       val changedFuns = case space of
	   Util.GTK =>
	       [FUNC("gtk_combo_set_popdown_strings", VOID, 
		      [POINTER (false, STRUCTREF "GtkCombo"),
		       LIST ("GList", STRING (true, true))])]
	 | _ => nil

       (* ignoreType: true if this type should be ignored *)
       fun ignoreType (ENUMREF t)       = not (testPositiveTypeList t)
         | ignoreType (STRUCTREF t)     = not (testPositiveTypeList t)
         | ignoreType (UNIONREF t)      = not (testPositiveTypeList t) 
         | ignoreType (TYPEREF (_, t))  = ignoreType t (* not (testPositiveTypeList n) *)
         | ignoreType _                 = false
         
       (* isIgnored: true if no binding should be generated for an item *)
       fun isIgnored (FUNC (n, retT, argsT)) = 
	   (Util.contains n ignoreItems) orelse
           (List.exists (fn (FUNC (n',_,_)) => n=n' | _ => false) changedFuns) orelse
           (* also ignore functions which use values of a type we deceided ignore *)
           ignoreType retT orelse List.exists ignoreType argsT
         
	 | isIgnored (STRUCT (n, _)) = not (testPositiveTypeList n) orelse 
                                        Util.contains n ignoreItems
	 | isIgnored (ENUM (n, _)) = not (testPositiveTypeList n) orelse 
                                        Util.contains n ignoreItems
	 | isIgnored _ = false

        (*
       fun isIgnored (t as FUNC (n, retT, argsT)) =
            Util.contains n ignoreItems orelse
            List.exists (fn (FUNC  (n', _, _)) => n = n' | _ => false) changedFuns orelse
            (if ignoreType retT then (
                debugDecl ("due to return type " ^ tyToString retT ^ " ignoring", t);
                true)
             else
                case List.find ignoreType argsT of
                    SOME at     => (debugDecl ("due to argument type " ^ tyToString at ^
                                                "ignoring", t); true)
                  | NONE        => false
            )
       	 | isIgnored (t as STRUCT (n, _)) = 
            if not (testPositiveTypeList n) then
               (debugDecl ("ignoring", t); true)
            else Util.contains n ignoreItems
	 | isIgnored (t as ENUM (n, _)) = 
            if not (testPositiveTypeList n) then
                (debugDecl ("ignoring", t); true)
            else Util.contains n ignoreItems
	 | isIgnored _ = false
        *)
         
    end
