//
// Authors:
//   Thorsten Brunklaus <brunklaus@ps.uni-sb.de>
//
// Copyright:
//   Thorsten Brunklaus, 2002
//
// Last Change:
//   $Date$ by $Author$
//   $Revision$
//

#ifndef __ALICE__NATIVE_CODE_INTERPRETER_HH__
#define __ALICE__NATIVE_CODE_INTERPRETER_HH__

#if defined(INTERFACE)
#pragma interface "alice/NativeCodeInterpreter.hh"
#endif

#include "generic/Interpreter.hh"

typedef Interpreter::Result (*native_fun)(class NativeCodeFrame *);

class NativeCodeInterpreter : public Interpreter {
public:
  // Exported NativeCodeInterpreter Instance
  static NativeCodeInterpreter *self;
  // NativeCodeInterpreter Constructor
  NativeCodeInterpreter() : Interpreter() {}
  // NativeCodeInterpreter Static Constructor
  static void Init() {
    self = new NativeCodeInterpreter();
  }
  // Handler Methods
  virtual Block *GetAbstractRepresentation(Block *blockWithHandler);
  // Frame Handling
  virtual void PushCall(TaskStack *taskStack, Closure *closure);
#if defined(ALICE_IMPLICIT_KILL)
  virtual void PurgeFrame(word frame);
#endif
  // Execution
  virtual Result Run(TaskStack *taskStack);
  virtual Result Handle(word exn, Backtrace *trace, TaskStack *taskStack);
  // Debugging
  virtual const char *Identify();
  virtual void DumpFrame(word frame);
#if defined(ALICE_PROFILE)
  // Profiling
  virtual word GetProfileKey(StackFrame *frame);
  virtual word GetProfileKey(ConcreteCode *concreteCode);
  virtual String *GetProfileName(StackFrame *frame);
  virtual String *GetProfileName(ConcreteCode *concreteCode);
#endif
};

#endif
