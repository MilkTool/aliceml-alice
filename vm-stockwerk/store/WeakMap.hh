//
// Author:
//   Thorsten Brunklaus <brunklaus@ps.uni-sb.de>
//
// Copyright:
//   Thorsten Brunklaus, 2002
//
// Last Change:
//   $Date$ by $Author$
//   $Revision$
//
#ifndef __STORE__WEAK_MAP_HH__
#define __STORE__WEAK_MAP_HH__

#if defined(INTERFACE)
#pragma interface "store/WeakMap.hh"
#endif

#include "store/BaseMap.hh"

class TokenKey {
public:
  static u_int Hash(word key, u_int size) {
    Assert(PointerOp::IsInt(key));
    return ((u_int) key % size);
  }
  static bool Equals(word a, word b) {
    return a == b;
  }
};

class DllExport Finalization {
public:
  virtual void Finalize(word value) = 0;
};

class DllExport WeakMap : public BaseMap<TokenKey> {
protected:
  friend class Store;

  word GetHandler() {
    return static_cast<Block *>(this)->GetArg(RESERVED_POS);
  }
public:
  static WeakMap *New(u_int size, Finalization *handler) {
    BaseMap<TokenKey> *map = BaseMap<TokenKey>::New(WEAK_MAP_LABEL, size);
    static_cast<Block *>(map)
      ->InitArg(RESERVED_POS, Store::UnmanagedPointerToWord(handler));
    Store::RegisterWeakDict(static_cast<WeakMap *>(map));
    return static_cast<WeakMap *>(map);
  }
  static WeakMap *FromWord(word x) {
    Block *map = Store::WordToBlock(x);
    Assert(map == INVALID_POINTER || map->GetLabel() == WEAK_MAP_LABEL);
    return static_cast<WeakMap *>(map);
  }
  static WeakMap *FromWordDirect(word x) {
    Block *map = Store::DirectWordToBlock(x);
    Assert(map->GetLabel() == WEAK_MAP_LABEL);
    return static_cast<WeakMap *>(map);
  }
};

#endif
