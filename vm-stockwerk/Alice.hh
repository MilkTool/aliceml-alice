//
// Author:
//   Leif Kornstaedt <kornstae@ps.uni-sb.de>
//
// Copyright:
//   Leif Kornstaedt, 2002-2003
//
// Last Change:
//   $Date$ by $Author$
//   $Revision$
//

#ifndef __ALICE_HH__
#define __ALICE_HH__

#include "Seam.hh"
#include "alice/Guid.hh"
#include "alice/Data.hh"
#include "alice/Types.hh"
#include "alice/AbstractCode.hh"
#include "alice/AbstractCodeInterpreter.hh"
#include "alice/AliceConcreteCode.hh"
#if LIGHTNING
#include "alice/NativeCodeInterpreter.hh"
#include "alice/NativeConcreteCode.hh"
#endif
#include "alice/PrimitiveTable.hh"
#include "alice/AliceLanguageLayer.hh"
#include "alice/Authoring.hh"
#include "alice/BootLinker.hh"

DllExport int AliceMain(char *home, u_int argc, char *argv[]);

#endif
