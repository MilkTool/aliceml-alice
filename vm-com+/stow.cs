//
// Authors:
//   Thorsten Brunklaus <brunklaus@ps.uni-sb.de>
//   Leif Kornstaedt <kornstae@ps.uni-sb.de>
//
// Copyright:
//   Thorsten Brunklaus and Leif Kornstaedt, 2000
//
// Last change:
//   $Date$ by $Author$
//   $Revision$
//

using System;

class Start {
    public static void Main(string[] args) {
	Alice.Komponist k = new Alice.Komponist();
	Alice.Komponist.global_k = k;
	if (args.Length < 1) {
	    Console.WriteLine("Usage: stow <application dll> <arguments ...>");
	    Environment.Exit(2);
	} else {
	    try {
		Alice.Builtins.Future_await.StaticApply(k.Import(args[0]));
	    } catch (System.Reflection.TargetInvocationException e) {
		Exception ei = e.InnerException;
		if (ei is Alice.Values.Exception) {
		    Alice.Values.Exception ai = (Alice.Values.Exception) ei;
		    Console.WriteLine(ei.StackTrace.ToString());
		    Console.WriteLine(ai.Value);
		}
	    }
	}
    }
}
