#ifndef __headerop_hh__
#define __headerop_hh__

#include "base.hh"
#include "headerdef.hh"

class HeaderOp : private HeaderDef {
public:
  // Header Creation and Acess
  static void EncodeHeader(Block *t, t_label l, u_int s, u_int g) {
    Assert(t != NULL);
    ((u_int *) t)[0] =  0x00 | (s << SIZE_SHIFT) | (((u_int) l) << TAG_SHIFT) | (g << GEN_SHIFT);
  }
  static u_int GetHeader(Block *p) {
    Assert(p != NULL); return *((u_int *) p);
  }
  // Label Access
  static void EncodeLabel(Transient *p, t_label l) {
    Assert(p != NULL);
    ((u_int *) p)[0] = ((((u_int *) p)[0] & ~TAG_MASK) | (((u_int) l) << TAG_SHIFT));
  }
  static t_label DecodeLabel(Block *p) {
    Assert(p != NULL);
    return (t_label) ((((u_int *) p)[0] & TAG_MASK) >> TAG_SHIFT);
  }
  // Size Access
  static u_int BlankDecodeSize(Block *p) {
    Assert (p != NULL);
    return (u_int) ((((u_int *) p)[0] & SIZE_MASK) >> SIZE_SHIFT);
  }
  static u_int DecodeSize(Block *p) {
    u_int s = BlankDecodeSize(p);
    return (u_int) ((s < MAX_HBSIZE) ? s : (*((u_int *) ((char *) p - 4)) >> 1));
  }
  static void EncodeSize(Block *p, u_int s) {
    if (HeaderOp::BlankDecodeSize(p) == HeaderDef::MAX_HBSIZE) {
      *((u_int *) ((char *) p - 4)) = s;
    }
    else {
      *((u_int *) p) = ((((u_int *) p)[0] & ~SIZE_MASK) | (s << SIZE_SHIFT));
    }
  }
};

#endif
