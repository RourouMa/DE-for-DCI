root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
{bundle,name,loopText,workerText,out}=Take[$CommandLine,-5];loops=ToExpression[loopText];workers=ToExpression[workerText];
InitializeFiniteFlow["/home/april/Packages/finiteflow","/home/april/Packages/finiteflow/mathlink"];FiniteFlow`FFNThreads=workers;
cfg=Get[FileNameJoin[{bundle,name,"FamilyConfiguration.wl"}]];
f=CreateFamily[KeyTake[cfg["LoopFamilies"][loops],{"Name","Dimension","External","Loops","Variables","Kinematics","ExternalDerivatives","ExternalPermutations","Propagators","TopSector","SuperSectors","Completion","IntegralOrdering","MaxLoopPower"}]];
top=If[loops===3,First[cfg["OriginalInput"]],G@@Join[f["TopSector"],ConstantArray[1,loops]]];
If[!FiniteIntegralQ[f,top],Print["INVALID TOP"];Quit[2]];
If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
pool={};done={};symdone={};started=AbsoluteTime[];point={7338376896737913617,7718278679044643367};records={};success=False;
Do[
 Print[<|"Event"->"AnsatzStarted","Loops"->loops,"Family"->name,"Order"->order,"Seconds"->AbsoluteTime[]-started|>];
 ansatz=ConformalIBP`Private`topDerivativeAnsatz[f,top,order];If[FailureQ[ansatz],Print[ansatz];Quit[3]];
 raw=ConformalIBP`Private`canonExpr[f,#]& /@ ansatz["Expressions"];
 generated=GenerateSystem[f,ConformalIBP`Private`support[raw],"SeedGeometry"->"InverseTargets","InverseOperatorPolicy"->"Complete","SeedDomain"->"Extended",
   "Workers"->workers,"CompletedApplications"->done,"CompletedSymmetryInputs"->symdone,"ProgressFunction"->Print];
 If[FailureQ[generated],Print[generated];Quit[4]];
 pool=Union[pool,generated["Equations"]];done=Union[done,generated["Applications"]];symdone=Union[symdone,generated["SymmetryInputs"]];
 q=G /@ (-970000-Range[Length[raw]]);boundary=ConformalIBP`Private`sources[{pool,raw}];
 physical=SortBy[ConformalIBP`Private`support[{pool,raw}],ConformalIBP`Private`simpleKey[f,#]&];sentinel=G[-980001];cols=Join[{sentinel},physical,q,boundary];equations=Join[pool,raw-q,{sentinel-First[q]}];
 Print[<|"Event"->"NumericalQueryProbe","Loops"->loops,"Order"->order,"PoolRows"->Length[pool],"Queries"->Length[q],"PhysicalAtoms"->Length[physical],"BoundaryAtoms"->Length[boundary],"Seconds"->AbsoluteTime[]-started|>];
 Put[<|"Family"->f,"Top"->top,"Ansatz"->ansatz,"Pool"->pool,"Queries"->q,"Columns"->cols,"Equations"->equations,"Records"->records|>,FileNameJoin[{out,"ProbeInput.wl"}]];
 (* FiniteFlow reports FFImpossible for an empty needed pivot set. A harmless
    alias guarantees nonempty output so zero found relations remain a valid result. *)
 FiniteFlow`FFNewGraph[gr];FiniteFlow`FFGraphInputVars[gr,inn,f["Variables"]];registration=FiniteFlow`FFAlgSparseSolver[gr,node,{inn},f["Variables"],#==0& /@ equations,cols,"NeededVars"->Prepend[q,sentinel]];
 FiniteFlow`FFSolverSparseOutput[gr,node];FiniteFlow`FFGraphOutput[gr,node];learn=FiniteFlow`FFSparseSolverLearn[gr,cols];
 vals=FiniteFlow`FFGraphEvaluateMany[gr,{point},"NThreads"->1];FiniteFlow`FFDeleteGraph[gr];
 If[!ListQ[learn]||!MatchQ[vals,{_List}],Print[<|"Event"->"ProbeDiagnostic","Registration"->registration,"Learn"->learn,"Values"->vals|>];Quit[5]];
 nrules=FiniteFlow`FFSparseSolverSol[First[vals],learn];nrules=Select[nrules,MemberQ[q,First[#]]&];
 rec=<|"LoopCount"->loops,"Family"->name,"AnsatzOrder"->order,"DerivativeQueries"->Length[q],"PoolRows"->Length[pool],"PhysicalAtoms"->Length[physical],
  "BoundaryAtoms"->Length[boundary],"ScalarRelationsFound"->Length[nrules],"NumericalRules"->nrules,
  "Seconds"->AbsoluteTime[]-started,"Scope"->"HighestLoopModuloBoundary","LowerLoopSourcesRetained"->True,"Point"->point,
  "DECampaignRun"->False,"KnownMIRead"->False,"OldDERead"->False|>;
 AppendTo[records,rec];Put[records,FileNameJoin[{out,"Progress.wl"}]];Print[KeyDrop[rec,{"NumericalRules","Point"}]];
 If[nrules==={},Continue[]];
 Print[<|"Event"->"ReconstructOnlyScalarRelations","Count"->Length[nrules]|>];
 srules=FiniteFlow`FFSparseSolve[#==0& /@ equations,cols,"NeededVars"->q,"Parameters"->f["Variables"],"SparseOutput"->True,"MaxPrimes"->5];
 If[!ListQ[srules],Print[srules];Continue[]];srules=Select[srules,MemberQ[q,First[#]]&];
 ds={dx,dy};oprows=ConformalIBP`Private`canonicalLinear /@ ((First /@ srules)-(Last /@ srules));
 operators=ConformalIBP`Private`operatorNormalize[#,ds]& /@ ((ConformalIBP`Private`coeff[oprows/._BoundaryIntegral->0,q]).(Times@@(ds^#)& /@ ansatz["Exponents"]));
 bound=TopAnnihilatorRankBound[operators,ds,f["Variables"],"TimeLimit"->30];
 Put[<|"Family"->f,"Top"->top,"Ansatz"->ansatz,"Pool"->pool,"QueryRules"->srules,"Operators"->operators,"LowerLoopSourceRows"->(oprows/._G->0),
   "Bound"->bound,"Scope"->"HighestLoopModuloBoundary","ExactIdentityCertificateCompleted"->False,"Seconds"->AbsoluteTime[]-started|>,FileNameJoin[{out,"Candidate.wl"}]];
 Print[<|"Event"->"CandidateBound","Order"->order,"Bound"->If[FailureQ[bound],Missing["NotCertified"],bound["UpperBound"]],"Diagnostic"->If[FailureQ[bound],bound[[1]],None],"Seconds"->AbsoluteTime[]-started|>];
 If[AssociationQ[bound],success=True;Break[]],{order,{2,3}}];
 Print[<|"Event"->"BudgetProbeFinished","FiniteCandidate"->success,"Seconds"->AbsoluteTime[]-started|>];Quit[0];
