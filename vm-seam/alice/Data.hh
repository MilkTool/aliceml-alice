//
// Authors:
//   Thorsten Brunklaus <brunklaus@ps.uni-sb.de>
//   Leif Kornstaedt <kornstae@ps.uni-sb.de>
//
// Copyright:
//   Thorsten Brunklaus, 2000
//   Leif Kornstaedt, 2000-2002
//
// Last Change:
//   $Date$ by $Author$
//   $Revision$
//

#ifndef __ALICE__DATA_HH__
#define __ALICE__DATA_HH__

#if defined(INTERFACE)
#pragma interface "alice/Data.hh"
#endif

#include <cstring>
#include "generic/UniqueString.hh"
#include "generic/ConcreteRepresentation.hh"

class Transform;

class Alice {
public:
  static const BlockLabel Array   = MIN_DATA_LABEL;
  static const BlockLabel Cell    = (BlockLabel) (MIN_DATA_LABEL + 1);
  static const BlockLabel ConVal  = (BlockLabel) (MIN_DATA_LABEL + 2);
  static const BlockLabel Record  = (BlockLabel) (MIN_DATA_LABEL + 3);
  static const BlockLabel Vector  = (BlockLabel) (MIN_DATA_LABEL + 4);
  static const BlockLabel MIN_TAG = (BlockLabel) (MIN_DATA_LABEL + 5);
  static const BlockLabel MAX_TAG = MAX_DATA_LABEL;

  static bool IsTag(BlockLabel l) {
    return l >= MIN_TAG && l <= MAX_TAG;
  }
  static BlockLabel TagToLabel(u_int l) {
    Assert(l <= MAX_TAG - MIN_TAG);
    return Store::MakeLabel(MIN_TAG + l);
  }
  static u_int LabelToTag(BlockLabel l) {
    Assert(IsTag(l));
    return l - MIN_TAG;
  }
};

class Array: private Block {
private:
  static const u_int LENGTH_POS = 0;
  static const u_int BASE_SIZE = 1;
public:
  static const u_int maxLen = MAX_BIGBLOCKSIZE - BASE_SIZE;

  using Block::ToWord;

  static Array *New(u_int length) {
    Block *b = Store::AllocBlock(Alice::Array, BASE_SIZE + length);
    b->InitArg(LENGTH_POS, length);
    return static_cast<Array *>(b);
  }
  static Array *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER || b->GetLabel() == Alice::Array);
    return static_cast<Array *>(b);
  }
  static Array *FromWordDirect(word x) {
    Block *b = Store::DirectWordToBlock(x);
    Assert(b->GetLabel() == Alice::Array);
    return static_cast<Array *>(b);
  }

  u_int GetLength() {
    return Store::DirectWordToInt(GetArg(LENGTH_POS));
  }
  void Init(u_int index, word value) {
    InitArg(BASE_SIZE + index, value);
  }
  void Update(u_int index, word value) {
    ReplaceArg(BASE_SIZE + index, value);
  }
  word Sub(u_int index) {
    return GetArg(BASE_SIZE + index);
  }
};

class Cell: private Block {
protected:
  static const u_int VAL_POS = 0;
  static const u_int SIZE = 1;
public:
  using Block::ToWord;

  static Cell *New() {
    return static_cast<Cell *>(Store::AllocBlock(Alice::Cell, SIZE));
  }
  static Cell *New(word value) {
    Cell *c = static_cast<Cell *>(Store::AllocBlock(Alice::Cell, SIZE));
    c->InitArg(VAL_POS, value);
    return c;
  }
  static Cell *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER || b->GetLabel() == Alice::Cell);
    return static_cast<Cell *>(b);
  }
  static Cell *FromWordDirect(word x) {
    Block *b = Store::DirectWordToBlock(x);
    Assert(b->GetLabel() == Alice::Cell);
    return static_cast<Cell *>(b);
  }

  void Init(word value) {
    InitArg(VAL_POS, value);
  }
  void Assign(word value) {
    ReplaceArg(VAL_POS, value);
  }
  word Access() {
    return GetArg(VAL_POS);
  }
  word Exchange(word value) {
    word val = GetArg(VAL_POS);
    ReplaceArg(VAL_POS, value);
    return val;
  }
};

class Constructor: private ConcreteRepresentation {
private:
  static const u_int NAME_POS = 0;
  static const u_int TRANSFORM_POS = 1;
  static const u_int SIZE = 2;
  static ConcreteRepresentationHandler *handler;
public:
  using Block::ToWord;

  static void Init();

  static Constructor *New(word name, Block *guid);
  static Constructor *New(word name) {
    ConcreteRepresentation *b = ConcreteRepresentation::New(handler, SIZE);
    b->Init(NAME_POS, name);
    b->Init(TRANSFORM_POS, Store::IntToWord(0)); // constructed lazily
    return static_cast<Constructor *>(b);
  }
  static Constructor *FromWord(word x) {
    ConcreteRepresentation *b = ConcreteRepresentation::FromWord(x);
    Assert(b == INVALID_POINTER || b->GetSize() == SIZE);
    return static_cast<Constructor *>(b);
  }
  static Constructor *FromWordDirect(word x) {
    ConcreteRepresentation *b = ConcreteRepresentation::FromWordDirect(x);
    Assert(b->GetSize() == SIZE);
    return static_cast<Constructor *>(b);
  }

  Transform *GetTransform();
};

class ConVal: private Block {
protected:
  static const u_int CON_POS = 0;
  static const u_int BASE_SIZE = 1;
public:
  using Block::ToWord;

  static ConVal *New(Constructor *cons, u_int n) {
    Block *b = Store::AllocBlock(Alice::ConVal, BASE_SIZE + n);
    b->InitArg(CON_POS, cons->ToWord());
    return static_cast<ConVal *>(b);
  }
  static ConVal *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER ||
	   b->GetLabel() == Alice::ConVal ||
	   b->GetLabel() == CONCRETE_LABEL);
    return static_cast<ConVal *>(b);
  }
  static ConVal *FromWordDirect(word x) {
    Block *b = Store::DirectWordToBlock(x);
    Assert(b->GetLabel() == Alice::ConVal ||
	   b->GetLabel() == CONCRETE_LABEL);
    return static_cast<ConVal *>(b);
  }

  bool IsConVal() { // as opposed to a Constructor, see FromWord
    return GetLabel() == Alice::ConVal;
  }
  Constructor *GetConstructor() {
    Assert(GetLabel() == Alice::ConVal);
    return Constructor::FromWordDirect(GetArg(CON_POS));
  }
  void AssertWidth(u_int n) {
    Assert(Store::SizeToBlockSize(BASE_SIZE + n) == GetSize()); n = n;
  }
  void Init(u_int index, word value) {
    InitArg(BASE_SIZE + index, value);
  }
  word Sel(u_int index) {
    return GetArg(BASE_SIZE + index);
  }
};

class Real: private Chunk {
public:
  using Chunk::ToWord;

  static Real *New(double value) {
    Chunk *chunk = Store::AllocChunk(sizeof(double));
    std::memcpy(chunk->GetBase(), &value, sizeof(double));
    return static_cast<Real *>(chunk);
  }
  static Real *FromWord(word x) {
    Chunk *chunk = Store::WordToChunk(x);
    Assert(chunk == INVALID_POINTER || chunk->GetSize() == sizeof(double));
    return static_cast<Real *>(chunk);
  }
  static Real *FromWordDirect(word x) {
    Chunk *chunk = Store::DirectWordToChunk(x);
    Assert(chunk->GetSize() == Store::SizeToChunkSize(sizeof(double)));
    return static_cast<Real *>(chunk);
  }

  double GetValue() {
    double result;
    std::memcpy(GetBase(), &result, sizeof(double));
    return result;
  }
};

class TagVal: private Block {
public:
  using Block::ToWord;

  static TagVal *New(u_int tag, u_int n) {
    return static_cast<TagVal *>(Store::AllocBlock(Alice::TagToLabel(tag), n));
  }
  static TagVal *FromWord(word x) {
    Block *p = Store::WordToBlock(x);
    Assert(p == INVALID_POINTER || Alice::IsTag(p->GetLabel()));
    return static_cast<TagVal *>(p);
  }
  static TagVal *FromWordDirect(word x) {
    Block *p = Store::DirectWordToBlock(x);
    Assert(Alice::IsTag(p->GetLabel()));
    return static_cast<TagVal *>(p);
  }

  u_int GetTag() {
    return Alice::LabelToTag(GetLabel());
  }
  void AssertWidth(u_int n) {
    Assert(Store::SizeToBlockSize(n) == GetSize()); n = n;
  }
  void Init(u_int index, word value) {
    InitArg(index, value);
  }
  word Sel(u_int index) {
    return GetArg(index);
  }
};

class UniqueConstructor: public Constructor {
public:
  static UniqueConstructor *New(String *id) {
    return static_cast<UniqueConstructor *>
      (Constructor::New(id->ToWord(), static_cast<Block *>(id)));
  }
  static UniqueConstructor *FromWord(word x) {
    return static_cast<UniqueConstructor *>(Constructor::FromWord(x));
  }
  static UniqueConstructor *FromWordDirect(word x) {
    return static_cast<UniqueConstructor *>(Constructor::FromWordDirect(x));
  }
};

class Vector: private Block {
protected:
  static const u_int LENGTH_POS = 0;
  static const u_int BASE_SIZE = 1;
public:
  static const u_int maxLen = MAX_BIGBLOCKSIZE - BASE_SIZE;

  using Block::ToWord;

  static Vector *New(u_int length) {
    Block *b =
      Store::AllocBlock(Alice::Vector, BASE_SIZE + length);
    b->InitArg(LENGTH_POS, length);
    return static_cast<Vector *>(b);
  }
  static Vector *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER || b->GetLabel() == Alice::Vector);
    return static_cast<Vector *>(b);
  }
  static Vector *FromWordDirect(word x) {
    Block *b = Store::DirectWordToBlock(x);
    Assert(b->GetLabel() == Alice::Vector);
    return static_cast<Vector *>(b);
  }

  u_int GetLength() {
    return Store::DirectWordToInt(GetArg(LENGTH_POS));
  }
  void Init(u_int index, word value) {
    InitArg(BASE_SIZE + index, value);
  }
  void LateInit(u_int index, word value) {
    // This is only meant to be called by Vector.tabulate
    ReplaceArg(BASE_SIZE + index, value);
  }
  word Sub(u_int index) {
    return GetArg(BASE_SIZE + index);
  }
};

class Record: private Block {
protected:
  static const u_int WIDTH_POS = 0;
  static const u_int BASE_SIZE = 1;
public:
  using Block::ToWord;

  static Record *New(u_int n) {
    Block *b = Store::AllocBlock(Alice::Record, BASE_SIZE + n * 2);
    b->InitArg(WIDTH_POS, n);
    return static_cast<Record *>(b);
  }
  static Record *New(Vector *labels) {
    u_int n = labels->GetLength();
    Block *b = Store::AllocBlock(Alice::Record, BASE_SIZE + n * 2);
    b->InitArg(WIDTH_POS, n);
    for (u_int i = n; i--; ) {
      UniqueString *label = UniqueString::FromWordDirect(labels->Sub(i));
      b->InitArg(BASE_SIZE + i * 2, label->ToWord());
    }
    return static_cast<Record *>(b);
  }
  static Record *FromWord(word x) {
    Block *p = Store::WordToBlock(x);
    Assert(p == INVALID_POINTER || p->GetLabel() == Alice::Record);
    return static_cast<Record *>(p);
  }
  static Record *FromWordDirect(word x) {
    Block *p = Store::DirectWordToBlock(x);
    Assert(p->GetLabel() == Alice::Record);
    return static_cast<Record *>(p);
  }

  void Init(u_int i, word value) {
    InitArg(BASE_SIZE + i * 2 + 1, value);
  }
  void Init(const char *s, word value) {
    UniqueString *label = UniqueString::New(String::New(s));
    u_int n = Store::DirectWordToInt(GetArg(WIDTH_POS));
    u_int index = label->Hash() % n;
    u_int i = index;
    while (true) {
      if (Store::WordToInt(GetArg(BASE_SIZE + i * 2)) != INVALID_INT) {
	InitArg(BASE_SIZE + i * 2, label->ToWord());
	InitArg(BASE_SIZE + i * 2 + 1, value);
	return;
      }
      i = (i + 1) % n;
      Assert(i != index);
    }
  }
  void AssertLabel(u_int i, UniqueString *label) {
    Assert(GetArg(BASE_SIZE + i * 2) == label->ToWord()); i = i; label = label;
  }
  word PolySel(UniqueString *label) {
    word wLabel = label->ToWord();
    u_int n = Store::DirectWordToInt(GetArg(WIDTH_POS));
    u_int index = label->Hash() % n;
    u_int i = index;
    while (true) {
      if (GetArg(BASE_SIZE + i * 2) == wLabel)
	return GetArg(BASE_SIZE + i * 2 + 1);
      i = (i + 1) % n;
      Assert(i != index);
    }
  }
};

#endif
