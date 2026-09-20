(* A state is a trusted local Wolfram expression, never an opaque global session. *)
generateSharded[f_,targets_,options_]:=Module[{n=options["Workers"],ops,shards,dir,kernel,runner,jobs={},results,code,out,cacheFile,imported,sharedImages,plan,active,ids,subplan},
 If[!IntegerQ[n] || n<1,Return[fail["Workers","Workers must be a positive integer."]]];
 ops=DeleteDuplicates[Replace[options["Operators"],Automatic:>GenerateOperators[f]]];
 plan=GenerateSeeds[f,targets,ops,Sequence@@FilterRules[Normal[options],Options[GenerateSeeds]]];If[FailureQ[plan],Return[plan]];
 plan=pendingSeedPlan[plan,options["CompletedApplications"]];
 active=Select[Range[Length[ops]],plan["Batches"][[#]]["Seeds"]=!={} || (options["FiniteSeeds"]=!={} && ops[[#]]["Degree"]===ConstantArray[0,f["LoopCount"]])&];
 n=Min[n,Length[active]];If[n===0,Return[Join[generatePlannedSystem[f,targets,options,plan],<|"IndependentKernels"->0|>]]];
 kernel=Replace[options["KernelExecutable"],Automatic:>First[$CommandLine]];
 runner=FileNameJoin[{DirectoryName[DirectoryName[$packageFile]],"scripts","ibp-worker.wls"}];
 dir=CreateDirectory[FileNameJoin[{$TemporaryDirectory,"conformal-ibp-"<>CreateUUID[]}]];
 sharedImages=CanonicalIntegral[f,#]& /@ support[targets];
 If[AnyTrue[sharedImages,FailureQ],Return[First[Select[sharedImages,FailureQ]]]];
 cacheFile=FileNameJoin[{dir,"SymmetryCache.wl"}];Put[exportSymmetryCache[f],cacheFile];
 Do[ids=active[[Range[i,Length[active],n]]];shards=ops[[ids]];
  subplan=Join[plan,<|"Operators"->shards,"Batches"->MapIndexed[Join[#1,<|"OperatorIndex"->First[#2]|>]&,plan["Batches"][[ids]]]|>];
  Put[<|"Family"->f,"Targets"->targets,"SeedPlan"->subplan,"SymmetryCacheFile"->cacheFile,"Options"->Normal[Join[options,<|"Workers"->1,"Operators"->shards|>]]|>,
    FileNameJoin[{dir,"input"<>ToString[i]<>".wl"}]];
  AppendTo[jobs,StartProcess[{kernel,"-script",runner,FileNameJoin[{dir,"input"<>ToString[i]<>".wl"}],FileNameJoin[{dir,"output"<>ToString[i]<>".wl"}]}]],{i,n}];
 If[AnyTrue[jobs,Head[#]=!=ProcessObject&],Scan[If[Head[#]===ProcessObject,KillProcess[#]]&,jobs];Return[fail["KernelLaunch","Could not launch independent workers.",<|"Directory"->dir|>]]];
 While[AnyTrue[jobs,ProcessStatus[#]==="Running"&],Pause[0.1]];
 If[!And@@Table[ProcessInformation[jobs[[i]],"ExitCode"]===0 && FileExistsQ[FileNameJoin[{dir,"output"<>ToString[i]<>".wl"}]],{i,n}],
  Return[fail["WorkerFailure","Worker failed; inspect the retained job directory.",<|"Directory"->dir,"Output"->(ReadString[#,EndOfBuffer]& /@ jobs),"Processes"->(ProcessInformation /@ jobs)|>]]];
 results=Get /@ Table[FileNameJoin[{dir,"output"<>ToString[i]<>".wl"}],{i,n}];
 If[AnyTrue[results,FailureQ],Return[First[Select[results,FailureQ]]]];
 Do[imported=importSymmetryCache[f,result["SymmetryCache"]];If[FailureQ[imported],Return[imported]],{result,results}];
 <|"Equations"->Union[Flatten[Lookup[results,"Equations"]]],
  "Applications"->Union[Flatten[Lookup[results,"Applications"],1]],
  "RejectedApplications"->Flatten[Lookup[results,"RejectedApplications"]],
  "DegreeCoverageGaps"->Union[Flatten[Lookup[results,"DegreeCoverageGaps"],1]],
  "SymmetryInputs"->Union[Flatten[Lookup[results,"SymmetryInputs"]]],
  "NewSymmetryInputs"->Union[Flatten[Lookup[results,"NewSymmetryInputs"]]],
  "AllActualSeedsInsideOriginalDomain"->And@@Lookup[results,"AllActualSeedsInsideOriginalDomain"],
  "SeedPolicy"->Lookup[First[results],"SeedPolicy",<||>],
  "SeedingDeduplication"->plan["SeedingDeduplication"],
  "AllGeneratedSupportCanonicalized"->True,"IndependentKernels"->n,"JobDirectory"->dir|>];

Options[RunDE]={"OutputDirectory"->None,"MaxRounds"->8,"MaxSystemExpansions"->12,
 "Solver"->Automatic,"MaxExactColumns"->1500,"MaxPrimes"->80,"Workers"->1,"VerificationWorkers"->1,
 "KernelExecutable"->Automatic,"InitialEquations"->{},"BoundaryPolicy"->"Retain",
 "GenerationPolicy"->"OnDemand","ReductionScope"->"Targets",
 "SeedDomain"->"Original","BlockExpansion"->"Cartesian","GapSeeding"->True,"ProgressFunction"->Print};
Options[RunReduction]=Options[RunDE];
progress[o_,a_]:=If[o["ProgressFunction"]=!=None,o["ProgressFunction"][a]];
checkpoint[state_,dir_]:=If[StringQ[dir],Module[{path,tmp,saved},
 If[!DirectoryQ[dir],CreateDirectory[dir,CreateIntermediateDirectories->True]];
 path=FileNameJoin[{dir,"Checkpoint.wl"}];tmp=path<>".tmp";
 saved=Append[state,"SymmetryCache"->exportSymmetryCache[state["Family"]]];
 Put[<|"Version"->$ConformalIBPVersion,"Hash"->Hash[saved,"SHA256"],"State"->saved|>,tmp];
 RenameFile[tmp,path,OverwriteTarget->True]]];
saveRound[dir_,epoch_,round_,record_]:=If[StringQ[dir],Module[{path=FileNameJoin[{dir,"epoch"<>ToString[epoch],"round"<>ToString[round]}]},
 If[!DirectoryQ[path],CreateDirectory[path,CreateIntermediateDirectories->True]];
 KeyValueMap[Put[#2,FileNameJoin[{path,#1<>".wl"}]]&,record]]];
makeState[f_,inputs_,mode_,o_]:=<|"Family"->f,"FamilyHash"->f["Hash"],"ImplementationHash"->$implementationHash,"OriginalInputs"->inputs,
 "Mode"->mode,"Options"->o,"Equations"->o["InitialEquations"],"CompletedApplications"->{},"CompletedSymmetryInputs"->{},
 "HistoricalTargets"->support[inputs],"PreviousRepresentatives"->{},"History"->{},"Epoch"->0,
 "Status"->"Initialized","Closed"->False,"HistoricalRules"->{}|>;
RunDE[f_Association,inputs_List,opts:OptionsPattern[]]:=runCampaign[makeState[f,inputs,"DE",Join[Association[Options[RunDE]],Association[{opts}]]]];
RunReduction[f_Association,inputs_List,opts:OptionsPattern[]]:=runCampaign[makeState[f,inputs,"Reduction",Join[Association[Options[RunReduction]],Association[{opts}]]]];
RunDE[f_Association,input_ /; !ListQ[input],opts:OptionsPattern[]]:=RunDE[f,{input},opts];
RunReduction[f_Association,input_ /; !ListQ[input],opts:OptionsPattern[]]:=RunReduction[f,{input},opts];
ResumeRun[dir_String]:=Module[{data=Get[FileNameJoin[{dir,"Checkpoint.wl"}]],s},
 If[!AssociationQ[data] || Lookup[data,"Version",None]=!=$ConformalIBPVersion ||
  Lookup[data,"Hash",None]=!=Hash[Lookup[data,"State",None],"SHA256"],Return[fail["CheckpointMismatch","Checkpoint version or content hash does not match."]]];
 s=data["State"];If[Lookup[s,"ImplementationHash",None]=!=$implementationHash,
  Return[fail["ImplementationMismatch","Package source changed. Start a new campaign; old application ledgers must not be reused."]]];
 If[familyHash[s["Family"]]=!=s["FamilyHash"],Return[fail["FamilyMismatch","Checkpoint family changed."]]];
 runCampaign[s]];
(* Build exact equation neighbors in one support traversal, only when needed. *)
relationFrontier[f_,masters_List,rows_List]:=Module[{groups,atoms,keys},
 groups=Association[Last[Reap[Do[atoms=support[row];
   Scan[(Sow[atoms,#])&,Intersection[atoms,masters]],{row,rows}],_G,(#1->Union[Flatten[#2]])&]]];
 keys=Association[(#->simpleKey[f,#])& /@ Union[masters,Flatten[Values[groups]]]];
 Union[Flatten[Table[Select[Lookup[groups,master,{}],#=!=master && OrderedQ[{keys[master],keys[#]}]&],{master,masters}]]]];
runCampaign[initial_Association]:=Module[{s=initial,f=initial["Family"],o=initial["Options"],basis,pass,der,rows,targets,
 reduction,query,generated,new,finite,records,historyRules={},oldResidual,ci,cd,vars,r,p,cl,coordinates,
 fullInput,fullDE,input,de,boundary,matrices,sourcesRows,reason,changed,replay=True,epoch,startEpoch,
 independent,selectedRows,originalCount,curvature,allCoordinates,inputCoordinates,allSources,inputSources,
 frontier,masters,canonicalRows,generationNeeded,cacheImport,seedTargets,seedOptions,gapTargets,focused,fallback},
 If[familyHash[f]=!=s["FamilyHash"],Return[fail["FamilyMismatch","Family metadata hash changed."]]];
 If[!MemberQ[{"Retain","Quotient"},o["BoundaryPolicy"]],Return[fail["BoundaryPolicy","BoundaryPolicy must be Retain or Quotient."]]];
 If[!MemberQ[{"Always","OnDemand"},o["GenerationPolicy"]],Return[fail["GenerationPolicy","GenerationPolicy must be Always or OnDemand."]]];
 If[!MemberQ[{"Full","Targets"},o["ReductionScope"]],Return[fail["ReductionScope","ReductionScope must be Full or Targets."]]];
 If[!MemberQ[{"Original","Extended"},o["SeedDomain"]] || !MemberQ[{"Cartesian","SingleBlock"},o["BlockExpansion"]] || !MemberQ[{True,False},o["GapSeeding"]],Return[fail["SeedPolicy","Invalid campaign seeding policy."]]];
 If[s["Mode"]==="DE" && (f["Variables"]==={} || !And@@(FiniteIntegralQ[f,#]& /@ s["OriginalInputs"])),
  Return[fail["UnverifiedInput","DE inputs must pass the finite-integral check and kinematic variables must be supplied."]]];
 If[KeyExistsQ[s,"SymmetryCache"],cacheImport=importSymmetryCache[f,s["SymmetryCache"]];If[FailureQ[cacheImport],Return[cacheImport]]];
 startEpoch=s["Epoch"];reason="ExpansionLimit";s["Closed"]=False;
 If[KeyExistsQ[s,"PendingRelations"],s["Equations"]=Union[s["Equations"],s["PendingRelations"]];
  s=KeyDrop[s,"PendingRelations"];s["Epoch"]++];
 While[replay && s["Epoch"]-startEpoch<=o["MaxSystemExpansions"],
  replay=False;basis=s["OriginalInputs"];records={};
  Do[
   der=If[s["Mode"]==="DE",DifferentiateIntegrals[f,basis],<|"Rows"-><||>,"Targets"->support[basis]|>];
   If[FailureQ[der],reason=der;Break[]];rows=Flatten[Values[der["Rows"]],1];
   targets=Union[support[basis],der["Targets"]];
   s["HistoricalTargets"]=Union[s["HistoricalTargets"],targets];
   query=Union[s["HistoricalTargets"],s["PreviousRepresentatives"],targets];
   If[o["ReductionScope"]==="Targets",query=Union[query,support[Lookup[s,"HistoricalRules",{}]],sources[Lookup[s,"HistoricalRules",{}]]]];
   reduction=If[o["ReductionScope"]==="Targets",ReduceTargetIntegrals,ReduceIntegrals][f,query,s["Equations"],"Solver"->o["Solver"],"MaxExactColumns"->o["MaxExactColumns"],"MaxPrimes"->o["MaxPrimes"],"VerificationWorkers"->o["VerificationWorkers"],"KernelExecutable"->o["KernelExecutable"],
    "ProgressFunction"->Function[event,progress[o,Join[<|"Epoch"->s["Epoch"],"Round"->pass|>,event]]]];
   If[FailureQ[reduction],reason=reduction;Break[]];
   historyRules=Lookup[s,"HistoricalRules",{}];
   If[historyRules=!={},oldResidual=canonicalLinear /@ (((First /@ historyRules)-(Last /@ historyRules))/.Dispatch[reduction["Rules"]]);
    If[!And@@(zero /@ oldResidual),reason=fail["HistoricalRegression","An old reduction identity is not reproduced."];Break[]]];
   s["HistoricalRules"]=reduction["Rules"];s["LastReduction"]=reduction;
   s["CurrentRound"]=pass;s["CurrentInputs"]=basis;
   s["Status"]="ReductionVerified";checkpoint[s,o["OutputDirectory"]];
   progress[o,<|"Epoch"->s["Epoch"],"Round"->pass,"Action"->If[Lookup[reduction,"VerificationScope","Full"]==="SelectedOriginalEquations","Target reduction verified using selected original equations","Full reduction verified; continuing same-loop closure"],
    "Columns"->reduction["Columns"],"Queries"->Length[query],
    "BoundaryRuleCount"->Count[reduction["BoundaryRules"],Rule[a_,b_]/;!zero[a-b]]|>];
   fullInput=canonicalLinear /@ ((canonExpr[f,#]& /@ basis)/.Dispatch[reduction["Rules"]]);
   fullDE=canonicalLinear /@ ((canonExpr[f,#]& /@ rows)/.Dispatch[reduction["Rules"]]);
   input=fullInput/._BoundaryIntegral->0;de=fullDE/._BoundaryIntegral->0;
   s["PreviousRepresentatives"]=Union[s["PreviousRepresentatives"],support[{fullInput,fullDE}]];
   masters=support[{fullInput,fullDE}];frontier={};generationNeeded=True;
   If[s["Mode"]==="DE" && o["GenerationPolicy"]==="OnDemand",
    finite=BuildFiniteBasis[f,Join[fullInput,fullDE]];
    generationNeeded=FailureQ[finite] || reduction["UnseenTargets"]=!={}];
   If[generationNeeded,
   gapTargets=Union[reduction["UnseenTargets"],If[s["Mode"]==="DE" && o["GenerationPolicy"]==="OnDemand" && FailureQ[finite],masters,{}]];
   focused=TrueQ[o["GapSeeding"]] && s["Equations"]=!={} && gapTargets=!={};
   If[!focused,
    progress[o,<|"Epoch"->s["Epoch"],"Round"->pass,"Action"->"Building relation frontier for broad seeding"|>];
    canonicalRows=canonExpr[f,#]& /@ s["Equations"];frontier=relationFrontier[f,masters,canonicalRows]];
   seedTargets=If[focused,gapTargets,Union[targets,masters,frontier]];
   progress[o,<|"Epoch"->s["Epoch"],"Round"->pass,"Action"->"Generating IBP seeds","FocusedGapSeeding"->focused,"GapTargetCount"->Length[gapTargets],"CenterCount"->Length[seedTargets]|>];
   seedOptions={"CompletedApplications"->s["CompletedApplications"],"CompletedSymmetryInputs"->Lookup[s,"CompletedSymmetryInputs",{}],
    "FiniteSeeds"->Select[basis,Length[support[#]]>1&],"Workers"->o["Workers"],"KernelExecutable"->o["KernelExecutable"],
    "SeedDomain"->o["SeedDomain"],"BlockExpansion"->o["BlockExpansion"]};
   generated=GenerateSystem[f,seedTargets,"SeedCenters"->If[focused,"AllOriginalImages","Raw"],Sequence@@seedOptions];
   (* Widen only after the focused neighborhood contributes no new relation. *)
   If[!FailureQ[generated] && focused && Complement[generated["Equations"],s["Equations"]]==={},
    progress[o,<|"Epoch"->s["Epoch"],"Round"->pass,"Action"->"Focused seeds added no relations; building fallback frontier"|>];
    canonicalRows=canonExpr[f,#]& /@ s["Equations"];frontier=relationFrontier[f,masters,canonicalRows];
    fallback=GenerateSystem[f,Union[targets,masters,frontier],"SeedCenters"->"AllOriginalImages",
     Sequence@@Normal[Join[Association[seedOptions],<|"CompletedApplications"->Union[s["CompletedApplications"],generated["Applications"]]|>]]];
    If[FailureQ[fallback],generated=fallback,
     generated=Join[fallback,<|"Applications"->Union[generated["Applications"],fallback["Applications"]],
      "Equations"->Union[generated["Equations"],fallback["Equations"]],
      "RejectedApplications"->Join[generated["RejectedApplications"],fallback["RejectedApplications"]],
      "NewSymmetryInputs"->Union[generated["NewSymmetryInputs"],fallback["NewSymmetryInputs"]],"GapFallbackUsed"->True|>]]];
   If[AssociationQ[generated],generated=Join[generated,<|"GapTargets"->gapTargets,"FocusedGapSeeding"->focused,"RequestedCenters"->seedTargets|>]],
   generated=<|"Equations"->{},"Applications"->{},"GenerationSkipped"->True,
    "Reason"->"All actual queries covered and finite cover certified; advance derivative round"|>];
   If[FailureQ[generated],reason=generated;Break[]];
   s["CompletedApplications"]=Union[s["CompletedApplications"],generated["Applications"]];
   s["CompletedSymmetryInputs"]=Union[Lookup[s,"CompletedSymmetryInputs",{}],Lookup[generated,"NewSymmetryInputs",{}]];
   new=Complement[generated["Equations"],s["Equations"]];
   s["LastGenerationAudit"]=KeyDrop[generated,{"Equations","Applications"}];
   s["LastGenerationAudit"]=Append[s["LastGenerationAudit"],"RelationFrontierCenters"->frontier];
   s["GenerationHistory"]=Append[Lookup[s,"GenerationHistory",{}],Join[<|"Epoch"->s["Epoch"],"Round"->pass,"NewRelationCount"->Length[new],"ApplicationCount"->Length[generated["Applications"]]|>,s["LastGenerationAudit"]]];
   If[new=!={} && s["Epoch"]-startEpoch<o["MaxSystemExpansions"],
    s["Equations"]=Union[s["Equations"],new];s["Epoch"]++;replay=True;
    s["Status"]="ReplayFromOriginalInputs";
    progress[o,<|"Epoch"->s["Epoch"],"NewRelations"->Length[new],"HistoricalQueries"->Length[query],"Action"->"Re-reduce all historical targets and restart from original inputs"|>];
    checkpoint[s,o["OutputDirectory"]];Break[]];
   If[new=!={},reason="ExpansionLimit";s["PendingRelations"]=new;Break[]];
   If[s["Mode"]==="Reduction",s["ReducedInputs"]=fullInput;reason="ReductionFixedPoint";Break[]];
   vars=support[{input,de}];ci=coeff[input,vars];cd=coeff[de,vars];r=rr[ci];p=pivots[r];
   cl=If[r==={},And@@Flatten[Map[zero,cd,{2}]],And@@Flatten[Map[zero,cd-cd[[All,p]].r,{2}]]];
   finite=BuildFiniteBasis[f,Join[fullInput,fullDE]];
   If[FailureQ[finite],reason=finite;s["UnverifiedRows"]=Join[fullInput,fullDE];Break[]];
   AppendTo[records,<|"Round"->pass,"InputCount"->Length[basis],"DERows"->Length[rows],"Targets"->Length[der["Targets"]],
    "RawSupport"->Length[vars],"SingleFinite"->Length[finite["SingleFinite"]],"Combinations"->Length[finite["Combinations"]],
    "OutputCount"->Length[finite["Basis"]],"ClosedOnSameInput"->cl,"BoundarySources"->Length[sources[{fullInput,fullDE}]],
    "FactorizedSingleFinite"->Count[(Length[parts[f,#]]>1& /@ finite["SingleFinite"]),True],
    "SelfReducedQueries"->Length[reduction["SelfReducedTargets"]],"UnseenQueries"->Length[reduction["UnseenTargets"]]|>];
   saveRound[o["OutputDirectory"],s["Epoch"],pass,<|"Input"->basis,"Derivatives"->der,"Reduction"->reduction,
    "ReducedInput"->fullInput,"ReducedDE"->fullDE,"FiniteBasis"->finite,"Summary"->Last[records]|>];
   progress[o,Last[records]];s["Basis"]=finite["Basis"];s["History"]=records;
   If[cl,
    (* Coordinates are solved against the SAME independent input, not the new output. *)
    originalCount=Length[basis];independent=pivots[rr[Transpose[ci]]];
    selectedRows=Flatten[Table[independent+(k-1)originalCount,{k,Length[f["Variables"]]}]];
    allCoordinates=If[independent==={},ConstantArray[{},Length[fullDE]],Map[Together,cd[[All,p]].Inverse[ci[[independent,p]]],{2}]];
    inputCoordinates=If[independent==={},ConstantArray[{},Length[fullInput]],Map[Together,ci[[All,p]].Inverse[ci[[independent,p]]],{2}]];
    allSources=canonicalLinear /@ (fullDE-allCoordinates.fullInput[[independent]]);
    inputSources=canonicalLinear /@ (fullInput-inputCoordinates.fullInput[[independent]]);
    basis=basis[[independent]];fullInput=fullInput[[independent]];fullDE=fullDE[[selectedRows]];
    coordinates=allCoordinates[[selectedRows]];
    matrices=Association@MapIndexed[#1->Take[coordinates,{(First[#2]-1)Length[basis]+1,First[#2]Length[basis]}]&,f["Variables"]];
    sourcesRows=canonicalLinear /@ (fullDE-coordinates.fullInput);
    If[!FreeQ[sourcesRows,_G],reason=fail["SourceReconstruction","DE reconstruction failed."];Break[]];
    s["Basis"]=basis;s["Matrices"]=matrices;s["BoundaryRows"]=sourcesRows;
    s["LowerLoopDETargets"]=sources[sourcesRows];
    s["AllInputDEResidualSources"]=allSources;s["InputReconstructionSources"]=inputSources;
    s["InputReconstructionMatrix"]=inputCoordinates;
    s["ClosedModuloBoundary"]=True;s["Closed"]=And@@(zero /@ Join[allSources,inputSources]);
    reason=If[s["Closed"],"Closed",If[o["BoundaryPolicy"]==="Quotient","QuotientClosed","ClosedModuloBoundary"]];
    If[s["Closed"],curvature=Table[With[{a=f["Variables"][[i]],b=f["Variables"][[j]]},
      Map[Together,D[matrices[a],b]-D[matrices[b],a]+matrices[a].matrices[b]-matrices[b].matrices[a],{2}]],
      {i,Length[f["Variables"]]},{j,i+1,Length[f["Variables"]]}];
     s["FlatnessVerified"]=And@@(zero /@ Flatten[curvature]);
     If[!TrueQ[s["FlatnessVerified"]],s["Closed"]=False;reason=fail["Curvature","Closed candidate failed the flatness check."]]];
    Break[]];
   basis=finite["Basis"];reason="RoundLimit",
   {pass,o["MaxRounds"]}];
  s["History"]=records;checkpoint[s,o["OutputDirectory"]]
 ];
 s["Status"]=reason;s["Closed"]=TrueQ[Lookup[s,"Closed",False]];
 s["BoundaryPolicy"]=o["BoundaryPolicy"];
 checkpoint[s,o["OutputDirectory"]];s];
