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
#ifndef __JAVA__BYTE_CODE_INTERPRETER_HH__
#define __JAVA__BYTE_CODE_INTERPRETER_HH__

#if defined(INTERFACE)
#pragma interface "java/ByteCodeInterpreter.hh"
#endif

#include "generic/Interpreter.hh"

class DllExport ByteCodeInterpreter : public Interpreter {
private:
  ByteCodeInterpreter() : Interpreter() {}
public:
  static ByteCodeInterpreter *self;

  static void Init();

  virtual Transform *GetAbstractRepresentation(ConcreteRepresentation *);

  virtual Result Run();
  virtual Result Handle(word data);
  virtual u_int GetInArity(ConcreteCode *concreteCode);
  virtual void PushCall(Closure *closure);
  virtual const char *Identify();
  virtual void DumpFrame(word wFrame);

  //--** move this to the JavaLanguageLayer?:
  static void FillStackTraceElement(word wFrame, Object *stackTraceElement);
};

#endif
