//
// Author:
//   Leif Kornstaedt <kornstae@ps.uni-sb.de>
//
// Copyright:
//   Leif Kornstaedt, 2002
//
// Last Change:
//   $Date$ by $Author$
//   $Revision$
//

#ifndef __JAVA__NATIVE_METHOD_TABLE_HH__
#define __JAVA__NATIVE_METHOD_TABLE_HH__

#if defined(INTERFACE)
#pragma interface "java/NativeMethodTable.hh"
#endif

#include "adt/HashTable.hh"
#include "generic/RootSet.hh"
#include "generic/Closure.hh"
#include "java/Data.hh"

class DllExport NativeMethodTable {
private:
  static const u_int initialSize = 19;
  static word wTable;
public:
  static void Init() {
    wTable = HashTable::New(HashTable::BLOCK_KEY, initialSize)->ToWord();
    RootSet::Add(wTable);
  }

  static Closure *Lookup(JavaString *className, JavaString *name,
			 JavaString *descriptor) {
    HashTable *table = HashTable::FromWordDirect(wTable);
    word key = className->Concat(name)->Concat(descriptor)->ToWord();
    if (!table->IsMember(key)) return INVALID_POINTER;
    return Closure::FromWordDirect(table->GetItem(key));
  }
};

#endif
