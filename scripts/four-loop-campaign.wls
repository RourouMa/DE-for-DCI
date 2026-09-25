(* Portable fresh-run counterpart of the current production driver.
   Highest-loop closure first. Private orchestration is frozen with the package. *)
config=Import[Environment["DCI_LAUNCH_CONFIGURATION"],"RawJSON"];
If[!AssociationQ[config],Print["Missing launch configuration"];Quit[2]];
root=DirectoryName[DirectoryName[$InputFileName]];run=config["output"];
Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
If[!TrueQ[InitializeFiniteFlow[config["finiteflow"],config["mathlink"]]],Quit[2]];
FiniteFlow`FFNThreads=config["ff_threads"];
family=LadderFamily[4,kinematics,{x,y}];top=G@@Join[family["TopSector"],ConstantArray[1,4]];
emit[e_]:=(Print[e];PutAppend[Join[<|"At"->DateString[Now,"ISODateTime"]|>,e],FileNameJoin[{run,"Events.wl"}]]);
options=Join[Get[FileNameJoin[{root,"Examples","four-loop-count-policy.wl"}]],{
 "MasterCountPreflight"->"Required","Solver"->"FiniteFlow",
 "Workers"->config["workers"],"VerificationWorkers"->config["workers"],"SeedPlanningWorkers"->config["workers"],
 "KernelExecutable"->config["kernel"],"MaxRounds"->config["max_rounds"],"MaxSystemExpansions"->config["max_expansions"],"MaxPrimes"->80,
 "VerificationMode"->"Numerical","NumericalVerificationPoints"->Automatic,
 "FiniteBasisPolicy"->"FiniteSupportThenSpan","GenerationPolicy"->"OnDemand",
 "CheckpointFormat"->"MXFileHash","DeferBoundaryCoefficientSimplification"->True,
 "TargetSelector"->"FiniteFlowDirect","QueryCoveragePolicy"->"ActualRows",
 "SeedGeometry"->"InverseTargets","InverseOperatorPolicy"->"Complete","SeedDomain"->"Extended",
 "BoundaryPolicy"->"Retain","OutputDirectory"->FileNameJoin[{run,"loop4"}],"ProgressFunction"->emit}];
pool=None;
If[KeyExistsQ[config,"pool"],
 pool=Get[config["pool"]];
 If[!AssociationQ[pool]||Lookup[pool,"FamilyHash",None]=!=family["Hash"]||Lookup[pool,"ImplementationHash",None]=!=ConformalIBP`Private`$implementationHash||
   Lookup[pool,"OriginalInputs",None]=!={top}||!ListQ[Lookup[pool,"Equations",None]]||
   Lookup[pool,"EquationPoolHash",None]=!=Hash[pool["Equations"],"SHA256"]||
   Lookup[pool,"ApplicationLedgerHash",None]=!=Hash[Lookup[pool,"CompletedApplications",None],"SHA256"]||
   Lookup[pool,"SymmetryLedgerHash",None]=!=Hash[Lookup[pool,"CompletedSymmetryInputs",None],"SHA256"],
   Print["Pool/source/family/ledger compatibility check failed"];Quit[3]];
 options=Append[options,"InitialEquations"->pool["Equations"]]];
Put[<|"Family"->family,"OriginalInput"->{top},"Options"->DeleteCases[options,Rule["InitialEquations",_]],
 "InitialPool"->If[AssociationQ[pool],KeyTake[pool,{"EquationPoolHash","SourceEpoch","SourceRound"}],None],"ImplementationHash"->ConformalIBP`Private`$implementationHash,
 "HighestLoopFirst"->True,"LowerLoopDEGenerated"->False|>,FileNameJoin[{run,"Configuration.wl"}]];
If[TrueQ[config["configure_only"]],Print[<|"ConfigurationVerified"->True,"IndexSlots"->Length[top],"EstimatedThreshold"->100,"LowerLoopDEGenerated"->False|>];Quit[0]];

repairComplexity[inputState_,audit_,candidate_List]:=Module[{s=inputState,centers,generation,new,record},
 centers=Lookup[audit,"TargetedSeedTargets",{}];
 If[centers==={},Return[Failure["NoComplexitySeedTargets",<|"MessageTemplate"->"Inspect the saved unresolved same-loop expressions."|>]]];
 emit[<|"Event"->"HighestLoopComplexityRepairStarted","Epoch"->s["Epoch"],"Round"->s["CurrentRound"],"Targets"->Length[centers]|>];
 generation=GenerateSystem[family,centers,"SeedCenters"->"AllOriginalImages","SeedGeometry"->"InverseTargets","InverseOperatorPolicy"->"Complete","SeedDomain"->"Extended",
  "CompletedApplications"->s["CompletedApplications"],"CompletedSymmetryInputs"->Lookup[s,"CompletedSymmetryInputs",{}],
  "FiniteSeeds"->Select[candidate,Length[ConformalIBP`Private`support[#]]>1&],"Workers"->config["workers"],"SeedPlanningWorkers"->config["workers"],"KernelExecutable"->config["kernel"],"ProgressFunction"->emit];
 If[FailureQ[generation],Return[generation]];
 new=Complement[generation["Equations"],s["Equations"]];
 record=Join[<|"Epoch"->s["Epoch"],"Round"->s["CurrentRound"],"Trigger"->"ComplexityReviewRequired","NewRelationCount"->Length[new],"ApplicationCount"->Length[generation["Applications"]]|>,KeyDrop[generation,{"Equations","Applications"}]];
 Put[record,FileNameJoin[{run,"ComplexityRepair-epoch"<>ToString[s["Epoch"]]<>".wl"}]];
 If[new==={},Return[Failure["ComplexityRepairNoNewRelations",<|"MessageTemplate"->"Inspect a broader seed neighborhood; no next DE input was accepted."|>]]];
 s["CompletedApplications"]=Union[s["CompletedApplications"],generation["Applications"]];
 s["CompletedSymmetryInputs"]=Union[Lookup[s,"CompletedSymmetryInputs",{}],Lookup[generation,"NewSymmetryInputs",{}]];
 s["LastGenerationAudit"]=record;s["GenerationHistory"]=Append[Lookup[s,"GenerationHistory",{}],record];
 s["Equations"]=Union[s["Equations"],new];s["Epoch"]++;s["Status"]="ReplayFromOriginalInputs";
 s=KeyDrop[s,{"VerifiedRoundContinuation","SymmetryCache","CandidateFiniteBasis","UnverifiedRows"}];
 emit[<|"Event"->"PoolExpanded","Epoch"->s["Epoch"],"Round"->s["CurrentRound"],"NewRelations"->Length[new],"ReplayFromOriginalTop"->True|>];
 ConformalIBP`Private`checkpoint[s,s["Options"]["OutputDirectory"]];s];

result=If[AssociationQ[pool],
 state=ConformalIBP`Private`makeState[family,{top},"DE",Join[Association[Options[RunDE]],Association[options]]];
 state=Join[state,KeyTake[pool,{"CompletedApplications","CompletedSymmetryInputs"}]];
 emit[<|"Event"->"VerifiedPoolImported","EquationCount"->Length[pool["Equations"]],"ReplayFromOriginalTop"->True,"ReductionRulesImported"->False|>];
 Clear[pool];ConformalIBP`Private`runCampaign[state],RunDE[family,{top},Sequence@@options]];repairs=0;
While[AssociationQ[result]&&MatchQ[Lookup[result,"Status",None],Failure["ComplexityReviewRequired",_]]&&repairs<config["max_complexity_repairs"],
 candidate=If[KeyExistsQ[result,"CandidateFiniteBasis"],result["CandidateFiniteBasis"]["Basis"],result["CurrentInputs"]];
 state=repairComplexity[result,result["ComplexityAudit"],candidate];If[FailureQ[state],result=state;Break[]];repairs++;
 result=ConformalIBP`Private`runCampaign[state]];
Put[result,FileNameJoin[{run,"Result.wl"}]];
summary=If[AssociationQ[result],Join[KeyTake[result,{"Status","Epoch","Closed","ClosedModuloBoundary","FlatnessVerified","MasterCountRankAudit"}],
 <|"BasisCount"->Length[Lookup[result,"Basis",{}]],"EquationCount"->Length[Lookup[result,"Equations",{}]],"ComplexityRepairs"->repairs,
 "HighestLoopVerificationStillRequired"->True,"LowerLoopDEGenerated"->False|>],<|"Failure"->result|>];
Put[summary,FileNameJoin[{run,"Summary.wl"}]];Print[summary];
(* A numerical/source-retaining highest-loop result still needs independent
   coverage/finite-basis/curvature verification before any lower-loop campaign. *)
Quit[If[FailureQ[result]||FailureQ[Lookup[result,"Status",None]],1,0]];
