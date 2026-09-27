r="/home/april/Documents/ChatGPT/DE for DCI";d=DirectoryName[$InputFileName];Get[r<>"/DE-for-DCI-publish/Kernel/ConformalIBP.wl"];
p=Get[r<>"/DE-for-DCI-publish/runs/g4-closure-20260925/loop4-v7/Checkpoint.wl"];s=p["State"];f=s["Family"];
whole=Select[s["CompletedApplications"],!MatchQ[#,{_Integer,_ConformalIBP`G}]&];Clear[s,p,ConformalIBP`Private`$checkpointPayload];
Print["NonAtomicCount ",Length[whole]]; atoms=ConformalIBP`Private`support[Last /@ whole];Print["UniqueNonAtomicSeedAtoms ",Length[atoms]];
max=Max[Flatten[(List@@#)[[f["LoopLoopIDs"]]]& /@ atoms]];
contact=Select[whole,AnyTrue[ConformalIBP`Private`support[Last[#]],MemberQ[(List@@#)[[f["LoopLoopIDs"]]],2]&]&];
report=<|"NonAtomicApplications"->Length[whole],"UniqueSeedAtoms"->Length[atoms],"MaximumInternalPowerAmongAtoms"->max,"NonAtomicApplicationsWithAnyInternalDoublePole"->Length[contact],"AllNonAtomicSeedsFreeOfPairContact"->(contact==={}),"OperatorHashes"->Union[First /@ whole]|>;
Print[report];Put[<|"Report"->report,"Family"->f,"Applications"->whole,"ApplicationsWithAnyInternalDoublePole"->contact|>,d<>"/NonAtomicContactAudit.wl"];
Export[d<>"/NonAtomicContactAudit.json",report,"RawJSON"];Quit[];
