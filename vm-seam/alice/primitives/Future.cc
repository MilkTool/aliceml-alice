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

#include "emulator/Transients.hh"
#include "emulator/Closure.hh"
#include "emulator/Interpreter.hh"
#include "emulator/Scheduler.hh"
#include "emulator/Authoring.hh"

DEFINE1(Future_alarmQuote) {
  RETURN_UNIT; //--** not implemented
} END

DEFINE1(Future_await) {
  if (Store::WordToTransient(x0) != INVALID_POINTER) {
    REQUEST(x0);
  } else {
    RETURN(x0);
  }
} END

DEFINE1(Future_byneed) {
  RETURN(Byneed::New(x0)->ToWord());
} END

DEFINE1(Future_concur) {
  Future *future       = Future::New();
  TaskStack *taskStack = TaskStack::New();
  ByneedInterpreter::PushFrame(taskStack, future);
  Scheduler::NewThread(x0, Interpreter::EmptyArg(), taskStack);
  RETURN(future->ToWord());
} END

DEFINE1(Future_isFailed) {
  Transient *transient = Store::WordToTransient(x0);
  RETURN_BOOL(transient != INVALID_POINTER &&
	      transient->GetLabel() == CANCELLED_LABEL);
} END

DEFINE1(Future_isFuture) {
  Transient *transient = Store::WordToTransient(x0);
  RETURN_BOOL(transient != INVALID_POINTER &&
	      transient->GetLabel() == FUTURE_LABEL);
} END

void PrimitiveTable::RegisterFuture() {
  RegisterUniqueConstructor("Future.Future");
  Register("Future.alarm'", Future_alarmQuote, -1);
  Register("Future.await", ::Future_await, -1);
  Register("Future.byneed", Future_byneed, -1);
  Register("Future.concur", Future_concur, -1);
  Register("Future.isFailed", Future_isFailed, -1);
  Register("Future.isFuture", Future_isFuture, -1);
}
