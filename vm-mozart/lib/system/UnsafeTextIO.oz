%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1999-2001
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

functor
import
   BootName(newUnique: NewUniqueName) at 'x-oz://boot/Name'
   Open(file text)
   Property(get)
   System(printInfo)
export
   'UnsafeTextIO$': TextIO
define
   IoException = {NewUniqueName 'IO.Io'}

   class TextFile from Open.file Open.text end

   ConvertLine ConvertAll
   case {Property.get 'platform.os'} of win32 then
      fun {ConvertLine S}
	 case S of [&\r] then nil
	 [] C|Cr then C|{ConvertLine Cr}
	 [] nil then nil
	 end
      end
      fun {ConvertAll S}
	 case S of &\r|&\n|Rest then &\n|{ConvertAll Rest}
	 [] C|Cr then C|{ConvertAll Cr}
	 [] nil then nil
	 end
      end
   else
      fun {ConvertLine S} S end
      fun {ConvertAll S} S end
   end

   fun {InputAll F}
      {ConvertAll {F read(list: $ size: all)}}
   end

   TextIO =
   'TextIO'(
      'stdIn':
	 {New TextFile init(name: stdin flags: [read])}
      'openIn':
	 fun {$ S}
	    try
	       {New TextFile init(name: S flags: [read])}
	    catch system(E=os(os ...) ...) then
	       {Exception.raiseError
		alice(IoException(name: S
				  function: {ByteString.make 'openIn'}
				  cause: E))}   %--** cause not of type exn
	       unit
	    end
	 end
      'inputAll':
	 fun {$ F} {ByteString.make {InputAll F}} end
      'inputLine':
	 fun {$ F}
	    case {F getS($)} of false then {ByteString.make ""}
	    elseof S then {ByteString.make {ConvertLine S}#'\n'}
	    end
	 end
      'closeIn':
	 fun {$ F} {F close()} unit end
      'stdOut':
	 {New TextFile init(name: stdout flags: [write])}
      'stdErr':
	 {New TextFile init(name: stderr flags: [write])}
      'openOut':
	 fun {$ S}
	    {New TextFile init(name: S flags: [write create truncate])}
	 end
      'output':
	 fun {$ F S} {F write(vs: S)} unit end
      'output1':
	 fun {$ F C} {F write(vs: [C])} unit end
      'flushOut':
	 fun {$ F} /*{F flush()}*/ unit end   %--** not supported for files?
      'closeOut':
	 fun {$ F} {F close()} unit end
      'print':
	 fun {$ X}
	    {System.printInfo X} unit
	 end)
end
