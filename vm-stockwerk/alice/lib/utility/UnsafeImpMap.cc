//
// Author:
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

#include <cstdio>
#include "store/WeakDictionary.hh"
#include "generic/Tuple.hh"
#include "alice/StackFrame.hh"
#include "alice/Authoring.hh"

static const BlockLabel ENTRY_LABEL = TUPLE_LABEL;
static const BlockLabel IMPMAP_LABEL = TUPLE_LABEL;

//
// Abstract Data Type: ImpMap
//

class ImpMapEntry: private Block {
private:
  enum { KEY_POS, VALUE_POS, PREV_POS, NEXT_POS, SIZE };
public:
  using Block::ToWord;

  static ImpMapEntry *New(word key, word value, ImpMapEntry *next) {
    Block *b = Store::AllocBlock(ENTRY_LABEL, SIZE);
    b->InitArg(KEY_POS, key);
    b->InitArg(VALUE_POS, value);
    b->InitArg(PREV_POS, 0);
    if (next != INVALID_POINTER) {
      b->InitArg(NEXT_POS, next->ToWord());
      next->ReplaceArg(PREV_POS, b->ToWord());
    } else
      b->InitArg(NEXT_POS, 0);
    return static_cast<ImpMapEntry *>(b);
  }
  static ImpMapEntry *FromWordDirect(word w) {
    Block *b = Store::DirectWordToBlock(w);
    Assert(b->GetLabel() == ENTRY_LABEL && b->GetSize() == SIZE);
    return static_cast<ImpMapEntry *>(b);
  }

  word GetKey() {
    return GetArg(KEY_POS);
  }
  word GetValue() {
    return GetArg(VALUE_POS);
  }
  void SetValue(word value) {
    ReplaceArg(VALUE_POS, value);
  }
  ImpMapEntry *GetNext() {
    word next = GetArg(NEXT_POS);
    if (next == Store::IntToWord(0))
      return INVALID_POINTER;
    else
      return ImpMapEntry::FromWordDirect(next);
  }

  word Unlink() {
    // Returns:
    //    Integer 1, iff unlink was completed without the need to touch head.
    //    Integer 0, iff head needs to be set to the empty list.
    //    New head, otherwise.
    word prev = GetArg(PREV_POS);
    word next = GetArg(NEXT_POS);
    if (next != Store::IntToWord(0)) {
      ImpMapEntry *nextEntry = ImpMapEntry::FromWordDirect(next);
      nextEntry->ReplaceArg(PREV_POS, prev);
    }
    if (prev != Store::IntToWord(0)) {
      ImpMapEntry *prevEntry = ImpMapEntry::FromWordDirect(prev);
      prevEntry->ReplaceArg(NEXT_POS, next);
      return Store::IntToWord(1);
    } else
      return next;
  }
};

//--** ImpMaps should be picklable
class ImpMap: private Block {
private:
  enum { HASHTABLE_POS, HEAD_POS, SIZE };

  static const u_int initialSize = 8; //--** to be determined

  BlockHashTable *GetHashTable() {
    return BlockHashTable::FromWordDirect(GetArg(HASHTABLE_POS));
  }
public:
  using Block::ToWord;

  static ImpMap *New() {
    Block *b = Store::AllocBlock(IMPMAP_LABEL, SIZE);
    b->InitArg(HASHTABLE_POS, BlockHashTable::New(initialSize)->ToWord());
    b->InitArg(HEAD_POS, 0);
    return static_cast<ImpMap *>(b);
  }
  static ImpMap *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER ||
	   b->GetLabel() == IMPMAP_LABEL && b->GetSize() == SIZE);
    return static_cast<ImpMap *>(b);
  }

  void Insert(word key, word value) {
    BlockHashTable *hashTable = GetHashTable();
    Assert(!hashTable->IsMember(key));
    word head = GetArg(HEAD_POS);
    ImpMapEntry *headEntry = head == Store::IntToWord(0)?
      INVALID_POINTER: ImpMapEntry::FromWordDirect(head);
    ImpMapEntry *entry = ImpMapEntry::New(key, value, headEntry);
    ReplaceArg(HEAD_POS, entry->ToWord());
    hashTable->InsertItem(key, entry->ToWord());
  }
  void Delete(word key) {
    BlockHashTable *hashTable = GetHashTable();
    Assert(hashTable->IsMember(key));
    ImpMapEntry *entry =
      ImpMapEntry::FromWordDirect(hashTable->GetItem(key));
    hashTable->DeleteItem(key);
    word result = entry->Unlink();
    if (result != Store::IntToWord(1))
      ReplaceArg(HEAD_POS, result);
  }
  void DeleteAll() {
    GetHashTable()->Clear();
    ReplaceArg(HEAD_POS, 0);
  }
  ImpMapEntry *LookupEntry(word key) {
    BlockHashTable *hashTable = GetHashTable();
    Assert(hashTable->IsMember(key));
    return ImpMapEntry::FromWordDirect(hashTable->GetItem(key));
  }
  word Lookup(word key) {
    BlockHashTable *hashTable = GetHashTable();
    if (hashTable->IsMember(key)) {
      TagVal *some = TagVal::New(1, 1); // SOME ...
      ImpMapEntry *entry =
	ImpMapEntry::FromWordDirect(hashTable->GetItem(key));
      some->Init(0, entry->GetValue());
      return some->ToWord();
    } else {
      return Store::IntToWord(0); // NONE
    }
  }
  bool Member(word key) {
    return GetHashTable()->IsMember(key);
  }
  bool IsEmpty() {
    return GetHashTable()->IsEmpty();
  }
  u_int GetSize() {
    return GetHashTable()->GetSize();
  }
  ImpMapEntry *GetHead() {
    word head = GetArg(HEAD_POS);
    if (head == Store::IntToWord(0))
      return INVALID_POINTER;
    else
      return ImpMapEntry::FromWordDirect(head);
  }
};

#define DECLARE_IMP_MAP(impMap, x) DECLARE_BLOCKTYPE(ImpMap, impMap, x)
#define DECLARE_WORD(w, x) \
  word w; \
  s_int i_w = Store::WordToInt(x); \
  if (i_w == INVALID_INT) { \
    Block *p = Store::WordToBlock(x); \
    if (p == INVALID_POINTER) { \
      REQUEST(x); \
    } \
    else \
      w = p->ToWord(); \
  } \
  else { \
    w = Store::IntToWord(i_w); \
  }

//
// Worker for insertWithi
//

class ImpMapInsertWorker: public Worker {
private:
  static ImpMapInsertWorker *self;
  ImpMapInsertWorker(): Worker() {}
public:
  static void Init() {
    self = new ImpMapInsertWorker();
  }
  // Frame Handling
  static void PushFrame(ImpMapEntry *entry);
  // Execution
  virtual Result Run();
  // Debugging
  virtual const char *Identify();
  virtual void DumpFrame(word frame);
};

class ImpMapInsertFrame: private StackFrame {
private:
  enum { ENTRY_POS, SIZE };
public:
  using StackFrame::ToWord;

  static ImpMapInsertFrame *New(Worker *worker, ImpMapEntry *entry) {
    StackFrame *frame = StackFrame::New(CELLMAP_INSERT_FRAME, worker, SIZE);
    frame->InitArg(ENTRY_POS, entry->ToWord());
    return static_cast<ImpMapInsertFrame *>(frame);
  }
  static ImpMapInsertFrame *FromWordDirect(word frame) {
    StackFrame *p = StackFrame::FromWordDirect(frame);
    Assert(p->GetLabel() == CELLMAP_INSERT_FRAME);
    return static_cast<ImpMapInsertFrame *>(p);
  }

  ImpMapEntry *GetEntry() {
    return ImpMapEntry::FromWordDirect(GetArg(ENTRY_POS));
  }
};

ImpMapInsertWorker *ImpMapInsertWorker::self;

void ImpMapInsertWorker::PushFrame(ImpMapEntry *entry) {
  Scheduler::PushFrame(ImpMapInsertFrame::New(self, entry)->ToWord());
}

Worker::Result ImpMapInsertWorker::Run() {
  ImpMapInsertFrame *frame =
    ImpMapInsertFrame::FromWordDirect(Scheduler::GetAndPopFrame());
  ImpMapEntry *entry = frame->GetEntry();
  Construct();
  entry->SetValue(Scheduler::currentArgs[0]);
  Scheduler::nArgs = 0;
  return Worker::CONTINUE;
}

const char *ImpMapInsertWorker::Identify() {
  return "ImpMapInsertWorker";
}

void ImpMapInsertWorker::DumpFrame(word) {
  std::fprintf(stderr, "UnsafeImpMap.insertWithi\n");
}

//
// Worker for Iterating over ImpMaps
//

class ImpMapIteratorWorker: public Worker {
private:
  static ImpMapIteratorWorker *self;
  ImpMapIteratorWorker(): Worker() {}
public:
  enum operation { app, appi, fold, foldi };

  static void Init() {
    self = new ImpMapIteratorWorker();
  }
  // Frame Handling
  static void PushFrame(ImpMapEntry *entry, word closure, operation op);
  // Execution
  virtual Result Run();
  // Debugging
  virtual const char *Identify();
  virtual void DumpFrame(word frame);
};

class ImpMapIteratorFrame: private StackFrame {
private:
  enum { ENTRY_POS, CLOSURE_POS, OPERATION_POS, SIZE };
public:
  using StackFrame::ToWord;

  static ImpMapIteratorFrame *New(Worker *worker,
				   ImpMapEntry *entry, word closure,
				   ImpMapIteratorWorker::operation op) {
    StackFrame *frame = StackFrame::New(CELLMAP_ITERATOR_FRAME, worker, SIZE);
    frame->InitArg(ENTRY_POS, entry->ToWord());
    frame->InitArg(CLOSURE_POS, closure);
    frame->InitArg(OPERATION_POS, Store::IntToWord(op));
    return static_cast<ImpMapIteratorFrame *>(frame);
  }
  static ImpMapIteratorFrame *FromWordDirect(word frame) {
    StackFrame *p = StackFrame::FromWordDirect(frame);
    Assert(p->GetLabel() == CELLMAP_ITERATOR_FRAME);
    return static_cast<ImpMapIteratorFrame *>(p);
  }

  ImpMapEntry *GetEntry() {
    return ImpMapEntry::FromWordDirect(GetArg(ENTRY_POS));
  }
  void SetEntry(ImpMapEntry *entry) {
    ReplaceArg(ENTRY_POS, entry->ToWord());
  }
  word GetClosure() {
    return GetArg(CLOSURE_POS);
  }
  ImpMapIteratorWorker::operation GetOperation() {
    return static_cast<ImpMapIteratorWorker::operation>
      (Store::DirectWordToInt(GetArg(OPERATION_POS)));
  }
};

ImpMapIteratorWorker *ImpMapIteratorWorker::self;

void ImpMapIteratorWorker::PushFrame(ImpMapEntry *entry,
				      word closure, operation op) {
  ImpMapIteratorFrame *frame =
    ImpMapIteratorFrame::New(self, entry, closure, op);
  Scheduler::PushFrame(frame->ToWord());
}

Worker::Result ImpMapIteratorWorker::Run() {
  ImpMapIteratorFrame *frame =
    ImpMapIteratorFrame::FromWordDirect(Scheduler::GetFrame());
  ImpMapEntry *entry = frame->GetEntry();
  word closure = frame->GetClosure();
  operation op = frame->GetOperation();
  ImpMapEntry *nextEntry = entry->GetNext();
  if (nextEntry != INVALID_POINTER)
    frame->SetEntry(nextEntry);
  else
    Scheduler::PopFrame();
  switch (op) {
  case app:
    Scheduler::nArgs = Scheduler::ONE_ARG;
    Scheduler::currentArgs[0] = entry->GetValue();
    break;
  case appi:
    Scheduler::nArgs = 2;
    Scheduler::currentArgs[0] = entry->GetKey();
    Scheduler::currentArgs[1] = entry->GetValue();
    break;
  case fold:
    Construct();
    Scheduler::nArgs = 2;
    Scheduler::currentArgs[1] = Scheduler::currentArgs[0];
    Scheduler::currentArgs[0] = entry->GetValue();
    break;
  case foldi:
    Construct();
    Scheduler::nArgs = 3;
    Scheduler::currentArgs[2] = Scheduler::currentArgs[0];
    Scheduler::currentArgs[0] = entry->GetKey();
    Scheduler::currentArgs[1] = entry->GetValue();
    break;
  }
  return Scheduler::PushCall(closure);
}

const char *ImpMapIteratorWorker::Identify() {
  return "ImpMapIteratorWorker";
}

void ImpMapIteratorWorker::DumpFrame(word wFrame) {
  ImpMapIteratorFrame *frame = ImpMapIteratorFrame::FromWordDirect(wFrame);
  const char *name;
  switch (frame->GetOperation()) {
  case app: name = "app"; break;
  case appi: name = "appi"; break;
  case fold: name = "fold"; break;
  case foldi: name = "foldi"; break;
  default:
    Error("unknown ImpMapIteratorWorker operation\n");
  }
  std::fprintf(stderr, "UnsafeImpMap.%s\n", name);
}

//
// Worker for Searching in ImpMaps
//

class ImpMapFindWorker: public Worker {
private:
  static ImpMapFindWorker *self;
  ImpMapFindWorker(): Worker() {}
public:
  enum operation { find, findi };

  static void Init() {
    self = new ImpMapFindWorker();
  }
  // Frame Handling
  static void PushFrame(ImpMapEntry *entry, word closure, operation op);
  // Execution
  virtual Result Run();
  // Debugging
  virtual const char *Identify();
  virtual void DumpFrame(word frame);
};

class ImpMapFindFrame: private StackFrame {
private:
  enum { ENTRY_POS, CLOSURE_POS, OPERATION_POS, SIZE };
public:
  using StackFrame::ToWord;

  static ImpMapFindFrame *New(Worker *worker,
			       ImpMapEntry *entry, word closure,
			       ImpMapFindWorker::operation op) {
    StackFrame *frame =
      StackFrame::New(CELLMAP_FIND_FRAME, worker, SIZE);
    frame->InitArg(ENTRY_POS, entry->ToWord());
    frame->InitArg(CLOSURE_POS, closure);
    frame->InitArg(OPERATION_POS, Store::IntToWord(op));
    return static_cast<ImpMapFindFrame *>(frame);
  }
  static ImpMapFindFrame *FromWordDirect(word frame) {
    StackFrame *p = StackFrame::FromWordDirect(frame);
    Assert(p->GetLabel() == CELLMAP_FIND_FRAME);
    return static_cast<ImpMapFindFrame *>(p);
  }

  ImpMapEntry *GetEntry() {
    return ImpMapEntry::FromWordDirect(GetArg(ENTRY_POS));
  }
  void SetEntry(ImpMapEntry *entry) {
    ReplaceArg(ENTRY_POS, entry->ToWord());
  }
  word GetClosure() {
    return GetArg(CLOSURE_POS);
  }
  ImpMapFindWorker::operation GetOperation() {
    return static_cast<ImpMapFindWorker::operation>
      (Store::DirectWordToInt(GetArg(OPERATION_POS)));
  }
};

ImpMapFindWorker *ImpMapFindWorker::self;

void ImpMapFindWorker::PushFrame(ImpMapEntry *entry,
				  word closure, operation op) {
  ImpMapFindFrame *frame = ImpMapFindFrame::New(self, entry, closure, op);
  Scheduler::PushFrame(frame->ToWord());
}

Worker::Result ImpMapFindWorker::Run() {
  ImpMapFindFrame *frame =
    ImpMapFindFrame::FromWordDirect(Scheduler::GetFrame());
  ImpMapEntry *entry = frame->GetEntry();
  word closure = frame->GetClosure();
  operation op = frame->GetOperation();
  Assert(Scheduler::nArgs == Scheduler::ONE_ARG);
  switch (Store::WordToInt(Scheduler::currentArgs[0])) {
  case 0: // false
    entry = entry->GetNext();
    if (entry != INVALID_POINTER) {
      frame->SetEntry(entry);
      switch (op) {
      case find:
	Scheduler::nArgs = Scheduler::ONE_ARG;
	Scheduler::currentArgs[0] = entry->GetValue();
	break;
      case findi:
	Scheduler::nArgs = 2;
	Scheduler::currentArgs[0] = entry->GetKey();
	Scheduler::currentArgs[1] = entry->GetValue();
	break;
      }
      return Scheduler::PushCall(closure);
    } else {
      Scheduler::PopFrame();
      Scheduler::nArgs = Scheduler::ONE_ARG;
      Scheduler::currentArgs[0] = Store::IntToWord(0); // NONE
      return Worker::CONTINUE;
    }
  case 1: // true
    {
      Scheduler::PopFrame();
      TagVal *some = TagVal::New(1, 1); // SOME ...
      switch (op) {
      case find:
	some->Init(0, entry->GetValue());
	break;
      case findi:
	Tuple *pair = Tuple::New(2);
	pair->Init(0, entry->GetKey());
	pair->Init(1, entry->GetValue());
	some->Init(0, pair->ToWord());
	break;
      }
      Scheduler::nArgs = Scheduler::ONE_ARG;
      Scheduler::currentArgs[0] = some->ToWord();
      return Worker::CONTINUE;
    }
  case INVALID_INT:
    Scheduler::currentData = Scheduler::currentArgs[0];
    return Worker::REQUEST;
  default:
    Error("ImpMapFindWorker: boolean expected");
  }
}

const char *ImpMapFindWorker::Identify() {
  return "ImpMapFindWorker";
}

void ImpMapFindWorker::DumpFrame(word wFrame) {
  ImpMapFindFrame *frame = ImpMapFindFrame::FromWordDirect(wFrame);
  const char *name;
  switch (frame->GetOperation()) {
  case find: name = "find"; break;
  case findi: name = "findi"; break;
  default:
    Error("unknown ImpMapFindWorker operation\n");
  }
  std::fprintf(stderr, "UnsafeImpMap.%s\n", name);
}

//
// Primitives
//

DEFINE0(UnsafeImpMap_new) {
  RETURN(ImpMap::New()->ToWord());
} END

DEFINE1(UnsafeImpMap_clone) {
  DECLARE_IMP_MAP(impMap, x0);
  ImpMap *newImpMap = ImpMap::New();
  ImpMapEntry *entry = impMap->GetHead();
  while (entry != INVALID_POINTER) {
    newImpMap->Insert(entry->GetKey(), entry->GetValue());
    entry = entry->GetNext();
  }
  RETURN(newImpMap->ToWord());
} END

DEFINE4(UnsafeImpMap_insertWithi) {
  word closure = x0;
  DECLARE_IMP_MAP(impMap, x1);
  DECLARE_WORD(key, x2);
  word value = x3;
  if (impMap->Member(key)) {
    ImpMapEntry *entry = impMap->LookupEntry(key);
    ImpMapInsertWorker::PushFrame(entry);
    Scheduler::nArgs = 3;
    Scheduler::currentArgs[0] = key;
    Scheduler::currentArgs[1] = entry->GetValue();
    Scheduler::currentArgs[2] = value;
    return Scheduler::PushCall(closure);
  } else {
    impMap->Insert(key, value);
    RETURN_UNIT;
  }
} END

DEFINE3(UnsafeImpMap_deleteWith) {
  word closure = x0;
  DECLARE_IMP_MAP(impMap, x1);
  DECLARE_WORD(key, x2);
  if (impMap->Member(key)) {
    impMap->Delete(key);
    RETURN_UNIT;
  } else {
    Scheduler::nArgs = Scheduler::ONE_ARG;
    Scheduler::currentArgs[0] = key;
    return Scheduler::PushCall(closure);
  }
} END

DEFINE1(UnsafeImpMap_deleteAll) {
  DECLARE_IMP_MAP(impMap, x0);
  impMap->DeleteAll();
  RETURN_UNIT;
} END

DEFINE2(UnsafeImpMap_lookup) {
  DECLARE_IMP_MAP(impMap, x0);
  DECLARE_WORD(key, x1);
  RETURN(impMap->Lookup(key));
} END

DEFINE1(UnsafeImpMap_isEmpty) {
  DECLARE_IMP_MAP(impMap, x0);
  RETURN_BOOL(impMap->IsEmpty());
} END

DEFINE1(UnsafeImpMap_size) {
  DECLARE_IMP_MAP(impMap, x0);
  RETURN_INT(impMap->GetSize());
} END

DEFINE2(UnsafeImpMap_app) {
  word closure = x0;
  DECLARE_IMP_MAP(impMap, x1);
  ImpMapEntry *entry = impMap->GetHead();
  if (entry != INVALID_POINTER)
    ImpMapIteratorWorker::PushFrame(entry, closure,
				     ImpMapIteratorWorker::app);
  RETURN_UNIT;
} END

DEFINE2(UnsafeImpMap_appi) {
  word closure = x0;
  DECLARE_IMP_MAP(impMap, x1);
  ImpMapEntry *entry = impMap->GetHead();
  if (entry != INVALID_POINTER)
    ImpMapIteratorWorker::PushFrame(entry, closure,
				     ImpMapIteratorWorker::appi);
  RETURN_UNIT;
} END

DEFINE3(UnsafeImpMap_fold) {
  word closure = x0;
  word zero = x1;
  DECLARE_IMP_MAP(impMap, x2);
  ImpMapEntry *entry = impMap->GetHead();
  if (entry != INVALID_POINTER)
    ImpMapIteratorWorker::PushFrame(entry, closure,
				     ImpMapIteratorWorker::fold);
  RETURN(zero);
} END

DEFINE3(UnsafeImpMap_foldi) {
  word closure = x0;
  word zero = x1;
  DECLARE_IMP_MAP(impMap, x2);
  ImpMapEntry *entry = impMap->GetHead();
  if (entry != INVALID_POINTER)
    ImpMapIteratorWorker::PushFrame(entry, closure,
				     ImpMapIteratorWorker::foldi);
  RETURN(zero);
} END

DEFINE2(UnsafeImpMap_find) {
  word closure = x0;
  DECLARE_IMP_MAP(impMap, x1);
  ImpMapEntry *entry = impMap->GetHead();
  if (entry != INVALID_POINTER) {
    ImpMapFindWorker::PushFrame(entry, closure,
				 ImpMapFindWorker::find);
    Scheduler::nArgs = Scheduler::ONE_ARG;
    Scheduler::currentArgs[0] = entry->GetValue();
    return Scheduler::PushCall(closure);
  } else {
    RETURN_INT(0); // NONE
  }
} END

DEFINE2(UnsafeImpMap_findi) {
  word closure = x0;
  DECLARE_IMP_MAP(impMap, x1);
  ImpMapEntry *entry = impMap->GetHead();
  if (entry != INVALID_POINTER) {
    ImpMapFindWorker::PushFrame(entry, closure,
				 ImpMapFindWorker::findi);
    Scheduler::nArgs = 2;
    Scheduler::currentArgs[0] = entry->GetKey();
    Scheduler::currentArgs[1] = entry->GetValue();
    return Scheduler::PushCall(closure);
  } else {
    RETURN_INT(0); // NONE
  }
} END

word UnsafeImpMap() {
  ImpMapInsertWorker::Init();
  ImpMapIteratorWorker::Init();
  ImpMapFindWorker::Init();

  Record *record = Record::New(14);
  INIT_STRUCTURE(record, "UnsafeImpMap", "new",
		 UnsafeImpMap_new, 0, true);
  INIT_STRUCTURE(record, "UnsafeImpMap", "clone",
		 UnsafeImpMap_clone, 1, true);
  INIT_STRUCTURE(record, "UnsafeImpMap", "insertWithi",
		 UnsafeImpMap_insertWithi, 4, true);
  INIT_STRUCTURE(record, "UnsafeImpMap", "deleteWith",
		 UnsafeImpMap_deleteWith, 3, true);
  INIT_STRUCTURE(record, "UnsafeImpMap", "deleteAll",
		 UnsafeImpMap_deleteAll, 1, true);
  INIT_STRUCTURE(record, "UnsafeImpMap", "lookup",
		 UnsafeImpMap_lookup, 2, true);
  INIT_STRUCTURE(record, "UnsafeImpMap", "isEmpty",
		 UnsafeImpMap_isEmpty, 1, true);
  INIT_STRUCTURE(record, "UnsafeImpMap", "size",
		 UnsafeImpMap_size, 1, true);
  INIT_STRUCTURE(record, "UnsafeImpMap", "app",
		 UnsafeImpMap_app, 2, true);
  INIT_STRUCTURE(record, "UnsafeImpMap", "appi",
		 UnsafeImpMap_appi, 2, true);
  INIT_STRUCTURE(record, "UnsafeImpMap", "fold",
		 UnsafeImpMap_fold, 3, true);
  INIT_STRUCTURE(record, "UnsafeImpMap", "foldi",
		 UnsafeImpMap_foldi, 3, true);
  INIT_STRUCTURE(record, "UnsafeImpMap", "find",
		 UnsafeImpMap_find, 2, true);
  INIT_STRUCTURE(record, "UnsafeImpMap", "findi",
		 UnsafeImpMap_findi, 2, true);

  RETURN_STRUCTURE("UnsafeImpMap$", record);
}
