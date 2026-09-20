Clear[SmallBlock];
sbZero[e_]:=TrueQ[Together[e]===0];
LocalSmallBlocks[expressions_,tag_,preferredExpressions_:{}] := Module[
 {ints,c,atoms={},den,polys,exps,w,active,known,flows={},allEdges={},remaining,pos,neg,choices,chosen,amount,edge,sgn,monomial,orderedAtoms,uniqueEdges,orderedEdges,forest={},parent,root,b,rr,pivots,weights,res,defs,rebuilt,report,preferredEdges},
 ints=Union[Cases[expressions,_G,Infinity]];
 c=Map[Together,Normal[CoefficientArrays[expressions,ints][[2]]],{2}];
 Do[
  den=Apply[PolynomialLCM,Denominator /@ c[[r]]];
  polys=Expand[Together[den #]]& /@ c[[r]];
  If[!And@@(PolynomialQ[#,{x,y}]& /@ polys),Print["Nonpolynomial coefficient atoms"];Abort[]];
  exps=Union[Flatten[(First /@ CoefficientRules[#,{x,y}]& /@ polys),1]];
  Do[w=Coefficient[Coefficient[#,x,pow[[1]]],y,pow[[2]]]& /@ polys;
   If[!And@@(NumberQ /@ w) || !sbZero[Total[w]],Print["Nonzero-sum coefficient atom: ",{r,pow}];Abort[]];
   active=Select[Range[Length[ints]],w[[#]]!=0&];
   If[active=!={},AppendTo[atoms,<|"source"->r,"monomial"->pow,"denominator"->den,"weights"->w,"support"->active|>]],{pow,exps}],{r,Length[expressions]}];
 known=Union[Sort[# ["support"]]& /@ Select[atoms,Length[#["support"]]==2&]];
 orderedAtoms=SortBy[atoms,{Length[#["support"]]&,#["source"]&,#["monomial"]&}];
 Do[remaining=atom["weights"];monomial=x^atom["monomial"][[1]] y^atom["monomial"][[2]]/atom["denominator"];
  While[AnyTrue[remaining,Positive],
   pos=Select[Range[Length[ints]],remaining[[#]]>0&];neg=Select[Range[Length[ints]],remaining[[#]]<0&];
   choices=Tuples[{pos,neg}];
   chosen=First[SortBy[choices,{If[MemberQ[known,Sort[#]],0,1]&,If[remaining[[#[[1]]]] == -remaining[[#[[2]]]],0,1]&,Total[Abs[(List@@ints[[#[[1]]]])-(List@@ints[[#[[2]]]])]]&,Identity}]];
   amount=Min[remaining[[chosen[[1]]]],-remaining[[chosen[[2]]]]];edge=Sort[chosen];sgn=If[chosen===edge,1,-1];
   AppendTo[flows,<|"source"->atom["source"],"monomial"->atom["monomial"],"edge"->edge,"coefficient"->Together[sgn amount monomial]|>];
   AppendTo[allEdges,edge];known=Union[Append[known,edge]];
   remaining[[chosen[[1]]]]-=amount;remaining[[chosen[[2]]]]+=amount;
  ],{atom,orderedAtoms}];
 uniqueEdges=Union[allEdges];
 (* Old pairs are included among the sources and kept before choosing new edges. *)
 preferredEdges=Table[active=Flatten[Position[ints,#]& /@ Union[Cases[e,_G,Infinity]]];
  If[Length[active]!=2 || !sbZero[Total[Coefficient[Expand[e],#]& /@ ints]],
   Print["Invalid preferred pair: ",e];Abort[]];Sort[active],{e,preferredExpressions}];
 If[!And@@(MemberQ[uniqueEdges,#]& /@ preferredEdges),Print["Preferred pair missing from local sources"];Abort[]];
 orderedEdges=SortBy[uniqueEdges,{-Count[allEdges,#]&,Total[Abs[(List@@ints[[#[[1]]]])-(List@@ints[[#[[2]]]])]]&,Identity}];
 orderedEdges=Join[DeleteDuplicates[preferredEdges],Select[orderedEdges,!MemberQ[preferredEdges,#]&]];
 parent=Range[Length[ints]];root[i_]:=If[parent[[i]]==i,i,root[parent[[i]]]];
 Do[If[root[ed[[1]]]!=root[ed[[2]]],AppendTo[forest,ed];parent[[root[ed[[1]]]]]=root[ed[[2]]]],{ed,orderedEdges}];
 If[!And@@(MemberQ[forest,#]& /@ preferredEdges),Print["Preferred pairs are linearly dependent"];Abort[]];
 b=Table[ReplacePart[ConstantArray[0,Length[ints]],{ed[[1]]->1,ed[[2]]->-1}],{ed,forest}];
 rr=RowReduce[b];pivots=Table[First[Select[Range[Length[row]],row[[#]]!=0&]],{row,rr}];
 weights=Map[Together,c[[All,pivots]].Inverse[b[[All,pivots]]],{2}];res=Map[Together,c-weights.b,{2}];
 If[!And@@Flatten[Map[sbZero,res,{2}]],Print["Small-block span failed"];Abort[]];
 defs=MapIndexed[SmallBlock[tag,First[#2]] -> (#1.ints)&,b];
 rebuilt=weights.(First /@ defs);
 If[!And@@(sbZero /@ ((rebuilt /. Dispatch[defs])-expressions)),Print["Small-block reconstruction failed"];Abort[]];
 report=<|"integrals"->ints,"originalExpressions"->expressions,"coefficientMatrix"->c,"localAtoms"->atoms,"localSplits"->flows,"allObservedPairEdges"->uniqueEdges,"retainedPairEdges"->forest,"definitions"->defs,"pairCoefficientRows"->b,"originalInSmallBlocks"->rebuilt,"weights"->weights,"exactReconstruction"->True,"finitenessStatus"->"User-requested local zero-sum splitting heuristic; no independent pole proof"|>;
 Print[{tag,"sourceCombinations",Length[expressions],"rawIntegrals",Length[ints],"observedPairs",Length[uniqueEdges],"independentSmallPairs",Length[forest]}//InputForm];report
];
