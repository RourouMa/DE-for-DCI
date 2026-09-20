(* Optional full canonical solve. FiniteFlow must be built for the host platform. *)
hHome=DirectoryName[$InputFileName];hData=Environment["DCI_SNAPSHOT_DATA"];
If[!StringQ[hData] || hData==="",hData=FileNameJoin[{hHome,"data"}]];
hWork=Environment["DCI_SOLVE_OUT"];
If[!StringQ[hWork] || hWork==="",hWork=FileNameJoin[{hHome,"work","solve"}]];
If[DirectoryQ[hWork],Print["Use a new DCI_SOLVE_OUT directory"];Quit[1]];
hLib=Environment["FINITEFLOW_LIBRARY_PATH"];hMath=Environment["FINITEFLOW_MATHLINK_PATH"];
If[!StringQ[hLib] || !DirectoryQ[hLib] || !StringQ[hMath] || !DirectoryQ[hMath],
 Print["Set FINITEFLOW_LIBRARY_PATH and FINITEFLOW_MATHLINK_PATH"];Quit[1]];
$FiniteFlowLibPath=hLib;AppendTo[$LibraryPath,hLib];AppendTo[$Path,hMath];Needs["FiniteFlow`"];
hGet[name_]:=Get[FileNameJoin[{hData,"matrix",name}]];
hOrder=hGet["ColumnOrder.wl"];hNeed=hGet["SolverQueries.wl"];
hRows=DeleteCases[DeleteDuplicates[Join[hGet["BaseEquationsWithSymmetry.wl"]/._G3->0,
 hGet["CanonicalAddedEquations.wl"]]],0];
Print[{"Rows",Length[hRows],"Columns",Length[hOrder],"Queries",Length[hNeed]}];
If[Length[hRows]=!=2833280 || Length[hOrder]=!=2850483,Print["Matrix count mismatch"];Quit[1]];
CreateDirectory[hWork,CreateIntermediateDirectories->True];
hSeconds=First[AbsoluteTiming[hSol=FiniteFlow`FFSparseSolve[#==0& /@ hRows,hOrder,
 "NeededVars"->hNeed,"SparseOutput"->True,"MaxPrimes"->80]]];
If[!ListQ[hSol] || !And@@(MatchQ[#,_Rule]& /@ hSol),Print["Solve failed"];Quit[1]];
hCanonical=Thread[hNeed->(hNeed/.Dispatch[hSol])];
hExpected=Dispatch[hGet["CanonicalReductionRules.wl"]];
hResidual=Together /@ ((hNeed/.Dispatch[hCanonical])-(hNeed/.hExpected));
hExact=And@@(#===0& /@ hResidual);
Put[hCanonical,FileNameJoin[{hWork,"CanonicalReductionRules.wl"}]];
hMap=hGet["QueryMap.wl"];
hRules=Thread[(First /@ hMap)->(Expand /@ ((Last /@ hMap)/.Dispatch[hCanonical]))];
Put[hRules,FileNameJoin[{hWork,"IBP4ReductionRules.txt"}]];
Put[<|"Seconds"->hSeconds,"Rows"->Length[hRows],"Columns"->Length[hOrder],
 "ExactCanonicalRulesMatch"->hExact,"G4QuotientOnly"->True|>,FileNameJoin[{hWork,"Verification.wl"}]];
Print[{"ExactCanonicalRulesMatch",hExact}];Quit[If[hExact,0,1]];
