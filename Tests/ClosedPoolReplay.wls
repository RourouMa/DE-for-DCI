(* Replay a trusted closed campaign's equation pool with current defaults.
   Usage: WolframKernel -script Tests/ClosedPoolReplay.wls checkpoint.wl finiteflow-root output-directory *)
root=DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
args=Take[If[Length[$ScriptCommandLine]>=4,$ScriptCommandLine,$CommandLine],-3];
If[!TrueQ[InitializeFiniteFlow[args[[2]],FileNameJoin[{args[[2]],"mathlink"}]]],Quit[1]];
old=Get[args[[1]]];If[old["Hash"]=!=Hash[old["State"],"SHA256"],Print["Invalid archive hash"];Quit[1]];old=old["State"];
f=CreateFamily[KeyDrop[old["Family"],{"Hash"}]];
Needs["ProcessLink`"];streams=CreateDirectory[FileNameJoin[{$TemporaryDirectory,"closed-pool-replay-"<>CreateUUID[]}]];
result=Block[{ProcessLink`Private`$TempPrefix=FileNameJoin[{streams,"wl-stream-std"}]},
 RunDE[f,old["OriginalInputs"],"InitialEquations"->old["Equations"],"Solver"->"FiniteFlow","OutputDirectory"->args[[3]]]];
If[!AssociationQ[result] || !KeyExistsQ[result,"Matrices"],Print[result];Quit[1]];
checks=<|"ClosedModuloBoundary"->TrueQ[Lookup[result,"ClosedModuloBoundary",False]],
 "SameBasis"->(result["Basis"]===old["Basis"]),
 "SameMatrices"->And@@(ConformalIBP`Private`zero /@ Flatten[Values[result["Matrices"]]-Values[old["Matrices"]]]),
 "SameBoundaryRows"->And@@(ConformalIBP`Private`zero /@ (result["BoundaryRows"]-old["BoundaryRows"])),
 "NoNewSeedingNeeded"->(result["CompletedApplications"]==={}),
 "SameInputCoordinates"->(result["InputReconstructionMatrix"]===old["InputReconstructionMatrix"])|>;
Put[checks,FileNameJoin[{args[[3]],"PackageRegression.wl"}]];Print[checks];Quit[If[And@@Values[checks],0,1]];
