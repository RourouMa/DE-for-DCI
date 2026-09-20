(* Exact comparison with a trusted baseline package for every distinct degree.
   Usage: WolframKernel -script Tests/SeedPlanEquivalence.wls baseline.wl job.wl *)
root=DirectoryName[DirectoryName[$InputFileName]];
args=Take[If[Length[$ScriptCommandLine]>=3,$ScriptCommandLine,$CommandLine],-2];
Get[First[args]];
DownValues[legacyGenerateSeeds]=DownValues[ConformalIBP`GenerateSeeds] /. ConformalIBP`GenerateSeeds -> legacyGenerateSeeds;
Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
job=Get[Last[args]];f=job["Family"];targets=job["Targets"];
ops=GenerateOperators[f];representatives=First /@ GatherBy[ops,#["Degree"]&];
t=AbsoluteTiming[optimized=GenerateSeeds[f,targets,ops,"SeedDomain"->"Extended","SeedCenters"->"Raw","BlockExpansion"->"Cartesian"];];
Print[<|"Centers"->Length[targets],"OptimizedAllOperatorsSeconds"->First[t]|>];
reports=Table[
 timing=AbsoluteTiming[old=TimeConstrained[legacyGenerateSeeds[f,targets,{op}],120,$Aborted];];
 new=SelectFirst[optimized["Batches"],#["Degree"]===op["Degree"]&];
 check=AssociationQ[old] && First[old["Batches"]]["Seeds"]===new["Seeds"];
 report=<|"Degree"->op["Degree"],"OriginalOneOperatorSeconds"->First[timing],
  "SeedCount"->Length[new["Seeds"]],"ExactlyEqual"->check|>;
 Print[report];report,{op,representatives}];
ok=And@@Lookup[reports,"ExactlyEqual"];
Print[<|"AllDegreesExactlyEqual"->ok,"DegreeClasses"->Length[reports]|>];
Quit[If[ok,0,1]];
