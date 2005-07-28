//
// Author:
//   Robert Grabowski <grabow@ps.uni-sb.de>
//
// Copyright:
//   Robert Grabowski, 2003
//
// Last Change:
//   $Date$ by $Author$
//   $Revision$
//

/*
  The native core component. See Core.aml for the purpose of the core.
*/

#include "Alice.hh"
#include "MyNativeAuthoring.hh"
#include "NativeUtils.hh"
#include "ExtraMarshaller.hh"

#if defined(__CYGWIN32__) || defined(__MINGW32__)
#include <windows.h>
#endif

static word eventStream;
static word weakDict;
static word signalMap;
static word signalMap2;
static bool had_events;
static word destroyCallback;

///////////////////////////////////////////////////////////////////////

// push a word to the front of a list and return the new list
static word push_front(word list, word value) {
  TagVal *cons = TagVal::New(0,2);
  cons->Init(0,value);
  cons->Init(1,list);
  return cons->ToWord();
}

///////////////////////////////////////////////////////////////////////
// GENERAL CONSTANTS

DEFINE0(NativeCore_null) {
  RETURN(OBJECT_TO_WORD(NULL));
} END

DEFINE0(NativeCore_gtkTrue) {
  RETURN(INT_TO_WORD(TRUE));
} END

DEFINE0(NativeCore_gtkFalse) {
  RETURN(INT_TO_WORD(FALSE));
} END

///////////////////////////////////////////////////////////////////////
// EVENT HANDLING FUNCTIONS

static inline word ExposeEvent(GdkEvent* event, int label) {
  GdkEventExpose *ev = reinterpret_cast<GdkEventExpose*>(event);
  TagVal *t = TagVal::New(label, 8);
  t->Init(0, INT_TO_WORD((ev->area).height));
  t->Init(1, INT_TO_WORD((ev->area).width));
  t->Init(2, INT_TO_WORD((ev->area).x));
  t->Init(3, INT_TO_WORD((ev->area).y));
  t->Init(4, INT_TO_WORD(ev->count));
  t->Init(5, OBJECT_TO_WORD(ev->region,TYPE_UNKNOWN));
  t->Init(6, BOOL_TO_WORD(ev->send_event));
  t->Init(7, OBJECT_TO_WORD(ev->window,TYPE_G_OBJECT));
  return t->ToWord();
}

static inline word MotionEvent(GdkEvent* event, int label) {
  GdkEventMotion *ev = reinterpret_cast<GdkEventMotion*>(event);
  TagVal *t = TagVal::New(label, 10);
  t->Init(0, OBJECT_TO_WORD(ev->device,TYPE_G_OBJECT));
  t->Init(1, INT_TO_WORD(ev->is_hint));
  t->Init(2, BOOL_TO_WORD(ev->send_event));
  t->Init(3, INT_TO_WORD(ev->state));
  t->Init(4, INT_TO_WORD(ev->time));
  t->Init(5, OBJECT_TO_WORD(ev->window,TYPE_G_OBJECT));
  t->Init(6, REAL_TO_WORD(ev->x));
  t->Init(7, REAL_TO_WORD(ev->x_root));
  t->Init(8, REAL_TO_WORD(ev->y));
  t->Init(9, REAL_TO_WORD(ev->y_root));
  return t->ToWord();
}

static inline word ButtonEvent(GdkEvent* event, int label) {
  GdkEventButton *ev = reinterpret_cast<GdkEventButton*>(event);
  TagVal *t = TagVal::New(label, 10);
  t->Init(0, INT_TO_WORD(ev->button));
  t->Init(1, OBJECT_TO_WORD(ev->device,TYPE_G_OBJECT));
  t->Init(2, BOOL_TO_WORD(ev->send_event));
  t->Init(3, INT_TO_WORD(ev->state));
  t->Init(4, INT_TO_WORD(ev->time));
  t->Init(5, OBJECT_TO_WORD(ev->window,TYPE_G_OBJECT));
  t->Init(6, REAL_TO_WORD(ev->x));
  t->Init(7, REAL_TO_WORD(ev->x_root));
  t->Init(8, REAL_TO_WORD(ev->y));
  t->Init(9, REAL_TO_WORD(ev->y_root));
  return t->ToWord();
}

static inline word KeyEvent(GdkEvent* event, int label) {
  GdkEventKey *ev = reinterpret_cast<GdkEventKey*>(event);
  TagVal *t = TagVal::New(label, 9);
  t->Init(0, INT_TO_WORD(ev->group));
  t->Init(1, INT_TO_WORD(ev->hardware_keycode));
  t->Init(2, INT_TO_WORD(ev->keyval));
  t->Init(3, INT_TO_WORD(ev->length));
  t->Init(4, BOOL_TO_WORD(ev->send_event));
  t->Init(5, INT_TO_WORD(ev->state));
  t->Init(6, STRING_TO_WORD(ev->string));
  t->Init(7, INT_TO_WORD(ev->time));
  t->Init(8, OBJECT_TO_WORD(ev->window,TYPE_G_OBJECT));
  return t->ToWord();
}

static inline word CrossingEvent(GdkEvent* event, int label) {
  GdkEventCrossing *ev = reinterpret_cast<GdkEventCrossing*>(event);    
  TagVal *t = TagVal::New(label, 12);
  t->Init(0, INT_TO_WORD(ev->detail));
  t->Init(1, BOOL_TO_WORD(ev->focus));
  t->Init(2, INT_TO_WORD(ev->mode));
  t->Init(3, BOOL_TO_WORD(ev->send_event));
  t->Init(4, INT_TO_WORD(ev->state));
  t->Init(5, OBJECT_TO_WORD(ev->subwindow,TYPE_G_OBJECT));
  t->Init(6, INT_TO_WORD(ev->time));
  t->Init(7, OBJECT_TO_WORD(ev->window,TYPE_G_OBJECT));
  t->Init(8, REAL_TO_WORD(ev->x));
  t->Init(9, REAL_TO_WORD(ev->x_root));
  t->Init(10, REAL_TO_WORD(ev->y));
  t->Init(11, REAL_TO_WORD(ev->y_root));
  return t->ToWord();
}

static inline word FocusEvent(GdkEvent* event, int label) {
  GdkEventFocus *ev = reinterpret_cast<GdkEventFocus*>(event);
  TagVal *t = TagVal::New(label, 3);
  t->Init(0, BOOL_TO_WORD(ev->in));
  t->Init(1, BOOL_TO_WORD(ev->send_event));
  t->Init(2, OBJECT_TO_WORD(ev->window,TYPE_G_OBJECT));
  return t->ToWord();
}

static inline word ConfigureEvent(GdkEvent* event, int label) {
  GdkEventConfigure *ev = reinterpret_cast<GdkEventConfigure*>(event);
  TagVal *t = TagVal::New(label, 6);
  t->Init(0, INT_TO_WORD(ev->height));
  t->Init(1, BOOL_TO_WORD(ev->send_event));
  t->Init(2, INT_TO_WORD(ev->width));
  t->Init(3, OBJECT_TO_WORD(ev->window,TYPE_G_OBJECT));
  t->Init(4, INT_TO_WORD(ev->x));
  t->Init(5, INT_TO_WORD(ev->y));
  return t->ToWord();
}

static inline word VisibilityEvent(GdkEvent* event, int label) {
  GdkEventVisibility *ev = reinterpret_cast<GdkEventVisibility*>(event);
  TagVal *t = TagVal::New(label, 3);
  t->Init(0, BOOL_TO_WORD(ev->send_event));
  t->Init(1, INT_TO_WORD(ev->state));
  t->Init(2, OBJECT_TO_WORD(ev->window,TYPE_G_OBJECT));
  return t->ToWord();
}

static inline word NoExposeEvent(GdkEvent* event, int label) {
  GdkEventNoExpose *ev = reinterpret_cast<GdkEventNoExpose*>(event);
  TagVal *t = TagVal::New(label, 2);
  t->Init(0, OBJECT_TO_WORD(ev->window,TYPE_G_OBJECT));  
  t->Init(1, BOOL_TO_WORD(ev->send_event));
  return t->ToWord();
}

static inline word ScrollEvent(GdkEvent* event, int label) {
  GdkEventScroll *ev = reinterpret_cast<GdkEventScroll*>(event);    
  TagVal *t = TagVal::New(label, 10);
  t->Init(0, OBJECT_TO_WORD(ev->device,TYPE_G_OBJECT));
  t->Init(1, INT_TO_WORD(ev->direction));
  t->Init(2, BOOL_TO_WORD(ev->send_event));
  t->Init(3, INT_TO_WORD(ev->state));
  t->Init(4, INT_TO_WORD(ev->time));
  t->Init(5, OBJECT_TO_WORD(ev->window,TYPE_G_OBJECT));
  t->Init(6, REAL_TO_WORD(ev->x));
  t->Init(7, REAL_TO_WORD(ev->x_root));
  t->Init(8, REAL_TO_WORD(ev->y));
  t->Init(9, REAL_TO_WORD(ev->y_root));
  return t->ToWord();
}

static inline word SimpleEvent(int label) {
  return INT_TO_WORD (label);
}

static word GdkEventToDatatype(GdkEvent *event) {
  enum { EVENT_2BUTTON_PRESS, EVENT_3BUTTON_PRESS, 
	   EVENT_BUTTON_PRESS, EVENT_BUTTON_RELEASE, 
	 EVENT_CLIENT_EVENT,
	 EVENT_CONFIGURE,
	 EVENT_DELETE, EVENT_DESTROY,
	 EVENT_DRAG_ENTER, EVENT_DRAG_LEAVE, 
	   EVENT_DRAG_MOTION, EVENT_DRAG_STATUS,
	 EVENT_DROP_FINISHED, EVENT_DROP_START, 
	 EVENT_ENTER_NOTIFY, 
	 EVENT_EXPOSE,
	 EVENT_FOCUS_CHANGE, 
	 EVENT_KEY_PRESS, EVENT_KEY_RELEASE,
	 EVENT_LEAVE_NOTIFY, 
	 EVENT_MAP,
	 EVENT_MOTION_NOTIFY,
	 EVENT_NOTHING,
	 EVENT_NO_EXPOSE,
	 EVENT_PROPERTY_NOTIFY,
	 EVENT_PROXIMITY_IN, EVENT_PROXIMITY_OUT,
	 EVENT_SCROLL, 
	 EVENT_SELECTION_CLEAR, EVENT_SELECTION_NOTIFY,EVENT_SELECTION_REQUEST,
	 EVENT_SETTING, 
	 EVENT_UNMAP,
	 EVENT_UNSUPPORTED, 
	 EVENT_VISIBILITY_NOTIFY, 
	 EVENT_WINDOW_STATE };

  switch (event->type) {
  case GDK_NOTHING: return SimpleEvent(EVENT_NOTHING);
  case GDK_DELETE: return SimpleEvent(EVENT_DELETE);
  case GDK_DESTROY: return SimpleEvent(EVENT_DESTROY);
  case GDK_EXPOSE: return ExposeEvent(event, EVENT_EXPOSE);
  case GDK_MOTION_NOTIFY: return MotionEvent(event, EVENT_MOTION_NOTIFY);
  case GDK_BUTTON_PRESS: return ButtonEvent(event, EVENT_BUTTON_PRESS);
  case GDK_2BUTTON_PRESS:return ButtonEvent(event, EVENT_2BUTTON_PRESS);
  case GDK_3BUTTON_PRESS:return ButtonEvent(event, EVENT_3BUTTON_PRESS);
  case GDK_BUTTON_RELEASE: return ButtonEvent(event, EVENT_BUTTON_RELEASE);
  case GDK_KEY_PRESS: return KeyEvent(event, EVENT_KEY_PRESS);
  case GDK_KEY_RELEASE: return KeyEvent(event, EVENT_KEY_RELEASE);
  case GDK_ENTER_NOTIFY: return CrossingEvent(event, EVENT_ENTER_NOTIFY);
  case GDK_LEAVE_NOTIFY: return CrossingEvent(event, EVENT_LEAVE_NOTIFY);
  case GDK_FOCUS_CHANGE: return FocusEvent(event, EVENT_FOCUS_CHANGE);
  case GDK_CONFIGURE: return ConfigureEvent(event, EVENT_CONFIGURE);
  case GDK_MAP: return SimpleEvent(EVENT_MAP);
  case GDK_UNMAP: return SimpleEvent(EVENT_UNMAP);
  case GDK_PROPERTY_NOTIFY: return SimpleEvent(EVENT_PROPERTY_NOTIFY);
  case GDK_SELECTION_CLEAR: return SimpleEvent(EVENT_SELECTION_CLEAR);
  case GDK_SELECTION_REQUEST: return SimpleEvent(EVENT_SELECTION_REQUEST);
  case GDK_SELECTION_NOTIFY: return SimpleEvent(EVENT_SELECTION_NOTIFY);
  case GDK_PROXIMITY_IN: return SimpleEvent(EVENT_PROXIMITY_IN);
  case GDK_PROXIMITY_OUT: return SimpleEvent(EVENT_PROXIMITY_OUT);
  case GDK_DRAG_ENTER: return SimpleEvent(EVENT_DRAG_ENTER);
  case GDK_DRAG_LEAVE: return SimpleEvent(EVENT_DRAG_LEAVE);
  case GDK_DRAG_MOTION: return SimpleEvent(EVENT_DRAG_MOTION);
  case GDK_DRAG_STATUS: return SimpleEvent(EVENT_DRAG_STATUS);
  case GDK_DROP_START: return SimpleEvent(EVENT_DROP_START);
  case GDK_DROP_FINISHED: return SimpleEvent(EVENT_DROP_FINISHED);
  case GDK_CLIENT_EVENT: return SimpleEvent(EVENT_CLIENT_EVENT);
  case GDK_VISIBILITY_NOTIFY: 
    return VisibilityEvent(event, EVENT_VISIBILITY_NOTIFY);
  case GDK_NO_EXPOSE: return NoExposeEvent(event, EVENT_NO_EXPOSE);
  case GDK_SCROLL: return ScrollEvent(event, EVENT_SCROLL);
  case GDK_WINDOW_STATE: return SimpleEvent(EVENT_WINDOW_STATE);
  case GDK_SETTING: return SimpleEvent(EVENT_SETTING);
  default:
    TagVal *tv = TagVal::New(EVENT_UNSUPPORTED, 1);
    tv->Init(0, OBJECT_TO_WORD(event,TYPE_UNKNOWN));
    return tv->ToWord();  
  }
}

// put a word on a stream
static inline void put_on_stream(word *stream, word value) {
  Future *f = static_cast<Future*>(Store::WordToTransient(*stream));
  *stream = (Future::New())->ToWord();  
  f->ScheduleWaitingThreads();
  f->Become(REF_LABEL, push_front(*stream, value));
}

// construct an arg value
static inline word create_param(int tag, word value) {
  TagVal *param = TagVal::New(tag,1);
  param->Init(0, value);
  return param->ToWord();
}

// convert a pointer to an object with the correct type information
static GType G_LIST_TYPE;
static GType G_SLIST_TYPE;
static GType GDK_EVENT_TYPE;
static GType GTK_OBJECT_TYPE;

static word create_object(GType t, gpointer p) {
  int tag = gtkOBJECT;
  word value;
  if (g_type_is_a(t, G_LIST_TYPE)) {
    tag = gtkLIST;
    value = GLIST_OBJECT_TO_WORD(static_cast<GList*>(p));
  }
  else
    if (g_type_is_a(t, G_SLIST_TYPE)) {
      tag = gtkLIST;
      value = GSLIST_OBJECT_TO_WORD(static_cast<GSList*>(p));
    }
    else
      if (t == GDK_EVENT_TYPE) {
	tag = gtkEVENT;
	value = GdkEventToDatatype(gdk_event_copy(static_cast<GdkEvent*>(p)));
      }
      else
        if (g_type_is_a(t, GTK_TYPE_TEXT_ITER)) {
          tag = gtkINT;
          value =
            INT_TO_WORD(gtk_text_iter_get_offset(static_cast<GtkTextIter*>(p)));
        } else
          if (g_type_is_a(t, GTK_OBJECT_TYPE))
            value = OBJECT_TO_WORD(p, TYPE_GTK_OBJECT);
          else
            value = OBJECT_TO_WORD(p, (G_IS_OBJECT(p) ? TYPE_G_OBJECT 
                                                      : TYPE_UNKNOWN));
  return create_param(tag, value);
}

// main function that puts arguments on event stream
static void
sendArgsToStream(gint connid, guint n_param_values, const GValue *param_values) {
  word paramlist = INT_TO_WORD(Types::nil);
  gpointer widget = NULL;

  for (int i = n_param_values-1; i >= 0; i--) {
    word value;

    const GValue *val = param_values + i;
    /*
    GTypeQuery q;
    memset(&q, 0, sizeof(q));
    g_type_query(G_VALUE_TYPE(val), &q);
    g_print("Param #%d, Type: %ld, Name: %s\n", i, G_VALUE_TYPE(val), 
	    q.type_name);
    */
    switch(G_VALUE_TYPE(val)) {
    case G_TYPE_CHAR:   
      value = create_param(gtkINT, 
		   INT_TO_WORD(static_cast<int>(g_value_get_char(val))));
      break;
    case G_TYPE_UCHAR:  
      value = create_param(gtkINT, 
                 INT_TO_WORD(static_cast<int>(g_value_get_uchar(val))));
      break;
    case G_TYPE_BOOLEAN:
      value = create_param(gtkBOOL, BOOL_TO_WORD(g_value_get_boolean(val)));
      break;
    case G_TYPE_INT:    
      value = create_param(gtkINT, INT_TO_WORD(g_value_get_int(val)));
      break;
    case G_TYPE_UINT:   
      value = create_param(gtkINT, INT_TO_WORD(g_value_get_uint(val)));
      break;
    case G_TYPE_LONG:   
      value = create_param(gtkINT, INT_TO_WORD(g_value_get_long(val)));
      break;
    case G_TYPE_ULONG:  
      value = create_param(gtkINT, INT_TO_WORD(g_value_get_ulong(val)));
      break;
    case G_TYPE_INT64:  
      value = create_param(gtkINT, INT_TO_WORD(g_value_get_int64(val)));
      break;
    case G_TYPE_UINT64: 
      value = create_param(gtkINT, INT_TO_WORD(g_value_get_uint64(val)));
      break;
    case G_TYPE_ENUM:   
      value = create_param(gtkINT, INT_TO_WORD(g_value_get_enum(val)));
      break;
    case G_TYPE_FLAGS:  
      value = create_param(gtkINT, INT_TO_WORD(g_value_get_flags(val)));
      break;
    case G_TYPE_FLOAT:  
      value = create_param(gtkREAL, REAL_TO_WORD(g_value_get_float(val)));
      break;
    case G_TYPE_DOUBLE: 
      value = create_param(gtkREAL, REAL_TO_WORD(g_value_get_double(val)));
      break;
    case G_TYPE_STRING: 
     value = create_param(gtkSTRING, STRING_TO_WORD(g_value_get_string(val)));
      break;
    default:
      if (i==0)
	widget = g_value_peek_pointer(val);
      else
	value = create_object(G_VALUE_TYPE(val), g_value_peek_pointer(val));
    }
    if (!widget) paramlist = push_front(paramlist,value);
  }
  
  word widgetW;
  if (GTK_IS_OBJECT(widget))
    widgetW = OBJECT_TO_WORD(widget, TYPE_GTK_OBJECT);
  else
    widgetW = OBJECT_TO_WORD(widget, (G_IS_OBJECT(widget) ? TYPE_G_OBJECT 
                                                          : TYPE_UNKNOWN));
  Tuple *tup = Tuple::New(3);
  tup->Init(0,INT_TO_WORD(connid));
  tup->Init(1,widgetW);
  tup->Init(2,paramlist);
  
  put_on_stream(&eventStream, tup->ToWord());

  //  g_message("event has been put on stream");
}

// the generic_marshaller is attached to every GObject (instead of the
// the alice callback function, which cannot be invoked in C)
static void generic_marshaller(GClosure *closure, GValue *return_value, 
			       guint n_param_values, const GValue *param_values, 
			       gpointer, gpointer marshal_data) {

  gint connid = GPOINTER_TO_INT(marshal_data);

  //  g_print("event occured: %d\n", connid);
  had_events = true;

  sendArgsToStream(connid,n_param_values,param_values);

  if (G_VALUE_HOLDS(return_value, G_TYPE_BOOLEAN))
    g_value_set_boolean(return_value,
			(GPOINTER_TO_INT(closure->data) == 2) ? TRUE : FALSE);
}

static word SignalConnect(void *object, char *signalname, bool after) {
  gint userData = (!strcmp(signalname, "delete-event") ? 2 : 1);
  GClosure *closure = g_cclosure_new(G_CALLBACK(generic_marshaller),
                                     GINT_TO_POINTER(userData), NULL);
  gulong connid = g_signal_connect_closure(G_OBJECT(object), signalname, 
					   closure, after ? TRUE : FALSE); 
  g_closure_set_meta_marshal(closure,GINT_TO_POINTER(connid),
			     generic_marshaller);
  return INT_TO_WORD(static_cast<int>(connid));
}

DEFINE3(NativeCore_signalConnect) {
  DECLARE_OBJECT(obj,x0);
  DECLARE_CSTRING(signalname,x1);
  DECLARE_BOOL(after,x2);
  RETURN(SignalConnect(obj, signalname, after));
} END

DEFINE2(NativeCore_signalDisconnect) {
  DECLARE_OBJECT(obj,x0);
  DECLARE_INT(handler_id,x1);
  g_signal_handler_disconnect(G_OBJECT(obj), static_cast<gulong>(handler_id));
  RETURN_UNIT;
} END

DEFINE2(NativeCore_signalHandlerBlock) {
  DECLARE_OBJECT(obj,x0);
  DECLARE_INT(handler_id,x1);
  g_signal_handler_block(G_OBJECT(obj), static_cast<gulong>(handler_id));
  RETURN_UNIT;
} END

DEFINE2(NativeCore_signalHandlerUnblock) {
  DECLARE_OBJECT(obj,x0);
  DECLARE_INT(handler_id,x1);
  g_signal_handler_unblock(G_OBJECT(obj), static_cast<gulong>(handler_id));
  RETURN_UNIT;
} END

DEFINE1(NativeCore_getEventStream) {
  destroyCallback = x0;
  RETURN(eventStream);
} END

////////////////////////////////////////////////////////////////////////
// SIGNAL MAP FUNCTIONS

static void AddToSignalMap(word connid, word callback, word key) {
  Map::FromWordDirect(signalMap)->Put(connid, callback);
  Map *signalMap2_ = Map::FromWordDirect(signalMap2);
  word ids = signalMap2_->CondGet(key, INT_TO_WORD(Types::nil));
  signalMap2_->Put(key, push_front(ids, connid));
}

DEFINE3(NativeCore_signalMapAdd) {
  // x0 = connid, x1 = callback-fn
  AWAIT(connid, x0);
  DECLARE_OBJECT(p, x2);
  word key = Store::UnmanagedPointerToWord(p);
  AddToSignalMap(connid, x1, key);
  RETURN_UNIT;
} END

DEFINE1(NativeCore_signalMapRemove) {
  // x0 = connid to remove 
  //g_message("removing signal #%d", Store::WordToInt(x0));
  AWAIT(connid, x0);
  Map::FromWordDirect(signalMap)->Remove(connid);
  RETURN_UNIT;
} END

DEFINE2(NativeCore_signalMapCondGet) {
  // x0 = connid to get, x1 = alternative
  AWAIT(connid, x0);
  RETURN(Map::FromWordDirect(signalMap)->CondGet(connid, x1));
} END

DEFINE1(NativeCore_signalMapGetConnIds) {
  // x0 = object
  DECLARE_OBJECT(p,x0);
  word key = Store::UnmanagedPointerToWord(p);
  Map* sm2 = Map::FromWordDirect(signalMap2);
  word ids = sm2->CondGet(key, INT_TO_WORD(Types::nil));
  sm2->Remove(key);
  RETURN(ids);
} END

//////////////////////////////////////////////////////////////////////
// WEAK MAP FUNCTIONS

class MyFinalization: public Finalization {
public:
  void Finalize(word value) {
    Tuple *t = Tuple::FromWord(value);
    void *p  = Store::WordToUnmanagedPointer(t->Sel(0));
    int type = Store::WordToInt(t->Sel(1));
//      g_print("Finalize: (Pointer: %p, Type: %s)\n", p, getObjectType(type));
    __unrefObject(p, type);
  }
};

///////////////////////////////////////////////////////////////////////
// OBJECT HANDLING

// convert a pointer to an object, and add it to the weak map if necessary
word OBJECT_TO_WORD_implementation(const void *pointer, int type) {
  void *pointer_ = const_cast<void *>(pointer);
  word key = Store::UnmanagedPointerToWord(pointer_);
  if (pointer == NULL) {
    Tuple *object = Tuple::New(3);
    object->Init(0, key);
    object->Init(1, Store::IntToWord(type));
    object->Init(2, Store::IntToWord(0));
    return object->ToWord();
  } else {
    WeakMap *objectMap = WeakMap::FromWordDirect(weakDict);
    if (objectMap->IsMember(key)) {
      Tuple *object = Tuple::FromWordDirect(objectMap->Get(key));
      int objectType = Store::DirectWordToInt(object->Sel(1));
      if ((type != objectType) &&
          (objectType != TYPE_UNKNOWN) &&
          (type != TYPE_UNKNOWN) ) {
	fprintf(stderr, "OBJECT_TO_WORD: type warning: old %s != new %s\n",
		getObjectType(objectType), getObjectType(type));
	fflush(stderr);
      }
      return object->ToWord();
    }
    else {
      Tuple *object = Tuple::New(3);
      object->Init(0, key);
      object->Init(1, Store::IntToWord(type));
      object->Init(2, Store::IntToWord(0));
      objectMap->Put(key, object->ToWord());
      __refObject(pointer_, type);
      // Register default destroy event for gtk objects
      if (type == TYPE_GTK_OBJECT) {
	word connid = SignalConnect(pointer_, "destroy", true);
	AddToSignalMap(connid, destroyCallback, key);
      }
      return object->ToWord();
    }
  }
}

DEFINE1(NativeCore_unrefObject) {
  DECLARE_OBJECT_WITH_TYPE(p,type,x0);
  __unrefObject(p,type);  
  RETURN_UNIT;
} END

//////////////////////////////////////////////////////////////////////
// INIT AND MAIN LOOP FUNCTIONS

static void __die(char *s) {
  g_warning(s);
  exit(0);
}

static void
default_delete_text_handler(gint oldOff, gint newOff, gchar* txt) {
  return;
}

static void Init() {
  static const u_int INITIAL_MAP_SIZE = 256; // TODO: find appropriate size
  // Init global data
  eventStream = (Future::New())->ToWord();
  RootSet::Add(eventStream);
  weakDict = WeakMap::New(INITIAL_MAP_SIZE, new MyFinalization())->ToWord();
  RootSet::Add(weakDict);
  signalMap = Map::New(INITIAL_MAP_SIZE)->ToWord();
  RootSet::Add(signalMap);
  signalMap2 = Map::New(INITIAL_MAP_SIZE)->ToWord();
  RootSet::Add(signalMap2);
  had_events = false;
  destroyCallback = Store::IntToWord(0);
  RootSet::Add(destroyCallback);
  // We use the SEAM Broker to distribute the OBJECT_TO_WORD implementation
  word wOBJECT_TO_WORD =
    Store::UnmanagedPointerToWord((void *) OBJECT_TO_WORD_implementation);
  OBJECT_TO_WORD_instance = OBJECT_TO_WORD_implementation;
  Broker::Register(String::New(Alice_Gtk_OBJECT_TO_WORD), wOBJECT_TO_WORD);
  /*
   * On Windows, Gdk blocks on stdin during init if input redirection is used,
   * as for example within emacs.
   * The solution is to reconnect stdin to a pipe and undo this change after
   * gtk init. gdk still obtains its input.
   */
#if defined(__CYGWIN32__) || defined(__MINGW32__)
  HANDLE stdInHandle, pipeInHandle, pipeOutHandle;
  SECURITY_ATTRIBUTES saAttr;
  saAttr.nLength              = sizeof(SECURITY_ATTRIBUTES);
  saAttr.lpSecurityDescriptor = NULL;
  saAttr.bInheritHandle       = TRUE;
  stdInHandle = GetStdHandle(STD_INPUT_HANDLE);
  if (!CreatePipe(&pipeInHandle, &pipeOutHandle, &saAttr, 0))
    __die("error during init: cannot create pipe");
  if (!SetStdHandle(STD_INPUT_HANDLE, pipeInHandle))
    __die("error during init: cannot redirect stdin");

  /*
   * Praise the infinite wisdom of the Windows API designers!
   * If the parent Windows process started Alice with a STARTUPINFO structure
   * (like Emacs does, also praise their wisdom for using this nonsense!)
   * then the first call to ShowWindow will have no predictable effect.
   * Since Gtk ignores this problem (let's praise their wisdom as well),
   * this means that the first window we try to create might not show up.
   * For instance, this happens to the Inspector under Windows under Emacs.
   * To work around this intellectual diarrhoea, we create a dummy window here
   * and delete it immediately. - AR
   */
  HINSTANCE hInst;
  HWND hWnd = CreateWindow("BUTTON", "", 0, 0, 0, 0, 0, NULL, NULL, hInst, NULL);
  ShowWindow(hWnd, SW_SHOWNORMAL);
  DestroyWindow(hWnd);
#endif
  gtk_init(NULL,NULL);
#if defined(__CYGWIN32__) || defined(__MINGW32__)
  if (!SetStdHandle(STD_INPUT_HANDLE, stdInHandle))
    __die("error during init: cannot reverse stdin redirecting");
#endif
  // Init types
  G_LIST_TYPE = g_type_from_name("GList");
  G_SLIST_TYPE = g_type_from_name("GSList");
  GDK_EVENT_TYPE = gdk_event_get_type();
  GTK_OBJECT_TYPE = g_type_from_name("GtkObject");

  // Provide special events

  GClosure *default_closure;
  GType param_types[3];
  
  default_closure = g_cclosure_new(G_CALLBACK(default_delete_text_handler),
                                   NULL, NULL);

  param_types[0] = G_TYPE_INT;
  param_types[1] = G_TYPE_INT;
  param_types[2] = G_TYPE_STRING;

  g_signal_newv("delete-text",
                GTK_TYPE_TEXT_BUFFER,
                (GSignalFlags) (G_SIGNAL_RUN_LAST | G_SIGNAL_NO_RECURSE | G_SIGNAL_NO_HOOKS),
                default_closure,
                NULL, NULL,
                g_cclosure_user_marshal_VOID__INT_INT_STRING,
                G_TYPE_NONE,
                3,
                param_types);
}

DEFINE0(NativeCore_handlePendingEvents) {
  while (gtk_events_pending())
    gtk_main_iteration();
  bool ret = had_events;
  had_events = false;
  RETURN(BOOL_TO_WORD(ret));
} END

///////////////////////////////////////////////////////////////////////
// DEBUG FUNCTIONS

DEFINE1(NativeCore_printObject) {
  DECLARE_OBJECT_WITH_TYPE(obj,type,x0);
  g_print("printObject: Tuple %p = (Pointer: %p, Type: %s)\n",
	  x0, obj, getObjectType(type));
  RETURN_UNIT;
} END

DEFINE0(NativeCore_forceGC) {
  StatusWord::SetStatus(Store::GCStatus());
  RETURN_UNIT;
} END

///////////////////////////////////////////////////////////////////////
// CHARACTER SET CONVERSION FUNCTIONS

DEFINE1(NativeCore_latin1ToUtf8) {
  DECLARE_STRING(str, x0);
  gsize written;
  GError *error = NULL;
  gchar *ret = g_convert_with_fallback(str->ExportC(),
                                       str->GetSize(),
                                       "UTF-8","ISO-8859-1",
                                       "X", NULL, &written,
                                       &error);
  if (error != NULL)
    RETURN1(String::New("")->ToWord());
  RETURN1(STRING_TO_WORD(ret));
} END

DEFINE1(NativeCore_utf8ToLatin1) {
  DECLARE_STRING(str, x0);
  gsize written;
  GError *error = NULL;
  gchar *ret = g_convert_with_fallback(str->ExportC(),
                                       str->GetSize(),
                                       "ISO-8859-1","UTF-8", 
                                       "X", NULL, &written,
                                       &error);
  if (error != NULL)
    RETURN1(String::New("")->ToWord());
  RETURN1(STRING_TO_WORD(ret));
} END

////////////////////////////////////////////////////////////////////////
// propertySetting

DEFINE3(NativeCore_propSetString) {
    DECLARE_OBJECT(ob, x0);
    DECLARE_CSTRING(name, x1);
    DECLARE_CSTRING(str, x2);
    GValue v;
    g_value_init (&v, G_TYPE_STRING);
    g_value_set_string (&v, str);
    g_object_set_property ((GObject*)ob, (const gchar*)name, &v);
    RETURN_UNIT;
} END

DEFINE3(NativeCore_propSetBool) {
    DECLARE_OBJECT(ob, x0);
    DECLARE_CSTRING(name, x1);
    DECLARE_BOOL(b, x2);
    GValue v;
    g_value_init (&v, G_TYPE_BOOLEAN);
    g_value_set_boolean (&v, b);
    g_object_set_property ((GObject*)ob, (const gchar*)name, &v);
    RETURN_UNIT;
} END


DEFINE3(NativeCore_propSetInt) {
    DECLARE_OBJECT(ob, x0);
    DECLARE_CSTRING(name, x1);
    DECLARE_INT(b, x2);
    GValue v;
    g_value_init (&v, G_TYPE_INT);
    g_value_set_int (&v, b);
    g_object_set_property ((GObject*)ob, (const gchar*)name, &v);
    RETURN_UNIT;
} END

DEFINE2(NativeCore_propString) {
    DECLARE_OBJECT(ob, x0);
    DECLARE_CSTRING(name, x1);
    GValue v;
    g_value_init (&v, G_TYPE_STRING);
    g_object_get_property ((GObject*)ob, (const gchar*)name, &v);
    RETURN1(String::New(g_value_get_string (&v))->ToWord ());
} END

DEFINE2(NativeCore_propInt) {
    DECLARE_OBJECT(ob, x0);
    DECLARE_CSTRING(name, x1);
    GValue v;
    g_value_init (&v, G_TYPE_INT);
    g_object_get_property ((GObject*)ob, (const gchar*)name, &v);
    RETURN_INT(g_value_get_int (&v));
} END

DEFINE2(NativeCore_propBool) {
    DECLARE_OBJECT(ob, x0);
    DECLARE_CSTRING(name, x1);
    GValue v;
    g_value_init (&v, G_TYPE_BOOLEAN);
    g_object_get_property ((GObject*)ob, (const gchar*)name, &v);
    RETURN_BOOL(g_value_get_boolean (&v));
} END


////////////////////////////////////////////////////////////////////////
// setLogMode -- enable/disable logging

static void null_log_handler (const gchar *dom, GLogLevelFlags l, const gchar *msg, 
        gpointer d) {
    // do nothing
}

DEFINE2(NativeCore_setLogMode) {
    DECLARE_STRING(dom, x0);
    DECLARE_INT(mode, x1);      // constructors of no arguments = int
    switch (mode) {
        case 0: // LOG_MODE_DEFAULT
            g_log_set_handler (dom->ExportC (), (GLogLevelFlags)(G_LOG_LEVEL_MASK | G_LOG_FLAG_FATAL
                    | G_LOG_FLAG_RECURSION), g_log_default_handler, NULL);
            break;

        case 1: // LOG_MODE_NULL
            g_log_set_handler (dom->ExportC (), (GLogLevelFlags)(G_LOG_LEVEL_MASK | G_LOG_FLAG_FATAL
                    | G_LOG_FLAG_RECURSION), null_log_handler, NULL);
            break;

        default:
            Assert(false);
    }
    RETURN_UNIT;
} END

///////////////////////////////////////////////////////////////////////
word InitComponent() {
  Record *record = Record::New(25);
  Init();
  INIT_STRUCTURE(record, "NativeCore", "null", 
		 NativeCore_null, 0);
  INIT_STRUCTURE(record, "NativeCore", "gtkTrue", 
		 NativeCore_gtkTrue, 0);
  INIT_STRUCTURE(record, "NativeCore", "gtkFalse", 
		 NativeCore_gtkFalse, 0);

  INIT_STRUCTURE(record, "NativeCore", "signalConnect", 
		 NativeCore_signalConnect, 3);
  INIT_STRUCTURE(record, "NativeCore", "signalDisconnect", 
		 NativeCore_signalDisconnect, 2);
  INIT_STRUCTURE(record, "NativeCore", "getEventStream", 
		 NativeCore_getEventStream, 1);

  INIT_STRUCTURE(record, "NativeCore", "signalHandlerBlock", 
		 NativeCore_signalHandlerBlock, 2);
  INIT_STRUCTURE(record, "NativeCore", "signalHandlerUnblock", 
		 NativeCore_signalHandlerUnblock, 2);

  INIT_STRUCTURE(record, "NativeCore", "signalMapAdd",
		 NativeCore_signalMapAdd, 3);
  INIT_STRUCTURE(record, "NativeCore", "signalMapRemove",
		 NativeCore_signalMapRemove, 1);
  INIT_STRUCTURE(record, "NativeCore", "signalMapCondGet",
		 NativeCore_signalMapCondGet, 2);
  INIT_STRUCTURE(record, "NativeCore", "signalMapGetConnIds",
		 NativeCore_signalMapGetConnIds, 1);

  INIT_STRUCTURE(record, "NativeCore", "unrefObject", 
		 NativeCore_unrefObject, 1);

  INIT_STRUCTURE(record, "NativeCore", "handlePendingEvents", 
		 NativeCore_handlePendingEvents, 0);

  INIT_STRUCTURE(record, "NativeCore", "printObject", 
		 NativeCore_printObject, 1);
  INIT_STRUCTURE(record, "NativeCore", "forceGC",
		 NativeCore_forceGC, 0);
  INIT_STRUCTURE(record, "NativeCore", "latin1ToUtf8",
		 NativeCore_latin1ToUtf8, 1);
  INIT_STRUCTURE(record, "NativeCore", "utf8ToLatin1",
		 NativeCore_utf8ToLatin1, 1);

  INIT_STRUCTURE(record, "NativeCore", "setLogMode",
                NativeCore_setLogMode, 2);

  INIT_STRUCTURE(record, "NativeCore", "propSetInt",
            NativeCore_propSetInt, 3);
  INIT_STRUCTURE(record, "NativeCore", "propSetString",
            NativeCore_propSetString, 3);
  INIT_STRUCTURE(record, "NativeCore", "propSetBool",
            NativeCore_propSetBool, 3);

  INIT_STRUCTURE(record, "NativeCore", "propInt",
            NativeCore_propInt, 2);
  INIT_STRUCTURE(record, "NativeCore", "propString",
            NativeCore_propString, 2);
  INIT_STRUCTURE(record, "NativeCore", "propBool",
            NativeCore_propBool, 2);


  RETURN_STRUCTURE("NativeCore$", record);
}
