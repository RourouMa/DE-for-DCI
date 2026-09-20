Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],"Kernel","ConformalIBP.wl"}]];
args=Take[If[Length[$ScriptCommandLine]>=3,$ScriptCommandLine,$CommandLine],-2];job=Get[First[args]];
If[job["ImplementationHash"]=!=ConformalIBP`Private`$implementationHash,Quit[1]];
plan=Check[GenerateSeeds[job["Family"],job["Centers"],job["Operators"],Sequence@@job["Options"]],$Failed];
If[!AssociationQ[plan],Put[plan,Last[args]];Quit[1]];
Put[<|"Plan"->plan,"ImplementationHash"->ConformalIBP`Private`$implementationHash,"FamilyHash"->job["Family"]["Hash"],"Indices"->job["Indices"],"TargetHash"->Hash[job["Centers"],"SHA256"]|>,Last[args]];Quit[0];
