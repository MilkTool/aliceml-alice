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

#ifndef __ALICE__PRIMITIVE_TABLE_HH__
#define __ALICE__PRIMITIVE_TABLE_HH__

#if defined(INTERFACE)
#pragma interface "alice/PrimitiveTable.hh"
#endif

#include "generic/Interpreter.hh"
#include "generic/Primitive.hh"

class PrimitiveTable {
private:
  static word valueTable;
  static word functionTable;

  static void Register(const char *name, word value);
  static void Register(const char *name,
		       Interpreter::function value, u_int arity);
  static void RegisterUniqueConstructor(const char *name);

  static void RegisterUnqualified();
  static void RegisterArray();
  static void RegisterChar();
  static void RegisterFuture();
  static void RegisterGeneral();
  static void RegisterGlobalStamp();
  static void RegisterHole();
  static void RegisterInt();
  static void RegisterLargeWord();
  static void RegisterList();
  static void RegisterMath();
  static void RegisterOption();
  static void RegisterReal();
  static void RegisterRef();
  static void RegisterString();
  static void RegisterThread();
  // static void RegisterTimer();
  static void RegisterUniqueString();
  static void RegisterUnsafe();
  static void RegisterVector();
  static void RegisterWord();
  static word Lookup(word table, Chunk *name);
public:
  static word Future_Future;
  static word General_Chr;
  static word General_Div;
  static word General_Overflow;
  static word General_Size;
  static word General_Subscript;
  static word Hole_Cyclic;
  static word Hole_Hole;
  static word Thread_Terminated;

  static void Init();
  static word LookupValue(Chunk *name);
  static word LookupFunction(Chunk *name);
};

#endif
