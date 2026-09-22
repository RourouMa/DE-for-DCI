(* Diagnostic collision residues modulo exact loop/external relabelings.
   These are not extra IBP equations or a complete convergence criterion. *)
Clear[crLoopCount,crEdges,crAssert,crOrbit,crCanonical,crContract,crResidue,crCollect];
crAssert[b_,m_]:=If[!TrueQ[b],Print[m];Abort[]];
crLoopCount[n_Integer]:=Switch[n,5,1,11,2,18,3,26,4,_,crAssert[False,"Unknown family size"]];
crEdges[l_Integer]:=crEdges[l]=Join[Partition[Range[l],2,1],
 Complement[Subsets[Range[l],{2}],Partition[Range[l],2,1]]];
crExternal={{1,2,3,4},{3,2,1,4},{1,4,3,2},{3,4,1,2}};
crOrbit[a_List]:=Module[{l=crLoopCount[Length[a]],edges,parts,b,ids},
 edges=crEdges[l];
 parts=ConnectedComponents[Graph[Range[l],UndirectedEdge@@@Pick[edges,
   (#!=0& /@ a[[4l+Range[Length[edges]]]])]]];
 Union[Flatten[Table[b=a;
   Do[Do[b[[Range[4i-3,4i]]]=a[[4(i-1)+crExternal[[choice[[k]]]]]],{i,parts[[k]]}],{k,Length[parts]}];
   Table[ids=Join[Flatten[Range[4#-3,4#]& /@ perm],
    4l+(First[FirstPosition[edges,Sort[perm[[#]]]]]& /@ edges),4l+Length[edges]+perm];
    b[[ids]],{perm,Permutations[Range[l]]}],{choice,Tuples[Range[4],Length[parts]]}],1]]];
