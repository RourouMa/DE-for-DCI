(* Shared exact-linear helpers for nested G4 DE iterations. *)
itBase=DirectoryName[$InputFileName];
itAuditSource=First[StringSplit[Import[FileNameJoin[{itBase,"IBP4ActualDECombinationAudit.wl"}],"Text"],"dd=FileNameJoin["]];
ToExpression[itAuditSource];Get[FileNameJoin[{itBase,"IBP4LocalSmallBlocks.wl"}]];
itZero[e_]:=TrueQ[Together[e]===0];
itSupport[e_]:=Union[Cases[{e},_G,Infinity]];
itCanon[e_]:=Module[{v=Union[Cases[{e},_G|_G3|_SmallBlock|_ActualFinite,Infinity]],a},
 If[v==={},Return[Together[e]]];a=CoefficientArrays[{e},v];
 If[Length[a]>2,Print["Nonlinear integral expression"];Quit[1]];
 First[Normal[a[[1]]]]+If[Length[a]<2,0,(Together /@ First[Normal[a[[2]]]]).v]];
itCoeff[rows_,vars_]:=Module[{a=CoefficientArrays[rows,vars]},
 If[Length[a]>2,Print["Nonlinear rows"];Quit[1]];
 If[Length[a]<2,ConstantArray[0,{Length[rows],Length[vars]}],Map[Together,Normal[a[[2]]],{2}]]];
itRR[m_]:=Select[RowReduce[m],!And@@(itZero /@ #)&];
itPiv[m_]:=Table[First[Select[Range[Length[row]],!itZero[row[[#]]]&]],{row,m}];
itDiv[g_G]:=Max[(List@@g)[[17;;22]]]>=2;
itFactor[g_G]:=Length[ConnectedComponents[Graph[Range[4],UndirectedEdge@@@Pick[
 {{1,2},{2,3},{3,4},{1,3},{1,4},{2,4}},(#!=0& /@ (List@@g)[[17;;22]])]]]]>1;
itAuditCached[rows_,tag_,dir_]:=Module[{file=FileNameJoin[{dir,tag<>".wl"}],cached},
 If[FileExistsQ[file],cached=Get[file];
  If[Lookup[cached,"InputRowsHash",None]===Hash[rows/._G3->0,"SHA256"] &&
    And@@(itZero /@ Lookup[cached,"rowChecks",{1}]),Print[{tag,"Using verified audit cache"}];Return[cached]]];
 Block[{out=dir},audit[rows,tag]]];
itSolveCoordinates[c_,b_,p_]:=Module[{cd,cb,cr,cols,labels,requests,vars,eqs,sol,values},
 $FiniteFlowLibPath="/Users/april/Packages/finiteflow/install";
 If[!MemberQ[$LibraryPath,$FiniteFlowLibPath],AppendTo[$LibraryPath,$FiniteFlowLibPath]];
 If[!MemberQ[$Path,"/Users/april/Packages/finiteflow/mathlink"],AppendTo[$Path,"/Users/april/Packages/finiteflow/mathlink"]];
 Needs["FiniteFlow`"];
 cols=Array[cd,Length[First[b]]];labels=Array[cb,Length[b]];requests=Array[cr,Length[c]];
 vars=Join[requests,cols[[p]],cols[[Complement[Range[Length[cols]],p]]],labels];
 eqs=Join[b.cols-labels,requests-c.cols];
 sol=FiniteFlow`FFSparseSolve[#==0& /@ eqs,vars,"NeededVars"->requests,"SparseOutput"->True,"MaxPrimes"->50];
 If[!ListQ[sol] || !FreeQ[sol,$Failed],Print["Basis-coordinate solve failed"];Quit[1]];
 values=requests/.Dispatch[sol];
 If[!FreeQ[values,Alternatives@@Join[cols,requests]],Print["Chosen basis does not span requested rows"];Quit[1]];
 Map[Together,Normal[CoefficientArrays[values,labels][[2]]],{2}]];
itDX[g_G]:=itDX[g]=DEexpr[g,DOperatorx,Propagators4];
itDY[g_G]:=itDY[g]=DEexpr[g,DOperatory,Propagators4];
itDifferentiate[e_,axis_]:=Module[{gs=itSupport[e],c,dc,dg},
 c=First[itCoeff[{e},gs]];dc=D[c,axis];dg=If[axis===x,itDX /@ gs,itDY /@ gs];
 itCanon[dc.gs+c.dg]];
itDerivatives[pkg_,dir_]:=Module[{raw=pkg["InputExpanded"],dx,dy,t,summary,n=Length[pkg["Basis"]]},
 If[!DirectoryQ[dir],CreateDirectory[dir,CreateIntermediateDirectories->True]];
 Put[pkg,FileNameJoin[{dir,"InputBasis.wl"}]];
 dx=MapIndexed[If[Mod[First[#2],50]==0,Print[{"Dx",First[#2],n}]];itDifferentiate[#1,x]&,raw];
 dy=MapIndexed[If[Mod[First[#2],50]==0,Print[{"Dy",First[#2],n}]];itDifferentiate[#1,y]&,raw];
 t=itSupport[{dx,dy}];
 If[!FreeQ[{dx,dy},_sp|_d|_v] || Max[Flatten[(List@@@t)[[All,17;;22]]]]>2,Print["Invalid derivative target"];Quit[1]];
 Put[dx,FileNameJoin[{dir,"Dx.wl"}]];Put[dy,FileNameJoin[{dir,"Dy.wl"}]];
 Put[t,FileNameJoin[{dir,"Targets.wl"}]];
 summary=<|"InputCount"->n,"DerivativeRows"->2 n,"Targets"->Length[t],"RawInputG4"->Length[itSupport[raw]],
 "MinimumTargetIndex"->Min[List@@@t],"TargetLoopLoopPatterns"->Counts[(List@@#)[[17;;19]]& /@ t]|>;
 Put[summary,FileNameJoin[{dir,"DerivativeSummary.wl"}]];Print[summary//InputForm];
 <|"Dx"->dx,"Dy"->dy,"Targets"->t,"Summary"->summary|>];

itBuildBasis[pkg_,fullDE_,dr_,tag_,dir_,reusePkg_:None]:=Module[
 {n=Length[pkg["Basis"]],fullInput,input,de=fullDE,gs,ci,cd,order,ri,p,closureResidual,cl,a,ai,sourceExpr,splits,
  splitDefs,mapping,safe,bare,pool,poolRaw,vars,cp,poolIDs,cm,chosen,labels,original,workingRows,weights,exact,
  added,allDefs,defs,nestedLabels,nestedDefs,nestedIDs,fullWorking,g3Direct,g3Basis,sources,fullCheck,
  independent,summary,rawDE,singleLabels,oldDefs=pkg["Definitions"],bundle,g4Only=TrueQ[$IBP4G4OnlyReduction],sourceStatus,
  poolOriginal,reusing=AssociationQ[reusePkg],active,candidateOrder,factorCandidates,
  factorFirst=TrueQ[$IBP4FactorizedFirstBasis]},
 If[!DirectoryQ[dir],CreateDirectory[dir,CreateIntermediateDirectories->True]];
 fullInput=itCanon[#/.dr]& /@ pkg["InputExpanded"];input=fullInput/._G3->0;
 Put[de,FileNameJoin[{dir,If[g4Only,"ReducedDEG4.wl","ReducedDEIncludingG3.wl"]}]];
 Put[fullInput,FileNameJoin[{dir,If[g4Only,"ReducedInputsG4.wl","ReducedInputsIncludingG3.wl"]}]];
 gs=Union[itSupport[input],itSupport[de]];ci=itCoeff[input,gs];cd=itCoeff[de/._G3->0,gs];
 order=SortBy[Range[Length[gs]],{Count[ci[[All,#]],Except[0]]&,LeafCount[ci[[All,#]]]&,Identity}];
 gs=gs[[order]];ci=ci[[All,order]];cd=cd[[All,order]];ri=itRR[ci];p=itPiv[ri];
 closureResidual=Map[Together,cd-cd[[All,p]].ri,{2}];
 cl=<|"InputRank"->Length[ri],"Closed"->And@@Flatten[Map[itZero,closureResidual,{2}]],
  "NonclosedRows"->Select[Range[2 n],!And@@(itZero /@ closureResidual[[#]])&],"Variables"->gs,"Residual"->closureResidual|>;
 Put[cl,FileNameJoin[{dir,"Closure.wl"}]];
 Print[{tag,"InputRank",Length[ri],"NonclosedRows",Length[cl["NonclosedRows"]]}//InputForm];
 Print[{tag,"Auditing actual coefficient combinations"}//InputForm];
 a=itAuditCached[de,tag<>"_DE",dir];ai=itAuditCached[input,tag<>"_Input",dir];
 If[reusing,
 pool=reusePkg["Basis"];poolOriginal=reusePkg["InputExpanded"];splitDefs=reusePkg["Definitions"];
 poolRaw=(itCanon[#/.dr]/._G3->0)& /@ poolOriginal;
 Put[<|"ReusedBasis"->pool,"Definitions"->splitDefs|>,FileNameJoin[{dir,"ReusedPool.wl"}]],
 sourceExpr=Join[Last /@ a["definitions"],Last /@ ai["definitions"]];
 splits=If[sourceExpr==={},<|"definitions"->{},"originalInSmallBlocks"->{}|>,LocalSmallBlocks[sourceExpr,tag]];
 Put[splits,FileNameJoin[{dir,"LocalSplits.wl"}]];splitDefs=splits["definitions"];
 mapping=Dispatch[Thread[Join[First /@ a["definitions"],First /@ ai["definitions"]]->splits["originalInSmallBlocks"]]];
 safe=Union[a["singleFinite"],ai["singleFinite"]];
 bare=Select[itSupport[{a["rewrittenDE"],ai["rewrittenDE"]}/.mapping],itDiv];
 pool=Join[safe,First /@ splitDefs,bare];poolRaw=pool/.Dispatch[splitDefs];poolOriginal=poolRaw];
 vars=Union[itSupport[poolRaw],itSupport[input],itSupport[de]];cp=itCoeff[poolRaw,vars];
 Print[{tag,"Selecting independent local blocks",Dimensions[cp]}//InputForm];
 poolIDs=itPiv[itRR[Transpose[cp]]];pool=pool[[poolIDs]];poolRaw=poolRaw[[poolIDs]];poolOriginal=poolOriginal[[poolIDs]];
 cm=itCoeff[Join[input,poolRaw],vars];
 labels=Join[pkg["Basis"],pool];original=Join[pkg["InputExpanded"],poolOriginal];
 candidateOrder=Range[Length[labels]];
 If[factorFirst,
  factorCandidates=Select[candidateOrder,MatchQ[labels[[#]],_G] && itFactor[labels[[#]]]&];
  candidateOrder=Join[factorCandidates,Complement[candidateOrder,factorCandidates]]];
 chosen=candidateOrder[[itPiv[itRR[Transpose[cm[[candidateOrder]]]]]]];
 workingRows=cm[[chosen]];
 Print[{tag,"Selected working basis",Length[chosen]}//InputForm];
 p=itPiv[itRR[workingRows]];
 weights=If[Environment["IBP4_AUDIT_FINITEFLOW"]==="1",
  itSolveCoordinates[itCoeff[Join[input,de/._G3->0],vars],workingRows,p],
  Map[Together,itCoeff[Join[input,de/._G3->0],vars][[All,p]].Inverse[workingRows[[All,p]]],{2}]];
 exact=And@@Flatten[Map[itZero,Normal[SparseArray[weights].SparseArray[workingRows]]-itCoeff[Join[input,de/._G3->0],vars],{2}]];
 If[!exact,Print["G4 basis reconstruction failed"];Quit[1]];
 active=Select[Range[Length[chosen]],!And@@(itZero /@ weights[[All,#]])&];
 chosen=chosen[[active]];workingRows=workingRows[[active]];weights=weights[[All,active]];
 added=Select[chosen,#>n&];allDefs=DeleteDuplicates[Join[oldDefs,splitDefs]];
 defs=Select[allDefs,MemberQ[labels[[chosen]],First[#]]&];
 nestedLabels=Join[pkg["Basis"],labels[[added]]];nestedDefs=Select[allDefs,MemberQ[nestedLabels,First[#]]&];
 nestedIDs=Join[Range[n],added];
 Print[{tag,"G4 reconstruction passed",If[g4Only,"G3 sources not computed","projecting legacy G3 sources"]}//InputForm];
 fullWorking=itCanon[#/.dr]& /@ original[[chosen]];
 (* Project the lower-loop source before multiplication, keeping its rational structure. *)
 fullCheck=And@@Flatten[Map[itZero,itCoeff[fullWorking/._G3->0,vars]-workingRows,{2}]];
 fullCheck=fullCheck && And@@(TrueQ[(#/.{_G->0,_G3->0})===0]& /@ Join[fullInput,de,fullWorking]);
 g3Direct=Join[fullInput,de]/._G->0;g3Basis=fullWorking/._G->0;
 sources=g3Direct-weights.g3Basis;
 fullCheck=fullCheck && FreeQ[sources,_G];
 If[!fullCheck,Print["Full source projection failed"];Quit[1]];
 sourceStatus=If[g4Only,"Not computed: G4 quotient only",
  "Algebraic legacy-system sources only; physical sources require regeneration after the DropY2 mapping fix"];
 rawDE=itSupport[de];singleLabels=Select[labels[[chosen]],MatchQ[#,_G] && !itDiv[#]&];
 summary=<|"InputCount"->n,"InputRankAfterReduction"->Length[ri],"ClosedOnInput"->cl["Closed"],
  "NonclosedRows"->Length[cl["NonclosedRows"]],"RawDEG4"->Length[rawDE],
  "RawDEDivergent"->Count[rawDE,g_G/;itDiv[g]],"RawDEFactorized"->Count[rawDE,g_G/;itFactor[g]],
  "IndependentCount"->Length[chosen],"SingleFinite"->Length[singleLabels],
  "FiniteCombinations"->Length[defs],"BareDivergent"->Count[labels[[chosen]],g_G/;itDiv[g]],
  "FactorizedStandalone"->Count[singleLabels,g_G/;itFactor[g]],
  "NestedCount"->Length[nestedLabels],"NestedRank"->Length[chosen],"AddedDirections"->Length[added],
  "RetainedInputPositions"->Select[chosen,#<=n&],"OmittedInputPositions"->Complement[Range[n],chosen],
  "G4Reconstruction"->exact,"FullSourceProjection"->If[g4Only,Missing["NotComputed"],fullCheck],
  "G4QuotientOnly"->g4Only,"G3SourceStatus"->sourceStatus,"ReusedKnownFinitePool"->reusing,
  "FactorizedFirstBasisSelection"->factorFirst,
  "FinitenessStatus"->"Local zero-sum candidates; no independent pole proof"|>;
 independent=<|"Basis"->labels[[chosen]],"Definitions"->defs,"InputExpanded"->original[[chosen]],
  "ReducedG4Rows"->workingRows.vars,"SingleFinite"->singleLabels,
  "BareDivergent"->Select[labels[[chosen]],MatchQ[#,_G] && itDiv[#]&],"Summary"->summary|>;
 Put[independent,FileNameJoin[{dir,"IndependentBasis.wl"}]];
 Put[<|"Basis"->nestedLabels,"Definitions"->nestedDefs,
  "IndependentPositions"->(First[FirstPosition[nestedIDs,#]]& /@ chosen),"Summary"->summary|>,FileNameJoin[{dir,"NestedBasis.wl"}]];
 Put[<|"InputBasis"->pkg["Basis"],"OutputBasis"->independent["Basis"],"InputInOutputBasis"->Take[weights,n],
  "Ax"->Take[Drop[weights,n],n],"Ay"->Drop[weights,2 n],"InputG3Sources"->If[g4Only,Missing["NotComputed"],Take[sources,n]],
  "G3SourceRows"->If[g4Only,Missing["NotComputed"],Drop[sources,n]],"G3SourceForm"->sourceStatus,
  "G4Reconstruction"->exact,"FullSourceProjection"->If[g4Only,Missing["NotComputed"],fullCheck]|>,FileNameJoin[{dir,"Matrices.wl"}]];
 Put[summary,FileNameJoin[{dir,"Summary.wl"}]];Print[summary//InputForm];independent];
