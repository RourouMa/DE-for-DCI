r="/home/april/Documents/ChatGPT/DE for DCI";d=DirectoryName[$InputFileName];Get[r<>"/DE-for-DCI-publish/Kernel/ConformalIBP.wl"];
p=Get[r<>"/DE-for-DCI-publish/runs/g4-closure-20260925/loop4-v7/Checkpoint.wl"];s=p["State"];Print["StateKeys ",Keys[s]];
bad=Select[s["CompletedApplications"],!MatchQ[#,{_Integer,_ConformalIBP`G}]&,20];Print["BadApplicationExamples ",InputForm[bad]];
record=<|"CheckpointFile"->Lookup[p,"File",None],"Rows"->Length[s["Equations"]],"CompletedApplications"->Length[Lookup[s,"CompletedApplications",{}]],"AllCompletedSeedsAtomicG"->AllTrue[s["CompletedApplications"],MatchQ[#,{_Integer,_ConformalIBP`G}]&],"NonAtomicExamples"->(ToString[#,InputForm]& /@ bad),"CompletedCoupledGroups"->Lookup[s,"CompletedCoupledGroups",{}],"CoupledSeedGroupsOption"->Lookup[s["Options"],"CoupledSeedGroups",{}],"AdditionalOptions"->KeyTake[s["Options"],{"WholeSeedGroups","AdditionalEquations","Operators","SeedDomain"}]|>;
Print[record];Print["ExampleApplications ",InputForm[Take[Lookup[s,"CompletedApplications",{}],UpTo[3]]]];
Export[d<>"/CheckpointContactAudit.json",record,"RawJSON"];Quit[];
