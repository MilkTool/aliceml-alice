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

#ifndef __JAVA__JAVA_BYTE_CODE_HH__
#define __JAVA__JAVA_BYTE_CODE_HH__

#if defined(INTERFACE)
#pragma interface "java/JavaByteCode.hh"
#endif

#include "generic/ConcreteCode.hh"
#include "java/Data.hh"
#include "java/Table.hh"
#include "java/ByteCodeInterpreter.hh"

class DllExport ExceptionTableEntry: private Block {
protected:
  enum {
    START_PC_POS, // int
    END_PC_POS, // int
    HANDLER_PC_POS, // int
    CATCH_TYPE_POS, // Future(Class) | int(0)
    SIZE
  };
private:
  static ExceptionTableEntry *NewInternal(u_int startPC, u_int endPC,
					  u_int handlerPC) {
    Block *b = Store::AllocBlock(JavaLabel::ExceptionTableEntry, SIZE);
    b->InitArg(START_PC_POS, startPC);
    b->InitArg(END_PC_POS, endPC);
    b->InitArg(HANDLER_PC_POS, handlerPC);
    return static_cast<ExceptionTableEntry *>(b);
  }
public:
  using Block::ToWord;

  static ExceptionTableEntry *New(u_int startPC, u_int endPC,
				  u_int handlerPC) {
    ExceptionTableEntry *entry = NewInternal(startPC, endPC, handlerPC);
    entry->InitArg(CATCH_TYPE_POS, 0);
    return entry;
  }
  static ExceptionTableEntry *New(u_int startPC, u_int endPC,
				  u_int handlerPC, word catchType) {
    ExceptionTableEntry *entry = NewInternal(startPC, endPC, handlerPC);
    entry->InitArg(CATCH_TYPE_POS, catchType);
    return entry;
  }
};

class DllExport JavaByteCode: private ConcreteCode {
protected:
  enum {
    MAX_STACK_POS, // int
    MAX_LOCALS_POS, // int
    CODE_POS, // Chunk
    EXCEPTION_TABLE_POS, // Table(ExceptionTableEntry)
    SIZE
  };
public:
  using Block::ToWord;

  static JavaByteCode *New(u_int maxStack, u_int maxLocals, Chunk *code,
			   Table *exceptionTable) {
    ConcreteCode *concreteCode =
      ConcreteCode::New(ByteCodeInterpreter::self, SIZE);
    concreteCode->Init(MAX_STACK_POS, Store::IntToWord(maxStack));
    concreteCode->Init(MAX_LOCALS_POS, Store::IntToWord(maxLocals));
    concreteCode->Init(CODE_POS, code->ToWord());
    concreteCode->Init(EXCEPTION_TABLE_POS, exceptionTable->ToWord());
    return static_cast<JavaByteCode *>(concreteCode);
  }

  u_int GetMaxStack() {
    return Store::DirectWordToInt(Get(MAX_STACK_POS));
  }
  u_int GetMaxLocals() {
    return Store::DirectWordToInt(Get(MAX_LOCALS_POS));
  }
  Chunk *GetCode() {
    return Store::DirectWordToChunk(Get(CODE_POS));
  }
  Table *GetExceptionTable() {
    return Table::FromWordDirect(Get(EXCEPTION_TABLE_POS));
  }
};

#endif
