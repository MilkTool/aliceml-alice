//
// Authors:
//   Thorsten Brunklaus <brunklaus@ps.uni-sb.de>
//   Leif Kornstaedt <kornstae@ps.uni-sb.de>
//
// Copyright:
//   Thorsten Brunklaus and Leif Kornstaedt, 2002
//
// Last Change:
//   $Date$ by $Author$
//   $Revision$
//

#ifndef __JAVA__DATA_HH__
#define __JAVA__DATA_HH__

#if defined(INTERFACE)
#pragma interface "java/Data.hh"
#endif

#include <cstring>
#include "adt/HashTable.hh"
#include "generic/Closure.hh"
#include "generic/Transients.hh"
#include "generic/Worker.hh"
#include "generic/Float.hh"
#include "generic/Double.hh"

typedef u_char u_int8;
typedef signed char s_int8;
typedef short s_int16; //--** ensure that this is always 16-bit
typedef unsigned short u_int16; //--** ensure that this is always 16-bit
typedef s_int s_int32; //--** ensure that this is always 32-bit
typedef u_int u_int32; //--** ensure that this is always 32-bit
typedef signed long long s_int64; //--** ensure that this is always 64-bit
typedef unsigned long long u_int64; //--** ensure that this is always 64-bit

typedef u_int16 u_wchar;

class JavaLabel {
private:
  static const u_int base = MIN_DATA_LABEL;
public:
  static const BlockLabel ClassLoader         = (BlockLabel) (base + 0);
  // Symbolic class representation
  static const BlockLabel ConstantPool        = (BlockLabel) (base + 1);
  static const BlockLabel Table               = (BlockLabel) (base + 2);
  static const BlockLabel FieldInfo           = (BlockLabel) (base + 3);
  static const BlockLabel MethodInfo          = (BlockLabel) (base + 4);
  static const BlockLabel ClassInfo           = (BlockLabel) (base + 5);
  // Runtime class representation
  static const BlockLabel RuntimeConstantPool = (BlockLabel) (base + 6);
  static const BlockLabel StaticFieldRef      = (BlockLabel) (base + 7);
  static const BlockLabel InstanceFieldRef    = (BlockLabel) (base + 8);
  static const BlockLabel StaticMethodRef     = (BlockLabel) (base + 9);
  static const BlockLabel VirtualMethodRef    = (BlockLabel) (base + 10);
  // Code
  static const BlockLabel ExceptionTableEntry = (BlockLabel) (base + 11);
  // Types
  static const BlockLabel Class               = (BlockLabel) (base + 12);
  static const BlockLabel PrimitiveType       = (BlockLabel) (base + 13);
  static const BlockLabel ArrayType           = (BlockLabel) (base + 14);
  // Data layer
  static const BlockLabel Lock                = (BlockLabel) (base + 15);
  static const BlockLabel Object              = (BlockLabel) (base + 16);
  static const BlockLabel ObjectArray         = (BlockLabel) (base + 17);
  static const BlockLabel BaseArray           = CHUNK_LABEL;
};

static const word null = Store::IntToWord(0);

class DllExport Table: private Block {
protected:
  enum {
    COUNT_POS, // int
    BASE_SIZE
    // ... elements
  };
public:
  using Block::ToWord;

  static Table *New(u_int count) {
    Block *b = Store::AllocBlock(JavaLabel::Table, BASE_SIZE + count);
    b->InitArg(COUNT_POS, Store::IntToWord(count));
    return static_cast<Table *>(b);
  }
  static Table *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER || b->GetLabel() == JavaLabel::Table);
    return static_cast<Table *>(b);
  }
  static Table *FromWordDirect(word x) {
    Block *b = Store::DirectWordToBlock(x);
    Assert(b->GetLabel() == JavaLabel::Table);
    return static_cast<Table *>(b);
  }

  u_int GetCount() {
    return Store::DirectWordToInt(GetArg(COUNT_POS));
  }
  void Init(u_int index, word value) {
    Assert(index < GetCount());
    InitArg(BASE_SIZE + index, value);
  }
  word Get(u_int index) {
    Assert(index < GetCount());
    return GetArg(BASE_SIZE + index);
  }
};

//
// Types
//
class DllExport Type: public Block {
public:
  static Type *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER ||
	   b->GetLabel() == JavaLabel::Class ||
	   b->GetLabel() == JavaLabel::PrimitiveType ||
	   b->GetLabel() == JavaLabel::ArrayType);
    return static_cast<Type *>(b);
  }
  static Type *FromWordDirect(word x) {
    Block *b = Store::DirectWordToBlock(x);
    Assert(b->GetLabel() == JavaLabel::Class ||
	   b->GetLabel() == JavaLabel::PrimitiveType ||
	   b->GetLabel() == JavaLabel::ArrayType);
    return static_cast<Type *>(b);
  }
};

class DllExport Class: protected Type {
protected:
  enum {
    CLASS_INFO_POS, // ClassInfo
    METHOD_HASH_TABLE_POS, // HashTable(name x descriptor -> MethodRef)
    VIRTUAL_TABLE_POS, // Table(Closure)
    LOCK_POS, // Lock
    CLASS_INITIALIZER_POS, // Closure | int(0)
    NUMBER_OF_INSTANCE_FIELDS_POS, // int
    BASE_SIZE
    // ... static fields
    // ... static methods
  };
public:
  using Block::ToWord;

  static void Init();

  static Class *New(class ClassInfo *classInfo);
  static Class *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER || b->GetLabel() == JavaLabel::Class);
    return static_cast<Class *>(b);
  }
  static Class *FromWordDirect(word x) {
    Block *b = Store::DirectWordToBlock(x);
    Assert(b->GetLabel() == JavaLabel::Class);
    return static_cast<Class *>(b);
  }

  static word MakeMethodKey(class JavaString *name,
			    class JavaString *descriptor);

  class ClassInfo *GetClassInfo();
  bool IsInterface();
  Class *GetSuperClass();

  HashTable *GetMethodHashTable() {
    return HashTable::FromWordDirect(GetArg(METHOD_HASH_TABLE_POS));
  }
  void FillMethodHashTable(HashTable *methodHashTable);
  u_int GetNumberOfInstanceFields() {
    return Store::DirectWordToInt(GetArg(NUMBER_OF_INSTANCE_FIELDS_POS));
  }
  Table *GetVirtualTable() {
    return Table::FromWordDirect(GetArg(VIRTUAL_TABLE_POS));
  }
  Closure *GetVirtualMethod(u_int index) {
    return Closure::FromWordDirect(GetVirtualTable()->Get(index));
  }
  class Lock *GetLock();
  Closure *GetClassInitializer() {
    word wClassInitializer = GetArg(CLASS_INITIALIZER_POS);
    if (wClassInitializer == Store::IntToWord(0)) return INVALID_POINTER;
    return Closure::FromWordDirect(wClassInitializer);
  }
  word GetStaticField(u_int index) {
    return GetArg(BASE_SIZE + index);
  }
  void PutStaticField(u_int index, word value) {
    ReplaceArg(BASE_SIZE + index, value);
  }
  Closure *GetStaticMethod(u_int index) {
    return Closure::FromWordDirect(GetArg(BASE_SIZE + index));
  }
  bool IsInitialized() {
    return GetArg(CLASS_INITIALIZER_POS) == null;
  }
  Worker::Result RunInitializer();
};

class DllExport PrimitiveType: protected Type {
public:
  enum type { Byte, Char, Double, Float, Int, Long, Short, Boolean };
protected:
  enum {
    TYPE_POS, // int (type)
    SIZE
  };
public:
  using Block::ToWord;

  static PrimitiveType *New(type t) {
    Block *b = Store::AllocBlock(JavaLabel::PrimitiveType, SIZE);
    b->InitArg(TYPE_POS, t);
    return static_cast<PrimitiveType *>(b);
  }

  static u_int GetElementSize(type baseType) {
    switch (baseType) {
    case PrimitiveType::Boolean:
    case PrimitiveType::Byte:
      return 1;
    case PrimitiveType::Char:
    case PrimitiveType::Short:
      return 2;
    case PrimitiveType::Int:
    case PrimitiveType::Float:
      return 4;
    case PrimitiveType::Long:
    case PrimitiveType::Double:
      return 8;
    default:
      Error("invalid base type");
    }
  }

  type GetType() {
    return static_cast<type>(Store::DirectWordToInt(GetArg(TYPE_POS)));
  }
};

class DllExport ArrayType: protected Type {
protected:
  enum {
    TYPE_POS, // Type
    SIZE
  };
public:
  using Block::ToWord;

  static ArrayType *New(word wType) {
    Block *b = Store::AllocBlock(JavaLabel::ArrayType, SIZE);
    b->InitArg(TYPE_POS, wType);
    return static_cast<ArrayType *>(b);
  }
};

//
// Data Layer
//
//--** to be done: support boxed 32-bit integers (for compatibility)
class DllExport JavaInt {
public:
  static word ToWord(s_int value) {
    s_int x = value * 2;
    return Store::IntToWord(x / 2); //--** hack: sign-extend 31-bit -> 32-bit
  }
  static s_int FromWord(word value) {
    return Store::DirectWordToInt(value);
  }
};

class DllExport JavaLong: public Chunk {
public:
  static JavaLong *New(s_int32 high, s_int32 low) {
    Chunk *chunk = Store::AllocChunk(8);
    char *p = chunk->GetBase();
    p[0] = high >> 24; p[1] = high >> 16; p[2] = high >> 8; p[3] = high;
    p[4] = low >> 24; p[5] = low >> 16; p[6] = low >> 8; p[7] = low;
    return static_cast<JavaLong *>(chunk);
  }
  static JavaLong *New(s_int64 v) {
    Chunk *chunk = Store::AllocChunk(8);
    char *p = chunk->GetBase();
    p[0] = v >> 56; p[1] = v >> 48; p[2] = v >> 40; p[3] = v >> 32;
    p[4] = v >> 24; p[5] = v >> 16; p[6] = v >> 8; p[7] = v;
    return static_cast<JavaLong *>(chunk);
  }
  static JavaLong *New(u_char *p) {
    Chunk *chunk = Store::AllocChunk(8);
    std::memcpy(chunk->GetBase(), p, 8);
    return static_cast<JavaLong *>(chunk);
  }
  static JavaLong *FromWord(word x) {
    return static_cast<JavaLong *>(Store::WordToChunk(x));
  }
  static JavaLong *FromWordDirect(word x) {
    return static_cast<JavaLong *>(Store::DirectWordToChunk(x));
  }

  s_int64 GetValue() {
    u_char *p = reinterpret_cast<u_char *>(GetBase());
    u_int64 high =
      static_cast<u_int32>((p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3]);
    u_int64 low =
      static_cast<u_int32>((p[4] << 24) | (p[5] << 16) | (p[6] << 8) | p[7]);
    return (high << 32) | low;
  }
  u_char *GetNetworkRepresentation() {
    return reinterpret_cast<u_char *>(GetBase());
  }
};

class DllExport Lock: private Block {
protected:
  enum { COUNT_POS, THREAD_POS, FUTURE_POS, SIZE };
public:
  using Block::ToWord;

  static Lock *New() {
    Block *b = Store::AllocBlock(JavaLabel::Lock, SIZE);
    b->InitArg(COUNT_POS, 0);
    return static_cast<Lock *>(b);
  }
  static Lock *FromWordDirect(word x) {
    Block *b = Store::DirectWordToBlock(x);
    Assert(b->GetLabel() == JavaLabel::Lock);
    return static_cast<Lock *>(b);
  }

  Future *Acquire() {
    u_int count = Store::DirectWordToInt(GetArg(COUNT_POS));
    if (count == 0) {
      ReplaceArg(COUNT_POS, 1);
      ReplaceArg(THREAD_POS, Scheduler::GetCurrentThread()->ToWord());
      ReplaceArg(FUTURE_POS, 0);
      return INVALID_POINTER;
    } else {
      Thread *thread = Thread::FromWordDirect(GetArg(THREAD_POS));
      if (thread == Scheduler::GetCurrentThread()) {
	ReplaceArg(COUNT_POS, count + 1);
	return INVALID_POINTER;
      } else {
	word wFuture = GetArg(FUTURE_POS);
	Future *future;
	if (wFuture == Store::IntToWord(0)) {
	  future = Future::New();
	  ReplaceArg(FUTURE_POS, future->ToWord());
	} else {
	  future = static_cast<Future *>
	    (Store::DirectWordToTransient(wFuture));
	}
	future->AddToWaitQueue(thread);
	Scheduler::currentData = future->ToWord();
	return future;
      }
    }
  }
  void Release() {
    u_int count = Store::DirectWordToInt(GetArg(COUNT_POS));
    Assert(count > 0);
    Assert(Thread::FromWordDirect(GetArg(THREAD_POS)) ==
	   Scheduler::GetCurrentThread());
    if (count > 1) {
      ReplaceArg(COUNT_POS, count - 1);
    } else {
      word wFuture = GetArg(FUTURE_POS);
      if (wFuture != Store::IntToWord(0)) {
	Future *future = static_cast<Future *>
	  (Store::DirectWordToTransient(wFuture));
	future->ScheduleWaitingThreads();
      }
      ReplaceArg(COUNT_POS, 0);
    }
  }
  void AssertAcquired() {
    Assert(Thread::FromWordDirect(GetArg(THREAD_POS)) ==
	   Scheduler::GetCurrentThread());
  }
};

class DllExport Object: private Block {
protected:
  enum {
    CLASS_POS, // Class
    LOCK_POS, // Lock | int(0)
    BASE_SIZE
    // ... instance fields
  };

  static Object *New(word wClass, u_int size) {
    Block *b = Store::AllocBlock(JavaLabel::Object, BASE_SIZE + size);
    b->InitArg(CLASS_POS, wClass);
    b->InitArg(LOCK_POS, null);
    //--** initialization incorrect for long/float/double
    for (u_int i = size; i--; ) b->InitArg(BASE_SIZE + i, null);
    return static_cast<Object *>(b);
  }
public:
  using Block::ToWord;

  static Object *New(Class *theClass) {
    return New(theClass->ToWord(), theClass->GetNumberOfInstanceFields());
  }
  static Object *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER || b->GetLabel() == JavaLabel::Object);
    return static_cast<Object *>(b);
  }
  static Object *FromWordDirect(word x) {
    Block *b = Store::DirectWordToBlock(x);
    Assert(b->GetLabel() == JavaLabel::Object);
    return static_cast<Object *>(b);
  }

  Class *GetClass() {
    Class *theClass = Class::FromWord(GetArg(CLASS_POS));
    Assert(theClass != INVALID_POINTER);
    return theClass;
  }
  bool IsInstanceOf(Class *aClass) {
    Assert(!aClass->IsInterface());
    Class *theClass = GetClass();
  loop:
    if (theClass == aClass) return true;
    theClass = theClass->GetSuperClass();
    if (theClass == INVALID_POINTER) return false;
    goto loop;
  }
  Lock *GetLock() {
    word wLock = GetArg(LOCK_POS);
    if (wLock == null) {
      Lock *lock = Lock::New();
      ReplaceArg(LOCK_POS, lock->ToWord());
      return lock;
    }
    return Lock::FromWordDirect(wLock);
  }
  void InitInstanceField(u_int index, word value) {
    ReplaceArg(BASE_SIZE + index, value);
  }
  void PutInstanceField(u_int index, word value) {
    ReplaceArg(BASE_SIZE + index, value);
  }
  word GetInstanceField(u_int index) {
    return GetArg(BASE_SIZE + index);
  }
  Closure *GetVirtualMethod(u_int index) {
    return GetClass()->GetVirtualMethod(index);
  }
};

class DllExport ObjectArray: private Block {
protected:
  enum {
    ELEMENT_TYPE_POS, // Type (!= PrimitiveType)
    LENGTH_POS, // int
    BASE_SIZE
    // ... elements
  };
public:
  using Block::ToWord;

  static ObjectArray *New(Type *elementType, u_int length) {
    Assert(elementType->GetLabel() != JavaLabel::PrimitiveType);
    Block *b = Store::AllocBlock(JavaLabel::ObjectArray, BASE_SIZE + length);
    b->InitArg(ELEMENT_TYPE_POS, elementType->ToWord());
    b->InitArg(LENGTH_POS, Store::IntToWord(length));
    for (u_int i = length; i--; ) b->InitArg(BASE_SIZE + i, null);
    return static_cast<ObjectArray *>(b);
  }
  static ObjectArray *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER || b->GetLabel() == JavaLabel::ObjectArray);
    return static_cast<ObjectArray *>(b);
  }
  static ObjectArray *FromWordDirect(word x) {
    Block *b = Store::DirectWordToBlock(x);
    Assert(b->GetLabel() == JavaLabel::ObjectArray);
    return static_cast<ObjectArray *>(b);
  }

  Type *GetElementType() {
    return Type::FromWordDirect(GetArg(ELEMENT_TYPE_POS));
  }
  u_int GetLength() {
    return Store::DirectWordToInt(GetArg(LENGTH_POS));
  }
  void Init(u_int index, word value) {
    Assert(index < GetLength());
    InitArg(BASE_SIZE + index, value);
  }
  word Load(u_int index) {
    Assert(index < GetLength());
    return GetArg(BASE_SIZE + index);
  }
  void Store(u_int index, word value) {
    //--** assert assignment compatibility
    Assert(index < GetLength());
    ReplaceArg(BASE_SIZE + index, value);
  }
};

class BaseArray: private Chunk {
  friend class JavaString;
protected:
  enum {
    ELEMENT_TYPE_POS, // byte (PrimitiveType::type);
    BASE_SIZE
    // ... elements
  };
  u_char *GetElementPointer(u_int index, u_int elemSize) {
    Assert(index < (GetSize() - BASE_SIZE) / elemSize);
    return reinterpret_cast<u_char *>
      (GetBase() + BASE_SIZE + index * elemSize);
  }
public:
  using Block::ToWord;

  static BaseArray *New(PrimitiveType::type elementType, u_int length) {
    u_int elementSize = PrimitiveType::GetElementSize(elementType);
    Chunk *chunk = Store::AllocChunk(BASE_SIZE + length * elementSize);
    char *p = chunk->GetBase();
    //--** initialization wrong for float/double
    for (u_int i = length * elementSize; i--; ) p[BASE_SIZE + i] = 0;
    p[ELEMENT_TYPE_POS] = elementType;
    return static_cast<BaseArray *>(chunk);
  }
  static BaseArray *FromWord(word x) {
    return static_cast<BaseArray *>(Store::WordToChunk(x));
  }
  static BaseArray *FromWordDirect(word x) {
    return static_cast<BaseArray *>(Store::DirectWordToChunk(x));
  }

  PrimitiveType::type GetElementType() {
    return static_cast<PrimitiveType::type>(GetBase()[ELEMENT_TYPE_POS]);
  }
  u_int GetLength() {
    switch (GetElementType()) {
    case PrimitiveType::Boolean:
    case PrimitiveType::Byte:
      return GetSize() - BASE_SIZE;
    case PrimitiveType::Char:
    case PrimitiveType::Short:
      return (GetSize() - BASE_SIZE) / 2;
    case PrimitiveType::Int:
    case PrimitiveType::Float:
      return (GetSize() - BASE_SIZE) / 4;
    case PrimitiveType::Long:
    case PrimitiveType::Double:
      return (GetSize() - BASE_SIZE) / 8;
    default:
      Error("invalid base type");
    }
  }

  u_int LoadBoolean(u_int index) {
    Assert(GetElementType() == PrimitiveType::Boolean);
    return GetElementPointer(index, 1)[0];
  }
  u_int LoadByte(u_int index) {
    Assert(GetElementType() == PrimitiveType::Byte);
    return GetElementPointer(index, 1)[0];
  }
  u_int LoadChar(u_int index) {
    Assert(GetElementType() == PrimitiveType::Char);
    u_char *p = GetElementPointer(index, 2);
    return (p[0] << 8) | p[1];
  }
  u_int LoadShort(u_int index) {
    Assert(GetElementType() == PrimitiveType::Short);
    u_char *p = GetElementPointer(index, 2);
    return (p[0] << 8) | p[1];
  }
  u_int LoadInt(u_int index) {
    Assert(GetElementType() == PrimitiveType::Int);
    u_char *p = GetElementPointer(index, 4);
    return (p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3];
  }
  JavaLong *LoadLong(u_int index) {
    Assert(GetElementType() == PrimitiveType::Long);
    return JavaLong::New(GetElementPointer(index, 8));
  }
  Float *LoadFloat(u_int index) {
    Assert(GetElementType() == PrimitiveType::Float);
    return Float::NewFromNetworkRepresentation(GetElementPointer(index, 4));
  }
  Double *LoadDouble(u_int index) {
    Assert(GetElementType() == PrimitiveType::Double);
    return Double::NewFromNetworkRepresentation(GetElementPointer(index, 8));
  }

  void StoreBoolean(u_int index, u_int value) {
    Assert(GetElementType() == PrimitiveType::Boolean);
    GetElementPointer(index, 1)[0] = value & 1;
  }
  void StoreByte(u_int index, u_int value) {
    Assert(GetElementType() == PrimitiveType::Byte);
    GetElementPointer(index, 1)[0] = value;
  }
  void StoreChar(u_int index, u_int value) {
    Assert(GetElementType() == PrimitiveType::Char);
    u_char *p = GetElementPointer(index, 2);
    p[0] = value >> 8;
    p[1] = value;
  }
  void StoreShort(u_int index, u_int value) {
    Assert(GetElementType() == PrimitiveType::Short);
    u_char *p = GetElementPointer(index, 2);
    p[0] = value >> 8;
    p[1] = value;
  }
  void StoreInt(u_int index, u_int value) {
    Assert(GetElementType() == PrimitiveType::Int);
    u_char *p = GetElementPointer(index, 4);
    p[0] = value >> 24;
    p[1] = value >> 16;
    p[2] = value >> 8;
    p[3] = value;
  }
  void StoreLong(u_int index, JavaLong *value) {
    Assert(GetElementType() == PrimitiveType::Long);
    std::memcpy(GetElementPointer(index, 8),
		value->GetNetworkRepresentation(), 8);
  }
  void StoreFloat(u_int index, Float *value) {
    Assert(GetElementType() == PrimitiveType::Float);
    std::memcpy(GetElementPointer(index, 4),
		value->GetNetworkRepresentation(), 4);
  }
  void StoreDouble(u_int index, Double *value) {
    Assert(GetElementType() == PrimitiveType::Double);
    std::memcpy(GetElementPointer(index, 8),
		value->GetNetworkRepresentation(), 8);
  }

  void Copy(u_int destPos, BaseArray *srcArray, u_int srcPos, u_int n) {
    Assert(GetElementType() == srcArray->GetElementType());
    Assert(destPos + n <= GetLength());
    Assert(srcPos + n <= srcArray->GetLength());
    u_int elemSize = PrimitiveType::GetElementSize(GetElementType());
    if (srcArray == this) {
      std::memmove(GetElementPointer(destPos, elemSize),
		   srcArray->GetElementPointer(srcPos, elemSize),
		   n * elemSize);
    } else {
      std::memcpy(GetElementPointer(destPos, elemSize),
		  srcArray->GetElementPointer(srcPos, elemSize),
		  n * elemSize);
    }
  }
};

class DllExport JavaString: public Object {
protected:
  enum {
    VALUE_INDEX, // BaseArray(Char)
    OFFSET_INDEX, // int
    COUNT_INDEX, // int
    HASH_INDEX, // int
    SIZE
  };
private:
  static word wClass;

  BaseArray *GetValue() {
    return BaseArray::FromWordDirect(GetInstanceField(VALUE_INDEX));
  }
  u_int GetOffset() {
    return Store::DirectWordToInt(GetInstanceField(OFFSET_INDEX));
  }
  u_int GetCount() {
    return Store::DirectWordToInt(GetInstanceField(COUNT_INDEX));
  }
  u_char *GetBase(u_int offset) {
    Assert(offset < GetValue()->GetLength());
    return GetValue()->GetElementPointer(offset, 2);
  }
  u_char *GetBase() {
    return GetBase(GetOffset());
  }
public:
  static void Init();

  static JavaString *New(BaseArray *array, u_int offset, u_int length) {
    Object *object = Object::New(wClass, SIZE);
    object->InitInstanceField(VALUE_INDEX, array->ToWord());
    object->InitInstanceField(OFFSET_INDEX, Store::IntToWord(offset));
    object->InitInstanceField(COUNT_INDEX, Store::IntToWord(length));
    object->InitInstanceField(HASH_INDEX, Store::IntToWord(0));
    return static_cast<JavaString *>(object);
  }
  static JavaString *New(u_int length) {
    return New(BaseArray::New(PrimitiveType::Char, length), 0, length);
  }
  static JavaString *New(const u_wchar *s, u_int length) {
    JavaString *string = New(length);
    u_char *p = string->GetBase(0);
    for (u_int i = length; i--; ) {
      u_int i = *s++;
      *p++ = i >> 8;
      *p++ = i;
    }
    return string;
  }
  static JavaString *New(const char *s, u_int length) {
    JavaString *string = New(length);
    u_char *p = string->GetBase(0);
    for (u_int i = length; i--; ) { *p++ = 0; *p++ = *s++; }
    return string;
  }
  static JavaString *New(const char *s) {
    return New(s, std::strlen(s));
  }
  static JavaString *FromWord(word x) {
    return static_cast<JavaString *>(Object::FromWord(x));
  }
  static JavaString *FromWordDirect(word x) {
    return static_cast<JavaString *>(Object::FromWordDirect(x));
  }

  u_int GetLength() {
    return GetCount();
  }
  u_wchar CharAt(u_int index) {
    u_char *p = GetBase(GetOffset() + index);
    return (p[0] << 8) | p[1];
  }
  bool Equals(JavaString *otherString) {
    u_int length = GetLength();
    if (otherString->GetLength() != length) return false;
    return !std::memcmp(GetBase(), otherString->GetBase(),
			length * sizeof(u_wchar));
  }
  JavaString *Concat(JavaString *otherString) {
    u_int length = GetLength();
    u_int otherLength = otherString->GetLength();
    JavaString *resultString = JavaString::New(length + otherLength);
    u_char *p = resultString->GetBase(0);
    std::memcpy(p, GetBase(), length * 2);
    std::memcpy(p + length * 2, otherString->GetBase(), otherLength * 2);
    return resultString;
  }
  JavaString *Concat(const char *s) {
    u_int length = GetLength();
    u_int otherLength = std::strlen(s);
    JavaString *resultString = JavaString::New(length + otherLength);
    u_char *p = resultString->GetBase(0);
    std::memcpy(p, GetBase(), length * 2);
    p += length * 2;
    for (u_int i = otherLength; i--; ) { *p++ = 0; *p++ = *s++; }
    return resultString;
  }
  JavaString *Substring(u_int beginIndex, u_int endIndex) {
    u_int offset = GetOffset();
    return JavaString::New(GetValue(), offset + beginIndex,
			   endIndex - beginIndex);
  }
  JavaString *Intern();
  BaseArray *ToArray() {
    BaseArray *array = GetValue();
    u_int offset = GetOffset();
    u_int length = GetLength();
    if (offset == 0 && length == array->GetLength()) return array;
    BaseArray *newArray = BaseArray::New(PrimitiveType::Char, length);
    for (u_int i = length; i--; )
      newArray->StoreChar(i, array->LoadChar(offset + i));
    return newArray;
  }

  char *ExportC() {
    u_int n = GetLength();
    Chunk *chunk = Store::AllocChunk(n + 1);
    char *p = chunk->GetBase();
    u_char *q = GetBase();
    for (u_int i = n; i--; ) p[i] = q[i * 2 + 1];
    p[n] = '\0';
    return p;
  }
};

class DllExport StackTraceElement: public Object {
public:
  enum {
    DECLARING_CLASS_INDEX, // JavaString
    METHOD_NAME_INDEX, // JavaString
    FILE_NAME_INDEX, // JavaString | null
    LINE_NUMBER_INDEX, // int (-1 == unknown, -2 == native)
    SIZE
  };
};

//
// Runtime Constant Pool Entries
//

class DllExport RuntimeConstantPool: private Block {
public:
  using Block::ToWord;

  static RuntimeConstantPool *New(u_int size) {
    Block *b = Store::AllocBlock(JavaLabel::RuntimeConstantPool, size);
    return static_cast<RuntimeConstantPool *>(b);
  }
  static RuntimeConstantPool *FromWordDirect(word x) {
    Block *b = Store::DirectWordToBlock(x);
    Assert(b->GetLabel() == JavaLabel::RuntimeConstantPool);
    return static_cast<RuntimeConstantPool *>(b);
  }

  void Init(u_int index, word value) {
    InitArg(index - 1, value);
  }
  word Get(u_int index) {
    return GetArg(index - 1);
  }
};

class DllExport FieldRef: public Block {
public:
  static FieldRef *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER ||
	   b->GetLabel() == JavaLabel::StaticFieldRef ||
	   b->GetLabel() == JavaLabel::InstanceFieldRef);
    return static_cast<FieldRef *>(b);
  }
};

class DllExport StaticFieldRef: private FieldRef {
protected:
  enum { CLASS_POS, INDEX_POS, NUMBER_OF_REQUIRED_SLOTS_POS, SIZE };
public:
  using Block::ToWord;

  static StaticFieldRef *New(Class *theClass, u_int index, u_int nSlots) {
    Block *b = Store::AllocBlock(JavaLabel::StaticFieldRef, SIZE);
    b->InitArg(CLASS_POS, theClass->ToWord());
    b->InitArg(INDEX_POS, index);
    b->InitArg(NUMBER_OF_REQUIRED_SLOTS_POS, nSlots);
    return static_cast<StaticFieldRef *>(b);
  }
  static StaticFieldRef *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER || b->GetLabel() == JavaLabel::StaticFieldRef);
    return static_cast<StaticFieldRef *>(b);
  }

  Class *GetClass() {
    return Class::FromWordDirect(GetArg(CLASS_POS));
  }
  u_int GetIndex() {
    return Store::DirectWordToInt(GetArg(INDEX_POS));
  }
  u_int GetNumberOfRequiredSlots() {
    return Store::DirectWordToInt(GetArg(NUMBER_OF_REQUIRED_SLOTS_POS));
  }
};

class DllExport InstanceFieldRef: private FieldRef {
protected:
  enum { INDEX_POS, NUMBER_OF_REQUIRED_SLOTS_POS, SIZE };
public:
  using Block::ToWord;

  static InstanceFieldRef *New(u_int index, u_int nSlots) {
    Block *b = Store::AllocBlock(JavaLabel::InstanceFieldRef, SIZE);
    b->InitArg(INDEX_POS, index);
    b->InitArg(NUMBER_OF_REQUIRED_SLOTS_POS, nSlots);
    return static_cast<InstanceFieldRef *>(b);
  }
  static InstanceFieldRef *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER ||
	   b->GetLabel() == JavaLabel::InstanceFieldRef);
    return static_cast<InstanceFieldRef *>(b);
  }

  u_int GetIndex() {
    return Store::DirectWordToInt(GetArg(INDEX_POS));
  }
  u_int GetNumberOfRequiredSlots() {
    return Store::DirectWordToInt(GetArg(NUMBER_OF_REQUIRED_SLOTS_POS));
  }
};

class DllExport MethodRef: public Block {
public:
  static MethodRef *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER ||
	   b->GetLabel() == JavaLabel::StaticMethodRef ||
	   b->GetLabel() == JavaLabel::VirtualMethodRef);
    return static_cast<MethodRef *>(b);
  }
};

class DllExport StaticMethodRef: private MethodRef {
protected:
  enum { CLASS_POS, INDEX_POS, NUMBER_OF_ARGUMENTS_POS, SIZE };
public:
  using Block::ToWord;

  static StaticMethodRef *New(Class *theClass, u_int index, u_int nArgs) {
    Block *b = Store::AllocBlock(JavaLabel::StaticMethodRef, SIZE);
    b->InitArg(CLASS_POS, theClass->ToWord());
    b->InitArg(INDEX_POS, index);
    b->InitArg(NUMBER_OF_ARGUMENTS_POS, nArgs);
    return static_cast<StaticMethodRef *>(b);
  }
  static StaticMethodRef *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER ||
	   b->GetLabel() == JavaLabel::StaticMethodRef);
    return static_cast<StaticMethodRef *>(b);
  }
  static StaticMethodRef *FromWordDirect(word x) {
    Block *b = Store::DirectWordToBlock(x);
    Assert(b->GetLabel() == JavaLabel::StaticMethodRef);
    return static_cast<StaticMethodRef *>(b);
  }

  Class *GetClass() {
    return Class::FromWordDirect(GetArg(CLASS_POS));
  }
  u_int GetIndex() {
    return Store::DirectWordToInt(GetArg(INDEX_POS));
  }
  u_int GetNumberOfArguments() {
    return Store::DirectWordToInt(GetArg(NUMBER_OF_ARGUMENTS_POS));
  }
};

class DllExport VirtualMethodRef: private MethodRef {
protected:
  enum { CLASS_POS, INDEX_POS, NUMBER_OF_ARGUMENTS_POS, SIZE };
public:
  using Block::ToWord;

  static VirtualMethodRef *New(Class *theClass, u_int index, u_int nArgs) {
    Block *b = Store::AllocBlock(JavaLabel::VirtualMethodRef, SIZE);
    b->InitArg(CLASS_POS, theClass->ToWord());
    b->InitArg(INDEX_POS, index);
    b->InitArg(NUMBER_OF_ARGUMENTS_POS, nArgs);
    return static_cast<VirtualMethodRef *>(b);
  }
  static VirtualMethodRef *FromWord(word x) {
    Block *b = Store::WordToBlock(x);
    Assert(b == INVALID_POINTER ||
	   b->GetLabel() == JavaLabel::VirtualMethodRef);
    return static_cast<VirtualMethodRef *>(b);
  }
  static VirtualMethodRef *FromWordDirect(word x) {
    Block *b = Store::DirectWordToBlock(x);
    Assert(b->GetLabel() == JavaLabel::VirtualMethodRef);
    return static_cast<VirtualMethodRef *>(b);
  }

  Class *GetClass() {
    return Class::FromWordDirect(GetArg(CLASS_POS));
  }
  u_int GetIndex() {
    return Store::DirectWordToInt(GetArg(INDEX_POS));
  }
  u_int GetNumberOfArguments() {
    return Store::DirectWordToInt(GetArg(NUMBER_OF_ARGUMENTS_POS));
  }
};

//
// Implementation of Inline `Class' Methods
//

inline Lock *Class::GetLock() {
  return Lock::FromWordDirect(GetArg(LOCK_POS));
}

#endif
