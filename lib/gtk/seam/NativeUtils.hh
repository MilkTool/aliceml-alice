#ifndef _UNSAFE_UTILS_HH_
#define _UNSAFE_UTILS_HH_

#include "Alice.hh"
#include "MyNativeAuthoring.hh"
#include "generic/RootSet.hh"

#include <gtk/gtk.h>

typedef struct { 
  int initCount;   
  void (*func) (Record *record);
} includeData;

static word TypeMismatchConstructor;

Record *CreateRecord(includeData data[], int size, int baseCount) {
  int total = baseCount;
  for (int i = 0; i < size; i++)
    total += data[i].initCount;
  Record *record = Record::New(total);

  TypeMismatchConstructor =
    UniqueConstructor::New(String::New("GtkTypes.TypeMismatch"))->ToWord();
  RootSet::Add(TypeMismatchConstructor);
  
  for (int i = 0; i < size; i++)
    if (data[i].func)
      (data[i].func)(record);
  return record;
}

word createExn(void *pointer, const gchar *tname, const gchar* funname, 
	       int argno) {
  char err[4000];
  g_snprintf(err, 4000, 
	     "%s: Type mismatch in argument %d: needed type %s, got type %s", 
	     funname, argno+1, tname, G_OBJECT_TYPE_NAME(pointer));            
  g_print("%s\n", err);                                       
  ConVal *conVal =
    ConVal::New(Constructor::FromWordDirect(TypeMismatchConstructor), 1);
  conVal->Init(0, String::New(err)->ToWord());     
  return conVal->ToWord();
}

#ifdef DEBUG
#define CHECK_TYPE(pointer, tname, funname, argno) {                         \
  if (G_IS_OBJECT(pointer) &&                                                \
      g_type_is_a(G_OBJECT_TYPE(pointer), g_type_from_name(tname)) == FALSE) \
      { RAISE(createExn(pointer,tname,funname,argno)); }                     \
  }
#else
#define CHECK_TYPE(pointer, tname, funname, argno) ;
#endif

/***********************************************************************/

#define DECLARE_GLIST(l, x, ltype, ltype2, F)               \
  ltype *l = NULL;                                          \
  {                                                         \
    DECLARE_LIST_ELEMS(l##__tagval, l##__length, x,         \
      { F(l##__value,l##__tagval->Sel(0));                  \
        l = ltype2##_append(l, l##__value);                 \
      } );                                                  \
  }

#define __RETURN_STRING(s) \
  String::New(reinterpret_cast<const char *>(s))->ToWord()

#define __RETURN_LIST_HELP(lname,ltype,convertfun)          \
  word tail = Store::IntToWord(1); /*nil*/                  \
  for (guint i = ltype##_length(lname); i > 0; i--) {       \
    TagVal *cons = TagVal::New(0,2);                        \
    cons->Init(0,convertfun(ltype##_nth_data(lname,i-1)));  \
    cons->Init(1,tail);                                     \
    tail = cons->ToWord();                                  \
  }                                                         \
  return tail;

word GListToObjectList(GList *list) {
  __RETURN_LIST_HELP(list, g_list, Store::UnmanagedPointerToWord);
}

word GSListToObjectList(GSList *list) {
  __RETURN_LIST_HELP(list, g_slist, Store::UnmanagedPointerToWord);
}

word GListToStringList(GList *list) {
  __RETURN_LIST_HELP(list, g_list, __RETURN_STRING);
}

word GSListToStringList(GSList *list) {
  __RETURN_LIST_HELP(list, g_slist, __RETURN_STRING);
}


#endif
