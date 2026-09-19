Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],"Kernel","ConformalIBP.wl"}]];
args=Take[If[Length[$ScriptCommandLine]>=3,$ScriptCommandLine,$CommandLine],-2];job=Get[First[args]];
result=Check[ConformalIBP`GenerateSystem[job["Family"],job["Targets"],Sequence@@job["Options"]],$Failed];
Put[result,Last[args]];Quit[If[FailureQ[result] || result===$Failed,1,0]];
