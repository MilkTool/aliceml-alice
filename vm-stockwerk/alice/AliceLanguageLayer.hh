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

#ifndef __ALICE__ALICE_LANGUAGE_LAYER_HH__
#define __ALICE__ALICE_LANGUAGE_LAYER_HH__

#if defined(INTERFACE)
#pragma interface "alice/AliceLanguageLayer.hh"
#endif

#include "store/Store.hh"

class TagVal;

typedef word (*concrete_constructor)(TagVal *);

class DllExport AliceLanguageLayer {
public:
  class DllExport TransformNames {
  public:
    static word primitiveValue;
    static word primitiveFunction;
    static word function;
    static word constructor;
    static word uniqueString;
  };

  static word aliceHome;
  static word rootUrl;
  static word commandLineArguments;
  static word remoteCallback;

  static concrete_constructor concreteCodeConstructor;

  static void Init(const char *home, int argc, char *argv[]);
};

#endif
