
functor MkSpecial(val space : Util.spaces) :> SPECIAL =
    struct
	open TypeTree

	val includeFiles =
	    case space of
		Util.GTK => ["NativeGtkSpecial.hh"]
	      | Util.GDK => ["NativeGdkSpecial.hh"]
	      | Util.GNOMECANVAS => ["NativeGnomeCanvasSpecial.hh"]
	      | _ => nil

        (* ignoreFuns: do not generate any code for: *)
	val ignoreFuns = 
	    case space of
		Util.GTK => ["gtk_init",
			     "gtk_init_check", 
			     "gtk_true", 
			     "gtk_false",
			     "gtk_tree_store_new",
			     "gtk_type_init" (**),
			     "gtk_signal_compat_matched" (**)]
	      | Util.GDK => ["gdk_init",
			     "gdk_init_check",
			     "gdk_pixbuf_new_from_xpm_data"]
	      | Util.GNOMECANVAS => ["gnome_canvas_item_new",
				     "gnome_canvas_join_gdk_to_art", (**)
				     "gnome_canvas_cap_gdk_to_art" (**)]
	      | _ => nil

        (* specialFuns: generate asig, but no code for: *)
	val specialFuns = case space of
	    Util.GTK => 
		[FUNC("gtk_init", VOID, nil),
		 FUNC("gtk_get_event_stream", POINTER VOID, nil),
		 FUNC("gtk_signal_connect", NUMERIC (false, false, LONG), 
		      [POINTER VOID, STRING true, BOOL]),
		 FUNC("gtk_signal_disconnect", VOID, 
		      [POINTER VOID, NUMERIC (false, false, LONG)]),
		 FUNC("gtk_null", POINTER VOID, nil),
		 FUNC("gtk_gtk_true", NUMERIC(true, false, INT), nil),
		 FUNC("gtk_gtk_false", NUMERIC(true, false, INT), nil),
		 FUNC("gtk_text_iter_new", POINTER (STRUCTREF "_GtkTextIter"), 
		      nil),
		 FUNC("gtk_tree_iter_new", POINTER (STRUCTREF "_GtkTreeIter"), 
		      nil),
		 FUNC("gtk_tree_store_new", POINTER VOID, nil),
		 FUNC("gtk_tree_view_get_selected_string", 
		      STRING true, [POINTER VOID]),
		 FUNC("gtk_g_object_unref", VOID, [POINTER VOID]),
		 FUNC("gtk_delete_unref", VOID, [POINTER VOID])]

	 | Util.GDK =>
	       [FUNC("gdk_init", VOID, nil),
	        FUNC("gdk_pixbuf_new_from_xpm_data", POINTER VOID,
		     [ARRAY (NONE, STRING true)]),
		FUNC("gdk_color_new", POINTER (STRUCTREF "_GdkColor"), 
		     [NUMERIC (false,false,INT),
		      NUMERIC (false,false,INT), NUMERIC (false,false,INT)]),
		FUNC("gdk_point_new", POINTER (STRUCTREF "_GdkPoint"),
		     [NUMERIC (true,false,INT), NUMERIC (true,false,INT)]),
		FUNC("gdk_rectangle_new", POINTER (STRUCTREF "_GdkRectangle"),
		     [NUMERIC (true,false,INT), NUMERIC (true,false,INT),
		      NUMERIC (true,false,INT), NUMERIC (true,false,INT)])]
	  | Util.GNOMECANVAS =>
	       [FUNC("gnome_canvas_points_set_coords", VOID,
		     [POINTER VOID, NUMERIC (true,false,INT), 
		      NUMERIC (true,false,INT)]),
		FUNC("gnome_canvas_item_new", POINTER VOID,
		     [POINTER VOID, NUMERIC (true,false,INT)])]
	  | _ => nil

       (* changedFuns: generate different asig and code for: *)
       val changedFuns = case space of
	   Util.GTK =>
	       [FUNC("gtk_combo_set_popdown_strings", VOID, 
		      [POINTER (STRUCTREF "GtkCombo"),
		       LIST ("GList", STRING true)])]
	 | _ => nil

       (* ignoreSafeFuns: do not generate any safe code for: *)
       val ignoreSafeFuns =
	   case space of
	       Util.GTK => ["gtk_init",
			    "gtk_get_event_stream",
			    "gtk_main",
			    "gtk_signal_connect",
			    "gtk_signal_disconnect",
			    "gtk_null",
			    "gtk_gtk_true",
			    "gtk_gtk_false",
			    "gtk_g_object_unref",
			    "gtk_delete_unref"]
	     | Util.GDK => ["gdk_init"]
	     | _ => nil

       fun isIgnored (FUNC (n,_,_)) = 
	   (List.exists (fn n' => n=n') ignoreFuns) orelse
           (List.exists (fn (FUNC (n',_,_)) => n=n' | _ => false) changedFuns)
	 | isIgnored _              = false

       fun isIgnoredSafe (FUNC (n,_,_)) = List.exists (fn n' => n=n') 
	                                    ignoreSafeFuns
	 | isIgnoredSafe _              = false

    end
