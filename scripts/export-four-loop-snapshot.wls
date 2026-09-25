(* Usage: WolframKernel -script scripts/export-four-loop-snapshot.wls CHECKPOINT OUTDIR *)
root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
args=Take[$CommandLine,-2];checkpointFile=args[[1]];out=args[[2]];
data=Get[checkpointFile];
If[!AssociationQ[data]||!TrueQ[ConformalIBP`Private`checkpointIntegrityQ[data]],Print["Checkpoint integrity failed"];Quit[2]];
s=data["State"];
If[s["ImplementationHash"]=!=ConformalIBP`Private`$implementationHash||Length[s["Family"]["Loops"]]=!=4,Print["Source or family mismatch"];Quit[3]];
If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
If[FileExistsQ[FileNameJoin[{out,"PortablePool.wl"}]],Print["Refusing to overwrite snapshot"];Quit[4]];
pool=Join[KeyTake[s,{"Family","FamilyHash","ImplementationHash","OriginalInputs","Equations","CompletedApplications","CompletedSymmetryInputs"}],
 <|"EquationPoolHash"->Hash[s["Equations"],"SHA256"],"ApplicationLedgerHash"->Hash[s["CompletedApplications"],"SHA256"],
 "SymmetryLedgerHash"->Hash[s["CompletedSymmetryInputs"],"SHA256"],"SourceEpoch"->s["Epoch"],"SourceRound"->s["CurrentRound"],
 "LowerLoopDEGenerated"->False,"ClosedModuloBoundary"->False,"ReductionRulesImported"->False|>];
Put[pool,FileNameJoin[{out,"PortablePool.wl"}]];
meta=<|"Epoch"->s["Epoch"],"Round"->s["CurrentRound"],"EquationCount"->Length[s["Equations"]],"CompletedApplications"->Length[s["CompletedApplications"]],
 "CurrentInputCount"->Length[s["CurrentInputs"]],"ImplementationHash"->ToString[s["ImplementationHash"],InputForm],
 "EquationPoolHash"->ToString[pool["EquationPoolHash"] ,InputForm],"ClosedModuloBoundary"->False,"NativeCheckpointRequired"->False|>;
Export[FileNameJoin[{out,"Snapshot.json"}],meta,"RawJSON"];Print[meta];Quit[0];
