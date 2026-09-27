package=DirectoryName[DirectoryName[$InputFileName]];
neat=Environment["NEATIBP_ROOT"];ff=Environment["FINITEFLOW_ROOT"];spasm=Environment["SPASM_LIBRARY"];
If[!StringQ[neat]||!DirectoryQ[neat]||!StringQ[ff]||!DirectoryQ[ff],Print["Optional test requires NEATIBP_ROOT and FINITEFLOW_ROOT."];Quit[77]];
Get[FileNameJoin[{package,"Kernel","ConformalIBP.wl"}]];
SparseRREF`SpaSMLibrary=If[StringQ[spasm],spasm,"/usr/local/lib/libspasm.so"];
Get[FileNameJoin[{neat,"SparseRREF","SparseRREF.m"}]];
Get[FileNameJoin[{package,"Adapters","NeatIBPRowSelection.wl"}]];
If[!TrueQ[InitializeFiniteFlow[ff,FileNameJoin[{ff,"mathlink"}]]],Quit[2]];
FiniteFlow`FFNThreads=2;
(* Synthetic linear identities in a four-loop column and retained source
   columns. These are solver tests, not generated physical IBP equations. *)
g=G@@ConstantArray[1,26];b1=BoundaryIntegral[1,{1,1,1,1,1}];b2=BoundaryIntegral[1,{2,0,2,0,1}];
cols={g,b1,b2};eq={g-b1,b1-x b2};
normal=ConformalIBPNeatSelection`NeatTargetSolve[eq,cols,{g}];
known=ConformalIBPNeatSelection`NeatTargetSolve[eq,cols,{g},"InputRowsIndependent"->True];
free=ConformalIBPNeatSelection`NeatTargetSolve[eq,cols,{b2}];
empty=ConformalIBPNeatSelection`NeatTargetSolve[{},cols,{g}];
zero=ConformalIBPNeatSelection`NeatTargetSolve[{0,0},cols,{g}];
bad=Block[{ConformalIBPNeatSelection`SelectSparseTargetRows=Function[Null,<|"Rows"->{}|>,HoldAll]},
 ConformalIBPNeatSelection`NeatTargetSolve[eq,cols,{g}]];
tests=<|"SourceConstraint"->(normal["ReducedTargets"]==={x b2}),
 "KnownIndependentInput"->(known["ReducedTargets"]==={x b2}),
 "ReferenceIncludesFreeImages"->MemberQ[normal["CheckedColumns"],b2],
 "FullSystemCheck"->TrueQ[normal["FullPoolTargetAgreement"]],
 "FreeTarget"->(free["ReducedTargets"]==={b2}),"EmptySystem"->(empty["ReducedTargets"]==={g}),
 "ZeroSystem"->(zero["ReducedTargets"]==={g}),
 "WrongSelectionRejected"->(FailureQ[bad]&&bad[[1]]==="FullPoolTargetMismatch")|>;
Print[tests];Quit[If[And@@Values[tests],0,3]];
