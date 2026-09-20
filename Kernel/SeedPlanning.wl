(* Partition only target centers: each shard uses the unchanged seed geometry. *)
mergeSeedPlans[plans_List]:=Module[{ops=First[plans]["Operators"],batches},
 If[!And@@(#["Operators"]===ops& /@ plans),Return[fail["SeedPlanOperators","Seed planning shards disagree on operators."]]];
 batches=Table[Join[First[plans]["Batches"][[k]],<|"Seeds"->Union[Flatten[(#["Batches"][[k]]["Seeds"]& /@ plans),1]]|>],{k,Length[ops]}];
 Join[First[plans],<|"Batches"->batches,"Centers"->Union[Flatten[Lookup[plans,"Centers"],1]],
  "UnmappedCenters"->Union[Flatten[Lookup[plans,"UnmappedCenters"],1]],
  "EmptyDegrees"->Union[Lookup[Select[batches,#["Seeds"]==={}&],"Degree",{}]]|>]];
seedPlan[f_,targets_,ops_,options_]:=Module[{n=Replace[options["SeedPlanningWorkers"],Automatic->options["Workers"]],threshold=options["SeedPlanningThreshold"],
 centers=support[targets],operators=Replace[ops,Automatic:>GenerateOperators[f]],seedOptions,dir,runner,kernel,jobs={},ids,job,results,plan,started=AbsoluteTime[],report=options["ProgressFunction"]},
 If[!IntegerQ[n] || n<1 || !IntegerQ[threshold] || threshold<0,Return[fail["SeedPlanningOptions","SeedPlanningWorkers must be Automatic or a positive integer; SeedPlanningThreshold must be a nonnegative integer."]]];
 seedOptions=FilterRules[Normal[options],Options[GenerateSeeds]];
 n=Min[n,Length[centers]];
 If[report=!=None,report[<|"Action"->"Preparing seed plan","TargetCenters"->Length[centers],"PlanningWorkers"->If[n<2 || Length[centers]<threshold,0,n]|>]];
 If[n<2 || Length[centers]<threshold,
  plan=GenerateSeeds[f,targets,operators,Sequence@@seedOptions];If[FailureQ[plan],Return[plan]];
  If[report=!=None,report[<|"Action"->"Seed plan prepared","PlanningWorkers"->0,"Seconds"->AbsoluteTime[]-started|>]];
  Return[Append[plan,"SeedPlanning"-><|"IndependentKernels"->0,"TargetCenters"->Length[centers],"Seconds"->AbsoluteTime[]-started|>]]];
 If[!And@@(validIntegral[f,#]& /@ centers),Return[fail["IntegralShape","Invalid seed center."]]];
 dir=CreateDirectory[FileNameJoin[{$TemporaryDirectory,"conformal-seed-plan-"<>CreateUUID[]}]];
 runner=FileNameJoin[{DirectoryName[DirectoryName[$packageFile]],"scripts","seed-plan-worker.wls"}];kernel=Replace[options["KernelExecutable"],Automatic:>First[$CommandLine]];
 Do[ids=Range[k,Length[centers],n];job=<|"Family"->f,"Centers"->centers[[ids]],"Indices"->ids,"Operators"->operators,"Options"->seedOptions,"ImplementationHash"->$implementationHash|>;
  Put[job,FileNameJoin[{dir,"input"<>ToString[k]<>".wl"}]];
  AppendTo[jobs,StartProcess[{kernel,"-script",runner,FileNameJoin[{dir,"input"<>ToString[k]<>".wl"}],FileNameJoin[{dir,"output"<>ToString[k]<>".wl"}]}]],{k,n}];
 If[AnyTrue[jobs,Head[#]=!=ProcessObject&],Scan[If[Head[#]===ProcessObject,KillProcess[#]]&,jobs];Return[fail["SeedPlanWorkerLaunch","Could not launch seed planning workers.",<|"Directory"->dir|>]]];
 While[AnyTrue[jobs,ProcessStatus[#]==="Running"&],Pause[0.1]];
 If[!And@@Table[ProcessInformation[jobs[[k]],"ExitCode"]===0 && FileExistsQ[FileNameJoin[{dir,"output"<>ToString[k]<>".wl"}]],{k,n}],Return[fail["SeedPlanWorkerFailure","Seed planning worker failed; no plan accepted.",<|"Directory"->dir|>]]];
 results=Get /@ Table[FileNameJoin[{dir,"output"<>ToString[k]<>".wl"}],{k,n}];
 If[!And@@Table[AssociationQ[results[[k]]] && Lookup[results[[k]],"ImplementationHash",None]===$implementationHash &&
   Lookup[results[[k]],"FamilyHash",None]===f["Hash"] && Lookup[results[[k]],"Indices",{}]===Range[k,Length[centers],n] &&
   Lookup[results[[k]],"TargetHash",None]===Hash[centers[[Range[k,Length[centers],n]]],"SHA256"] && AssociationQ[Lookup[results[[k]],"Plan",None]],{k,n}],
  Return[fail["SeedPlanCoverage","Seed planning source, family or exact target coverage mismatch.",<|"Directory"->dir|>]]];
 plan=mergeSeedPlans[Lookup[results,"Plan"]];If[FailureQ[plan],Return[plan]];
 If[report=!=None,report[<|"Action"->"Seed plan prepared","PlanningWorkers"->n,"Seconds"->AbsoluteTime[]-started|>]];
 Append[plan,"SeedPlanning"-><|"IndependentKernels"->n,"TargetCenters"->Length[centers],"Seconds"->AbsoluteTime[]-started,"JobDirectory"->dir,"ExactTargetCoverage"->True|>]];
