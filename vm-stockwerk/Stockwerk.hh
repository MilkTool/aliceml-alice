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

#ifndef __STOW_HH__
#define __STOW_HH__

#define STOCKWERK_FOREIGN

#include "store/Store.hh"
#include "adt/HashTable.hh"
#include "adt/Queue.hh"
#include "adt/Stack.hh"
#include "generic/FinalizationSet.hh"
#include "generic/Transform.hh"
#include "generic/ConcreteRepresentationHandler.hh"
#include "generic/ConcreteRepresentation.hh"
#include "generic/ConcreteCode.hh"
#include "generic/Closure.hh"
#include "generic/Thread.hh"
#include "generic/ThreadQueue.hh"
#include "generic/Tuple.hh"
#include "generic/String.hh"
#include "generic/StackFrame.hh"
#include "generic/Backtrace.hh"
#include "generic/Pickle.hh"
#include "generic/Debug.hh"
#include "generic/RootSet.hh"
#include "generic/UniqueString.hh"
#include "generic/Properties.hh"
#include "generic/TaskStack.hh"
#include "generic/IOHandler.hh"
#include "generic/SignalHandler.hh"
#include "generic/Scheduler.hh"
#include "generic/Transients.hh"
#include "generic/Interpreter.hh"
#include "generic/Primitive.hh"
#include "generic/PushCallInterpreter.hh"
#include "generic/ByneedInterpreter.hh"
#include "generic/Unpickler.hh"
#include "generic/Pickler.hh"
#include "generic/BootLinker.hh"
#include "generic/Profiler.hh"
#include "generic/Authoring.hh"

DllExport int StockwerkMain(char *home, u_int argc, char *argv[]);

#if defined(__MINGW32__) || defined(_MSC_VER)
// We must not use DllExport here:
extern "C" __declspec(dllexport) word InitComponent();
#else
extern "C" word InitComponent();
#endif

#endif
