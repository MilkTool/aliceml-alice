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

#ifndef __ALICE__ABSTRACT_CODE_INTERPRETER_HH__
#define __ALICE__ABSTRACT_CODE_INTERPRETER_HH__

#if defined(INTERFACE)
#pragma interface "alice/AbstractCodeInterpreter.hh"
#endif

#include "generic/Interpreter.hh"

class DllExport AbstractCodeInterpreter: public Interpreter {
private:
  AbstractCodeInterpreter(): Interpreter() {}
public:
  static AbstractCodeInterpreter *self;

  static void Init();

  virtual Transform *GetAbstractRepresentation(ConcreteRepresentation *);

  virtual Result Run();
  virtual Result Handle();
  virtual u_int GetInArity(ConcreteCode *concreteCode);
  virtual void PushCall(Closure *closure);
  virtual const char *Identify();
  virtual void DumpFrame(word frame);
#if PROFILE
  virtual word GetProfileKey(StackFrame *frame);
  virtual word GetProfileKey(ConcreteCode *concreteCode);
  virtual String *GetProfileName(StackFrame *frame);
  virtual String *GetProfileName(ConcreteCode *concreteCode);
#endif
};

#endif
