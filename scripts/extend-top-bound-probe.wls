{source,out}=Take[$CommandLine,-2];Get[FileNameJoin[{source,"Kernel","ConformalIBP.wl"}]];
InitializeFiniteFlow["/home/april/Packages/finiteflow","/home/april/Packages/finiteflow/mathlink"];FiniteFlow`FFNThreads=6;
p=Get[FileNameJoin[{out,"ProbeInput.wl"}]];f=p["Family"];top=p["Top"];ansatz=p["Ansatz"];pool=p["Pool"];started=AbsoluteTime[];
exp=ansatz["Exponents"];raw=ConformalIBP`Private`canonExpr[f,#]& /@ ansatz["Expressions"];index=First[FirstPosition[exp,{3,0}]];
extra=First[DifferentiateIntegrals[f,{raw[[index]]}]["Rows"][First[f["Variables"]]]];
extra=ConformalIBP`Private`canonExpr[f,extra];AppendTo[raw,extra];AppendTo[exp,{4,0}];
gen=GenerateSystem[f,ConformalIBP`Private`support[extra],"SeedGeometry"->"InverseTargets","InverseOperatorPolicy"->"Complete","SeedDomain"->"Extended","Workers"->6,"ProgressFunction"->Print];
If[FailureQ[gen],Print[gen];Quit[2]];pool=Union[pool,gen["Equations"]];
q=G /@ (-970000-Range[Length[raw]]);physical=SortBy[ConformalIBP`Private`support[{pool,raw}],ConformalIBP`Private`simpleKey[f,#]&];boundary=ConformalIBP`Private`sources[{pool,raw}];
cols=Join[physical,q,boundary];equations=Join[pool,raw-q];
Print[<|"Event"->"TargetedFourthDerivative","Queries"->Length[q],"PoolRows"->Length[pool],"Seconds"->AbsoluteTime[]-started|>];
rules=FiniteFlow`FFSparseSolve[#==0& /@ equations,cols,"NeededVars"->q,"Parameters"->f["Variables"],"SparseOutput"->True,"MaxPrimes"->5];
If[!ListQ[rules],Print[rules];Quit[3]];rules=Select[rules,MemberQ[q,First[#]]&];rows=ConformalIBP`Private`canonicalLinear /@ ((First /@ rules)-(Last /@ rules));
ds={dx,dy};operators=ConformalIBP`Private`operatorNormalize[#,ds]& /@ (ConformalIBP`Private`coeff[rows/._BoundaryIntegral->0,q].(Times@@(ds^#)& /@ exp));
bound=TopAnnihilatorRankBound[operators,ds,f["Variables"],"TimeLimit"->20];
result=<|"LoopCount"->2,"Scope"->"HighestLoopModuloBoundary","Operators"->operators,"LowerLoopSourceRows"->(rows/._G->0),"Bound"->bound,
 "PreviousPoolReused"->True,"ExactIdentityCertificateCompleted"->False,"Seconds"->AbsoluteTime[]-started|>;
Put[result,FileNameJoin[{out,"TargetedFourthDerivative.wl"}]];Print[<|"Event"->"TargetedExtensionFinished","Bound"->If[FailureQ[bound],Missing["NotCertified"],bound["UpperBound"]],"Diagnostic"->If[FailureQ[bound],bound[[1]],None],"Seconds"->AbsoluteTime[]-started|>];Quit[0];
