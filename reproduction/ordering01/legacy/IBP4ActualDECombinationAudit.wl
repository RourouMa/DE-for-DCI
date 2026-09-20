base = DirectoryName[$InputFileName];
out = FileNameJoin[{base,"IBP4_actual_DE_combinations"}];
If[!DirectoryQ[out],CreateDirectory[out]];
z[e_] := TrueQ[Together[e]===0];
audit[rows0_,tag_] := Module[{rows,ints,div,safe,c,eligible,order,e={},p={},selected={},b={},v,pivot,scale,w,res,defs,rew,checks,report,text,steps=0,
 ffMode=Environment["IBP4_AUDIT_FINITEFLOW"]==="1",ffD,ffB,ffR,ffCols,ffBases,ffRows,ffVars,ffEqs,ffSol,ffValues,ffCoefficients,coefficientCheck},
 rows=# /. _G3->0& /@ rows0;
 ints=Union[Cases[rows,_G,Infinity]];
 div=Select[ints,Max[(List@@#)[[{17,18,19}]]]>=2&];safe=Complement[ints,div];
 c=If[div==={},ConstantArray[0,{Length[rows],0}],
  Map[Together,Normal[CoefficientArrays[rows,div][[2]]],{2}]];
 eligible=Select[Range[Length[rows]],z[Total[c[[#]]]] && !And@@(z /@ c[[#]])&];
 order=SortBy[eligible,{Count[c[[#]],a_/;!z[a]]&,LeafCount[c[[#]]]&}];
 Print[{tag,"Eligible zero-sum rows",Length[order],"Divergent columns",Length[div]}//InputForm];
 Do[v=c[[i]];scale=First[Select[v,!z[#]&]];v=Together /@ (v/scale);
  Do[If[v[[p[[j]]]]=!=0,v=Together /@ (v-v[[p[[j]]]] e[[j]])],{j,Length[e]}];
  If[!And@@(z /@ v),pivot=First[Select[Range[Length[div]],!z[v[[#]]]&]];
   AppendTo[p,pivot];AppendTo[e,Together /@ (v/v[[pivot]])];AppendTo[selected,i];AppendTo[b,Together /@ (c[[i]]/scale)]];
  steps++;If[Mod[steps,50]==0,Print[{tag,"Rows examined",steps,"Selected",Length[b]}//InputForm]],{i,order}];
 Print[{tag,"Exact coordinate solve",Length[b]}//InputForm];
 If[ffMode && b=!={},
  $FiniteFlowLibPath="/Users/april/Packages/finiteflow/install";
  If[!MemberQ[$LibraryPath,$FiniteFlowLibPath],AppendTo[$LibraryPath,$FiniteFlowLibPath]];
  If[!MemberQ[$Path,"/Users/april/Packages/finiteflow/mathlink"],AppendTo[$Path,"/Users/april/Packages/finiteflow/mathlink"]];
  Needs["FiniteFlow`"];
  ffCols=Array[ffD,Length[div]];ffBases=Array[ffB,Length[b]];ffRows=Array[ffR,Length[rows]];
  ffVars=Join[ffRows,ffCols[[p]],ffCols[[Complement[Range[Length[div]],p]]],ffBases];
  ffEqs=Join[b.ffCols-ffBases,ffRows-c.ffCols];
  ffSol=FiniteFlow`FFSparseSolve[#==0& /@ ffEqs,ffVars,"NeededVars"->ffRows,"SparseOutput"->True,"MaxPrimes"->50];
  If[!ListQ[ffSol] || !FreeQ[ffSol,$Failed],Print["FiniteFlow coordinate solve failed"];Abort[]];
  ffValues=ffRows/.Dispatch[ffSol];
  If[!FreeQ[ffValues,Alternatives@@ffRows],Print["Unresolved coordinate rows"];Abort[]];
  ffCoefficients=Map[Together,Normal[CoefficientArrays[ffValues,Join[ffBases,ffCols]][[2]]],{2}];
  w=ffCoefficients[[All,;;Length[b]]];res=ffCoefficients[[All,Length[b]+1;;]];
  coefficientCheck=Map[Together,c-Normal[SparseArray[w].SparseArray[b]]-res,{2}];
  If[!And@@Flatten[Map[z,coefficientCheck,{2}]],Print["Exact coordinate verification failed"];Abort[]],
 w=If[b==={},ConstantArray[{},Length[rows]],Map[Together,c[[All,p]].Inverse[b[[All,p]]],{2}]];
 res=If[b==={},c,Map[Together,c-w.b,{2}]]];
 defs=MapIndexed[ActualFinite[tag,First[#2]] -> (#1.div)&,b];
 rew=Table[(rows[[i]] /. Dispatch[Thread[div->0]])+w[[i]].(First /@ defs)+res[[i]].div,{i,Length[rows]}];
 Print[{tag,"Exact reconstruction check"}//InputForm];
 checks=If[ffMode && b=!={},If[And@@(z /@ #),0,1]& /@ coefficientCheck,
  Together /@ ((rew /. Dispatch[defs])-rows)];
 If[!And@@(z /@ checks),Print["Reconstruction failed"];Abort[]];
 report=<|"InputRowsHash"->Hash[rows,"SHA256"],"sourceRows"->selected,"coefficientField"->"Q(x,y)","singleFinite"->safe,"rawDivergent"->div,"definitions"->defs,"basisCoefficientRows"->b,"weights"->w,"residualCoefficients"->res,"allDERowsCovered"->And@@Flatten[Map[z,res,{2}]],"rowChecks"->checks,"rewrittenDE"->rew,"inputDERowCount"->Length[rows],"allZeroSumCandidateRows"->eligible,"finitenessStatus"->"DE-supported candidates; no independent pole analysis"|>;
 Put[report,FileNameJoin[{out,tag<>".wl"}]];
 text={"# "<>tag,"","Combinations are normalized divergent parts of actual DE rows, selected for linear independence over Q(x,y). No arbitrary common-pivot differences are declared finite. Coefficient zero-sum and exact DE coverage are algebraic evidence, not an independent convergence proof.","", "Single finite: "<>ToString[Length[safe]]<>"; divergent symbols: "<>ToString[Length[div]]<>"; selected combinations: "<>ToString[Length[b]]<>"; all DE rows covered: "<>ToString[report["allDERowsCovered"]],"", "Source row indices: "<>ToString[selected,InputForm],"", "## Single finite","```wolfram"};
 text=Join[text,ToString[#,InputForm]& /@ safe,{"```","","## Actual-DE combinations","```wolfram"},ToString[#,InputForm]& /@ defs,{"```","","Coefficients depending on x,y must also be differentiated in the next iteration (product rule). The accompanying .wl stores coefficient matrices, coverage weights and exact reconstruction residuals."}];
 Export[FileNameJoin[{out,tag<>".md"}],StringRiffle[text,"\n"],"Text"];
 Print[{tag,"single",Length[safe],"rawDiv",Length[div],"combinations",Length[b],"covered",report["allDERowsCovered"],"sourceRows",selected}//InputForm];report
];
dd=FileNameJoin[{base,"IBP4_ladder_rotated_top_derivative_finite4_de_targets"}];
rr=Get[FileNameJoin[{base,"IBP4_ladder_rotated_top_derivative_finite4_targeted_residual_reduction","IBP4ReductionRules.txt"}]];
rows=Join[Get[FileNameJoin[{dd,"IBP4DxTopDerivativeFinite4Basis.txt"}]],Get[FileNameJoin[{dd,"IBP4DyTopDerivativeFinite4Basis.txt"}]]] /. Dispatch[rr];
audit[rows,"SECOND_ROUND_ACTUAL_DE"];
audit[Get[FileNameJoin[{base,"IBP4_finite16_de_results","ReducedDEIncludingG3.wl"}]],"FORMER16_DIAGNOSTIC"];
Quit[];
