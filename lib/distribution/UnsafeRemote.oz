%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 2001-2002
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

functor
import
   BootName(newUnique: NewUniqueName) at 'x-oz://boot/Name'
   Alice(rpc) at 'x-oz://boot/Alice'
   Pickle(packWithCells unpack) at 'x-oz://boot/Pickle'
   Property(put)
   Connection(offer)
export
   'UnsafeRemote$' : Remote
define
   SitedException = {NewUniqueName 'UnsafeRemote.Sited'}

   Remote =
   'Remote'('Sited': SitedException
	    '\'Sited': SitedException
	    getLocalIP:
	       fun {$ unit}   % generate a ticket just to guess our IP
		  case {VirtualString.toString {Connection.offer 7}}
		  of &x|&-|&o|&z|&t|&i|&c|&k|&e|&t|&:|&/|&/|Rest then
		     {ByteString.make
		      {List.takeWhile Rest fun {$ C} C \= &: end}}
		  end
	       end
	    setCallback:
	       fun {$ Callback}
		  {Property.put 'alice.rpc'
		   if {Procedure.arity Callback} == 3 then Callback
		   else fun {$ A B} {Callback A#B} end
		   end}
		  unit
	       end
	    packValue:
	       fun {$ X}
		  try {Pickle.packWithCells X}
		  catch error(dp(generic ...) ...) then
		     {Exception.raiseError alice(SitedException)} unit
		  end
		  %--** should handle pickle:resources for holes
	       end
	    unpackValue: Pickle.unpack)
end
