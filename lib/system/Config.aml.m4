(*
 * Authors:
 *   Leif Kornstaedt <kornstae@ps.uni-sb.de>
 *   Andreas Rossberg <rossberg@ps.uni-sb.de>
 *
 * Copyright:
 *   Leif Kornstaedt and Andreas Rossberg, 2001
 *
 * Last change:
 *   $Date$ by $Author$
 *   $Revision$
 *)

import structure OS           from "OS"
import signature CONFIG       from "CONFIG-sig"
import structure UnsafeConfig from "UnsafeConfig"

structure Config : CONFIG =
struct
    datatype platform = WIN32 | UNIX

    val platform = UnsafeConfig.platform
    val homeDir  = OS.Process.getEnv "STOCKHOME"
end
