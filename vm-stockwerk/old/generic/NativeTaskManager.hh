//
// Author:
//   Leif Kornstaedt <kornstae@ps.uni-sb.de>
//
// Copyright:
//   Leif Kornstaedt, 2000
//
// Last Change:
//   $Date$ by $Author$
//   $Revision$
//

#ifndef __BUILTINS__PRIMITIVE_HH__
#define __BUILTINS__PRIMITIVE_HH__

#pragma interface "builtins/Primitive.hh"

#include "datalayer/alicedata.hh"

class TaskStack;

class Primitive {
private:
  typedef Interpreter::Result (*function)(TaskStack *);

  static void Register(const char *name, word value);
  static void Register(const char *name, function value, u_int arity);

  static void RegisterInternal();
  static void RegisterUnqualified();
  static void RegisterArray();
  static void RegisterChar();
  static void RegisterFuture();
  static void RegisterGeneral();
  static void RegisterGlobalStamp();
  static void RegisterHole();
  static void RegisterInt();
  static void RegisterList();
  static void RegisterMath();
  static void RegisterOption();
  static void RegisterReal();
  static void RegisterString();
  static void RegisterThread();
  static void RegisterUnsafe();
  static void RegisterVector();
  static void RegisterWord();
public:
  static void Init();
  static word Lookup(const char *name);
};

#endif __BUILTINS__PRIMITIVE_HH__
