#ifndef _NATIVE_GNOME_CANVAS_SPECIAL_HH_
#define _NATIVE_GNOME_CANVAS_SPECIAL_HH_ { 0, NULL }

DEFINE3(NativeGnomeCanvas_pointsSetCoords) {
  DECLARE_UNMANAGED_POINTER(points,x0);
  DECLARE_INT(num,x1);
  DECLARE_INT(value,x2);
  (static_cast<GnomeCanvasPoints*>(points))->coords[num] = value;
  RETURN_UNIT;
} END

DEFINE2(NativeGnomeCanvas_itemNew) {
  DECLARE_UNMANAGED_POINTER(parent,x0);
  DECLARE_INT(type,x1);
  GnomeCanvasItem *ret = gnome_canvas_item_new(
		           static_cast<GnomeCanvasGroup*>(parent), 
			   static_cast<GtkType>(type), NULL);
  RETURN(Store::UnmanagedPointerToWord(ret));
} END

#endif
