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

#ifndef __ALICE__ALICE_CONCRETE_CODE_HH__
#define __ALICE__ALICE_CONCRETE_CODE_HH__

#if defined(INTERFACE)
#pragma interface "alice/AliceConcreteCode.hh"
#endif

#include <cstdio>
#include "generic/ConcreteCode.hh"
#include "alice/Data.hh"
#include "alice/AbstractCodeInterpreter.hh"

class AliceConcreteCode: private ConcreteCode {
private:
  enum { ABSTRACT_CODE_POS, TRANSFORM_POS, SIZE };
public:
  using Block::ToWord;

  static word New(TagVal *abstractCode);
  TagVal *GetAbstractCode() {
    return TagVal::FromWordDirect(Get(ABSTRACT_CODE_POS));
  }
  Block *GetAbstractRepresentation() {
    return Store::DirectWordToBlock(Get(TRANSFORM_POS));
  }
  void Disassemble(std::FILE *file);

  static AliceConcreteCode *FromWord(word x) {
    ConcreteCode *b = ConcreteCode::FromWord(x);
    Assert(b == INVALID_POINTER ||
	   b->GetInterpreter() == AbstractCodeInterpreter::self);
    return static_cast<AliceConcreteCode *>(b);
  }
  static AliceConcreteCode *FromWordDirect(word x) {
    ConcreteCode *b = ConcreteCode::FromWordDirect(x);
    Assert(b->GetInterpreter() == AbstractCodeInterpreter::self);
    return static_cast<AliceConcreteCode *>(b);
  }
};

#endif
