functor
import
   FD
   FS
   Search
   Inspector
   Select at 'x-ozlib://duchier/cp/Select.ozf'
export
   'Smurf$': SmurfModule
define
   %% Attribute A is one of [b ems i tt u size color]

   InitialAttributes = attributes(b: 1 ems: 1 i: 1 tt: 1 u: 1
				  size: 11 color: 9)

   fun {MkDataItemAttributes Property IsSpace}
      attributes(b: if IsSpace then {FD.int 1#2}
		    elseif Property.b then 2 else 1
		    end
		 ems: if IsSpace then {FD.int 1#3}
		      elseif Property.s then 3
		      elseif Property.em then 2
		      else 1
		      end
		 i: if IsSpace then {FD.int 1#2}
		    elseif Property.i then 2
		    else 1
		    end
		 tt: if IsSpace then {FD.int 1#2}
		     elseif Property.tt then 2
		     else 1
		     end
		 u: Property.u + 1
		 size: case Property.size of ~1 then 11 elseof S then S + 1 end
		 color:
		    if IsSpace then {FD.int 1#11}
		    elsecase Property.color of 'R' then 1
		    [] 'G' then 2
		    [] 'B\'' then 3
		    [] 'C' then 4
		    [] 'M' then 5
		    [] 'Y' then 6
		    [] 'K' then 7
		    [] 'W' then 8
		    [] 'UNKNOWN' then 9
		    end)
   end

   fun {MkElementAttributes}
      attributes(b: {FD.int 1#2}
		 ems: {FD.int 1#3}
		 i: {FD.int 1#2}
		 tt: {FD.int 1#2}
		 u: {FD.int 1#4}
		 size: {FD.int 1#11}
		 color: {FD.int 1#9})
   end

   fun {MkSizeProc I}
      proc {$ A In Out}
	 case A of size then Out = I
	 else Out = In
	 end
      end
   end

   fun {MkColorProc I}
      proc {$ A In Out}
	 case A of color then Out = I
	 else Out = In
	 end
      end
   end

   Tags = tags(0: tag(p: proc {$ _ In Out} Out = In end)   % epsilon
	       1: tag(name: 'B'
		      p: proc {$ A In Out}
			    case A of b then Out = 2
			    else Out = In
			    end
			 end)
	       2: tag(name: 'EM'
		      p: proc {$ A In Out}
			    case A of ems then Out = {Select.fd [2 1 3] In}
			    else Out = In
			    end
			 end)
	       3: tag(name: 'I'
		      p: proc {$ A In Out}
			    case A of i then Out = 2
			    else Out = In
			    end
			 end)
	       4: tag(name: 'PL'
		      p: proc {$ A In Out}
			    case A of b then Out = 1
			    [] em then Out = 1
			    [] i then Out = 1
			    [] tt then Out = 1
			    [] u then Out = 1
			    else Out = In
			    end
			 end)
	       5: tag(name: 'S'
		      p: proc {$ A In Out}
			    case A of em then Out = 3
			    else Out = In
			    end
			 end)
	       6: tag(name: 'TT'
		      p: proc {$ A In Out}
			    case A of tt then Out = 2
			    else Out = In
			    end
			 end)
	       7: tag(name: 'U'
		      p: proc {$ A In Out}
			    case A of u then Out = {FD.max {FD.plus In 1} 4}
			    else Out = In
			    end
			 end)
	       8: tag(name: 'SIZE'(0)
		      p: {MkSizeProc 1})
	       9: tag(name: 'SIZE'(1)
		      p: {MkSizeProc 2})
	       10: tag(name: 'SIZE'(2)
		      p: {MkSizeProc 3})
	       11: tag(name: 'SIZE'(3)
		      p: {MkSizeProc 4})
	       12: tag(name: 'SIZE'(4)
		      p: {MkSizeProc 5})
	       13: tag(name: 'SIZE'(5)
		      p: {MkSizeProc 6})
	       14: tag(name: 'SIZE'(6)
		      p: {MkSizeProc 7})
	       15: tag(name: 'SIZE'(7)
		      p: {MkSizeProc 8})
	       16: tag(name: 'SIZE'(8)
		      p: {MkSizeProc 9})
	       17: tag(name: 'SIZE'(9)
		      p: {MkSizeProc 10})
	       18: tag(name: 'COLOR'('R')
		      p: {MkColorProc 1})
	       19: tag(name: 'COLOR'('G')
		      p: {MkColorProc 2})
	       20: tag(name: 'COLOR'('B\'')
		      p: {MkColorProc 3})
	       21: tag(name: 'COLOR'('C')
		      p: {MkColorProc 4})
	       22: tag(name: 'COLOR'('M')
		      p: {MkColorProc 5})
	       23: tag(name: 'COLOR'('Y')
		      p: {MkColorProc 6})
	       24: tag(name: 'COLOR'('K')
		      p: {MkColorProc 7})
	       25: tag(name: 'COLOR'('W')
		      p: {MkColorProc 8}))

   RootI = 0
   Epsilon = 0
   MaxTag = 25

   fun {Constrain Meaning NumberOfElements}
      NumberOfDataItems = {Length Meaning}
      NumberOfVertices = NumberOfDataItems + NumberOfElements

      %% Root is vertex with number 0
      Root = root(daughters: {FS.var.upperBound 1#NumberOfVertices}
		  scope: {FS.var.upperBound 1#NumberOfDataItems})
      DataItems = {List.mapInd Meaning
		   fun {$ I Text#IsSpace#Property}
		      dataItem(mother: {FD.int 0#NumberOfVertices}
			       daughters: FS.value.empty
			       down: FS.value.empty
			       eqdown: {FS.value.singl I}
			       scope: {FS.value.singl I}
			       attributes:
				  {MkDataItemAttributes Property IsSpace}
			       text: Text)
		   end}
      Elements = for I in 1..NumberOfElements collect: Collect do
		    {Collect
		     element(mother: {FD.int 0#NumberOfVertices}
			     daughters: {FS.var.upperBound 1#NumberOfVertices}
			     down: {FS.var.upperBound 1#NumberOfVertices}
			     eqdown: {FS.var.upperBound 0#NumberOfVertices}
			     scope: {FS.var.upperBound 1#NumberOfDataItems}
			     tag: {FD.int Epsilon#MaxTag}
			     attributes: {MkElementAttributes})}
		 end

      V = {AdjoinAt
	   {List.toTuple vertices {Append DataItems Elements}}
	   RootI Root}

      %% Treeness Constraints
      for I in 1..NumberOfVertices do
	 V.I.mother \=: I
      end

      Eqdowns = for I in 1..NumberOfVertices collect: Collect do
		   {Collect V.I.eqdown}
		end

      for I in 1..NumberOfElements do W in
	 W = V.(NumberOfDataItems + I)
	 {Select.union Eqdowns W.daughters W.down}
	 {FS.exclude I W.down}
	 W.eqdown = {FS.partition [{FS.value.singl NumberOfDataItems + I}
				   W.down]}
      end

      for I in 0..NumberOfVertices do W in
	 W = V.I
	 for I2 in 1..NumberOfVertices do
	    if I2 \= I then W2 in
	       W2 = V.I2
	       (W2.mother =: I) =: {FS.reified.isIn I2 W.daughters}
	    end
	 end
      end

      {FS.disjointN for I in 0..NumberOfVertices collect: Collect do
		       {Collect V.I.daughters}
		    end}

      %% Attribute constraints
      %%--** missing

      %% Scope constraints
      Scopes = for I in 0..NumberOfVertices collect: Collect do
		  {Collect V.I.scope}
	       end

      {FS.int.convex Root.scope}
      {Select.union Scopes Root.daughters Root.scope}
      for I in 1..NumberOfElements do W in
	 W = V.(NumberOfDataItems + I)
	 {FS.int.convex W.scope}
	 {Select.union Scopes W.daughters W.scope}
      end

      %% Unused elements are immediate daughters of the root
      for I in 1..NumberOfElements do W in
	 W = V.(NumberOfDataItems + I)
	 (W.tag =: Epsilon) =: {FS.reified.equal W.scope FS.value.empty}
	 (W.tag =: Epsilon) =<: (W.mother =: RootI)
      end
   in
      V
   end

   local
      fun {ToDocSub Daughters V}
	 {List.foldR {FS.reflect.lowerBoundList Daughters}
	  fun {$ I In}
	     case V.I of dataItem(text: Text ...) then
		'TEXT'(Text)|In
	     [] element(tag: !Epsilon ...) then In
	     [] element(tag: Tag daughters: Daughters ...) then
		'TAGGED'(Tags.Tag.name {ToDocSub Daughters V})|In
	     end
	  end nil}
      end
   in
      fun {ToDoc V}
	 {ToDocSub V.RootI.daughters V}
      end
   end

   fun {Smurf Meaning NumberOfElements}
      {ToDoc {Search.base.one
	      proc {$ V}
		 V = {Constrain {Reverse Meaning} NumberOfElements}
		 {FS.distribute naive
		  for I in 0..{Width V} - 1 collect: Collect do
		     {Collect V.I.daughters}
		  end}
	      end}.1}
   end

   SmurfModule = 'Smurf'(smurf: Smurf)

   SampleProperty = '#'(b: false em: false i: false s: false tt: false
			u: 0 size: ~1 color: 'UNKNOWN')
   SampleMeaning = [[{ByteString.make 'c'}]#false#SampleProperty
		    [{ByteString.make 'b'}]#false#SampleProperty
		    [{ByteString.make 'a'}]#false#SampleProperty]

   {Inspector.inspect {Smurf SampleMeaning 5}}
end
