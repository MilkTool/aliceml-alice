//
// Authors:
//   Thorsten Brunklaus <brunklaus@ps.uni-sb.de>
//   Leif Kornstaedt <kornstae@ps.uni-sb.de>
//
// Copyright:
//   Thorsten Brunklaus, 2002
//   Leif Kornstaedt, 2002
//
// Last Change:
//   $Date$ by $Author$
//   $Revision$
//

#ifndef __ALICE__LAZY_SEL_INTERPRETER_HH__
#define __ALICE__LAZY_SEL_INTERPRETER_HH__

#if defined(INTERFACE)
#pragma implementation "alice/LazySelInterpreter.hh"
#endif

#include "generic/Interpreter.hh"
#include "generic/ConcreteCode.hh"
#include "generic/Closure.hh"
#include "generic/UniqueString.hh"

class LazySelInterpreter: public Interpreter {
private:
  LazySelInterpreter(): Interpreter() {}
public:
  static LazySelInterpreter *self;

  static void Init() {
    self = new LazySelInterpreter();
  }

  virtual Result Run();
  virtual u_int GetInArity(ConcreteCode *concreteCode);
  virtual void PushCall(Closure *closure);
  virtual const char *Identify();
  virtual void DumpFrame(word frame);
};

class LazySelClosure: public Closure {
public:
  enum { RECORD_POS, LABEL_POS, SIZE };

  static LazySelClosure *New(word record, UniqueString *label) {
    ConcreteCode *concreteCode =
      ConcreteCode::New(LazySelInterpreter::self, 0);
    Closure *closure = Closure::New(concreteCode->ToWord(), SIZE);
    closure->Init(RECORD_POS, record);
    closure->Init(LABEL_POS, label->ToWord());
    return static_cast<LazySelClosure *>(closure);
  }

  word GetRecord() {
    return Sub(RECORD_POS);
  }
  UniqueString *GetLabel() {
    return UniqueString::FromWordDirect(Sub(LABEL_POS));
  }
};

#endif
