Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],"Kernel","ConformalIBP.wl"}]];
args=Take[If[Length[$ScriptCommandLine]>=3,$ScriptCommandLine,$CommandLine],-2];job=Get[First[args]];
options=Association[job["Options"]];
If[KeyExistsQ[job,"OptionsFile"],shared=Quiet[Check[Get[job["OptionsFile"]],$Failed]];
 If[!AssociationQ[shared],Put[Failure["WorkerOptions",<|"MessageTemplate"->"Shared worker options could not be loaded."|>],Last[args]];Quit[1]];
 options=Join[shared,options]];
If[KeyExistsQ[job,"SymmetryCacheFile"],imported=ConformalIBP`Private`importSymmetryCache[job["Family"],Get[job["SymmetryCacheFile"]]];
 If[FailureQ[imported],Put[imported,Last[args]];Quit[1]]];
priorSymmetry=Keys[ConformalIBP`Private`symmetryKnown[job["Family"]["Hash"]]];
result=Check[If[KeyExistsQ[job,"SeedPlan"],
 ConformalIBP`Private`generatePlannedSystem[job["Family"],job["Targets"],options,job["SeedPlan"]],
 ConformalIBP`GenerateSystem[job["Family"],job["Targets"],Sequence@@Normal[options]]],$Failed];
If[AssociationQ[result],result=Append[result,"SymmetryCache"->ConformalIBP`Private`exportSymmetryCache[job["Family"],priorSymmetry]]];
Put[result,Last[args]];Quit[If[FailureQ[result] || result===$Failed,1,0]];
