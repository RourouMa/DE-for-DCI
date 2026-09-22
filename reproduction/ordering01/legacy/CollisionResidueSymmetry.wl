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
crCanonical[a_List]:=crCanonical[a]=First[crOrbit[a]];
crContract[g_G,edge_Integer]:=crContract[g,edge]=Module[
 {a=List@@g,l,edges,pair,keep,map,out,lowerEdges,p,q,idx},
 l=crLoopCount[Length[a]];edges=crEdges[l];
 crAssert[MemberQ[4l+Range[Length[edges]],edge] && a[[edge]]===2 &&
  Take[a,-l]===ConstantArray[1,l],"Unsupported collision power or delta indices"];
 pair=edges[[edge-4l]];a[[edge]]-=2;keep=DeleteCases[Range[l],Last[pair]];
 map=First[FirstPosition[keep,#]]& /@ (Range[l]/.Last[pair]->First[pair]);
 lowerEdges=crEdges[l-1];out=Join[ConstantArray[0,4(l-1)+Length[lowerEdges]],ConstantArray[1,l-1]];
 Do[out[[Range[4map[[j]]-3,4map[[j]]]]]+=a[[Range[4j-3,4j]]],{j,l}];
 Do[p=Sort[map[[edges[[j]]]]];q=a[[4l+j]];
  If[First[p]===Last[p],crAssert[q===0,"Unremoved self propagator in collision residue"],
   idx=4(l-1)+First[FirstPosition[lowerEdges,p]];out[[idx]]+=q],{j,Length[edges]}];
 out];
crCollect[e_]:=With[{v=Union[Cases[{e},_ResidueG,Infinity]],a=Expand[e]},
 Total[Together[Coefficient[a,#]] #& /@ v]];
crResidue[e_]:=Module[{gs=Union[Cases[{e},_G,Infinity]],a,l,edges,c},
 crCollect[Total[Table[a=List@@g;l=crLoopCount[Length[a]];
  edges=Select[4l+Range[Length[crEdges[l]]],a[[#]]>=2&];
  crAssert[And@@(a[[#]]===2& /@ edges),"Higher-order pole requires a separate residue analysis"];
  c=Coefficient[Expand[e],g];
  c Total[ResidueG[l-1,crCanonical[crContract[g,#]]]& /@ edges],{g,gs}]]]];
