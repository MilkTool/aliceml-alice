//
// Author:
//   Christian Mueller <cmueller@ps.uni-sb.de>
//
// Copyright:
//   Christian Mueller, 2005
//
// Last Change:
//   $Date$ by $Author$
//   $Revision$
//

#ifndef __ALICE_BYTECODE_INLINER_HH__
#define __ALICE_BYTECODE_INLINER_HH__

#if defined(INTERFACE)
#pragma interface "alice/ByteCodeInliner.hh"
#endif

#include "alice/Authoring.hh"
#include "alice/AbstractCode.hh"

class LazyCompileClosure;

//#define INLINE_LIMIT 5 moved to ByteCodeInliner.cc

namespace ByteCodeInliner_Internal {
  static inline u_int GetNumberOfLocals(TagVal *abstractCode) {
    TagVal *annotation = TagVal::FromWordDirect(abstractCode->Sel(2));
    switch (AbstractCode::GetAnnotation(annotation)) {
    case AbstractCode::Simple:
      return Store::DirectWordToInt(annotation->Sel(0));
    case AbstractCode::Debug:
      return Vector::FromWordDirect(annotation->Sel(0))->GetLength();
    }
  }

  class Container {
  private:
    u_int size;
    u_int flattenedSize;
    u_int top;
    Tuple *container;
  public:
    Container() : size(10), flattenedSize(0), top(0) { 
      container = Tuple::New(size); 
    }
    void Append(word item, u_int itemSize = 1) {
      if(top >= size) {
	u_int newSize = size * 3 / 2;
	Tuple *newContainer = Tuple::New(newSize);
	for(u_int i=size; i--; ) 
	  newContainer->Init(i,container->Sel(i));
	size = newSize;
	container = newContainer;
      }
      flattenedSize += itemSize;
      container->Init(top++,item);
    }
    word Sub(u_int i) { return container->Sel(i); }
    void Clear() { 
      container = Tuple::New(20);
      top = 0; 
      flattenedSize = 0; 
    }
    u_int GetLength() { return top; }
    u_int GetFlattenedLength() { return flattenedSize; }
  };
};

class InlineInfo : private Tuple {
private:
  enum { INLINE_MAP_POS, LIVENESS_POS, NLOCALS_POS, NNODES_POS, SIZE };
public:
  using Tuple::ToWord;

  static InlineInfo *New(Map *inlineMap, Vector *liveness, 
			 u_int nLocals, u_int nNodes) {
    Tuple *tup = Tuple::New(SIZE); 
    tup->Init(INLINE_MAP_POS,inlineMap->ToWord());
    tup->Init(LIVENESS_POS,liveness->ToWord());
    tup->Init(NLOCALS_POS,Store::IntToWord(nLocals));
    tup->Init(NNODES_POS,Store::IntToWord(nNodes));
    return (InlineInfo *) tup;
  }
  Map *GetInlineMap() { 
    return Map::FromWordDirect(Tuple::Sel(INLINE_MAP_POS)); 
  }
  Vector *GetLiveness() { 
    return Vector::FromWordDirect(Tuple::Sel(LIVENESS_POS)); 
  }
  u_int GetNLocals() { 
    return Store::DirectWordToInt(Tuple::Sel(NLOCALS_POS)); 
  }
  u_int GetNNodes() { 
    return Store::DirectWordToInt(Tuple::Sel(NNODES_POS)); 
  }

  static InlineInfo *FromWord(word info) {
    return STATIC_CAST(InlineInfo *, Tuple::FromWord(info));
  }
  static InlineInfo *FromWordDirect(word info) {
    return STATIC_CAST(InlineInfo *, Tuple::FromWordDirect(info));
  }
};

class ByteCodeInliner {
private:
  class InlineAnalyser {
  private:
    u_int counter;
    u_int nLocals;
    Vector *subst;
    TagVal *abstractCode;
    Vector *liveness;
    Map *inlineMap;
    ByteCodeInliner_Internal::Container livenessInfo;
    void Append(word key,
		TagVal *acc, Closure *closure, word idDefsInstrOpt,
		InlineInfo *inlineInfo);
    Vector *MergeLiveness();
  public:
    InlineAnalyser(TagVal *ac) : abstractCode(ac), counter(0) {
      subst = Vector::FromWordDirect(abstractCode->Sel(1));
      liveness = Vector::FromWordDirect(abstractCode->Sel(6));
      inlineMap = Map::New(20); 
      nLocals = ByteCodeInliner_Internal::GetNumberOfLocals(abstractCode);
    }
    // This functions breaks an inline analysis cycle introduced by 
    // mutual recursive functions.
    bool CheckCycle(TagVal *acc);
    void Count(TagVal *instr);
    void AnalyseAppVar(TagVal *instr);
    InlineInfo *ComputeInlineInfo() {
      return InlineInfo::New(inlineMap,MergeLiveness(),nLocals,counter);
    } 
  };
  // The driver implements a depth-first search from the root and applies 
  // the analysers to every node exactly ones
  static void Driver(TagVal *root, InlineAnalyser *analyser); 
  static Map *inlineCandidates;
public:

  // Checks if a function is inlinable
  // At the moment we use a very simple heuristic to decide whether we 
  // inline a function or not:
  // We impose a very ad-hoc size level, which is based on the number
  // of nodes inside an abstract code function. More profiling should
  // make this size barrier less ad-hoc.
  static InlineInfo *AnalyseInlining(TagVal *abstractCode);

  // This function must be called in the ByteCodeJitter to indicate the start
  // of the analysis. A new map is created which records the processed 
  // functions.
  static void ResetRoot() { inlineCandidates = Map::New(20); }
};

#endif // __ALICE_BYTECODE_INLINER_HH__
