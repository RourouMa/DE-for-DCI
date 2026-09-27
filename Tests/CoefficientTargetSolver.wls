package=DirectoryName[DirectoryName[$InputFileName]];ff=Environment["FINITEFLOW_ROOT"];
If[!StringQ[ff]||!DirectoryQ[ff],Print["Optional test requires FINITEFLOW_ROOT."];Quit[77]];
Get[FileNameJoin[{package,"Kernel","ConformalIBP.wl"}]];
Get[FileNameJoin[{package,"Adapters","NeatIBPRowSelection.wl"}]];
If[!TrueQ[InitializeFiniteFlow[ff,FileNameJoin[{ff,"mathlink"}]]],Quit[2]];
FiniteFlow`FFNThreads=1;
g=G@@ConstantArray[1,26];b1=BoundaryIntegral[1,{1,1,1,1,1}];b2=BoundaryIntegral[1,{2,0,2,0,1}];
cols={g,b1,b2};eq={g-b1,b1-x b2};
normal=ConformalIBPNeatSelection`NeatTargetSolve[eq,cols,{g},"SelectionMethod"->"CoefficientDAG"];
free=ConformalIBPNeatSelection`NeatTargetSolve[eq,cols,{b2},"SelectionMethod"->"CoefficientDAG"];
wrong=Block[{ConformalIBPNeatSelection`SelectCoefficientTargetRows=Function[Null,<|"Rows"->{}|>,HoldAll]},
 ConformalIBPNeatSelection`NeatTargetSolve[eq,cols,{g},"SelectionMethod"->"CoefficientDAG"]];
dependent=ConformalIBPNeatSelection`SelectCoefficientTargetRows[SparseArray[{{1,2},{2,4}}],{1},101,"InputRowsIndependent"->True];
aggregate=ConformalIBPNeatSelection`NeatTargetSolve[eq,cols,{g},"SelectionMethod"->"AggregateCoefficientDAG"];
g2=G@@ReplacePart[ConstantArray[1,26],1->2];
cancellation=ConformalIBPNeatSelection`NeatTargetSolve[{g+g2,g2+x b2},{g,g2,b2},{g,g2},
 "SelectionMethod"->"AggregateCoefficientDAG","SelectionPrime"->2];
If[!FailureQ[cancellation]||cancellation[[1]]=!= "FullPoolTargetMismatch",Print["Cancellation fixture result: ",cancellation]];
constant=ConformalIBPNeatSelection`NeatTargetSolve[{g-b1,b1-3 b2},cols,{g},"SelectionMethod"->"AggregateCoefficientDAG"];
constantCancellation=ConformalIBPNeatSelection`NeatTargetSolve[{g+g2,g2+b2},{g,g2,b2},{g,g2},
 "SelectionMethod"->"AggregateCoefficientDAG","SelectionPrime"->2];
tests=<|"SourceConstraint"->(normal["ReducedTargets"]==={x b2}),
 "FullPoolCheck"->TrueQ[normal["FullPoolTargetAgreement"]],
 "FreeImagesChecked"->MemberQ[normal["CheckedColumns"],b2],
 "FreeTarget"->(free["ReducedTargets"]==={b2}),
 "WrongSelectionRejected"->(FailureQ[wrong]&&wrong[[1]]==="FullPoolTargetMismatch"),
 "FalseIndependenceRejected"->(FailureQ[dependent]&&dependent[[1]]==="CoefficientSelectorRankMismatch"),
 "AggregateSourceConstraint"->(aggregate["ReducedTargets"]==={x b2}),
 "AggregateFullPoolCheck"->TrueQ[aggregate["FullPoolTargetAgreement"]],
 "AggregateCancellationRejected"->(FailureQ[cancellation]&&cancellation[[1]]==="FullPoolTargetMismatch"),
 "ConstantSystem"->(constant["ReducedTargets"]==={3 b2}),
 "ConstantCancellationRejected"->(FailureQ[constantCancellation]&&constantCancellation[[1]]==="FullPoolTargetMismatch")|>;
Print[tests];Quit[If[And@@Values[tests],0,3]];
