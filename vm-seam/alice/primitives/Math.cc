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

#include <cmath>
#include "alice/primitives/Authoring.hh"

#define REAL_TO_REAL(name, op)					\
  DEFINE1(name) {						\
    DECLARE_REAL(real, x0);					\
    RETURN(Real::New(op(real->GetValue()))->ToWord());		\
  } END

#define REAL_REAL_TO_REAL(name, op)					   \
  DEFINE2(name) {							   \
    DECLARE_REAL(real1, x0);						   \
    DECLARE_REAL(real2, x1);						   \
    RETURN(Real::New(op(real1->GetValue(), real2->GetValue()))->ToWord()); \
  } END

static inline double Asinh(double x) {
  return log(x + sqrt(x * x + 1.0));
}

static inline double Acosh(double x) {
  return log(x + sqrt(x * x - 1.0));
}

static inline double Atanh(double x) {
  if (fabs(x) > 1.0) {
    return asin(2.0);
  } else {
    return log((1.0 + x) / (1.0 - x)) / 2.0;
  }
}

REAL_TO_REAL(Math_acos, std::acos)
REAL_TO_REAL(Math_acosh, Acosh)
REAL_TO_REAL(Math_asin, std::asin)
REAL_TO_REAL(Math_asinh, Asinh)
REAL_TO_REAL(Math_atan, std::atan)
REAL_TO_REAL(Math_atanh, Atanh)
REAL_REAL_TO_REAL(Math_atan2, std::atan2);
REAL_TO_REAL(Math_cos, std::cos)
REAL_TO_REAL(Math_cosh, std::cosh)
REAL_TO_REAL(Math_exp, std::exp)
REAL_TO_REAL(Math_ln, std::log)
REAL_REAL_TO_REAL(Math_pow, std::pow);
REAL_TO_REAL(Math_sin, std::sin);
REAL_TO_REAL(Math_sinh, std::sinh);
REAL_TO_REAL(Math_sqrt, std::sqrt);
REAL_TO_REAL(Math_tan, std::tan);
REAL_TO_REAL(Math_tanh, std::tanh);

void PrimitiveTable::RegisterMath() {
  Register("Math.acos", Math_acos, 1);
  Register("Math.acosh", Math_acosh, 1);
  Register("Math.asin", Math_asin, 1);
  Register("Math.asinh", Math_asinh, 1);
  Register("Math.atan", Math_atan, 1);
  Register("Math.atanh", Math_atanh, 1);
  Register("Math.atan2", Math_atan2, 2);
  Register("Math.cos", Math_cos, 1);
  Register("Math.cosh", Math_cosh, 1);
  Register("Math.e", Real::New(2.71828182846)->ToWord());
  Register("Math.exp", Math_exp, 1);
  Register("Math.ln", Math_ln, 1);
  Register("Math.pi", Real::New(3.14159265359)->ToWord());
  Register("Math.pow", Math_pow, 2);
  Register("Math.sin", Math_sin, 1);
  Register("Math.sinh", Math_sinh, 1);
  Register("Math.sqrt", Math_sqrt, 1);
  Register("Math.tan", Math_tan, 1);
  Register("Math.tanh", Math_tanh, 1);
}
