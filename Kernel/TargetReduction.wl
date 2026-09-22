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
 If[!MemberQ[{Automatic,"Python","FiniteFlow"},OptionValue["TargetSelector"]],Return[fail["TargetSelector","Unknown target selector."]]];
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
