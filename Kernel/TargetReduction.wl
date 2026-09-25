fullPoolNumericalAgreement[rows_,columns_,queries_,rules_,parameters_,requested_]:=Module[{graph,in,sys,learn,values,points=numericalPoints[parameters,requested],prime,nrules,point,diff,samples},
 FiniteFlow`FFNewGraph[graph];FiniteFlow`FFGraphInputVars[graph,in,parameters];
 FiniteFlow`FFAlgSparseSolver[graph,sys,{in},parameters,#==0& /@ rows,columns,"NeededVars"->queries];
 FiniteFlow`FFSolverSparseOutput[graph,sys];FiniteFlow`FFGraphOutput[graph,sys];learn=FiniteFlow`FFSparseSolverLearn[graph,columns];
 If[!ListQ[learn],FiniteFlow`FFDeleteGraph[graph];Return[fail["FullPoolNumericalLearn","Full-pool numerical reference could not be learned."]]];
 values=FiniteFlow`FFGraphEvaluateMany[graph,points,"NThreads"->Length[points]];FiniteFlow`FFDeleteGraph[graph];
 If[!ListQ[values] || Length[values]=!=Length[points] || !AllTrue[values,VectorQ[#,IntegerQ]&],Return[fail["FullPoolNumericalEvaluation","The full-pool sample must be nonsingular."]]];
 prime=FiniteFlow`FFPrimeNo[0];samples=Table[point=Thread[parameters->points[[k]]];nrules=FiniteFlow`FFSparseSolverSol[values[[k]],learn];
 diff=((queries/.point)/.Dispatch[nrules])-((queries/.point)/.Dispatch[Thread[(First /@ rules)->((Last /@ rules)/.point)]]);
 <|"Point"->points[[k]],"Passed"->AllTrue[diff,numericalLinearZeroQ[#,prime]&]|>,{k,Length[points]}];
 <|"Passed"->And@@Lookup[samples,"Passed"],"Samples"->samples,"Prime"->prime,"PoolHash"->Hash[rows,"SHA256"],"SymbolicResidualVerificationPerformed"->False|>];

(* Certify a target reduction with ORIGINAL selected equations, not the full pool. *)
$lastTargetSampling=<||>;
Options[ReduceTargetIntegrals]=Join[Options[ReduceIntegrals],{"MinimumSelectionRows"->500,"PythonExecutable"->"python3","ReuseTargetSampling"->True,"TargetSelector"->Automatic}];
ReduceTargetIntegrals[f_Association,targets_List,equations_List,opts:OptionsPattern[]]:=Module[
 {rows,ct,atoms,all,position,triples={},gs,values,samples={},sample,prime,point,numeric,attempt,samplingParameters,
  dir,inputFile,outputFile,script,process,selection,ids,red,needed,keep,images,rules,result,report=OptionValue["ProgressFunction"],
  started=AbsoluteTime[],selectionSeconds,baseOptions,certificate,nontrivial,rankWitness=Missing["UnprunedSystem"],rankCertified=False,samplingKey,samplingReused=False},
 If[!MemberQ[{Automatic,"Python","FiniteFlow","FiniteFlowDirect"},OptionValue["TargetSelector"]],Return[fail["TargetSelector","Unknown target selector."]]];
 If[OptionValue["TargetSelector"]==="FiniteFlowDirect",Return[reduceTargetsFFDirect[f,targets,equations,Association[Join[Options[ReduceTargetIntegrals],{opts}]]]]];
 If[OptionValue["TargetSelector"]==="FiniteFlow" || (OptionValue["TargetSelector"]===Automatic && (OptionValue["Solver"]==="FiniteFlow" || (OptionValue["Solver"]===Automatic && MemberQ[$Packages,"FiniteFlow`"])) && Length[equations]>=OptionValue["MinimumSelectionRows"]),
  Return[reduceTargetsFF[f,targets,equations,Association[Join[Options[ReduceTargetIntegrals],{opts}]]]]];
 baseOptions=FilterRules[{opts},Options[ReduceIntegrals]];
 rows=DeleteCases[canonExpr[f,#]& /@ equations,0];ct=canonExpr[f,#]& /@ targets;
 If[AnyTrue[Join[rows,ct],FailureQ],Return[First[Select[Join[rows,ct],FailureQ]]]];
 atoms=Join[support[ct],sources[ct]];
 all=Join[SortBy[Union[support[rows],support[ct]],simpleKey[f,#]&],sources[{rows,ct}]];
 position=Association[Thread[all->Range[Length[all]]]];
 If[Length[rows]>=OptionValue["MinimumSelectionRows"],
 samplingKey=Hash[{f["Hash"],$implementationHash,rows,all},"SHA256"];
 samplingReused=TrueQ[OptionValue["ReuseTargetSampling"]] && Lookup[$lastTargetSampling,"Key",None]===samplingKey;
 If[samplingReused,samples=$lastTargetSampling["Samples"],
 triples=Flatten[Table[gs=Join[support[rows[[i]]],sources[rows[[i]]]];
  Table[{i,position[g],Together[Coefficient[rows[[i]],g]]},{g,gs}],{i,Length[rows]}],1];
 values=If[triples==={},{},triples[[All,3]]];samplingParameters=Union[Flatten[Variables /@ values]];
 Do[prime={1000003,1000033}[[sample]];numeric=$Failed;
  Do[point=Thread[samplingParameters->Prime[Range[Length[samplingParameters]]+sample+attempt-2]];
   numeric=Quiet[Check[Together /@ (values/.point),$Failed]];
   If[ListQ[numeric] && VectorQ[numeric,MatchQ[#,_Integer|_Rational]&] &&
     !AnyTrue[numeric,Mod[Denominator[#],prime]===0&],Break[],numeric=$Failed],{attempt,1,10}];
  If[numeric===$Failed,Return[fail["TargetSampling","No nonsingular rational sampling point found."]]];
  numeric=Mod[Numerator[#] PowerMod[Denominator[#],-1,prime],prime]& /@ numeric;
  AppendTo[samples,<|"Prime"->prime,"Entries"->MapThread[Append,{If[triples==={},{},triples[[All,{1,2}]]],numeric}]|>],{sample,1,2}];
 If[TrueQ[OptionValue["ReuseTargetSampling"]],$lastTargetSampling=<|"Key"->samplingKey,"Samples"->samples|>]];
 dir=CreateDirectory[FileNameJoin[{$TemporaryDirectory,"conformal-target-selection-"<>CreateUUID[]}]];
 inputFile=FileNameJoin[{dir,"input.json"}];outputFile=FileNameJoin[{dir,"selection.json"}];
 Export[inputFile,<|"Rows"->Length[rows],"Targets"->(position /@ atoms),"Samples"->samples|>,"RawJSON"];
 script=FileNameJoin[{DirectoryName[DirectoryName[$packageFile]],"scripts","select-equation-rows.py"}];
 process=RunProcess[{OptionValue["PythonExecutable"],script,inputFile,outputFile}];
 If[!AssociationQ[process] || process["ExitCode"]=!=0 || !FileExistsQ[outputFile],
  Return[fail["TargetSelection","Dependency selector failed.",<|"Process"->process,"Directory"->dir|>]]];
 selection=Import[outputFile,"RawJSON"];ids=Lookup[selection,"Rows",$Failed];
 If[!ListQ[ids] || !DuplicateFreeQ[ids] || !VectorQ[ids,IntegerQ[#] && 1<=#<=Length[rows]&],
  Return[fail["TargetSelection","Invalid original-row indices from selector."]]];
 selectionSeconds=AbsoluteTime[]-started,
 ids=Range[Length[rows]];selection=<|"Samples"->{}|>;dir=None;selectionSeconds=AbsoluteTime[]-started];
 If[report=!=None,report[<|"Action"->"Target subset selected","OriginalRows"->Length[rows],"SelectedRows"->Length[ids],"TargetAtoms"->Length[atoms],"SelectionSeconds"->selectionSeconds,"SamplingReused"->samplingReused|>]];
 red=ReduceIntegrals[f,targets,rows[[ids]],Sequence@@baseOptions];If[FailureQ[red],Return[red]];
 (* Structural identity detection avoids combining unrelated integral coefficients into one huge fraction.
    The disjoint-pivot test below rejects any nontrivial self-dependence. *)
 nontrivial=Select[red["Rules"],First[#]=!=Last[#]&];
 If[selection["Samples"]=!={},
  rankWitness=Max[Lookup[selection["Samples"],"SelectedRank"]];
  rankCertified=rankWitness===Length[nontrivial] &&
   Intersection[First /@ nontrivial,Join[support[Last /@ nontrivial],sources[Last /@ nontrivial]]]==={};
  If[!TrueQ[rankCertified],Return[fail["TargetRankCertificate","Selected equations and returned independent constraints have different rank.",
   <|"ModularRank"->rankWitness,"NontrivialRules"->Length[nontrivial]|>]]]];
 needed=Union[atoms,support[red["ReducedTargets"]],sources[red["ReducedTargets"]]];
 keep=Join[SortBy[Select[needed,MatchQ[#,_G]&],simpleKey[f,#]&],Select[needed,MatchQ[#,_BoundaryIntegral]&]];
 images=canonicalLinear /@ (keep/.Dispatch[red["Rules"]]);rules=Thread[keep->images];
 certificate=<|"OriginalPoolHash"->Hash[rows,"SHA256"],"OriginalRowIndices"->ids,
  "SelectedEquationsHash"->Hash[rows[[ids]],"SHA256"],"Rules"->red["Rules"],
  "ExactEquationResidualsZero"->red["ExactEquationResidualsZero"],"Idempotent"->red["Idempotent"],"Sampling"->selection["Samples"],
  "ModularRankWitness"->rankWitness,"IndependentConstraintCount"->Length[nontrivial],"ExactSelectedRowSpaceCertified"->(rankCertified && OptionValue["VerificationMode"]==="Exact"),"NumericalSelectedRowSpaceChecked"->(rankCertified && OptionValue["VerificationMode"]==="Numerical")|>;
 result=Join[red,<|"Rules"->rules,"ColumnOrder"->keep,"Columns"->Length[keep],
  "SameLoopRules"->Select[rules,MatchQ[First[#],_G]&],"BoundaryRules"->Select[rules,MatchQ[First[#],_BoundaryIntegral]&],
  "UnseenTargets"->Complement[support[ct],support[rows]],"VerificationScope"->"SelectedOriginalEquations",
  "FullPoolEquationResidualsChecked"->(Length[ids]===Length[rows]),"OriginalEquationCount"->Length[rows],
  "SelectionSeconds"->selectionSeconds,"SamplingReused"->samplingReused,"SelectionDirectory"->dir,"VerificationCertificate"->certificate|>];result];

(* The backend tracks a smaller set of ORIGINAL rows. The existing independent
   modular-rank and exact selected-row certificate remains mandatory. A separate
   full-pool target solve must agree before returning the selected reduction. *)
reduceTargetsFF[f_,targets_,equations_,o_]:=Module[
 {rows,ct,atoms,all,graph,in,sys,learn,ids,count,inner,certificate,mapped,reference,diff,
  start=AbsoluteTime[],selectedSeconds,innerOptions,parameters,report=o["ProgressFunction"],fullSeconds},
 If[!MemberQ[$Packages,"FiniteFlow`"],Return[fail["FiniteFlowNotLoaded","FiniteFlow selector requires FiniteFlow."]]];
 rows=DeleteCases[canonExpr[f,#]& /@ equations,0];ct=canonExpr[f,#]& /@ targets;
 If[AnyTrue[Join[rows,ct],FailureQ],Return[First[Select[Join[rows,ct],FailureQ]]]];
 atoms=Join[support[ct],sources[ct]];
 all=Join[SortBy[Union[support[rows],support[ct]],simpleKey[f,#]&],sources[{rows,ct}]];
 innerOptions=Join[o,<|"TargetSelector"->"Python","MinimumSelectionRows"->0|>];
 If[rows==={} || atoms==={},Return[ReduceTargetIntegrals[f,targets,equations,Sequence@@Normal[innerOptions]]]];
 parameters=coefficientParameters[rows];
 FiniteFlow`FFNewGraph[graph];FiniteFlow`FFGraphInputVars[graph,in,parameters];
 FiniteFlow`FFAlgSparseSolver[graph,sys,{in},parameters,#==0& /@ rows,all,"NeededVars"->atoms];
 FiniteFlow`FFGraphOutput[graph,sys];learn=FiniteFlow`FFSparseSolverLearn[graph,all];
 If[!ListQ[learn],FiniteFlow`FFDeleteGraph[graph];
  Return[ReduceTargetIntegrals[f,targets,equations,Sequence@@Normal[innerOptions]]]];
 count=FiniteFlow`FFSparseSolverMarkAndSweepEqs[graph,sys];ids=FiniteFlow`FFSolverIndepEqs[graph,sys];
 FiniteFlow`FFDeleteGraph[graph];
 If[!ListQ[ids] || !DuplicateFreeQ[ids] || !VectorQ[ids,IntegerQ[#] && 1<=#<=Length[rows]&] || count=!=Length[ids],
  Return[fail["TargetSelection","FiniteFlow returned invalid original-row indices."]]];
 If[count===0,Return[ReduceTargetIntegrals[f,targets,equations,Sequence@@Normal[innerOptions]]]];
 selectedSeconds=AbsoluteTime[]-start;
 If[report=!=None,report[<|"Action"->"FiniteFlow dependency rows selected","OriginalRows"->Length[rows],"SelectedRows"->Length[ids],"SelectionSeconds"->selectedSeconds|>]];
 inner=ReduceTargetIntegrals[f,targets,rows[[ids]],Sequence@@Normal[innerOptions]];
 If[FailureQ[inner],Return[inner]];
 start=AbsoluteTime[];
 If[report=!=None,report[<|"Action"->"Starting full-pool target reference","Parameters"->parameters,"Queries"->Length[inner["ColumnOrder"]]|>]];
 If[o["VerificationMode"]==="Numerical",
 reference=fullPoolNumericalAgreement[rows,all,inner["ColumnOrder"],inner["Rules"],parameters,o["NumericalVerificationPoints"]];
 If[FailureQ[reference],Return[reference]];
 If[!TrueQ[reference["Passed"]],Return[fail["FullPoolTargetMismatch","Selected target normal forms differ from the full pool."]]],
 reference=FiniteFlow`FFSparseSolve[#==0& /@ rows,all,"NeededVars"->inner["ColumnOrder"],"Parameters"->parameters,"SparseOutput"->True,"MaxPrimes"->o["MaxPrimes"]];
 If[!ListQ[reference] || !And@@(MatchQ[#,_Rule]& /@ reference),Return[fail["FullPoolTargetSolve","Full-pool target reference failed."]]];
 If[report=!=None,report[<|"Action"->"Full-pool target solve returned; comparing exact normal forms","Seconds"->AbsoluteTime[]-start|>]];
 diff=If[o["VerificationMode"]==="Exact",canonicalLinear /@ ((inner["ColumnOrder"]/.Dispatch[reference])-(inner["ColumnOrder"]/.Dispatch[inner["Rules"]])),If[sampledRuleAgreement[inner["ColumnOrder"],reference,inner["Rules"],parameters,o["NumericalVerificationPoints"]],{}, {1}]];
 If[!And@@(zero /@ diff),Return[fail["FullPoolTargetMismatch","Selected target normal forms differ from the full pool.",<|"Residuals"->DeleteCases[diff,0]|>]]];
 ];
 fullSeconds=AbsoluteTime[]-start;
 certificate=inner["VerificationCertificate"];mapped=ids[[certificate["OriginalRowIndices"]]];
 certificate=Join[certificate,<|"OriginalPoolHash"->Hash[rows,"SHA256"],"OriginalRowIndices"->mapped,
  "SelectedEquationsHash"->Hash[rows[[mapped]],"SHA256"],"SelectionBackend"->"FiniteFlowThenIndependentModularCertificate",
  "FullPoolTargetAgreement"->True,"FullPoolTargetVerificationMode"->o["VerificationMode"],"FullPoolTargetRulesHash"->Hash[reference,"SHA256"]|>];
 If[report=!=None,report[<|"Action"->If[o["VerificationMode"]==="Exact","Full-pool target normal forms agree exactly","Full-pool target normal forms agree at requested numerical points"],"Queries"->Length[inner["ColumnOrder"]],"Seconds"->fullSeconds|>]];
 Join[inner,<|"VerificationCertificate"->certificate,"OriginalEquationCount"->Length[rows],
  "FullPoolEquationResidualsChecked"->(Length[mapped]===Length[rows]),"FullPoolTargetAgreement"->True,"FullPoolTargetVerificationMode"->o["VerificationMode"],
  "SelectionSeconds"->(selectedSeconds+inner["SelectionSeconds"]),"FullPoolTargetCheckSeconds"->fullSeconds|>]
];

(* Reconstruct only queried normal forms. A fresh graph checks those forms and
   every free image atom against the FULL input pool at the requested point.
   This certificate deliberately does not claim full symbolic row residuals. *)
$lastVerifiedTargetReduction=<||>;
reduceTargetsFFDirect[f_,targets_,equations_,o_]:=Module[
 {rows,ct,atoms,all,parameters,rawRules,keep,images,rules,reference,raw,result,
  report=o["ProgressFunction"],start=AbsoluteTime[],solveSeconds,checkSeconds,fallback,cacheKey,dispatch},
 fallback[]:=ReduceTargetIntegrals[f,targets,equations,Sequence@@Normal[Join[o,<|"TargetSelector"->"FiniteFlow"|>]]];
 If[o["VerificationMode"]=!="Numerical",Return[fallback[]]];
 If[!MemberQ[$Packages,"FiniteFlow`"],Return[fail["FiniteFlowNotLoaded","FiniteFlow direct target reduction requires FiniteFlow."]]];
 rows=DeleteCases[canonExpr[f,#]& /@ equations,0];ct=canonExpr[f,#]& /@ targets;
 If[AnyTrue[Join[rows,ct],FailureQ],Return[First[Select[Join[rows,ct],FailureQ]]]];
 atoms=Join[support[ct],sources[ct]];
 If[rows==={} || atoms==={},Return[fallback[]]];
 all=Join[SortBy[Union[support[rows],support[ct]],simpleKey[f,#]&],sources[{rows,ct}]];
 cacheKey=Hash[{f["Hash"],$implementationHash,rows,all,o["MaxPrimes"],o["VerificationMode"],o["NumericalVerificationPoints"]},"SHA256"];
 If[TrueQ[o["ReuseVerifiedReduction"]] && Lookup[$lastVerifiedTargetReduction,"Key",None]===cacheKey && Complement[atoms,$lastVerifiedTargetReduction["Result"]["ColumnOrder"]]==={},
  result=Join[$lastVerifiedTargetReduction["Result"],<|"ReductionReused"->True|>];
  If[report=!=None,report[<|"Action"->"Reusing verified full-pool target normal forms","Queries"->Length[atoms]|>]];
  Return[directTargetMetadata[result,ct,rows]]];
 parameters=coefficientParameters[rows];
 If[report=!=None,report[<|"Action"->"Starting direct full-pool target solve","Rows"->Length[rows],"Columns"->Length[all],"NeededColumns"->Length[atoms],"PreparationSeconds"->(AbsoluteTime[]-start)|>]];
 start=AbsoluteTime[];
 rawRules=FiniteFlow`FFSparseSolve[#==0& /@ rows,all,"NeededVars"->atoms,"Parameters"->parameters,"SparseOutput"->True,"MaxPrimes"->o["MaxPrimes"]];
 If[!ListQ[rawRules] || !AllTrue[rawRules,MatchQ[#,_Rule]&],Return[fallback[]]];
 images=atoms/.Dispatch[rawRules];
 keep=Union[atoms,support[images],sources[images]];
 keep=Join[SortBy[Select[keep,MatchQ[#,_G]&],simpleKey[f,#]&],Select[keep,MatchQ[#,_BoundaryIntegral]&]];
 rules=Thread[keep->(keep/.Dispatch[rawRules])];solveSeconds=AbsoluteTime[]-start;
 If[report=!=None,report[<|"Action"->"Direct target reconstruction completed","ReconstructedRules"->Length[rawRules],"RetainedColumns"->Length[keep],"Seconds"->solveSeconds|>]];
 start=AbsoluteTime[];
 reference=fullPoolNumericalAgreement[rows,all,keep,rules,parameters,o["NumericalVerificationPoints"]];
 If[FailureQ[reference],Return[reference]];
 If[!TrueQ[reference["Passed"]],Return[fail["FullPoolTargetMismatch","Direct target normal forms differ from a fresh full-pool numerical solve."]]];
 raw=Join[support[Last /@ rules],sources[Last /@ rules]];
 If[!sampledRuleAgreement[raw,rules,{},parameters,o["NumericalVerificationPoints"]],Return[fail["NonIdempotentReduction","Direct target images are not normal forms."]]];
 checkSeconds=AbsoluteTime[]-start;
 result=<|"Rules"->rules,"ColumnOrder"->keep,"Columns"->Length[keep],"FullPoolColumns"->Length[all],
  "SameLoopRules"->Select[rules,MatchQ[First[#],_G]&],"BoundaryRules"->Select[rules,MatchQ[First[#],_BoundaryIntegral]&],
  "BoundaryConstraintOrigin"->"Existing input equations only","EquationCount"->Length[rows],"OriginalEquationCount"->Length[rows],
  "ExactEquationResidualsZero"->False,"NumericalEquationResidualsZero"->False,"FullPoolEquationResidualsChecked"->False,
  "VerificationScope"->"FullPoolTargetNormalForms","VerificationMode"->"Numerical","NumericalVerificationPoints"->numericalPoints[parameters,o["NumericalVerificationPoints"]],
  "Idempotent"->True,"Solver"->"FiniteFlow","CoefficientParameters"->parameters,"Ordering"->Lookup[f,"IntegralOrdering","LadderFirst"],"ReductionReused"->False,
  "StageTimings"-><|"TargetSolve"->solveSeconds,"FullPoolTargetCheck"->checkSeconds|>,
  "FullPoolTargetAgreement"->True,"FullPoolTargetVerificationMode"->"Numerical",
  "VerificationCertificate"-><|"OriginalPoolHash"->Hash[rows,"SHA256"],"SelectionBackend"->"FiniteFlowDirect", "CheckedColumns"->keep,
   "FullPoolTargetAgreement"->True,"NumericalReference"->reference,"Idempotent"->True,"SymbolicResidualVerificationPerformed"->False|>|>;
 If[report=!=None,report[<|"Action"->"Direct target normal forms agree with fresh full-pool numerical solve","Queries"->Length[keep],"Seconds"->checkSeconds|>]];
 If[TrueQ[o["ReuseVerifiedReduction"]],$lastVerifiedTargetReduction=<|"Key"->cacheKey,"Result"->result|>];
 If[report=!=None,report[<|"Action"->"Building direct target metadata","Queries"->Length[ct]|>]];
 result=directTargetMetadata[result,ct,rows];
 If[report=!=None,report[<|"Action"->"Direct target metadata completed"|>]];result
];

(* An atomic query is already a reconstructed normal form. Avoid expanding its
   rational coefficients merely to return it; combined physical rows still use
   canonicalLinear and undergo the usual exact finite-cover checks. *)
directTargetMetadata[result_,targets_,rows_]:=Module[{dispatch=Dispatch[result["Rules"]],images},
 images=If[MatchQ[#,_G|_BoundaryIntegral],#/.dispatch,canonicalLinear[#/.dispatch]]& /@ targets;
 Join[result,<|"ReducedTargets"->images,"RawMasters"->support[images],"BoundarySources"->sources[images],
  "SelfReducedTargets"->Select[support[targets],selfReducedIntegralQ[#,#/.dispatch]&],
  "UnseenTargets"->Complement[support[targets],support[rows]]|>]];
